/*
 * Author(s)	: Shubham Singh, Naman Singhal, Jon Sharp, Akshat Khanna
 * Module name	: uart_tx.sv
 *
 * Description: 8-bit UART transmitter. It takes clock, reset_n, data
 * as inputs and outputs when the data is ready and the data bit by bit.
 *
 */
 module uart_tx(clk, rst_n, tx_start, tx_data, tx, tx_rdy);

  typedef enum reg [1:0] {IDLE, TX} state_t;
  state_t state, nxt_state;

  input clk, rst_n, tx_start;
  input logic [7:0] tx_data;
  output logic tx;
  output logic tx_rdy;

  logic bit_full, baud_full, clr, load, shift;
  logic [11:0] baud;
  logic [3:0] bit_cnt;
  logic [9:0] shift_reg;

  assign bit_full = (bit_cnt == 4'hA) ? 1 : 0;
  assign baud_full = (baud == 12'hA2C) ? 1 : 0;
  assign tx = shift_reg[0];

//state machine
  always_ff @(posedge clk, negedge rst_n)
      if (!rst_n)
          state <= IDLE;
      else
          state <= nxt_state;

  always_comb begin
    shift = 0;
    load = 0;
    clr = 0;
    tx_rdy = 1;
    nxt_state = IDLE;

    case(state)
      IDLE: begin
        if (tx_start) begin
          load = 1;
          nxt_state = TX;
        end
        else
          clr = 1;
      end

      TX: begin
        tx_rdy = 0;
        if (baud_full)
          if (!bit_full) begin
            shift = 1;
            clr = 1;
            nxt_state = TX;
          end
          else
  			    nxt_state = IDLE;
        else
          nxt_state = TX;
      end
    endcase
  end

  //baud counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      baud <= 12'b0;
    else
      baud <= clr ? 12'b0 : baud + 1;

  //bit counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      bit_cnt <= 4'b0;
    else
      if (load)
        bit_cnt <= 4'b0;
      else
        if (shift)
          bit_cnt <= bit_cnt + 1;

  //shift register
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      shift_reg <= 12'b1;
    else
      if (load)
        shift_reg <= {1'b1, tx_data, 1'b0};
      else
        if (shift)
          shift_reg <= {shift_reg[9], shift_reg[9:1]};

endmodule
