#include<iostream>
#include "random.h"
using namespace std;
__global__ void hillisSteeleScanDevice(int *d_array , int numberOfElements, int *d_tmpArray,int moveIndex)
{
    int index = threadIdx.x + blockDim.x * blockIdx.x;
    if(index > numberOfElements)
    {
        return;
    }
    if(index - moveIndex >=0)
    {
        d_tmpArray[index] = d_tmpArray[index] +d_array[index - moveIndex];
    }
    
}
void hillisSteeleScanHost(int *h_array,int numberOfElements)
{
    int *d_array;
    cudaMalloc(&d_array,sizeof(int)*numberOfElements);
    cudaMemcpy(d_array,h_array,sizeof(int)*numberOfElements,cudaMemcpyHostToDevice);
    int *d_tmpArray;
    cudaMalloc(&d_tmpArray,sizeof(int)*numberOfElements);
    for(int j=1;j<numberOfElements;j= j*2)
    {   cudaMemcpy(d_tmpArray,d_array,sizeof(int)*numberOfElements,cudaMemcpyDeviceToDevice);
        hillisSteeleScanDevice<<<1600,500>>>(d_array,numberOfElements,d_tmpArray, j);
        cudaMemcpy(d_array,d_tmpArray,sizeof(int)*numberOfElements,cudaMemcpyDeviceToDevice);
    }
    cudaMemcpy(h_array,d_array ,sizeof(int)*numberOfElements,cudaMemcpyDeviceToHost);
}

int main()
{
    cout<<"enter the number of numbers ";
    int numberOfElements;
    cin>>numberOfElements;
    int *h_array = new int[numberOfElements];
    class random a(h_array,numberOfElements);
    hillisSteeleScanHost(h_array,numberOfElements);
}
