/* Mac module accumulates the sum of products of two 8-bit
 * numbers. The clr_n input sets the accumulated sum to zero.
 *
 */
module mac(clk, rst_n, a, b, clr_n, acc);

	input signed[7:0] a, b;
	input clr_n, clk, rst_n;
	output reg signed[15:0] acc;
	
	logic [15:0] mult, acc_next;
	logic [16:0] add;

	assign mult =  a * b;
	assign add = {mult[15], mult[15:0]} + {acc[15], acc[15:0]};		//sign extends inputs before addition to check for underflow/overflow
	assign acc_next = clr_n ? add[15:0] : 4'h0000;
	
	
	always @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			acc <= 4'h0000;
		end
		
		acc <= acc_next;
		
	end

endmodule