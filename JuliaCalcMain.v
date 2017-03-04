`default_nettype none
`include "def.v"

module JuliaCalcMain(
	input clk,
	input enable,
	input signed [31:0] mod_j_x0_1,
	input signed [31:0] mod_j_y0_1,
	input signed [31:0] cr,
	input signed [31:0] ci,
	output out_calc_end,
	output unsigned [15:0] out_color);
	
	reg [7:0] state = `CALC_JULIA_NOP;
	reg unsigned [15:0] iteration = 16'd0;

	reg mod_j_enable_1 = 1'b0;
	reg signed [31:0] mod_j_x_work, mod_j_y_work;
	wire signed [31:0] mod_j_xN_out, mod_j_yN_out;
	wire signed [31:0] julia_calc_out;
	wire julia_calc_end_flg;
	
	wire calc_end;
	wire [15:0] color;

	// calc julia
	JuliaCalc jualCalc1(.clk(clk), .enable(mod_j_enable_1),
			.x0(mod_j_x_work), .y0(mod_j_y_work), .cr(cr), .ci(ci),
			.working(julia_calc_end_flg), .out_xN(mod_j_xN_out), .out_yN(mod_j_yN_out),
			.dout(julia_calc_out));
			
	always @(posedge clk) begin
		if(enable == 1'b0) begin
			state <= `CALC_JULIA;
			mod_j_enable_1 <= 1'b0;
			iteration <= 0;
			calc_end <= 0;
			mod_j_x_work <= mod_j_x0_1;
			mod_j_y_work <= mod_j_y0_1;
			
		end else begin
			if(state == `CALC_JULIA && mod_j_enable_1 == 1'b0) begin
				mod_j_enable_1 <= 1'b1;

			end else if(state == `CALC_JULIA && mod_j_enable_1 == 1'b1
					&& iteration > `JULIA_ITE_MAX) begin
				mod_j_enable_1 <= 1'b0;
				state <= `CALC_JULIA_END;
				//iteration <= 0;
				//iteration <= 16'hFFFF;
				iteration <= 16'b00000_000000_11111;
				
			end else if(state == `CALC_JULIA && mod_j_enable_1 == 1'b1
					&& julia_calc_end_flg == 1'b1) begin
				state <= `CALC_JULIA_JUDGE;
				
			end else if(state == `CALC_JULIA_JUDGE && mod_j_enable_1 == 1'b1) begin
				if (julia_calc_out > `E_LIMIT) begin
					state <= `CALC_JULIA_END;
					
				end else begin		// Julia Loop
					mod_j_x_work = mod_j_xN_out;
					mod_j_y_work = mod_j_yN_out;
					mod_j_enable_1 <= 1'b0;

					iteration = iteration + 16'd1;
					state = `CALC_JULIA;
				end
				
			end else if(state == `CALC_JULIA_END) begin
				state = `CALC_JULIA_NOP;
				mod_j_enable_1 = 1'b0;
				
				if(iteration > 16'hFFFF) begin
					iteration = 16'hFFFF;
				end
				
				// color
				color = (((iteration << 12) % 16'hFFFF)
							| ((iteration << 8) % 16'hFFFF)
							| (iteration % 16'hFFFF));
				
				// Blue
//				color = ((16'h0000)
//							| (16'h0000)
//							| ((iteration) % 16'hFFFF));

				// Devil
//				color = ((16'h0000)
//							| ((iteration << 10) % 16'hFFFF)
//							| ((iteration) % 16'hFFFF));

				calc_end = 1;
				iteration = 0;
			end
		end
	end
	
	assign out_calc_end = calc_end;
	assign out_color = color;
	
endmodule

