/*
 * Copyright (c) 2018, Thanos Stratikopoulos, APT Group, Department of Computer Science,
 * School of Engineering, The University of Manchester. All rights reserved.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>
#include <stdbool.h>
#include "inttypes.h"
#include <sys/ioctl.h>
#include <errno.h>
#include "libfnvme.h"
#include <sys/syscall.h>
#define gettid() syscall(SYS_gettid)


static char *dma_addr=NULL;

int main(int argc, const char *argv[]){
        char *str_data;
        char *ret_data;
	const int number_of_fastpaths=4;
	const int bs_per_fastpath=4096;
        int size = 1048576;
        int sent = 0;
        int bs = number_of_fastpaths*bs_per_fastpath;
        long long slba=0;
        int i,write;
        char operation;
        double start_time=0,stop_time=0,total_time=0;
        double io_throughput=0;
        int fp_d;
        fastpath *fp;
        uint64_t cycles;
        uint64_t latency;

        fp = fastpath_alloc();
        dma_addr = fp->str_dma_addr;

        if(argc==4) {
                operation = argv[1][0];

                if(operation=='r')
                        write=0;
                else if(operation=='w')
                        write=1;
                else{
                        printf("Inserted wrong character, try (r,w)!\n");
                        exit(-1);
                }
                size = atoi(argv[2]);
	      bs = atoi(argv[3]);
        }else{
                printf("User has to insert three inputs (operation, size, bs)!\n");
                exit(-1);
        }

        fp->nr = size/bs;
        fp->bs = bs;
        set_io_nr(fp);
        printf("User request %s %d size with %d bs!\n",(write==1)?"Writing":"Reading",size,bs);
 
        // Initialise arrays
        str_data = (char*) malloc (sizeof(char)*size);
        ret_data = (char*) malloc (sizeof(char)*size);

        if(write==1){
	printf("Enter a string, up to 4096 bytes:\n");
        	scanf("%[^\n]s",str_data);
          strcpy(fp->str_dma_addr,str_data);
	printf("str_data: %s\n",str_data);
	printf("dma_addr: %s\n",fp->str_dma_addr);
        }

        start_time = gettime_fp();
	// Loop over and submit all the requests
        while(sent<size) {
        	if(write==1)
  		fastpath_write(fp,(int*)&fp->str_dma_addr[sent/bs],bs,FP_DIRECT);
        	else
  		fastpath_read(fp,(int*)&fp->str_dma_addr[sent/bs],bs,FP_DIRECT);
		sent +=bs;
        }
        

        fastpath_polling(fp);
        stop_time = gettime_fp();
        total_time = stop_time - start_time;
        io_throughput = size/total_time;
        printf("Total %s gettime= %lf seconds - Bandwidth = %lf MB/s - size: %d\n",(write==1)?"Writing":"Reading",total_time, io_throughput/(1048576), size);
        cycles = get_cycles(fp);
        latency = (uint64_t)(cycles/125)*(0.000001);
        printf("Total I/O FPGA cycles = %"PRIu64" cycles - :%"PRIu64" seconds\n\n", cycles,latency);



        
        if(write==0){
	printf("---------- Read Message! ----------\n");
	strcpy(ret_data,fp->str_dma_addr);
	printf("ret_data: %s\n",ret_data);
        }

perror:     
        for(i=0; i<size/4; i++) {
		fp->str_dma_addr[i] = -1;
        }
        fastpath_free(fp);
     
        free(str_data);
        free(ret_data);
}
