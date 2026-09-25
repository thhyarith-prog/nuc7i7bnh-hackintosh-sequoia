#include <IOKit/IOKitLib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
typedef struct { char major, minor, build, reserved[1]; uint16_t release; } V;
typedef struct { uint16_t version, length; uint32_t cpuPLimit, gpuPLimit, memPLimit; } P;
typedef struct { uint32_t dataSize, dataType; char dataAttributes; } I;
typedef struct { uint32_t key; V vers; P pLimitData; I keyInfo; char result, status, data8; uint32_t data32; unsigned char bytes[32]; } D;
static io_connect_t c;
static uint32_t k2u(const char *s){return (s[0]<<24)|(s[1]<<16)|(s[2]<<8)|s[3];}
static int call(D *in, D *out){size_t o=sizeof(D);return IOConnectCallStructMethod(c,2,in,sizeof(D),out,&o);}
static int rd(const char *key, double *v){
  D in={0},out={0}; in.key=k2u(key); in.data8=9; if(call(&in,&out)||out.result) return 0;
  uint32_t sz=out.keyInfo.dataSize, t=out.keyInfo.dataType; in.keyInfo.dataSize=sz; in.data8=5;
  memset(&out,0,sizeof out); if(call(&in,&out)||out.result) return 0;
  if(t==k2u("sp78")){ *v=(int16_t)((out.bytes[0]<<8)|out.bytes[1])/256.0; return 1;}
  if(t==k2u("fpe2")){ *v=((out.bytes[0]<<8)|out.bytes[1])/4.0; return 1;}
  if(t==k2u("flt ")){ float f; memcpy(&f,out.bytes,4); *v=f; return 1;}
  if(t==k2u("ui8 ")){ *v=out.bytes[0]; return 1;}
  if(t==k2u("ui16")){ *v=(out.bytes[0]<<8)|out.bytes[1]; return 1;}
  return 0; }
int main(){
  io_service_t s=IOServiceGetMatchingService(kIOMainPortDefault,IOServiceMatching("AppleSMC"));
  if(!s||IOServiceOpen(s,mach_task_self(),0,&c)){puts("no SMC");return 1;}
  const char *keys[][2]={{"TC0P","CPU proximity"},{"TC0D","CPU die"},{"TC0E","CPU die (E)"},{"TC0F","CPU die (F)"},{"TCXC","CPU PECI"},{"TC0C","Core 0"},{"TC1C","Core 1"},{"TC2C","Core 2"},{"TC3C","Core 3"},{"TCGC","iGPU"},{"TG0P","GPU proximity"},{"TM0P","Memory"},{"TA0P","Ambient"},{"TPCD","PCH"},{"F0Ac","Fan 0 RPM"},{"FNum","Fan count"},{"PC0C","CPU core power W"},{"PCPC","CPU package power W"}};
  for(unsigned i=0;i<sizeof keys/sizeof keys[0];i++){double v; if(rd(keys[i][0],&v)) printf("%-5s %-20s %.1f\n",keys[i][0],keys[i][1],v);}
  return 0; }
