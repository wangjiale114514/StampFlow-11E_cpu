//I_cache缓存
//64 KB / 核
//高带宽、低延迟，支持非阻塞访问
//带指令位宽标签页和正常指令缓存的内容
//配置缓存加法器加物理数值填入

//缓存设计，一个缓存加法器，每次访问新建一个地址存储虚拟映射被访问的数据保持数据常新、指令缓存是常新且关注二缓的，如果二缓某个数据被改写了就标记脏数据并改写

//缓存得标签数据由取指阶段查找

//二缓是随时跟随一级数据缓存的
module I_cache (
    input wire clk,    //时钟信号
    input wire reset,  //复位

    //面向cpu
    input wire [63:0] address,    //内存寻址
    output reg [255:0] out,       //缓存输出   
    output reg [255:0] tag_out,   //指令长度标签输出
    output reg [3:0] cache_hit,   //命中标识,分别代表输出得四位缓存行是否为可用行,输出1代表命中，否则未命中

    //面向if的解码指令长度
    input wire [255:0] init_tag_in,//解码器填写tag内容(4位)
    input wire [63:0] init_tag,    //填写得tag得tag(地址)（代表4位）
    input wire init_tag_start,     //tag写入得势能

    //面向缓存,监控D_cache，如果发现就立即写入到自身标记为脏数据
    input wire [63:0] cache_address, //内存寻址
    input wire [63:0] write,         //写入内容
    input wire write_start,          //写入势能

    //面向L2缓存和后续缓存
    input wire cache_read_start, //cpu未命中读取请求势能
    input wire [63:0] cache_read,//需要存入得tag
    input wire [63:0] cache_in,  //未命中接收下层命中信息
    input wire cache_in_start,   //下层命中上传势能

    //系统输出
    output wire [31:0] cache_pc  //cache分配pc，-1为上一次写入的内容
);

    //面向cpu寻址得逻辑
    integer i;    //循环比对次数
    integer d;    //寻址位宽8x4，每条指令最长位宽8个字，所以寻址4次,寻址偏移量

    reg [129:0] mem [0:8191];   //数据存储    高64位tag，低64位DATA，数据按偏移算,最后一位是脏数据标记,最高位129位为无效位，拉高1为有效
    reg [63:0] tag [0:8191];    //指令标记标签

    //复位
    always @(posedge reset) begin
        cache_pc <= 32'b0;    //pc
        out <= 256'b0;        //out
        tag_out <= 256'b0;    //tag
        cache_hit <= 4'b0;    //hit

        for (i = 0; i < 8192; i = i + 1) begin
            mem[i] <= 130'b0;    //所有缓存归零
            tag[i] <= 64'b0;     //所有tag归零
        end
    end

    always @(*) begin     //面向cpu的寻址
        //输出逻辑
        cache_hit = 4'b0;
        for (d = 0; d < 4; d = d + 1) begin
            for (i = 0; i < 8192; i = i + 1) begin
                if (mem[i][128:65] == (address + d)) begin    //判断内容输出
                    if ((mem[i][0] == 1'b0) && (mem[i][129] == 1'b1)) begin                 //判断内容是为脏数据
                        out[((d * 64)+ 63) : (d * 64)] <= mem[i][64:1];        //指令输出
                        tag_out[((d * 64)+ 63) : (d * 64)] <= tag[i];          //指令标签输出
                        cache_hit[d] = 1'b1;                                   //填写命中标签
                    end 
                end
            end
        end
    end

    //init_tag被写入处理
    always @(posedge init_tag_start) begin
        for (i = 0; i < 8192; i = i + 1) begin
            if ((mem[i][128:65] == init_tag) && (mem[i][129] == 1'b1)) begin    //第一条写入
                tag[i] <= init_tag_in[63:0];
            end

            if ((mem[i][128:65] == (init_tag + 1'b1)) && (mem[i][129] == 1'b1)) begin  //第二条写入
                tag[i] <= init_tag_in[127:64];
            end

            if ((mem[i][128:65] == (init_tag + 1'b10)) && (mem[i][129] == 1'b1)) begin  //第三条写入
                tag[i] <= init_tag_in[191:128];
            end

            if ((mem[i][128:65] == (init_tag + 1'b11)) && (mem[i][129] == 1'b1)) begin  //第四条写入
                tag[i] <= init_tag_in[255:192];
            end
        end
    end

    //面向D_cache得监控写入内容
    always @(posedge write_start) begin
        for (i = 0; i < 8192; i = i + 1) begin
            if ((mem[i][128:65] == cache_address) && (mem[i][129] == 1'b1)) begin
                mem[i][0] <= 1'b1;                      //挂脏数据，代表该数值已被改变 
            end
        end
    end

    //面向L2缓存和后续缓存
    always @(posedge cache_in_start) begin
        if (cache_read_start) begin
            for (i = 0; i < 8192; i = i + 1) begin
                if ((mem[i][128:65] == cache_read) && (mem[i][129] == 1'b1)) begin
                    mem[i][129] <= 1'b0;                                            //去除旧数据的有效标记
                end
            end
        
        mem[cache_pc][128:64] <= cache_read;    //写入新tag
        mem[cache_pc][64:1] <= cache_in;        //写入新数据
        mem[cache_pc][129] <= 1'b1;             //写入新数据有效
        mem[cache_pc][0] <= 1'b0;               //写入数据非脏数据
        cache_pc <= cache_pc + 1;               //cache_pc+1
        end
    end

    always @(*) begin                         //限制缓存pc行数
        if (cache_pc >= 32'd8192) begin
            cache_pc = 32'b0;                 //超过这个数归零
        end
    end
    
endmodule