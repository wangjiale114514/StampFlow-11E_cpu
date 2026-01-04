//L2 Cache
//2 MB / 核
//这边因为没有实际参考支撑
//读优先，写缓冲
//带一位写缓冲溢出标识（面向主存,写缓冲满了就暂停流水线）
//数据写入主存的时候要是快要消除的数值
//写直达式赋值

module L2_cache (
    input wire clk,
    input wire reset,
    output reg stop,

    //面向if方向的输出 (输出4个缓存行,增加取指位宽最大化取指效率)
    input wire [63:0] if_adderss_read,    //to "if" read adderss
    output wire [255:0] if_data_read,     //to "if" data read
    output reg [3:0] if_hit_read,         //to "if" hit bit
    //面向if方向的输入
    input wire [63:0] if_adderss_write,   //to "if" write adderss
    input wire [63:0] if_data_write,      //to "if" write data
    input wire if_write_start,            //to "if" write enable

    //面向LSU的输出(输出单个缓存行，减少污染)
    input wire [63:0] lsu_adderss_read,   //to "lsu" read adderss
    output reg [63:0] lsu_data_read,      //to "lsu" read data
    output reg lsu_hit_read,              //to "lsu" hit bit

    //面向LSU的读取
    input wire [63:0] lsu_adderss_write,  //to "lsu" write adderss
    input wire [63:0] lsu_data_write,     //to "lsu" write data
    input wire lsu_write_start,           //to "lsu" write enable

    //面向主存的写缓冲
    input reg read_stop_en,               //to "mem" if read stop the write
    output reg [63:0] mem_adderss_write,  //to "mem" write adderss
    output reg [63:0] mem_data_write,     //to "mem" write data
    output reg mem_start_write,           //to "mem" write enable

    //系统
    output reg [31:0] cache_pc            //cache pc adder
);

    //循环计数器
    integer i;              //for
    integer d;              //inst_out's bit
    integer g;              //always's integer

    //定义cache空间及内容
    reg [63:0] inst_mem [0:262144];    //data's mem
    reg [63:0] inst_tag [0:262144];    //data's tag (inst's adderss)
    reg valid_bit [0:262144];          //inst's valid_bit (1 = true 0 = false)
    reg dirty_bit [0:262144];          //inst's dirty_bit (1 = dirty)
    reg go_mem_bit [0:262144];         //to mem bit (1 = in mem)

    //LSU缓冲
    reg [63:0] lsu_fifo_data;               //this in lsu in data
    reg [63:0] lsu_fifo_adderss;            //lsu fifo's adderss
    reg lsu_fifo_en;                        //lsu fifo's enable

    //定义cache写入主存fifo内容
    //写缓冲(A)
    reg [63:0] go_mem_A_adderss [0:20];   //mem_fifo adderss reg
    reg [63:0] go_mem_A_data [0:20];      //mem_fifo adderss
    reg go_mem_A_en[0:20];                //go_mem enable
    reg [4:0] go_mem_A_pc;                //mem_fifo pc
    //写缓冲(B)
    reg [63:0] go_mem_B_adderss [0:20];   //mem_fifo adderss reg
    reg [63:0] go_mem_B_data [0:20];      //mem_fifo adderss
    reg go_mem_B_en[0:20];                //go_mem enable
    reg [4:0] go_mem_B_pc;                //mem_fifo pc

    reg go_mem_mux;                       //go_mem_mux

    //输出分割
    //to "if" out
    reg [63:0] if_read_out [0:3];    //four "if" out(inst_tag's out)
    assign if_data_read[63:0] = if_read_out[0];
    assign if_data_read[127:64] = if_read_out[1];
    assign if_data_read[191:128] = if_read_out[2];
    assign if_data_read[255:192] = if_read_out[3];

    //执行逻辑
    //reset
    always @(posedge reset) begin
        for (i = 0; i < 262145; i = i + 1) begin
            inst_mem[g] <= 64'b0;               //inst_cache to zero
            inst_tag[g] <= 64'b0;               //inst_tag to zero
            valid_bit[g] <= 1'b0;               //valid_bit to zero
            dirty_bit[g] <= 1'b0;               //dirty_bit to zero
        end

        cache_pc <= 32'b0;                       //cache's adder to zero

        //cache's out to reset
        //read_data <= 64'b0;                      //cache's data out to zero
        //cache_hit <= 1'b0;                       //cache's hit_tag out to zero

        mem_adderss_write <= 64'b0;
        mem_data_write <= 64'b0;
        mem_start_write <= 64'b0;
        lsu_data_read <= 64'b0;
        lsu_hit_read <= 1'b0;
        if_hit_read <= 4'b0;
        
        lsu_fifo <= 64'b0;
        lsu_fifo_en <= 1'b0;

        for (i = 0; i < 4; i = i + 1) begin      //cache's "if" out to zero
            if_read_out[i] <= 64'b0;
        end

        for (i = 0; i < 21; i = i + 1) begin    //go_mem_fifo reset
            go_mem_A_adderss[i] <= 64'b0;
            go_mem_A_data[i] <= 64'b0;
            go_mem_B_adderss[i] <= 64'b0;
            go_mem_B_data[i] <= 64'b0;

            go_mem_A_pc[i] <= 5'b0;
            go_mem_B_pc[i] <= 5'b0;

            go_mem_A_pc[i] <= 1'b0;
            go_mem_B_en[i] <= 1'b0;
        end
    end

    //to "if" data's out(S-A)
    always @(*) begin
        if_hit_read <= 4'b0;    //set if_hit zero
        for (d = 0; d < 25; d = d + 8) begin             //search data's bit (four)
            for (i = 0; i < 262145; i = i + 1) begin    //saerch data's adderss
                if (
                    ((if_adderss_read + d) == inst_tag[i])&&    //search data's tag
                    (valid_bit[i])&&                            //search data is true(1)
                    (!(dirty_bit[i]))                           //search data's dirty_bit is not dirty
                ) begin                   
                    if_read_out[d/8] <= inst_mem[i];              //data to data's out
                    if_hit_read[d/8] <= 1'b1;                     //hit to win
                end
            end
            else begin                                                       //search mem's fifo
                for (i = 0; i < 21; i = i + 1) begin     
                    if ((if_adderss_read + d) == go_mem_A_adderss[i]) begin  //if data in fifo(A)
                        if_read_out[d/8] <= go_mem_A_data[i];                  //data to data's out
                        if_hit_read[d/8] <= 1'b1;                              //hit to win
                    end
                    if ((if_adderss_read + d) == go_mem_B_adderss[i]) begin  //if data in fifo(B)
                        if_read_out[d/8] <= go_mem_B_data[i];                  //data to data's out
                        if_hit_read[d/8] <= 1'b1;
                    end
                end
            end
        end
    end

    //to "if" data's in
    always @(posedge clk) begin
        if (if_write_start) begin
            for (i = 0; i < 262145; i = i + 1) begin   //saerch the data's adderss(one)
                if (
                    (if_adderss_write == inst_tag[i])&&  //search data's tag
                    (valid_bit[i])&&                     //search data is true(1)
                    (!(dirty_bit[i]))                    //search data's dirty_bit is not dirty
                ) begin
                    valid_bit[i] <= 1'b0;                //the data is found
                end
            end

            //write the data
            if (cache_pc >= 32'd262145) begin         //if cache_pc is 262145
                cache_pc <= 32'b0;                  //the cache is zero
            end
            else begin
                cache_pc <= cache_pc + 1;            //pc + 1
            end

            inst_mem[cache_pc] <= if_data_write;     //write the data
            inst_tag[cache_pc] <= if_adderss_write;  //write the adderss
            valid_bit[cache_pc] <= 1'b1;             //write the valid is true
            dirty_bit[cache_pc] <= 1'b0;             //write this is not dirty

            if (                        //to mem_fifo
                (valid_bit[cache_pc])&&              //search data is true(1)
                (!(dirty_bit[cache_pc]))             //search data's dirty_bit is not dirty
            ) begin
                if (go_mem_A_pc => 5'd21) begin      //upload go_mem pc (A)
                    go_mem_A_pc <= 5'b0;
                end
                else begin
                    if ((go_mem_A_pc == 5'b0) || (go_mem_A_en[go_mem_A_pc] == 1'b1)) begin
                        go_mem_A_pc <= go_mem_A_pc + 1;
                    end
                end
                if ((go_mem_A_pc == 5'b0) || (go_mem_A_en[go_mem_A_pc] == 1'b1)) begin
                    stop <= 1'b0;                                     //stop = false
                    go_mem_A_data[go_mem_A_pc] <= inst_mem[cache_pc];
                    go_mem_A_adderss[go_mem_A_pc] <= inst_tag[cache_pc];
                    go_mem_A_en[go_mem_A_pc] <= 1'b1;
                end
                else begin
                    stop <= 1'b1;                                     //stop = true
                end
            end
        end
    end

    //to "LSU" data's out
    always @(*) begin
        lsu_hit_read <= 1'b0;    //set lsu_hit zero
        for (i = 0; i < 262145; i = i + 1) begin
            if (
                (lsu_adderss_read == inst_tag[i])&&   //search data's tag
                (valid_bit[i])&&                      //search data is true(1)
                (!(dirty_bit[i]))                     //search data's dirty_bit is not dirty
            ) begin
                lsu_data_read <= inst_mem[i];         //data to data's out
                lsu_hit_read <= 1'b1;                 //hit to win               
            end
        end
        else begin                                                       //search mem's fifo
                for (i = 0; i < 21; i = i + 1) begin     
                    if ((lsu_adderss_read) == go_mem_A_adderss[i]) begin  //if data in fifo(A)
                        lsu_read_out <= go_mem_A_data[i];                     //data to data's out
                        lsu_hit_read <= 1'b1;                                 //hit to win
                    end
                    if ((lsu_adderss_read) == go_mem_B_adderss[i]) begin  //if data in fifo(B)
                        lsu_data_read <= go_mem_B_data[i];                    //data to data's out
                        lsu_hit_read <= 1'b1;                                 //hit to win
                    end
                end
            end
    end

    //to "LSU" data's write in
    always @(posedge clk) begin
        if (lsu_write_start) begin      //write lsu fifo
            lsu_fifo_en <= 1'b1;        //en = true
            lsu_fifo_adderss <= lsu_adderss_write;
            lsu_fifo_data <= lsu_data_write;
        end
    end

    always @(posedge (!(clk))) begin
        if (lsu_fifo_en) begin
            lsu_fifo_en <= 1'b0;        //en = flase
            for (i = 0; i < 262145; i = i + 1) begin   //saerch the data's adderss(one)
                if (
                    (lsu_adderss_write == inst_tag[i])&& //search data's tag
                    (valid_bit[i])&&                     //search data is true(1)
                    (!(dirty_bit[i]))                    //search data's dirty_bit is not dirty
                ) begin
                    valid_bit[i] <= 1'b0;                //the data is found
                end
            end

            //write the data
            if (cache_pc >= 32'd262145) begin         //if cache_pc is 262145
                cache_pc <= 32'b0;                  //the cache is zero
            end
            else begin
                cache_pc <= cache_pc + 1;            //pc + 1
            end

            inst_mem[cache_pc] <= lsu_data_write;    //write the data
            inst_tag[cache_pc] <= lsu_adderss_write; //write the adderss
            valid_bit[cache_pc] <= 1'b1;             //write the valid is true
            dirty_bit[cache_pc] <= 1'b0;             //write this is not dirty

            if (                        //to mem_fifo
                (valid_bit[cache_pc])&&              //search data is true(1)
                (!(dirty_bit[cache_pc]))             //search data's dirty_bit is not dirty
            ) begin
                if (go_mem_B_pc => 5'd21) begin      //upload go_mem pc (B)
                    go_mem_B_pc <= 5'b0;
                end
                else begin
                    if ((go_mem_B_pc == 5'b0) || (go_mem_B_en[go_mem_B_pc] == 1'b1)) begin
                        go_mem_B_pc <= go_mem_B_pc + 1;
                    end
                end
                if ((go_mem_B_pc == 5'b0) || (go_mem_B_en[go_mem_B_pc] == 1'b1)) begin
                    stop <= 1'b0;                                     //stop = false
                    go_mem_B_data[go_mem_B_pc] <= inst_mem[cache_pc];
                    go_mem_B_adderss[go_mem_B_pc] <= inst_tag[cache_pc];
                    go_mem_B_en[go_mem_B_pc] <= 1'b1;
                end
                else begin
                    stop <= 1'b1;   //stop = true
                end
            end
        end
    end

    //to mem fifo's data out
    always @(posedge clk) begin
        if (!(read_stop_en)) begin
            go_mem_mux <= ~go_mem_mux;
            mem_start_write <= 1'b0;
            for (i = 0; i < 21; i = i + 1) begin
                if (go_mem_mux) begin
                    if (go_mem_A_en[i]) begin
                        go_mem_A_en[i] <= 1'b0;
                        mem_start_write <= 1'b1;
                        mem_adderss_write <= go_mem_A_adderss[i];
                        mem_data_write <= go_mem_A_data[i];
                        i <= 22;    //stop
                    end
                end
                else begin
                    if (go_mem_B_en[i]) begin
                        go_mem_B_en[i] <= 1'b0;
                        mem_start_write <= 1'b1;
                        mem_adderss_write <= go_mem_B_adderss[i];
                        mem_data_write <= go_mem_B_data[i];
                        i <= 22;    //stop
                    end
                end
            end
        end
    end

endmodule