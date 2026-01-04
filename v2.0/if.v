//先向I_cache请求内容，若输出未命中请求L2_cache
//在读inst的时候如果全空读主存的时候要广播读势能，因为要对LSU和写缓冲进行暂停处理
//在访问主存的时候遵循inst优先，LSU在后，写缓冲
//在把命令写入I_cache的时候一定要保证是顺序de(1>2>3>4)
//在设计id_cache时剩余容量不足8条的时候输出爆满通知，停止向id_fifo提供内容
//if阶段要向id_fifo输出pc内容方便定位分支指令位置
//if阶段要向bp发送内容获取分支预测结果（指令分割输出内容和下一条pc偏移量）
module if (
    input wire clk,
    input wire reset,

    //面向I_cache的取指(1)
    output reg [63:0] i_cache_adderss_read,    //search inst's adderss in I_cache
    input wire [255:0] i_cache_data_read,      //inst
    input wire [255:0] i_cache_tag_read,       //tag(inst's long)(暂时用不到)
    input wire [3:0] i_cache_hit_read,         //I_cache's hit bit

    //面向I_cache的写入
    output wire [255:0] i_cache_adderss_write, //data's adderss write I_cache 
    output wire [255:0] i_cache_data_write,    //data's data write I_cache
    output wire [255:0] i_cache_tag_write,     //inst's tag write I_cache(暂时用不到)
    output reg [3:0] i_cache_start,            //I_cache write's enable

    //面向L2_cache的取指(2)
    output reg [63:0] cache_adderss_read,      //search inst's adderss in L2_cache
    input wire [255:0] cache_data_read,        //read inst's data in L2_cache
    input wire [3:0] cache_hit_read,           //read inst's hit bit in L2_cache

    //面向L2_cache的写入
    output reg [63:0] cache_adderss_write,     //write L2_cache's adderss
    output reg [63:0] cache_data_write,        //write L2_cache's data
    output reg cache_start,                    //write L2_cache's enable

    //面向主存的取指(3)
    output reg write_stop,                     //stop write_fifo's enable
    output reg [63:0] mem_adderss_read,        //search inst's data in mem
    input reg [63:0] mem_data_read,            //read inst's data in mem

    //面向id的输出(输出8个指令到id的fifo等待执行（指令宽度不定）一定要按顺序)
    output wire [511:0] id_fifo_data,       //out to id's fifo data     
    output reg [7:0] id_fifo_en,            //out to id's enable(data's)
    input wire id_fifo_stop,                //to id's stop enable(inst is full)
    output wire [7:0] inst_bp,              //输入分支预测结果，8位代表8个指令，1为跳转，0为不跳转
    output wire [511:0] id_fifo_adderss,    //写入id FIFO 的指令地址（作为后端唯一标识）

    //面向分支预测
    output wire [255:0] bp_adderss,         //out to bp adderss
    output wire [255:0] bp_data,            //out to bp data
    input wire [63:0] bp_next_pc,           //in to bp's next pc (偏移)
    input wire [7:0] bp_inst_seg,           //in to bp's Instruction Segmentation out
    input wire [7:0] bp_if,                 //bp哪部分跳转哪部分不跳转（1为跳转，0为不跳转）

    //面向jump单元
    input wire jump_start,                   //回溯势能
    input wire [63:0] jump_adderss,          //回溯地址
    
    //系统输入暂停流水线势能
    input wire stop                         //stop's enable
);

    //定义循环变量
    integer i;
    integer d;
    integer g;

    //pc_adder
    reg [63:0] pc;               //pc_adder(search inst)
    //next_pc
    wire [63:0] next_pc;
    assign next_pc = bp_next_pc;  //下一个地址的偏移（正常是pc + 64'd32）
    

    //if_en
    reg [2:0] if_en;             //control "if" search cache
    //if_en = 000 is search I_cache   //
    //if_en = 001 is search L2_cache  //
    //if_en = 010 is search mem       //
    reg [64:0] miss_data [3:0];       //miss data's adderss(search miss's data)
    //I_cache miss is search miss_data[0]'s data                 //
    //L2_cache miss is search {miss_data[i][64] == 1'b1}'s data  //

    //miss data's fifo
    reg [63:0] data_fifo_adderss [3:0];    //store adderss
    reg [63:0] data_fifo_data [3:0];       //store data
    reg data_fifo_en[3:0];                 //store enable

    //拼接器
    //省略
    //rv32i

    //分支预测
    //bp_adderss's out
    assign bp_adderss[63:0] = (pc + 0);
    assign bp_adderss[127:64] = (pc + 8);
    assign bp_adderss[191:128] = (pc + 16);
    assign bp_adderss[255:192] = (pc + 24);
    //bp_data's out
    assign bp_data = (if_en == 3'b000) ? i_cache_data_read : cache_data_read;    //search bp's data out
    //bp分支情况输出
    assign inst_bp = bp_if;
    
    //分线 
    //i_cache_data_read
    wire [63:0] i_data_read [0:3];    //I_cache's out (four) data
    assign i_data_read[0] = i_cache_data_read[63:0];    //1
    assign i_data_read[1] = i_cache_data_read[127:64];  //2
    assign i_data_read[2] = i_cache_data_read[191:128]; //3
    assign i_data_read[3] = i_cache_data_read[255:192]; //4

    //i_cache_adderss_write
    reg [63:0] i_adderss_write [0:3]; //I_cache's in (four) adderss
    assign i_cache_adderss_write[63:0] = i_adderss_write[0];    //1
    assign i_cache_adderss_write[127:64] = i_adderss_write[1];  //2
    assign i_cache_adderss_write[191:128] = i_adderss_write[2]; //3
    assign i_cache_adderss_write[255:192] = i_adderss_write[3]; //4

    //i_cache_data_write
    reg [63:0] i_data_write [0:3];    //I_cache's in (four) data
    assign i_cache_data_write[63:0] = i_data_write[0];    //1
    assign i_cache_data_write[127:64] = i_data_write[1];  //2
    assign i_cache_data_write[191:128] = i_data_write[2]; //3
    assign i_cache_data_write[255:192] = i_data_write[3]; //4

    //cache_data_read
    wire [63:0] cache_read [0:3];     //L2_cache's read
    assign cache_read[0] = cache_data_read[63:0];    //1
    assign cache_read[1] = cache_data_read[127:64];  //2
    assign cache_read[2] = cache_data_read[191:128]; //3
    assign cache_read[3] = cache_data_read[255:192]; //4

    //id_fifo(id_fifo_data)out
    reg [63:0] id_fifo [7:0];         //to id_fifo's out(8)
    assign id_fifo_data[63:0] = id_fifo[0];    //1
    assign id_fifo_data[127:64] = id_fifo[1];  //2
    assign id_fifo_data[191:128] = id_fifo[2]; //3
    assign id_fifo_data[255:192] = id_fifo[3]; //4
    assign id_fifo_data[319:256] = id_fifo[4]; //5
    assign id_fifo_data[383:320] = id_fifo[5]; //6
    assign id_fifo_data[447:384] = id_fifo[6]; //7
    assign id_fifo_data[511:448] = id_fifo[7]; //8

    //id_fifo(id_fifo_adderss)out
    assign id_fifo_adderss[63:0] = (pc + 0);     //1
    assign id_fifo_adderss[127:64] = (pc + 4);   //2
    assign id_fifo_adderss[191:128] = (pc + 8);  //3
    assign id_fifo_adderss[255:192] = (pc + 12); //4
    assign id_fifo_adderss[319:256] = (pc + 16); //5
    assign id_fifo_adderss[383:320] = (pc + 20); //6
    assign id_fifo_adderss[447:384] = (pc + 24); //7
    assign id_fifo_adderss[511:448] = (pc + 28); //8

    //执行逻辑
    //reset
    always @(posedge reset) begin
        i_cache_adderss_read <= 64'b0;    //one
        i_cache_start <= 4'b0;
        cache_adderss_read <= 64'b0;
        cache_adderss_write <= 64'b0;
        cache_data_write <= 64'b0;
        cache_start <= 1'b0;
        pc <= 64'b0;

        if_en <= 3'b0;

        for (i = 0; i < 4; i = i + 1) begin    //four 
            i_data_read[i] <= 64'b0;
            i_adderss_write[i] <= 64'b0;
            i_data_write[i] <= 64'b0;
            cache_read[i] <= 64'b0; 
        end

        for (i = 0; i < 8; i = i + 1) begin    //eight
            id_fifo[i] <= 64'b0;
        end
    end

    //回溯
    always @(posedge clk) begin
        if (jump_start) begin
            pc <= jump_adderss;     //先回溯后一个tick清理id_fifo和rob一起
        end
    end

    //if
    //I_cache's search
    always @(posedge clk) begin       //search I_cache
        if (!stop) begin              //not stop
            if (id_fifo_stop == 1'b0) begin   //if id_fifo is not full
                id_fifo_en <= 8'b0;           //reset id_fifo's in enable
                if (if_en == 3'b000) begin    //if I_cache not search
                    i_cache_adderss_read <= pc;    //search the pc's adderss
                    if (i_cache_hit_read == 4'b1111) begin   //verify hit bit
                        for (i = 0; i < 8; i = i + 1) begin
                            if (i % 2) begin              //split inst
                                id_fifo[i] <= i_data_read[(i - 1) / 2][63:32];    //top
                            end
                            else begin                    //if inst's split is down
                                id_fifo[i] <= i_data_read[i / 2][31:0];           //down
                            end
                        end
                        id_fifo_en <= bp_inst_seg;    //top the id_fifo's in enable
                        pc = pc + next_pc;            //pc
                    end
                    else begin                        //I_cache is miss
                        if_en <= 3'b001;              //next clk search L2_cache
                        miss_data[0][64] <= 1'b1;     //set miss_data's Valid Bit is true
                        miss_data[0][63:0] <= pc;     //next clk search L2_cache's adderss
                    end
                end
            end
        end
    end

    //L2_cache's search
    always @(posedge clk) begin
        if (!stop) begin                       //not stop
            if (id_fifo_stop == 1'b0) begin    //if id_fifo is not full
                if (if_en == 3'b001) begin     //if L2_cache not search
                    cache_adderss_read <= pc;  //search the pc's adderss
                    if (cache_hit_read == 4'b1111) begin   //verify hit bit
                        for (i = 0; i < 8; i = i + 1) begin
                            if (i % 2) begin              //split inst
                                id_fifo[i] <= cache_read[(i - 1) / 2][63:32];    //top
                            end
                            else begin                    //if inst's split is down
                                id_fifo[i] <= cache_read[i / 2][31:0];           //down
                            end
                        end
                        id_fifo_en <= bp_inst_seg;    //top the id_fifo's in enable
                        pc = pc + next_pc;             //pc
                        if_en = 3'b000;               //next clk search I_cache
                        //把内容存到I_cache里面(i_adderss_write)
                        for (i = 0; i < 4; i = i + 1) begin
                            i_adderss_write[i] <= (pc + (i*8));           //to write I_cache's adderss
                            i_cache_data_write[i] <= cache_read[i*8];   //to write I_cache's data
                        end

                    end
                    else begin
                        for (i = 0; i < 25; i = i + 8) begin       //next clk search mem
                            if (cache_hit_read[i/8] == 1'b0) begin //not adderss in 
                                miss_data[i/8][63:0] <= (pc + i);  //mem search data
                                miss_data[i/8][64] <= 1'b1;        //search's enable is top
                            end
                            else begin
                                miss_data[i/8][64] <= 1'b0;        //search's enable is down(don't search)
                            end
                        end

                        if_en = 3'b010;                          //next clk search mem's data
                        write_stop = 1'b1;                       //如果出现错误先删除这个语句试试，这是暂停势能
                    end
                end
            end
        end
    end

    //mem's search(old)
/*
    always @(posedge clk) begin
        write_stop = 1'b0;                     //not stop L2_cache's write fifo
        cache_start = 1'b0;                    //reset L2_cache enable
        if (!stop) begin                       //not stop
            if (id_fifo_stop == 1'b0) begin    //if id_fifo is not full
                if (if_en == 3'b010) begin     //if L2_cache not search
                    if (                       //if not search miss's data
                        (miss_data[0][64])||
                        (miss_data[1][64])||
                        (miss_data[2][64])||
                        (miss_data[3][64])
                    ) begin
                        for (i = 0; i < 4; i = i + 1) begin
                            if ((miss_data[i][64])) begin
                                i = 5;                //stop loop
                                write_stop = 1'b1;    //stop write fifo
                                miss_data[i][64] = 1'b0;    //kill enable
                                mem_adderss_read = miss_data[i][63:0];    //search mem's adderss
                                data_fifo_adderss[i] = miss_data[i][63:0];//store mem's out adderss
                                data_fifo_data[i] = mem_data_read;        //store mem's out data
                                data_fifo_en[i] = 1'b1;                   //store mem's data's enable
                                //L2_cache
                                cache_adderss_write = miss_data[i][63:0]; //L2_cache write adderss
                                cache_data_write = mem_data_read;         //L2_cache write data
                                cache_start = 1'b1;                       //L2_cache enable top
                            end
                            else begin
                                data_fifo_en[i] = 1'b0;
                            end
                        end
                    end
                    else begin
                        if_en == 3'b001;    //search L2_cache
                    end
                end
            end
        end
        
    end
*/

    //mem's search
    always @(posedge clk) begin
        cache_start = 1'b0;                    //reset L2_cache enable
        if (!stop) begin                       //not stop 
            if (id_fifo_stop == 1'b0) begin    //if id_fifo is not full
                if (if_en == 3'b010) begin     //if L2_cache not search
                    if (                       //if not search miss's data
                        (miss_data[0][64])||
                        (miss_data[1][64])||
                        (miss_data[2][64])||
                        (miss_data[3][64])
                    ) begin
                        if (                    //do they is search mem's adderss
                            ((miss_data[0][63:0] == mem_adderss_read) && (miss_data[0][64]))||
                            ((miss_data[1][63:0] == mem_adderss_read) && (miss_data[1][64]))||
                            ((miss_data[2][63:0] == mem_adderss_read) && (miss_data[2][64]))||
                            ((miss_data[3][63:0] == mem_adderss_read) && (miss_data[3][64]))
                        ) begin                 //if yes
                            for (i = 0; i < 4; i = i + 1) begin
                                if (miss_data[i][63:0] == mem_adderss_read) begin  //search that miss bit
                                    i = i + 4;                                     //stop fifo
                                    miss_data[i][64] = 1'b0;                       //kill enable   
                                    write_stop = 1'b0;                             //not stop L2_cache's write fifo
                                    data_fifo_adderss[i] = miss_data[i][63:0];     //store mem's out adderss 
                                    data_fifo_data[i] = mem_data_read;             //store mem's out data
                                    data_fifo_en[i] = 1'b1;                        //store mem's data's enable
                                    //L2_cache
                                    cache_start = 1'b1;                            //L2_cache enable top
                                    cache_data_write = mem_data_read;              //L2_cache write data
                                    cache_adderss_write = miss_data[i][63:0];      //L2_cache write adderss
                                end
                            end
                        end
                        else begin
                            write_stop = 1'b1;                        //stop write fifo
                            for (i = 0; i < 4; i = i + 1) begin
                                if (miss_data[i][64]) begin
                                    i = i + 4;                                //stop fifo
                                    mem_adderss_read = miss_data[i][63:0];    //search mem's adderss
                                end
                            end
                        end
                    end
                    else begin
                        if_en == 3'b001;    //search L2_cache
                    end
                end
            end
        end
    end
    
endmodule