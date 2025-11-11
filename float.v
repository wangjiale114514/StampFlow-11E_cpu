//浮点数处理库
//测试用
//0001加法
//0010乘法
//0011除法
//0100整数转浮点数
//0101浮点数转整数
//0110判断大于
//0111判断小于
//1000判断不等于
//1001判断等于
module float (
    input wire [3:0] o,    //符号位（+，—，*，/,整数化浮点，浮点化整数)
    input wire [31:0] a,    //数值a
    input wire [31:0] b,    //数值b
    output wire [31:0] c    //结果c

);
    integer i;

    //加法
    reg [63:0] add_a_wei;      //加法a尾数
    reg [7:0] add_a_jie_z;     //加法a阶码逻辑正
    reg [7:0] add_a_jie_f;     //加法a阶码逻辑负
 
    reg [63:0] add_b_wei;      //加法b尾数
    reg [7:0] add_b_jie_z;     //加法b阶码逻辑正
    reg [7:0] add_b_jie_f;     //加法a阶码逻辑负

    reg [63:0] add_c_wei;      //未规格化的结果位
    reg [7:0] add_c_jie;       //未规格化的阶码
    
    reg [31:0] add_c;          //结果位打包
    
    always @(*) begin //对齐阶码数值（浮点数加法）
        add_a_wei[31:9] = a[22:0];    //a位初始化尾数展开
        add_a_wei[8:0] = 9'b0;
        add_a_wei[32] = 1'b1;
        add_a_wei[63:33] = 31'b0;

        if (a[30:23] > 8'b01111111) begin         //a位真实阶码计算
            add_a_jie_z = a[30:23] - 8'b01111111;
            add_a_jie_f = 8'b0;
        end
        else begin
            if (a[30:23] < 8'b01111111) begin
                add_a_jie_f = 8'b01111111 - a[30:23];
                add_a_jie_z = 8'b0;
            end
            else begin
                add_a_jie_z = 8'b0;
                add_a_jie_f = 8'b0;
            end
        end

        add_b_wei[31:9] = b[22:0];    //b位初始化尾数展开
        add_b_wei[8:0] = 9'b0;
        add_b_wei[32] = 1'b1;
        add_b_wei[63:33] = 31'b0;

        if (b[30:23] > 8'b01111111) begin         //b位真实阶码计算
            add_b_jie_z = b[30:23] - 8'b01111111;
            add_b_jie_f = 8'b0;
        end
        else begin
            if (b[30:23] < 8'b01111111) begin
                add_b_jie_f = 8'b01111111 - b[30:23];
                add_b_jie_z = 8'b0;
            end
            else begin
                add_b_jie_z = 8'b0;
                add_b_jie_f = 8'b0;
            end
        end

        //判断阶码谁大谁小然后对阶
        if (a[30:23] > b[30:23]) begin        //a大b小
            add_b_wei = add_b_wei >> (a[30:23] - b[30:23]);
            add_c_jie = a[30:23];
        end

        if (a[30:23] < b[30:23]) begin        //a小b大
            add_a_wei = add_a_wei >> (b[30:23] - a[30:23]);
            add_c_jie = b[30:23];                           //赋值未规格化的阶码
        end
        
        //计算部分，同号相加，异号相减
        if (a[31] == b[31]) begin    //符号相等,相加
            add_c_wei = add_a_wei + add_b_wei;
            add_c[31] = a[31];
        end

        if ((a[31] != b[31]) && (add_a_wei > add_b_wei)) begin  //符号不同大的减小的,取绝对值大的符号
            add_c_wei = add_a_wei - add_b_wei;
            add_c[31] = a[31];
        end

        if ((a[31] != b[31]) && (add_a_wei < add_b_wei)) begin  //符号不同，大的减小的，符号取绝对值大的
            add_c_wei = add_b_wei - add_a_wei;
            add_c[31] = b[31];
        end

        if ((a[31] != b[31]) && (add_a_wei == add_b_wei)) begin  //如果相等则为0，符号位随意
            add_c_wei = 64'b0;
            add_c[31] = b[31];
        end

        //规格化
        if (add_c_wei == 64'b0) begin                            //如果结果为0就输出0
            add_c = 32'b0;
        end

        if (add_c_wei[63:32] == 32'b00000000000000000000000000000000) begin    //如果整数位全是0
            for (i = 0; i < 32; i = i + 1) begin
                add_c_wei = add_c_wei << 1;                                    //向左移
                add_c_jie = add_c_jie - 1'b1;                                  //阶码-1
                if (add_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
                    i = 32;                                                    //如果得到了整数个位是1的话就退出循环
                end
            end
        end

        if (add_c_wei[63:32] > 32'b00000000000000000000000000000001) begin    //如果整数位有东西
            for (i = 0; i < 32; i = i + 1) begin
                add_c_wei = add_c_wei >> 1;                                   //向右移
                add_c_jie = add_c_jie + 1'b1;                                 //阶码+1
                if (add_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
                    i = 32;                                                   //如果得到了整数个位是1的话就退出循环
                end
            end
        end

        if (add_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
            add_c[22:0] = add_c_wei[31:9];                                    //去掉整数位1，舍去9后面的位数
            add_c[30:23] = add_c_jie;                                         //上传阶码
        end
    end

    //乘法MULT
    reg [63:0] mult_a_wei;       //乘法a尾数
    reg [63:0] mult_b_wei;       //乘法b尾数

    reg [63:0] mult_c_wei;       //未规格化的结果位
    reg [7:0] mult_c_jie;         //未规格化的阶码

    reg [31:0] mult_c;          //结果位打包

    always @(*) begin
        mult_a_wei[31:9] = a[22:0];    //初始化a位尾数展开
        mult_a_wei[8:0] = 9'b0;
        mult_a_wei[32] = 1'b1;
        mult_a_wei[63:33] = 31'b0;

        mult_b_wei[31:9] = b[22:0];    //初始化b位尾数展开
        mult_b_wei[8:0] = 9'b0;
        mult_b_wei[32] = 1'b1;
        mult_b_wei[63:33] = 31'b0;

        //阶码求和
        mult_c_jie = a[30:23] + b[30:23] - 8'b01111111;

        //尾数相乘
        mult_c_wei[63:9] = mult_a_wei[63:9] * mult_b_wei[63:9];   //相乘

        //符号位
        mult_c[31] = a[31] ^ b[31];             //获取符号位

        //规格化
        if (mult_c_wei == 64'b0) begin                            //如果结果为0就输出0
            mult_c_wei = 32'b0;
        end

        if (mult_c_wei[63:32] == 32'b00000000000000000000000000000000) begin    //如果整数位全是0
            for (i = 0; i < 32; i = i + 1) begin
                mult_c_wei = mult_c_wei << 1;                                    //向左移
                mult_c_jie = mult_c_jie - 1'b1;                                  //阶码-1
                if (mult_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
                    i = 32;                                                    //如果得到了整数个位是1的话就退出循环
                end
            end
        end

        if (mult_c_wei[63:32] > 32'b00000000000000000000000000000001) begin    //如果整数位有东西
            for (i = 0; i < 32; i = i + 1) begin
                mult_c_wei = mult_c_wei >> 1;                                   //向右移
                mult_c_jie = mult_c_jie + 1'b1;                                 //阶码+1
                if (mult_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
                    i = 32;                                                   //如果得到了整数个位是1的话就退出循环
                end
            end
        end

        if (mult_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
            mult_c[22:0] = mult_c_wei[31:9];                                    //去掉整数位1，舍去9后面的位数
            mult_c[30:23] = mult_c_jie;                                         //上传阶码
        end
    end

    //除法FDIV
    reg [63:0] FDIV_a_wei;       //除法a尾数
    reg [63:0] FDIV_b_wei;       //除法b尾数

    reg [63:0] FDIV_c_wei;       //未规格化的结果位
    reg [7:0] FDIV_c_jie;         //未规格化的阶码

    reg [31:0] FDIV_c;          //结果位打包

    always @(*) begin
        FDIV_a_wei[31:9] = a[22:0];    //初始化a位尾数展开
        FDIV_a_wei[8:0] = 9'b0;
        FDIV_a_wei[32] = 1'b1;
        FDIV_a_wei[63:33] = 31'b0;

        FDIV_b_wei[31:9] = b[22:0];    //初始化b位尾数展开
        FDIV_b_wei[8:0] = 9'b0;
        FDIV_b_wei[32] = 1'b1;
        FDIV_b_wei[63:33] = 31'b0;

        //阶码求和
        FDIV_c_jie = 8'b01111111 + a[30:23] - b[30:23];

        //尾数相乘
        FDIV_c_wei[63:9] = FDIV_a_wei[63:9] / FDIV_b_wei[63:9];   //相乘

        //符号位
        FDIV_c[31] = a[31] ^ b[31];             //获取符号位

        //规格化
        if (FDIV_c_wei == 64'b0) begin                            //如果结果为0就输出0
            FDIV_c_wei = 32'b0;
        end

        if (FDIV_c_wei[63:32] == 32'b00000000000000000000000000000000) begin    //如果整数位全是0
            for (i = 0; i < 32; i = i + 1) begin
                FDIV_c_wei = FDIV_c_wei << 1;                                    //向左移
                FDIV_c_jie = FDIV_c_jie - 1'b1;                                  //阶码-1
                if (FDIV_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
                    i = 32;                                                    //如果得到了整数个位是1的话就退出循环
                end
            end
        end

        if (FDIV_c_wei[63:32] > 32'b00000000000000000000000000000001) begin    //如果整数位有东西
            for (i = 0; i < 32; i = i + 1) begin
                FDIV_c_wei = FDIV_c_wei >> 1;                                   //向右移
                FDIV_c_jie = FDIV_c_jie + 1'b1;                                 //阶码+1
                if (FDIV_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
                    i = 32;                                                   //如果得到了整数个位是1的话就退出循环
                end
            end
        end

        if (FDIV_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
            FDIV_c[22:0] = FDIV_c_wei[31:9];                                    //去掉整数位1，舍去9后面的位数
            FDIV_c[30:23] = FDIV_c_jie;                                         //上传阶码
        end
    end

    //整数转浮点数 ITF
 
    reg [63:0] ITF_c_wei;       //未规格化的结果位
    reg [7:0] ITF_c_jie;         //未规格化的阶码

    reg [31:0] ITF_c;          //结果位打包

    always @(*) begin
        ITF_c_wei[63:32] = a;        //初始化
        ITF_c_wei[31:0] = 32'b0;

        ITF_c_jie = 8'b01111111;     //初始化阶码

        ITF_c[31] = 1'b1;            //初始化符号位

        //规格化
        if (ITF_c_wei == 64'b0) begin                            //如果结果为0就输出0
            ITF_c_wei = 32'b0;
        end

        if (ITF_c_wei[63:32] == 32'b00000000000000000000000000000000) begin    //如果整数位全是0
            for (i = 0; i < 32; i = i + 1) begin
                ITF_c_wei = ITF_c_wei << 1;                                    //向左移
                ITF_c_jie = ITF_c_jie - 1'b1;                                  //阶码-1
                if (ITF_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
                    i = 32;                                                    //如果得到了整数个位是1的话就退出循环
                end
            end
        end

        if (ITF_c_wei[63:32] > 32'b00000000000000000000000000000001) begin    //如果整数位有东西
            for (i = 0; i < 32; i = i + 1) begin
                ITF_c_wei = ITF_c_wei >> 1;                                   //向右移
                ITF_c_jie = ITF_c_jie + 1'b1;                                 //阶码+1
                if (ITF_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
                    i = 32;                                                   //如果得到了整数个位是1的话就退出循环
                end
            end
        end

        if (ITF_c_wei[63:32] == 32'b00000000000000000000000000000001) begin
            ITF_c[22:0] = ITF_c_wei[31:9];                                    //去掉整数位1，舍去9后面的位数
            ITF_c[30:23] = ITF_c_jie;                                         //上传阶码
        end
    end

    //浮点数转整数    FTI
    reg [63:0] FTI_a_wei;       //浮点数a尾数
    reg [31:0] FTI_c;            //结果位打包

    always @(*) begin
        FTI_a_wei[31:9] = a[22:0];    //初始化a位尾数展开
        FTI_a_wei[8:0] = 9'b0;
        FTI_a_wei[32] = 1'b1;
        FTI_a_wei[63:33] = 31'b0;

        if (a[30:23] < 8'b01111111) begin                         //如果这个数的阶码是负数就右移
            FTI_a_wei = FTI_a_wei >> (8'b01111111 - a[30:23]);    //位移相对应的位数
            FTI_c = FTI_a_wei[63:32];                             //结果位赋值
        end

        if (a[30:23] > 8'b01111111) begin                         //如果这个数的阶码是正数就左移
            FTI_a_wei = FTI_a_wei << (a[30:23] - 8'b01111111);    //位移相对应的位数
            FTI_c = FTI_a_wei[63:32];                             //结果位赋值
        end

        if (a[30:23] == 8'b01111111) begin                        //如果这个数的阶码是8'b01111111就不用移动
            FTI_c = FTI_a_wei[63:32];                             //结果位直接赋值
        end
    end

    //浮点数a比b
    //FUCK 比较>*
    //FKCU 比较<（比较结果会存到rd寄存器(全部为1，否则为0)）*
    //FKCK 比较=*
    //FKNK 比较不等于*
    reg [63:0] FKNK_a_wei;      //加法a尾数
    reg [7:0] FKNK_a_jie_z;     //加法a阶码逻辑正
    reg [7:0] FKNK_a_jie_f;     //加法a阶码逻辑负
 
    reg [63:0] FKNK_b_wei;      //加法b尾数
    reg [7:0] FKNK_b_jie_z;     //加法b阶码逻辑正
    reg [7:0] FKNK_b_jie_f;     //加法a阶码逻辑负

    reg [63:0] FKNK_c_wei;      //未规格化的结果位
    reg [7:0] FKNK_c_jie;       //未规格化的阶码
    
    reg [31:0] FUCK_c;          //大于结果位打包
    reg [31:0] FKCU_c;          //小于结果位打包
    reg [31:0] FKCK_c;          //等于结果位打包
    reg [31:0] FKNK_c;          //不等于结果位打包
    
    always @(*) begin //对齐阶码数值（浮点数加法）
        FKNK_a_wei[31:9] = a[22:0];    //a位初始化尾数展开
        FKNK_a_wei[8:0] = 9'b0;
        FKNK_a_wei[32] = 1'b1;
        FKNK_a_wei[63:33] = 31'b0;

        if (a[30:23] > 8'b01111111) begin         //a位真实阶码计算
            FKNK_a_jie_z = a[30:23] - 8'b01111111;
            FKNK_a_jie_f = 8'b0;
        end
        else begin
            if (a[30:23] < 8'b01111111) begin
                FKNK_a_jie_f = 8'b01111111 - a[30:23];
                FKNK_a_jie_z = 8'b0;
            end
            else begin
                FKNK_a_jie_z = 8'b0;
                FKNK_a_jie_f = 8'b0;
            end
        end

        FKNK_b_wei[31:9] = b[22:0];    //b位初始化尾数展开
        FKNK_b_wei[8:0] = 9'b0;
        FKNK_b_wei[32] = 1'b1;
        FKNK_b_wei[63:33] = 31'b0;

        if (b[30:23] > 8'b01111111) begin         //b位真实阶码计算
            FKNK_b_jie_z = b[30:23] - 8'b01111111;
            FKNK_b_jie_f = 8'b0;
        end
        else begin
            if (b[30:23] < 8'b01111111) begin
                FKNK_b_jie_f = 8'b01111111 - b[30:23];
                FKNK_b_jie_z = 8'b0;
            end
            else begin
                FKNK_b_jie_z = 8'b0;
                FKNK_b_jie_f = 8'b0;
            end
        end

        //判断阶码谁大谁小然后对阶
        if (a[30:23] > b[30:23]) begin        //a大b小
            FKNK_b_wei = FKNK_b_wei >> (a[30:23] - b[30:23]);
            FKNK_c_jie = a[30:23];
        end

        if (a[30:23] < b[30:23]) begin        //a小b大
            FKNK_a_wei = FKNK_a_wei >> (b[30:23] - a[30:23]);
            FKNK_c_jie = b[30:23];                           //赋值未规格化的阶码
        end

        //判断大小
        if (FKNK_a_wei > FKNK_b_wei) begin                 //如果结果判断为大
            FUCK_c = 32'b11111111111111111111111111111111; //大于结果位打包
            FKNK_c = 32'b11111111111111111111111111111111; //不等于结果位打包
            FKCK_c = 32'b00000000000000000000000000000000; //等于结果位打包
            FKCU_c = 32'b00000000000000000000000000000000; //小于结果位打包
        end
        else begin
            if (FKNK_a_wei < FKNK_b_wei) begin
                FUCK_c = 32'b00000000000000000000000000000000; //大于结果位打包
                FKNK_c = 32'b11111111111111111111111111111111; //不等于结果位打包
                FKCK_c = 32'b00000000000000000000000000000000; //等于结果位打包
                FKCU_c = 32'b11111111111111111111111111111111; //小于结果位打包
            end
            else begin
                if (FKNK_a_wei == FKNK_b_wei) begin
                    FUCK_c = 32'b00000000000000000000000000000000; //大于结果位打包
                    FKNK_c = 32'b00000000000000000000000000000000; //不等于结果位打包
                    FKCK_c = 32'b11111111111111111111111111111111; //等于结果位打包
                    FKCU_c = 32'b00000000000000000000000000000000; //小于结果位打包
                end
            end
        end
    end


    //根据符号位o给c赋值
    assign c = (o == 4'b0001)? add_c :
               (o == 4'b0010)? mult_c:
               (o == 4'b0011)? FDIV_c:
               (o == 4'b0100)? ITF_c :
               (o == 4'b0101)? FTI_c :
               (o == 4'b0110)? FUCK_c:
               (o == 4'b0111)? FKCU_c:
               (o == 4'b1000)? FKNK_c:
               (o == 4'b1001)? FKCK_c:32'b0


//0001加法
//0010乘法
//0011除法
//0100整数转浮点数
//0101浮点数转整数
//0110判断大于
//0111判断小于
//1000判断不等于
//1001判断等于

endmodule
