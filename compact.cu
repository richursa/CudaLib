#include<iostream>
#include<stdio.h>
#include "random.h"
#include<conio.h>
using namespace std;
int h_sizeOfCompactedArray;
__global__ void scatter(int *d_array , int *d_predicateArray, int *d_scanArray,int *d_compactedArray, int d_numberOfElements)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if(index < d_numberOfElements)
    {
        if(d_predicateArray[index]==1)
        {
            d_compactedArray[d_scanArray[index]-1] = d_array[index];
        
        }
    }
}

__global__ void predicate(int *d_array, int d_numberOfElements,int *d_predicateArray)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    if(index <d_numberOfElements)
    {
        if(d_array[index]%32== 0)
        {
            d_predicateArray[index] =1;
        }
        else
        {
            d_predicateArray[index]  = 0;
        }
    }
}

__global__ void hillisSteeleScanDevice(int *d_predicateArray , int d_numberOfElements ,int *d_tmpArray,int d_offset)
{
    int index = blockIdx.x * blockDim.x +  threadIdx.x;
    if(index < d_numberOfElements)
    {
        d_tmpArray[index] = d_predicateArray[index];
        if(index - d_offset >= 0)
            {
            
             d_tmpArray[index] = d_predicateArray[index] + d_predicateArray[index-d_offset];
            }
    }
}
void hillisSteeleScanHost(int *d_predicateArray,int h_numberOfElements)
{
    int k=0;
    int *d_tmpArray;
    cudaMalloc(&d_tmpArray,sizeof(int)*h_numberOfElements);
    for(int j=1;j<h_numberOfElements;j= j*2,k++)
    {
        if(k%2==0)
        {
            hillisSteeleScanDevice<<<1600,500>>>(d_predicateArray,h_numberOfElements,d_tmpArray,j);
        }
        else
        {
            hillisSteeleScanDevice<<<1600,500>>>(d_tmpArray,h_numberOfElements,d_predicateArray,j);
        }
        
    }
    if(k%2==0)
    {
        
    }
    else
    {
        d_predicateArray = d_tmpArray;
    }
}

void normalPredicarte(int *h_array, int h_numberOfElements)
{
    cout<<"\ncpu muwth\n";
    int j=0;
    for(int i=0;i<h_numberOfElements;i++)
    {
        if(h_array[i]%32 == 0)
        {
            cout<<h_array[i]<<"\n";
            j++;
        }
    }
    
        cout<<"\n size of compact cpu "<<j<<"\n";
        h_sizeOfCompactedArray = j;
    cout<<"gpu freak\n";
}
int main()
{
    cout<<"enter the number of elements";
    int h_numberOfElements;
    cin>>h_numberOfElements;
    int *h_array = new int[h_numberOfElements];
    class random a(h_array,h_numberOfElements);
    normalPredicarte(h_array,h_numberOfElements);
    int *d_array;
    cudaMalloc(&d_array,sizeof(int)*h_numberOfElements);
    cudaMemcpy(d_array,h_array,sizeof(int)*h_numberOfElements,cudaMemcpyHostToDevice);
    int *d_predicateArray;
    cudaMalloc(&d_predicateArray,sizeof(int)*h_numberOfElements);
    int *d_scanArray;
    cudaMalloc(&d_scanArray,sizeof(int)*h_numberOfElements);
    predicate<<<1600 ,500>>>(d_array,h_numberOfElements,d_predicateArray);
    cudaMemcpy(d_scanArray,d_predicateArray,sizeof(int)*h_numberOfElements,cudaMemcpyDeviceToDevice);
    hillisSteeleScanHost(d_scanArray,h_numberOfElements);
    int *d_compactedArray;
    //int h_sizeOfCompactedArray;
   // cudaMemcpy(&h_sizeOfCompactedArray,&d_scanArray[h_numberOfElements-2],sizeof(int),cudaMemcpyDeviceToHost);
    cout<<"\nsize of compacted array "<<h_sizeOfCompactedArray<<"\n";
    cudaMalloc(&d_compactedArray,sizeof(int)*h_sizeOfCompactedArray);
    scatter<<<1600,500>>>(d_array,d_predicateArray,d_scanArray,d_compactedArray,h_numberOfElements);
    int *h_compactedArray = new int[h_sizeOfCompactedArray];
    cudaMemcpy(h_compactedArray,d_compactedArray,sizeof(int)*h_sizeOfCompactedArray,cudaMemcpyDeviceToHost);
    for(int i=0;i<h_sizeOfCompactedArray;i++)
        {
         cout<<h_compactedArray[i]<<"\n";
        }
    cout<<"scanarray is \n";
    fflush(stdin);
    cudaDeviceSynchronize();
    cudaMemcpy(h_array,d_scanArray,sizeof(int)*h_numberOfElements,cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize();
    getch();

}
/*int main()
{
    int d_numberOfElements;
    cin>>d_numberOfElements;
    int *h_array = new int[d_numberOfElements];
    for(int i=0;i<d_numberOfElements;i++)
    {
        h_array[i]  = i;
    }
    int *d_array;
    cudaMalloc(&d_array,sizeof(int)*d_numberOfElements);
    cudaMemcpy(d_array,h_array,sizeof(int)*d_numberOfElements,cudaMemcpyHostToDevice);
    hillisSteeleScanHost(d_array,d_numberOfElements);
    cudaMemcpy(h_array,d_array,sizeof(int)*d_numberOfElements,cudaMemcpyDeviceToHost);
    for(int i=0;i<d_numberOfElements;i++)
    {
        cout<<h_array[i]<<"\n";
    }
    getch();
}*/