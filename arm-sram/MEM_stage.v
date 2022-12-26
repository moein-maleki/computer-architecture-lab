module MEM_stage(
    input               clk,
    input               rst,
    input               wb_en_in,
    input               mem_r_en_in,
    input               mem_w_en_in,
    input       [31:0]  alu_result_in,
    input       [3:0]   wb_reg_dest_in,  
    input       [31:0]  val_rm_in,

    output              wb_en_out,
    output              mem_r_en_out,
    output      [31:0]  alu_result_out,
    output      [31:0]  data_memory_result_out,
    output      [3:0]   wb_reg_dest_out,
    output      [31:0]  frwd_mem_value_out,

    // sram wires
    output              sram_busy_out,
    inout      [15:0]   sram_dq_inout,
    output     [17:0]   sram_addr_out,
    output              sram_ub_n_out,
    output              sram_lb_n_out,
    output              sram_we_n_out,
    output              sram_ce_n_out,
    output              sram_oe_n_out
);

    wire                sram_ready;
    wire        [31:0]  memory_address;
    wire        [31:0]  aligned_address;

    // control signal passing
    assign wb_en_out                    = wb_en_in;
    assign mem_r_en_out                 = mem_r_en_in;
    assign alu_result_out               = alu_result_in;
    assign wb_reg_dest_out              = wb_reg_dest_in;

    // forwarding
    assign frwd_mem_value_out           = alu_result_out;

    // address alignment
    assign memory_address = alu_result_in - 32'd1024;
    assign aligned_address = {memory_address[31:2], 2'b0};

    // sram busy - to freeze other stages 
    assign sram_busy_out = ~sram_ready;

    sram_controller sram_ctrl_unit(
        .clk                (clk),
        .rst                (rst),

        // from memory stage
        .w_en_in            (mem_w_en_in),
        .r_en_in            (mem_r_en_in),
        .address_in         (aligned_address),
        .write_data_in      (val_rm_in),

        // to wb stage
        .read_data_out      (data_memory_result_out),

        // ready signal - sram busy freezes other stages
        .ready_out          (sram_ready),

        // sram control signals
        .sram_dq_out        (sram_dq_inout),
        .sram_addr_out      (sram_addr_out),  
        .sram_ub_n_out      (sram_ub_n_out),
        .sram_lb_n_out      (sram_lb_n_out),
        .sram_we_n_out      (sram_we_n_out),  
        .sram_ce_n_out      (sram_ce_n_out),
        .sram_oe_n_out      (sram_oe_n_out)
    );

endmodule