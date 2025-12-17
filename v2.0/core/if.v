//if 取指阶段
//取指先从I_cache发出取值申请让pc+16
//取指位数不限，取出最多8条指令，最少四条，
//放入译码阶段的译码缓冲等待执行，直到可以成功执行为止
module if (
    input wire clk,               //时钟信号
    input wire reset,             //复位信号
    input wire if_stop,           //停止流水线 拉高停止

    //面向I_cache的输入
    output reg [63:0] pc,         //pc值
    input wire [255:0] inst,      //指令流入口
    input wire [255:0] tag,       //tag入口
    input wire [3:0] hit,         //命中标识

    //面向I_cache的输出
    output reg [255:0] tag_white;  //即将写入的新tag(inst_tag(down_pc+256):(down_pc+1):这是属于新tag的位数)
    output reg [63:0] init_tag,    //填写得tag得tag(地址)（代表4位）
    output reg init_tag_start,     //tag写入得势能

    //面向id
    output wire [519:0] out_inst_flat,  //输出8条标准命令，最低位校验为1可执行(展开)
    output reg out_inst_start,          //输出存入势能

    //面向全局
    output reg stop               //停顿
); 
    
    integer i;                    //定义循环变量

    //内部暂留拼接器
    reg [63:0] inst_down;         //需要在前拼接
    reg [6:0] down_pc;            //遗留拼接位数

    reg [319:0] inst_link;        //指令拼接
    reg [319:0] inst_tag;         //tag拼接

    //面向id的指令分割
    reg [64:0] out_inst [0:7];    //8条命令输出
    assign out_inst_flat [64:0] = out_inst[0];    //1
    assign out_inst_flat [129:65] = out_inst[1];  //2
    assign out_inst_flat [194:130] = out_inst[2]; //3
    assign out_inst_flat [259:195] = out_inst[3]; //4
    assign out_inst_flat [324:260] = out_inst[4]; //5
    assign out_inst_flat [389:325] = out_inst[5]; //6
    assign out_inst_flat [454:390] = out_inst[6]; //7
    assign out_inst_flat [519:455] = out_inst[7]; //8

    //分tag判断
    wire [63:0] inst_tag_start [0:3];       //把tag分为四份，确保不会有未分隔的
    assign inst_tag_start[0] = tag[63:0];   
    assign inst_tag_start[1] = tag[127:64]; 
    assign inst_tag_start[2] = tag[191:128];
    assign inst_tag_start[3] = tag[255:192];

    //起始位标签（标记起始位）
    reg [8:0] inst_tag_top;    //起始位置标志
    reg [3:0] inst_out_tag;    //输出命令位置

    //pc加法器与分指令（要写如果L_cache里面没有咋办）
    always @(posedge clk) begin
        init_tag_start = 1'b0;    //复位一下tag写入势能
        out_inst_start = 1'b0;    //复位一下面向id的输出势能
        if (~if_stop) begin       //非停止流水线
            if (
                (inst_tag_start[0] == 64'b0)||    //判断内容是否有空缺tag
                (inst_tag_start[1] == 64'b0)||
                (inst_tag_start[2] == 64'b0)||
                (inst_tag_start[3] == 64'b0)
            ) begin                                //如果有任意一份tag没有得到定位且        

                //拼接inst
                inst_link[down_pc:0] = inst_down[down_pc:0];    //拼接down位
                inst_link[(down_pc+256):(down_pc+1)] = inst;    //拼接指令位
                inst_link[319:(down_pc+257)] = '0;              //高位全部归零

                //拼接tag
                inst_tag[down_pc:0] = '0;                       //拼接down位的tag（全0）
                inst_tag[(down_pc+256):(down_pc+1)] = tag;      //拼接tag位的tag
                inst_tag[319:(down_pc+257)] = '0;               //高位全部归零

                //从上至下搜寻可用标签(6位操作码)
                for (i = 0; i < 320; i = i + 0) begin    //每次循环都必然是吓一条指令的起始位置
                    //首位填写
                    if (i = 0) begin    //查看是否为首位
                        case (inst_link[6:0])
                            7'b0110011: begin          //R类型（32位宽）
                                tag_white[31] = 1'b1;  //指令边界
                                i = i + 32;            //规定下一条指令的起始位置
                            end

                            7'b0010011:begin           //I类型（32位宽）
                                tag_white[31] = 1'b1;  //指令边界
                                i = i + 32;            //规定下一条指令的起始位置
                            end

                            7'b0000011:begin           //load_inst(I类型)(32位宽)
                                tag_white[31] = 1'b1;  //指令边界
                                i = i + 32;            //规定下一条指令的起始位置
                            end
                        
                            7'b0100011:begin           //S类型(32位宽)
                                tag_white[31] = 1'b1;  //指令边界
                                i = i + 32;            //规定下一条指令的起始位置
                            end

                            7'b1100011:begin           //B类型(32位宽)
                                tag_white[31] = 1'b1;  //指令边界
                                i = i + 32;            //规定下一条指令的起始位置
                            end

                            7'b1101111:begin           //j类型(32位宽)
                                tag_white[31] = 1'b1;  //指令边界
                                i = i + 32;            //规定下一条指令的起始位置
                            end

                            7'b1100111:begin           //I类型(32位宽)立即数跳转
                                tag_white[31] = 1'b1;  //指令边界
                                i = i + 32;            //规定下一条指令的起始位置
                            end

                            7'b0110111:begin           //U类型(32位宽)
                                tag_white[31] = 1'b1;  //指令边界
                                i = i + 32;            //规定下一条指令的起始位置
                            end

                            7'b0010111:begin           //U_B类型(32位宽)
                                tag_white[31] = 1'b1;  //指令边界
                                i = i + 32;            //规定下一条指令的起始位置
                            end

                            7'b1110011:begin           //I类型(32位宽)two
                                tag_white[31] = 1'b1;  //指令边界
                                i = i + 32;            //规定下一条指令的起始位置
                            end
                        
                            //变长扩展
                            //。。。。

                            //特殊指令处理
                            default: begin             //如果遇到辨认不对的指令触发异常处理
                                                       //大致就是往异常处理的寄存器发送异常信息然后暂停流水线
                            stop = 1'b1;               //暂停流水线等待异常处理
                            end
                        endcase
                    end
                    else begin                         //后续命令边界判断（非头部）
                        case (inst_link[(i + 6):(i + 0)])
                            7'b0110011: begin              //R类型（32位宽）
                                tag_white[i + 31] = 1'b1;  //指令边界
                                i = i + 32;                //规定下一条指令的起始位置
                            end

                            7'b0010011:begin               //I类型（32位宽）
                                tag_white[i + 31] = 1'b1;  //指令边界
                                i = i + 32;                //规定下一条指令的起始位置
                            end

                            7'b0000011:begin               //load_inst(I类型)(32位宽)
                                tag_white[i + 31] = 1'b1;  //指令边界
                                i = i + 32;                //规定下一条指令的起始位置
                            end
                        
                            7'b0100011:begin               //S类型(32位宽)
                                tag_white[i + 31] = 1'b1;  //指令边界
                                i = i + 32;                //规定下一条指令的起始位置
                            end

                            7'b1100011:begin               //B类型(32位宽)
                                tag_white[i + 31] = 1'b1;  //指令边界
                                i = i + 32;                //规定下一条指令的起始位置
                            end

                            7'b1101111:begin               //j类型(32位宽)
                                tag_white[i + 31] = 1'b1;  //指令边界
                                i = i + 32;                //规定下一条指令的起始位置
                            end

                            7'b1100111:begin               //I类型(32位宽)立即数跳转
                                tag_white[i + 31] = 1'b1;  //指令边界
                                i = i + 32;                //规定下一条指令的起始位置
                            end

                            7'b0110111:begin               //U类型(32位宽)
                                tag_white[i + 31] = 1'b1;  //指令边界
                                i = i + 32;                //规定下一条指令的起始位置
                            end

                            7'b0010111:begin               //U_B类型(32位宽)
                                tag_white[i + 31] = 1'b1;  //指令边界
                                i = i + 32;                //规定下一条指令的起始位置
                            end

                            7'b1110011:begin               //I类型(32位宽)two
                                tag_white[i + 31] = 1'b1;  //指令边界
                                i = i + 32;                //规定下一条指令的起始位置
                            end
                        
                            //变长扩展
                            //。。。。

                            //特殊指令处理
                            default: begin             //如果遇到辨认不对的指令触发异常处理
                                                       //大致就是往异常处理的寄存器发送异常信息然后暂停流水线
                            stop = 1'b1;               //暂停流水线等待异常处理
                            end
                        endcase

                        tag_white = inst_tag[(down_pc+256):(down_pc+1)];    //拼接填写tag
                        init_tag = pc;                                      //填写pc内容
                        init_tag_start = 1'b1;                              //点一下势能
                    end
                end
                
                end
            else begin  
                pc = pc + 64'd16;  //pc+16

                //拼接inst
                inst_link[down_pc:0] = inst_down[down_pc:0];    //拼接down位
                inst_link[(down_pc+256):(down_pc+1)] = inst;    //拼接指令位
                inst_link[319:(down_pc+257)] = '0;              //高位全部归零
            
                //拼接tag
                inst_tag[down_pc:0] = '0;                       //拼接down位的tag（全0）
                inst_tag[(down_pc+256):(down_pc+1)] = tag;      //拼接tag位的tag
                inst_tag[319:(down_pc+257)] = '0;               //高位全部归零

                //输出到id阶段的内容
                //输出id阶段8条命令以及down位寄存器和down_pc的值
                inst_tag_top = 9'b0;                        //标志低位位宽归零
                inst_out_tag = 4'b0;                        //指令输出归零
                for (i = 0; i < 8; i = i + 1) begin         //清除8个指令位
                    out_inst[i] = 65'b0;                    //归零
                end

                //8条指令的输出
                for (i = 0; i < 320; i = i + 1'b1) begin    //扫描位宽
                    if (inst_tag[i] == 1'b1) begin
                        out_inst [inst_out_tag][0] = 1'b1;  //低位挂标记
                        out_inst [inst_out_tag][64:1] = inst_link[i:inst_tag_top];  //输出命令

                        inst_tag_top = i + 1'b1;                                    //低位标记为i + 1
                        inst_out_tag = inst_out_tag + 1'b1;                         //位数加一
                    end
                end

                //down_pc和down的输出内容
                down_pc = 6'(320 - inst_tag_top);    //down_pc赋值
                inst_down = [319:inst_tag_top];      //inst_down赋值

                out_inst_start = 1'b1;               //输出势能存入id缓冲区
            end
        end
    end
    

endmodule