`timescale 1ns/1ns

module testbench;

    reg                 duv_clk;
    reg         [17:0]  duv_sw;

    wire        [15:0]  sram_inout_dq;
    wire        [17:0]  sram_in_addr;
    wire                sram_in_we_n;
    wire                sram_in_ub_n;
    wire                sram_in_lb_n;
    wire                sram_in_ce_n;
    wire                sram_in_oe_n;

    // .rst				    (duv_sw[0]),
    // .use_forwarding		(duv_sw[2]),

    arm DUV(
        .CLOCK_50           (duv_clk),
        .SW                 (duv_sw),
        .SRAM_DQ            (sram_inout_dq),
        .SRAM_ADDR          (sram_in_addr),
        .SRAM_WE_N          (sram_in_we_n),
        .SRAM_UB_N			(sram_in_ub_n),
		.SRAM_LB_N			(sram_in_lb_n),
		.SRAM_CE_N			(sram_in_ce_n),
		.SRAM_OE_N			(sram_in_oe_n)
    );

    sram_model sram_unit(
        .clk                (duv_clk),
        .rst                (duv_sw[0]),
        .sram_dq_inout      (sram_inout_dq),
        .sram_addr_in       (sram_in_addr),
        .sram_we_n_in       (sram_in_we_n),
        .sram_ub_n_in       (sram_in_ub_n),  
        .sram_lb_n_in       (sram_in_lb_n), 
        .sram_ce_n_in       (sram_in_ce_n), 
        .sram_oe_n_in       (sram_in_oe_n) 
    );
    
    always #10 duv_clk = ~duv_clk;

    initial begin
        duv_clk = 0;
        duv_sw[0] = 0;
        duv_sw[2] = 1;

        @(posedge duv_clk) duv_sw[0] = 1;
        @(posedge duv_clk) duv_sw[0] = 0;

        repeat(1000) @(posedge duv_clk) ;
        $stop();
    end

endmodule