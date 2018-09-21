#include<stdio.h>
#include<cuda.h>
#include<iostream>
#include<fstream>
#include<chrono>


using namespace std;
__global__ void parallelReduction(int *d_array , int numberOfElements, int elementsPerThread,int numberOfThreadsPerBlock,int numberOfBlocks,int *d_global)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x ;
    int sum = 0;

    int j=0;
    for(int i=index;i<numberOfElements;i = i+(numberOfBlocks*numberOfThreadsPerBlock))
    {
        sum = sum + d_array[i];
        j++;
    }
    d_global[index] = sum;
}

void parallelReduceHost(int *h_array ,int *d_array ,int numberOfElements,int elementsPerThread , int numberOfThreadsPerBlock , int numberOfBlocks)
{
    int *d_global;
    cudaMalloc(&d_global, sizeof(int)*numberOfBlocks*numberOfThreadsPerBlock);
    parallelReduction<<<numberOfBlocks,numberOfThreadsPerBlock>>>(d_array,numberOfElements,elementsPerThread,numberOfThreadsPerBlock,numberOfBlocks,d_global);
    int *d_global1;
    cudaMalloc(&d_global1,sizeof(int)*numberOfThreadsPerBlock*numberOfBlocks);
    parallelReduction<<<numberOfBlocks,numberOfThreadsPerBlock>>>(d_global,2560*64,elementsPerThread,64,80,d_global1);
    int *h_global = new int[64*80];
    cudaMemcpy(h_global,d_global1,sizeof(int)*64*80,cudaMemcpyDeviceToHost);
    int sum=0;
    for(int i=0;i<64*80;i++)
    {
            sum =sum+h_global[i];
    }
    cout<<sum;
}
int main()
{
   
    int numberOfElements;
    ifstream inFile;
    inFile.open("random");
    int x;
    int i=0;
    inFile >>x ;
    numberOfElements = x;
   int *h_array = new int[numberOfElements];
    while(inFile >> x)
    {
        h_array[i] = x;
        i++;
    }
    int *d_array;
    cudaMalloc(&d_array , sizeof(int)*numberOfElements);
    cudaMemcpy(d_array, h_array , sizeof(int)*numberOfElements, cudaMemcpyHostToDevice);
    //serialReduceHost(h_array, d_array ,numberOfElements);
    int elementsPerThread, numberOfBlocks , numberOfThreadsPerBlock;
   elementsPerThread = 0 ;
   numberOfThreadsPerBlock = 64;
   numberOfBlocks =2560;
    parallelReduceHost(h_array,d_array,numberOfElements,elementsPerThread,numberOfThreadsPerBlock ,numberOfBlocks);  


}   
