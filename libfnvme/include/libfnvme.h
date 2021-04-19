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

typedef struct {
	char *uio;
	char *str_dma_addr;
	int *dma_addr;
	int ctx;
	int fp_d;
	int nr;
	int bs;
}fastpath;

#define FP_DIRECT	0x01		/* Direct I/O - No copy */
#define FP_BLOCKING	0x02		/* Blocking call */

extern fastpath* fastpath_alloc();
extern char* mmap_bram(int size);
extern int fastpath_disk_alloc();
extern void fastpath_disk_free(fastpath *fp);
extern int get_fastpath_ctx(fastpath *fp);
extern void free_fastpath_ctx(fastpath *fp);
extern void fastpath_free(fastpath *fp);
extern void set_io_nr(fastpath *fp);
extern void fastpath_polling(fastpath *fp);

extern void fastpath_write(fastpath *fp, int *buf, int size, int fp_flags);
extern void fastpath_read(fastpath *fp, int *buf, int size, int fp_flags);

extern uint64_t get_cycles(fastpath *fp);
extern double gettime_fp(void);

