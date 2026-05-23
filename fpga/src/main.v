module main
(
    input   clk_50M, rstn,
    output  clk_100M,
    output  [13:0] signal
);
    pll pll_inst
    (
        .inclk0(clk_50M),
        .c0(clk_100M)
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

