/*
*6-pin Mini-DIN (PS/2):
*1 - Data 
*2 - Not Implemented 
*3 - Ground 
*4 - Vcc (+5V) 
*5 - Clock 
*6 - Not Implemented 
*/

module PS2(
    input SampleCLK,
    input RST,
    input InCLK,
    input InData,
    output Valid,
    output [7:0] Ascii
);

wire [7:0] Scan;
reg CLK;
reg Data;
reg [10:0] RecvData;
assign Scan = RecvData[8:1];
reg [3:0] state;
reg receiving;
reg pre_receiving;
wire received = pre_receiving & ~receiving;
reg L_Shift, L_Ctrl;
reg Detach;
wire Valid_buf = ~Detach & received;
CONV_SC_TO_AS conv(Scan, L_Shift, Ascii);
EDGE_TO_PULSE genvalid(SampleCLK, Valid_buf, Valid);

always @(posedge SampleCLK)
    CLK <= InCLK;

always @(posedge SampleCLK)
    Data <= InData;

always @(negedge CLK, posedge RST)
    if(RST)
        state <= 4'h0;
    else begin
        if(state < 4'd10) state <= state + 1'b1;
        else state <= 4'h0;
        case(state)
            4'd0:begin
                RecvData[0] <= Data;
                receiving <= 1'b1;
            end
            4'd1:RecvData[1] <= Data;
            4'd2:RecvData[2] <= Data;
            4'd3:RecvData[3] <= Data;
            4'd4:RecvData[4] <= Data;
            4'd5:RecvData[5] <= Data;
            4'd6:RecvData[6] <= Data;
            4'd7:RecvData[7] <= Data;
            4'd8:RecvData[8] <= Data;
            4'd9:RecvData[9] <= Data;
            4'd10:begin
                RecvData[10] <= Data;
                receiving <= 1'b0;
            end
            default:RecvData <= 11'h7FF;
        endcase
    end

always @(posedge CLK, posedge RST) 
    if(RST) begin
        L_Shift <= 1'b0;
        L_Ctrl <= 1'b0;
        Detach <= 1'b0;
    end
    else begin
        pre_receiving <= receiving;
        if(received) begin
            if(~Detach)
                case(Scan)
                    8'h12:L_Shift <= 1'b1;
                    8'h14:L_Ctrl <= 1'b1;
                    8'hF0:Detach <= 1'b1;
                endcase
            else begin
                Detach <= 1'b0;
                case(Scan)
                    8'h12:L_Shift <= 1'b0;
                    8'h14:L_Ctrl <= 1'b0;
                endcase
            end
        end
    end

endmodule

module CONV_SC_TO_AS(
    input [7:0] Scan,
    input Shift,
    output reg [7:0] Ascii
);

always @*
    if(~Shift)
        case(Scan)
            8'h66:Ascii = 8'h08;   //BS 
            8'h5A:Ascii = 8'h0D;   //Enter 
            8'h29:Ascii = 8'h20;   //Space 
            8'h76:Ascii = 8'h1B;   //Esc 

            8'h16:Ascii = 8'h31;   //1 
            8'h1E:Ascii = 8'h32;   //2 
            8'h26:Ascii = 8'h33;   //3 
            8'h25:Ascii = 8'h34;   //4 
            8'h2E:Ascii = 8'h35;   //5 
            8'h36:Ascii = 8'h36;   //6 
            8'h3D:Ascii = 8'h37;   //7 
            8'h3E:Ascii = 8'h38;   //8 
            8'h46:Ascii = 8'h39;   //9 
            8'h45:Ascii = 8'h30;   //0 

            8'h1C:Ascii = 8'h61;   //a 
            8'h32:Ascii = 8'h62;   //b 
            8'h21:Ascii = 8'h63;   //c 
            8'h23:Ascii = 8'h64;   //d 
            8'h24:Ascii = 8'h65;   //e 
            8'h2B:Ascii = 8'h66;   //f 
            8'h34:Ascii = 8'h67;   //g 
            8'h33:Ascii = 8'h68;   //h 
            8'h43:Ascii = 8'h69;   //i 
            8'h3B:Ascii = 8'h6A;   //j 
            8'h42:Ascii = 8'h6B;   //k 
            8'h4B:Ascii = 8'h6C;   //l 
            8'h3A:Ascii = 8'h6D;   //m 
            8'h31:Ascii = 8'h6E;   //n 
            8'h44:Ascii = 8'h6F;   //o 
            8'h4D:Ascii = 8'h70;   //p 
            8'h15:Ascii = 8'h71;   //q 
            8'h2D:Ascii = 8'h72;   //r 
            8'h1B:Ascii = 8'h73;   //s 
            8'h2C:Ascii = 8'h74;   //t 
            8'h3C:Ascii = 8'h75;   //u 
            8'h2A:Ascii = 8'h76;   //v 
            8'h1D:Ascii = 8'h77;   //w 
            8'h22:Ascii = 8'h78;   //x 
            8'h35:Ascii = 8'h79;   //y 
            8'h1A:Ascii = 8'h7A;   //z 
            default:Ascii = 8'h0;
        endcase
    else
        case(Scan)
            8'h16:Ascii = 8'h21;   //! 
            8'h1E:Ascii = 8'h22;   //" 
            8'h26:Ascii = 8'h23;   //# 
            8'h25:Ascii = 8'h24;   //$ 
            8'h2E:Ascii = 8'h25;   //% 
            8'h36:Ascii = 8'h26;   //& 
            8'h3D:Ascii = 8'h27;   //' 
            8'h3E:Ascii = 8'h28;   //( 
            8'h46:Ascii = 8'h29;   //) 

            8'h1C:Ascii = 8'h41;   //a 
            8'h32:Ascii = 8'h42;   //b 
            8'h21:Ascii = 8'h43;   //c 
            8'h23:Ascii = 8'h44;   //d 
            8'h24:Ascii = 8'h45;   //e 
            8'h2B:Ascii = 8'h46;   //f 
            8'h34:Ascii = 8'h47;   //g 
            8'h33:Ascii = 8'h48;   //h 
            8'h43:Ascii = 8'h49;   //i 
            8'h3B:Ascii = 8'h4A;   //j 
            8'h42:Ascii = 8'h4B;   //k 
            8'h4B:Ascii = 8'h4C;   //l 
            8'h3A:Ascii = 8'h4D;   //m 
            8'h31:Ascii = 8'h4E;   //n 
            8'h44:Ascii = 8'h4F;   //o 
            8'h4D:Ascii = 8'h70;   //p 
            8'h15:Ascii = 8'h51;   //q 
            8'h2D:Ascii = 8'h52;   //r 
            8'h1B:Ascii = 8'h53;   //s 
            8'h2C:Ascii = 8'h54;   //t 
            8'h3C:Ascii = 8'h55;   //u 
            8'h2A:Ascii = 8'h56;   //v 
            8'h1D:Ascii = 8'h57;   //w 
            8'h22:Ascii = 8'h58;   //x 
            8'h35:Ascii = 8'h59;   //y 
            8'h1A:Ascii = 8'h5A;   //z 
            default:Ascii = 8'h0;
        endcase
endmodule

