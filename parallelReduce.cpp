#include<iostream>
#include<stdio.h>
#include<time.h>
#include<omp.h>
using namespace std;
int parallelReduce(int *d_array ,int startIndex , int lastIndex)
{

    if(startIndex == lastIndex)
    {
        return d_array[startIndex];
    }
    else
    {
        int mid = (startIndex + lastIndex)/2;
        int val1,val2;
        
        val1 = parallelReduce(d_array,startIndex,mid);
        val2 = parallelReduce(d_array,mid+1,lastIndex);
        return val1 + val2;
    }
}
int main()
{
   omp_set_dynamic(0);
   omp_set_num_threads(4);
    int NUMBER_OF_ELEMENTS;
    cin>>NUMBER_OF_ELEMENTS;
    double start , end,cpu_time_used;
    int *d_array = new int[NUMBER_OF_ELEMENTS];
    for(int i=0;i<NUMBER_OF_ELEMENTS;i++)
    {
        scanf("%d",&d_array[i]);
    }
    start = omp_get_wtime();
    int d_sum, d_sum1;
    // #pragma omp parallel 
     {
     d_sum = parallelReduce(d_array,0,(NUMBER_OF_ELEMENTS-1)/2);
     d_sum1 = parallelReduce(d_array,((NUMBER_OF_ELEMENTS-1)/2)+1 , NUMBER_OF_ELEMENTS-1);
     }
    end = omp_get_wtime();
    cpu_time_used = end - start;
    cout<<d_sum+d_sum1;
    cout<<"\n time taken is "<<cpu_time_used;
    
}

