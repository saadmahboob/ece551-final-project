module ram_hidden_unit (
  input [7:0] data1,
  input [7:0] data2,
  input [4:0] addr1,
  input [4:0] addr2,
  input we, clk,
  output [7:0] q1,
  output [7:0] q2);
  // Declare the RAM variable
  reg [7:0] ram[2**5-1:0];
  // Variable to hold the registered read address
  reg [4:0] addr_reg1;
  reg [4:0] addr_reg2;

  initial
  $readmemh("./Files/memory\ initialization\ files/ram_hidden_contents.txt", ram);

  always @ (posedge clk)
  begin
  if (we) begin  // Write
    ram[addr1] <= data1;
    ram[addr2] <= data2;
  end
    addr_reg1 <= addr1;
    addr_reg2 <= addr2;
  end
  assign q1 = ram[addr_reg1];
  assign q2 = ram[addr_reg2];
  endmodule
