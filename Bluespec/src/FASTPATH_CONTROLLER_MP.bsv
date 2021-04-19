/*
 * Copyright (c) 2018-2021, APT Group, Department of Computer Science,
 * School of Engineering, The University of Manchester. All rights reserved.
 *
 * Authors: Thanos Stratikopoulos
 */
package FASTPATH_CONTROLLER_MP;

// Quite a number of packages are required to make AXI work
import GetPut::*;
import TLM2::*;
import Axi::*;
import AXI32_GDefines::*;
import Zynq_AXI32::*;
import ACPDefines::*;
import Zynq_ACP::*;
import DefaultValue::*;
import BusRange::*;
import Connectable::*;
// FIFOs are always handy for flow control;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;

// NVMe commands are 64 bytes wide. So, sixteen 32-bit words
// are required to store each command
typedef 1 NumQids;
`define BLOCK_SIZE 4096

/* The FASTPATH_MP_CONTROLLER module receives I/O requests from the libfnvme library.
 * The requests are going in the req_fifo fifo. Then it analyzes each request, 
 * and configures the number of fastpaths that should be used, 
 * along with the number of commands that will be dispatched per path 
 * (num_cp_fp0_fifo, num_cp_fp1_fifo, num_cp_fp2_fifo, num_cp_fp3_fifo).
 * 
 * Each FastPath is configured to issue commands for 4KB block sizes. 
 * So, the number of paths is configurable depending on 
*/
interface AXI_ifc;
	(*prefix="S_AXI" *)
	interface Zynq_Axi32_rd_slave sread;
	(* prefix="S_AXI" *)
	interface Zynq_Axi32_wr_slave swrite;

	method ActionValue #(Bit#(64)) get_req2fp0();

	method ActionValue #(Bit#(32)) start_pollingfp0();
	method ActionValue #(Bit#(32)) start_pollingfp1();
	method ActionValue #(Bit#(32)) start_pollingfp2();
	method ActionValue #(Bit#(32)) start_pollingfp3();

	(* always_enabled, prefix="" *)
	method Action setQidMask ((*port="SET_QID_MASK"*)Bit#(1) qid_in);
	(* always_ready, result="GET_QID_MASK" *)
	method Bit#(1) getQidMask();
endinterface

//The bs interface makes the stuff compatible with bluespec transactors (although maybe not so much Xilinx)
interface Axibs_ifc;
	(*prefix="S_AXI" *)
	interface Zynq_Axi32_rd_dec_slave sread;
	(* prefix="S_AXI" *)
	interface Zynq_Axi32_wr_dec_slave swrite;

	method ActionValue #(Bit#(64)) get_req2fp0();

	method ActionValue #(Bit#(32)) start_pollingfp0();
	method ActionValue #(Bit#(32)) start_pollingfp1();
	method ActionValue #(Bit#(32)) start_pollingfp2();
	method ActionValue #(Bit#(32)) start_pollingfp3();

	(* always_enabled, prefix="" *)
	method Action setQidMask ((*port="SET_QID_MASK"*)Bit#(1) qid_in);
	(* always_ready, result="GET_QID_MASK" *)
	method Bit#(1) getQidMask();
endinterface

(* synthesize *)
module fastpath_controller_mp(AXI_ifc);
	Zynq_Axi32_rd_slave_xactor rd_slave 		<- mkZynq_Axi32_rd_slave_xactor(1); //these are the input side Axi to tlm
	Zynq_Axi32_wr_slave_xactor wr_slave 		<- mkZynq_Axi32_wr_slave_xactor(1); //these are the input side Axi to tlm

	FIFOF#(ACPBusRequest) 	faread			<- mkSizedFIFOF(1);
	FIFOF#(ACPBusRequest) 	faread2 		<- mkSizedFIFOF(1);
	FIFOF#(ACPBusRequest) 	fawrite 		<- mkSizedFIFOF(256);
	FIFOF#(ACPBusRequest) 	fawrite2 		<- mkSizedFIFOF(256);

	Reg#(Bit#(32)) 		num_of_qids	<- mkReg(0);
	Reg#(Bit#(32)) 		iodepth		<- mkReg(0);
	Reg#(Bit#(16)) 		wr_fpd		<- mkReg(0);
	Reg#(Bit#(14)) 		wr_qid		<- mkReg(0);
	Reg#(Bit#(16)) 		rd_fpd		<- mkReg(0);
	Reg#(Bit#(14)) 		rd_qid		<- mkReg(0);
	Reg#(Bit#(32)) 		num_req_fp0	<- mkReg(0);
	Reg#(Bit#(32)) 		num_req_fp1	<- mkReg(0);
	Reg#(Bit#(32)) 		num_req_fp2	<- mkReg(0);
	Reg#(Bit#(32)) 		num_req_fp3	<- mkReg(0);
	Reg#(Bit#(32)) 		num_compl_fp0	<- mkReg(0);
	Reg#(Bit#(32)) 		num_compl_fp1	<- mkReg(0);
	Reg#(Bit#(32)) 		num_compl_fp2	<- mkReg(0);
	Reg#(Bit#(32)) 		num_compl_fp3	<- mkReg(0);
	Reg#(Bit#(32)) 		sent_cmds_fp0	<- mkReg(0);
	Reg#(Bit#(32)) 		sent_cmds_fp1	<- mkReg(0);
	Reg#(Bit#(32)) 		sent_cmds_fp2	<- mkReg(0);
	Reg#(Bit#(32)) 		sent_cmds_fp3	<- mkReg(0);
	FIFOF#(Bit#(64))		req_fifo		<- mkSizedFIFOF(8192);
	FIFOF#(Bit#(64))		fp0_fifo		<- mkSizedFIFOF(8192);
	FIFOF#(Bit#(64))		fp1_fifo		<- mkSizedFIFOF(8192);
	FIFOF#(Bit#(64))		fp2_fifo		<- mkSizedFIFOF(8192);
	FIFOF#(Bit#(64))		fp3_fifo		<- mkSizedFIFOF(8192);

	FIFOF#(Bit#(32))		num_cp_fp0_fifo 	<- mkSizedFIFOF(1024);
	FIFOF#(Bit#(32))		num_cp_fp1_fifo 	<- mkSizedFIFOF(1024);
	FIFOF#(Bit#(32))		num_cp_fp2_fifo 	<- mkSizedFIFOF(1024);
	FIFOF#(Bit#(32))		num_cp_fp3_fifo 	<- mkSizedFIFOF(1024);

	Reg#(Bit#(1)) 		fake_qid		<- mkReg(0);

	Vector#(NumQids,Reg#(Bit#(1))) qid_mask;

	for(Integer i=0; i<valueOf(NumQids); i=i+1)
		qid_mask[i] <- mkReg(0);

	rule checkMask;
		let req = req_fifo.first();
		if(qid_mask[req[5:2]]==1) begin // In the current version the index passed is always 0.
			case(req[5:2])
				4'h0: begin	
					let num_paths = 32'h0;
					// Each path issues a command with 4KB block size.
					num_paths = zeroExtend(req[62:32])>>12;
					if(sent_cmds_fp0==0) begin
					 	 //let num_cmds = (req[62:32]>>12) << num_req_fp0;
						// FastPath distributes a request for multiple
						if(num_paths==32'h1)
							num_cp_fp0_fifo.enq(num_req_fp0);
						else if(num_paths==32'h2)begin
							num_cp_fp0_fifo.enq(num_req_fp0);
							num_cp_fp1_fifo.enq(num_req_fp0); //
						end else if(num_paths==32'h4) begin
							num_cp_fp0_fifo.enq(num_req_fp0); //
							num_cp_fp1_fifo.enq(num_req_fp0); //
							num_cp_fp2_fifo.enq(num_req_fp0); //
							num_cp_fp3_fifo.enq(num_req_fp0); //
						end

						req[63] = 1;
						if (num_req_fp0==1)
							sent_cmds_fp0 <= 0;
						else
							sent_cmds_fp0 <= sent_cmds_fp0 +1;
					end else if(sent_cmds_fp0==(num_req_fp0-1)) begin
						req[63] = 0;
						sent_cmds_fp0 <= 0;
					end else begin
						req[63] = 0;
						sent_cmds_fp0 <= sent_cmds_fp0 +1;
					end
					fp0_fifo.enq(req);
					//$display("Fp0 - num_cmds: %d - send_cmd: %d",num_req_fp0,sent_cmds_fp0); end
					$display("Fp0 "); end
			endcase	
			req_fifo.deq;		
		end
	endrule
	
	rule getRdReq;
		let req <- rd_slave.tlm.tx.get();
		Axi32BusResponse resp = defaultValue;
		resp.error = False; //Signal that no errors occured

		if (req.address[11:2]==10'h000)
			resp.data = num_of_qids;
		else if (req.address[11:2]==10'h001) begin
			if(qid_mask[0]==0) begin
				qid_mask[0] <= 1;
				resp.data = 0;
				//$display("The resp.data is : (0x%0x)\n",resp.data);
				//i = 100;		// break when i>NumQids
			end else
				resp.data = -1;		// no available queue
		end else
			resp.data = 32'hdeadbeaf;

		resp.id = req.id; //The id of the incoming req needs to be passed back
		rd_slave.tlm.rx.put(resp);
	endrule

	//This rule will take data passed from the ARM to the model, as parameters to the function
	rule getWrCmd;
		//First take a request from the write master
  		let req <- wr_slave.tlm.tx.get();
		if (req.address[11:2]==10'h000)
			num_of_qids <= req.data;
		else if (req.address[11:2]==10'h001) begin
			qid_mask[0] <= 0;
			num_req_fp0 <= 0;
		end else if (req.address[11:2]==10'h002) begin
			wr_qid <= req.data[29:16];
			wr_fpd <= req.data[15:0];
		end else if (req.address[11:2]==10'h003)
			req_fifo.enq({req.data,wr_fpd,wr_qid,2'h1});	// wr_req = ((op==1),fpd,size)
		else if (req.address[11:2]==10'h004) begin
			rd_qid <= req.data[29:16];
			rd_fpd <= req.data[15:0];
		end else if (req.address[11:2]==10'h005)
			req_fifo.enq({req.data,rd_fpd,rd_qid,2'h2});	// rd_req = ((op==2),fpd,size)
		else if (req.address[11:2]==10'h006)
			num_req_fp0 <= req.data;//fromInteger(log2(valueOf(256)));
		else if (req.address[11:2]==10'h007)
			num_compl_fp0 <= req.data;
		else if (req.address[11:2]==10'h008)
			num_req_fp1 <= req.data;
		else if (req.address[11:2]==10'h009)
			num_compl_fp1 <= req.data;
		else if (req.address[11:2]==10'h00a)
			num_req_fp2 <= req.data;//fromInteger(log2(valueOf(256)));
		else if (req.address[11:2]==10'h00b)
			num_compl_fp2 <= req.data;
		else if (req.address[11:2]==10'h00c)
			num_req_fp3 <= req.data;//fromInteger(log2(valueOf(256)));
		else if (req.address[11:2]==10'h00d)
			num_compl_fp3 <= req.data;
		

		//Acknowledge that we got the data
		Axi32BusResponse resp = defaultValue;
		resp.error = False;		//Signal that no errors occured
		resp.id = req.id; 		//We need to pass back the id of the incoming req
	    	wr_slave.tlm.rx.put(resp);
	endrule

	method ActionValue #(Bit#(64)) get_req2fp0();
		let req = fp0_fifo.first();
		fp0_fifo.deq();
		return(req);
	endmethod
	
	method ActionValue #(Bit#(32)) start_pollingfp0();
		let req = num_cp_fp0_fifo.first();
		num_cp_fp0_fifo.deq();
		return(req);
	endmethod

	method ActionValue #(Bit#(32)) start_pollingfp1();
		let req = num_cp_fp1_fifo.first();
		num_cp_fp1_fifo.deq();
		return(req);
	endmethod
	method ActionValue #(Bit#(32)) start_pollingfp2();
		let req = num_cp_fp2_fifo.first();
		num_cp_fp2_fifo.deq();
		return(req);
	endmethod
	method ActionValue #(Bit#(32)) start_pollingfp3();
		let req = num_cp_fp3_fifo.first();
		num_cp_fp3_fifo.deq();
		return(req);
	endmethod

	method Action setQidMask (Bit#(1) qid_in);
		fake_qid <= qid_in;
	endmethod
	method Bit#(1) getQidMask();
		let res = {qid_mask[0]};
		return(res);
	endmethod

	interface sread = rd_slave.fabric;
	interface swrite = wr_slave.fabric;

endmodule :fastpath_controller_mp

module fastpath_controller_mp_bs (Axibs_ifc);
  AXI_ifc axiModule <- fastpath_controller_mp() ;
  //THIS WORKS OK FOR A SYSTEM BUT FOR A XILINX SYSTEM LETS BIN THE ADDRESS STUFF

  AddressRange#(Zynq_Axi32_Addr) axiModule_params = defaultValue;
  axiModule_params.base = 32'h0000_0000;
  axiModule_params.high = 32'h0002_0000 - 1;

	interface AxiRdFabricSlave sread;
		interface AxiRdSlave bus = axiModule.sread;
		method Bool addrMatch(Zynq_Axi32_Addr value) = False;
	endinterface

	interface AxiWrFabricSlave swrite;
		interface AxiWrSlave bus = axiModule.swrite;
		method Bool addrMatch(Zynq_Axi32_Addr value) = False;
	endinterface

	method ActionValue #(Bit#(64)) get_req2fp0();
		let res <- axiModule.get_req2fp0();
		return(res);
	endmethod

	method ActionValue #(Bit#(32)) start_pollingfp0();
		let res <- axiModule.start_pollingfp0();
		return(res);
	endmethod

	method ActionValue #(Bit#(32)) start_pollingfp1();
		let res <- axiModule.start_pollingfp1();
		return(res);
	endmethod

	method ActionValue #(Bit#(32)) start_pollingfp2();
		let res <- axiModule.start_pollingfp2();
		return(res);
	endmethod

	method ActionValue #(Bit#(32)) start_pollingfp3();
		let res <- axiModule.start_pollingfp3();
		return(res);
	endmethod

	method Action setQidMask (Bit#(1) qid_in);
		axiModule.setQidMask(qid_in);
	endmethod
	method Bit#(1) getQidMask();
		let res = axiModule.getQidMask();
		return(res);
	endmethod

endmodule

module test();
	Reg#(Bit#(32)) count_send <-mkReg(0);
	Reg#(Bit#(32)) count_read <-mkReg(0);
	Reg#(Bit#(32)) count_write <-mkReg(0);
	Reg#(Bit#(16)) count_a <-mkReg(0);
	Reg#(Bit#(32)) count_b <-mkReg(0);
	Reg#(Bit#(32)) iterations <-mkReg(0);
	Reg#(UInt#(32)) cycle <-mkReg(0);
	// The following are just stored for logging
	Reg#(UInt#(32)) wtr_count <- mkReg(0);
	Reg#(UInt#(32)) rt_count <- mkReg(0);
	Reg#(UInt#(32)) send_words <- mkReg(0);
	Reg#(Bit#(32)) c_reg <- mkReg(0);
	
	FIFOF#(Bit#(64)) test_fp0_fifo <- mkSizedFIFOF(8192);
	FIFOF#(Bit#(64)) test_fp1_fifo <- mkSizedFIFOF(8192);
	FIFOF#(Bit#(64)) test_fp2_fifo <- mkSizedFIFOF(8192);
	FIFOF#(Bit#(64)) test_fp3_fifo <- mkSizedFIFOF(8192);

	FIFOF#(Bit#(32)) test_polling_fp0_fifo <- mkSizedFIFOF(1024);
	FIFOF#(Bit#(32)) test_polling_fp1_fifo <- mkSizedFIFOF(1024);
	FIFOF#(Bit#(32)) test_polling_fp2_fifo <- mkSizedFIFOF(1024);
	FIFOF#(Bit#(32)) test_polling_fp3_fifo <- mkSizedFIFOF(1024);

	Axibs_ifc dut <- fastpath_controller_mp_bs ();

	AddressRange#(Zynq_ACP_Addr) t_params = defaultValue;
	t_params.base = 32'h0000_0000;
	t_params.high = 32'hFFFF_FFFF;

	Zynq_Axi32_rd_master_xactor read_master <- mkZynq_Axi32_rd_master_xactor;
	Zynq_Axi32_wr_master_xactor write_master <- mkZynq_Axi32_wr_master_xactor;

 	mkConnection(read_master.fabric.bus, dut.sread.bus);
 	mkConnection(write_master.fabric.bus, dut.swrite.bus );

 	rule sendWCmd ;//(iterations<1024);
		Axi32BusRequest req = defaultValue;
		req.write = True;
		req.byteen = -1;

		let c = count_send%9;
		c_reg <= count_send%9;

		if (iterations<1024) begin
			if (c==0 && iterations<4) begin
				req.address = 32'h53c00018+(iterations<<3);
				req.data = 8;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==1 && iterations<4) begin
				req.address = 32'h53c0001C+(iterations<<3);
				req.data = 2;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==2) begin
				req.address = 32'h53c00008;
				req.data = {0,16'h2000};
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
				/*if((count_a+1) ==16'h4)
					count_a <=0;
				else
					count_a <= count_a + 1;*/
			end else if (c==3) begin
				req.address = 32'h53c0000C;
				req.data = 32'h00002000;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
				iterations <= iterations + 1;
			end else begin
				req.address = 32'h53c0_fff0;
				req.data = 0;
			end
		end else if (count_b<4) begin
			req.address = 32'h53c00004;
			req.data = count_b;
			$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			//if((count_b+1) ==32'h4)
			//	count_b <=0;
			//else
				count_b <= count_b + 1;
		end else begin
			req.address = 32'h53c0_fff0;
			req.data = 0;
		end

		write_master.tlm.rx.put(req);
		count_send <= count_send + 1;
 	endrule

	
	rule getReqFromFp0;
		let req <- dut.get_req2fp0();
		test_fp0_fifo.enq(req);
	endrule
	
	rule submitFp0;
		let req = test_fp0_fifo.first();
		test_fp0_fifo.deq();
	endrule

	//POLLING

	rule getPollingFp0;
		let req <- dut.start_pollingfp0();
		test_polling_fp0_fifo.enq(req);
	endrule
	
	rule releaseFp0;
		let req = test_polling_fp0_fifo.first();
		test_polling_fp0_fifo.deq();
	endrule

	rule getPollingFp1;
		let req <- dut.start_pollingfp1();
		test_polling_fp1_fifo.enq(req);
	endrule
	
	rule releaseFp1;
		let req = test_polling_fp1_fifo.first();
		test_polling_fp1_fifo.deq();
	endrule

	rule getPollingFp2;
		let req <- dut.start_pollingfp2();
		test_polling_fp2_fifo.enq(req);
	endrule
	
	rule releaseFp2;
		let req = test_polling_fp2_fifo.first();
		test_polling_fp2_fifo.deq();
	endrule

	rule getPollingFp3;
		let req <- dut.start_pollingfp3();
		test_polling_fp3_fifo.enq(req);
	endrule
	
	rule releaseFp3;
		let req = test_polling_fp3_fifo.first();
		test_polling_fp3_fifo.deq();
	endrule

 	// We send a read request and will get a response when avaliable, the master will
 	// stall if we send too many
 	rule sendRCmd (count_send<30);
		Axi32BusRequest req = defaultValue;
		let c = count_send%9;
		if (c<4)
			req.address = 32'h53c00004;
		else
			req.address = 32'h53c000f4;
		req.write = False;
	        	req.byteen = -1;
		read_master.tlm.rx.put(req);

		count_read <= count_read + 1;
	endrule

 	// We need to read data back from the Slave AXI port of our module,
	// this will only fire if there is data to read
 	rule rr;
 		let resp <- read_master.tlm.tx.get();
 		$display($time,"Qid returned data: (0x%0x)from address 32'h53c00004!!\n",resp.data);
 	endrule

 	// We also ALWAYS need to check write responses
 	rule wr;
 		let resp <- write_master.tlm.tx.get();
 	endrule

 	// This is to stop when finished
	rule go;
		if(cycle==120000)begin
			$finish;
		end
		cycle<=cycle+1;
	endrule
endmodule

endpackage:FASTPATH_CONTROLLER_MP
