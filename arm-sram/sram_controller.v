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
    output              sram_ub_n_out,  //
    output              sram_lb_n_out, //
    output              sram_we_n_out,  
    output              sram_ce_n_out, //
    output              sram_oe_n_out //
);

    parameter MEMORY_LATENCY = 6;

    localparam CW = $clog2(MEMORY_LATENCY); // counter width
    
    reg         [CW-1:0] latency_cycle_count;

    wire                memory_access_pending;
    wire        [15:0]  write_data_16bit;

    initial begin
        latency_cycle_count = 0;
    end

    assign {sram_ub_n_out, sram_lb_n_out, sram_ce_n_out, sram_oe_n_out} = 4'b0;
    assign memory_access_pending        =  w_en_in | r_en_in;
    assign sram_dq_out                  = (w_en_in) ? (write_data_16bit) : 16'bz;
    assign ready_out                    =
        (latency_cycle_count == 3'b101) ? (1'b1) :
        (memory_access_pending) ? (1'b0) : 1'b1;
    assign sram_addr_out                =
        ((latency_cycle_count == 3'b000) & (memory_access_pending)) ? ({address_in[16:0], 1'b0}) :
        ((latency_cycle_count == 3'b001) & (memory_access_pending)) ? ({address_in[16:0], 1'b1}) : 18'bz;

    // sram write/read control signals
    assign sram_we_n_out = ~((~|latency_cycle_count[CW-1:1]) & (w_en_in));

    // data to write control 
    assign write_data_16bit             =
        ((latency_cycle_count == 3'b000) & (w_en_in)) ? (write_data_in[15:0]) :
        ((latency_cycle_count == 3'b001) & (w_en_in)) ? (write_data_in[31:16]) : 16'bz;

    // data to read control
    always @(posedge clk) begin
        if(     (latency_cycle_count == 3'b001) & (r_en_in))    read_data_out <= {read_data_out[31:16], sram_dq_out};  
        else if((latency_cycle_count == 3'b010) & (r_en_in))    read_data_out <= {sram_dq_out, read_data_out[15:0]}; 
        else                                                    read_data_out <= read_data_out;
    end

    // latency control
    always @(posedge clk) begin
        if(latency_cycle_count == (MEMORY_LATENCY - 1)) begin
            latency_cycle_count <= 3'b000;
        end
        else if(memory_access_pending) begin 
            latency_cycle_count <= latency_cycle_count + 3'b001;
        end
    end

endmodule