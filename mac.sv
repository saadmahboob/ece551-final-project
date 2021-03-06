/*
 * Author(s)	: Shubham Singh, Naman Singhal, Jon Sharp, Akshat Khanna
 * Module name	: mac.sv
 *
 * Description	: mac module accumulates the sum of products of two 8-bit
 * numbers. The clr_n input sets the accumulated sum to zero.
 *
 */
module mac(clk, rst_n, a, b, clr_n, acc, addr_LUT);

	input signed[7:0] a, b;
	input clr_n, clk, rst_n;
	output reg signed[25:0] acc;
	output logic [10:0] addr_LUT;

	logic [15:0] mult;
	logic [25:0] mult_ext;
	logic [25:0] acc_next;
	logic [25:0] add;

	assign mult =  a * b;
	assign mult_ext = {{10{mult[15]}}, mult[15:0]};
	assign add = mult_ext + acc;		//sign extends inputs before addition to check for underflow/overflow
	assign acc_next = clr_n ? add : 26'h0;

	assign addr_LUT = (acc[25]==0 && |acc[24:17] == 1) ? 11'h3ff :
					  (acc[25]==1 && &acc[24:17] == 0) ? 11'h400 : acc[17:7];

	always @(posedge clk, negedge rst_n)
		if (!rst_n)
			acc <= 26'h0;
		else
			acc <= acc_next;

endmodule
