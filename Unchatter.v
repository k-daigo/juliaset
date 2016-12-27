//`timescale 1ns/1ms

module Unchatter(din, clk, dout);
	input din;
	input clk;
	output dout;
	reg [15:0] cnt = 0;
	reg dff = 0;
	
	always @(posedge clk) begin
		cnt = cnt + 16'd1;
	end
	
	always @(posedge cnt[15]) begin
		dff = ~din;
	end
	
	assign dout=dff;
endmodule
