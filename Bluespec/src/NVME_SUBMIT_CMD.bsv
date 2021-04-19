/*
 * Copyright (c) 2018, Thanos Stratikopoulos, APT Group, Department of Computer Science,
 * School of Engineering, The University of Manchester. All rights reserved.
 */

/*
 * The NVME_SUBMIT_CMD module implements the logic
 * of the nvme_submit_cmd in the NVMe Linux driver.
*/
package NVME_SUBMIT_CMD;

import FIFO::*;

`define SQ_DEPTH 1024

typedef Bit#(32) Width;
typedef Bit#(512) NvmeCmd;

interface NvmeSubmitCmd_ifc;
	method Action 	clear ();
	method Action 	reset ();
	method Action 	setSqAddr (Width addr);
	method Width 	getSqAddr ();
	method Action 	setSqDBAddr (Width addr);
	method Width 	getSqDBAddr ();
	method Action 	start();
	method Action 	setCmd (NvmeCmd cmd);
	method Width 	getSqAddrOffset();
	method Width 	getSqTail();
	method ActionValue #(NvmeCmd) submitCmd();
endinterface: NvmeSubmitCmd_ifc

module mkNvmeSubmitCmd (NvmeSubmitCmd_ifc);
	Reg#(Width)  		sq_addr_reg	<- mkReg(0);
	Reg#(Width)  		sq_db_addr_reg	<- mkReg(0);
	Reg#(Width)  		sq_tail		<- mkReg(0);
	Reg#(Bool) 		start_reg	<- mkReg(False);

	FIFO#(NvmeCmd) 		sq		<- mkSizedFIFO(256);

	method Action clear ();
		sq.clear();
	endmethod

	method Action reset ();
		sq_addr_reg	<= 0;
		sq_db_addr_reg	<= 0;
		sq_tail		<= 0;
	endmethod

	method Action setSqAddr (Width addr);
		sq_addr_reg 	<= addr;
	endmethod

	method Width getSqAddr();
		return(sq_addr_reg);
	endmethod

	method Action setSqDBAddr (Width addr);
		sq_db_addr_reg <= addr;
	endmethod

	method Width getSqDBAddr();
		return(sq_db_addr_reg);
	endmethod

	method Action start();
		start_reg <= True;
	endmethod

	method Action setCmd (NvmeCmd cmd) if(start_reg);
		sq.enq(cmd);
		if ((sq_tail+1)==(`SQ_DEPTH))
			sq_tail <= 0;
		else
			sq_tail <= sq_tail + 1;
	endmethod

	method Width getSqAddrOffset();
		let r = sq_tail;
		if(r==0)
			return(32'h3ff);	//1023
		else begin
			let cur_tail = sq_tail-1;
			return(cur_tail);
		end
	endmethod

	method Width getSqTail();
		let r = sq_tail;
		if (r==(`SQ_DEPTH))
			return(0);
		else
			return(sq_tail);
	endmethod

	method ActionValue #(NvmeCmd) submitCmd();
		let cmd = sq.first();
		sq.deq();
		return(cmd);
	endmethod

endmodule: mkNvmeSubmitCmd

endpackage
