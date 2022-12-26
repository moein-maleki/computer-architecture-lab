module sram_controller(
    input               clk,
    input               rst,

    // from memory stage
    input               w_en_in,
    input               r_en_in,
    input       [31:0]  address_in,
    input       [31:0]  write_data_in,

    // to wb stage
    output reg  [31:0]  read_data_out,

    // to freeze other stages
    output              ready_out,

    // sram control signals
    inout       [15:0]  sram_dq_out,
    output      [17:0]  sram_addr_out,  
    output              sram_ub_n_out, // useless signal (to us. we don't use them.)
    output              sram_lb_n_out, // useless signal
    output              sram_we_n_out,  
    output              sram_ce_n_out, // useless signal
    output              sram_oe_n_out  // useless signal
);

    parameter MEMORY_LATENCY = 6;

    localparam CW = $clog2(MEMORY_LATENCY); // counter width
    
    reg         [CW-1:0] latency_cycle_count;

    wire                memory_access_pending;
    wire        [15:0]  write_data_16bit;
    wire        [16:0]  address_slice_accessed;

    initial begin
        latency_cycle_count = 0;    
    end

    assign {sram_ub_n_out, sram_lb_n_out, sram_ce_n_out, sram_oe_n_out} = 4'b0;
    assign memory_access_pending        =  w_en_in | r_en_in;
    assign sram_dq_out                  = (w_en_in) ? (write_data_16bit) : 16'bz;
    assign ready_out                    =
        (latency_cycle_count == MEMORY_LATENCY-1)   ? (1'b1) :
        (memory_access_pending)                     ? (1'b0) : 1'b1;
    assign address_slice_accessed       = address_in[16:0];
    assign sram_addr_out                =
        ((latency_cycle_count == 0) & (memory_access_pending)) ? ({address_slice_accessed, 1'b0}) :
        ((latency_cycle_count == 1) & (memory_access_pending)) ? ({address_slice_accessed, 1'b1}) : 18'bz;

    // sram write/read control signals
    assign sram_we_n_out = ~((~|latency_cycle_count[CW-1:1]) & (w_en_in));

    // data to write control 
    assign write_data_16bit             =
        ((latency_cycle_count == 0) & (w_en_in)) ? (write_data_in[15:0]) :
        ((latency_cycle_count == 1) & (w_en_in)) ? (write_data_in[31:16]) : 16'bz;

    // data to read control
    always @(posedge clk) begin
        if(rst)                                             read_data_out <= 0;
        else if((latency_cycle_count == 1) & (r_en_in))     read_data_out <= {read_data_out[31:16], sram_dq_out};  
        else if((latency_cycle_count == 2) & (r_en_in))     read_data_out <= {sram_dq_out, read_data_out[15:0]}; 
        else                                                read_data_out <= read_data_out;
    end

    // latency control
    always @(posedge clk) begin
        if(rst)                                                 latency_cycle_count <= 0;
        else if(latency_cycle_count == (MEMORY_LATENCY - 1))    latency_cycle_count <= 0;
        else if(memory_access_pending)                          latency_cycle_count <= latency_cycle_count + 1;
        else                                                    latency_cycle_count <= latency_cycle_count;
    end

endmodule