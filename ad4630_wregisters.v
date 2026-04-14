`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/08 10:49:07
// Design Name: 
// Module Name: ad4630_wregisters
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ad4630_wregisters(
    input  wire         clk             ,       //100mhz,period=10ns
    input  wire         resetn          ,
    output reg          CH0_DIN         ,      //spi output  mosi  REGISTER WRITE
    output reg          CH0_SCK         ,      //sclk 10mhz     
    output reg          CH0_CS          ,      //spi cs
    output wire         finish_flag
    );
    //=============================
// ���üĴ��������
//=============================
localparam 
    REG_CONF_MODE          = 24'hBFFFFF,            // ��������ģʽ����������ַ0x3FFF��
    MODES_REGISTER         = 24'h002000,            // ģʽ���üĴ�����002000��1lane��spi model��SDR��
    EXIT_CONFIGURATION_MODE =24'h001401;          // �˳�����ģʽ����
 
//=============================
// ����״̬����SPIͨ�ſ��ƣ�
// ���ܣ�ͨ��SPI�ӿ�����ADC�Ĵ���
//=============================
reg             [5:0]    state;           // ����״̬�Ĵ��� 
// ״̬����
localparam
    idle        = 6'b00_0000,   // ����״̬
    pre_cs      = 6'b00_0001,   // ������Ƭѡʹ��
    shift       = 6'b00_0010,   // ����������׼��
    postshift   = 6'b00_0100,   // ��������λ��� 
    finish      = 6'b01_0000;   // �������״̬
 
 
 reg [2:0] clk_div;
 // DIVERGENT CLK ,GENERATE 10MHZ 
always@(posedge clk or negedge resetn)begin
    if(!resetn)begin
        CH0_SCK<=1'b0;
        clk_div<=3'b0;
    end
    else begin
        if(clk_div ==3'd4)begin
            clk_div<=0;
            CH0_SCK<=~CH0_SCK;
           end
         else begin
            clk_div<=clk_div+1'b1;
            end
        end
    end
     
 reg [7:0] bit_cnt;//24bits count
 reg [1:0] data_sel; //select 3 datas write in registers
 reg done;          //write done ,assign =finish
 
 reg[23:0] shift_reg;
 
always@(posedge clk or negedge resetn)begin
    if(!resetn)begin
        state<=idle;
        CH0_CS<=1'b1;
        CH0_DIN<=1'b0;
        bit_cnt<=8'b0;
        data_sel<=2'b0;
        done<=1'b0;
        shift_reg<=24'b0;
    end
    else begin
        case(state)
            idle:begin
                if((data_sel==2'b00)&&(done==1'b0))begin
                    shift_reg<=REG_CONF_MODE;
                    state<=pre_cs;
                end
                else if((data_sel==2'b01)&&(done==1'b0))begin
                    shift_reg<=MODES_REGISTER;
                    state<=pre_cs;
                end
                else if((data_sel==2'b10)&&(done==1'b0))begin
                    shift_reg<=EXIT_CONFIGURATION_MODE;
                    state<=pre_cs;
                end 
                else begin
                    shift_reg<=24'b0;
                    state<=pre_cs;
                end
            end
            pre_cs:begin
                if((clk_div==2)&&(CH0_SCK==1'b0))begin     //set cs down  20ns before sclk 
                    CH0_CS<=1'b0;
                    state<=shift;
                end
            end
            shift:begin
                if((clk_div==3)&&(CH0_SCK==1'b0))begin     //10ns before sclk rising edge output din 
                    CH0_DIN<=shift_reg[23];              
                    shift_reg<={shift_reg[22:0],1'b0};    //shift register
                    bit_cnt<=bit_cnt+1'b1;
                    if(bit_cnt==8'd23)begin
                        state<=postshift;                   //24bits sent
                        if(data_sel!=2'b10)begin
                            data_sel<=data_sel+1'b1;
                        end
                        else begin
                            data_sel<=2'b11;
                        end
                    end
                end
            end
            
            postshift:begin             //post shift
                if((clk_div==0)&&(CH0_SCK==1'b0))begin     //pull cs up  10ns after last sclk 
                    CH0_CS<=1'b1;
                    state<=idle; 
                    bit_cnt<=8'd0;
                    if(data_sel==2'b11)begin
                        done<=1'b1;    //3datas have been sent
                    end 
                end
            end            
        endcase
    end
end

assign finish_flag=done;


endmodule
