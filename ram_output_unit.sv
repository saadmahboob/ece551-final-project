module ram_output_unit (
 input [7:0] data,
 input [3:0] addr,
 input we, clk,
 output [7:0] q);
 // Declare the RAM variable
 reg [7:0] ram[2**3:0];
 // Variable to hold the registered read address
 reg [3:0] addr_reg;

 initial
 $readmemh("Initialization file", ram);

 always @ (posedge clk)
 begin
 if (we) // Write
 ram[addr] <= data;
 addr_reg <= addr;
 end
 assign q = ram[addr_reg];
endmodule
