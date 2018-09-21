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
    extern __shared__ int d_blockMemmory[];
    d_blockMemmory[threadIdx.x] = sum;
    sum =0;
    __syncthreads();


    if(threadIdx.x == 0)
    {
        for(int i =0; i<numberOfThreadsPerBlock;i++)
        {
            sum = sum+ d_blockMemmory[i];
        }
        d_global[blockIdx.x] = sum;
    }
}
void parallelReduceHost(int *h_array ,int *d_array ,int numberOfElements,int elementsPerThread , int numberOfThreadsPerBlock , int numberOfBlocks)
{
    int *d_global;
    cudaMalloc(&d_global, sizeof(int)*numberOfBlocks);


    parallelReduction<<<numberOfBlocks,numberOfThreadsPerBlock,numberOfThreadsPerBlock*sizeof(int)>>> (d_array,numberOfElements,elementsPerThread,numberOfThreadsPerBlock,numberOfBlocks,d_global);

    int *h_global = new int[numberOfBlocks];
    cudaMemcpy(h_global,d_global,sizeof(int)*numberOfBlocks,cudaMemcpyDeviceToHost);
    int sum=0;

    for(int i=0;i<numberOfBlocks;i++)

    {
        sum = sum + h_global[i];
    }

    printf("\n%d",sum);
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
