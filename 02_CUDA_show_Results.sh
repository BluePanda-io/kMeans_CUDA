echo "Number of Loops for Kmeans: "  
read numLdoops  

nvcc kMeans_Distance_groups.cu -std=c++11 -o kMeansProgram

./kMeansProgram $numLdoops

python Display2ReadDocuments.py 