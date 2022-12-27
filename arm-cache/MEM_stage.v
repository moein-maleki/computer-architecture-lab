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

    // freeze signal
    output              stage_busy_out,
    
    // sram wires
    inout      [15:0]   sram_dq_inout,
    output     [17:0]   sram_addr_out,
    output              sram_ub_n_out,
    output              sram_lb_n_out,
    output              sram_we_n_out,
    output              sram_ce_n_out,
    output              sram_oe_n_out
);

    wire        [31:0]  memory_address;
    wire        [31:0]  aligned_address;
    wire        [63:0]  sram_ctrl_read_data_out;
    wire                sram_ctrl_ready_out;
    wire                cache_ready_out;
    wire        [31:0]  cache_sram_ctrl_address_out;
    wire        [31:0]  cache_sram_ctrl_write_data_out;
    wire                cache_sram_w_en_out;
    wire                cache_sram_r_en_out;

    // control signal passing
    assign wb_en_out                    = wb_en_in;
    assign mem_r_en_out                 = mem_r_en_in;
    assign alu_result_out               = alu_result_in;
    assign wb_reg_dest_out              = wb_reg_dest_in;

    // forwarding
    assign frwd_mem_value_out           = alu_result_out;

    // address alignment
    assign memory_address               = alu_result_in - 32'd1024;
    assign aligned_address              = {2'b0, memory_address[31:2]};

    // stage busy - to freeze other stages 
    assign stage_busy_out               = ~cache_ready_out;

    sram_controller sram_ctrl_unit(
        .clk                    (clk),
        .rst                    (rst),

        // from cache controller
        .w_en_in                (cache_sram_w_en_out),
        .r_en_in                (cache_sram_r_en_out),
        .address_in             (cache_sram_ctrl_address_out),
        .write_data_in          (cache_sram_ctrl_write_data_out),

        // the block read. to cache stage.
        .read_data_out          (sram_ctrl_read_data_out),

        // to cache. helps in writing to cache_ds and determining cache_ready_out
        .ready_out              (sram_ctrl_ready_out),

        // sram controller, sram device control signals
        .sram_dq_out            (sram_dq_inout),
        .sram_addr_out          (sram_addr_out),  
        .sram_ub_n_out          (sram_ub_n_out), // useless signal (to us. we don't use them.)
        .sram_lb_n_out          (sram_lb_n_out), // useless signal
        .sram_we_n_out          (sram_we_n_out),  
        .sram_ce_n_out          (sram_ce_n_out), // useless signal
        .sram_oe_n_out          (sram_oe_n_out)  // useless signal
    );

    cache_controller cache_ctrlunit(
        .clk                    (clk),
        .rst                    (rst),

        // memory stage signals
        .address_bus_in         (aligned_address),
        .write_data_in          (val_rm_in),
        .mem_r_en_in            (mem_r_en_in),
        .mem_w_en_in            (mem_w_en_in),
        .read_data_out          (data_memory_result_out),
        .ready_out              (cache_ready_out),

        // cache, sram controller signals
        .sram_read_data_in      (sram_ctrl_read_data_out),
        .sram_ready_in          (sram_ctrl_ready_out),
        .sram_addr_out          (cache_sram_ctrl_address_out),
        .sram_write_data_out    (cache_sram_ctrl_write_data_out),
        .sram_r_en_out          (cache_sram_r_en_out),
        .sram_w_en_out          (cache_sram_w_en_out)
    ); 

endmodule