module WriteLCD(
	input clk,
	input in_reset,
	input enable,
	input in_rs,
	input in_cs,
	input in_wr,
	input unsigned [15:0] in_db,
	output out_rs,
	output out_wr,
	output out_rd,
	output out_cs,
	output [15:0] out_db
);
	wire w_reset;
	wire w_rs;
	wire w_cs;
	wire w_rd;
	wire w_wr;
	wire [15:0] w_db;

	always @(posedge clk) begin
		w_rs = in_rs;
		w_cs = in_cs;
		w_rd = 1;
		w_wr = in_wr;
		w_db = in_db;
	end

	assign out_reset = in_reset;
	assign out_rs = w_rs;
	assign out_cs = w_cs;
	assign out_rd = 1;
	assign out_wr = w_wr;
	assign out_db = {8'h00, w_db[7:0]};
endmodule
