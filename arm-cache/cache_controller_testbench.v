module cache_controller_testbench;

    reg                 duv_clk;
    reg                 duv_rst;
    reg         [31:0]  duv_address_bus;
    reg         [31:0]  duv_write_data_in;
    reg                 duv_w_en_in;
    reg                 duv_r_en_in;
    
    wire        [17:0]  sram_cont_dev_addr;  
    wire        [15:0]  sram_cont_dev_dq;
    wire                sram_cont_dev_we_n;  
    wire        [63:0]  sram_cont_read_data;
    wire                sram_cont_ready;

    wire        [31:0]  cache_sram_cont_write_data;
    wire        [31:0]  cache_sram_cont_addr;
    wire        [31:0]  cache_read_data_out;
    wire                cache_ready_out;
    wire                cache_sram_r_en_out;
    wire                cache_sram_w_en_out;

    sram_model SRAM_DUV(
        .clk                    (duv_clk),
        .rst                    (duv_rst),
        .sram_dq_inout          (sram_cont_dev_dq),
        .sram_addr_in           (sram_cont_dev_addr),
        .sram_we_n_in           (sram_cont_dev_we_n)
    );

    sram_controller SRAM_CONTROLLER_DUV(
        .clk                    (duv_clk),
        .rst                    (duv_rst),
        .w_en_in                (cache_sram_w_en_out),
        .r_en_in                (cache_sram_r_en_out),
        .address_in             (cache_sram_cont_addr),
        .write_data_in          (cache_sram_cont_write_data),
        .read_data_out          (sram_cont_read_data),
        .ready_out              (sram_cont_ready),
        .sram_dq_out            (sram_cont_dev_dq),
        .sram_addr_out          (sram_cont_dev_addr),  
        .sram_we_n_out          (sram_cont_dev_we_n)
    );

    cache_controller CAHCE_CONTROLLER_DUV(
        .clk                    (duv_clk),
        .rst                    (duv_rst),
        .address_bus_in         (duv_address_bus),
        .write_data_in          (duv_write_data_in),
        .mem_r_en_in            (duv_r_en_in),
        .mem_w_en_in            (duv_w_en_in),
        .read_data_out          (cache_read_data_out),
        .ready_out              (cache_ready_out),
        .sram_read_data_in      (sram_cont_read_data),
        .sram_ready_in          (sram_cont_ready),
        .sram_addr_out          (cache_sram_cont_addr),
        .sram_write_data_out    (cache_sram_cont_write_data),
        .sram_r_en_out          (cache_sram_r_en_out),
        .sram_w_en_out          (cache_sram_w_en_out)
    ); 

    task read_32bits_at;

        input [31:0] read_task_address;
        
        begin
            duv_r_en_in = 1;
            duv_address_bus = read_task_address;
            @(posedge duv_clk) ;
            while (~cache_ready_out) @(posedge duv_clk) ;
            $display("read data. MEM[%h]=%h", read_task_address, cache_read_data_out);
            duv_r_en_in = 0;
            duv_address_bus = 32'b0;
            @(posedge duv_clk) ;
        end
    endtask

    task write_32bits_at;

        input [31:0] write_task_address;
        input [31:0] write_task_data;
        
        begin
            duv_w_en_in = 1;
            duv_address_bus = write_task_address;
            duv_write_data_in = write_task_data;
            @(posedge duv_clk) ;
            while (~cache_ready_out) @(posedge duv_clk) ;
            $display("wrote data. MEM[%h]=%h", write_task_address, write_task_data);
            duv_w_en_in = 0;
            duv_address_bus = 32'b0;
            @(posedge duv_clk) ;
        end
    endtask

    always #10 duv_clk = ~duv_clk;

    initial begin
        duv_clk = 0;
        duv_rst = 0;
        duv_address_bus = 0;
        duv_write_data_in = 0;
        duv_w_en_in = 0;
        duv_r_en_in = 0;

        @(posedge duv_clk) duv_rst = 1;
        @(posedge duv_clk) duv_rst = 0;

        // write stage
        // these all will be only written to main memory. (sram)
        // because all of them will be miss'ed 
        write_32bits_at(32'b000000000000000_0000000000_000000_0, 32'hF0F0_F0F0);
        repeat(20) @(posedge duv_clk) ;

        write_32bits_at(32'b000000000000000_0000000000_000000_1, 32'hFFFF_FFFF);
        repeat(20) @(posedge duv_clk) ;

        write_32bits_at(32'b000000000000000_1111111111_000000_0, 32'hAAAA_AAAA);
        repeat(20) @(posedge duv_clk) ;

        write_32bits_at(32'b000000000000000_1111111111_000000_1, 32'hBBBB_BBBB);
        repeat(20) @(posedge duv_clk) ;

        write_32bits_at(32'b000000000000000_0101010101_000000_0, 32'hDDDD_CCCC);
        repeat(20) @(posedge duv_clk) ;

        write_32bits_at(32'b000000000000000_0101010101_000000_1, 32'hFFFF_EEEE);
        repeat(20) @(posedge duv_clk) ;
        // end of write stage

        repeat(100) @(posedge duv_clk) ;
        // read stage

        // cache[0], left cell recently used
        read_32bits_at(32'b000000000000000_0000000000_000000_0); 
        repeat(20) @(posedge duv_clk) ;

        // cache[0], right cell recently used
        read_32bits_at(32'b000000000000000_1111111111_000000_1); 
        repeat(20) @(posedge duv_clk) ;

        // cache[0], left cell recently used
        read_32bits_at(32'b000000000000000_0000000000_000000_0); 
        repeat(20) @(posedge duv_clk) ;

        // cache[0], read a new memory address
        // the right cell in cache[0] should be replaced.
        read_32bits_at(32'b000000000000000_0101010101_000000_0);
        repeat(50) @(posedge duv_clk) ;

        $stop();

    end


endmodule