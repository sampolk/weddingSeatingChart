% TODO: 
%   - Add in sibling affinity
%   - Make sure couples/parties aren't split up
%   - Model family politics

%% Load and preprocess data 

dataManipulation

%% Set parameters for seating chart

maxNumPeoplePerTable = 10;
minNumPeoplePerTable = 8;

numTables = ceil(height(T)/maxNumPeoplePerTable); % Ensure that everyone can sit at a table

%% Set scores for like family, unit, side, generation, and status

familyScore = 6; % We add this affinity to a pair of individuals if they come from the same family
unitScore = 2; % We add this affinity to a pair of individuals if they come from the same "unit", which is 1 level higher in the family tree
sideScore = 1; % We add this affinity to a pair of individuals if they come from the same side of the aisle (or from both)
statusScore = 10; % We add this affinity to a pair of individuals if they come from the same status (group of like invited wedding guests)
genScore = 4; % We add this affinity to a pair of individuals if they come from the same generation 

partyScore = 1000; % We add this much to a pair of inviduals' affinity if they come from the same party (i.e., couple or family)

%% Build matrix
% This matrix encodes a complete graph, with each pair of wedding attendees
% being weighted according to their likelihood to enjoy each other's
% company. 

numGuests = height(T);

matrix = zeros(numGuests);
for i = 1:numGuests
    for j = 1:numGuests

        % First, add familyScore if guests i and j have same family. 
        matrix(i,j) = familyScore*(T.familyNums(i) == T.familyNums(j));

        % Next, add unitScore if guests i and j have same unit. 
        matrix(i,j) = matrix(i,j) + unitScore*(T.unitNums(i) == T.unitNums(j));

        % Next, add sideScore if guests i and j have same side 
        % (or if one of them comes from both)
        if T.sideNums(i) == T.sideNums(j) || T.sideNums(i) == sideDict("Both") || T.sideNums(j) == sideDict("Both")
            matrix(i,j) = matrix(i,j) + sideScore;
        end

        % Next, add statusScore if guests i and j have same status. 
        matrix(i,j) = matrix(i,j) + statusScore*(T.statusNums(i) == T.statusNums(j));

        % First, add genScore if guests i and j have same generation. 
        matrix(i,j) = matrix(i,j) + genScore*(T.genNums(i) == T.genNums(j));
 
    end
    matrix(i,i) = 0; % Make it so that each person is not connected to themself
end

%% Ensure that people from same party are seated together
% --- Weight intra-party edges really high
% TODO: Maybe we can turn this into a constraint instead.  n
for party = 1:length(unique(T.partyNums))
    thisParty = find(T.partyNums == party);
    matrix(thisParty,thisParty) =  partyScore;
end 

%% Separate guests into tables using constrained spectral clustering
% We rely on a constrained K-Means MATLAB implementation that I published
% open-source here: https://www.mathworks.com/matlabcentral/fileexchange/117355-constrained-k-means
%
% We will effectivley look for a partition of guests based on  

% First, we compute the eigendecomposition of the graph Laplacian of the
% affinity matrix. The K eigenvectors with largest eigenvalue tend to
% concentrate on the K most highly-connected regions in the graph. 
[V,D] = eig(matrix./sum(matrix));
[lambda,idx] = sort(abs(diag(D)), 'descend');  

% Next, let's perform Constrained K-Means on the first numTables
% eigenvectors calculated above. 
X = V(:,idx(2:numTables));

% Assign initial table assignments and centroids meant to represent the
% "average guest on each table"
labels = randi(numTables,numGuests,1);
centroids = zeros(numTables,size(X,2));
for k = 1:numTables
    centroids(k,:) = mean(X(labels==k,:));
end

iter = 1; % Used to ensure that we not exceed maxiter iterations. 
while iter<20  
    
    % Below is our objective function 
    objectiveFunction = reshape(0.5*pdist2(X, centroids).^2, [numGuests*numTables,1]); % Squared Euclidean distance between data points and centroids, vectorized
    
    % Next, let's build our constraint matrix
    % First, we ensure that no point is assigned to more than one table
    A1 = sparse(repmat((1:numGuests)',1,numTables),  reshape(1:numTables*numGuests, [numGuests,numTables]), ones(numGuests, numTables));
    b1 = ones(numGuests,1); 

    % Next, we ensure that each point is assigned to at least one table.
    A2 = sparse(repmat((1:numGuests)',1,numTables),  reshape(1:numTables*numGuests, [numGuests,numTables]), -ones(numGuests, numTables));
    b2 = -ones(numGuests,1); 

    % Next, we ensure that each table is assigned at least minTableSize
    % guests 
    A3 = sparse(reshape(repmat((1:numTables)', 1,numGuests)', [numGuests*numTables,1]),1:numGuests*numTables, -ones(1,numGuests*numTables)); 
    b3 = -minNumPeoplePerTable*ones(numTables,1); 

    % Next, we ensure that each table is assigned at most maxTableSize
    % guests 
    A4 = sparse(reshape(repmat((1:numTables)', 1,numGuests)', [numGuests*numTables,1]),1:numGuests*numTables, ones(1,numGuests*numTables)); 
    b4 = maxNumPeoplePerTable*ones(numTables,1); 

    % Next, we ensure that each party is assigned to the same table
    [A5, b5] = buildIntraPartyConstraint(T.partyNums, numTables);

    % Now that we have our constraints, let's optimize using mixed-integer
    % linear programming. This gives us table assignments satisfying the
    % above constraints
    output = intlinprog(objectiveFunction, 1:numGuests*numTables, [A1; A2; A3; A4; A5], [b1; b2; b3; b4; b5], [], [], zeros(numGuests*numTables,1), ones(numGuests*numTables,1));
    [~, labelsNew] = max(reshape(output,numGuests,numTables), [], 2);

    % Now that we have our new labels, let's update our centroids. 
    centroidsNew = zeros(numTables,size(X,2));
    for k = 1:numTables
        centroidsNew(k,:) = mean(X(labelsNew == k,:));
    end

    % Let's test to see if we have converged. If our old centroids are the
    % same as our new centroids, we stop iterating.  
    if sum(diag(pdist2(centroids, centroidsNew)) == zeros(numTables,1)) == 2 % True if centroids do not change. 
        labels = labelsNew;
        centroids = centroidsNew;
        break
    else
        % In this case, we take the current centroids and move on
        centroids = centroidsNew;
        iter = iter+1;
    end
end
if iter == 20
    labels = labelsNew;
    centroids = centroidsNew;
end
        
%% Visualize seating chart
seatingChart = cell(numTables,1);
for table = 1:numTables
    disp(["Table ", num2str(table)])
    disp(T.name(labels == table));
end

%% Constraint to ensure people from same party are in same table
[A,b] = buildIntraPartyConstraint(T.partyNums, numTables);

A*output;


