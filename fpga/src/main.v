module main
(
    input   clk_50M, rstn,
    input   uart_rx,
    output  clk_100M,
    output  [13:0] signal,
    output  [5:0]   sel,
    output  [7:0]   seg
);
    pll pll_inst
    (
        .inclk0(clk_50M),
        .c0(clk_100M)
    );

    wire [7:0] uart_data;
    wire uart_done;
    UARTReceiver uart_receiver_inst
    (
        .clk(clk_100M),
        .rstn(rstn),
        .rx(uart_rx),
        .data(uart_data),
        .done(uart_done)
    );

    reg [23:0] uart_history_data = 24'd0;
    always @(posedge uart_done or negedge rstn) begin
        if (!rstn) begin
            uart_history_data <= 24'd0;
        end
        else begin
            uart_history_data <= {uart_history_data[15:0], uart_data};  // 将新数据添加到历史数据的末尾
        end
    end

    wire clk_1kHz;
    DIV #(50_000) div_1kHz_inst
    (
        .clk(clk_50M),
        .rstn(rstn),
        .clk_div(clk_1kHz)
    );

    HEXDGT hex_dgt_inst
    (
        .clk(clk_1kHz),
        .rstn(rstn),
        .hex(uart_history_data),
        .dots(6'b010101),
        .sel(sel),
        .seg(seg)
    );

    SignalGenerator signal_gen_inst
    (
        .clk100M(clk_100M),
        .rstn(rstn),
        .freq(24'd1000),  // 频率为1000Hz
        .signal(signal)
    );
endmodule


module SignalGenerator
(
    input clk100M, rstn,
    input [23:0] freq,  // 频率，单位Hz
    output [13:0] signal
);
    parameter FIXED_WIDTH = 38;  // 相位累加器定点数宽度
    parameter PHASE_WIDTH = FIXED_WIDTH + 12;  // 相位累加器总宽度
    parameter CLK_FREQ = 100_000_000;  // 时钟频率，单位Hz
    reg [PHASE_WIDTH-1:0] phase = 0;
    reg [11:0] addr = 0;

    wire [PHASE_WIDTH-1:0] phase_increment = ({freq, {PHASE_WIDTH{1'b0}}}) / CLK_FREQ;  // 计算相位增量

    always @(posedge clk100M or negedge rstn) begin
        if (!rstn) begin
            phase <= 0;
            addr <= 0;
        end
        else begin
            phase <= phase + phase_increment;
            addr <= phase[PHASE_WIDTH-1:PHASE_WIDTH-12];  // 解除定点数位移
        end
    end

    sin_rom rom(
        .address(addr),
        .clock(clk100M),
        .q(signal)
    );
endmodule

