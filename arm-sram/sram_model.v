module sram_model(
    input               clk,
    input               rst,

    inout       [15:0]  sram_dq_inout,
    input       [17:0]  sram_addr_in,  
    input               sram_ub_n_in,  
    input               sram_lb_n_in, 
    input               sram_we_n_in,  
    input               sram_ce_n_in, 
    input               sram_oe_n_in 
);

    reg         [15:0] memory_element [0:262143];
    reg        [15:0]  read_data_16bit;

    assign sram_dq_inout = (sram_we_n_in) ? (read_data_16bit) : 16'bz;

    always @(posedge clk) begin
        if(sram_we_n_in)        read_data_16bit                 <= memory_element[sram_addr_in];
        else if(~sram_we_n_in)  memory_element[sram_addr_in]    <= sram_dq_inout;
    end

endmodule