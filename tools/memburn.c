// memburn <MB> <seconds> : memcpy bandwidth, prints GB/s every 5 s
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
static double now(){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec+t.tv_nsec/1e9;}
int main(int c,char**v){ size_t mb=atol(v[1]); int s=atoi(v[2]); size_t n=mb*1024*1024/2;
  char *a=malloc(n),*b=malloc(n); memset(a,1,n); memset(b,2,n);
  double st=now(),mark=st; double bytes=0;
  while(now()-st<s){ memcpy(b,a,n); memcpy(a,b,n); bytes+=2.0*n*2;
    if(now()-mark>=5){ printf("%ld mem_gbps %.2f\n",(long)time(0),bytes/(now()-mark)/1e9); fflush(stdout); bytes=0; mark=now(); } }
  return a[7]+b[9]==0; }
