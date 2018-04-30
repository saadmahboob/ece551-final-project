module snn_core(start, clk, rst_n, q_input, addr_input_unit, digit, done);

  typedef enum reg[2:0] {IDLE, MAC1, MAC2, MAX, DONE} state;
  state curr_state, next_state;

  output logic [9:0] addr_input_unit;
  output logic [3:0] digit;
  output logic done;

  input logic clk, start, rst_n;
  input logic q_input;

  logic clr_n, select_input, increment_input, increment_output, increment_digit, write_hidden, write_out;

  logic [7:0]   q_extended;
  logic [7:0]   ram_hidden_data;
  logic [5:0]   cnt_hidden;
  logic [7:0]   hidden_weight_q;
  logic [4:0]   addr_ram_hidden;
  
  //MAC stuff
  logic [7:0]   a, b, lut_out;
  logic [25:0]  acc;     
  logic [10:0]  addr_LUT;

  //Max stuff
  logic [7:0]   digit_prob, output_weight_q, max_prob, check_max;
  logic [3:0]   output_unit_addr, digit_reg;
  logic [3:0]   cnt_output;

  rom_hidden_weight    hidden_weight(.addr({cnt_hidden[4:0], addr_input_unit[9:0]}), .clk(clk), .q(hidden_weight_q));
  rom_output_weight    output_weight(.addr({cnt_output[3:0], cnt_hidden[4:0]}), .clk(clk), .q(output_weight_q));
  ram_hidden_unit      hidden_unit(.data(lut_out), .addr(addr_ram_hidden), .clk(clk), .we(write_hidden), .q(ram_hidden_data));
  rom_act_func_lut     act_func_lut(.addr(addr_LUT + 11'h400), .clk(clk), .q(lut_out));
  mac                  mac(.clk(clk), .a(a), .b(b), .acc(acc), .clr_n(clr_n), .rst_n(rst_n));
  ram_output_unit      output_unit(.data(lut_out), .addr(output_unit_addr), .clk(clk), .we(write_out), .q(digit_prob));

  assign q_extended = (q_input) ? 8'h7F : 8'h00;

  //MAC 1
  assign addr_input_unit_max = addr_input_unit == 10'h30f ? 1 : 0;
  assign cnt_hidden_max = cnt_hidden == 6'h20 ? 1 : 0;

  //MAC 2
  assign addr_ram_hidden_max = (select_input) ? ((addr_ram_hidden == 31) ? 1 : 0) : 0;
  assign cnt_output_max =  (select_input) ? ((cnt_output == 10) ? 1 : 0) : 0;

  //MAX
  assign digit_max = (output_unit_addr == 9) ? 1 : 0;

  always_ff @(posedge clk) begin
    if(acc[25]==0 && |acc[24:17] == 1)
      addr_LUT = 11'h3ff;
    else if(acc[25]==1 && &acc[24:17] == 0)
      addr_LUT = 11'h400;
    else
      addr_LUT = acc[17:7];
  end

  assign a = select_input ? ram_hidden_data : q_extended;
  assign b = select_input ? output_weight_q : hidden_weight_q;

 always @(posedge clk, negedge rst_n)
  if (!rst_n) begin
    max_prob <= 0;
    digit <= 0;
  end
  else if (check_max)
    if (digit_prob > max_prob) begin
      max_prob <= digit_prob;
      digit <= digit_reg;
    end
  
  // assign max_prob = (check_max) ? ((max_prob > digit_prob) ? max_prob : digit_prob) : 0;

  // assign digit = (check_max) ? ((max_prob < digit_prob) ? output_unit_addr : digit) : 0; 

  // FSM
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
      curr_state <= IDLE;
    end
    else
      curr_state <= next_state;

  always_comb begin
    //default values
    select_input = 0;
    increment_input = 0;
    increment_output = 0;
    done = 0;
    clr_n = 0;
    check_max = 0;
    next_state = IDLE;
    write_hidden = 0;
    write_out = 0;

    case (curr_state)
      IDLE:
        if (start) begin					//start bit detected
          next_state = MAC1;
        end

      MAC1: begin
        if (!addr_input_unit_max)
          clr_n = 1;
        else
          write_hidden = 1;
        if (cnt_hidden_max)	begin //at middle of start bit
          next_state = MAC2;
        end
        else begin
          increment_input = 1;
          next_state = MAC1;
        end
      end

      MAC2: begin
        select_input = 1;
        if (!addr_ram_hidden_max)
            clr_n = 1;
        else 
          write_out = 1;
        if (cnt_output_max) begin	//middle of a bit which isn't the stop bit
          next_state = MAX;
        end
        else begin
          increment_output = 1;
          next_state = MAC2;
        end

      end

      MAX: begin
        check_max = 1;
        if (digit_max) begin
          next_state = DONE;
        end
        else begin
          increment_digit = 1;
          next_state = MAX;
        end
      end

      DONE: begin 
        check_max = 1;
        done = 1;
        next_state = IDLE;
      end
    endcase
  end

  //address input unit counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      addr_input_unit <= 10'b0;
    else
      if (addr_input_unit_max)
        addr_input_unit <= 10'b0;
      else
        if (increment_input)
          addr_input_unit <= addr_input_unit+1;

  //hidden weight address counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cnt_hidden <= 6'b0;
    else
      if (addr_input_unit_max)
        cnt_hidden <= cnt_hidden + 1;
      else if (increment_output)
        cnt_hidden <= cnt_hidden + 1;

  //address ram hidden counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      addr_ram_hidden <= 5'b0;
    else
      //if (addr_ram_hidden_max)
      //  addr_ram_hidden <= 5'b0;
      //else 
      if (increment_output)
        addr_ram_hidden <= addr_ram_hidden + 1;
      else if (addr_input_unit_max)
        addr_ram_hidden <= addr_ram_hidden + 1;

  //output weight address counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cnt_output <= 4'h0;
    else
      if (addr_ram_hidden_max)
        cnt_output <= cnt_output + 1;

  //output address counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
      output_unit_addr <= 4'b0;
    end
    else begin
      if (digit_max) begin
        if (write_out || check_max)
          output_unit_addr <= 4'b0;
      end

      else if (increment_digit)
          output_unit_addr <= output_unit_addr + 1;
      else if (addr_ram_hidden_max)
          output_unit_addr <= output_unit_addr + 1;
    end

    //digit of max prob needs to be one clock cycle behind input address
    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n)
        digit_reg <= 0;
      else 
        digit_reg <= output_unit_addr;

endmodule
