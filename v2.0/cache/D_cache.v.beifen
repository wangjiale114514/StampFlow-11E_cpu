//D_cache
//64 KB / 核
//高带宽、低延迟，支持非阻塞访问
//缓存行数据宽度为64位，实际地址是缓存行位置-1x8+偏移量
module D_cache (
    input wire clk,              //时钟信号
    input wire reset,            //复位

    //面向cpu
    input wire [63:0] address,   //内存寻址
    output reg [63:0] out,       //缓存输出

    input wire [63:0] write,     //写入内容
    input wire write_start,      //写入势能

    output reg cache_hit,        //命中标识

    //面向L2缓存
    input reg cache_miss,            // miss后向后拉取请求的势能（监听势能）
    input wire [63:0] cache_in,      //未命中接收下层命中信息
    input wire [63:0] cache_address, //该写入的内容的tag
    input wire cache_in_start,       //下层命中上传势能

    //系统输出
    output wire [31:0] cache_pc  //cache分配pc
);

    integer i;                  //循环比对次数
    reg [129:0] mem [0:8191];   //数据存储    高64位tag，低64位DATA，数据按偏移算,最后一位是脏数据标记,最高位129位为无效位，拉高1为有效  

    //处理复位
    always @(posedge reset) begin
        cache_pc <= 32'b0;                 //pc值归零
        out <= 64'b0;                      //out归零
        cache_hit <= 1'b0;                 //命中标识归零

        for (i = 0; i < 8192; i = i + 1) begin
            mem[i] <= 130'b0;                  //全部归零
        end
    end

    //面向于cpu寻址的输出
    always @(*) begin
        cache_hit = 1'b0;                                                  //初始化为未命中
        for (i = 0; i < 8192; i = i + 1) begin
            if (mem[i][128:65] == address) begin                           //判断tag
                if ((mem[i][0] == 1'b0) && (mem[i][129] == 1'b1)) begin    //判断脏数据以及有效数据
                    out <= mem[i][64:1];                                   //赋值
                    cache_hit <= 1'b1;                                     //表示命中
                end 
            end
        end
    end

    //面向与cpu的写入
    always @(posedge write_start) begin
        for (i = 0; i < 8192; i = i + 1) begin
            if (mem[i][128:65] == address) begin    //寻址到内容
                mem[i][129] <= 1'b0;                //去除旧数据的有效标记
            end
        end

        mem[cache_pc][128:64] <= address;           //写入新的tag
        mem[cache_pc][64:1] <= write;               //写入新数据
        mem[cache_pc][129] <= 1'b1;                 //写入新数据有效
        mem[cache_pc][0] <= 1'b0;                   //写入数据非脏数据
        cache_pc <= cache_pc + 1;                   //cache_pc+1
    end

    //面向L2缓存
    always @(posedge cache_in_start) begin
        for (i = 0; i < 8192; i = i + 1) begin
            if (mem[i][128:65] == cache_address) begin //寻址到内容
                mem[i][129] <= 1'b0;                   //去除旧数据的有效标记
            end
        end
        
        mem[cache_pc][128:64] <= cache_address;     //写入新的tag
        mem[cache_pc][64:1] <= cache_in;            //写入新数据
        mem[cache_pc][129] <= 1'b1;                 //写入新数据有效
        mem[cache_pc][0] <= 1'b0;                   //写入数据非脏数据
        cache_pc <= cache_pc + 1;                   //cache_pc+1
    end

    always @(*) begin                         //限制缓存pc行数
        if (cache_pc >= 32'd8192) begin
            cache_pc = 32'b0;                 //超过这个数归零
        end
    end
    
endmodule