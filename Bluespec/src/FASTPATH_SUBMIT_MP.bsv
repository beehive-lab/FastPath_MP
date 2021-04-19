/*
 * Copyright (c) 2018, Thanos Stratikopoulos, APT Group, Department of Computer Science,
 * School of Engineering, The University of Manchester. All rights reserved.
 */
package FASTPATH_SUBMIT_MP;

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

import NVME_SUBMIT_CMD::*;

// NVMe commands are 64 bytes wide. So, sixteen 32-bit words
// are required to store each command
typedef 15 NumElements;
`define BLOCK_SIZE 4096


interface AXI_ifc;
	(* prefix="M_AXI_SUBMIT0" *)
	interface Zynq_ACP_rd_master mread_sub0;
	(* prefix="M_AXI_SUBMIT0" *)
	interface Zynq_ACP_wr_master mwrite_sub0;
	(* prefix="M_AXI_DB0" *)
	interface Zynq_ACP_rd_master mread_db0;
	(* prefix="M_AXI_DB0" *)
	interface Zynq_ACP_wr_master mwrite_db0;
	(* prefix="M_AXI_SUBMIT1" *)
	interface Zynq_ACP_rd_master mread_sub1;
	(* prefix="M_AXI_SUBMIT1" *)
	interface Zynq_ACP_wr_master mwrite_sub1;
	(* prefix="M_AXI_DB1" *)
	interface Zynq_ACP_rd_master mread_db1;
	(* prefix="M_AXI_DB1" *)
	interface Zynq_ACP_wr_master mwrite_db1;

	(* prefix="M_AXI_SUBMIT2" *)
	interface Zynq_ACP_rd_master mread_sub2;
	(* prefix="M_AXI_SUBMIT2" *)
	interface Zynq_ACP_wr_master mwrite_sub2;
	(* prefix="M_AXI_DB2" *)
	interface Zynq_ACP_rd_master mread_db2;
	(* prefix="M_AXI_DB2" *)
	interface Zynq_ACP_wr_master mwrite_db2;
	(* prefix="M_AXI_SUBMIT3" *)
	interface Zynq_ACP_rd_master mread_sub3;
	(* prefix="M_AXI_SUBMIT3" *)
	interface Zynq_ACP_wr_master mwrite_sub3;
	(* prefix="M_AXI_DB3" *)
	interface Zynq_ACP_rd_master mread_db3;
	(* prefix="M_AXI_DB3" *)
	interface Zynq_ACP_wr_master mwrite_db3;
	(*prefix="S_AXI" *)
	interface Zynq_Axi32_rd_slave sread;
	(* prefix="S_AXI" *)
	interface Zynq_Axi32_wr_slave swrite;

	(* always_enabled, prefix="" *)
	method Action setHead0 (Bit#(32) h0_in);
	(* always_enabled, prefix="" *)
	method Action setHead1 (Bit#(32) h1_in);
	(* always_enabled, prefix="" *)
	method Action setHead2 (Bit#(32) h2_in);
	(* always_enabled, prefix="" *)
	method Action setHead3 (Bit#(32) h3_in);

	//(* always_enabled, prefix="" *)
	//method Action set_req ((*port="SET_REQ"*)Bit#(64) req_in);
	method Action set_req (Bit#(64) req_in);
endinterface

//The bs interface makes the stuff compatible with bluespec transactors (although maybe not so much Xilinx)
interface Axibs_ifc;
	(* prefix="M_AXI_SUBMIT0" *)
	interface Zynq_ACP_rd_master mread_sub0;
	(* prefix="M_AXI_SUBMIT0" *)
	interface Zynq_ACP_wr_master mwrite_sub0;
	(* prefix="M_AXI_DB0" *)
	interface Zynq_ACP_rd_master mread_db0;
	(* prefix="M_AXI_DB0" *)
	interface Zynq_ACP_wr_master mwrite_db0;
	(* prefix="M_AXI_SUBMIT1" *)
	interface Zynq_ACP_rd_master mread_sub1;
	(* prefix="M_AXI_SUBMIT1" *)
	interface Zynq_ACP_wr_master mwrite_sub1;
	(* prefix="M_AXI_DB1" *)
	interface Zynq_ACP_rd_master mread_db1;
	(* prefix="M_AXI_DB1" *)
	interface Zynq_ACP_wr_master mwrite_db1;

	(* prefix="M_AXI_SUBMIT2" *)
	interface Zynq_ACP_rd_master mread_sub2;
	(* prefix="M_AXI_SUBMIT2" *)
	interface Zynq_ACP_wr_master mwrite_sub2;
	(* prefix="M_AXI_DB2" *)
	interface Zynq_ACP_rd_master mread_db2;
	(* prefix="M_AXI_DB2" *)
	interface Zynq_ACP_wr_master mwrite_db2;
	(* prefix="M_AXI_SUBMIT3" *)
	interface Zynq_ACP_rd_master mread_sub3;
	(* prefix="M_AXI_SUBMIT3" *)
	interface Zynq_ACP_wr_master mwrite_sub3;
	(* prefix="M_AXI_DB3" *)
	interface Zynq_ACP_rd_master mread_db3;
	(* prefix="M_AXI_DB3" *)
	interface Zynq_ACP_wr_master mwrite_db3;

	(*prefix="S_AXI" *)
	interface Zynq_Axi32_rd_dec_slave sread;
	(* prefix="S_AXI" *)
	interface Zynq_Axi32_wr_dec_slave swrite;

	(* always_enabled, prefix="" *)
	method Action setHead0 (Bit#(32) h0_in);
	(* always_enabled, prefix="" *)
	method Action setHead1 (Bit#(32) h1_in);
	(* always_enabled, prefix="" *)
	method Action setHead2 (Bit#(32) h2_in);
	(* always_enabled, prefix="" *)
	method Action setHead3 (Bit#(32) h3_in);

	//(* always_enabled, prefix="" *)
	//method Action set_req ((*port="SET_REQ"*)Bit#(64) req_in);
	method Action set_req (Bit#(64) req_in);
endinterface

(* synthesize *)
module fastpath_submit_mp(AXI_ifc);
	Zynq_ACP_rd_master_xactor 	rd_master_sub0 	<- mkZynq_ACP_rd_master_xactor; //This moves our TLM Read interface interface to AXI
	Zynq_ACP_wr_master_xactor 	wr_master_sub0 	<- mkZynq_ACP_wr_master_xactor; //This moves our TLM Write interface interface to AXI
	Zynq_ACP_rd_master_xactor 	rd_master_db0 	<- mkZynq_ACP_rd_master_xactor; //This moves our TLM Read interface interface to AXI
	Zynq_ACP_wr_master_xactor 	wr_master_db0 	<- mkZynq_ACP_wr_master_xactor; //This moves our TLM Write interface interface to AXI
	Zynq_ACP_rd_master_xactor 	rd_master_sub1 	<- mkZynq_ACP_rd_master_xactor; //This moves our TLM Read interface interface to AXI
	Zynq_ACP_wr_master_xactor 	wr_master_sub1 	<- mkZynq_ACP_wr_master_xactor; //This moves our TLM Write interface interface to AXI
	Zynq_ACP_rd_master_xactor 	rd_master_db1 	<- mkZynq_ACP_rd_master_xactor; //This moves our TLM Read interface interface to AXI
	Zynq_ACP_wr_master_xactor 	wr_master_db1 	<- mkZynq_ACP_wr_master_xactor; //This moves our TLM Write interface interface to AXI
	Zynq_ACP_rd_master_xactor 	rd_master_sub2 	<- mkZynq_ACP_rd_master_xactor; //This moves our TLM Read interface interface to AXI
	Zynq_ACP_wr_master_xactor 	wr_master_sub2 	<- mkZynq_ACP_wr_master_xactor; //This moves our TLM Write interface interface to AXI
	Zynq_ACP_rd_master_xactor 	rd_master_db2 	<- mkZynq_ACP_rd_master_xactor; //This moves our TLM Read interface interface to AXI
	Zynq_ACP_wr_master_xactor 	wr_master_db2 	<- mkZynq_ACP_wr_master_xactor; //This moves our TLM Write interface interface to AXI
	Zynq_ACP_rd_master_xactor 	rd_master_sub3 	<- mkZynq_ACP_rd_master_xactor; //This moves our TLM Read interface interface to AXI
	Zynq_ACP_wr_master_xactor 	wr_master_sub3 	<- mkZynq_ACP_wr_master_xactor; //This moves our TLM Write interface interface to AXI
	Zynq_ACP_rd_master_xactor 	rd_master_db3 	<- mkZynq_ACP_rd_master_xactor; //This moves our TLM Read interface interface to AXI
	Zynq_ACP_wr_master_xactor 	wr_master_db3 	<- mkZynq_ACP_wr_master_xactor; //This moves our TLM Write interface interface to AXI
	Zynq_Axi32_rd_slave_xactor 	rd_slave 		<- mkZynq_Axi32_rd_slave_xactor(1); //these are the input side Axi to tlm
	Zynq_Axi32_wr_slave_xactor 	wr_slave 		<- mkZynq_Axi32_wr_slave_xactor(1); //these are the input side Axi to tlm

	NvmeSubmitCmd_ifc 		nvmetr_ifc_0 	<- mkNvmeSubmitCmd();
	NvmeSubmitCmd_ifc 		nvmetr_ifc_1 	<- mkNvmeSubmitCmd();
	NvmeSubmitCmd_ifc 		nvmetr_ifc_2 	<- mkNvmeSubmitCmd();
	NvmeSubmitCmd_ifc 		nvmetr_ifc_3 	<- mkNvmeSubmitCmd();

	FIFOF#(ACPBusRequest) 	faread_sub0	<- mkSizedFIFOF(1);
	FIFOF#(ACPBusRequest) 	faread_db0	<- mkSizedFIFOF(1);
	FIFOF#(ACPBusRequest) 	fawrite_sub0	<- mkSizedFIFOF(1024);
	FIFOF#(ACPBusRequest) 	fawrite_db0	<- mkSizedFIFOF(1024);
	FIFOF#(ACPBusRequest) 	faread_sub1	<- mkSizedFIFOF(1);
	FIFOF#(ACPBusRequest) 	faread_db1	<- mkSizedFIFOF(1);
	FIFOF#(ACPBusRequest) 	fawrite_sub1	<- mkSizedFIFOF(1024);
	FIFOF#(ACPBusRequest) 	fawrite_db1	<- mkSizedFIFOF(1024);
	FIFOF#(ACPBusRequest) 	faread_sub2	<- mkSizedFIFOF(1);
	FIFOF#(ACPBusRequest) 	faread_db2	<- mkSizedFIFOF(1);
	FIFOF#(ACPBusRequest) 	fawrite_sub2	<- mkSizedFIFOF(1024);
	FIFOF#(ACPBusRequest) 	fawrite_db2	<- mkSizedFIFOF(1024);
	FIFOF#(ACPBusRequest) 	faread_sub3	<- mkSizedFIFOF(1);
	FIFOF#(ACPBusRequest) 	faread_db3	<- mkSizedFIFOF(1);
	FIFOF#(ACPBusRequest) 	fawrite_sub3	<- mkSizedFIFOF(1024);
	FIFOF#(ACPBusRequest) 	fawrite_db3	<- mkSizedFIFOF(1024);

	FIFOF#(Bit#(64))	req_fifo		<- mkSizedFIFOF(1024);

	Reg#(Bool) 		submission_0_flag	<- mkReg(False);
	Reg#(Bool) 		submission_1_flag	<- mkReg(False);
	Reg#(Bool) 		submission_2_flag	<- mkReg(False);
	Reg#(Bool) 		submission_3_flag	<- mkReg(False);

	Reg#(Bool) 		go2DB0_reg	<- mkReg(False);
	RWire#(Bool) 		go2DB0_wire 	<- mkRWire();
	Reg#(Bool) 		go2DB1_reg	<- mkReg(False);
	RWire#(Bool) 		go2DB1_wire 	<- mkRWire();
	Reg#(Bool) 		go2DB2_reg	<- mkReg(False);
	RWire#(Bool) 		go2DB2_wire 	<- mkRWire();
	Reg#(Bool) 		go2DB3_reg	<- mkReg(False);
	RWire#(Bool) 		go2DB3_wire 	<- mkRWire();

	Reg#(Bool) 		release_sub0_flag_reg <- mkReg(False);
	RWire#(Bool) 		release_sub0_flag_wire <- mkRWire();
	Reg#(Bool) 		release_sub1_flag_reg <- mkReg(False);
	RWire#(Bool) 		release_sub1_flag_wire <- mkRWire();
	Reg#(Bool) 		release_sub2_flag_reg <- mkReg(False);
	RWire#(Bool) 		release_sub2_flag_wire <- mkRWire();
	Reg#(Bool) 		release_sub3_flag_reg <- mkReg(False);
	RWire#(Bool) 		release_sub3_flag_wire <- mkRWire();

	Reg#(Bool) 		first2		<- mkReg(True);
	Reg#(Bool) 		first_0		<- mkReg(True);
	Reg#(Bool) 		second_0		<- mkReg(False);
	Reg#(Bool) 		third_0		<- mkReg(False);
	Reg#(Bool) 		fourth_0 		<- mkReg(False);
	Reg#(Bool) 		fifth_0 		<- mkReg(False);
	Reg#(Bool) 		sixth_0 		<- mkReg(False);
	Reg#(Bool) 		seventh_0 	<- mkReg(False);
	Reg#(Bit#(64)) 		second_word_0	<- mkReg(0);
	Reg#(Bit#(64)) 		third_word_0	<- mkReg(0);
	Reg#(Bit#(64)) 		fourth_word_0 	<- mkReg(0);
	Reg#(Bit#(64)) 		fifth_word_0 	<- mkReg(0);
	Reg#(Bit#(64)) 		sixth_word_0 	<- mkReg(0);
	Reg#(Bit#(64)) 		seventh_word_0 	<- mkReg(0);
	Reg#(Bit#(64)) 		top_0		<- mkReg(0);
	Reg#(Bool) 		first_1		<- mkReg(True);
	Reg#(Bool) 		second_1		<- mkReg(False);
	Reg#(Bool) 		third_1		<- mkReg(False);
	Reg#(Bool) 		fourth_1 		<- mkReg(False);
	Reg#(Bool) 		fifth_1 		<- mkReg(False);
	Reg#(Bool) 		sixth_1 		<- mkReg(False);
	Reg#(Bool) 		seventh_1 	<- mkReg(False);
	Reg#(Bit#(64)) 		second_word_1	<- mkReg(0);
	Reg#(Bit#(64)) 		third_word_1	<- mkReg(0);
	Reg#(Bit#(64)) 		fourth_word_1 	<- mkReg(0);
	Reg#(Bit#(64)) 		fifth_word_1 	<- mkReg(0);
	Reg#(Bit#(64)) 		sixth_word_1 	<- mkReg(0);
	Reg#(Bit#(64)) 		seventh_word_1 	<- mkReg(0);
	Reg#(Bit#(64)) 		top_1		<- mkReg(0);
	Reg#(Bool) 		first_2		<- mkReg(True);
	Reg#(Bool) 		second_2		<- mkReg(False);
	Reg#(Bool) 		third_2		<- mkReg(False);
	Reg#(Bool) 		fourth_2 		<- mkReg(False);
	Reg#(Bool) 		fifth_2 		<- mkReg(False);
	Reg#(Bool) 		sixth_2 		<- mkReg(False);
	Reg#(Bool) 		seventh_2 	<- mkReg(False);
	Reg#(Bit#(64)) 		second_word_2	<- mkReg(0);
	Reg#(Bit#(64)) 		third_word_2	<- mkReg(0);
	Reg#(Bit#(64)) 		fourth_word_2 	<- mkReg(0);
	Reg#(Bit#(64)) 		fifth_word_2 	<- mkReg(0);
	Reg#(Bit#(64)) 		sixth_word_2 	<- mkReg(0);
	Reg#(Bit#(64)) 		seventh_word_2 	<- mkReg(0);
	Reg#(Bit#(64)) 		top_2		<- mkReg(0);
	Reg#(Bool) 		first_3		<- mkReg(True);
	Reg#(Bool) 		second_3		<- mkReg(False);
	Reg#(Bool) 		third_3		<- mkReg(False);
	Reg#(Bool) 		fourth_3 		<- mkReg(False);
	Reg#(Bool) 		fifth_3 		<- mkReg(False);
	Reg#(Bool) 		sixth_3 		<- mkReg(False);
	Reg#(Bool) 		seventh_3 	<- mkReg(False);
	Reg#(Bit#(64)) 		second_word_3	<- mkReg(0);
	Reg#(Bit#(64)) 		third_word_3	<- mkReg(0);
	Reg#(Bit#(64)) 		fourth_word_3 	<- mkReg(0);
	Reg#(Bit#(64)) 		fifth_word_3 	<- mkReg(0);
	Reg#(Bit#(64)) 		sixth_word_3 	<- mkReg(0);
	Reg#(Bit#(64)) 		seventh_word_3 	<- mkReg(0);
	Reg#(Bit#(64)) 		top_3		<- mkReg(0);

	Reg#(Bool)		usermode_reg	<- mkReg(True);
	Reg#(Bool) 		secure_reg	<- mkReg(False);
	Reg#(Bool) 		wa_reg		<- mkReg(False);
	Reg#(Bool) 		ra_reg		<- mkReg(False);
	Reg#(Bool) 		c_reg		<- mkReg(True);
	Reg#(Bool) 		b_reg		<- mkReg(True);
	Reg#(Bit#(32)) 		dma_addr_reg 	<- mkReg(0);

	Reg#(Bit#(32)) 		fp_d_0		<- mkReg(0);
	Reg#(Bit#(32)) 		fp_d_1		<- mkReg(0);
	Reg#(Bit#(32)) 		fp_d_2		<- mkReg(0);
	Reg#(Bit#(32)) 		fp_d_3		<- mkReg(0);

	Reg#(Bit#(8)) 		op		<- mkReg(0);
	Reg#(Bit#(8)) 		flags		<- mkReg(0);
	Reg#(Bit#(16)) 		command_id_0	<- mkReg(0);
	Reg#(Bit#(16)) 		command_id_1	<- mkReg(0);
	Reg#(Bit#(16)) 		command_id_2	<- mkReg(0);
	Reg#(Bit#(16)) 		command_id_3	<- mkReg(0);

	Reg#(Bit#(32)) 		nsid		<- mkReg(1);
	Reg#(Bit#(64)) 		rsvd2		<- mkReg(0);
	Reg#(Bit#(64)) 		metadata		<- mkReg(0);
	Reg#(Bit#(64)) 		prp1_0		<- mkReg(0);
	Reg#(Bit#(64)) 		prp1_1		<- mkReg(0);
	Reg#(Bit#(64)) 		prp1_2		<- mkReg(0);
	Reg#(Bit#(64)) 		prp1_3		<- mkReg(0);

	Reg#(Bit#(64)) 		prp2		<- mkReg(0);
	Reg#(Bit#(64)) 		slba_0		<- mkReg(0);
	Reg#(Bit#(64)) 		slba_1		<- mkReg(0);
	Reg#(Bit#(64)) 		slba_2		<- mkReg(0);
	Reg#(Bit#(64)) 		slba_3		<- mkReg(0);

	Reg#(Bit#(16)) 		length		<- mkReg(7);
	Reg#(Bit#(16)) 		control		<- mkReg(0);
	Reg#(Bit#(32)) 		dsmgmt		<- mkReg(0);
	Reg#(Bit#(32)) 		reftag		<- mkReg(0);
	Reg#(Bit#(16)) 		apptag		<- mkReg(0);
	Reg#(Bit#(16)) 		appmask		<- mkReg(0);

	//Reg#(Bit#(32)) 		data_size		<- mkReg(0);
	Reg#(Bit#(32)) 		num_of_paths	<- mkReg(0);
	Reg#(Bit#(32)) 		synth_cmds	<- mkReg(0);
	Reg#(Bool) 		synth_cmd_0_reg	<- mkReg(False);
	Reg#(Bool) 		synth_cmd_1_reg	<- mkReg(False);
	Reg#(Bool) 		synth_cmd_2_reg	<- mkReg(False);
	Reg#(Bool) 		synth_cmd_3_reg	<- mkReg(False);

	Reg#(Bit#(32))		fake_op		<- mkReg(0);
	Reg#(Bit#(32))		fake_size		<- mkReg(0);
	Reg#(Bit#(32))		fake_cmds		<- mkReg(0);
	Reg#(Bit#(32))		fake_prp1		<- mkReg(0);
	Reg#(Bit#(64))		fake_slba		<- mkReg(0);
	Reg#(Bit#(32))		fake_fpd		<- mkReg(0);
	Reg#(Bit#(32))		fake_dma		<- mkReg(0);
	Reg#(Bit#(32))		fake_flag		<- mkReg(0);
	Reg#(Bit#(32))		fake_tailhead		<- mkReg(0);
	Reg#(Bit#(32))		head_0_reg		<- mkReg(0);
	Reg#(Bit#(32))		head_1_reg		<- mkReg(0);
	Reg#(Bit#(32))		head_2_reg		<- mkReg(0);
	Reg#(Bit#(32))		head_3_reg		<- mkReg(0);

	Reg#(Bit#(32))		cur_tail		<- mkReg(0);
	Reg#(Bit#(32))		fake_sflag	<- mkReg(0);
	Reg#(Bit#(32))		fake_go2db	<- mkReg(0);

	Vector#(NumElements,Reg#(Bit#(32))) cmd_bottom_reg;

	for(Integer i=0; i<valueOf(NumElements); i=i+1)
		cmd_bottom_reg[i] <- mkReg(0);

	//----------------------------------------------------------------------------------
	rule formCmd(!synth_cmd_0_reg && !submission_0_flag && !synth_cmd_1_reg && !submission_1_flag && !synth_cmd_2_reg && !submission_2_flag && !synth_cmd_3_reg && !submission_3_flag);
		let req_entry = req_fifo.first();
		req_fifo.deq();
		let le=16'h7; //let le=16'h0;

		op 	<= zeroExtend(req_entry[1:0]);
		//data_size <= zeroExtend(req_entry[62:32]);
		let num_paths = 32'h0;
		num_paths = zeroExtend(req_entry[62:32])>>12;
		num_of_paths <= num_paths;

		case(num_paths)
				32'd1: begin
					// SLBA
					if(req_entry[63]==1)
						slba_0 	<= zeroExtend(req_entry[31:16])<<28;
					else begin
						let lba_offset_0 	= le+1;	
						slba_0	<= slba_0 + zeroExtend(lba_offset_0);
					end
		
					// PRP
					if(req_entry[63]==1)
						prp1_0 	<= zeroExtend(dma_addr_reg);
					else begin
						let offset_0 	= 32'h1000;//req_entry[62:32];	// block size
						prp1_0		<= prp1_0 + zeroExtend(offset_0);
					end

					fp_d_0 	<= zeroExtend(req_entry[31:16]);
					synth_cmd_0_reg <= True;
				end 31'd2: 	begin
					// SLBA
					if(req_entry[63]==1) begin
						slba_0 	<= zeroExtend(req_entry[31:16])<<28;
						let lba_offset_1 	= le+1;	
						slba_1	<= (zeroExtend(req_entry[31:16])<<28) + zeroExtend(lba_offset_1);
					end else begin
						let lba_offset_0 	= le+1;	
						slba_0	<= slba_0 + (zeroExtend(lba_offset_0)<<64'h1);
						let lba_offset_1 	= le+1;	
						slba_1	<= slba_1 + (zeroExtend(lba_offset_1)<<64'h1);
					end
		
					// PRP
					if(req_entry[63]==1) begin
						prp1_0 	<= zeroExtend(dma_addr_reg);
						let offset_1 	= 32'h1000;	// block size
						prp1_1		<= zeroExtend(dma_addr_reg) + zeroExtend(offset_1);
					end else begin
						let offset_0 	= 32'h1000;	// block size
						prp1_0		<= prp1_0 + (zeroExtend(offset_0)<<64'h1);
						let offset_1 	= 32'h1000;	// block size
						prp1_1		<= prp1_1 + (zeroExtend(offset_1)<<64'h1);
					end

					fp_d_0 	<= zeroExtend(req_entry[31:16]);
					fp_d_1 	<= zeroExtend(req_entry[31:16]);
					synth_cmd_0_reg <= True;
					synth_cmd_1_reg <= True;
				end 31'd4: 	begin
					// SLBA
					if(req_entry[63]==1) begin
						slba_0 	<= zeroExtend(req_entry[31:16])<<28;
						let lba_offset_1 	= le+1;	
						slba_1	<= (zeroExtend(req_entry[31:16])<<28) + zeroExtend(lba_offset_1);
						let lba_offset_2 	= 32'h10;	
						slba_2	<= (zeroExtend(req_entry[31:16])<<28) + zeroExtend(lba_offset_2);
						let lba_offset_3 	= 32'h18;	
						slba_3	<= (zeroExtend(req_entry[31:16])<<28) + zeroExtend(lba_offset_3);
					end else begin
						let lba_offset_0 	= le+1;	
						slba_0	<= slba_0 + (zeroExtend(lba_offset_0)<<64'h2);
						slba_1	<= slba_1 + (zeroExtend(lba_offset_0)<<64'h2);
						slba_2	<= slba_2 + (zeroExtend(lba_offset_0)<<64'h2);
						slba_3	<= slba_3 + (zeroExtend(lba_offset_0)<<64'h2);
					end
		
					// PRP
					if(req_entry[63]==1) begin
						prp1_0 	<= zeroExtend(dma_addr_reg);
						let offset_1 	= 32'h1000;	// block size
						prp1_1		<= zeroExtend(dma_addr_reg) + zeroExtend(offset_1);
						let offset_2 	= 32'h2000;	// block size
						prp1_2		<= zeroExtend(dma_addr_reg) + zeroExtend(offset_2);
						let offset_3 	= 32'h3000;	// block size
						prp1_3		<= zeroExtend(dma_addr_reg) + zeroExtend(offset_3);
					end else begin
						let offset_0 	= 32'h1000;	// block size
						prp1_0		<= prp1_0 + (zeroExtend(offset_0)<<64'h2);
						prp1_1		<= prp1_1 + (zeroExtend(offset_0)<<64'h2);
						prp1_2		<= prp1_2 + (zeroExtend(offset_0)<<64'h2);
						prp1_3		<= prp1_3 + (zeroExtend(offset_0)<<64'h2);
					end

					fp_d_0 	<= zeroExtend(req_entry[31:16]);
					fp_d_1 	<= zeroExtend(req_entry[31:16]);
					fp_d_2 	<= zeroExtend(req_entry[31:16]);
					fp_d_3 	<= zeroExtend(req_entry[31:16]);
					synth_cmd_0_reg <= True;
					synth_cmd_1_reg <= True;
					synth_cmd_2_reg <= True;
					synth_cmd_3_reg <= True;
				end
		endcase

		length 	<= le;
	endrule

	//----------------------------------------------------- Queue 0
	// AXI_SUBMIT port
	rule fwSub0; //forward write requests
		let r = fawrite_sub0.first;
		wr_master_sub0.tlm.rx.put(r);
		fawrite_sub0.deq();
	endrule

	rule frSub0; //forward read requests
		let r = faread_sub0.first;
		rd_master_sub0.tlm.rx.put(r);
		faread_sub0.deq();
	endrule

	rule mreadRespSub0; //when the output side read receives a read response
		let resp <- rd_master_sub0.tlm.tx.get ();
	endrule

	rule mwriteRespSub0;//just swallow the responses from the write channel and go to doorbell update
		let resp <- wr_master_sub0.tlm.tx.get ();
		go2DB0_wire.wset(True);
	endrule

	// AXI_DB port
	rule fwDb0; //forward write requests
		let r = fawrite_db0.first;
		wr_master_db0.tlm.rx.put(r);
		fawrite_db0.deq();
	endrule

	rule frDb0; //forward read requests
		let r = faread_db0.first;
		rd_master_db0.tlm.rx.put(r);
		faread_db0.deq();
	endrule

	rule mreadRespDb0; //when the output side read receives a read response
		let resp <- rd_master_db0.tlm.tx.get ();
	endrule

	rule mwriteRespDb0;//just swallow the responses from the write channel
		let resp <- wr_master_db0.tlm.tx.get ();
		//submission_flag <= False;
		release_sub0_flag_wire.wset(True);
	endrule
	//
	rule releaseSub0Flag(submission_0_flag && release_sub0_flag_reg);
		submission_0_flag <= False;
	endrule

	// This rule submits NVMe commands as 8 64-bit burst words
	rule forwardCmd0 (submission_0_flag && !go2DB0_reg);
		ACPBusRequest forward = defaultValue;
		forward.b=b_reg;
		forward.c=c_reg;
		forward.ra=ra_reg;
		forward.wa=wa_reg;
		forward.user=1;
		forward.usermode=usermode_reg;
		forward.secure=secure_reg;
		$display("Request: %d %d %d %d - Prot: %d %d",forward.b,forward.c,forward.ra,forward.wa,forward.secure,forward.usermode );
		forward.write = True;

		if(first_0) begin
			let tail = nvmetr_ifc_0.getSqAddrOffset();
			let addr = nvmetr_ifc_0.getSqAddr() + ((tail)<<6);
			
			forward.address = addr;
			forward.byteen= 8'hff;

			let cmd <- nvmetr_ifc_0.submitCmd();
			$display($time,"submit cmd is called!");
			first_0<=False;
			forward.data = cmd[63:0];
			second_word_0 <= cmd[127:64];
			third_word_0 <= cmd[191:128];
			fourth_word_0 <= cmd[255:192];
			fifth_word_0 <= cmd[319:256];
			sixth_word_0 <= cmd[383:320];
			seventh_word_0 <= cmd[447:384];
			top_0 <= cmd[511:448];
			$display("Q0 - Req_address: 0x%x | Address: 0x%x - sq_addr: 0x%x - cmd[255-192]: 0x%x | cmd[191-128]: 0x%x | cmd[127-64]: 0x%x | cmd[63-0]: 0x%x - tail:%d",addr,nvmetr_ifc_0.getSqAddr() + ((tail)<<6),nvmetr_ifc_0.getSqAddr(),cmd[255:192],cmd[191:128],cmd[127:64],cmd[63:0],(tail));
			$display("Q0 - cmd[511:448]: 0x%x | cmd[447:384]: 0x%x | cmd[383:320]: 0x%x | cmd[319:256]: 0x%x ",cmd[511:448],cmd[447:384],cmd[383:320],cmd[319:256]);
			second_0 <= True;
		end else if(second_0) begin
			let tail = nvmetr_ifc_0.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",second_word,(tail));
			second_0<=False;
			forward.data = second_word_0;
			third_0 <= True;
		end else if(third_0) begin
			let tail = nvmetr_ifc_0.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			third_0<=False;
			forward.data = third_word_0;
			fourth_0 <= True;
		end else if(fourth_0) begin
			let tail = nvmetr_ifc_0.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			fourth_0<=False;
			forward.data = fourth_word_0;
			fifth_0 <= True;
        	end else if(fifth_0) begin
			let tail = nvmetr_ifc_0.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			fifth_0<=False;
			forward.data = fifth_word_0;
			sixth_0 <= True;
        	end else if(sixth_0) begin
			let tail = nvmetr_ifc_0.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			sixth_0<=False;
			forward.data = sixth_word_0;
			seventh_0 <= True;
        	end else if(seventh_0) begin
			let tail = nvmetr_ifc_0.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			seventh_0 <=False;
			forward.data = seventh_word_0;
        	end else begin
			let tail = nvmetr_ifc_0.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",top,(tail));
			first_0<=True;
			forward.data = top_0;
		end
		forward.burst = 8;// it was 2 for 128bits
		forward.first = first_0;
		fawrite_sub0.enq(forward);
	endrule

	// This rule writes the new tail into the doorbell register
	rule go2DB0 (submission_0_flag && go2DB0_reg);
		ACPBusRequest forward = defaultValue;
		forward.b=b_reg;
		forward.c=c_reg;
		forward.ra=ra_reg;
		forward.wa=wa_reg;
		forward.user=1;
		forward.usermode=usermode_reg;
		forward.secure=secure_reg;
		$display("Q0 - Request: %d %d %d %d - Prot: %d %d",forward.b,forward.c,forward.ra,forward.wa,forward.secure,forward.usermode );
		forward.write = True;

		forward.address = nvmetr_ifc_0.getSqDBAddr();
		forward.byteen= 8'h0f;

		let tail = nvmetr_ifc_0.getSqTail();
		forward.data = zeroExtend(tail);
		$display("Q0 - Cur Tail: %d\n",tail);
		$display("Q0 - DB_address: 0x%x | Data: 0x%x",forward.address,forward.data);

		forward.burst = 1;
		forward.first = first2;
		fawrite_db0.enq(forward);
	endrule

	rule synthCmds0(synth_cmd_0_reg && !submission_0_flag);
		let tail = nvmetr_ifc_0.getSqTail();
		let pass = False;
		if(tail==1023)
			pass = (0==head_0_reg)?False:True;	
		else
			pass = (tail+1==head_0_reg)?False:True;		
		
		if(pass) begin
			let cmd = {appmask,apptag,reftag,dsmgmt,control,length,slba_0,prp2,prp1_0,metadata,rsvd2,nsid,command_id_0,flags,op};

			nvmetr_ifc_0.setCmd(cmd);
			submission_0_flag <= True;
			command_id_0 	<= command_id_0 + 1;
			synth_cmd_0_reg <= False;
		end
	endrule

	//----------------------------------------------------- Queue 1
	// AXI_SUBMIT port
	rule fwSub1; //forward write requests
		let r = fawrite_sub1.first;
		wr_master_sub1.tlm.rx.put(r);
		fawrite_sub1.deq();
	endrule

	rule frSub1; //forward read requests
		let r = faread_sub1.first;
		rd_master_sub1.tlm.rx.put(r);
		faread_sub1.deq();
	endrule

	rule mreadRespSub1; //when the output side read receives a read response
		let resp <- rd_master_sub1.tlm.tx.get ();
	endrule

	rule mwriteRespSub1;//just swallow the responses from the write channel and go to doorbell update
		let resp <- wr_master_sub1.tlm.tx.get ();
		go2DB1_wire.wset(True);
	endrule

	// AXI_DB port
	rule fwDb1; //forward write requests
		let r = fawrite_db1.first;
		wr_master_db1.tlm.rx.put(r);
		fawrite_db1.deq();
	endrule

	rule frDb1; //forward read requests
		let r = faread_db1.first;
		rd_master_db1.tlm.rx.put(r);
		faread_db1.deq();
	endrule

	rule mreadRespDb1; //when the output side read receives a read response
		let resp <- rd_master_db1.tlm.tx.get ();
	endrule

	rule mwriteRespDb1;//just swallow the responses from the write channel
		let resp <- wr_master_db1.tlm.tx.get ();
		//submission_flag <= False;
		release_sub1_flag_wire.wset(True);
	endrule
	//
	rule releaseSub1Flag(submission_1_flag && release_sub1_flag_reg);
		submission_1_flag <= False;
	endrule

	// This rule submits NVMe commands as 8 64-bit burst words
	rule forwardCmd1 (submission_1_flag && !go2DB1_reg);
		ACPBusRequest forward = defaultValue;
		forward.b=b_reg;
		forward.c=c_reg;
		forward.ra=ra_reg;
		forward.wa=wa_reg;
		forward.user=1;
		forward.usermode=usermode_reg;
		forward.secure=secure_reg;
		$display("Q1 - Request: %d %d %d %d - Prot: %d %d",forward.b,forward.c,forward.ra,forward.wa,forward.secure,forward.usermode );
		forward.write = True;

		if(first_1) begin
			let tail = nvmetr_ifc_1.getSqAddrOffset();
			let addr = nvmetr_ifc_1.getSqAddr() + ((tail)<<6);
			
			forward.address = addr;
			forward.byteen= 8'hff;

			let cmd <- nvmetr_ifc_1.submitCmd();
			$display($time,"submit cmd is called!");
			first_1<=False;
			forward.data = cmd[63:0];
			second_word_1 <= cmd[127:64];
			third_word_1 <= cmd[191:128];
			fourth_word_1 <= cmd[255:192];
			fifth_word_1 <= cmd[319:256];
			sixth_word_1 <= cmd[383:320];
			seventh_word_1 <= cmd[447:384];
			top_1 <= cmd[511:448];
			$display("Q1 - Req_address: 0x%x | Address: 0x%x - sq_addr: 0x%x - cmd[255-192]: 0x%x | cmd[191-128]: 0x%x | cmd[127-64]: 0x%x | cmd[63-0]: 0x%x - tail:%d",addr,nvmetr_ifc_1.getSqAddr() + ((tail)<<6),nvmetr_ifc_1.getSqAddr(),cmd[255:192],cmd[191:128],cmd[127:64],cmd[63:0],(tail));
			$display("Q1 - cmd[511:448]: 0x%x | cmd[447:384]: 0x%x | cmd[383:320]: 0x%x | cmd[319:256]: 0x%x ",cmd[511:448],cmd[447:384],cmd[383:320],cmd[319:256]);
			second_1 <= True;
		end else if(second_1) begin
			let tail = nvmetr_ifc_1.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",second_word,(tail));
			second_1<=False;
			forward.data = second_word_1;
			third_1 <= True;
		end else if(third_1) begin
			let tail = nvmetr_ifc_1.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			third_1<=False;
			forward.data = third_word_1;
			fourth_1 <= True;
		end else if(fourth_1) begin
			let tail = nvmetr_ifc_1.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			fourth_1<=False;
			forward.data = fourth_word_1;
			fifth_1 <= True;
                	end else if(fifth_1) begin
			let tail = nvmetr_ifc_1.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			fifth_1<=False;
			forward.data = fifth_word_1;
			sixth_1 <= True;
                	end else if(sixth_1) begin
			let tail = nvmetr_ifc_1.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			sixth_1<=False;
			forward.data = sixth_word_1;
			seventh_1 <= True;
                	end else if(seventh_1) begin
			let tail = nvmetr_ifc_1.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			seventh_1 <=False;
			forward.data = seventh_word_1;
                	end else begin
			let tail = nvmetr_ifc_1.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",top,(tail));
			first_1<=True;
			forward.data = top_1;
		end
		forward.burst = 8;// it was 2 for 128bits
		forward.first = first_1;
		fawrite_sub1.enq(forward);
	endrule

	// This rule writes the new tail into the doorbell register
	rule go2DB1 (submission_1_flag && go2DB1_reg);
		ACPBusRequest forward = defaultValue;
		forward.b=b_reg;
		forward.c=c_reg;
		forward.ra=ra_reg;
		forward.wa=wa_reg;
		forward.user=1;
		forward.usermode=usermode_reg;
		forward.secure=secure_reg;
		$display("Q1 - Request: %d %d %d %d - Prot: %d %d",forward.b,forward.c,forward.ra,forward.wa,forward.secure,forward.usermode );
		forward.write = True;

		forward.address = nvmetr_ifc_1.getSqDBAddr();
		forward.byteen= 8'h0f;

		let tail = nvmetr_ifc_1.getSqTail();
		forward.data = zeroExtend(tail);
		$display("Q1 - Cur Tail: %d\n",tail);
		$display("Q1 - DB_address: 0x%x | Data: 0x%x",forward.address,forward.data);

		forward.burst = 1;
		forward.first = first2;
		fawrite_db1.enq(forward);
	endrule

	rule synthCmds1(synth_cmd_1_reg && !submission_1_flag);
		let tail = nvmetr_ifc_1.getSqTail();
		let pass = False;
		if(tail==1023)
			pass = (0==head_1_reg)?False:True;	
		else
			pass = (tail+1==head_1_reg)?False:True;		
		
		if(pass) begin
			let cmd = {appmask,apptag,reftag,dsmgmt,control,length,slba_1,prp2,prp1_1,metadata,rsvd2,nsid,command_id_1,flags,op};

			nvmetr_ifc_1.setCmd(cmd);
			submission_1_flag <= True;
			command_id_1 	<= command_id_1 + 1;
			synth_cmd_1_reg <= False;
		end
	endrule

	//----------------------------------------------------- Queue 2
	// AXI_SUBMIT port
	rule fwSub2; //forward write requests
		let r = fawrite_sub2.first;
		wr_master_sub2.tlm.rx.put(r);
		fawrite_sub2.deq();
	endrule

	rule frSub2; //forward read requests
		let r = faread_sub2.first;
		rd_master_sub2.tlm.rx.put(r);
		faread_sub2.deq();
	endrule

	rule mreadRespSub2; //when the output side read receives a read response
		let resp <- rd_master_sub2.tlm.tx.get ();
	endrule

	rule mwriteRespSub2;//just swallow the responses from the write channel and go to doorbell update
		let resp <- wr_master_sub2.tlm.tx.get ();
		go2DB2_wire.wset(True);
	endrule

	// AXI_DB port
	rule fwDb2; //forward write requests
		let r = fawrite_db2.first;
		wr_master_db2.tlm.rx.put(r);
		fawrite_db2.deq();
	endrule

	rule frDb2; //forward read requests
		let r = faread_db2.first;
		rd_master_db2.tlm.rx.put(r);
		faread_db2.deq();
	endrule

	rule mreadRespDb2; //when the output side read receives a read response
		let resp <- rd_master_db2.tlm.tx.get ();
	endrule

	rule mwriteRespDb2;//just swallow the responses from the write channel
		let resp <- wr_master_db2.tlm.tx.get ();
		//submission_flag <= False;
		release_sub2_flag_wire.wset(True);
	endrule
	//
	rule releaseSub2Flag(submission_2_flag && release_sub2_flag_reg);
		submission_2_flag <= False;
	endrule

	// This rule submits NVMe commands as 8 64-bit burst words
	rule forwardCmd2 (submission_2_flag && !go2DB2_reg);
		ACPBusRequest forward = defaultValue;
		forward.b=b_reg;
		forward.c=c_reg;
		forward.ra=ra_reg;
		forward.wa=wa_reg;
		forward.user=1;
		forward.usermode=usermode_reg;
		forward.secure=secure_reg;
		$display("Request: %d %d %d %d - Prot: %d %d",forward.b,forward.c,forward.ra,forward.wa,forward.secure,forward.usermode );
		forward.write = True;

		if(first_2) begin
			let tail = nvmetr_ifc_2.getSqAddrOffset();
			let addr = nvmetr_ifc_2.getSqAddr() + ((tail)<<6);
			
			forward.address = addr;
			forward.byteen= 8'hff;

			let cmd <- nvmetr_ifc_2.submitCmd();
			$display($time,"submit cmd is called!");
			first_2<=False;
			forward.data = cmd[63:0];
			second_word_2 <= cmd[127:64];
			third_word_2 <= cmd[191:128];
			fourth_word_2 <= cmd[255:192];
			fifth_word_2 <= cmd[319:256];
			sixth_word_2 <= cmd[383:320];
			seventh_word_2 <= cmd[447:384];
			top_2 <= cmd[511:448];
			$display("Q2 - Req_address: 0x%x | Address: 0x%x - sq_addr: 0x%x - cmd[255-192]: 0x%x | cmd[191-128]: 0x%x | cmd[127-64]: 0x%x | cmd[63-0]: 0x%x - tail:%d",addr,nvmetr_ifc_2.getSqAddr() + ((tail)<<6),nvmetr_ifc_2.getSqAddr(),cmd[255:192],cmd[191:128],cmd[127:64],cmd[63:0],(tail));
			$display("Q0 - cmd[511:448]: 0x%x | cmd[447:384]: 0x%x | cmd[383:320]: 0x%x | cmd[319:256]: 0x%x ",cmd[511:448],cmd[447:384],cmd[383:320],cmd[319:256]);
			second_2 <= True;
		end else if(second_2) begin
			let tail = nvmetr_ifc_2.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",second_word,(tail));
			second_2<=False;
			forward.data = second_word_2;
			third_2 <= True;
		end else if(third_2) begin
			let tail = nvmetr_ifc_2.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			third_2<=False;
			forward.data = third_word_2;
			fourth_2 <= True;
		end else if(fourth_2) begin
			let tail = nvmetr_ifc_2.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			fourth_2<=False;
			forward.data = fourth_word_2;
			fifth_2 <= True;
                	end else if(fifth_2) begin
			let tail = nvmetr_ifc_2.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			fifth_2<=False;
			forward.data = fifth_word_2;
			sixth_2 <= True;
                	end else if(sixth_2) begin
			let tail = nvmetr_ifc_2.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			sixth_2<=False;
			forward.data = sixth_word_2;
			seventh_2 <= True;
                	end else if(seventh_2) begin
			let tail = nvmetr_ifc_2.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",third_word,(tail));
			seventh_2 <=False;
			forward.data = seventh_word_2;
                	end else begin
			let tail = nvmetr_ifc_2.getSqAddrOffset();
			//$display("Submit data: 0x%x tail: %d",top,(tail));
			first_2<=True;
			forward.data = top_2;
		end
		forward.burst = 8;// it was 2 for 128bits
		forward.first = first_2;
		fawrite_sub2.enq(forward);
	endrule

	// This rule writes the new tail into the doorbell register
	rule go2DB2 (submission_2_flag && go2DB2_reg);
		ACPBusRequest forward = defaultValue;
		forward.b=b_reg;
		forward.c=c_reg;
		forward.ra=ra_reg;
		forward.wa=wa_reg;
		forward.user=1;
		forward.usermode=usermode_reg;
		forward.secure=secure_reg;
		$display("Q2 - Request: %d %d %d %d - Prot: %d %d",forward.b,forward.c,forward.ra,forward.wa,forward.secure,forward.usermode );
		forward.write = True;

		forward.address = nvmetr_ifc_2.getSqDBAddr();
		forward.byteen= 8'h0f;

		let tail = nvmetr_ifc_2.getSqTail();
		forward.data = zeroExtend(tail);
		$display("Q2 - Cur Tail: %d\n",tail);
		$display("Q2 - DB_address: 0x%x | Data: 0x%x",forward.address,forward.data);

		forward.burst = 1;
		forward.first = first2;
		fawrite_db2.enq(forward);
	endrule

	rule synthCmds2(synth_cmd_2_reg && !submission_2_flag);
		let tail = nvmetr_ifc_2.getSqTail();
		let pass = False;
		if(tail==1023)
			pass = (0==head_2_reg)?False:True;	
		else
			pass = (tail+1==head_2_reg)?False:True;		
		
		if(pass) begin
			let cmd = {appmask,apptag,reftag,dsmgmt,control,length,slba_2,prp2,prp1_2,metadata,rsvd2,nsid,command_id_2,flags,op};

			nvmetr_ifc_2.setCmd(cmd);
			submission_2_flag <= True;
			command_id_2 	<= command_id_2 + 1;
			synth_cmd_2_reg <= False;
		end
	endrule

	//----------------------------------------------------- Queue 3
	// AXI_SUBMIT port
	rule fwSub3; //forward write requests
		let r = fawrite_sub3.first;
		wr_master_sub3.tlm.rx.put(r);
		fawrite_sub3.deq();
	endrule

	rule frSub3; //forward read requests
		let r = faread_sub3.first;
		rd_master_sub3.tlm.rx.put(r);
		faread_sub3.deq();
	endrule

	rule mreadRespSub3; //when the output side read receives a read response
		let resp <- rd_master_sub3.tlm.tx.get ();
	endrule

	rule mwriteRespSub3;//just swallow the responses from the write channel and go to doorbell update
		let resp <- wr_master_sub3.tlm.tx.get ();
		go2DB3_wire.wset(True);
	endrule

	// AXI_DB port
	rule fwDb3; //forward write requests
		let r = fawrite_db3.first;
		wr_master_db3.tlm.rx.put(r);
		fawrite_db3.deq();
	endrule

	rule frDb3; //forward read requests
		let r = faread_db3.first;
		rd_master_db3.tlm.rx.put(r);
		faread_db3.deq();
	endrule

	rule mreadRespDb3; //when the output side read receives a read response
		let resp <- rd_master_db3.tlm.tx.get ();
	endrule

	rule mwriteRespDb3;//just swallow the responses from the write channel
		let resp <- wr_master_db3.tlm.tx.get ();
		//submission_flag <= False;
		release_sub3_flag_wire.wset(True);
	endrule
	//
	rule releaseSub3Flag(submission_3_flag && release_sub3_flag_reg);
		submission_3_flag <= False;
	endrule

	// This rule submits NVMe commands as 8 64-bit burst words
	rule forwardCmd3 (submission_3_flag && !go2DB3_reg);
		ACPBusRequest forward = defaultValue;
		forward.b=b_reg;
		forward.c=c_reg;
		forward.ra=ra_reg;
		forward.wa=wa_reg;
		forward.user=1;
		forward.usermode=usermode_reg;
		forward.secure=secure_reg;
		$display("Request: %d %d %d %d - Prot: %d %d",forward.b,forward.c,forward.ra,forward.wa,forward.secure,forward.usermode );
		forward.write = True;

		if(first_3) begin
			let tail = nvmetr_ifc_3.getSqAddrOffset();
			let addr = nvmetr_ifc_3.getSqAddr() + ((tail)<<6);
			
			forward.address = addr;
			forward.byteen= 8'hff;

			let cmd <- nvmetr_ifc_3.submitCmd();
			$display($time,"submit cmd is called!");
			first_3<=False;
			forward.data = cmd[63:0];
			second_word_3 <= cmd[127:64];
			third_word_3 <= cmd[191:128];
			fourth_word_3 <= cmd[255:192];
			fifth_word_3 <= cmd[319:256];
			sixth_word_3 <= cmd[383:320];
			seventh_word_3 <= cmd[447:384];
			top_3 <= cmd[511:448];
			$display("Q3 - Req_address: 0x%x | Address: 0x%x - sq_addr: 0x%x - cmd[255-192]: 0x%x | cmd[191-128]: 0x%x | cmd[127-64]: 0x%x | cmd[63-0]: 0x%x - tail:%d",addr,nvmetr_ifc_3.getSqAddr() + ((tail)<<6),nvmetr_ifc_3.getSqAddr(),cmd[255:192],cmd[191:128],cmd[127:64],cmd[63:0],(tail));
			$display("Q3 - cmd[511:448]: 0x%x | cmd[447:384]: 0x%x | cmd[383:320]: 0x%x | cmd[319:256]: 0x%x ",cmd[511:448],cmd[447:384],cmd[383:320],cmd[319:256]);
			second_3 <= True;
		end else if(second_3) begin
			let tail = nvmetr_ifc_3.getSqAddrOffset();
			second_3<=False;
			forward.data = second_word_3;
			third_3 <= True;
		end else if(third_3) begin
			let tail = nvmetr_ifc_3.getSqAddrOffset();
			third_3<=False;
			forward.data = third_word_3;
			fourth_3 <= True;
		end else if(fourth_3) begin
			let tail = nvmetr_ifc_3.getSqAddrOffset();
			fourth_3<=False;
			forward.data = fourth_word_3;
			fifth_3 <= True;
                	end else if(fifth_3) begin
			let tail = nvmetr_ifc_3.getSqAddrOffset();
			fifth_3<=False;
			forward.data = fifth_word_3;
			sixth_3 <= True;
                	end else if(sixth_3) begin
			let tail = nvmetr_ifc_3.getSqAddrOffset();
			sixth_3<=False;
			forward.data = sixth_word_3;
			seventh_3 <= True;
                	end else if(seventh_3) begin
			let tail = nvmetr_ifc_3.getSqAddrOffset();
			seventh_3 <=False;
			forward.data = seventh_word_3;
                	end else begin
			let tail = nvmetr_ifc_3.getSqAddrOffset();
			first_3<=True;
			forward.data = top_3;
		end
		forward.burst = 8;// it was 2 for 128bits
		forward.first = first_3;
		fawrite_sub3.enq(forward);
	endrule

	// This rule writes the new tail into the doorbell register
	rule go2DB3 (submission_3_flag && go2DB3_reg);
		ACPBusRequest forward = defaultValue;
		forward.b=b_reg;
		forward.c=c_reg;
		forward.ra=ra_reg;
		forward.wa=wa_reg;
		forward.user=1;
		forward.usermode=usermode_reg;
		forward.secure=secure_reg;
		$display("Q3 - Request: %d %d %d %d - Prot: %d %d",forward.b,forward.c,forward.ra,forward.wa,forward.secure,forward.usermode );
		forward.write = True;

		forward.address = nvmetr_ifc_3.getSqDBAddr();
		forward.byteen= 8'h0f;

		let tail = nvmetr_ifc_3.getSqTail();
		forward.data = zeroExtend(tail);
		$display("Q3 - Cur Tail: %d\n",tail);
		$display("Q3 - DB_address: 0x%x | Data: 0x%x",forward.address,forward.data);

		forward.burst = 1;
		forward.first = first2;
		fawrite_db3.enq(forward);
	endrule

	rule synthCmds3(synth_cmd_3_reg && !submission_3_flag);
		let tail = nvmetr_ifc_3.getSqTail();
		let pass = False;
		if(tail==1023)
			pass = (0==head_3_reg)?False:True;	
		else
			pass = (tail+1==head_3_reg)?False:True;		
		
		if(pass) begin
			let cmd = {appmask,apptag,reftag,dsmgmt,control,length,slba_3,prp2,prp1_3,metadata,rsvd2,nsid,command_id_3,flags,op};

			nvmetr_ifc_3.setCmd(cmd);
			submission_3_flag <= True;
			command_id_3 	<= command_id_3 + 1;
			synth_cmd_3_reg <= False;
		end
	endrule

	//--------------------------------------------------------------------------------------------------

	rule getRdReq;
		let req <- rd_slave.tlm.tx.get();
		Axi32BusResponse resp = defaultValue;
		resp.error = False; //Signal that no errors occured

		if (req.address[11:2]==10'h000)
			resp.data = nvmetr_ifc_0.getSqAddr();
		else if (req.address[11:2]==10'h001)
			resp.data = nvmetr_ifc_0.getSqDBAddr();
		else if (req.address[11:2]==10'h002)
			resp.data = dma_addr_reg;
		else if (req.address[11:2]==10'h003)
			resp.data = nvmetr_ifc_1.getSqAddr();
		else if (req.address[11:2]==10'h004)
			resp.data = nvmetr_ifc_1.getSqDBAddr();
		else if (req.address[11:2]==10'h005)
			resp.data = nvmetr_ifc_2.getSqAddr();
		else if (req.address[11:2]==10'h006)
			resp.data = nvmetr_ifc_2.getSqDBAddr();
		else if (req.address[11:2]==10'h007)
			resp.data = nvmetr_ifc_3.getSqAddr();
		else if (req.address[11:2]==10'h008)
			resp.data = nvmetr_ifc_3.getSqDBAddr();
		
		else
			resp.data = -1;

		resp.id = req.id; //The id of the incoming req needs to be passed back
		rd_slave.tlm.rx.put(resp);
	endrule

	//This rule will take data passed from the ARM to the model, as parameters to the function
	rule getWrCmd;
		//First take a request from the write master
  		let req <- wr_slave.tlm.tx.get();
		if (req.address[11:2]==10'h000)
			nvmetr_ifc_0.setSqAddr(req.data);
		else if (req.address[11:2]==10'h001)
			nvmetr_ifc_0.setSqDBAddr(req.data);
		else if (req.address[11:2]==10'h002)begin
			dma_addr_reg <= req.data;
			nvmetr_ifc_0.start();
			nvmetr_ifc_1.start();
			nvmetr_ifc_2.start();
			nvmetr_ifc_3.start();
		end else if (req.address[11:2]==10'h003)
			nvmetr_ifc_1.setSqAddr(req.data);
		else if (req.address[11:2]==10'h004)
			nvmetr_ifc_1.setSqDBAddr(req.data);
		else if (req.address[11:2]==10'h005)
			nvmetr_ifc_2.setSqAddr(req.data);
		else if (req.address[11:2]==10'h006)
			nvmetr_ifc_2.setSqDBAddr(req.data);
		else if (req.address[11:2]==10'h007)
			nvmetr_ifc_3.setSqAddr(req.data);
		else if (req.address[11:2]==10'h008)
			nvmetr_ifc_3.setSqDBAddr(req.data);

		//Acknowledge that we got the data
		Axi32BusResponse resp = defaultValue;
		resp.error = False;		//Signal that no errors occured
		resp.id = req.id; 		//We need to pass back the id of the incoming req
	    	wr_slave.tlm.rx.put(resp);
	endrule

	rule go2DB0Rule;
		let go0 = fromMaybe(False, go2DB0_wire.wget());
		go2DB0_reg <= go0;
	endrule

	rule releaseSub0FlagRule;
		let go1 = fromMaybe(False, release_sub0_flag_wire.wget());
		release_sub0_flag_reg <= go1;
	endrule

	rule go2DB1Rule;
		let go2 = fromMaybe(False, go2DB1_wire.wget());
		go2DB1_reg <= go2;
	endrule

	rule releaseSub1FlagRule;
		let go3 = fromMaybe(False, release_sub1_flag_wire.wget());
		release_sub1_flag_reg <= go3;
	endrule

	rule go2DB2Rule;
		let go4 = fromMaybe(False, go2DB2_wire.wget());
		go2DB2_reg <= go4;
	endrule

	rule releaseSub2FlagRule;
		let go5 = fromMaybe(False, release_sub2_flag_wire.wget());
		release_sub2_flag_reg <= go5;
	endrule

	rule go2DB3Rule;
		let go6 = fromMaybe(False, go2DB3_wire.wget());
		go2DB3_reg <= go6;
	endrule

	rule releaseSub3FlagRule;
		let go7 = fromMaybe(False, release_sub3_flag_wire.wget());
		release_sub3_flag_reg <= go7;
	endrule

	method Action set_req (Bit#(64) req_in);
		req_fifo.enq(req_in);	
	endmethod

	method Action setHead0 (Bit#(32) h0_in);
		head_0_reg <= h0_in;
	endmethod

	method Action setHead1 (Bit#(32) h1_in);
		head_1_reg <= h1_in;
	endmethod

	method Action setHead2 (Bit#(32) h2_in);
		head_2_reg <= h2_in;
	endmethod

	method Action setHead3 (Bit#(32) h3_in);
		head_3_reg <= h3_in;
	endmethod

	interface mread_sub0 = rd_master_sub0.fabric;
	interface mwrite_sub0 = wr_master_sub0.fabric;
	interface mread_db0 = rd_master_db0.fabric;
	interface mwrite_db0 = wr_master_db0.fabric;
	interface mread_sub1 = rd_master_sub1.fabric;
	interface mwrite_sub1 = wr_master_sub1.fabric;
	interface mread_db1 = rd_master_db1.fabric;
	interface mwrite_db1 = wr_master_db1.fabric;
	interface mread_sub2 = rd_master_sub2.fabric;
	interface mwrite_sub2 = wr_master_sub2.fabric;
	interface mread_db2 = rd_master_db2.fabric;
	interface mwrite_db2 = wr_master_db2.fabric;
	interface mread_sub3 = rd_master_sub3.fabric;
	interface mwrite_sub3 = wr_master_sub3.fabric;
	interface mread_db3 = rd_master_db3.fabric;
	interface mwrite_db3 = wr_master_db3.fabric;
	interface sread = rd_slave.fabric;
	interface swrite = wr_slave.fabric;

endmodule :fastpath_submit_mp

module fastpath_submit_mp_bs (Axibs_ifc);
  AXI_ifc axiModule <- fastpath_submit_mp() ;
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

	method Action set_req (Bit#(64) req_in);
		axiModule.set_req(req_in);
	endmethod

	method Action setHead0 (Bit#(32) h0_in);
		axiModule.setHead0(h0_in);
	endmethod

	method Action setHead1 (Bit#(32) h1_in);
		axiModule.setHead1(h1_in);
	endmethod

	method Action setHead2 (Bit#(32) h2_in);
		axiModule.setHead2(h2_in);
	endmethod

	method Action setHead3 (Bit#(32) h3_in);
		axiModule.setHead3(h3_in);
	endmethod

	interface mread_sub0 = axiModule.mread_sub0;
	interface mwrite_sub0 = axiModule.mwrite_sub0;
	interface mread_db0 = axiModule.mread_db0;
	interface mwrite_db0 = axiModule.mwrite_db0;
	interface mread_sub1 = axiModule.mread_sub1;
	interface mwrite_sub1 = axiModule.mwrite_sub1;
	interface mread_db1 = axiModule.mread_db1;
	interface mwrite_db1 = axiModule.mwrite_db1;
	interface mread_sub2 = axiModule.mread_sub2;
	interface mwrite_sub2 = axiModule.mwrite_sub2;
	interface mread_db2 = axiModule.mread_db2;
	interface mwrite_db2 = axiModule.mwrite_db2;
	interface mread_sub3 = axiModule.mread_sub3;
	interface mwrite_sub3 = axiModule.mwrite_sub3;
	interface mread_db3 = axiModule.mread_db3;
	interface mwrite_db3 = axiModule.mwrite_db3;
endmodule

module test();
	Reg#(Bit#(32)) count_send <-mkReg(0);
	Reg#(Bit#(32)) count_read <-mkReg(0);
	Reg#(Bit#(32)) count_write <-mkReg(0);
	Reg#(NvmeCmd) count_a <-mkReg(0);
	Reg#(Bit#(32)) count_b <-mkReg(0);
	Reg#(UInt#(32)) cycle <-mkReg(0);
	// The following are just stored for logging
	Reg#(UInt#(32)) wtr0_count <- mkReg(0);
	Reg#(UInt#(32)) wtr1_count <- mkReg(0);
	Reg#(UInt#(32)) wtr2_count <- mkReg(0);
	Reg#(UInt#(32)) wtr3_count <- mkReg(0);

	Reg#(UInt#(32)) rt0_count <- mkReg(0);
	Reg#(UInt#(32)) rt1_count <- mkReg(0);
	Reg#(UInt#(32)) rt2_count <- mkReg(0);
	Reg#(UInt#(32)) rt3_count <- mkReg(0);

	Reg#(UInt#(32)) send_words0 <- mkReg(0);
	Reg#(UInt#(32)) send_words1 <- mkReg(0);
	Reg#(UInt#(32)) send_words2 <- mkReg(0);
	Reg#(UInt#(32)) send_words3 <- mkReg(0);
	Reg#(Bit#(32)) c_reg <- mkReg(0);

	Axibs_ifc dut <- fastpath_submit_mp_bs ();

	AddressRange#(Zynq_ACP_Addr) t_params = defaultValue;
	t_params.base = 32'h0000_0000;
	t_params.high = 32'hFFFF_FFFF;

	Zynq_ACP_rd_slave_dec_xactor read_slave_sub0 <- mkZynq_ACP_rd_slave_dec_xactor(addAddressRangeMatch(t_params));
	Zynq_ACP_wr_slave_dec_xactor write_slave_sub0 <- mkZynq_ACP_wr_slave_dec_xactor(addAddressRangeMatch(t_params));
	mkConnection(dut.mwrite_sub0.bus, write_slave_sub0.fabric.bus );
	mkConnection(dut.mread_sub0.bus, read_slave_sub0.fabric.bus );

	Zynq_ACP_rd_slave_dec_xactor read_slave_db0 <- mkZynq_ACP_rd_slave_dec_xactor(addAddressRangeMatch(t_params));
	Zynq_ACP_wr_slave_dec_xactor write_slave_db0 <- mkZynq_ACP_wr_slave_dec_xactor(addAddressRangeMatch(t_params));
	mkConnection(dut.mwrite_db0.bus, write_slave_db0.fabric.bus );
	mkConnection(dut.mread_db0.bus, read_slave_db0.fabric.bus );

	Zynq_ACP_rd_slave_dec_xactor read_slave_sub1 <- mkZynq_ACP_rd_slave_dec_xactor(addAddressRangeMatch(t_params));
	Zynq_ACP_wr_slave_dec_xactor write_slave_sub1 <- mkZynq_ACP_wr_slave_dec_xactor(addAddressRangeMatch(t_params));
	mkConnection(dut.mwrite_sub1.bus, write_slave_sub1.fabric.bus );
	mkConnection(dut.mread_sub1.bus, read_slave_sub1.fabric.bus );

	Zynq_ACP_rd_slave_dec_xactor read_slave_db1 <- mkZynq_ACP_rd_slave_dec_xactor(addAddressRangeMatch(t_params));
	Zynq_ACP_wr_slave_dec_xactor write_slave_db1 <- mkZynq_ACP_wr_slave_dec_xactor(addAddressRangeMatch(t_params));
	mkConnection(dut.mwrite_db1.bus, write_slave_db1.fabric.bus );
	mkConnection(dut.mread_db1.bus, read_slave_db1.fabric.bus );

	Zynq_ACP_rd_slave_dec_xactor read_slave_sub2 <- mkZynq_ACP_rd_slave_dec_xactor(addAddressRangeMatch(t_params));
	Zynq_ACP_wr_slave_dec_xactor write_slave_sub2 <- mkZynq_ACP_wr_slave_dec_xactor(addAddressRangeMatch(t_params));
	mkConnection(dut.mwrite_sub2.bus, write_slave_sub2.fabric.bus );
	mkConnection(dut.mread_sub2.bus, read_slave_sub2.fabric.bus );

	Zynq_ACP_rd_slave_dec_xactor read_slave_db2 <- mkZynq_ACP_rd_slave_dec_xactor(addAddressRangeMatch(t_params));
	Zynq_ACP_wr_slave_dec_xactor write_slave_db2 <- mkZynq_ACP_wr_slave_dec_xactor(addAddressRangeMatch(t_params));
	mkConnection(dut.mwrite_db2.bus, write_slave_db2.fabric.bus );
	mkConnection(dut.mread_db2.bus, read_slave_db2.fabric.bus );

	Zynq_ACP_rd_slave_dec_xactor read_slave_sub3 <- mkZynq_ACP_rd_slave_dec_xactor(addAddressRangeMatch(t_params));
	Zynq_ACP_wr_slave_dec_xactor write_slave_sub3 <- mkZynq_ACP_wr_slave_dec_xactor(addAddressRangeMatch(t_params));
	mkConnection(dut.mwrite_sub3.bus, write_slave_sub3.fabric.bus );
	mkConnection(dut.mread_sub3.bus, read_slave_sub3.fabric.bus );

	Zynq_ACP_rd_slave_dec_xactor read_slave_db3 <- mkZynq_ACP_rd_slave_dec_xactor(addAddressRangeMatch(t_params));
	Zynq_ACP_wr_slave_dec_xactor write_slave_db3 <- mkZynq_ACP_wr_slave_dec_xactor(addAddressRangeMatch(t_params));
	mkConnection(dut.mwrite_db3.bus, write_slave_db3.fabric.bus );
	mkConnection(dut.mread_db3.bus, read_slave_db3.fabric.bus );

	Zynq_Axi32_rd_master_xactor read_master <- mkZynq_Axi32_rd_master_xactor;
	Zynq_Axi32_wr_master_xactor write_master <- mkZynq_Axi32_wr_master_xactor;

 	mkConnection(read_master.fabric.bus, dut.sread.bus);
 	mkConnection(write_master.fabric.bus, dut.swrite.bus );

 	rule sendWCmd (count_send<200);
		Axi32BusRequest req = defaultValue;
		req.write = True;
		req.byteen = -1;


		let c = count_send%10;
		c_reg <= count_send%10;

		if (count_send<200) begin

			if (c==0 && count_send==0) begin
				req.address = 32'h53c00000;
				req.data = 32'h3f06_0000;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==1 && count_send==1) begin
				req.address = 32'h53c0000C;
				req.data = 32'h3f08_0000;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==2 && count_send==2) begin
				req.address = 32'h53c00004;
				req.data = 32'h4002_1010;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==3 && count_send==3) begin
				req.address = 32'h53c00008;
				req.data = 32'h4354_0000;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==4 && count_send==4) begin
				req.address = 32'h53c00010;
				req.data = 32'h4002_1020;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==5 && count_send==5) begin
				req.address = 32'h53c00014;
				req.data = 32'h3f0A_0000;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==6 && count_send==6) begin
				req.address = 32'h53c00018;
				req.data = 32'h4002_1030;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==7 && count_send==7) begin
				req.address = 32'h53c0001C;
				req.data = 32'h3f0C_0000;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==8 && count_send==8) begin
				req.address = 32'h53c00020;
				req.data = 32'h4002_1040;
				$display($time,"Write (0x%0x) to addr: (0x%0x) - count_send==%d!!\n",req.data,req.address,count_send);
			end else if (c==9) begin
				let req_in = 64'h0;
				if(count_b==0) begin
					req_in[63] = 1;
					count_b <= count_b + 1;
				end else if(count_b==3) 
					count_b <= 0;
				else
					count_b <= count_b + 1;
				req_in[62:32] = 31'h4000;	//size
				req_in[31:16] = 16'h1;	//fpd
				req_in[15:0] = 16'h1;	//op
				dut.set_req(req_in);
			end else begin
				req.address = 32'h53c01fff;
				req.data = 32'd0;
			end
		end

		write_master.tlm.rx.put(req);
		count_send <= count_send + 1;
 	endrule

	//Queue 0
	rule reply_WriteSub0;
		let req <- write_slave_sub0.tlm.tx.get();
		let baseAddress = 32'h3f06_0000;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		write_slave_sub0.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress + (wtr0_count<<3));

		$display("Q0 - target received write address 0x%x - 0x%x | Data: %0x_%0x %s %s | burst: %d | wtr0_count: %d",req.address ,pack(baseAddress + (wtr0_count<<3)),req.data[63:32],req.data[31:0] , req.first?"First beat":"", pass?"PASS":"FAIL", req.burst,wtr0_count);
		if(!pass)
			$display("MEGA FAIL!");

		if(wtr0_count==8191)
			wtr0_count <= 0;
		else
			wtr0_count <= wtr0_count+1;

		send_words0 <= send_words0 + 1;
	endrule

	rule reply_readSub0;
		let req <- read_slave_sub0.tlm.tx.get();
		let baseAddress = 32'h3f06_0000;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		ret.data = {pack(rt0_count+1) , pack(rt0_count)};
		read_slave_sub0.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress + (rt0_count<<5));
		rt0_count<=rt0_count+1;
	endrule

	rule reply_WriteDb0;
		let req <- write_slave_db0.tlm.tx.get();
		let baseAddress = 32'h4002_1010;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		write_slave_db0.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress);

		$display("Q0 - target received DB write address 0x%x - 40021010 | Data: %d_%d | %s \n",req.address ,req.data[63:32],req.data[31:0],pass?"PASS":"FAIL");
	endrule

	rule reply_readDb0;
		let req <- read_slave_db0.tlm.tx.get();
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		read_slave_db0.tlm.rx.put(ret);
	endrule

	// Queue 1
	rule reply_WriteSub1;
		let req <- write_slave_sub1.tlm.tx.get();
		let baseAddress = 32'h3f08_0000;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		write_slave_sub1.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress + (wtr1_count<<3));

		$display("Q1 - target received write address 0x%x - 0x%x | Data: %0x_%0x %s %s | burst: %d | wtr1_count: %d",req.address ,pack(baseAddress + (wtr1_count<<3)),req.data[63:32],req.data[31:0] , req.first?"First beat":"", pass?"PASS":"FAIL", req.burst,wtr1_count);
		if(!pass)
			$display("MEGA FAIL!");

		if(wtr1_count==8191)
			wtr1_count <= 0;
		else
			wtr1_count <= wtr1_count+1;

		send_words1 <= send_words1 + 1;
	endrule

	rule reply_readSub1;
		let req <- read_slave_sub1.tlm.tx.get();
		let baseAddress = 32'h3f08_0000;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		ret.data = {pack(rt1_count+1) , pack(rt1_count)};
		read_slave_sub1.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress + (rt1_count<<5));
		rt1_count<=rt1_count+1;
	endrule

	rule reply_WriteDb1;
		let req <- write_slave_db1.tlm.tx.get();
		let baseAddress = 32'h4002_1020;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		write_slave_db1.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress);

		$display("Q1 - target received DB write address 0x%x - 40021010 | Data: %d_%d | %s \n",req.address ,req.data[63:32],req.data[31:0],pass?"PASS":"FAIL");
	endrule

	rule reply_readDb1;
		let req <- read_slave_db1.tlm.tx.get();
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		read_slave_db1.tlm.rx.put(ret);
	endrule

	//Queue 2
	rule reply_WriteSub2;
		let req <- write_slave_sub2.tlm.tx.get();
		let baseAddress = 32'h3f0A_0000;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		write_slave_sub2.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress + (wtr2_count<<3));

		$display("Q2 - target received write address 0x%x - 0x%x | Data: %0x_%0x %s %s | burst: %d | wtr0_count: %d",req.address ,pack(baseAddress + (wtr0_count<<3)),req.data[63:32],req.data[31:0] , req.first?"First beat":"", pass?"PASS":"FAIL", req.burst,wtr2_count);
		if(!pass)
			$display("MEGA FAIL!");

		if(wtr2_count==8191)
			wtr2_count <= 0;
		else
			wtr2_count <= wtr2_count+1;

		send_words2 <= send_words2 + 1;
	endrule

	rule reply_readSub2;
		let req <- read_slave_sub2.tlm.tx.get();
		let baseAddress = 32'h3f0A_0000;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		ret.data = {pack(rt2_count+1) , pack(rt2_count)};
		read_slave_sub2.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress + (rt2_count<<5));
		rt2_count<=rt2_count+1;
	endrule

	rule reply_WriteDb2;
		let req <- write_slave_db2.tlm.tx.get();
		let baseAddress = 32'h4002_1030;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		write_slave_db2.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress);

		$display("Q2 - target received DB write address 0x%x - 40021030 | Data: %d_%d | %s \n",req.address ,req.data[63:32],req.data[31:0],pass?"PASS":"FAIL");
	endrule

	rule reply_readDb2;
		let req <- read_slave_db2.tlm.tx.get();
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		read_slave_db2.tlm.rx.put(ret);
	endrule

	//Queue 3
	rule reply_WriteSub3;
		let req <- write_slave_sub3.tlm.tx.get();
		let baseAddress = 32'h3f0C_0000;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		write_slave_sub3.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress + (wtr3_count<<3));

		$display("Q3 - target received write address 0x%x - 0x%x | Data: %0x_%0x %s %s | burst: %d | wtr0_count: %d",req.address ,pack(baseAddress + (wtr3_count<<3)),req.data[63:32],req.data[31:0] , req.first?"First beat":"", pass?"PASS":"FAIL", req.burst,wtr3_count);
		if(!pass)
			$display("MEGA FAIL!");

		if(wtr3_count==8191)
			wtr3_count <= 0;
		else
			wtr3_count <= wtr3_count+1;

		send_words3 <= send_words3 + 1;
	endrule

	rule reply_readSub3;
		let req <- read_slave_sub3.tlm.tx.get();
		let baseAddress = 32'h3f0C_0000;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		ret.data = {pack(rt3_count+1) , pack(rt3_count)};
		read_slave_sub3.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress + (rt3_count<<5));
		rt3_count<=rt3_count+1;
	endrule

	rule reply_WriteDb3;
		let req <- write_slave_db3.tlm.tx.get();
		let baseAddress = 32'h4002_1040;
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		write_slave_db3.tlm.rx.put(ret);
		let pass = req.address == pack(baseAddress);

		$display("Q3 - target received DB write address 0x%x - 40021040 | Data: %d_%d | %s \n",req.address ,req.data[63:32],req.data[31:0],pass?"PASS":"FAIL");
	endrule

	rule reply_readDb3;
		let req <- read_slave_db3.tlm.tx.get();
		ACPBusResponse ret = defaultValue;
		ret.error = False;
		read_slave_db3.tlm.rx.put(ret);
	endrule

 	// We send a read request and will get a response when avaliable, the master will
 	// stall if we send too many
 	rule sendRCmd (count_read<200);
		Axi32BusRequest req = defaultValue;
		req.write = False;
	        	req.byteen = -1;
		read_master.tlm.rx.put(req);

		count_read <= count_read + 1;
	endrule

 	// We need to read data back from the Slave AXI port of our module,
	// this will only fire if there is data to read
 	rule rr;
 		let resp <- read_master.tlm.tx.get();
 		//$display($time,"SQ_DB_ADDRESS returned data: (0x%0x)from address 32'h53c00008!!\n",resp.data);
 	endrule

 	// We also ALWAYS need to check write responses
 	rule wr;
 		let resp <- write_master.tlm.tx.get();
 	endrule

 	// This is to stop when finished
	rule go;
		if(cycle==200000)begin
			$finish;
		end
		cycle<=cycle+1;
	endrule
endmodule

endpackage:FASTPATH_SUBMIT_MP
