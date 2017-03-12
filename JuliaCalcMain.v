`default_nettype none
`include "def.v"

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
	wire unsigned [15:0] ite4color;

	reg calc_enable = 1'b0;
	wire signed [31:0] work_x, work_y;
	wire signed [31:0] res_x, res_y, res_calc;
	wire jcalc_end;
	
	wire calc_end;
	wire [15:0] color;

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
			calc_end <= 0;
			work_x <= in_x;
			work_y <= in_y;
			
		end else begin
			if(state == `CALC_JULIA && calc_enable == 1'b0) begin
				calc_enable <= 1'b1;

			end else if(state == `CALC_JULIA && calc_enable == 1'b1
					&& ite > `JULIA_ITE_MAX) begin
				calc_enable <= 1'b0;
				state <= `CALC_JULIA_END;
				
				ite <= 16'b00000_000000_11111; // RGB
				
			end else if(state == `CALC_JULIA && calc_enable == 1'b1
					&& jcalc_end == 1'b1) begin
				state <= `CALC_JULIA_JUDGE;
				
			end else if(state == `CALC_JULIA_JUDGE && calc_enable == 1'b1) begin
				if (res_calc > `E_LIMIT) begin
					state <= `CALC_JULIA_END;
					
				end else begin		// Julia Loop
					work_x <= res_x;
					work_y <= res_y;
					calc_enable <= 1'b0;

					ite <= ite + 16'd1;
					state <= `CALC_JULIA;
				end
				
			end else if(state == `CALC_JULIA_END) begin
				state <= `CALC_JULIA_NOP;
				calc_enable <= 1'b0;
				
				if(ite > 16'hFFFF) begin
					ite4color <= 16'hFFFF;
				end else begin
					ite4color <= ite;
				end
				
				// color
				color <= (((ite4color << 12) % 16'hFFFF)
							| ((ite4color << 8) % 16'hFFFF)
							| (ite4color % 16'hFFFF));
				
				// Blue
//				color = ((16'h0000)
//							| (16'h0000)
//							| ((ite4color) % 16'hFFFF));

				// Devil
//				color = ((16'h0000)
//							| ((ite4color << 10) % 16'hFFFF)
//							| ((ite4color) % 16'hFFFF));

				calc_end <= 1;
				ite <= 0;
			end
		end
	end
	
	assign out_calc_end = calc_end;
	assign out_color = color;
	
endmodule

