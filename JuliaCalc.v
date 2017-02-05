`default_nettype none
//`timescale 1ns/1ms
`include "def.v"

module JuliaCalc(
	input clk,
	input enable,
	input signed [31:0] x0,
	input signed [31:0] y0,
	input signed [31:0] cr,
	input signed [31:0] ci,
	output working,
	output signed [31:0] out_xN,
	output signed [31:0] out_yN,
	output signed [31:0] dout);

	reg signed [31:0] E;
	reg signed [31:0] x2;
	reg signed [31:0] y2, xy;
	reg signed [31:0] a1, a2, a3;
	reg calcStart = 1'b0;
	reg calcEnd = 1'b0;
	reg signed [31:0] w_x0, w_y0, w_cr, w_ci;
	wire signed [31:0] xN, yN, xyn2;
	wire end_flg;

	always @(posedge clk) begin
		if(enable == 1'b0) begin
			calcStart = 1'b0;
			calcEnd = 1'b0;
			end_flg = 1'b0;
		end else if(calcEnd == 1'b0 && calcStart == 1'b0 && enable == 1'b1) begin
			calcStart = 1'b1;
			end_flg = 1'b0;
			w_x0 = x0;
			w_y0 = y0;
			w_cr = cr;
			w_ci = ci;

			x2 = (w_x0 * w_x0);
			y2 = (w_y0 * w_y0);
			xN = ((x2 - y2) / `JL_MUL) + w_cr; // x^2-y^2+Cr

			//	 xy = (x0 * y0) / (JL_MUL);
			//	 yN = ((2 * x0 * y0) / JL_MUL) + ci; // 2 * x * y + Ci
			a1 = 32'd2 * w_x0;
			a2 = a1 * w_y0;
			a3 = a2 / `JL_MUL;
			yN = a3 + w_ci;

//			xyn2 = ((xN * xN) + (yN * yN)) / `JL_MUL;
			xyn2 = ((xN * xN) + (yN * yN));
			calcEnd = 1'b1;
			end_flg = 1'b1;
			calcStart = 1'b0;
			calcEnd = 1'b0;
		end
	end

	assign dout = xyn2;
	assign out_xN = xN;
	assign out_yN = yN;
	assign working = end_flg;
endmodule
