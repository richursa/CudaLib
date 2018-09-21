#include<stdio.h>
#include<cuda.h>
#include<iostream>
#include<fstream>
#include<chrono>


using namespace std;

__global__ void serialReduction(int *d_array, int numberOfElements)
{
    int sum = 0;
    for(int i=0;i<numberOfElements;i++)
    {
        sum = sum + d_array[i];
    }
    printf("%d",sum);
}



void serialReduceHost(int *h_array,int *d_array, int numberOfElements)
{
    
    serialReduction<<<1,1>>>(d_array,numberOfElements);
    cudaDeviceSynchronize();
    fflush(stdout);

}
__global__ void parallelReduction(int *d_array , int numberOfElements, int elementsPerThread,int numberOfThreadsPerBlock,int numberOfBlocks,int *d_global)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x ;
    index = index * elementsPerThread;

    if(index>numberOfElements)
    {
        return;
    }

    int sum = 0;

    for(int i=index;i<index+elementsPerThread;i++)
    {
        sum = sum + d_array[i];
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
void serialReduceCpu(int *d_array , int numberOfElements)
{
    int sum =0;
    for(int i=0;i<numberOfElements;i++)
    {
        sum = sum+d_array[i];
    }
    cout<<"\n"<<sum;
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
   elementsPerThread = 256 ;
   numberOfThreadsPerBlock = 64;
   numberOfBlocks =6400;
    parallelReduceHost(h_array,d_array,numberOfElements,elementsPerThread,numberOfThreadsPerBlock ,numberOfBlocks);
    serialReduceCpu(h_array , numberOfElements);    


}   




//    freopen("random", "r", stdin);