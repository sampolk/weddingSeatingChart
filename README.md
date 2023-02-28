# weddingSeatingChart
This repository contains MATLAB code to optimize my wedding's seating chart.  

Creating a seating chart is similar in spirit to the clustering problem in unsupervised learning. In particular, when creating a seating chart, one separates a long list of wedding guests into groups based on whom guests are likely to enjoy interacting with. In this code, I locate an "optimal" seating chart using a variant on the unsupervised _Spectral Clustering_ algorithm called _Constrained Spectral Clustering_. 

My implementation of Constrained Spectral Clustering for wedding seating chart creation operates as follows. 
 1. First, I calculate pairwise affinity between each pair of guests: a measurement that aims to quantify how much each pair of guests is expected to enjoy each other's company at my wedding. 
  2. Next, I create a graph from the pairwise affinity calculations above and take the eigendecomposition of its graph Laplacian. The first few eigenvectors calculated here tend to concentrate on regions within the original graph that have high intra-region edge affinity; i.e., groups of people who are likely to enjoy each other's company at my wedding. 
  3. Finally, I implement the Constrained K-Means clustering algorithm on these eigenvectors to generate a partition of the guests in my wedding into groups. I enforce minium and maximum cluster-size constraints in this step so that the right number of guests is assigned to each table. 
  
The resulting seating chart will consist of high intra-table affinity (i.e., I expect that any two guests assigned to the same table will enjoy each other's company). 

I relied on the following resources for this project. Please cite them (and this project) if you use this code (even if not for your own wedding). 
 1. Bradley, P. S., Bennett, K. P., & Demiriz, A. (2000). _Constrained k-means clustering_. Microsoft Research, Redmond, 20(0), 0.
 2. Von Luxburg, U. (2007). A tutorial on spectral clustering. Statistics and computing, 17, 395-416.
 3. Goldberg, A., Zhu, X., Singh, A., Xu, Z., & Nowak, R. (2009, April). Multi-manifold semi-supervised learning. In _Artificial intelligence and statistics_ (pp. 169-176). PMLR.
 4.  Sam Polk (2023). Constrained K-Means (https://www.mathworks.com/matlabcentral/fileexchange/117355-constrained-k-means), MATLAB Central File Exchange. Retrieved February 28, 2023. 
