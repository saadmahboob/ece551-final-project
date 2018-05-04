module snn_core(start, clk, rst_n, q_input, addr_input_unit, digit, done);

  typedef enum reg[1:0] {IDLE, MAC1, MAC2, DONE} state;
  state curr_state, next_state;

  output logic [9:0] addr_input_unit;
  output logic [3:0] digit, digit1, digit2;
  output logic done;

  input logic clk, start, rst_n;
  input logic q_input;

  logic select_input, inc_input_addr, increment_output, write_hidden;
  logic mac_clr_n, output_clr, hidden_clr, addr_input_unit_clr, digit_clr;

  logic [7:0]   q_extended;
  logic [7:0]   ram_hidden_data1, ram_hidden_data2;
  logic [5:0]   cnt_hidden;
  logic [4:0]   cnt_hidden1, cnt_hidden2;
  logic [7:0]   hidden_weight_q1, hidden_weight_q2;

  //MAC stuff
  logic [7:0]   a, b1, b2, lut_out1, lut_out2;
  logic [25:0]  acc1, acc2;
  logic [10:0]  addr_LUT1, addr_LUT2;

  //Max stuff
  logic [7:0]   output_weight_q, max_prob1, max_prob2;
  logic         check_max;
  logic [2:0]   digit_reg1;
  logic [3:0]   digit_reg2;
  logic [2:0]   cnt_output1, cnt_output2;

  rom_hidden_weight    hidden_weight(.clk(clk), .addr1({cnt_hidden1[4:0], addr_input_unit[9:0]}), .q1(hidden_weight_q1),
                                                .addr2({cnt_hidden2[4:0], addr_input_unit[9:0]}), .q2(hidden_weight_q2));

  rom_output_weight    output_weight(.clk(clk), .addr1({cnt_output1[3:0], cnt_hidden[4:0]}), .q1(output_weight_q1),
                                                .addr2({cnt_output2[3:0], cnt_hidden[4:0]}), .q2(output_weight_q2));

  ram_hidden_unit      hidden_unit(.clk(clk), .we(write_hidden), .data1(lut_out1), .addr1(cnt_hidden1 [4:0]), .q1(ram_hidden_data1),
                                                                .data2(lut_out2), .addr2(cnt_hidden2 [4:0]), .q2(ram_hidden_data2));

  rom_act_func_lut     act_func_lut(.clk(clk), .addr1(addr_LUT1 + 11'h400), .q1(lut_out1),
                                                .addr2(addr_LUT2 + 11'h400), .q2(lut_out2));

  mac                  mac1(.clk(clk), .a(a), .b(b1), .acc(acc1), .clr_n(mac_clr_n), .rst_n(rst_n), .addr_LUT(addr_LUT1));
  mac                  mac2(.clk(clk), .a(a), .b(b2), .acc(acc2), .clr_n(mac_clr_n), .rst_n(rst_n), .addr_LUT(addr_LUT2));

  assign q_extended = (q_input) ? 8'h7F : 8'h00;

  //MAC 1
  assign addr_input_unit_max = addr_input_unit == 10'h2ec ? 1 : 0;
  assign cnt_hidden_max = cnt_hidden1 == 5'h20 ? 1 : 0;

  //MAC 2
  assign cnt_hidden_max_out = cnt_hidden == 6'h11 ? 1 : 0;

  assign a = select_input ? ram_hidden_data : q_extended;
  assign b1 = select_input ? output_weight_q1 : hidden_weight_q1;
  assign b2 = select_input ? output_weight_q2 : hidden_weight_q2;

 always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    max_prob1 <= 8'h00;
  else
    if (digit_clr)
      max_prob1 <= 8'h00;
    else if (check_max)
      if (lut_out1 > max_prob1)
        max_prob1 <= lut_out1;

  always_ff @(posedge clk, negedge rst_n)
   if (!rst_n)
     max_prob2 <= 8'h00;
   else
     if (digit_clr)
       max_prob2 <= 8'h00;
     else if (check_max)
       if (lut_out2 > max_prob2)
         max_prob2 <= lut_out2;

  always_ff @(posedge clk, negedge rst_n)
   if (!rst_n)
     digit1 <= 0;
  else
    if (digit_clr)
      digit1 <= 0;
    else if (check_max)
      if (lut_out1 > max_prob1)
       digit1 <= digit_reg1;

   always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      digit2 <= 0;
   else
     if (digit_clr)
       digit2 <= 0;
     else if (check_max)
       if (lut_out2 > max_prob2)
        digit2 <= digit_reg2;

    always_ff @(posedge clk, negedge rst_n)
     if (!rst_n)
       digit <= 0;
    else
      if (digit_clr)
        digit <= 0;
      else if (check_max)
        if (digit1 > digit2)
         digit <= digit1;

  // FSM
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      curr_state <= IDLE;
    else
      curr_state <= next_state;

  always_comb begin
    //default values
    select_input = 0;
    inc_input_addr = 0;
    increment_output = 0;
    done = 0;
    mac_clr_n = 0;
    output_clr = 0;
    hidden_clr = 0;
    addr_input_unit_clr = 0;
    digit_clr = 0;
    check_max = 0;
    next_state = IDLE;
    write_hidden = 0;
    addr_input_unit_clr = 0;

    case (curr_state)
      IDLE:
        if (start) begin    					//start bit detected
          next_state = MAC1;
          digit_clr = 1;
          addr_input_unit_clr = 1;
        end

      MAC1: begin
        output_clr = 1;
        if (!addr_input_unit_max)
          mac_clr_n = 1;
        else
          write_hidden = 1;

        if (cnt_hidden_max)	begin
          hidden_clr = 1;
          next_state = MAC2;
        end
        else begin
          inc_input_addr = 1;
          next_state = MAC1;
        end
      end

      MAC2: begin
        select_input = 1;

        if (digit_reg1 == 4'h5)
            next_state = DONE;
        else begin
          addr_input_unit_clr = 1;
          increment_output = 1;
          next_state = MAC2;
        end

        if (cnt_hidden == 0)
            mac_clr_n = 0;
        else if (!cnt_hidden_max_out)
            mac_clr_n = 1;
        else
          check_max = 1;
      end

      DONE: begin
        check_max = 0;
        done = 1;
        next_state = IDLE;
      end

      default:
        next_state = IDLE;

    endcase
  end

  //address input unit counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      addr_input_unit <= 10'h0;
    else
      if (addr_input_unit_clr)
        addr_input_unit <= 10'h23;
      else if (addr_input_unit_max)
        addr_input_unit <= 10'h23;
      else
        if (inc_input_addr)
          addr_input_unit <= addr_input_unit + 1;

  //hidden weight address counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cnt_hidden1 <= 6'b0;
    else
      if (hidden_clr)
        cnt_hidden1 <= 6'b0;
      else if (addr_input_unit_max)
        cnt_hidden1 <= cnt_hidden1 + 1;
      else if (increment_output)
        cnt_hidden1 <= cnt_hidden1 + 1;

    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n)
        cnt_hidden2 <= 6'b10;
      else
        if (hidden_clr)
          cnt_hidden2 <= 6'b10;
        else if (addr_input_unit_max)
          cnt_hidden2 <= cnt_hidden2 + 1;
        else if (increment_output)
          cnt_hidden2 <= cnt_hidden2 + 1;

    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n)
        cnt_hidden <= 6'b0;
      else
        if (hidden_clr)
          cnt_hidden <= 6'b0;
        else if (addr_input_unit_max)
          cnt_hidden <= cnt_hidden + 1;
        else if (increment_output)
          cnt_hidden <= cnt_hidden + 1;

  //output weight address counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cnt_output <= 4'h0;
    else
      if (output_clr)
        cnt_output <= 4'h0;
      else
        if (cnt_hidden_max)
          cnt_output <= cnt_output + 1;

  //digit of max prob needs to be one clock cycle behind input address
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      digit_reg1 <= 4'h0;
    else
      if (digit_clr)
        digit_reg1 <= 4'h0;
      else
        if (check_max)
          digit_reg1 <= digit_reg1 + 1;

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      digit_reg2 <= 4'h5;
    else
      if (digit_clr)
        digit_reg2 <= 4'h5;
      else
        if (check_max)
          digit_reg2 <= digit_reg2 + 1;

endmodule
