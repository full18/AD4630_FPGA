`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/10 11:39:18
// Design Name: 
// Module Name: AD4630_TOP
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


module AD4630_TOP(
    input  wire         clk_100MHZ      ,       //100mhz,period=10ns
    input  wire         rstn            ,
    input  wire         CH0_AD0         , 
    input  wire         CH0_AD4         ,
    output wire         CH0_DIN         ,      //spi output  mosi  REGISTER WRITE
    output wire         CH0_SCK         ,      //sclk 10mhz     
    output wire         CH0_CS          ,      //spi cs
    output wire         CH0_CNV         ,
    input  wire         CH0_BUSY        ,      //goes high at at start of con, return low when conv finished(most 300ns) 
    output wire         read_flag       ,
    output wire [23:0]  adc_ch0         ,
    output wire [23:0]  adc_ch1         ,
    output wire         CH0_RESET       
    );
    assign CH0_RESET=1'b1;

     wire finish_flag;
     wire config_cs;
     wire config_sck;
     ad4630_wregisters  inst_config(
          .     clk         (clk_100MHZ)        ,       //100mhz,period=10ns
          .     resetn      (rstn)  ,
          .     CH0_DIN     (CH0_DIN)    ,      //spi output  mosi  REGISTER WRITE
          .     CH0_SCK     (config_sck)    ,      //sclk 10mhz     
          .     CH0_CS      (config_cs)     ,      //spi cs
          .     finish_flag (finish_flag)
         );
     wire read_cs;
     wire read_sck;
   
   read_4630 inst_read(
    .   clk      (clk_100MHZ  )      ,       //100mhz,period=10ns
    .   ready     (finish_flag )      ,
    .   CH0_CNV   (CH0_CNV     )      ,      //<=2MSPS ,100khz,period=10us=10000ns
    .   CH0_BUSY  (CH0_BUSY    )      ,      //goes high at at start of con, return low when conv finished(most 300ns) 
    .   CH0_SCK   (read_sck    )      ,      //sclk 10mhz     
    .   CH0_CS    (read_cs     )      ,      //spi cs
    .   CH0_AD0   (CH0_AD0     )      ,      //spi miso0
    .   CH0_AD4   (CH0_AD4     )      ,       //spi miso1
    .   flag      (read_flag   )      ,     //read done
    .   CH0       (adc_ch0     )      ,
    .   CH1       (adc_ch1     )  
    );
     
    assign CH0_CS  =(finish_flag==1)?read_cs:config_cs;
    assign CH0_SCK =(finish_flag==1)?read_sck:config_sck; 


endmodule
