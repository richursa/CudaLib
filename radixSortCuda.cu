#include<iostream>
#include<stdio.h>
using namespace std;
__global__ void predicateDevice(int *d_array , int *d_predicateArrry , int d_numberOfElements,int bit,int bitset)
{
    int index = threadIdx.x + blockIdx.x*blockDim.x;
    if(index < d_numberOfElements)
    {
        if(bitset == 0)
        {
            if((d_array[index] & bit) == 0)
             {
                d_predicateArrry[index] = 1;
             }
             else
             {
                d_predicateArrry[index] = 0;
             }
        }
        else
        {
            if((d_array[index] & bit) != 0)
            {
                d_predicateArrry[index] = 1;
            }
            else
            {
                d_predicateArrry[index] = 0;
            }
        }
    }
}
__global__ void scatter(int *d_array , int *d_scanArray , int *d_predicateArrry,int * d_scatteredArray ,int d_numberOfElements,int offset)
{
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    if(index < d_numberOfElements)
    {
        if(d_predicateArrry[index] == 1)
        {
            d_scatteredArray[d_scanArray[index] - 1 +offset ] = d_array[index];
        
        }
    }
}

__global__ void hillisSteeleScanDevice(int *d_array , int numberOfElements, int *d_tmpArray,int moveIndex)
{
    int index = threadIdx.x + blockDim.x * blockIdx.x;
    if(index > numberOfElements)
    {
        return;
    }
    d_tmpArray[index] = d_array[index];
    if(index - moveIndex >=0)
    {
        
        d_tmpArray[index] = d_tmpArray[index] +d_array[index - moveIndex];
    }
}
int* hillisSteeleScanHost(int *d_scanArray,int numberOfElements)
{
    int *d_tmpArray;
    cudaMalloc(&d_tmpArray,sizeof(int)*numberOfElements);
    int j,k=0;
    for(j=1;j<numberOfElements;j= j*2,k++)
    {
        if(k%2 == 0)
        {
            hillisSteeleScanDevice<<<100,256>>>(d_scanArray,numberOfElements,d_tmpArray, j);
        }
        else
        {
            hillisSteeleScanDevice<<<100,256>>>(d_tmpArray,numberOfElements,d_scanArray, j);
        }
    } 
    cudaDeviceSynchronize();
    if(k%2 == 0)
    {
        return d_scanArray;
    }
    else
    {
        return d_tmpArray;
    }
}

__global__ void getPos(int *d_scanArray , int d_numberOfElements,int *d_lastPos)
{
    *d_lastPos = d_scanArray[d_numberOfElements -1];
}
void radix(int *h_array , int numberOfElements,int numberOfThreads ,int numberOfBlocks)
{
    int *d_array ;
    cudaMalloc((void**)&d_array,sizeof(int)*numberOfElements);
    cudaMemcpy(d_array,h_array,sizeof(int)*numberOfElements,cudaMemcpyHostToDevice);
    int *d_predicateArrry;
    cudaMalloc((void**)&d_predicateArrry , sizeof(int)*numberOfElements);
    int *d_scanArray;
    cudaMalloc((void**)&d_scanArray,sizeof(int)*numberOfElements);
    int *d_scatteredArray;
    cudaMalloc((void**)&d_scatteredArray,sizeof(int)*numberOfElements);
    int *d_lastPos;
    cudaMalloc ((void**)&d_lastPos,sizeof(int));
    int *h_lastPos = new int[1];
    for(int i=0;i<8*sizeof(int);i++)
    {
        predicateDevice<<<numberOfBlocks,numberOfThreads>>>(d_array,d_predicateArrry,numberOfElements,1<<(i),0);
        cudaMemcpy(d_scanArray,d_predicateArrry,sizeof(int)*numberOfElements,cudaMemcpyDeviceToDevice);
        d_scanArray = hillisSteeleScanHost(d_scanArray,numberOfElements);
        scatter<<<numberOfBlocks,numberOfElements>>>(d_array,d_scanArray,d_predicateArrry,d_scatteredArray,numberOfElements,0);
        getPos<<<1,1>>>(d_scanArray,numberOfElements,d_lastPos);
        predicateDevice<<<numberOfBlocks,numberOfThreads>>>(d_array,d_predicateArrry,numberOfElements,1<<(i),1);
        cudaMemcpy(d_scanArray,d_predicateArrry,sizeof(int)*numberOfElements,cudaMemcpyDeviceToDevice);
        d_scanArray = hillisSteeleScanHost(d_scanArray,numberOfElements);
        cudaMemcpy(h_lastPos,d_lastPos,sizeof(int),cudaMemcpyDeviceToHost);
        scatter<<<numberOfBlocks,numberOfThreads>>>(d_array,d_scanArray,d_predicateArrry,d_scatteredArray,numberOfElements,(*h_lastPos));
        cudaMemcpy(d_array,d_scatteredArray,sizeof(int)*numberOfElements,cudaMemcpyDeviceToDevice);

    }
    cudaMemcpy(h_array,d_array,sizeof(int)*numberOfElements,cudaMemcpyDeviceToHost);
}


int main()
{
    cout<<"enter the numbre of element";
    int numberOfElements;
    cin>>numberOfElements;
    int *h_array = new int[numberOfElements];
    //class random a(h_array ,numberOfElements);
    for(int i=numberOfElements-1,k=0;i>=0;i--,k++)
    {
        h_array[k] = i;
    }
    radix(h_array,numberOfElements,256,100);
    cudaDeviceSynchronize();
    for(int i=0;i<numberOfElements;i++)
    {
        cout<<h_array[i]<<"\n";
    }
    
}