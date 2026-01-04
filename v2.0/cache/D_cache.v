//D_cache
//64 KB / 核
//高带宽、低延迟，支持非阻塞访问
//缓存行数据宽度为64位

module D_cache (
    input wire clk,                    //clk bit
    input wire reset,                  //reset

    //面向LSU（端口只读）
    input wire [63:0] read_address,    //read address
    output reg [63:0] read_data,       //data out
    output reg cache_hit,              //cache hit bit

    //面向LSU（端口写）
    input wire [63:0] write_address,   //write address
    input wire [63:0] write_data,      //write data
    input wire write_start,            //write enable

    //系统输出
    output reg [31:0] cache_pc;        //cache
);

    //循环计数器
    integer i;              //for
    integer d;              //inst_out's bit
    integer g;              //always's integer

    //cache
    reg [63:0] inst_mem [0:8191];    //data's mem
    reg [63:0] inst_tag [0:8191];    //data's tag (inst's adderss)
    reg valid_bit [0:8191];          //inst's valid_bit (1 = true 0 = false)
    reg dirty_bit [0:8191];          //inst's dirty_bit (1 = dirty)

    //执行逻辑
    //reset
    always @(posedge reset) begin
        for (g = 0; g < 8192; g = g + 1) begin
            inst_mem[g] <= 64'b0;               //inst_cache to zero
            inst_tag[g] <= 64'b0;               //inst_tag to zero
            valid_bit[g] <= 1'b0;               //valid_bit to zero
            dirty_bit[g] <= 1'b0;               //dirty_bit to zero
        end

        cache_pc <= 32'b0;                       //cache's adder to zero

        //cache's out to reset
        read_data <= 64'b0;                      //cache's data out to zero
        cache_hit <= 1'b0;                       //cache's hit_tag out to zero
    end

    //LSU's read
    always @(*) begin
        cache_hit <= 1'b0;                        //reset to hit's bit is zero
        for (i = 0; i < 8192; i = i + 1) begin
            if (
                (read_address == inst_tag[i])&&   //search data's tag
                (valid_bit[i])&&                  //search data is true(1)
                (!(dirty_bit[i]))                 //search data's dirty_bit is not dirty
            ) begin
                read_data <= inst_mem[i];         //data to data's out
                cache_hit <= 1'b1;                //hit to win               
            end
        end
    end

    //LSU's write
    always @(posedge clk) begin
        if (write_start) begin    //if data_in's enable is true
            for (i = 0; i < 8192; i = i + 1) begin   //saerch the data's adderss(one)
                if (
                    (write_address == inst_tag[i])&&  //search data's tag
                    (valid_bit[i])&&                  //search data is true(1)
                    (!(dirty_bit[i]))                 //search data's dirty_bit is not dirty
                ) begin
                    valid_bit[i] <= 1'b0;             //the data is found
                end
            end

            //write the data
            if (cache_pc => 32'd8191) begin         //if cache_pc is 8191
                cache_pc <= 32'b0;                  //the cache is zero
            end
            else begin
                cache_pc <= cache_pc + 1;           //pc + 1
            end

            inst_mem[cache_pc] <= write_data;       //write the data
            inst_tag[cache_pc] <= write_address;    //write the adderss
            valid_bit[cache_pc] <= 1'b1;            //write the valid is true
            dirty_bit[cache_pc] <= 1'b0;            //write this is not dirty
        end
    end
endmodule