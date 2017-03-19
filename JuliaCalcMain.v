`default_nettype none

`include "def.v"

// ジュリア集合の色決定メイン
module JuliaCalcMain(
	input clk,
	input enable,
	input signed [31:0] in_x,
	input signed [31:0] in_y,
	input signed [31:0] cr,
	input signed [31:0] ci,
	output out_calc_end,
	output unsigned [15:0] out_color);
	
	reg [7:0] state = `CALC_JULIA_NOP;
	reg unsigned [15:0] ite = 16'd0;

	reg calc_enable = 1'b0;
	wire signed [31:0] work_x, work_y;
	wire signed [31:0] res_x, res_y, res_calc;
	wire jcalc_end;
	
	// calc julia
	JuliaCalc jualCalc1(.clk(clk), .enable(calc_enable),
			.in_x(work_x), .in_y(work_y), .cr(cr), .ci(ci),
			.out_end(jcalc_end), .out_wx(res_x), .out_wy(res_y),
			.out_res(res_calc));
			
	always @(posedge clk) begin
		if(enable == 1'b0) begin
			state <= `CALC_JULIA;
			calc_enable <= 1'b0;
			ite <= 0;
			work_x <= in_x;
			work_y <= in_y;
			
		end else begin
		
			// 計算開始（再計算もここから開始）
			if(state == `CALC_JULIA && calc_enable == 1'b0) begin
				calc_enable <= 1'b1;
			end
			
			// 計算回数が上限を超えた場合は収束しないと判断し、iteに固定値を代入
			else if(state == `CALC_JULIA && calc_enable == 1'b1
					&& ite > `JULIA_ITE_MAX) begin
				calc_enable <= 1'b0;
				state <= `CALC_JULIA_END;
				
				ite <= 16'b00000_000000_11111; // RGB
				
			end

			// JuliaCalcから計算完了がきたら収束判定
			else if(state == `CALC_JULIA && calc_enable == 1'b1
					&& jcalc_end == 1'b1) begin
					
				// 上限を超えたら収束扱い
				if (res_calc > `E_LIMIT) begin
					state <= `CALC_JULIA_END;
				end
				
				// 上限を超えてなければ再計算
				else begin
					state <= `CALC_JULIA;
					
					work_x <= res_x;
					work_y <= res_y;
					calc_enable <= 1'b0;
					ite <= ite + 16'd1;
				end
			end
		end
	end

	assign out_calc_end = (state == `CALC_JULIA_END ? 1'b1 : 1'b0);
	// Basic
	assign out_color = ((ite << 12) % 16'hFFFF) | ((ite << 8) % 16'hFFFF) | (ite % 16'hFFFF);
	// Blue
//	assign out_color = 16'h0000 | 16'h0000 | (ite % 16'hFFFF);
	// Devil
//	assign out_color = ((16'h0000) | ((ite << 10) % 16'hFFFF) | ((ite) % 16'hFFFF));
	
endmodule

