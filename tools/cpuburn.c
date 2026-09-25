// cpuburn <threads> <seconds> : floating-point + integer load; prints Mops/s every 5 s
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdatomic.h>
#include <time.h>
#include <unistd.h>
static atomic_ullong total; static volatile int run=1;
static void *work(void *a){ double x=1.0001,y=0.9999,z=0; unsigned long long h=(unsigned long long)a+1,n=0;
  while(run){ for(int i=0;i<100000;i++){ z+=x*y; x=x*1.0000001+0.0000001; y=y*0.9999999+z*1e-12; h^=h<<13; h^=h>>7; h^=h<<17; }
    n++; atomic_fetch_add(&total,1); }
  return (void*)(uintptr_t)(h+(unsigned long long)z); }
int main(int c,char**v){ int t=atoi(v[1]),s=atoi(v[2]); pthread_t th[64];
  for(int i=0;i<t;i++) pthread_create(&th[i],0,work,(void*)(long)i);
  unsigned long long last=0; for(int e=5;e<=s;e+=5){ sleep(5); unsigned long long cur=atomic_load(&total);
    printf("%ld cpu_mops %.1f\n",(long)time(0),(cur-last)*0.1/5.0*1000); fflush(stdout); last=cur; }
  run=0; for(int i=0;i<t;i++) pthread_join(th[i],0); return 0; }
