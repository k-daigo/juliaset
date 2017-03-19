//
`define TIME_1S 50_000_000
`define TIME_500MS 50_000_000 / 1000 * 100 * 5
`define TIME_100MS 50_000_000 / 1000 * 100
`define TIME_10MS 50_000_000 / 1000 * 10
`define TIME_30MS 50_000_000 / 1000 * 30
//`define TIME_30MS 1
`define TIME_15MS 50_000_000 / 1000 * 15
`define TIME_5MS 50_000_000 / 1000 * 5
//`define TIME_5MS 1
`define TIME_1MS 50_000_000 / 1000 * 1
`define TIME_1US 50_000_000 / 1000 / 1000 * 1
//`define TIME_1US 1
`define TIME_50NS 5 // 50_000_000 / 1000 / 1000 / 1000 * 10
`define TIME_10NS 1

// LCDのXY
`define LCD_W 32'd320
`define LCD_H 32'd240

// ジュリア集合計算の並列数
`define CONCURRENT_COUNT 8'd8

`define JL_MUL		32'sd8192			// 2**13（2のべき乗とすることで除算ロジックをビットシフト化）
`define E_LIMIT	32'sd200000000
`define JULIA_ITE_MAX 16'd200
`define JULIA_STEP_SPEED 32768		// 2**15

// 位置的なもの
`define START_X	-32'd12288		// -1.50 * JL_MUL
`define END_X		32'd12288		// 1.50 * JL_MUL
`define START_Y	-32'd9216		// -1.125 * JL_MUL
`define END_Y		32'd9216			// 1.125; * JL_MUL
	
//
`define WAIT	8'd0 
`define RESET1	8'd1 
`define RESET2	8'd2 
`define RESET3	8'd3 
`define RESET4	8'd4
`define RESET5	8'd5

`define CMD		1'b0
`define DATA	1'b1

`define CMD_PREPARE	8'd6
`define CMD_SET		8'd7
`define CMD_WRITE		8'd8
`define DATA_PREPARE 8'd9
`define DATA_H_SET	8'd10
`define DATA_H_WRITE	8'd11
`define DATA_L_SET	8'd12
`define DATA_L_WRITE	8'd13

`define POINT_SET_CURSOR_X_CMD			8'd21
`define POINT_SET_CURSOR_X_CMD_WRITE	8'd22
`define POINT_SET_CURSOR_X_DATA			8'd23
`define POINT_SET_CURSOR_X_DATA_WRITE	8'd24
`define POINT_SET_CURSOR_X_DATA2			8'd25
`define POINT_SET_CURSOR_X_DATA_WRITE2	8'd26
`define POINT_SET_CURSOR_Y_CMD			8'd27
`define POINT_SET_CURSOR_Y_CMD_WRITE	8'd28
`define POINT_SET_CURSOR_Y_DATA			8'd29
`define POINT_SET_CURSOR_Y_DATA_WRITE	8'd30
`define POINT_SET_CURSOR_Y_DATA2			8'd31
`define POINT_SET_CURSOR_Y_DATA_WRITE2	8'd32
`define POINT_PREPARE_CMD					8'd33
`define POINT_CMD								8'd34
`define POINT_CMD_WRITE						8'd35
`define POINT_DATA_PREPARE					8'd36
`define POINT_DATA_H							8'd37
`define POINT_DATA_H2						8'd38
`define POINT_DATA_H_WRITE					8'd39
`define POINT_DATA_L							8'd40
`define POINT_DATA_L2						8'd41
`define POINT_DATA_L3						8'd42
`define POINT_DATA_L_WRITE					8'd43
`define NEXT_POS_PREPER						8'd44

`define CALC_JULIA_NOP						8'd0
`define CALC_JULIA							8'd50
`define CALC_JULIA_JUDGE					8'd51
`define CALC_JULIA_END						8'd52
`define CALC_JULIA_TARGET_SELECT			8'd53
