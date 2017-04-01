`default_nettype none

`include "def.v"

// ジュリア集合の計算
module JuliaCalcMain(
	input clk,
	input enable,
	input signed [31:0] in_x,
	input signed [31:0] in_y,
	input signed [31:0] cr,
	input signed [31:0] ci,
	output out_calc_end,
	output [15:0] out_color);
	
	wire [7:0] state;
	wire [15:0] ite;

	// 1クロックで確定しない場合は以下で値を保持
	wire signed [31:0] work_x, work_y;
	
	// ジュリア集合の計算
	wire signed [31:0] result_x = (((work_x**2) - (work_y**2)) / `JL_MUL) + cr;
	wire signed [31:0] result_y = (((32'sd2 * work_x) * work_y) / `JL_MUL) + ci;
	wire signed [31:0] calc_result = (result_x**2) + (result_y**2);

	always @(posedge clk) begin
		if(enable == 1'b0) begin
			state <= `CALC_JULIA;
			ite <= 0;
			work_x <= in_x;
			work_y <= in_y;

		end else begin

			// 上限を超えたら収束扱い
			if (calc_result > `E_LIMIT) begin
				state <= `CALC_JULIA_END;
			end
			
			// 上限を超えてなければ再計算
			else begin
				work_x <= result_x;
				work_y <= result_y;
				ite <= ite + 16'd1;
				
				// 計算回数が上限を超えた場合は収束しないと判断し、iteに固定値を代入
				if(ite > `JULIA_ITE_MAX) begin
//					ite <= 16'b00000_000000_00000; // R_G_B
//					ite <= 16'b11111_111111_11111; // R_G_B
					ite <= 16'b11111_101111_11001; // R_G_B

					state <= `CALC_JULIA_END;
				end
			end
		end
	end

	assign out_calc_end = (state == `CALC_JULIA_END ? 1'b1 : 1'b0);

//	wire [4:0] red   = ((ite / (`JULIA_ITE_MAX / 16'd32)) >> 0) & 5'b11111;
	wire [4:0] red   = 5'b11111;
	wire [5:0] green = ((ite / (`JULIA_ITE_MAX / 16'd64)) >> 0) & 6'b111111;
	wire [4:0] blue  = ((ite / (`JULIA_ITE_MAX / 16'd32)) >> 1) & 5'b11111;

	assign out_color = {red, green, blue};
	
endmodule

