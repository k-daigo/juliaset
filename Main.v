//`timescale 1ns/1ms

`include "def.h"

module Main(
	input clk,
	input [2:0] btn,
	input [9:0] sw,
	output [9:0] led,
	output [7:0] hled0,
	output [7:0] hled1,
	output [7:0] hled2,
	output [7:0] hled3,
	output [15:0] tft_db,
	output tft_rs,
	output tft_wr,
	output tft_rd,
	output tft_cs,
	output tft_reset,
	output [15:0] debug_iteration,
	output [15:0] debug_posx,
	output [15:0] debug_posy,
	output [31:0] debug_julia_calc_out
);
	parameter INIT_CR = -32'd12501; // JissuBu -1.2501
	parameter INIT_CI = -32'd2500; // KyosuuBu -0.2500
	
	reg [9:0] wled;
	reg [7:0] state = `RESET1;
	reg [7:0] next_state;
	reg [31:0] init_seq = 32'd0;
	reg [31:0] wait_time= 32'd0;
	reg resetting = 0;
	reg initilized = 0;
	
	reg [23:0] data;
	reg r_reset, w_rs, w_cs, w_wr;
	reg unsigned [15:0] w_db;
	
	reg signed [15:0] posx;
	reg signed [15:0] posy;
	wire unc_reset;

	reg unsigned [31:0] eLimit = 32'd2 * `JL_MUL;
	reg signed [31:0] dx, dy;

	reg signed [31:0] mod_j_x0_1, mod_j_y0_1;
	
	reg mod_j_enable_1 = 0;
	reg mod_j_enable_2 = 0;
	reg mod_j_enable_3 = 0;
	reg mod_j_enable_4 = 0;
	reg mod_j_enable_5 = 0;
	reg mod_j_enable_6 = 0;
	wire [15:0] color1;
	wire [15:0] color2;
	wire [15:0] color3;
	wire [15:0] color4;
	wire [15:0] color5;
	wire [15:0] color6;
	reg signed [31:0] mod_j_y_work;
	reg signed [31:0] mod_j_x_work1;
	reg signed [31:0] mod_j_x_work2;
	reg signed [31:0] mod_j_x_work3;
	reg signed [31:0] mod_j_x_work4;
	reg signed [31:0] mod_j_x_work5;
	reg signed [31:0] mod_j_x_work6;
	wire julia_calc_end_flg1;
	wire julia_calc_end_flg2;
	wire julia_calc_end_flg3;
	wire julia_calc_end_flg4;
	wire julia_calc_end_flg5;
	wire julia_calc_end_flg6;
	reg unsigned [15:0] color[6];
	reg unsigned [15:0] color_tmp;
	integer targetColorIndex = 0;
	integer targetColorIndexMax = 0;

	reg signed [31:0] xS = -32'd10000; // -1.00
	reg signed [31:0] xE =  32'd10000; // 1.00
	reg signed [31:0] yS = -32'd7500; // -0.75;
	reg signed [31:0] yE =  32'd7500; // 0.75;	
	
	reg signed [31:0] cr;
	reg signed [31:0] ci;
	
	reg unsigned [15:0] iteration = 16'd0;
	
	reg signed [31:0] crCalcMode = -32'd1;
	reg signed [31:0] ciCalcMode = 32'd0;
	
//	integer F_HANDLE;
//	initial F_HANDLE = $fopen("debug.log");	
  
	// unchattering
	Unchatter uc(btn[0], clk, unc_reset);

	always @(posedge clk) begin
	
		// to RESET
		if(unc_reset == 1) begin
			resetting <= 1;
			state <= `RESET1;
			init_seq = 0;
			initilized <= 0;

			// Julia Init
			dx = (xE - xS) / (`LCD_W);
			dy = (yE - yS) / (`LCD_H);
			cr = INIT_CR; // JissuBu
			ci = INIT_CI; // KyosuuBu
			crCalcMode = -32'd1;
			ciCalcMode = 32'd0;
			
		// RESET
		end else if(resetting == 1) begin
			if(state == `RESET1) begin
				r_reset <= 1;

				state <= `WAIT;
				next_state <= `RESET2;
				wait_time <= `TIME_5MS;
				
			end else if(state == `RESET2) begin
				r_reset <= 0;

				state <= `WAIT;
				next_state <= `RESET3;
				wait_time <= `TIME_5MS;
				
			end else if(state == `RESET3) begin
				r_reset <= 1;
				
				state <= `WAIT;
				next_state <= `RESET4;
				wait_time <= `TIME_15MS;
				
			end else if(state == `RESET4) begin
				w_cs <= 0;
				
				state <= `WAIT;
				next_state <= `RESET5;
				wait_time <= `TIME_15MS;

			end else if(state == `RESET5) begin
				resetting <= 0;
				
				state <= `WAIT;
				next_state <= `CMD_PREPARE;
				wait_time <= `TIME_5MS;

			end else if(state == `WAIT) begin
				wait_time = wait_time - 1;
				if(wait_time <= 0) begin
					state <= next_state;
				end
			end
		
		end else begin
		
			// end init
			if(initilized == 0 && init_seq == 41) begin
				init_seq = 42; 
				initilized <= 1;

				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_X_CMD;
			end
			
			// Init
			else if(initilized == 0) begin
				if(state == `CMD_PREPARE) begin
					init_seq = init_seq + 1;
					
					data = InitRom(init_seq);
					w_rs <= `CMD;
					w_cs <= 0;
					w_wr <= 0;
					
					state <= `WAIT;
					next_state <= `CMD_SET;
					wait_time <= `TIME_1US;
					
				end else if(state == `CMD_SET) begin
					data = InitRom(init_seq);
					w_db <= {8'h00, data[23:16]};

					state <= `WAIT;
					next_state <= `CMD_WRITE;
					wait_time <= `TIME_1US;
					
				end else if(state == `CMD_WRITE) begin
					data = InitRom(init_seq);
					w_cs <= 1;
					w_wr <= 1;

					state <= `WAIT;
					next_state <= `DATA_PREPARE;
					wait_time <= `TIME_1US;

				end else if(state == `DATA_PREPARE) begin
					data = InitRom(init_seq);
					w_rs <= `DATA;
					w_cs <= 0;
					w_wr <= 0;
					
					state <= `WAIT;
					next_state <= `DATA_H_SET;
					wait_time <= `TIME_1US;
					
				end else if(state == `DATA_H_SET) begin
					data = InitRom(init_seq);
					w_db <= {8'h00, data[15:8]};

					state <= `WAIT;
					next_state <= `DATA_H_WRITE;
					wait_time <= `TIME_1US;
					
				end else if(state == `DATA_H_WRITE) begin
					data = InitRom(init_seq);
					w_wr <= 1;

					state <= `WAIT;
					next_state <= `DATA_L_SET;
					wait_time <= `TIME_1US;
					
				end else if(state == `DATA_L_SET) begin
					data = InitRom(init_seq);
					w_wr <= 0;
					w_db <= {8'h00, data[7:0]};

					state <= `WAIT;
					next_state <= `DATA_L_WRITE;
					wait_time <= `TIME_1US;
					
				end else if(state == `DATA_L_WRITE) begin
					data = InitRom(init_seq);
					w_cs <= 1;
					w_wr <= 1;

					state <= `WAIT;
					next_state <= `CMD_PREPARE;
					wait_time <= `TIME_5MS;
				
				end else if(state == `WAIT) begin
					wait_time = wait_time -1;
					if(wait_time <= 0) begin
						state <= next_state;
					end
				end
			end
			
			// Draw
			else if(initilized == 1) begin
				DrawPoint();
			end
		end
	end
	
	task DrawPoint;
		if(initilized == 1) begin
			
			if(state == `POINT_SET_CURSOR_X_CMD) begin
				posx = 16'd0;
				posy = 16'd0;
				
				// Julia init
				mod_j_x0_1 = xS;
				mod_j_y0_1 = yS;
				
				// Left Min Top Max
				// R -1.25 i 0.25
				if(crCalcMode == -32'd1 && cr < -32'd12500) begin
					crCalcMode = 32'd0;
					cr = -32'd12500;
					ciCalcMode = -32'd1;
				// Left Min Bottom Min
				// R -1.25 i -0.25
				end else if(ciCalcMode == -32'd1 && ci < -32'd2500) begin
					crCalcMode = 32'd1;
					ciCalcMode = 32'd0;
					ci = -32'd2500;
				// Right Max Bottom Min
				// R -0.73 i -0.25
				end else if(crCalcMode == 32'd1 && cr > -32'd7300) begin
					crCalcMode = 32'd0;
					cr = -32'd7300;
					ciCalcMode = 32'd1;
				// Right Max Top Max
				// R -0.73 i 0.25
				end else if(ciCalcMode == 32'd1 && ci > -32'd1000) begin
					crCalcMode = -32'd1;
					ciCalcMode = 32'd0;
					ci = -32'd1000;
				end

				cr = cr + (32'd30 * crCalcMode);
				ci = ci + (32'd30 * ciCalcMode);

				w_rs <= 0; w_cs <= 0; w_wr <= 0;
				w_db <= {8'h00, 8'h4E};
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_X_CMD_WRITE;

			end else if(state == `POINT_SET_CURSOR_X_CMD_WRITE) begin
				w_cs <= 1; w_wr <= 1;
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_X_DATA;

			end else if(state == `POINT_SET_CURSOR_X_DATA) begin
				w_rs <= `DATA; w_cs <= 0;
				w_db <= 16'h0000;
				w_wr <= 0;
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_X_DATA_WRITE;
				
			end else if(state == `POINT_SET_CURSOR_X_DATA_WRITE) begin
				w_wr <= 1;
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_X_DATA2;

			end else if(state == `POINT_SET_CURSOR_X_DATA2) begin
				w_db <= 16'h0000;
				w_wr <= 0;//
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_X_DATA_WRITE2;
				
			end else if(state == `POINT_SET_CURSOR_X_DATA_WRITE2) begin
				w_cs <= 1; w_wr <= 1;
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_Y_CMD;

			end else if(state == `POINT_SET_CURSOR_Y_CMD) begin
				w_rs <= `CMD; w_cs <= 0;
				w_db <= {8'h00, 8'h4F};
				w_wr <= 0;//
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_Y_CMD_WRITE;
			
			end else if(state == `POINT_SET_CURSOR_Y_CMD_WRITE) begin
				w_cs <= 1; w_wr <= 1;
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_Y_DATA;
				
			end else if(state == `POINT_SET_CURSOR_Y_DATA) begin
				w_rs <= `DATA; w_cs <= 0;
				w_db <= {8'h00, 8'h00};
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_Y_DATA_WRITE;
			
			end else if(state == `POINT_SET_CURSOR_Y_DATA_WRITE) begin
				w_wr <= 1;
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_Y_DATA2;

			end else if(state == `POINT_SET_CURSOR_Y_DATA2) begin
				w_db <= {8'h00, 8'h00};
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_Y_DATA_WRITE2;
			
			end else if(state == `POINT_SET_CURSOR_Y_DATA_WRITE2) begin
				w_cs <= 1; w_wr <= 1;
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_PREPARE_CMD;

			end else if(state == `POINT_PREPARE_CMD) begin
				w_rs <= `CMD;
				w_cs <= 0;
				w_wr <= 0;
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_CMD;
				
			end else if(state == `POINT_CMD) begin
				w_db <= {8'h00, 8'h22};
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `POINT_CMD_WRITE;
				
			end else if(state == `POINT_CMD_WRITE) begin
				w_cs <= 1;
				w_wr <= 1;
				wait_time <= `TIME_10NS;

				state <= `WAIT;
				next_state <= `POINT_DATA_PREPARE;

			end else if(state == `POINT_DATA_PREPARE) begin	// X loop
				w_rs <= `DATA;
				w_cs <= 0;
				wait_time <= `TIME_10NS;
				
				state <= `WAIT;
				next_state <= `CALC_JULIA_TARGET_SELECT;

				iteration <= 16'd1;
				color[0] = 16'd0;
				color[1] = 16'd0;
				color[2] = 16'd0;
				color[3] = 16'd0;
				color[4] = 16'd0;
				color[5] = 16'd0;
				targetColorIndex = 0;
				
				mod_j_y_work = mod_j_y0_1;
				
				// 1
				mod_j_x_work1 = mod_j_x0_1;
				mod_j_enable_1 <= 1'b1;
				mod_j_x0_1 = mod_j_x0_1 + dx;
				posx = posx + 16'd1;
				targetColorIndexMax = 1;
				
				// 2
				if(posx >= `LCD_W) begin
					// NOP
				end else begin
					mod_j_x_work2 = mod_j_x0_1;
					mod_j_enable_2 <= 1'b1;
					mod_j_x0_1 = mod_j_x0_1 + dx;
					posx = posx + 16'd1;
					targetColorIndexMax = 2;
				end
				
				// 3
				if(posx >= `LCD_W) begin
					// NOP
				end else begin
					mod_j_x_work3 = mod_j_x0_1;
					mod_j_enable_3 <= 1'b1;
					mod_j_x0_1 = mod_j_x0_1 + dx;
					posx = posx + 16'd1;
					targetColorIndexMax = 3;
				end
				
				// 4
				if(posx >= `LCD_W) begin
					// NOP
				end else begin
					mod_j_x_work4 = mod_j_x0_1;
					mod_j_enable_4 <= 1'b1;
					mod_j_x0_1 = mod_j_x0_1 + dx;
					posx = posx + 16'd1;
					targetColorIndexMax = 4;
				end
				
				// 5
				if(posx >= `LCD_W) begin
					// NOP
				end else begin
					mod_j_x_work5 = mod_j_x0_1;
					mod_j_enable_5 <= 1'b1;
					mod_j_x0_1 = mod_j_x0_1 + dx;
					posx = posx + 16'd1;
					targetColorIndexMax = 5;
				end
					
			end else if(state == `CALC_JULIA_TARGET_SELECT) begin
				if(julia_calc_end_flg1 == 1'b1 && targetColorIndex == 0) begin
					color[0] <= color1;
					mod_j_enable_1 <= 1'b0;
					targetColorIndex = 1;
					state <= `POINT_DATA_H;
					
				end else if(julia_calc_end_flg2 == 1'b1 && targetColorIndex == 1) begin
					color[1] <= color2;
					mod_j_enable_2 <= 1'b0;
					targetColorIndex = 2;
					
					w_rs <= `DATA;
					w_cs <= 0;
					wait_time <= `TIME_10NS;
					
					state <= `WAIT;
					next_state <= `POINT_DATA_H;
					
				end else if(julia_calc_end_flg3 == 1'b1 && targetColorIndex == 2) begin
					color[2] <= color3;
					mod_j_enable_3 <= 1'b0;
					targetColorIndex = 3;
					
					w_rs <= `DATA;
					w_cs <= 0;
					wait_time <= `TIME_10NS;
					
					state <= `WAIT;
					next_state <= `POINT_DATA_H;

				end else if(julia_calc_end_flg4 == 1'b1 && targetColorIndex == 3) begin
					color[3] <= color4;
					mod_j_enable_4 <= 1'b0;
					targetColorIndex = 4;
					
					w_rs <= `DATA;
					w_cs <= 0;
					wait_time <= `TIME_10NS;
					
					state <= `WAIT;
					next_state <= `POINT_DATA_H;

				end else if(julia_calc_end_flg5 == 1'b1 && targetColorIndex == 4) begin
					color[4] <= color5;
					mod_j_enable_5 <= 1'b0;
					targetColorIndex = 5;
					
					w_rs <= `DATA;
					w_cs <= 0;
					wait_time <= `TIME_10NS;
					
					state <= `WAIT;
					next_state <= `POINT_DATA_H;
				end
			end else if(state == `POINT_DATA_H) begin
				color_tmp = color[targetColorIndex-1];
				w_db <= {8'h00, color_tmp[15:8]};
				
				//$fdisplay(F_HANDLE, "1,%d,%d,%d,%h,%h", posx, posy, iteration, color, w_db);

				wait_time <= `TIME_10NS;
				state <= `WAIT;
				next_state <= `POINT_DATA_H2;

			end else if(state == `POINT_DATA_H2) begin
				w_wr <= 0;

				wait_time <= `TIME_10NS;
				state <= `WAIT;
				next_state <= `POINT_DATA_H_WRITE;
				
			end else if(state == `POINT_DATA_H_WRITE) begin
				w_wr <= 1;
				
				wait_time <= `TIME_10NS;
				state <= `WAIT;
				next_state <= `POINT_DATA_L;
				
			end else if(state == `POINT_DATA_L) begin
				w_db <= {8'h00, color_tmp[7:0]};
				
				//$fdisplay(F_HANDLE, "2,%d,%d,%d,%h,%h", posx, posy, iteration, color, w_db);

				wait_time <= `TIME_10NS;
				state <= `WAIT;
				next_state <= `POINT_DATA_L2;
				
			end else if(state == `POINT_DATA_L2) begin
				w_wr <= 0;

				wait_time <= `TIME_10NS;
				state <= `WAIT;
				next_state <= `POINT_DATA_L3;
				
			end else if(state == `POINT_DATA_L3) begin
				w_wr <= 1;

				wait_time <= `TIME_10NS;
				state <= `WAIT;
				next_state <= `POINT_DATA_L_WRITE;
				
			end else if(state == `POINT_DATA_L_WRITE) begin
				w_cs <= 1;
				
				if(targetColorIndex == targetColorIndexMax) begin
					state <= `NEXT_POS_PREPER;
				end else begin
					state <= `CALC_JULIA_TARGET_SELECT;
				end
				
			end else if(state == `NEXT_POS_PREPER) begin
				mod_j_enable_1 <= 1'b0;
				mod_j_enable_2 <= 1'b0;
				mod_j_enable_3 <= 1'b0;
				mod_j_enable_4 <= 1'b0;
				mod_j_enable_5 <= 1'b0;
				mod_j_enable_6 <= 1'b0;

				if(posx >= `LCD_W) begin
					posx = 16'd0;
					posy = posy + 16'd1;

					// Julia
					mod_j_x0_1 = xS;
					mod_j_y0_1 = mod_j_y0_1 + dy;
				end

				wait_time <= `TIME_10NS;
				state <= `WAIT;
				
				if(posy >= `LCD_H)begin
					posy = 16'd0;
					mod_j_x0_1 = xS;

					next_state = `POINT_SET_CURSOR_X_CMD;	// next 0
					
				end else begin
					next_state = `POINT_DATA_PREPARE;	// next x
				end

			end else if(state == `WAIT) begin
				wait_time <= wait_time -1;
				if(wait_time <= 0) begin
					state <= next_state;
				end
			end
		end
	endtask

	// calc julia
	JuliaCalcMain jualCalcMain1(.clk(clk), .enable(mod_j_enable_1),
			.mod_j_x0_1(mod_j_x_work1), .mod_j_y0_1(mod_j_y_work), .cr(cr), .ci(ci),
			.out_calc_end(julia_calc_end_flg1), .out_color(color1));
	JuliaCalcMain jualCalcMain2(.clk(clk), .enable(mod_j_enable_2),
			.mod_j_x0_1(mod_j_x_work2), .mod_j_y0_1(mod_j_y_work), .cr(cr), .ci(ci),
			.out_calc_end(julia_calc_end_flg2), .out_color(color2));
	JuliaCalcMain jualCalcMain3(.clk(clk), .enable(mod_j_enable_3),
			.mod_j_x0_1(mod_j_x_work3), .mod_j_y0_1(mod_j_y_work), .cr(cr), .ci(ci),
			.out_calc_end(julia_calc_end_flg3), .out_color(color3));
	JuliaCalcMain jualCalcMain4(.clk(clk), .enable(mod_j_enable_4),
			.mod_j_x0_1(mod_j_x_work4), .mod_j_y0_1(mod_j_y_work), .cr(cr), .ci(ci),
			.out_calc_end(julia_calc_end_flg4), .out_color(color4));
	JuliaCalcMain jualCalcMain5(.clk(clk), .enable(mod_j_enable_5),
			.mod_j_x0_1(mod_j_x_work5), .mod_j_y0_1(mod_j_y_work), .cr(cr), .ci(ci),
			.out_calc_end(julia_calc_end_flg5), .out_color(color5));
//	JuliaCalcMain jualCalcMain6(.clk(clk), .enable(mod_j_enable_6),
//			.mod_j_x0_1(mod_j_x_work6), .mod_j_y0_1(mod_j_y_work), .cr(cr), .ci(ci),
//			.out_calc_end(julia_calc_end_flg6), .out_color(color6));

	wire [15:0] out_db;
	wire out_rs;
	wire out_wr;
	wire out_rd;
	wire out_cs;
	
	// write LCD
	WriteLCD(clk, r_reset, 0, w_rs, w_cs, w_wr, w_db,
		out_rs, out_wr, out_rd, out_cs, out_db);

	assign tft_reset = r_reset;
	assign tft_rs = out_rs;
	assign tft_cs = out_cs;
	assign tft_rd = out_rd;
	assign tft_wr = out_wr;
	assign tft_db = {8'h00, out_db[7:0]};

  // debug
	assign debug_iteration = iteration;
	assign debug_posx = posx;
	assign debug_posy = posy;
//	assign debug_julia_calc_out = julia_calc_out;

	// Hex output wire
	wire [7:0] whex0;
	wire [7:0] whex1;
	wire [7:0] whex2;
	wire [7:0] whex3;
/*
	HexSegDec hs0(color[3:0], whex0);
	HexSegDec hs1(color[7:4], whex1);
	HexSegDec hs2(color[11:8], whex2);
	HexSegDec hs3(color[15:12], whex3);

	HexSegDec hs0(ciCalcMode[3:0], whex0);
	HexSegDec hs1(0, whex1);
	HexSegDec hs2(crCalcMode[3:0], whex2);
	HexSegDec hs3(0, whex3);

	HexSegDec hs0(ci[3:0], whex0);
	HexSegDec hs1(ci[7:4], whex1);
	HexSegDec hs2(cr[3:0], whex2);
	HexSegDec hs3(cr[7:4], whex3);
*/	
	HexSegDec hs0(state[3:0], whex0);
	HexSegDec hs1(state[7:4], whex1);
	HexSegDec hs2(targetColorIndex, whex2);
	HexSegDec hs3(julia_calc_end_flg1, whex3);

	assign hled0 = whex0;
	assign hled1 = whex1;
	assign hled2 = whex2;
	assign hled3 = whex3;

	function [23:0] InitRom;
		input [31:0] index;
		begin
			case (index)
			// 
				1: InitRom = {8'h00, 8'h00, 8'h01}; //Start Oscillation OSCEN=1
				2: InitRom = {8'h03, 8'hA8, 8'hA4}; //Power Control (1)
				3: InitRom = {8'h0C, 8'h00, 8'h00}; //Power Control (2)
				4: InitRom = {8'h0D, 8'h08, 8'h0C}; //Power Control (3)
				5: InitRom = {8'h0E, 8'h2B, 8'h00}; //Power Control (4)  2C00?
				6: InitRom = {8'h1E, 8'h00, 8'hB7}; //Power Control (5)
				7: InitRom = {8'h01, 8'h2B, 8'h3F}; //Driver Output Control RL=0, REV=1, BGR=1, TB=1
				8: InitRom = {8'h02, 8'h06, 8'h00}; //Restore VSYNC mode from low power state
				9: InitRom = {8'h10, 8'h00, 8'h00}; //Sleep mode cancel
				10: InitRom = {8'h11, 8'h60, 8'h58}; //Entry Mode x=0 -> 320, y=0 -> 240
				11: InitRom = {8'h05, 8'h00, 8'h00}; // Compare register
				12: InitRom = {8'h06, 8'h00, 8'h00}; // Compare register
				13: InitRom = {8'h16, 8'hEF, 8'h1C}; // Horizontal and Vertical porch are for DOTCLK mode operation
				14: InitRom = {8'h17, 8'h00, 8'h03}; // Vertical Porch
				15: InitRom = {8'h07, 8'h02, 8'h33}; // Display Control
				16: InitRom = {8'h0B, 8'h00, 8'h00}; // Frame cycle control
				17: InitRom = {8'h0F, 8'h00, 8'h00}; // Gate Scan Position
				18: InitRom = {8'h41, 8'h00, 8'h00}; // Vertical Scroll Control
				19: InitRom = {8'h42, 8'h00, 8'h00}; // Vertical Scroll Control
				20: InitRom = {8'h48, 8'h00, 8'h00}; // Start position. 0
				21: InitRom = {8'h49, 8'h01, 8'h3F}; // End position.   319
				22: InitRom = {8'h4A, 8'h00, 8'h00};  //Horizontal RAM address position start/end setup
				23: InitRom = {8'h4B, 8'h00, 8'h00};  //Vertical RAM address start position setting
				24: InitRom = {8'h44, 8'hEF, 8'h00};  //Vertical RAM address end position setting (0x013F = dec 319)
				25: InitRom = {8'h45, 8'h00, 8'h00}; //Vertical RAM address start position setting
				26: InitRom = {8'h46, 8'h01, 8'h3F}; //Vertical RAM address end position setting (0x013F = dec 319)

				//gamma control
				27: InitRom = {8'h30, 8'h07, 8'h07};
				28: InitRom = {8'h31, 8'h02, 8'h04};
				29: InitRom = {8'h32, 8'h02, 8'h04};
				30: InitRom = {8'h33, 8'h05, 8'h02};
				31: InitRom = {8'h34, 8'h05, 8'h07};
				32: InitRom = {8'h35, 8'h02, 8'h04};
				33: InitRom = {8'h36, 8'h02, 8'h04};
				34: InitRom = {8'h37, 8'h05, 8'h02};
				35: InitRom = {8'h3A, 8'h03, 8'h02};
				36: InitRom = {8'h3B, 8'h03, 8'h02};

				37: InitRom = {8'h23, 8'h00, 8'h00};
				38: InitRom = {8'h24, 8'h00, 8'h00};
				39: InitRom = {8'h25, 8'h80, 8'h00};
				40: InitRom = {8'h4f, 8'h00, 8'h00};
				41: InitRom = {8'h4e, 8'h00, 8'h00};
				default : InitRom = {8'h00, 8'h00, 8'h00};
			endcase
		end
	endfunction 
endmodule
