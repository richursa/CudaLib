#include<iostream>
#include<stdio.h>
#include "random.h"
using namespace std;
__device__ int function(int value , int bit ,int bitset)
{
    if(bitset == 1 )
    {
        if((value & bit)  != 0)
        {
            return 1;
        }
        else 
            return 0;
    }
    else
    {
        if((value & bit) == 0)
        {
            return 1;
        }
        else 
        {
            return 0;
        }
    }
}
__global__ void predicateDevice(int *d_array , int *d_predicateArrry , int d_numberOfElements,int bit,int bitset)
{
    int index = threadIdx.x + blockIdx.x*blockDim.x;
    if(index < d_numberOfElements)
    {
    
           d_predicateArrry[index] = function(d_array[index],bit,bitset);
    }
}

__global__ void scatter(int *d_array , int *d_scanArray , int *d_predicateArrry,int * d_scatteredArray ,int d_numberOfElements,int offset)
{
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    if(index < d_numberOfElements)
    {
        if(d_predicateArrry[index] == 1)
        {
           // printf(" foundeed at index = %d val = %d\n",index,d_array[index]);
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
    int *d_tmpArray1;
    cudaMalloc(&d_tmpArray1,sizeof(int)*numberOfElements);
    cudaMalloc(&d_tmpArray,sizeof(int)*numberOfElements);
    cudaMemcpy(d_tmpArray1,d_scanArray,sizeof(int)*numberOfElements,cudaMemcpyDeviceToDevice);
    int j,k=0;
    for(j=1;j<numberOfElements;j= j*2,k++)
    {
        if(k%2 == 0)
        {
            hillisSteeleScanDevice<<<1600,500>>>(d_tmpArray1,numberOfElements,d_tmpArray, j);
            cudaDeviceSynchronize();
        }
        else
        {
            hillisSteeleScanDevice<<<1600,500>>>(d_tmpArray,numberOfElements,d_tmpArray1, j);
            cudaDeviceSynchronize();
        }
    } 
    cudaDeviceSynchronize();
    if(k%2 == 0)
    {
        
        return d_tmpArray1;
    }
    else
    {
        return d_tmpArray;
    }
}
__global__ void print(int *d_predicateArrry,int numberOfElements)
{
    
    for(int i=0;i<numberOfElements;i++)
    {
        printf("index = %d value = %d\n",i,d_predicateArrry[i]);
    }
}

int *compact(int *d_array,int numberOfElements,int bit)
{   
    int offset;
    int *d_predicateArrry;
    cudaMalloc((void**)&d_predicateArrry,sizeof(int)*numberOfElements);
    predicateDevice<<<1600,500>>>(d_array,d_predicateArrry,numberOfElements,bit,0);
    int *d_scanArray;
    d_scanArray = hillisSteeleScanHost(d_predicateArrry,numberOfElements);
    int *d_scatteredArray;
    cudaMalloc((void**)&d_scatteredArray,sizeof(int)*numberOfElements);
    //cout<<"offset = "<<offset<<"\n";
    scatter<<<1600,500>>>(d_array,d_scanArray,d_predicateArrry,d_scatteredArray, numberOfElements,0);
    cudaMemcpy(&offset,d_scanArray+numberOfElements-1,sizeof(int),cudaMemcpyDeviceToHost);
    predicateDevice<<<1600,500>>>(d_array,d_predicateArrry,numberOfElements,bit,1);
    d_scanArray = hillisSteeleScanHost(d_predicateArrry,numberOfElements);
    scatter<<<1600,500>>>(d_array,d_scanArray,d_predicateArrry,d_scatteredArray, numberOfElements,offset);
    return d_scatteredArray;
}
int *compact2(int *d_array,int numberOfElements,int bit)
{
    int offset;
    int *d_predicateArrry;
    cudaMalloc((void**)&d_predicateArrry,sizeof(int)*numberOfElements);
    predicateDevice<<<1600,500>>>(d_array,d_predicateArrry,numberOfElements,bit,1);
    int *d_scanArray;
    d_scanArray = hillisSteeleScanHost(d_predicateArrry,numberOfElements);
    int *d_scatteredArray;
    cudaMalloc((void**)&d_scatteredArray,sizeof(int)*numberOfElements);
    //cout<<"offset = "<<offset<<"\n";
    scatter<<<1600,500>>>(d_array,d_scanArray,d_predicateArrry,d_scatteredArray, numberOfElements,0);
    cudaMemcpy(&offset,d_scanArray+numberOfElements-1,sizeof(int),cudaMemcpyDeviceToHost);
    predicateDevice<<<1600,500>>>(d_array,d_predicateArrry,numberOfElements,bit,0);
    d_scanArray = hillisSteeleScanHost(d_predicateArrry,numberOfElements);
    scatter<<<1600,500>>>(d_array,d_scanArray,d_predicateArrry,d_scatteredArray, numberOfElements,offset);
    return d_scatteredArray;
}
int offset;
int *positivenegativesplit(int *d_array,int numberOfElements,int bit,int bitset)
{   
    int *d_predicateArrry;
    cudaMalloc((void**)&d_predicateArrry,sizeof(int)*numberOfElements);
    predicateDevice<<<1600,500>>>(d_array,d_predicateArrry,numberOfElements,bit,bitset);
    int *d_scanArray;
    d_scanArray = hillisSteeleScanHost(d_predicateArrry,numberOfElements);
    int *d_scatteredArray;
    cudaMemcpy(&offset,d_scanArray+numberOfElements-1,sizeof(int),cudaMemcpyDeviceToHost);
    cudaMalloc((void**)&d_scatteredArray,sizeof(int)*offset);
    //cout<<"offset = "<<offset<<"\n";
    scatter<<<1600,500>>>(d_array,d_scanArray,d_predicateArrry,d_scatteredArray, numberOfElements,0);
    return d_scatteredArray;
}
int * radixSort(int *d_array , int numberOfElements)
{
    int bit;
    int *d_negativeArray = positivenegativesplit(d_array,numberOfElements,1L<<31,1);
    for(int i=0;i<sizeof(int)*8;i++)
    {
        bit = 1<<i;
        d_negativeArray = compact2(d_negativeArray,offset,bit);
    }
    int *d_postiveArray = positivenegativesplit(d_array,numberOfElements,1L<<31,0);
    for(int i=0;i<sizeof(int)*8;i++)
    {
        bit = 1<<i;
        d_postiveArray = compact(d_postiveArray,offset,bit);
    }
    cudaMemcpy(d_array,d_negativeArray,sizeof(int)*(numberOfElements-offset),cudaMemcpyDeviceToDevice);
    cudaMemcpy(d_array+(numberOfElements-offset),d_postiveArray,sizeof(int)*offset,cudaMemcpyDeviceToDevice);
    return d_array;
}
int main()
{
    cout<<"enter the number of elements \n";
    int numberOfElements;
    cin>>numberOfElements;
    int *h_array  = new int[numberOfElements];
    //class random a(h_array,numberOfElements);
    for(int i=0;i<numberOfElements;i++)
    {
        cin>>h_array[i];
    }
    int *d_array;
    cudaMalloc((void**)&d_array ,sizeof(int)*numberOfElements);
    cudaMemcpy(d_array,h_array,sizeof(int)*numberOfElements,cudaMemcpyHostToDevice);
    d_array = radixSort(d_array, numberOfElements);
    cudaMemcpy(h_array,d_array,sizeof(int)*numberOfElements,cudaMemcpyDeviceToHost);
    for(int i=0;i<numberOfElements;i++)
    {
        cout<<h_array[i]<<"\n";
    }
}
