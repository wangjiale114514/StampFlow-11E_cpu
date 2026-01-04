//I_cache缓存
//64 KB / 核
//高带宽、低延迟，支持非阻塞访问
//带指令位宽标签页和正常指令缓存的内容
//配置缓存加法器加物理数值填入

//缓存设计，一个缓存加法器，每次访问新建一个地址存储虚拟映射被访问的数据保持数据常新、指令缓存是常新且关注二缓的，如果二缓某个数据被改写了就标记脏数据并改写

//缓存得标签数据由取指阶段查找

//二缓是随时跟随一级数据缓存的

module I_cache (
    input wire clk,        //clk
    input wire reset,      //reset bit

    //面向取指（仅输出）
    input wire [63:0] address,       //address
    output wire [255:0] out,         //cache_out
    output wire [255:0] tag_out,     //tag out
    output reg [3:0] cache_hit,      //cache_hit out
    
    //面向与取指后的输入tag
    input wire [63:0] address_in,     //tag's in address
    input wire [255:0] in_bit_tag,    //tag's in tag
    input wire in_tag_start,          //tag's in enable

    //输入的数据
    input wire [255:0] data_in_adderss,//data's in adderss
    input wire [255:0] data_in_data,  //data's in data
    input wire [3:0] data_in_start,   //data's in enable(four)

    //面向D_cache的监视器
    input wire [63:0] data_adderss_look,    //D_cache adderss's out monitor
    input wire [63:0] data_look,            //D_cache data's out monitor
    input wire data_out_start,              //D_cache enable's monitor

    //系统输出
    output reg [31:0] cache_pc              //cache's pc adder
);

    //循环计数器
    integer i;              //for
    integer d;              //inst_out's bit
    integer g;              //always's integer

    //内存
    reg [63:0] inst_mem [0:8191];    //data's mem
    reg [63:0] inst_tag [0:8191];    //data's tag (inst's adderss)
    reg valid_bit [0:8191];          //inst's valid_bit (1 = true 0 = false)
    reg dirty_bit [0:8191];          //inst's dirty_bit (1 = dirty)

    reg [63:0] tag_mem [0:8191];     //tag's mem (inst's tag)

    //内存输出分割
    //data's out
    reg [63:0] data_out [0:3];       //four inst out
    assign out[63:0] = data_out[0];   //1
    assign out[127:64] = data_out[1]; //2
    assign out[191:128] = data_out[2];//3
    assign out[255:192] = data_out[3];//4

    //tag's out
    reg [63:0] tag_out_out [0:3];    //four tag out(inst_tag's out)
    assign tag_out[63:0] = tag_out_out[0];    //1
    assign tag_out[127:64] = tag_out_out[1];  //2
    assign tag_out[191:128] = tag_out_out[2]; //3
    assign tag_out[255:192] = tag_out_out[3]; //4

    //tag's in
    wire [63:0] tag_in_in [0:3];      //four tag's write in
    assign tag_in_in[0] = in_bit_tag[63:0];    //1
    assign tag_in_in[1] = in_bit_tag[127:64];  //2
    assign tag_in_in[2] = in_bit_tag[191:128]; //3
    assign tag_in_in[3] = in_bit_tag[255:192]; //4
    
    //data's in
    //write data(4)
    wire [31:0] write_start_fifo [0:4];      //write bit's fifo(loop)
    reg [31:0] cache_pc_next;                //next_pc's next adderss
    //set fifo
    assign write_start_fifo[0] = ((cache_pc + 0) <= 32'd8191) ? cache_pc + 0 : ((cache_pc + 0) - 32'd8192);  
    assign write_start_fifo[1] = ((cache_pc + 1) <= 32'd8191) ? cache_pc + 1 : ((cache_pc + 1) - 32'd8192);
    assign write_start_fifo[2] = ((cache_pc + 2) <= 32'd8191) ? cache_pc + 2 : ((cache_pc + 2) - 32'd8192);
    assign write_start_fifo[3] = ((cache_pc + 3) <= 32'd8191) ? cache_pc + 3 : ((cache_pc + 3) - 32'd8192);
    assign write_start_fifo[4] = ((cache_pc + 4) <= 32'd8191) ? cache_pc + 4 : ((cache_pc + 4) - 32'd8192);

    //write data's data
    wire [63:0] write_data [0:3];                 //write data
    assign write_data[0] = data_in_data[63:0];
    assign write_data[1] = data_in_data[127:64];
    assign write_data[2] = data_in_data[191:128];
    assign write_data[3] = data_in_data[255:192];

    //write data's adderss
    wire [63:0] data_adderss [0:3];
    assign data_adderss[0] = data_in_adderss[63:0];
    assign data_adderss[1] = data_in_adderss[127:64];
    assign data_adderss[2] = data_in_adderss[191:128];
    assign data_adderss[3] = data_in_adderss[255:192];


    //执行逻辑
    //reset
    always @(posedge reset) begin
        for (g = 0; g < 8192; g = g + 1) begin
            inst_mem[g] <= 64'b0;               //inst_cache to zero
            inst_tag[g] <= 64'b0;               //inst_tag to zero
            valid_bit[g] <= 1'b0;               //valid_bit to zero
            dirty_bit[g] <= 1'b0;               //dirty_bit to zero
            tag_mem[g] <= 1'b0;
        end
        cache_pc <= 32'b0;                       //cache's adder to zero

        //cache's out to reset
        out <= 256'b0;                           //cache's inst out to zero
        tag_out <= 256'b0;                       //cache's tag out to zero
        cache_hit <= 4'b0;                       //cache's hit_tag out to zero

    end

    //cache's out I_cache's search bot
    always @(*) begin
        cache_hit <= 4'b0;                            //reset to hit's bit is zero
        for (d = 0; d < 25; d = d + 8) begin          //search data's bit (four)
            for (i = 0; i < 8192; i = i + 1) begin    //saerch data's adderss
                if (
                    ((address + d) == inst_tag[i])&&  //search data's tag
                    (valid_bit[i])&&                  //search data is true(1)
                    (!(dirty_bit[i]))                 //search data's dirty_bit is not dirty
                ) begin
                    data_out[d/8] <= inst_mem[i];       //data to data's out
                    tag_out_out[d/8] <= tag_mem[i];     //inst's tag to tag out
                    cache_hit[d/8] <= 1'b1;             //hit to win               
                end
            end
        end
    end

    //in inst's tag
    always @(posedge clk) begin
        if (in_tag_start) begin   //if in_tag_start(tag_in's enable) is true
            for (d = 0; d < 25; d = d + 8) begin        //search data's bit (four)
                for (i = 0; i < 8192; i = i + 1) begin  //saerch data's adderss
                    if (
                    ((address_in + d) == inst_tag[i])&& //search data's tag
                    (valid_bit[i])&&                    //search data is true(1)
                    (!(dirty_bit[i]))                   //search data's dirty_bit is not dirty
                    ) begin
                        tag_mem[i] <= tag_in_in[d/8];     //write the tag
                    end
                end
            end
        end
    end

    //data's in
    always @(posedge clk) begin
        if (data_in_start != 4'b0) begin    //if data_in's enable is true
            for (d = 0; d < 25; d = d + 8) begin  
                for (i = 0; i < 8192; i = i + 1) begin          //saerch the data's adderss(four)
                    if (                                        //Invalidate data if address is found
                        ((data_in_adderss + d) == inst_tag[i])&&//search data's tag
                        (valid_bit[i])&&                        //search data is true(1)
                        (!(dirty_bit[i]))                       //search data's dirty_bit is not dirty
                    ) begin                
                        valid_bit[i] <= 1'b0;                   //the data is found
                    end
                end
            end

            //write the data
            cache_pc <= cache_pc_next;           //pc + 1

            for (d = 0; d < 4; d = d + 1) begin
                if (data_in_start[d]) begin                                     //search enable
                    inst_mem[write_start_fifo[d]] <= write_data[d];             //write the data
                    inst_tag[write_start_fifo[d]] <= data_adderss[d];           //write the adderss
                    valid_bit[write_start_fifo[d]] <= 1'b1;                     //write the valid is true
                    dirty_bit[write_start_fifo[d]] <= 1'b0;                     //write this is not dirty
                    tag_mem[write_start_fifo[d]] <= 64'b0;                      //reset the inst's tag
                    cache_pc_next <= write_start_fifo[4];                       //set cache_pc's next adderss 
                end
            end

        end
    end

    //D_cache's monitor
    always @(posedge data_out_start) begin    //if data_out_start is top
        for (i = 0; i < 8192; i = i + 1) begin
            if (
                (data_adderss_look == inst_tag[i])&&//search data's tag
                (valid_bit[i])&&                    //search data is true(1)
                (!(dirty_bit[i]))                   //search data's dirty_bit is not dirty
            ) begin
                dirty_bit[i] <= 1'b1;               //data is dirty
            end
        end
    end
endmodule