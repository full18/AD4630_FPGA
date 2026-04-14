`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/09 14:25:32
// Design Name: 
// Module Name: read_4630
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


module read_4630(
    input  wire         clk             ,       //10mhz,period=100ns=0.1us
    input  wire         ready          ,
    output reg          CH0_CNV         ,      //==50KSPS ,period=20000ns=200clk
    input  wire         CH0_BUSY        ,      //goes high at at start of con, return low when conv finished(most 300ns) 
    output reg          CH0_SCK         ,      //sclk 10mhz/4=2.5MHZ     
    output wire         CH0_CS          ,      //spi cs
    input  wire         CH0_AD0         ,      //spi miso0
    input  wire         CH0_AD4         ,       //spi miso1
    output wire         flag            ,
    output reg  [23:0]  CH0             ,
    output reg  [23:0]  CH1
    );
    

reg             [4:0]    state;           // STATE SHIFT REGISTER 
// STATE VALUE
localparam
    idle        = 5'b0_0000,   //IDLE  ,DONE=0,CS=1;READY;UNTIL cnt_conV=1  
    start_cnv   = 5'b0_0001,   // cnv BUSY=1,WAIT FOR BUSY FALLEDGE ,DONE=0,CS=1
    pre_cs      = 5'b0_0010,   // conv start,BUSY ==0,CS=1,DONE=0
    shift       = 5'b0_0100,   // CS=0,DONE=0,SHIFT DATA INTO CH0/CH1[23:0]
    postshift   = 5'b0_1000,   // FINSIH SHIFT,CLEAR BIT_CNT,
    finish      = 5'b1_0000;   // DONE =1 ,READ VALUE,UNTIL cnt_conV=198   
    
reg [2:0] clk_div;
 // DIVERGENT CLK ,GENERATE SCLK=2.5MHZ 
always@(posedge clk )begin
    if(!ready)begin
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
    
 //CONV=200CLK ,50 ksps =200 clk
reg[15:0] cnt_conv;
always @(posedge clk )begin
    if(!ready)begin
        cnt_conv<=16'b0;
    end  
    else if(cnt_conv<16'd199) begin   //
        cnt_conv<=cnt_conv+1'b1;
    end  
    else begin
        cnt_conv<=16'b0;
    end
end
 //catch busy negedge
reg temp_busy;
reg busy_edg;

always @(posedge clk)begin
    temp_busy<=CH0_BUSY; 
    busy_edg<=temp_busy&(~CH0_BUSY);  //mark negedge of busy
end
reg temp_cs;
assign CH0_CS=temp_cs;
 reg done;  
 reg [7:0] bit_cnt;//24bits count    
 always@(posedge clk )begin
    if(!ready)begin
       state<=idle;
       bit_cnt<=8'b0;
       CH0_CNV<=1'b0;
       temp_cs<=1'b1;
       CH0<=24'b0;
       CH1<=24'b0;
       done<=1'b0;
    end
    else begin
        case(state)
             idle:begin
                     done<=1'b0;
                     temp_cs<=1'b1;
                     CH0_CNV<=1'b0;
                     bit_cnt<=8'b0;
                     done<=1'b0;
                     if(cnt_conv==16'b1)
                         state<=start_cnv;
                     else state<=idle;
             end
             start_cnv:begin
                     CH0_CNV<=1'b1;
                     if(busy_edg)state<=pre_cs; 
                     else if(cnt_conv>16'd36)state<=pre_cs; //3600   
                     else  state<=start_cnv; 
             end
             pre_cs:begin
             if((clk_div==2)&&(CH0_SCK==1'b0))begin     //set cs down  20ns before sclk 
                      temp_cs<=1'b0;
                      state<=shift;
                      CH0_CNV<=1'b0;
                end             
             end
             shift:begin
             if((clk_div==2)&&(CH0_SCK==1'b1))begin             //sclk high period
                       CH0<={CH0[22:0],CH0_AD0};
                       CH1<={CH1[22:0],CH0_AD4};
                       bit_cnt<=bit_cnt+1'b1;
                       if(bit_cnt==8'd23)begin
                                state<=postshift;                   //24bits sent
                       end
                       else begin 
                           state<=shift;
                       end
                   end
                 end
         postshift:begin             //post shift
                if((clk_div==0)&&(CH0_SCK==1'b0))begin     //pull cs up  10ns after last sclk 
                    state<=finish; 
//                    temp_cs<=1'b1;                    
                    bit_cnt<=8'd0;
                end
            end
         finish:begin
             done<=1'b1;
             if(cnt_conv<16'd198)//9998
                 state<=finish;
             else state<=idle;
         end
        endcase;
    end
end   
    assign flag=done;
    
    


endmodule