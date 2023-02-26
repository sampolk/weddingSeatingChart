%% Load table from the knot

T = readtable("guestList.csv");

%% Create single name variable
name = cell(height(T),1);
for i = 1:height(T)
   name{i} = T.FirstName{i} + " " + T.LastName{i};
end
T.name = name;

%% Party Identification
% Goal: identify each person's belonging to a party. 
% TODO: check to ensure that each party is sensibly made. 

partyDict = dictionary(string(unique(T.Party))', 1:length(unique(T.Party)));

partyNums = zeros(height(T),1);
for i = 1:height(T)
    partyNums(i) = partyDict(T.Party(i));
end
T.partyNums = partyNums;

%% Family Identification
% Goal: identify each person's belonging to a family. 

familyDict = dictionary(string(unique(T.Family))', 1:length(unique(T.Family)));

familyNums = zeros(height(T),1);
for i = 1:height(T)
    familyNums(i) = familyDict(T.Family(i));
end
T.familyNums = familyNums;

%% Unit Identification
% Goal: identify each person's belonging to a unit. 

unitDict = dictionary(string(unique(T.Unit))', 1:length(unique(T.Unit)));

unitNums = zeros(height(T),1);
for i = 1:height(T)
    unitNums(i) = unitDict(T.Unit(i));
end
T.unitNums = unitNums;


%% Side Identification
% Goal: identify each person's belonging to a side of the aisle. 

sideDict = dictionary(string(unique(T.Side))', 1:length(unique(T.Side)));

sideNums = zeros(height(T),1);
for i = 1:height(T)
    sideNums(i) = sideDict(T.Side(i));
end
T.sideNums = sideNums;


%% Generation Identification
% Goal: identify each person's belonging to a generation. 

genDict = dictionary(string(unique(T.Generation))', 1:length(unique(T.Generation)));

genNums = zeros(height(T),1);
for i = 1:height(T)
    genNums(i) = genDict(T.Generation(i));
end
T.genNums = genNums;


%% Status Identification
% Goal: identify each person's belonging to a status group. 

statusDict = dictionary(string(unique(T.Status))', 1:length(unique(T.Status)));

statusNums = zeros(height(T),1);
for i = 1:height(T)
    statusNums(i) = statusDict(T.Status(i));
end
T.statusNums = statusNums;


%% Delete unused variables 

T = removevars(T, ["Party","Family","Unit","Side","Generation","Status","State", "FirstName", "LastName"]);
 