module snn_core_tb();

logic clk, rst_n, rx_rdy, tx_start, strt, done, q_input, 
logic []

snn_core iDUT_snn_core(.strt(), .q_input(q_input), .addr_input_unit(), .digit(), .done());
rom iDUT_ram(.data(), .addr(), .we(), .clk(), .q(q_input));

task check_digit(input )


module ram (
    input data,
    input [9:0] addr,
    input we, clk,
    output q);

// Declare the RAM variable
reg ram[2**9:0];

// Variable to hold the registered read address
reg [9:0] addr_reg;

initial
    readmemh("Initialization file", ram);
end

always @ (posedge clk) begin
    if (we) // Write
        ram[addr] <= data;
        addr_reg <= addr;
end

assign q = ram[addr_reg];

endmodule
