First you need to run the python file in order to create the documents inside the path ~/documents

then you need to first compile the C++ code and the run this with this 2 command lines
g++ -std=c++11 read4CSV_readRealDocuments.cpp 
./a.out


This is teh files for creating and then reading the csv files in order to then us it on the CUDA code

T
Then you need to run the cuda code, for this you first have to run this command line for compiling and then to actually execute

nvcc calculateDistance2_newGroup.cu -std=c++11 -o averageGroups

./averageGroups
