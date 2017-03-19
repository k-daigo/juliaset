`default_nettype none

`include "def.v"

// Top Module
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
	output [15:0] debug_posx,
	output [15:0] debug_posy,
	output [31:0] debug_julia_calc_out
);
	parameter INIT_CR = -32'd10241; // JissuBu -1.2501 * 8192(JL_MUL)
	parameter INIT_CI = -32'd2048; // KyosuuBu -0.2500 * 8192(JL_MUL)
	
	reg [7:0] state = `RESET1;
	reg [7:0] next_state;
	reg [31:0] init_seq = 32'd0;
	reg [31:0] wait_time = 32'd0;
	reg lcd_reset_state = 0;
	reg lcd_init = 0;
	
	wire [23:0] lcd_init_data;
	reg lcd_reset, w_rs, w_cs, w_wr;
	reg unsigned [15:0] w_db;
	
	reg signed [15:0] posx;
	reg signed [15:0] posy;
	wire unc_reset;

	reg signed [31:0] dx, dy;
	reg signed [31:0] curr_x, curr_y;

	reg [7:0] ii;
	reg jcalc_enable[`CONCURRENT_COUNT];
	reg signed [31:0] jcalc_x[`CONCURRENT_COUNT];
	wire jcalc_end[`CONCURRENT_COUNT];
	reg unsigned [15:0] jcalc_res_color[`CONCURRENT_COUNT];
	wire [15:0] color[`CONCURRENT_COUNT];
	reg unsigned [15:0] color_tmp;
	integer jcalc_idx = 0;
	integer jcalc_idx_max = 0;

	wire signed [31:0] cr;	// 実数部
	wire signed [31:0] ci;	// 虚数部
	
	// 位置移動制御
	wire signed [31:0] jcalc_mode_cr;
	wire signed [31:0] jcalc_mode_ci;
	wire signed [31:0] jcalc_step_cnt;
	wire signed [31:0] jcalc_step_cnt_prev;
	wire signed [31:0] jcalc_step_cnt_curr;
	
//	integer F_HANDLE;
//	initial F_HANDLE = $fopen("debug.log");	
  
	// unchattering
	Unchatter uc(btn[0], clk, unc_reset);

	always @(posedge clk) begin
		jcalc_step_cnt = jcalc_step_cnt + 1;
	
		// リセット
		if(unc_reset == 1) begin
			lcd_reset_state <= 1;
			state <= `RESET1;
			init_seq = 0;
			lcd_init <= 0;

			// ジュリア集合の計算関係の初期化
			dx <= (`END_X - `START_X) / `LCD_W;
			dy <= (`END_Y - `START_Y) / `LCD_H;
			cr = INIT_CR;
			ci = INIT_CI;
			jcalc_mode_cr <= -32'd1;
			jcalc_mode_ci <= 32'd0;

			// 位置制御のカウンタ初期化
			jcalc_step_cnt <= 0;
			jcalc_step_cnt_prev <= 0;
			jcalc_step_cnt_curr <= 0;

		// LCDリセット
		end else if(lcd_reset_state == 1) begin
			if(state == `RESET1) begin
				lcd_reset <= 1;

				state <= `WAIT;
				next_state <= `RESET2;
				wait_time <= `TIME_5MS;
				
			end else if(state == `RESET2) begin
				lcd_reset <= 0;

				state <= `WAIT;
				next_state <= `RESET3;
				wait_time <= `TIME_5MS;
				
			end else if(state == `RESET3) begin
				lcd_reset <= 1;
				
				state <= `WAIT;
				next_state <= `RESET4;
				wait_time <= `TIME_15MS;
				
			end else if(state == `RESET4) begin
				w_cs <= 0;
				
				state <= `WAIT;
				next_state <= `RESET5;
				wait_time <= `TIME_15MS;

			end else if(state == `RESET5) begin
				lcd_reset_state <= 0;
				
				state <= `WAIT;
				next_state <= `CMD_PREPARE;
				wait_time <= `TIME_5MS;

			end else if(state == `WAIT) begin
				wait_time <= wait_time - 1;
				if(wait_time <= 0) begin
					state <= next_state;
				end
			end
		
		end else begin
		
			// end init
			if(lcd_init == 0 && init_seq == 41) begin
				init_seq <= 42; 
				lcd_init <= 1;

				state <= `WAIT;
				next_state <= `POINT_SET_CURSOR_X_CMD;
			end
			
			// LCD初期化
			else if(lcd_init == 0) begin
				InitLcdTask();
			end
			
			// ジュリア集合描画
			else if(lcd_init == 1) begin
				DrawJuliaTask();
			end
		end
	end
	
	// LCD初期化
	task InitLcdTask;
		if(state == `CMD_PREPARE) begin
			init_seq <= init_seq + 1;
		
			lcd_init_data <= LcdInitRom(init_seq);
			w_rs <= `CMD;
			w_cs <= 0;
			w_wr <= 0;
			
			state <= `WAIT;
			next_state <= `CMD_SET;
			wait_time <= `TIME_1US;
			
		end else if(state == `CMD_SET) begin
			w_db <= {8'h00, lcd_init_data[23:16]};

			state <= `WAIT;
			next_state <= `CMD_WRITE;
			wait_time <= `TIME_1US;
			
		end else if(state == `CMD_WRITE) begin
			w_cs <= 1;
			w_wr <= 1;

			state <= `WAIT;
			next_state <= `DATA_PREPARE;
			wait_time <= `TIME_1US;

		end else if(state == `DATA_PREPARE) begin
			w_rs <= `DATA;
			w_cs <= 0;
			w_wr <= 0;
			
			state <= `WAIT;
			next_state <= `DATA_H_SET;
			wait_time <= `TIME_1US;
			
		end else if(state == `DATA_H_SET) begin
			w_db <= {8'h00, lcd_init_data[15:8]};

			state <= `WAIT;
			next_state <= `DATA_H_WRITE;
			wait_time <= `TIME_1US;
			
		end else if(state == `DATA_H_WRITE) begin
			w_wr <= 1;

			state <= `WAIT;
			next_state <= `DATA_L_SET;
			wait_time <= `TIME_1US;
			
		end else if(state == `DATA_L_SET) begin
			w_wr <= 0;
			w_db <= {8'h00, lcd_init_data[7:0]};

			state <= `WAIT;
			next_state <= `DATA_L_WRITE;
			wait_time <= `TIME_1US;
			
		end else if(state == `DATA_L_WRITE) begin
			w_cs <= 1;
			w_wr <= 1;

			state <= `WAIT;
			next_state <= `CMD_PREPARE;
			wait_time <= `TIME_5MS;
		
		end else if(state == `WAIT) begin
			wait_time <= wait_time -1;
			if(wait_time <= 0) begin
				state <= next_state;
			end
		end
	endtask
	
	// ジュリア集合計算とLCD描画
	task DrawJuliaTask;
		if(state == `POINT_SET_CURSOR_X_CMD) begin
			posx <= 16'd0;
			posy <= 16'd0;
			
			// Julia init
			curr_x <= `START_X;
			curr_y <= `START_Y;

			w_rs <= 0; w_cs <= 0; w_wr <= 0;
			w_db <= {8'h00, 8'h4E};
			wait_time <= `TIME_10NS;
			
			state <= `WAIT;
			next_state <= `POINT_SET_CURSOR_X_CMD_WRITE;
			
			// 位置制御
			// Left Min Top Max
			// R -1.25 i 0.25
			if(jcalc_mode_cr == -32'd1 && cr < -32'd12500) begin
				jcalc_mode_cr = 32'd0;
				cr = -32'd12500;
				jcalc_mode_ci = -32'd1;
			// Left Min Bottom Min
			// R -1.25 i -0.25
			end else if(jcalc_mode_ci == -32'd1 && ci < -32'd2500) begin
				jcalc_mode_cr = 32'd1;
				jcalc_mode_ci = 32'd0;
				ci = -32'd2500;
			// Right Max Bottom Min
			// R -0.73 i -0.25
			end else if(jcalc_mode_cr == 32'd1 && cr > -32'd7300) begin
				jcalc_mode_cr = 32'd0;
				cr = -32'd7300;
				jcalc_mode_ci = 32'd1;
			// Right Max Top Max
			// R -0.73 i 0.1
			end else if(jcalc_mode_ci == 32'd1 && ci > -32'd750) begin
				jcalc_mode_cr = -32'd1;
				jcalc_mode_ci = 32'd0;
				ci = -32'd750;
			end

			jcalc_step_cnt_curr = (jcalc_step_cnt - jcalc_step_cnt_prev) / `JULIA_STEP_SPEED;
			jcalc_step_cnt_prev = jcalc_step_cnt;

			cr = cr + (jcalc_step_cnt_curr * jcalc_mode_cr);
			ci = ci + (jcalc_step_cnt_curr * jcalc_mode_ci);

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

		end
	
		// Xのループはここから
		else if(state == `POINT_DATA_PREPARE) begin
			w_rs <= `DATA;
			w_cs <= 0;
			wait_time <= `TIME_10NS;
			
			state <= `WAIT;
			next_state <= `CALC_JULIA_TARGET_SELECT;
			
			// color初期化
			for (ii = 8'd0; ii < `CONCURRENT_COUNT; ii = ii + 8'd1) begin
				color[ii] <= 16'd0;
			end
			jcalc_idx <= 0;

			// 並列数分JuliaCalcMainにenableを投げる
			for (ii = 8'd0; ii < `CONCURRENT_COUNT; ii = ii + 8'd1) begin
			
				// LCDの横幅を超えたら何もしない
				if(posx >= `LCD_W) begin
					// NOP
				end else begin
					jcalc_x[ii] <= curr_x;
					jcalc_enable[ii] <= 1'b1;
					jcalc_idx_max <= ii + 1;
					
					// 次のX
					curr_x = curr_x + dx;
					posx = posx + 16'd1;		// ここをノンブロッキングにしたいが。
				end
			end
				
		end else if(state == `CALC_JULIA_TARGET_SELECT) begin
		
			// 計算結果を取得
			for (ii = 8'd0; ii < `CONCURRENT_COUNT; ii = ii + 8'd1) begin
				if(jcalc_end[ii] == 1'b1 && jcalc_idx == ii) begin
					color[ii] <= jcalc_res_color[ii];
					jcalc_enable[ii] <= 1'b0;
					jcalc_idx <= ii + 1;
					
					if(ii == 0) begin
						state <= `POINT_DATA_H;
					end else begin
						w_rs <= `DATA;
						w_cs <= 0;
						wait_time <= `TIME_10NS;
						
						state <= `WAIT;
						next_state <= `POINT_DATA_H;
					end
				end
			end
		end else if(state == `POINT_DATA_H) begin
			color_tmp <= color[jcalc_idx - 1];
			w_db <= {8'h00, color_tmp[15:8]};
			
			//$fdisplay(F_HANDLE, "1,%d,%d,%h,%h", posx, posy, color, w_db);

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
			
			//$fdisplay(F_HANDLE, "2,%d,%d,%h,%h", posx, posy, color, w_db);

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
			
			if(jcalc_idx == jcalc_idx_max) begin
				state <= `NEXT_POS_PREPER;
			end else begin
				state <= `CALC_JULIA_TARGET_SELECT;
			end
			
		end else if(state == `NEXT_POS_PREPER) begin
			for (ii = 8'd0; ii < `CONCURRENT_COUNT; ii = ii + 8'd1) begin
				jcalc_enable[ii] <= 1'b0;
			end

			if(posx >= `LCD_W) begin
				posx <= 16'd0;
				posy <= posy + 16'd1;

				// Julia
				curr_x <= `START_X;
				curr_y <= curr_y + dy;
			end

			wait_time <= `TIME_10NS;
			state <= `WAIT;
			
			// 縦幅超えたら右上に戻る
			if(posy >= `LCD_H)begin
				posy <= 16'd0;
				curr_x <= `START_X;

				next_state <= `POINT_SET_CURSOR_X_CMD;	// next 0
				
			end
			
			// こえてなければ次のXの塊
			else begin
				next_state <= `POINT_DATA_PREPARE;	// next x
			end

		end
		
		// WAIT
		else if(state == `WAIT) begin
			wait_time <= wait_time -1;
			if(wait_time <= 0) begin
				state <= next_state;
			end
		end
	endtask

	// calc julia
	JuliaCalcMain jualCalcMain1(.clk(clk), .enable(jcalc_enable[0]),
			.in_x(jcalc_x[0]), .in_y(curr_y), .cr(cr), .ci(ci),
			.out_calc_end(jcalc_end[0]), .out_color(jcalc_res_color[0]));

	JuliaCalcMain jualCalcMain2(.clk(clk), .enable(jcalc_enable[1]),
			.in_x(jcalc_x[1]), .in_y(curr_y), .cr(cr), .ci(ci),
			.out_calc_end(jcalc_end[1]), .out_color(jcalc_res_color[1]));
	JuliaCalcMain jualCalcMain3(.clk(clk), .enable(jcalc_enable[2]),
			.in_x(jcalc_x[2]), .in_y(curr_y), .cr(cr), .ci(ci),
			.out_calc_end(jcalc_end[2]), .out_color(jcalc_res_color[2]));
	JuliaCalcMain jualCalcMain4(.clk(clk), .enable(jcalc_enable[3]),
			.in_x(jcalc_x[3]), .in_y(curr_y), .cr(cr), .ci(ci),
			.out_calc_end(jcalc_end[3]), .out_color(jcalc_res_color[3]));
	JuliaCalcMain jualCalcMain5(.clk(clk), .enable(jcalc_enable[4]),
			.in_x(jcalc_x[4]), .in_y(curr_y), .cr(cr), .ci(ci),
			.out_calc_end(jcalc_end[4]), .out_color(jcalc_res_color[4]));
	JuliaCalcMain jualCalcMain6(.clk(clk), .enable(jcalc_enable[5]),
			.in_x(jcalc_x[5]), .in_y(curr_y), .cr(cr), .ci(ci),
			.out_calc_end(jcalc_end[5]), .out_color(jcalc_res_color[5]));
	JuliaCalcMain jualCalcMain7(.clk(clk), .enable(jcalc_enable[6]),
			.in_x(jcalc_x[6]), .in_y(curr_y), .cr(cr), .ci(ci),
			.out_calc_end(jcalc_end[6]), .out_color(jcalc_res_color[6]));
	JuliaCalcMain jualCalcMain8(.clk(clk), .enable(jcalc_enable[7]),
			.in_x(jcalc_x[7]), .in_y(curr_y), .cr(cr), .ci(ci),
			.out_calc_end(jcalc_end[7]), .out_color(jcalc_res_color[7]));

	// LCD out
	assign tft_reset = lcd_reset;
	assign tft_rs = w_rs;
	assign tft_cs = w_cs;
	assign tft_rd = 1;
	assign tft_wr = w_wr;
	assign tft_db = {8'h00, w_db[7:0]};

	// debug
//	assign debug_posx = posx;
//	assign debug_posy = posy;
//	assign debug_julia_calc_out = julia_calc_out;

	// Hex output wire
/*
	wire [7:0] whex0;
	wire [7:0] whex1;
	wire [7:0] whex2;
	wire [7:0] whex3;
	HexSegDec hs0(color[3:0], whex0);
	HexSegDec hs1(color[7:4], whex1);
	HexSegDec hs2(color[11:8], whex2);
	HexSegDec hs3(color[15:12], whex3);
	assign hled0 = whex0;
	assign hled1 = whex1;
	assign hled2 = whex2;
	assign hled3 = whex3;
*/

	// LCD init ROM
	function [23:0] LcdInitRom;
		input [31:0] index;
		begin
			case (index)
			// 
				1: LcdInitRom = {8'h00, 8'h00, 8'h01}; //Start Oscillation OSCEN=1
				2: LcdInitRom = {8'h03, 8'hA8, 8'hA4}; //Power Control (1)
				3: LcdInitRom = {8'h0C, 8'h00, 8'h00}; //Power Control (2)
				4: LcdInitRom = {8'h0D, 8'h08, 8'h0C}; //Power Control (3)
				5: LcdInitRom = {8'h0E, 8'h2B, 8'h00}; //Power Control (4)  2C00?
				6: LcdInitRom = {8'h1E, 8'h00, 8'hB7}; //Power Control (5)
				7: LcdInitRom = {8'h01, 8'h2B, 8'h3F}; //Driver Output Control RL=0, REV=1, BGR=1, TB=1
				8: LcdInitRom = {8'h02, 8'h06, 8'h00}; //Restore VSYNC mode from low power state
				9: LcdInitRom = {8'h10, 8'h00, 8'h00}; //Sleep mode cancel
				10: LcdInitRom = {8'h11, 8'h60, 8'h58}; //Entry Mode x=0 -> 320, y=0 -> 240
				11: LcdInitRom = {8'h05, 8'h00, 8'h00}; // Compare register
				12: LcdInitRom = {8'h06, 8'h00, 8'h00}; // Compare register
				13: LcdInitRom = {8'h16, 8'hEF, 8'h1C}; // Horizontal and Vertical porch are for DOTCLK mode operation
				14: LcdInitRom = {8'h17, 8'h00, 8'h03}; // Vertical Porch
				15: LcdInitRom = {8'h07, 8'h02, 8'h33}; // Display Control
				16: LcdInitRom = {8'h0B, 8'h00, 8'h00}; // Frame cycle control
				17: LcdInitRom = {8'h0F, 8'h00, 8'h00}; // Gate Scan Position
				18: LcdInitRom = {8'h41, 8'h00, 8'h00}; // Vertical Scroll Control
				19: LcdInitRom = {8'h42, 8'h00, 8'h00}; // Vertical Scroll Control
				20: LcdInitRom = {8'h48, 8'h00, 8'h00}; // Start position. 0
				21: LcdInitRom = {8'h49, 8'h01, 8'h3F}; // End position.   319
				22: LcdInitRom = {8'h4A, 8'h00, 8'h00};  //Horizontal RAM address position start/end setup
				23: LcdInitRom = {8'h4B, 8'h00, 8'h00};  //Vertical RAM address start position setting
				24: LcdInitRom = {8'h44, 8'hEF, 8'h00};  //Vertical RAM address end position setting (0x013F = dec 319)
				25: LcdInitRom = {8'h45, 8'h00, 8'h00}; //Vertical RAM address start position setting
				26: LcdInitRom = {8'h46, 8'h01, 8'h3F}; //Vertical RAM address end position setting (0x013F = dec 319)

				//gamma control
				27: LcdInitRom = {8'h30, 8'h07, 8'h07};
				28: LcdInitRom = {8'h31, 8'h02, 8'h04};
				29: LcdInitRom = {8'h32, 8'h02, 8'h04};
				30: LcdInitRom = {8'h33, 8'h05, 8'h02};
				31: LcdInitRom = {8'h34, 8'h05, 8'h07};
				32: LcdInitRom = {8'h35, 8'h02, 8'h04};
				33: LcdInitRom = {8'h36, 8'h02, 8'h04};
				34: LcdInitRom = {8'h37, 8'h05, 8'h02};
				35: LcdInitRom = {8'h3A, 8'h03, 8'h02};
				36: LcdInitRom = {8'h3B, 8'h03, 8'h02};

				37: LcdInitRom = {8'h23, 8'h00, 8'h00};
				38: LcdInitRom = {8'h24, 8'h00, 8'h00};
				39: LcdInitRom = {8'h25, 8'h80, 8'h00};
				40: LcdInitRom = {8'h4f, 8'h00, 8'h00};
				41: LcdInitRom = {8'h4e, 8'h00, 8'h00};
				default : LcdInitRom = {8'h00, 8'h00, 8'h00};
			endcase
		end
	endfunction 
endmodule
