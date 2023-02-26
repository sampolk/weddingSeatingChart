% TODO: 
%   - Add in sibling affinity
%   - Make sure couples/parties aren't split up
%   - Model family politics

%% Load and preprocess data 

dataManipulation

%% Set parameters for seating chart

maxNumPeoplePerTable = 10;
minNumPeoplePerTable = 9;

%% Set scores for like family, unit, side, generation, and status

familyScore = 5; % We add this affinity to a pair of individuals if they come from the same family
unitScore = 2; % We add this affinity to a pair of individuals if they come from the same "unit"
sideScore = 1; % We add this affinity to a pair of individuals if they come from the same side of the aisle (or from both)
statusScore = 4; % We add this affinity to a pair of individuals if they come from the same family
genScore = 2; % We add this affinity to a pair of individuals if they come from the same generation 

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

%% Ensure that people from same party are seated together
% --- Weight intra-party edges really high
for party = 1:length(unique(T.partyNums))
    thisParty = find(T.partyNums == party);
    matrix(thisParty,thisParty) = 100;
end 

%% Separate guests into tables 

[V,D] = eig(matrix./sum(matrix));
[lambda,idx] = sort(abs(diag(D)), 'descend');  

numTables = ceil(height(T)/maxNumPeoplePerTable);

[labels,centroids] = constrainedKMeans(V(:,1:numTables), numTables, minNumPeoplePerTable*ones(numTables,1), maxNumPeoplePerTable*ones(numTables,1), 20);

%% Visualize seating chart
seatingChart = cell(numTables,1);
for table = 1:numTables
    disp(["Table ", num2str(table)])
    disp(T.name(labels == table));
end

