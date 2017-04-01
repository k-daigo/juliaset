`default_nettype none

`include "def.v"

// ジュリア集合の計算
module JuliaCalc(
	input clk,
	input enable,
	input signed [31:0] in_x,
	input signed [31:0] in_y,
	input signed [31:0] cr,
	input signed [31:0] ci,
	output out_end,
	output signed [31:0] out_wx,
	output signed [31:0] out_wy,
	output signed [31:0] out_res);

	wire signed [31:0] wx, wy;
	wire end_flg;

	always @(posedge clk) begin
		if(enable == 1'b0) begin
			end_flg <= 1'b0;
			
		end else if(enable == 1'b1) begin
			wx <= (((in_x**2) - (in_y**2)) / `JL_MUL) + cr;		// x^2 - y^2 + cr
			wy <= (((32'sd2 * in_x) * in_y) / `JL_MUL) + ci;	// 2 * x * y + ci
			
			end_flg <= 1'b1;
		end
	end

	assign out_res = ((wx * wx) + (wy * wy));
	assign out_wx = wx;
	assign out_wy = wy;
	assign out_end = end_flg;
endmodule
