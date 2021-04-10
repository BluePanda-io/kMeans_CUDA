#include <iostream>
#include <fstream>
#include <string>
#include <bits/stdc++.h>
#include <stdlib.h>
#include <stdio.h>


#define HANDLE_CUDA(e) (HandleCudaError(e, __FILE__, __LINE__ ))

static int HandleCudaError(cudaError_t e, const char *file, int line) {
    if (e != cudaSuccess) {
        printf("CudaError: %s in %s at line %d\n", cudaGetErrorString(e), file, line);
        return -1;
    } else {
    	return 0;
    }
}


using namespace std;


struct initialVariablesDoc
{
    int numDimsionsVector;
    int numDocuments;
    int numGroups;
};

initialVariablesDoc readDocumentForInitialVariables(int col, int row)
{

    int initialVariables[row];
    int i = 0;

    ifstream fin;
    int line;
    
    fin.open("documents/initialVariableDocuments.csv");
    fin>>line;
    
    while(!fin.eof()){
        initialVariables[i] = line;
        i += 1;

        fin>>line;
    }

    initialVariablesDoc result = {initialVariables[0],initialVariables[1],initialVariables[2]};

    return result;
}

int* readDocumentGroupGroundTruth(int col, int row)
{
    int* groupGroundTruth = new int[row];
    int i = 0;

    ifstream fin;
    int line;
    
    fin.open("documents/groupGroundTruth.csv");
    fin>>line;
    
    while(!fin.eof()){
        groupGroundTruth[i] = line;
        i += 1;

        fin>>line;
    }

    return groupGroundTruth;
}

float** readVectorDucment(int col, int row)
{
    float** vectorsDocuments = new float*[row];
    int i = 0;

    ifstream fin;
    string line;
    
    fin.open("documents/vectorsDocuments.csv");
    fin>>line;
    
    while(!fin.eof()){
        vectorsDocuments[i] = new float[col];

        // vectorsDocuments[i] = line;
        vectorsDocuments[i][0] = 5;
        vectorsDocuments[i][1] = 10;
        

        // cout<<"This is the line = "<<line<<endl;


        stringstream ss(line);
        int j=0;
        while (ss.good()) {
            string substr;
            getline(ss, substr, ',');
            // v.push_back(substr);
            vectorsDocuments[i][j] = stof(substr);
            // cout<<"hello = "<<substr<<endl;
            j++;
        }




        i += 1;

        fin>>line;
    }

    return vectorsDocuments;
}

void saveDocument(string file, int* groupGroundTruth,int numDocuments)
{
    std::ofstream myfile;
    myfile.open (file);
    

    for (int i = 0; i < numDocuments; ++i)
    {
        // cout<<groupGroundTruth[i]<<endl;
        myfile<<groupGroundTruth[i]<<endl;

    }
    myfile.close();
}

__global__ void averagePointGroups (int *groupGroundTruth, float *vectorsDocuments,float *sum, int *n,int numDocuments, int numDimsionsVector, int numGroups)
{
    int i; // This is for the Documents
    int j = threadIdx.x; // The Groups
    int k; // This is for the Vector


    for (k=0;k<numDimsionsVector;k++){
        sum[k+numDimsionsVector*j] = 0;
    }
    n[j] = 0;

    __syncthreads();


    for (i=0;i<numDocuments;i++)
    {
        if (groupGroundTruth[i] == j)
        {
            for (k=0;k<numDimsionsVector;k++){
                sum[k+numDimsionsVector*j] += vectorsDocuments[k+numDimsionsVector*i];
            }
            n[j]++;
        }
    }

    __syncthreads();


    for (k=0;k<numDimsionsVector;k++){
        sum[k+numDimsionsVector*j] = sum[k+numDimsionsVector*j]/n[j];
        // printf("xronia pola moro mou averagePoint = %d   %d  %d  %f  \n",k,j,n[j],sum[k+numDimsionsVector*j]);

    }




}


__global__ void calc_distance (float *vectorsDocuments,float *meanGroups,float *distance, int numDocuments, int numDimsionsVector, int numGroups)
{
    int i = blockIdx.x; // This is for the Documents
    int j = threadIdx.x; // The Groups
    int k; // This is for the Vector


    float total  = 0.0;
    float diff  = 0.0;
    for (k=0;k<numDimsionsVector;k++){
        diff = (vectorsDocuments[k+i*numDimsionsVector] - meanGroups[k+j*numDimsionsVector]);
        total += diff*diff;
    }
    distance[i+j*numDocuments]=total;

}


__global__ void findNewGroup (float *distance, int *groupGroundTruth, int numDocuments, int numDimsionsVector, int numGroups)
{
    int i= blockIdx.x; // This is for the Documents
    int j;  // The Groups
    // int k; // This is for the Vector


    float minDist;

    j = 0;
    minDist = distance[i+j*numDocuments];
    groupGroundTruth[i] = j;
    
    for (j=0;j<numGroups;j++)
    {
        // printf(" This is cool resutls = %d %d  %d  %d %f \n",i,j,i+j*numDocuments,numDocuments,distance[i+j*numDocuments]);
        if (minDist>distance[i+j*numDocuments])
        {   
            minDist = distance[i+j*numDocuments];
            groupGroundTruth[i] = j;
        } 
    }
    

}


int main(int argc, char** argv)
{

    // cout<<"This is the argv my friendo = "<<argv[1]<<endl;
    // ------------------------------ Read the Files ----------------------
    // initVar -> The initial Variables initVar.numDimsionsVector ...
    // groupGroundTruth -> The group Ground thruth in order to calcualte the average
    // vectorsDocuments-> The actual vercotrs of the documetns to calculate the average

    initialVariablesDoc initVar;
    initVar = readDocumentForInitialVariables(1,3);
    int* groupGroundTruth = readDocumentGroupGroundTruth(1,initVar.numDocuments);
    float** vectorsDocuments = readVectorDucment(initVar.numDimsionsVector,initVar.numDocuments);
    // ------------------------------ Read the Files ----------------------


    float *sum_d; // [vector,groups] -> summation of all the vector for Each Group 
    float sum_h[initVar.numGroups*initVar.numDimsionsVector];
    float sum_h_TEST[initVar.numGroups*initVar.numDimsionsVector];


    int *n_d; // [groups,1] -> number of documetns that we added in each group
    int n_h[initVar.numGroups];
    int n_h_TEST[initVar.numGroups];

    int *groupGroundTruth_d; 
    float *vectorsDocuments_d;


    float *distance_d; // [Documents,groups] -> summation of all the vector for Each Group 
    float distance_h[initVar.numDocuments*initVar.numGroups];



    // ---------------- Translate 2D to 1D ---------------- 
    float *vectorsDocuments1D = (float*)malloc(sizeof(float)*initVar.numDocuments*initVar.numDimsionsVector);
    int coun1DVec = 0;
    for (int i = 0; i < initVar.numDocuments; ++i)
    {
        for (int j = 0; j < initVar.numDimsionsVector; ++j)
        {
            vectorsDocuments1D[coun1DVec] = vectorsDocuments[i][j];
            coun1DVec++;
        }
    }

    // ---------------- Translate 2D to 1D ---------------- 

    // cout<<"This the number of Documents Each Group ----------- "<<endl;
    // for (int i = 0; i < 15; ++i)
    // {
    //     cout<<groupGroundTruth[i]<<endl;
    // }

    // ------------------ TEST the SUM --------------
    int i; // This is for the Documents
    int j; // The Groups
    int k; // This is for the Vector

    for (j=0;j<initVar.numGroups;j++)
    {
        for (k=0;k<initVar.numDimsionsVector;k++){
            sum_h_TEST[k+initVar.numDimsionsVector*j] = 0;
        }
        n_h_TEST[j] = 0;



        for (i=0;i<initVar.numDocuments;i++)
        {
            if (groupGroundTruth[i] == j)
            {
                for (k=0;k<initVar.numDimsionsVector;k++){
                    sum_h_TEST[k+initVar.numDimsionsVector*j] += vectorsDocuments1D[k+initVar.numDimsionsVector*i];
                }
                n_h_TEST[j]++;
            }
        }


        for (k=0;k<initVar.numDimsionsVector;k++){
            sum_h_TEST[k+initVar.numDimsionsVector*j] = sum_h_TEST[k+initVar.numDimsionsVector*j]/n_h_TEST[j];

        }

    }
    cout<<" The test of the HOST for the sum -----------"<<endl;
    for (int i = 0; i < initVar.numGroups; ++i)
    {
        for (int j = 0; j < initVar.numDimsionsVector; ++j)
        {
            cout<<sum_h_TEST[j+i*initVar.numDimsionsVector]<<" ";
        }
        cout<<endl;
    }
    // ---------------------------------------------------


    // ---------------- cudaMalloc -------------
    HANDLE_CUDA(cudaMalloc(( void **) &sum_d,initVar.numGroups*initVar.numDimsionsVector*sizeof(float)));
    HANDLE_CUDA(cudaMalloc(( void **) &sum_h,initVar.numGroups*initVar.numDimsionsVector*sizeof(float)));

    HANDLE_CUDA(cudaMalloc(( void **) &n_d,initVar.numGroups*sizeof(int)));
    HANDLE_CUDA(cudaMalloc(( void **) &n_h,initVar.numGroups*sizeof(int)));

    HANDLE_CUDA(cudaMalloc(( void **) &distance_d,initVar.numDocuments*initVar.numGroups*sizeof(float)));
    HANDLE_CUDA(cudaMalloc(( void **) &distance_h,initVar.numDocuments*initVar.numGroups*sizeof(float)));
    

    HANDLE_CUDA(cudaMalloc(( void **) &groupGroundTruth_d,initVar.numDocuments*sizeof(int)));
    HANDLE_CUDA(cudaMalloc(( void **) &vectorsDocuments_d,initVar.numDocuments*initVar.numDimsionsVector*sizeof(float)));
    // ---------------- cudaMalloc -------------

    // ---------------- cudaMemcpy  - HostToDevice -------------
    HANDLE_CUDA(cudaMemcpy(groupGroundTruth_d,groupGroundTruth,initVar.numDocuments*sizeof(int),cudaMemcpyHostToDevice));
    HANDLE_CUDA(cudaMemcpy(vectorsDocuments_d,vectorsDocuments1D,initVar.numDocuments*initVar.numDimsionsVector*sizeof(float),cudaMemcpyHostToDevice));

    HANDLE_CUDA(cudaMemcpy(sum_d,sum_h,initVar.numGroups*initVar.numDimsionsVector*sizeof(float),cudaMemcpyHostToDevice));

    HANDLE_CUDA(cudaMemcpy(n_d,n_h,initVar.numGroups*sizeof(int),cudaMemcpyHostToDevice));

    HANDLE_CUDA(cudaMemcpy(distance_d,distance_h,initVar.numDocuments*initVar.numGroups*sizeof(float),cudaMemcpyHostToDevice));

    // ---------------- cudaMemcpy  - HostToDevice  -------------


    // ---------------- kMeans Algorithm on CUDA code -------------
    int iter;
    long arg = strtol(argv[1], NULL, 10);
    for (iter = 0; iter<int(arg);iter++)
    {
        averagePointGroups<<<1,initVar.numGroups>>>(groupGroundTruth_d,vectorsDocuments_d,sum_d,n_d,initVar.numDocuments,initVar.numDimsionsVector,initVar.numGroups);

        calc_distance<<<initVar.numDocuments,initVar.numGroups>>>(vectorsDocuments_d,sum_d,distance_d,initVar.numDocuments,initVar.numDimsionsVector,initVar.numGroups);

        findNewGroup<<<initVar.numDocuments,1>>>(distance_d,groupGroundTruth_d,initVar.numDocuments,initVar.numDimsionsVector,initVar.numGroups);

    }
    // ---------------- kMeans Algorithm on CUDA code -------------



    // ---------------- cudaMemcpy  - DeviceToHost  -------------
    HANDLE_CUDA(cudaMemcpy(sum_h,sum_d,initVar.numGroups*initVar.numDimsionsVector*sizeof(float),cudaMemcpyDeviceToHost));
    HANDLE_CUDA(cudaMemcpy(n_h,n_d,initVar.numGroups*sizeof(int),cudaMemcpyDeviceToHost));

    HANDLE_CUDA(cudaMemcpy(distance_h,distance_d,initVar.numDocuments*initVar.numGroups*sizeof(float),cudaMemcpyDeviceToHost));

    HANDLE_CUDA(cudaMemcpy(groupGroundTruth,groupGroundTruth_d,initVar.numDocuments*sizeof(float),cudaMemcpyDeviceToHost));
    // ---------------- cudaMemcpy  - DeviceToHost  -------------

    cout.setf(ios::fixed,ios::floatfield);
    cout.precision(3);



    cout<<"This the Average of Each Group -----------"<<endl;
    for (int i = 0; i < initVar.numGroups; ++i)
    {
        for (int j = 0; j < initVar.numDimsionsVector; ++j)
        {
            cout<<sum_h[j+i*initVar.numDimsionsVector]<<" ";
        }
        cout<<endl;
    }

    


    cout<<"This the number of Documents Each Group ----------- "<<endl;
    // for (int i = 0; i < 4; ++i)
    // {
    //     cout<<groupGroundTruth[i]<<endl;
    // }

    saveDocument("documents/groupGroundTruth2.csv",groupGroundTruth,initVar.numDocuments);

    // cout<<"Group of Every Document ----------- "<<endl;
    // for (int i = 0; i < initVar.numGroups; ++i)
    // {
       
    //     cout<<n_h[i]<<endl;

    // }

    // cout.setf(ios::fixed,ios::floatfield);
    // cout.precision(1);

    cout<<"This the Average of Each Group ----------- "<<endl;
    // for (int i = 0; i < 2; ++i)
    for (int i = 0; i < initVar.numGroups; ++i)
    {
        for (int j = 0; j < initVar.numDocuments; ++j)
        // for (int j = 0; j < 2; ++j)
        {
            cout<<distance_h[j+i*initVar.numDocuments]<<" ";
        }
        cout<<endl;
    }


    // ------------ Free Memory -----------
    // free(sum_h);
    // free(n_h);
    // free(distance_h);
    // free(groupGroundTruth);


    // HANDLE_CUDA(cudaFree(sum_d));
    // HANDLE_CUDA(cudaFree(n_d));
    // HANDLE_CUDA(cudaFree(distance_d));
    // HANDLE_CUDA(cudaFree(groupGroundTruth_d));
    // HANDLE_CUDA(cudaFree(vectorsDocuments_d));
    // HANDLE_CUDA(cudaFree(sum_d));

    // ------------ Free Memory -----------




    return 0;
}