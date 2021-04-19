/*
 * Copyright (c) 2018, Thanos Stratikopoulos, APT Group, Department of Computer Science,
 * School of Engineering, The University of Manchester. All rights reserved.
 */

package FASTPATH_COMPLETE;

//Quite a number of packages are require to make AXI / ACP work
import GetPut::*;
import TLM2::*;
import Axi::*;
import AXI32_GDefines::*;
import Zynq_AXI32::*;
import DefaultValue::*;
import BusRange::*;
import AXI32_GDefines::*;
import ACPDefines::*;
import Zynq_ACP::*;
import Connectable::*;

//FIFOs are always handy for flow control;
import FIFO::*;
import FIFOF::*;
import Vector::*;

`define CQ_DEPTH 1024

interface AXI_ifc;
	(*prefix="S_AXI"  *)
	interface Zynq_Axi32_rd_slave sread;
	(* prefix="S_AXI"  *)
	interface Zynq_Axi32_wr_slave swrite;
	(* prefix="M_AXI_COMPLETE" *)
	interface Zynq_ACP_rd_master mread;
	(* prefix="M_AXI_COMPLETE"  *)
	interface Zynq_ACP_wr_master mwrite;

	method Action setComReq (Bit#(32) req_in);

	(* always_enabled, prefix="" *)
	method Action setCounter ((*port="SET_COUNTER"*)Bit#(64) cin);
	(* always_ready, result="GET_COUNTER" *)
	method Bit#(64) getCounter();

	(* always_enabled, prefix="" *)
	method Action setCompleted ((*port="SET_COMPLETED"*)Bit#(32) cin);
	(* always_ready, result="GET_COMPLETED" *)
	method Bit#(32) getCompleted();

	(* always_ready, result="GET_SQ_HEAD" *)
	method Bit#(32) getSqHead();
endinterface

//The bs interface makes the stuff compatible with bluespec transactors (although maybe not so much Xilinx)
interface Axibs_ifc;
	(* prefix="S_AXI"  *)
	interface Zynq_Axi32_rd_dec_slave sread;
	(* prefix="S_AXI"  *)
	interface Zynq_Axi32_wr_dec_slave swrite;
	(* prefix="M_AXI_COMPLETE" *)
	interface Zynq_ACP_rd_master mread;
	(* prefix="M_AXI_COMPLETE"  *)
	interface Zynq_ACP_wr_master mwrite;

	method Action setComReq (Bit#(32) req_in);

	(* always_enabled, prefix="" *)
	method Action setCounter ((*port="SET_COUNTER"*)Bit#(64) cin);
	(* always_ready, result="GET_COUNTER" *)
	method Bit#(64) getCounter();

	(* always_enabled, prefix="" *)
	method Action setCompleted ((*port="SET_COMPLETED"*)Bit#(32) cin);
	(* always_ready, result="GET_COMPLETED" *)
	method Bit#(32) getCompleted();

	(* always_ready, result="GET_SQ_HEAD" *)
	method Bit#(32) getSqHead();
endinterface

(* synthesize *)
module fastpath_complete(AXI_ifc);
	//These are essentially the channels of the AXI (aw and w are combined)
    	Zynq_Axi32_rd_slave_xactor rd_slave  <- mkZynq_Axi32_rd_slave_xactor(1); //these are the input side Axi to tlm
    	Zynq_Axi32_wr_slave_xactor wr_slave  <- mkZynq_Axi32_wr_slave_xactor(1); //these are the input side Axi to tlm
	Zynq_ACP_rd_master_xactor rd_master <- mkZynq_ACP_rd_master_xactor; //This moves our TLM Read interface interface to AXI
	Zynq_ACP_wr_master_xactor wr_master <- mkZynq_ACP_wr_master_xactor; //This moves our TLM Write interface interface to AXI

	FIFO#(ACPBusRequest) faread 	<- mkSizedFIFO(1024);
	FIFO#(Bit#(128))    cqe_fifo 	<- mkSizedFIFO(1024);
	FIFOF#(Bit#(32))	req_fifo		<- mkSizedFIFOF(1);

	Reg#(Bit#(32)) 	number_of_cmds 	<- mkReg(0);
	Reg#(Bit#(32)) 	completed_cmds 	<- mkReg(0);
	Reg#(Bit#(32)) 	cq_address 	<- mkReg(0);
	Reg#(Bit#(64)) 	cqe_reg		<- mkReg(0);
	Reg#(Bit#(64)) 	count_cycles	<- mkReg(0);
	Reg#(Bit#(1))  	cq_phase_reg   	<- mkReg(1);
        	Reg#(Bit#(32))  	cq_head_reg   	<- mkReg(0);
        	Reg#(Bit#(32))  	sq_head   	<- mkReg(0);
	Reg#(Bool) 	completed_polling 	<- mkReg(False);

	RWire#(Bool) 	wait_completion_wire <- mkRWire();
	Reg#(Bool) 	wait_completion <- mkReg(False);
	Reg#(Bool) 	start_timing 	<- mkReg(False);
	RWire#(Bool) 	polling_wire 	<- mkRWire();
	Reg#(Bool) 	polling 	<- mkReg(False);
	RWire#(Bool) 	clear_wire 	<- mkRWire();
	Reg#(Bool) 	clear 		<- mkReg(False);
	Reg#(Bool) 	stop_timing 	<- mkReg(False);
	Reg#(Bool) 	completion_flag	<- mkReg(False);
	Reg#(Bool) 	reading 	<- mkReg(False);
	Reg#(Bool) 	writing 	<- mkReg(False);

	Reg#(Bool) 	first2		<- mkReg(True);
	Reg#(Bool) 	second2		<- mkReg(False);
	Reg#(Bit#(64)) 	fake_counter	<- mkReg(0);
	Reg#(Bit#(32)) 	fake_completed	<- mkReg(0);

	//This rule will take data passed from the ARM to the model, as parameters to the function
    	rule getWrReq;
    		//First take a request from the write master
       		let req <- wr_slave.tlm.tx.get();

		if(req.address[8:2]==7'h0)
			cq_address <= req.data;
		else if(req.address[8:2]==7'h4) begin
			start_timing <= False;
			stop_timing <= False;
			completed_polling <= False;
			count_cycles <= 0;
			completed_cmds <= 0;
			completion_flag <= False;
			clear_wire.wset(True);
		end

		//Acknowledge that we got the data
		Axi32BusResponse resp = defaultValue;
		resp.error = False;		//Signal that no errors occured
		resp.id = req.id;  		//We need to pass back the id of the incoming req
	    	wr_slave.tlm.rx.put(resp);
	endrule

	rule getRdReq;
		let req <- rd_slave.tlm.tx.get();
		Axi32BusResponse resp = defaultValue;
		if(req.address[8:2]==7'h0)
			resp.data = cq_address;
		else if(req.address[8:2]==7'h01)
			resp.data = count_cycles[31:0];
		else if(req.address[8:2]==7'h02)
			resp.data = count_cycles[63:32];
		else if(req.address[8:2]==7'h03) begin
			if(completed_polling)
				resp.data = 32'h1;
			else
				resp.data = 32'h0;
		end else
			resp.data = 0;
		
		resp.error = False;		//Signal that no errors occured
		resp.id = req.id;  		//We need to pass back the id of the incoming req
		rd_slave.tlm.rx.put(resp);
	endrule

	// Second ACP bus
	rule fr;  //forward read requests
		let r = faread.first;	
		$display($time,"Reading request to mem address: 0x%08x!\n",r.address);
		rd_master.tlm.rx.put(r);
		faread.deq();
	endrule

	rule readReq(polling||wait_completion); // this rule may not fire if faread is full
		ACPBusRequest forward = defaultValue;
		forward.wa = False;
		forward.ra = False;
		forward.c = True;
		forward.b = True;
		forward.usermode=True;
		forward.secure=False;
		forward.user=1;

		forward.write = False;
		forward.address = cq_address + (cq_head_reg<<4);
		forward.burst = 2;// it was 2 for 128bits
		forward.first = first2;
		faread.enq(forward);
	endrule

	rule mreadResp;	// this rule may not fire if cqe_fifo is full
		let resp <- rd_master.tlm.tx.get();
		
		if(first2) begin
			first2<=False;
			cqe_reg[63:0] <= resp.data;
			$display($time,"Got resp1!\n");
			$display("1st word[63:0]: 0x%x - ",resp.data);
			second2 <= True;
		end else if(second2) begin
			second2<=False;
			$display($time,"Got resp2!\n");
			let cqe_data = {resp.data,cqe_reg[63:0]};
			cqe_fifo.enq(cqe_data);
			first2 <= True;
		end
	endrule

	rule cqeProcessing(completion_flag);
		let cqe_data = cqe_fifo.first();
		cqe_fifo.deq();
	
		let cqe_phase = cqe_data[112];

		if(cqe_phase==cq_phase_reg && cqe_data[114:113]==2'h0) begin
		    if((cq_head_reg+1)==`CQ_DEPTH) begin
			  cq_head_reg <= 0;
			  cq_phase_reg<= ~cq_phase_reg;
		    end else
			  cq_head_reg <= cq_head_reg + 1;

		    sq_head <= zeroExtend(cqe_data[79:64]);

		    if((completed_cmds+1) != number_of_cmds) begin
			completed_cmds <= completed_cmds + 1;
			wait_completion_wire.wset(True);
		    end else begin
			completed_cmds <= completed_cmds + 1;
			stop_timing <= True;
			clear_wire.wset(True);
			completion_flag <= False;
			completed_polling <= True;
		    end
		end
		else
			polling_wire.wset(True);
	endrule

	rule clearFifos(clear);
		faread.clear();
		cqe_fifo.clear();
	endrule
	
	rule waitCompletionRule;
		let go0 = fromMaybe(False, wait_completion_wire.wget());
		wait_completion <= go0;
	endrule

	rule pollingRule;
		let go = fromMaybe(False, polling_wire.wget());
		polling <= go;
	endrule

	rule clearRule;
		let go3 = fromMaybe(False, clear_wire.wget());
		clear <= go3;
	endrule

	rule timingCycles;
		if (stop_timing)
			start_timing <= False;
		else if (start_timing)
			count_cycles <= count_cycles + 1;
	endrule

	rule startPolling(!completion_flag);
		let req_entry = req_fifo.first();
		req_fifo.deq();

		number_of_cmds <= req_entry;
		
		start_timing <= True;
		wait_completion_wire.wset(True);
		stop_timing <= False;
		completed_polling <= False;
		completed_cmds <= 0;
		count_cycles <= 0;

		completion_flag <= True;
	endrule

	method Action setComReq (Bit#(32) req_in);
		req_fifo.enq(req_in);	
	endmethod

	method Action setCounter (Bit#(64) cin);
		fake_counter <= cin;
	endmethod

	method Bit#(64) getCounter();
		let res = count_cycles;
		return(res);
	endmethod

	method Action setCompleted (Bit#(32) cin);
		fake_completed <= cin;
	endmethod

	method Bit#(32) getCompleted();
		if(completed_polling)
			return(32'h1);
		else
			return(32'h0);
	endmethod

	method Bit#(32) getSqHead();
		return(sq_head);
	endmethod

    	interface sread  = rd_slave.fabric;
    	interface swrite = wr_slave.fabric;  
    	interface mread  = rd_master.fabric;
	interface mwrite = wr_master.fabric;

endmodule:fastpath_complete


module fastpath_complete_bs (Axibs_ifc);
	AXI_ifc dut <- fastpath_complete() ;
	//THIS WORKS OK FOR A SYSTEM BUT FOR A XILINX SYSTEM LETS BIN THE ADDRESS STUFF 

	AddressRange#(Zynq_Axi32_Addr) axiModule_params = defaultValue;
	axiModule_params.base       = 32'h0000_0000;
	axiModule_params.high       = 32'h0002_0000 - 1;

	interface AxiRdFabricSlave sread;  
	    interface AxiRdSlave bus =  dut.sread;
	    method  Bool addrMatch(Zynq_Axi32_Addr value) = False;
	endinterface    

	interface AxiWrFabricSlave swrite;
	interface AxiWrSlave bus =  dut.swrite;
	method  Bool addrMatch(Zynq_Axi32_Addr value) = False;
	endinterface
	
	method Action setComReq (Bit#(32) req_in);
		dut.setComReq(req_in);
	endmethod

	method Action setCounter (Bit#(64) cin);
		dut.setCounter(cin);
	endmethod

	method Bit#(64) getCounter();
		let res = dut.getCounter();
		return(res);
	endmethod

	method Action setCompleted (Bit#(32) cin);
		dut.setCompleted(cin);
	endmethod

	method Bit#(32) getCompleted();
		let res = dut.getCompleted();
		return(res);
	endmethod

	method Bit#(32) getSqHead();
		let res = dut.getSqHead();
		return(res);
	endmethod

	interface  mread = dut.mread;
	interface  mwrite = dut.mwrite;
endmodule

module test();
	Reg#(Bit#(32)) count_send <-mkReg(0);
	Reg#(Bit#(32)) count_read <-mkReg(0);
	Reg#(Bit#(32)) count_a <-mkReg(0);
	Reg#(Bit#(32)) count_b <-mkReg(0);
	Reg#(UInt#(32)) rtr_count <-mkReg(0);
	Reg#(UInt#(32)) rt_count <-mkReg(0);
	Reg#(UInt#(32)) rtr_count2 <-mkReg(0);
	Reg#(UInt#(32)) rtw_count <-mkReg(0);
	Reg#(UInt#(32)) cycle <-mkReg(0);
	Reg#(Bit#(32)) c_reg <- mkReg(0);
	FIFO#(Bit#(32)) read_address_fifo <- mkFIFO();
	//The following are just stored for logging

	AddressRange#(Zynq_ACP_Addr) t_params = defaultValue;
	t_params.base       = 32'h0000_0000;
	t_params.high       = 32'hFFFF_FFFF;

	Zynq_ACP_rd_slave_dec_xactor read_slave  <- mkZynq_ACP_rd_slave_dec_xactor(addAddressRangeMatch(t_params));
	Zynq_ACP_wr_slave_dec_xactor write_slave <- mkZynq_ACP_wr_slave_dec_xactor(addAddressRangeMatch(t_params));

	Zynq_Axi32_rd_master_xactor read_master <- mkZynq_Axi32_rd_master_xactor;
	Zynq_Axi32_wr_master_xactor write_master <- mkZynq_Axi32_wr_master_xactor;
	Axibs_ifc dut <- fastpath_complete_bs ();
 
 	mkConnection(read_master.fabric.bus,  dut.sread.bus);
 	mkConnection(write_master.fabric.bus, dut.swrite.bus); 
	mkConnection(dut.mwrite.bus, write_slave.fabric.bus);
	mkConnection(dut.mread.bus, read_slave.fabric.bus);

 	rule sendWCmd;
		Axi32BusRequest req = defaultValue;
		req.write = True;
		req.byteen = -1;


		let c = count_send%6;
		c_reg <= count_send%6;

		if (count_send<100 || (count_send>100 && count_send<200)) begin

			if (c==0 && count_send==0) begin
				req.address = 32'h53c00000;
				req.data = 32'h53c0_4000;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==5 && count_send==5) begin
				dut.setComReq(5);
			end else if (c==0 && count_send==120) begin
				req.address = 32'h53c00000;
				req.data = 32'h53c0_4000;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==5 && count_send==125) begin
				dut.setComReq(5);
			end
		end else if (count_send==100 || count_send==200)begin
			req.address = 32'h53c00010;
			req.data = 32'h1;
		end else begin
			req.address = 32'h53c0FFF0;
			req.data = 32'h1;
		end
			

		write_master.tlm.rx.put(req);
		count_send <= count_send + 1;
 	endrule

	/*rule getStopPolling;
		let res = False;
		res = dut.finish_polling();
		$display($time,"Got polling: %s!!!\n",(res)?"Finished":"NotFinished");
	endrule*/
 	
 	//We also ALWAYS need to check write responses
 	rule wr;
 		let resp <- write_master.tlm.tx.get();
 	endrule

	rule reply_write;
		let req <- write_slave.tlm.tx.get();
		ACPBusResponse ret = defaultValue;
		ret.error = False;

		write_slave.tlm.rx.put(ret);
		rtw_count <= rtw_count + 1;
	endrule

	rule reply_read2;
		let req <- read_slave.tlm.tx.get();
		let baseAddress = 32'h53c0_4000;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		let c1 = rtr_count2%6;
		if(c1==5)
			ret.data = {(32'h0001_0000+pack(rt_count)), pack(rt_count)};
		else
			ret.data = {(32'h0000_2345+pack(rt_count)), pack(rt_count)};
			
		read_slave.tlm.rx.put(ret);
		
		
		if(rtr_count2==4095)
			rt_count <= 1;
		else begin
			if(rtr_count2>4095) begin
				//if(c1!=0 && c1!=1)
					rt_count <= rt_count+1;
			end else begin
				//if(c1!=2 && c1!=3)
					rt_count <= rt_count+1;
			end
		end
		rtr_count2 <= rtr_count2 + 1;
	endrule
 	
 	//This is to stop when finished
	rule go;		
		if(cycle==200000)begin
			$finish;
		end
		cycle<=cycle+1;
	endrule

endmodule


endpackage:FASTPATH_COMPLETE

