`timescale 1ns/1ns

module testbench;

    reg                 duv_clk;
    reg         [17:0]  duv_sw;

    // .rst				    (duv_sw[0]),
    // .use_forwarding		(duv_sw[2]),

    arm DUV(
        .CLOCK_50(duv_clk),
        .SW(duv_sw)
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