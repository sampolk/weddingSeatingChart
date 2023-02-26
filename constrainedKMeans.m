function [labels,centroids] = constrainedKMeans(X, K, lb, ub, maxiter)
%{
Implements the constrained K-Means algorithm. This algorithm is a
balance-driven version of the canonical K-Means clustering algorithm. It
enforces a constraint that clusters have some minimum size. This script, in
particular, implements Algorithm 2.2 from the following paper: 
    - Bradley, P. S., Bennett, K. P., & Demiriz, A. (2000). Constrained 
      K-means Clustering. Microsoft Research, Redmond, 20(0), 0.
Inputs: 
    - X:        Data matrix with shape (n,D), where X(i,:) is the ith data 
                point in the dataset. 
    - K:        Desired number of clusters (integer greater than 1). 
    - lb:       length-K vector of integers greater than 1, with tau(k)  
                storing the minimum number of data points in cluster k. 
    - ub:       length-K vector of integers greater than 1, with tau(k)  
                storing the maximum number of data points in cluster k. 
    - maxiter:  Maximum number of iterations.
Outputs:
    labels:     Unsupervised cluster labels. labels(i) = k iff data point 
                i is in cluster k. 
    centroids:  Matrix with shape (K,D), where centroids(k,:) is the 
                centroid of data points with label=k in labels. 
Written by Sam Polk (MITLL, 03-39) on 9/8/22. 
Edited by Sam Polk (MITLL, 03-39) on 2/26/23 to allow for upper bound.
%}
% Extract dataset size information
[n,D] = size(X);
% Parse inputs to algorithm
if nargin == 2
    lb = min(0.05*n, 0.5*n/K)*ones(K,1);
    ub = Inf*ones(K,1);
    maxiter = 100;
elseif nargin == 4
    maxiter=100;
end
% Assign initial clusters and centroids
labels = randi(K,n,1);
centroids = zeros(K,D);
for k = 1:K
    centroids(k,:) = mean(X(labels==k,:));
end
% Variable needed for while-loop.
iter = 1; % Used to ensure that we not exceed maxiter iterations. 
while iter<maxiter  
    
    % Below is our objective function. By default, this script uses 
    objectiveFunction = reshape(0.5*pdist2(X, centroids).^2, [n*K,1]); % Squared Euclidean distance between data points and centroids, vectorized
    % Ensure at most one cluster to be assigned to each point:  
    % A1 has exactly n*K nonzero entries in a (n,n*K) matrix.
    A1 = sparse(repmat((1:n)',1,K),  reshape(1:K*n, [n,K]), ones(n, K));
    b1 = ones(n,1); 
    % Ensure at least one cluster to be assigned to each point: 
    % A2 has exactly n*K nonzero entries in a (n,n*K) matrix.
    A2 = sparse(repmat((1:n)',1,K),  reshape(1:K*n, [n,K]), -ones(n, K));
    b2 = -ones(n,1); 
    % Enforce minimum cluster size constraint:
    % A3 has exactly n*K nonzero entries in a (K,n*K) matrix.
    A3 = sparse(reshape(repmat((1:K)', 1,n)', [n*K,1]),1:n*K, -ones(1,n*K)); 
    b3 = -lb; 
    % Enforce maximum cluster size constraint:
    % A4 has exactly n*K nonzero entries in a (K,n*K) matrix.
    A4 = sparse(reshape(repmat((1:K)', 1,n)', [n*K,1]),1:n*K, ones(1,n*K)); 
    b4 = ub; 
 
    % Run linear program to get new cluster assignments
    T = intlinprog(objectiveFunction, 1:n*K, [A1; A2; A3; A4], [b1; b2; b3; b4], [], [], zeros(n*K,1), ones(n*K,1));
    [~, labelsNew] = max(reshape(T,n,K), [], 2);
    % Assign new centroids:  
    centroidsNew = zeros(K,D);
    for k = 1:K
        centroidsNew(k,:) = mean(X(labelsNew == k,:));
    end
    % Compare centroids from prior iteration and current iteration. 
    % The following condition will be true if labels do not change across
    % an iteration. We stop in this case and output the current labels.
    if sum(diag(pdist2(centroids, centroidsNew)) == zeros(K,1)) == 2 % True if centroids do not change. 
        labels = labelsNew;
        centroids = centroidsNew;
        break
    else
        % Take current centroids and move to next iteration.
        centroids = centroidsNew;
        iter = iter+1;
    end
end
        
