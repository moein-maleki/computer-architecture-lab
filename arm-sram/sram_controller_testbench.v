module sram_controller_testbench;

    reg               duv_clk;
    reg               duv_rst;
    reg               duv_w_en_in;
    reg               duv_r_en_in;
    reg       [31:0]  duv_address_in;
    reg       [31:0]  duv_write_data_in;
    // reg       [15:0]  duv_sram_dq_out_read;
    
    wire      [15:0]  duv_sram_dq_out;
    wire      [31:0]  duv_read_data_out;
    wire              duv_ready_out;
    wire      [17:0]  duv_sram_addr_out;
    wire              duv_sram_ub_n_out;
    wire              duv_sram_lb_n_out;
    wire              duv_sram_we_n_out;
    wire              duv_sram_ce_n_out;
    wire              duv_sram_oe_n_out;

    // assign duv_sram_dq_out = (duv_r_en_in) ? (duv_sram_dq_out_read) : (16'bz); 

    sram_model memory(
        .clk(duv_clk),
        .rst(duv_rst),
        .sram_dq_inout(duv_sram_dq_out),
        .sram_addr_in(duv_sram_addr_out),  
        .sram_ub_n_in(duv_sram_ub_n_out),           //
        .sram_lb_n_in(duv_sram_lb_n_out),           //
        .sram_we_n_in(duv_sram_we_n_out),  
        .sram_ce_n_in(duv_sram_ce_n_out),           //
        .sram_oe_n_in(duv_sram_oe_n_out)            //
);

    sram_controller duv(
        .clk                 (duv_clk),             //
        .rst                 (duv_rst),             //
        .w_en_in             (duv_w_en_in),         // --> input        --    wr
        .r_en_in             (duv_r_en_in),         //--> input         rd    --
        .address_in          (duv_address_in),      //--> input         rd    wr
        .write_data_in       (duv_write_data_in),   //--> input         --    wr
        .read_data_out       (duv_read_data_out),   //--> output
        .ready_out           (duv_ready_out),       //--> output        rd
        .sram_dq_out         (duv_sram_dq_out),     //--> input/output  rd    wr
        .sram_addr_out       (duv_sram_addr_out),   //--> output 
        .sram_ub_n_out       (duv_sram_ub_n_out),   //
        .sram_lb_n_out       (duv_sram_lb_n_out),   //
        .sram_we_n_out       (duv_sram_we_n_out),   //--> output
        .sram_ce_n_out       (duv_sram_ce_n_out),   //
        .sram_oe_n_out       (duv_sram_oe_n_out)    //
    );

    task read_32bits_at;
        input [31:0] read_task_address;
        
        begin
            duv_r_en_in = 1;
            duv_address_in = read_task_address;
            @(posedge duv_ready_out) ;
            @(posedge duv_clk) ;
            duv_r_en_in = 0;
            duv_address_in = 32'bz;
            @(posedge duv_clk) ;
        end
    endtask

    task write_32bits_at;
        input [31:0] write_task_address;
        input [31:0] write_task_data;
        begin
            duv_w_en_in = 1;
            duv_address_in = write_task_address;
            duv_write_data_in = write_task_data;
            @(posedge duv_ready_out) ;
            @(posedge duv_clk) ;
            duv_w_en_in = 0;
            duv_address_in = 32'bz;
            @(posedge duv_clk) ;
        end
    endtask


    always #10 duv_clk = ~duv_clk;

    initial begin
        duv_clk = 0;
        duv_rst = 0;
        duv_w_en_in = 0;
        duv_r_en_in = 0;
        duv_address_in = 0;
        duv_write_data_in = 0;
        // duv_sram_dq_out_read = 16'h1122;

        @(posedge duv_clk) ;
        write_32bits_at(32'h0000_0000, 32'h3344_1122);
        repeat(5) @(posedge duv_clk) ;

        read_32bits_at(32'h0000_0000);
        repeat(5) @(posedge duv_clk) ;
        $stop();
    end

endmodule