module testbench;

    reg duv_clk;
    reg duv_rst;
    
    arm_processor DUV (
        .clk(duv_clk),
        .rst(duv_rst)
    );

    always #10 duv_clk = ~duv_clk;

    initial begin
        duv_rst = 0;
        duv_clk = 0;

        @(posedge duv_clk) duv_rst = 1;
        @(posedge duv_clk) duv_rst = 0;

        repeat(200) @(posedge duv_clk) ;
        $stop();
    end

endmodule

