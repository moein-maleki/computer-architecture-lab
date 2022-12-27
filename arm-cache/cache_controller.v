`define IDLE

`define _right_cell    0 
`define _left_cell     1   

`define _right_valid        75
`define _right_tag          74:65
`define _right_data_block   64:1
`define _right_data_block_1 64:33
`define _right_data_block_0 32:1

`define _left_valid         150
`define _left_tag           149:140
`define _left_data_block    139:76
`define _left_data_block_1  139:108
`define _left_data_block_0  107:76

`define _used                   0
`define left_cell_last_used     0    
`define right_cell_last_used    1

module cache_controller(
    input               clk,
    input               rst,

    // memory stage signals
    input       [31:0]  address_bus_in,
    input       [31:0]  write_data_in,
    input               mem_r_en_in,
    input               mem_w_en_in,
    output      [31:0]  read_data_out,
    output              ready_out,

    // sram signals
    input       [63:0]  sram_read_data_in,
    input               sram_ready_in,
    output      [31:0]  sram_addr_out,
    output      [31:0]  sram_write_data_out,
    output              sram_r_en_out,
    output              sram_w_en_out
); 

    integer i;
    reg already_logged_transaction;
    initial begin
        already_logged_transaction <= 0;
    end

    reg         [150:0] cache_ds [63:0];

    // relevant address bits
    wire        [5:0]   address_index;
    wire        [9:0]   address_tag;
    wire                address_word_offset;
    
    // cache ds wires
    wire                left_valid;
    wire        [9:0]   left_tag;
    wire        [63:0]  left_data_block;
    wire        [31:0]  left_data_block_0;
    wire        [31:0]  left_data_block_1;
    wire                right_valid;
    wire        [9:0]   right_tag;
    wire        [63:0]  right_data_block;
    wire        [31:0]  right_data_block_0;
    wire        [31:0]  right_data_block_1;
    wire                used;

    // aux wires
    wire                memory_access_pending;
    wire                hit;
    wire                hit_left_cell;
    wire                hit_right_cell;
    wire        [31:0]  dest_block [1:0]; // placement: {1: OFFSET_1, 0: OFFSET_0}
    
    // dest_postion indicates which of the two cells at each row ...
    // ... of the 2-way set associative is chosen as dest_block. ...
    // ... left is 1. right is 0.
    wire                dest_postion;

    // address segments assignments
    assign address_index        = address_bus_in[6:1];
    assign address_tag          = address_bus_in[16:7];
    assign address_word_offset  = address_bus_in[0];

    // cache ds assignments
    assign left_valid           = cache_ds[address_index][`_left_valid];
    assign left_tag             = cache_ds[address_index][`_left_tag];
    assign left_data_block      = cache_ds[address_index][`_left_data_block];
    assign left_data_block_0    = cache_ds[address_index][`_left_data_block_0];
    assign left_data_block_1    = cache_ds[address_index][`_left_data_block_1];
    assign right_valid          = cache_ds[address_index][`_right_valid];
    assign right_tag            = cache_ds[address_index][`_right_tag];
    assign right_data_block     = cache_ds[address_index][`_right_data_block];
    assign right_data_block_0   = cache_ds[address_index][`_right_data_block_0];
    assign right_data_block_1   = cache_ds[address_index][`_right_data_block_1];
    assign used                 = cache_ds[address_index][`_used];

    // hit management
    assign hit_left_cell        = (address_tag == left_tag)  & left_valid; //((address_tag == left_tag)  & left_valid)  ? (1'b1) : (1'b0);
    assign hit_right_cell       = (address_tag == right_tag) & right_valid; //((address_tag == right_tag) & right_valid) ? (1'b1) : (1'b0);
    assign hit                  = (hit_left_cell) | (hit_right_cell);

    // block data managment
    assign dest_postion         =
        (hit_left_cell)                 ? (`_left_cell)  :           // priority 1: matched-tag block
        (hit_right_cell)                ? (`_right_cell) :           // ^^
        (~left_valid)                   ? (`_left_cell)  :           // priority 2: invalid block
        (~right_valid)                  ? (`_right_cell) :           // ^^
        (used == `right_cell_last_used) ? (`_left_cell)  :           // priority 3: valid block but tag missed, replace LRU block.
        (used == `left_cell_last_used)  ? (`_right_cell) : (1'bz);   // ^^
    assign {dest_block[1], dest_block[0]} =
        (dest_postion == `_left_cell)  ? ({left_data_block_1, left_data_block_0}) :
        (dest_postion == `_right_cell) ? ({right_data_block_1, right_data_block_0}) : 64'bz;

    // ready managment
    assign memory_access_pending        =  mem_w_en_in | mem_r_en_in;
    assign ready_out            = 
        (hit & mem_r_en_in)                                     ? (1'b1) :
        ((hit & mem_w_en_in) | (~hit & memory_access_pending))  ? (~(memory_access_pending ^ sram_ready_in)) : (1'b1) ;

    // cache read data out control
    assign read_data_out        =
        (hit) ? (dest_block[address_word_offset]) :
        (
            (~address_word_offset) ? (sram_read_data_in[31:0]) : (sram_read_data_in[63:32])
        );

    // sram read/write input signal managemnet
    assign sram_r_en_out        = (mem_r_en_in) & (~hit);
    assign sram_w_en_out        = mem_w_en_in;
    assign sram_write_data_out  = write_data_in;
    assign sram_addr_out        = address_bus_in;

    // cache mechanics
    always@(posedge clk) begin
        if(rst) begin
            for (i=0; i<64; i=i+1) begin
                cache_ds[i][`_left_valid]     <= 0;
                cache_ds[i][`_right_valid]    <= 0;
            end

        end
        else if(hit) begin
            if(mem_r_en_in) begin
                // hit & read. data is in cache.
                // return dest_block[word_offset];
                if(dest_postion == `_left_cell) cache_ds[address_index][`_used] <= `left_cell_last_used;
                else                            cache_ds[address_index][`_used] <= `right_cell_last_used;

            end

            else if(mem_w_en_in) begin
                // hit & write. data is in cache.
                // overwrite cached data at dest_block[address_word_offset].
                // write-through to memory (32-bits).
                // memory write address = address_bus_in
                if(dest_postion == `_left_cell) begin
                    if(address_word_offset) cache_ds[address_index][`_left_data_block_1] <= write_data_in;
                    else                    cache_ds[address_index][`_left_data_block_0] <= write_data_in;
                end
                else begin
                    if(address_word_offset) cache_ds[address_index][`_right_data_block_1] <= write_data_in;
                    else                    cache_ds[address_index][`_right_data_block_0] <= write_data_in;
                end

            end

        end
        else if(~hit) begin
            if(mem_r_en_in) begin
                // miss & read. data isn't in cache.
                // read block (64-bits) from memory.
                // read address = {address_bus_in[31:1], 0} to the whole 64-bits
                // place the 64-bits in dest_block position.
                // place the tag and set the valid.
                if(sram_ready_in) begin
                    if(dest_postion == `_left_cell) begin
                        cache_ds[address_index][`_left_data_block]  <= sram_read_data_in;
                        cache_ds[address_index][`_left_tag]         <= address_tag;
                        cache_ds[address_index][`_left_valid]       <= 1;
                        cache_ds[address_index][`_used]             <= `left_cell_last_used;
                    end
                    else begin
                        cache_ds[address_index][`_right_data_block] <= sram_read_data_in;
                        cache_ds[address_index][`_right_tag]        <= address_tag;
                        cache_ds[address_index][`_right_valid]      <= 1;
                        cache_ds[address_index][`_used]             <= `right_cell_last_used;
                    end
                end

            end

            else if(mem_w_en_in) begin
                // miss & write. data isn't in cache.
                // only write data (32-bits) to memory. (no-write allocation)
                // memory write address = address_bus_in 
                // place the tag and set the valid.

            end

        end
    end

endmodule