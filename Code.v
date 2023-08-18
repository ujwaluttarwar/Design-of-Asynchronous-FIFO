timescale 1ns/ 1ps
////
module RAM(RAM_ptr,out);
output [7:0] out;
input [7:0] RAM_ptr;
reg [7:0] input_RAM [127:0];
integer i;
initial begin
for(i=0;i<128;i=i+1)
input_RAM[i] = i*4;
end
assign out = input_RAM[RAM_ptr];
endmodule
module Async_fifo(clk_rd,clk_wr,rst,dout,rd_empty,wr_full);
parameter addr_size =4;
parameter data_size=8;
parameter RAM_size = 1<< addr_size;
input clk_rd,clk_wr;
input rst;
output wr_full,rd_empty;
output [data_size-1 : 0] dout;
wire [data_size-1 :0] data_in;
wire [addr_size:0] rd_ptr_gray, wr_ptr_gray;
wire [addr_size:0] rd_ptr_bin, wr_ptr_bin;
reg [addr_size:0] rd_ptr,rd_s1,rd_s2;
reg [addr_size:0] wr_ptr,wr_s1,wr_s2;
reg [data_size-1:0] memory[RAM_size-1:0];
reg [7:0] RAM_ptr;
reg full,empty;
//------------write logic-----------
always @(posedge rst or posedge clk_wr)
begin
if (rst) begin
wr_ptr <=0;
RAM_ptr <=0;
end
else if (full !== 1'b1) begin //full condition
wr_ptr <= wr_ptr+1;
RAM_ptr<= RAM_ptr+1;
memory[wr_ptr[addr_size-1:0]]<= data_in;
end
end
RAM r(RAM_ptr,data_in); //external ROM memory
//------two stage synchronizer for full---
always @(posedge clk_wr) begin
rd_s1 <= rd_ptr_gray;
rd_s2 <= rd_s1;
end
//------------Read logic-----------
always @(posedge rst or posedge clk_rd)
begin
if (rst) begin
rd_ptr <=0;
end
else if(empty !== 1'b1) begin
rd_ptr <= rd_ptr +1;
end
end
//------two stage synchronizer for empty---
always @ (posedge clk_rd) begin
wr_s1 <= wr_ptr_gray;
wr_s2 <= wr_s1;
end
//---check empty codition after 2 stage sync
always @(*)
begin
if(wr_ptr_bin==rd_ptr)
empty=1;
else
empty=0;
end
//---check full codition after 2 stage sync
always @(*)
begin
if({~wr_ptr[addr_size],wr_ptr[addr_size-1:0]}==rd_ptr_bin)
full = 1;
else
full = 0;
end
assign dout = memory[rd_ptr[addr_size-1 : 0]];
assign wr_full = full;
assign rd_empty=empty;
//----binary to gray pointer------------
assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);
//--------gray to binary pointer----------
assign wr_ptr_bin[4]=wr_s2[4];
assign wr_ptr_bin[3]=wr_s2[3] ^ wr_ptr_bin[4];
assign wr_ptr_bin[2]=wr_s2[2] ^ wr_ptr_bin[3];
assign wr_ptr_bin[1]=wr_s2[1] ^ wr_ptr_bin[2];
assign wr_ptr_bin[0]=wr_s2[0] ^ wr_ptr_bin[1];
assign rd_ptr_bin[4]=rd_s2[4];
assign rd_ptr_bin[3]=rd_s2[3] ^ rd_ptr_bin[4];
assign rd_ptr_bin[2]=rd_s2[2] ^ rd_ptr_bin[3];
assign rd_ptr_bin[1]=rd_s2[1] ^ rd_ptr_bin[2];
assign rd_ptr_bin[0]=rd_s2[0] ^ rd_ptr_bin[1];
endmodule
