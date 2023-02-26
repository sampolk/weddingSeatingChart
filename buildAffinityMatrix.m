%% Load and preprocess data 

dataManipulation

%% Set parameters for seating chart

maxPeoplePerTable = 10;
minPeoplePerTable = 8;

%% Set scores for like family, unit, side, generation, and status

familyScore = 3; % We add this affinity to a pair of individuals if they come from the same family
unitScore = 2; % We add this affinity to a pair of individuals if they come from the same "unit"
sideScore = 1; % We add this affinity to a pair of individuals if they come from the same side of the aisle (or from both)
statusScore = 4; % We add this affinity to a pair of individuals if they come from the same family
genScore = 2; % We add this affinity to a pair of individuals if they come from the same generation

%% Build matrix
% This matrix encodes a complete graph with edge weight  

numGuests = height(T);

matrix = zeros(numGuests);
for i = 1:numGuests
    for j = 1:numGuests

        % First, add familyScore if guests i and j have same family. 
        matrix(i,j) = familyScore*(T.familyNums(i) == T.familyNums(j));


        % First, add unitScore if guests i and j have same unit. 
        matrix(i,j) = matrix(i,j) + unitScore*(T.unitNums(i) == T.unitNums(j));

        % First, add sideScore if guests i and j have same side 
        % (or if one of them comes from both)
        if T.sideNums(i) == T.sideNums(j) || T.sideNums(i) == sideDict("Both") || T.sideNums(j) == sideDict("Both")
            matrix(i,j) = matrix(i,j) + sideScore;
        end

        % First, add statusScore if guests i and j have same status. 
        matrix(i,j) = matrix(i,j) + statusScore*(T.statusNums(i) == T.statusNums(j));

        % First, add genScore if guests i and j have same generation. 
        matrix(i,j) = matrix(i,j) + genScore*(T.genNums(i) == T.genNums(j));
 
    end
    matrix(i,i) = 0; % Make it so that each person is not connected to themself
end

%% Delte intra-party edges

for party = 1:length(unique(T.partyNums))

    % Look for all people who are in this party. We will force these people
    % to sit together by deleting edges of all but the most-connected
    % individual. 

    thisParty = find(T.partyNums == party);
    
    matrixSubset = matrix(thisParty,thisParty);
    [~,idx] = max(sum(matrixSubset)); % Most connected person in party 
    matrixSubset(setdiff(2:end, idx),setdiff(2:end, idx)) = 0; % Make other people in party only connected to that person
  
end

%% Separate guests into tables 

[V,D] = eig(matrix./sum(matrix));
[lambda,idx] = sort(abs(diag(D)), 'descend');  

numTables = ceil(height(T)/maxPeoplePerTable);

[labels,centroids] = constrainedKMeans(V(:,1:numTables), numTables, minPeoplePerTable*ones(numTables,1), 100);

%%      
seatingChart = cell(numTables,1);
for table = 1:numTables
    seatingChart{table} = T.name{find(labels == table)};
end

