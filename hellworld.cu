#include<iostream>
using namespace std;
__global__ void print()
{
    printf("hello from gpu thread %d\n",threadIdx.x);
}
int main()
{
    printf("hello from cpu \n");
    print<<<1,10>>>();
}