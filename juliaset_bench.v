//`timescale 1ns/1ms

// Simulation
module lcd_test3_bench();
	reg clk;
	reg [2:0] btn;
	reg [9:0] sw;
	wire [9:0] led;
	wire [7:0] hled0;
	wire [7:0] hled1;
	wire [7:0] hled2;
	wire [7:0] hled3;
	wire [15:0] tft_db;
	wire tft_rs;
	wire tft_wr;
	wire tft_rd;
	wire tft_cs;
	wire tft_reset;
	wire [15:0] debug_iteration;
	wire [15:0] debug_posx;
	wire [15:0] debug_posy;
	wire [31:0] debug_julia_calc_out;

	lcd_test3 lt(clk, btn, sw, led, hled0, hled1, hled2, hled3, tft_db,
          	tft_rs, tft_wr, tft_rd, tft_cs, tft_reset,
          	debug_iteration, debug_posx, debug_posy, debug_julia_calc_out);
				
	always #1 clk =~ clk;
	initial begin
//		$monitor("julia_calc_out_w=%h, tft_rd=%b, tft_reset=%b, tft_cs=%b, tft_rs=%b, tft_wr=%b, tft_db=%h",
//						julia_calc_out_w, tft_rd, tft_reset, tft_cs, tft_rs, tft_wr, tft_db,);
//		$monitor("%d, %d, %d, %h", debug_iteration, debug_posx, debug_posy, debug_julia_calc_out);
		$monitor("debug_posx=%d, debug_posy=%d, tft_rs=%b, tft_cs=%b, tft_wr=%b, tft_db=%h",
    	         debug_posx, debug_posy, tft_rs, tft_cs, tft_wr, tft_db,);

		clk = 0;
		
		#2
		  btn[0] = 1;
		#10
		  btn[0] = 0;
		#65535
		  btn[0] = 1;
		
//		#999999
//    		$finish;
	end
  
endmodule
