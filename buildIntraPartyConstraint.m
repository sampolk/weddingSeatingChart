function [A,b] = buildIntraPartyConstraint(partyNums, numTables)
% Builds constraints to ensure that each 

numGuests = length(partyNums); % Number of guests we are grouping
numParties = max(partyNums); % Number of parties we are ensuring stay together

% Preallocate memory for constraints
A = zeros(numParties, numTables*numGuests);
b = zeros(numParties, 1);

for party = 1:numParties

    % Find all guests within this party. 
    partyIdx = find(partyNums == party);
    partySize = length(partyIdx);

    if partySize>1
        % If more than one guest is in this party, we apply a constraint to
        % ensure that they are put on the same table. 

        for table = 1:numTables

            % Indicate that these guests must be put together at any table
            A(party, numGuests*(table-1) + partyIdx) = 1;
            b(party) = length(partyIdx);
        
        end
    end
end

% Get rid of vaccuous constraints
A = A(b>0,:);
b=  b(b>0);

A = sparse(A);






