#include<iostream>
#include<stdio.h>
#include<omp.h>
#include<time.h>
using namespace std;
int main()
{
    freopen("random", "r", stdin);
    int NUMBER_OF_ELEMENTS;
    scanf("%d",&NUMBER_OF_ELEMENTS);
    int *array = new int[NUMBER_OF_ELEMENTS];
    for(int i=0;i<NUMBER_OF_ELEMENTS;i++)
    {
        scanf("%d",&array[i]);
    }
    double start , end;
    int sum = 0;
    omp_set_dynamic(0);
    omp_set_num_threads(4);
    start = omp_get_wtime();
   #pragma omp parallel for reduction(+:sum)
    for(int i=0;i<NUMBER_OF_ELEMENTS;i++)
    {
        sum = sum + array[i];
    }
    end = omp_get_wtime();
    cout<<sum<<"\n"<<"time taken is "<<end - start;
}