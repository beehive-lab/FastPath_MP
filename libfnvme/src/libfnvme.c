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
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <stdbool.h>
#include "inttypes.h"
#include <string.h>
#include <pthread.h>
#include "../include/libfnvme.h"
#include <sys/syscall.h>
#define gettid() syscall(SYS_gettid)

#define FPGA_ACCEL

#define QID_MAX 4
#define TLAB_MAX 1024
#define BLOCK_SIZE 4096
#define DMA_BUF_SIZE  16777216

// These are the offsets to pass data to the IP blocks of FastPath_MP.
enum{CTX_REG=0x30004,WR_FPD_REG=0x30008,WR_SIZE_REG=0x3000C,RD_FPD_REG=0x30010,RD_SIZE_REG=0x30014};
enum{NUM_CMDS0_REG=0x30018,NUM_CMDS1_REG=0x30020,NUM_CMDS2_REG=0x30028,NUM_CMDS3_REG=0x30030};
enum{NUM_COMPL0_REG=0x3001C,NUM_COMPL1_REG=0x30024,NUM_COMPL2_REG=0x3002C,NUM_COMPL3_REG=0x30034};
enum{CNT_CYCLES_REG=0x4, FIN_POLLING=0xC, CLEAR_POLLING=0x10};
enum {SQ_0=0x0000, CQ_0=0x1000, SQ_1=0x2000, CQ_1=0x3000, SQ_2=0x4000, CQ_2=0x5000, SQ_3=0x6000, CQ_3=0x7000};

static char *uio=NULL;
static char *bram_ptr=NULL;
static int bram_fd;
static int uio_fd;
static int fp_d;
static int tlab_mask[TLAB_MAX];
static int nvme_c_fd;
static int lib_start_flag;
static int _pmf;
unsigned _page_size;
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

// The uio driver points at address 0x53c00000. 
// This is the address where the IP blocks in the Vivado project are placed.
// This library uses mmap to map this physical memory space to a virtual address space,
// where applications can write/read data.
fastpath* fastpath_alloc() {
        int *dma_addr;
        unsigned base_addr = 0;
        unsigned page_addr, page_offset;
        unsigned page_size=sysconf(_SC_PAGESIZE);
        int tid = gettid();
        int i=0;
        fastpath *fp;

        fp = (fastpath *)malloc(sizeof(fastpath));
        
        /* Memory map the FPGA to the virtual address space */
        base_addr = 0x53c00000;
        if (base_addr == 0) {
                printf("FPGA physical address is required.\n");
                exit(-1);
        }

        /* mmap the device into memory */
        page_addr= (base_addr & (~(page_size-1)));
        page_offset = base_addr - page_addr;

        // initialize the uio__fd and mmap the physical addresses to the respective virtual
        uio_fd = open ("/dev/mem", O_RDWR);
        if (uio_fd < 1) {
                printf("Unable to open /dev/mem\n");
                exit(-1);
        }
        fp->uio = (char *)mmap(NULL,0x100000, PROT_READ|PROT_WRITE, MAP_SHARED, uio_fd, page_addr);
        close(uio_fd);
        printf("Hardware mapped to virtual address %p and tid: (%d)\n",fp->uio,tid);//- pa: (0x%zx)

        if(lib_start_flag==0) {
	lib_start_flag=1;
	// Initialise tlab_mask
	for(i=0; i<TLAB_MAX; i++)
		tlab_mask[i] = 0;
        }

        pthread_mutex_lock(&mutex);
        fp->fp_d = fastpath_disk_alloc();
        printf("Allocated fp_d: %d for tid: %d!\n",fp->fp_d,tid);

        fp->ctx = get_fastpath_ctx(fp);
        if(fp->ctx<0) {
		printf("No available FastPath queue, please retry\n");
        }
        pthread_mutex_unlock(&mutex);
	
        nvme_c_fd = open ("/dev/nvme0", O_RDWR);
        if (nvme_c_fd < 1) {
		fprintf(stderr,"Unable to open %s\n","/dev/nvme0");
        }

        fp->str_dma_addr = (char *)mmap(NULL, DMA_BUF_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, nvme_c_fd,(fp->ctx<<12));
        fp->dma_addr = (int *)mmap(NULL, DMA_BUF_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, nvme_c_fd,(fp->ctx<<12));
        printf("DMA buffer returned: (%p)\n",fp->dma_addr);
        
        return(fp);
}

char* mmap_bram(int size){
        unsigned bram_addr = 0;
        unsigned page_addr, page_offset;
        unsigned page_size=sysconf(_SC_PAGESIZE);
        /* Memory map the FPGA to the virtual address space */
        bram_addr = 0x53c40000;
        if (bram_addr == 0) {
                printf("FPGA physical address is required.\n");
                exit(-1);
        }

        /* mmap the device into memory */
        page_addr = (bram_addr & (~(page_size-1)));
        page_offset = bram_addr - page_addr;

        // initialize the fpga_fd and mmap the physical addresses to the respective virtual
        bram_fd = open ("/dev/mem", O_RDWR);
        if (bram_fd < 1) {
                printf("Unable to open /dev/mem\n");
                exit(-1);
        }

        bram_ptr = (char *)mmap(NULL,0x10000, PROT_READ|PROT_WRITE, MAP_SHARED, bram_fd, page_addr);//MAP_FIXED
        close(bram_fd);
        printf("BRAM ptr mapped to virtual address %p\n",bram_ptr);
        return(bram_ptr);
}

int fastpath_disk_alloc() {
	for(int i=0; i < TLAB_MAX; i++) {
		if(tlab_mask[i]==0) {
			tlab_mask[i] = 1;
			return(i);
		}
	}
	// no available fp_d
	return -1;
}

void fastpath_disk_free(fastpath *fp) {
	tlab_mask[fp->fp_d] = 0;
	
	for(int i=0; i < TLAB_MAX; i++)
		printf("Current TLABmask[%d]: %d \t",i,tlab_mask[i]);
	printf("\n");
}

int get_fastpath_ctx(fastpath *fp) {
	int ctx = *(int *)(fp->uio+CTX_REG);
	return(ctx);
}

void free_fastpath_ctx(fastpath *fp) {
	printf("[free_fastpath_ctx] starts\n");
	*(int *)(fp->uio+CTX_REG) = fp->ctx;
	
	if(fp->bs/BLOCK_SIZE==1) {
	        *(int *)(fp->uio+CLEAR_POLLING+CQ_0)=1;
	} else if(fp->bs/BLOCK_SIZE==2) {
	        *(int *)(fp->uio+CLEAR_POLLING+CQ_0)=1;
	        *(int *)(fp->uio+CLEAR_POLLING+CQ_1)=1;
	} else if(fp->bs/BLOCK_SIZE==4) {
	        *(int *)(fp->uio+CLEAR_POLLING+CQ_0)=1;
	        *(int *)(fp->uio+CLEAR_POLLING+CQ_1)=1;
	        *(int *)(fp->uio+CLEAR_POLLING+CQ_2)=1;
	        *(int *)(fp->uio+CLEAR_POLLING+CQ_3)=1;
	} else 
		printf("Not recognised fp->bs: %d\n",fp->bs);
}

void fastpath_free(fastpath *fp) {
	//fastpath_disk_free(fp);
	free_fastpath_ctx(fp);
	munmap(fp->uio,0x100000);
}

void set_io_nr(fastpath *fp) {
	int num_compl = fp->nr ;//(fp->bs/BLOCK_SIZE);
	//printf("set_io_nr for ctx: %d - (%d) requests and (%d) number of completions!\n",fp->ctx,fp->nr,num_compl);
	if(fp->ctx==0) {
		memcpy((fp->uio+NUM_CMDS0_REG),&fp->nr,sizeof(int));
		memcpy((fp->uio+NUM_COMPL0_REG),&num_compl,sizeof(int));
	} else if(fp->ctx==1) {
		memcpy((fp->uio+NUM_CMDS1_REG),&fp->nr,sizeof(int));
		memcpy((fp->uio+NUM_COMPL1_REG),&num_compl,sizeof(int));
	} else if(fp->ctx==2) {
		memcpy((fp->uio+NUM_CMDS2_REG),&fp->nr,sizeof(int));
		memcpy((fp->uio+NUM_COMPL2_REG),&num_compl,sizeof(int));
	} else if(fp->ctx==3) {
		memcpy((fp->uio+NUM_CMDS3_REG),&fp->nr,sizeof(int));
		memcpy((fp->uio+NUM_COMPL3_REG),&num_compl,sizeof(int));
	} else 
		printf("Not recognised ctx: %d\n",fp->ctx);
}

void fastpath_polling(fastpath *fp) {
	// it should may sleep, during polling
	if(fp->bs/BLOCK_SIZE==1) {
	        while(*(fp->uio+FIN_POLLING+CQ_0)!=1);
		//usleep(70);
	} else if(fp->bs/BLOCK_SIZE==2) {
		while(*(fp->uio+FIN_POLLING+CQ_0)!=1);
	        while(*(fp->uio+FIN_POLLING+CQ_1)!=1);
		//usleep(70);
	} else if(fp->bs/BLOCK_SIZE==4) {
	        while(*(fp->uio+FIN_POLLING+CQ_0)!=1);
	        while(*(fp->uio+FIN_POLLING+CQ_1)!=1);
		while(*(fp->uio+FIN_POLLING+CQ_2)!=1);
	        while(*(fp->uio+FIN_POLLING+CQ_3)!=1);
		//usleep(70);
	} else 
		printf("Not recognised fp->bs: %d\n",fp->bs);
}

void fastpath_write(fastpath *fp, int *buf, int size, int fp_flags) {
	//double start_sub, stop_sub, total_sub;
	//double start_polling, stop_polling, total_polling;
	if(buf!=NULL) {
		//start_sub = gettime_fp();
		//set_io_nr(fp);
		fp->fp_d = fp->fp_d | (fp->ctx<<16);
		
		if((fp_flags&1)==0) {	// no direct I/O
			memcpy(fp->dma_addr,buf,size);
		}

		memcpy((fp->uio+WR_FPD_REG),&fp->fp_d,sizeof(int));
		memcpy((fp->uio+WR_SIZE_REG),&size,sizeof(int));
		//stop_sub = gettime_fp();
	}
	else {
		printf("buff is NULL!!\n");
	}
	//start_polling = gettime_fp();
	if((fp_flags&2)==2) {	// blocking call
		fastpath_polling(fp);
	}
	//stop_polling = gettime_fp();
	//total_sub = stop_sub-start_sub;
	//printf("FastWrite submission took :%lf seconds\n",total_sub);
	//total_polling = stop_polling-start_polling;
	//printf("FastWrite polling took :%lf seconds\n",total_polling);
}

void fastpath_read(fastpath *fp, int *buf, int size, int fp_flags) {
	//double start_sub, stop_sub, total_sub;
	//double start_polling, stop_polling, total_polling;
	if(buf!=NULL) {
		//start_sub = gettime_fp();
		//set_io_nr(fp);
		fp->fp_d = fp->fp_d | (fp->ctx<<16);
		memcpy((fp->uio+RD_FPD_REG),&fp->fp_d,sizeof(int));
		memcpy((fp->uio+RD_SIZE_REG),&size,sizeof(int));
		//stop_sub = gettime_fp();
	}
	//start_polling = gettime_fp();
	if((fp_flags&2)==2)	// blocking call
		fastpath_polling(fp);
	
	if((fp_flags&1)==0)	// no direct I/O
		memcpy(buf,fp->dma_addr,size);
	//stop_polling = gettime_fp();
	//total_sub = stop_sub-start_sub;
	//printf("FastRead submission took :%lf seconds\n",total_sub);
	//total_polling = stop_polling-start_polling;
	//printf("FastRead polling took :%lf seconds\n",total_polling);
}

uint64_t get_cycles(fastpath *fp) {
	uint64_t cycles;
	int bottom,top;
	memcpy(&bottom,(fp->uio+CNT_CYCLES_REG+CQ_0),sizeof(int));
	//memcpy(&top,(fp->uio+CNT_CYCLES_REG+CQ_0),sizeof(int));
	cycles = bottom;//(top<<32) | bottom;
	printf("Get Cycles returned value: %"PRIu64"\n",cycles);
	return(bottom);
}

double gettime_fp(void)
{
        struct timeval ttime;
        gettimeofday(&ttime,NULL);
        return ((double)(ttime.tv_sec + ttime.tv_usec*0.000001));
}
