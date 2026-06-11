/*
 * 组件模块，包含FPGA常用组件
 */

// N进制计数器
// clk: 时钟信号
// rstn: 复位信号，低电平有效
// count: 当前计数值，范围为0~N-1
// carry: 进位信号，当计数器从N-1回到0时，carry为1
// param N: 计数器的进制，默认为32
// param INITIAL_CNT: 计数器的初始值，默认为0
module CTU(
    input                           clk, rstn,
    output  reg [$clog2(N)-1 : 0]   count,
    output  reg                     carry
);
    parameter N = 32;
    parameter INITIAL_CNT = 0;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count <= INITIAL_CNT;
            carry <= 1'b0;
        end
        else
            if (count == N - 1) begin
                count <= 0;
                carry <= 1'b1;
            end
            else begin
                count <= count + 1'b1;
                carry <= 1'b0;
            end
    end
endmodule

// 分频器
// clk: 输入时钟信号
// rstn: 复位信号，低电平有效
// clk_div: 输出的分频时钟信号
// param NUM_DIV: 分频系数，必须为偶数，默认为10
module DIV(
    input        clk, rstn,
    output  reg  clk_div
);
    parameter NUM_DIV = 10;
    reg [$clog2(NUM_DIV>>1'b1)-1 : 0] count;
 
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count <= 0;
            clk_div <= 1'b0;
        end
        else if (count < (NUM_DIV >> 1'b1) - 1) begin
            count <= count + 1'b1;
        end
        else begin
            count <= 0;
            clk_div <= ~clk_div;
        end
    end
endmodule

// BCD数码管显示器
// clk: 时钟信号
// rstn: 复位信号，低电平有效
// bcd: 24位BCD码输入，表示6位十进制数，每4位表示一个数字
// dots: 6位小数点控制信号，1表示对应位的小数点亮起，0表示不亮
// sel: 数码管位选信号，6位，低电平有效
// seg: 数码管段选信号，8位，低电平有效，最高位为小数点
module BCDDGT(
    input               clk, rstn,
    input       [23:0]  bcd,
    input       [5:0]   dots,
    output  reg [5:0]   sel,
    output  reg [7:0]   seg
);
    parameter _0 = 7'b0111111, _1 = 7'b0000110, _2 = 7'b1011011,
              _3 = 7'b1001111, _4 = 7'b1100110, _5 = 7'b1101101,
              _6 = 7'b1111101, _7 = 7'b0000111, _8 = 7'b1111111,
              _9 = 7'b1101111, _X = 7'b0000000;
 
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sel <= 6'b111111;
        else
            sel <= (sel == 6'b111111) ? 6'b111110 : {sel[4:0], sel[5]};
    end
    
    reg [3:0] dig_seg;
    always @(*) begin
        case (sel)
            6'b111110: dig_seg = bcd[3:0];
            6'b111101: dig_seg = bcd[7:4];
            6'b111011: dig_seg = bcd[11:8];
            6'b110111: dig_seg = bcd[15:12];
            6'b101111: dig_seg = bcd[19:16];
            6'b011111: dig_seg = bcd[23:20]; 
            default: dig_seg = 4'b1111;
        endcase
    end
 
    reg dot;
    always @(*) begin
        dot = (sel == 6'b111110) ? dots[0] :
              (sel == 6'b111101) ? dots[1] :
              (sel == 6'b111011) ? dots[2] :
              (sel == 6'b110111) ? dots[3] :
              (sel == 6'b101111) ? dots[4] :
              (sel == 6'b011111) ? dots[5] : 1'b0;
        case (dig_seg)
            4'd0: seg = {dot, _0};
            4'd1: seg = {dot, _1};
            4'd2: seg = {dot, _2};
            4'd3: seg = {dot, _3};
            4'd4: seg = {dot, _4};
            4'd5: seg = {dot, _5};
            4'd6: seg = {dot, _6};
            4'd7: seg = {dot, _7};
            4'd8: seg = {dot, _8};
            4'd9: seg = {dot, _9};
            default: seg = {dot, _X};
        endcase
    end
endmodule

// HEX数码管显示器
// clk: 时钟信号
// rstn: 复位信号，低电平有效
// hex: 24位十六进制码输入，表示6位十六进制数，每4位表示一个数字
// dots: 6位小数点控制信号，1表示对应位的小数点亮起，0表示不亮
// sel: 数码管位选信号，6位，低电平有效
// seg: 数码管段选信号，8位，低电平有效，最高位为小数点
module HEXDGT(
    input               clk, rstn,
    input       [23:0]  hex,
    input       [5:0]   dots,
    output  reg [5:0]   sel,
    output  reg [7:0]   seg
);
    parameter _0 = 7'b0111111, _1 = 7'b0000110, _2 = 7'b1011011,
              _3 = 7'b1001111, _4 = 7'b1100110, _5 = 7'b1101101,
              _6 = 7'b1111101, _7 = 7'b0000111, _8 = 7'b1111111,
              _9 = 7'b1101111, _A = 7'b1110111, _B = 7'b1111100,
              _C = 7'b0111001, _D = 7'b1011110, _E = 7'b1111001,
              _F = 7'b1110001, _X = 7'b0000000;

    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sel <= 6'b111111;
        else
            sel <= (sel == 6'b111111) ? 6'b111110 : {sel[4:0], sel[5]};
    end
    
    reg [3:0] dig_seg;
    always @(*) begin
        case (sel)
            6'b111110: dig_seg = hex[3:0];
            6'b111101: dig_seg = hex[7:4];
            6'b111011: dig_seg = hex[11:8];
            6'b110111: dig_seg = hex[15:12];
            6'b101111: dig_seg = hex[19:16];
            6'b011111: dig_seg = hex[23:20]; 
            default: dig_seg = 4'b1111;
        endcase
    end
 
    reg dot;
    always @(*) begin
        dot = (sel == 6'b111110) ? dots[0] :
              (sel == 6'b111101) ? dots[1] :
              (sel == 6'b111011) ? dots[2] :
              (sel == 6'b110111) ? dots[3] :
              (sel == 6'b101111) ? dots[4] :
              (sel == 6'b011111) ? dots[5] : 1'b0;
        case (dig_seg)
            4'd0: seg = {dot, _0};
            4'd1: seg = {dot, _1};
            4'd2: seg = {dot, _2};
            4'd3: seg = {dot, _3};
            4'd4: seg = {dot, _4};
            4'd5: seg = {dot, _5};
            4'd6: seg = {dot, _6};
            4'd7: seg = {dot, _7};
            4'd8: seg = {dot, _8};
            4'd9: seg = {dot, _9};
            4'd10: seg = {dot, _A};
            4'd11: seg = {dot, _B};
            4'd12: seg = {dot, _C};
            4'd13: seg = {dot, _D};
            4'd14: seg = {dot, _E};
            4'd15: seg = {dot, _F};
            default: seg = {dot, _X};
        endcase
    end
endmodule

// 二进制数转BCD码
// bin: 16位二进制输入
// bcd: 24位BCD码输出，表示6位十进制数，每4位表示一个数字
module BIN2BCD
(
    input       [15:0]  bin,
    output  reg [23:0]  bcd
);
    integer i;
    always @(*) begin
        bcd = 24'b0;
        for (i = 15; i >= 0; i = i - 1) begin
            if (bcd[3:0] > 4)
                bcd[3:0] = bcd[3:0] + 3;
            if (bcd[7:4] > 4)
                bcd[7:4] = bcd[7:4] + 3;
            if (bcd[11:8] > 4)
                bcd[11:8] = bcd[11:8] + 3;
            if (bcd[15:12] > 4)
                bcd[15:12] = bcd[15:12] + 3;
            if (bcd[19:16] > 4)
                bcd[19:16] = bcd[19:16] + 3;
            if (bcd[23:20] > 4)
                bcd[23:20] = bcd[23:20] + 3;
            bcd = {bcd, bin[i]};
        end
    end
endmodule

// 有限状态机
// clk: 时钟信号
// rstn: 复位信号，低电平有效
// stn: 下一个状态输入
// initial_state: 初始状态，复位时stc被设置为该值
// stc: 当前状态输出
module FSM
(
    input               clk, rstn,
    input       [$clog2(N)-1 : 0]   stn,
    input       [$clog2(N)-1 : 0]   initial_state,
    output  reg [$clog2(N)-1 : 0]   stc
);
    parameter N = 4;
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            stc <= initial_state;
        else
            stc <= stn;
    end
endmodule

// 异步信号同步器
// clk: 时钟信号
// rstn: 复位信号，低电平有效
// signal: 输入的异步信号
// signal_sync: 输出的同步信号
module SignalSync
(
    input clk, rstn, signal,
    output reg signal_sync
);
    parameter DEFAULT_VALUE = 1'b0;
    reg signal_buf;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            signal_buf <= DEFAULT_VALUE;
            signal_sync <= DEFAULT_VALUE;
        end
        else begin
            signal_buf <= signal;
            signal_sync <= signal_buf;
        end
    end
endmodule

// 上升沿检测器
// clk: 时钟信号
// rstn: 复位信号，低电平有效
// signal_sync: 输入的同步信号。模块内部为了避免延迟没有进行二次同步，因此要求输入信号已经过同步处理
// signal_posedge: 输出的上升沿检测信号，当signal_sync从0变为1时，signal_posedge为1
module PosedgeDetector
(
    input clk, rstn, signal_sync,
    output signal_posedge
);
    reg signal_sync_prev;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            signal_sync_prev <= 1'b0;
        end
        else begin
            signal_sync_prev <= signal_sync;
        end
    end
    assign signal_posedge = signal_sync & ~signal_sync_prev;
endmodule

// 下降沿检测器
// clk: 时钟信号
// rstn: 复位信号，低电平有效
// signal_sync: 输入的同步信号。模块内部为了避免延迟没有进行二次同步，因此要求输入信号已经过同步处理
// signal_negedge: 输出的下降沿检测信号，当signal_sync从1变为0时，signal_negedge为1
module NegedgeDetector
(
    input clk, rstn, signal_sync,
    output signal_negedge
);
    reg signal_sync_prev;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            signal_sync_prev <= 1'b0;
        end
        else begin
            signal_sync_prev <= signal_sync;
        end
    end
    assign signal_negedge = ~signal_sync & signal_sync_prev;
endmodule

module UARTReceiver
(
    input clk, rstn, rx,
    output reg [7:0] data,
    output reg done
);
    parameter BAUD_RATE = 9600;
    parameter CLK_FREQ = 100_000_000;
    parameter BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    localparam integer BIT_PERIOD_I = BIT_PERIOD;
    localparam integer HALF_PERIOD_I = (BIT_PERIOD_I >> 1);

    wire rx_sync;
    SignalSync #(1'b1) sync_inst(
        .clk(clk),
        .rstn(rstn),
        .signal(rx),
        .signal_sync(rx_sync)
    );

    wire rx_negedge;
    NegedgeDetector negedge_inst(
        .clk(clk),
        .rstn(rstn),
        .signal_sync(rx_sync),
        .signal_negedge(rx_negedge)
    );

    wire [$clog2(BIT_PERIOD_I)-1:0] tick_count;
    reg [2:0] bit_index = 3'd0;

    reg tick_rstn = 1'b0;
    wire tick_carry;
    CTU #(BIT_PERIOD_I, 0) tick_counter(
        .clk(clk),
        .rstn(tick_rstn),
        .count(tick_count),
        .carry(tick_carry)
    );

    reg [1:0] stn;
    wire [1:0] stc;
    FSM #(4) fsm_inst(
        .clk(clk),
        .rstn(rstn),
        .stn(stn),
        .initial_state(IDLE),
        .stc(stc)
    );

    // 状态转移逻辑
    always @(*) begin
        stn = stc;
        case (stc)
            IDLE: stn = rx_negedge ? START : stn;

            START: stn = (tick_count == HALF_PERIOD_I) ? (rx_sync ? IDLE : DATA) : stn;

            DATA: stn = (tick_carry && bit_index == 3'd7) ? STOP : stn;

            STOP: stn = tick_carry ? IDLE : stn;

            default: stn = IDLE;
        endcase
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bit_index <= 3'd0;
            data <= 8'b0;
            done <= 1'b0;
            tick_rstn <= 1'b0;
        end
        else begin
            case (stc)
                IDLE: begin
                    done <= 1'b0;
                    bit_index <= 3'd0;
                    tick_rstn <= 1'b0;
                end

                START: begin
                    done <= 1'b0;
                    bit_index <= 3'd0;
                    if (tick_count == HALF_PERIOD_I && rx_sync == 1'b0) begin
                        tick_rstn <= 1'b0;  // 重置计数器，准备循环计数
                    end
                    else begin
                        tick_rstn <= 1'b1;  // 伪启动，保持计数器直至状态转移回空闲状态
                    end
                end

                DATA: begin
                    tick_rstn <= 1'b1;
                    done <= 1'b0;
                    if (tick_carry) begin
                        data[bit_index] <= rx_sync;
                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                end

                STOP: begin
                    tick_rstn <= 1'b1;
                    done <= tick_carry;  // 在停止位结束时输出done信号
                end

                default: begin
                    bit_index <= 3'd0;
                    tick_rstn <= 1'b0;
                    done <= 1'b0;
                end
            endcase
        end
    end
endmodule

// 无符号数据四舍五入模块
module UnsignedRnd
#(
    parameter DW_IN = 16,  // 输入数据位宽
    parameter DW_OUT = 8   // 输出数据位宽
)
(
    input [DW_IN-1:0] data_in,
    output [DW_OUT-1:0] data_out
);
    reg [DW_OUT-1:0] data_out_reg;
    always @(*)
    begin
        if (data_in[DW_IN-1:DW_IN-DW_OUT] == {{DW_OUT}{1'b1}})
        begin
            data_out_reg = data_in[DW_IN-1:DW_IN-DW_OUT];
        end
        else
        begin
            data_out_reg = data_in[DW_IN-1:DW_IN-DW_OUT] + data_in[DW_IN-DW_OUT-1];;
        end
    end

    assign data_out = data_out_reg;
endmodule

// 无符号数据饱和模块
module UnsignedSat
#(
    parameter DW_IN = 16,
    parameter DW_OUT = 8
)
(
    input [DW_IN-1:0] data_in,
    output [DW_OUT-1:0] data_out
);
    reg [DW_OUT-1:0] data_out_reg;
    always @(*)
    begin
        if (data_in[DW_IN-1:DW_OUT] == {{DW_IN-DW_OUT}{1'b0}})
        begin
            data_out_reg = data_in[DW_OUT-1:0];
        end
        else
        begin
            data_out_reg = {DW_OUT{1'b1}};
        end
    end

    assign data_out = data_out_reg;
endmodule

// 有符号数据四舍五入模块
module SignedRnd
#(
    parameter DW_IN = 16,
    parameter DW_OUT = 8
)
(
    input [DW_IN-1:0] data_in,
    output [DW_OUT-1:0] data_out
);
    reg [DW_OUT-1:0] data_out_reg;
    always @(*)
    begin
        if ((data_in[DW_IN-1:DW_IN-DW_OUT] == {1'b0, (DW_OUT-1){1'b1}}) || ((data_in[DW_IN-1] == 1'b1) && (data_in[DW_IN-DW_OUT-1:0] == {1'b1, (DW_IN-DW_OUT){1'b0}})))
        begin
            data_out_reg = data_in[DW_IN-1:DW_IN-DW_OUT];
        end
        else
        begin
            data_out_reg = data_in[DW_IN-1:DW_IN-DW_OUT] + data_in[DW_IN-DW_OUT-1];
        end
    end

    assign data_out = data_out_reg;
endmodule

// 有符号数据饱和模块
module SignedSat
#(
    parameter DW_IN = 16,
    parameter DW_OUT = 8
)
(
    input [DW_IN-1:0] data_in,
    output [DW_OUT-1:0] data_out
);
    reg [DW_OUT-1:0] data_out_reg;
    always @(*)
    begin
        if (data_in[DW_IN-1] == 1'b1 && data_in[DW_IN-2:DW_OUT-1] != {(DW_IN-DW_OUT){1'b1}})
        begin
            data_out_reg = {1'b1, {(DW_OUT-1){1'b0}}};
        end
        else if (data_in[DW_IN-1] == 1'b0 && data_in[DW_IN-2:DW_OUT-1] != {(DW_IN-DW_OUT){1'b0}})
        begin
            data_out_reg = {1'b0, {(DW_OUT-1){1'b1}}};
        end
        else
        begin
            data_out_reg = data_in[DW_OUT-1:0];
        end
    end

    assign data_out = data_out_reg;
endmodule

