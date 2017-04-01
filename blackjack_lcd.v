module blackjack_lcd(
  input [4:0]dValue,
  input [4:0]pValue,
  input gameOver,
  input playerWon,
  input clk,
  input [5:0]currCard,
  output LCD_ON,    // LCD Power ON/OFF
  output LCD_BLON,    // LCD Back Light ON/OFF
  output LCD_RW,    // LCD Read/Write Select, 0 = Write, 1 = Read
  output LCD_EN,    // LCD Enable
  output LCD_RS,    // LCD Command/Data Select, 0 = Command, 1 = Data
  inout [7:0] LCD_DATA    // LCD Data bus 8 bits
  );

wire RESET_DELAY;

wire currCardMesg;

determineCard dc0(.card(currCard), .mesg(currCardMesg));

warm_up_time w0 ( .clk(clk), .ready(RESET_DELAY));

assign LCD_ON = 1'b1;
assign LCD_BLON = 1'b1;

reg [125:0] mesg;
wire [17:0] pScore;
wire [17:0] dScore;

determineScore dsp( .value(pValue), .mesg(pScore));
determineScore dsd( .value(dValue), .mesg(dScore));

LCD_TEST u1(
// Host Side
   .iCLK(clk),
   .iRST_N(RESET_DELAY),
	.mesg(mesg),
	.pScore(pScore),
	.dScore(dScore),
// LCD Side
   .LCD_DATA(LCD_DATA),
   .LCD_RW(LCD_RW),
   .LCD_EN(LCD_EN),
   .LCD_RS(LCD_RS)
);

always@(*)
begin
  if(gameOver == 1'b0 && playerWon == 1'b0)
  begin
    //  Curr Card: XX 
    mesg <= {9'h143, 9'h175, 9'h172, 9'h172, 9'h120, 9'h143, 9'h161, 9'h172, 9'h164, 9'h13A, 9'h120, currCardMesg, 9'h120};	
  end
  else if (gameOver == 1'b1 && playerWon == 1'b1)
  begin
    //You Won! len = 8, line_len = 14, diff = 6, indent: 3 spaces per side
    mesg <= {9'h120, 9'h120, 9'h120, 9'h159, 9'h16F, 9'h175, 9'h120, 9'h157 , 9'h16F , 9'h16E , 9'h121, 9'h120, 9'h120, 9'h120};
  
  end
  else if (gameOver == 1'b1 && playerWon == 1'b0)
  begin
  
  //Dealer Won   len = 10, line_len = 14, diff =46, indent 2 spaces per side
    mesg <= {9'h120, 9'h120, 9'h144, 9'h165, 9'h161, 9'h16C, 9'h165, 9'h172, 9'h120, 9'h157 , 9'h16F , 9'h16E, 9'h120, 9'h120};
  
  end
  
  else
  begin
  
  mesg <= {9'h13F, 9'h13F, 9'h13F, 9'h13F, 9'h13F, 9'h13F, 9'h13F, 9'h13F, 9'h13F, 9'h13F , 9'h13F , 9'h13F, 9'h13F, 9'h13F};
  
  end


end
  
endmodule

module warm_up_time(
  input clk,
  output reg ready
  );
  
reg [19:0] time_took;

always@(posedge clk)
begin
  if(time_took < 20'hFFFFF)
  begin
    time_took <= time_took + 1'b1;
	 ready <= 1'b0;
  end
  else
  ready <= 1'b1;
end


endmodule

module	LCD_TEST (	//	Host Side
					iCLK,iRST_N, mesg, pScore, dScore,
					//	LCD Side
					LCD_DATA,LCD_RW,LCD_EN,LCD_RS	);
//	Host Side
input			iCLK,iRST_N;
input [125:0] mesg;
input [17:0] pScore;
input [17:0] dScore;
//	LCD Side
output	[7:0]	LCD_DATA;
output			LCD_RW,LCD_EN,LCD_RS;
//	Internal Wires/Registers
reg	[5:0]	LUT_INDEX;
reg	[8:0]	LUT_DATA;
reg	[5:0]	mLCD_ST;
reg	[17:0]	mDLY;
reg			mLCD_Start;
reg	[7:0]	mLCD_DATA;
reg			mLCD_RS;
wire		mLCD_Done;

parameter	LCD_INTIAL	=	0;
parameter	LCD_LINE1	=	5;
parameter	LCD_CH_LINE	=	LCD_LINE1+16;
parameter	LCD_LINE2	=	LCD_LINE1+16+1;
parameter	LUT_SIZE	=	LCD_LINE1+32+1;

always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		LUT_INDEX	<=	0;
		mLCD_ST		<=	0;
		mDLY		<=	0;
		mLCD_Start	<=	0;
		mLCD_DATA	<=	0;
		mLCD_RS		<=	0;
	end
	else
	begin
		if(LUT_INDEX<LUT_SIZE)
		begin
			case(mLCD_ST)
			0:	begin
					mLCD_DATA	<=	LUT_DATA[7:0];
					mLCD_RS		<=	LUT_DATA[8];
					mLCD_Start	<=	1;
					mLCD_ST		<=	1;
				end
			1:	begin
					if(mLCD_Done)
					begin
						mLCD_Start	<=	0;
						mLCD_ST		<=	2;					
					end
				end
			2:	begin
					if(mDLY<18'h3FFFE)
					mDLY	<=	mDLY+1;
					else
					begin
						mDLY	<=	0;
						mLCD_ST	<=	3;
					end
				end
			3:	begin
					LUT_INDEX	<=	LUT_INDEX+1;
					mLCD_ST	<=	0;
				end
			endcase
		end
	end
end

always
begin
	case(LUT_INDEX)
	//	Initial
	LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
	LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
	LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
	LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
	LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
	//	Line 1
	LCD_LINE1+0:	LUT_DATA	<=	9'h120;	//Space
	LCD_LINE1+1:	LUT_DATA	<=	mesg[8:0];
	LCD_LINE1+2:	LUT_DATA	<=	mesg[17:9];
	LCD_LINE1+3:	LUT_DATA	<=	mesg[26:18];
	LCD_LINE1+4:	LUT_DATA	<=	mesg[35:27];
	LCD_LINE1+5:	LUT_DATA	<=	mesg[44:36];
	LCD_LINE1+6:	LUT_DATA	<=	mesg[53:45];
	LCD_LINE1+7:	LUT_DATA	<=	mesg[62:54];
	LCD_LINE1+8:	LUT_DATA	<=	mesg[71:63];
	LCD_LINE1+9:	LUT_DATA	<=	mesg[80:72];
	LCD_LINE1+10:	LUT_DATA	<=	mesg[89:81];
	LCD_LINE1+11:	LUT_DATA	<=	mesg[98:90];
	LCD_LINE1+12:	LUT_DATA	<=	mesg[107:99];
	LCD_LINE1+13:	LUT_DATA	<=	mesg[116:108];
	LCD_LINE1+14:	LUT_DATA	<=	mesg[125:117];
	LCD_LINE1+15:	LUT_DATA	<=	9'h120;
	//	Change Line
	LCD_CH_LINE:	LUT_DATA	<=	9'h0C0;
	//	Line 2
	LCD_LINE2+0:	LUT_DATA	<=	9'h120; //Space
	LCD_LINE2+1:	LUT_DATA	<=	9'h120; //Space
	LCD_LINE2+2:	LUT_DATA	<=	9'h150; //P
	LCD_LINE2+3:	LUT_DATA	<=	9'h13A; //:
	LCD_LINE2+4:	LUT_DATA	<=	9'h120; //Space
	LCD_LINE2+5:	LUT_DATA	<=	pScore[17:9] ; //Player 10s
	LCD_LINE2+6:	LUT_DATA	<=	pScore[8:0]; //Player 1s
	LCD_LINE2+7:	LUT_DATA	<=	9'h120; //Space
	LCD_LINE2+8:	LUT_DATA	<=	9'h120; //Space
	LCD_LINE2+9:	LUT_DATA	<=	9'h144; //D
	LCD_LINE2+10:	LUT_DATA	<=	9'h13A; //:
	LCD_LINE2+11:	LUT_DATA	<=	9'h120; //Space
	LCD_LINE2+12:	LUT_DATA	<=	dScore[17:9]; //Dealer 1s
	LCD_LINE2+13:	LUT_DATA	<=	dScore[8:0]; //Dealer 10s	
	LCD_LINE2+14:	LUT_DATA	<=	9'h120; //Space
	LCD_LINE2+15:	LUT_DATA	<=	9'h120; //Space
	endcase
end

LCD_Controller 		u0	(	//	Host Side
							.iDATA(mLCD_DATA),
							.iRS(mLCD_RS),
							.iStart(mLCD_Start),
							.oDone(mLCD_Done),
							.iCLK(iCLK),
							.iRST_N(iRST_N),
							//	LCD Interface
							.LCD_DATA(LCD_DATA),
							.LCD_RW(LCD_RW),
							.LCD_EN(LCD_EN),
							.LCD_RS(LCD_RS)	);

endmodule

module determineCard( card, mesg);
input [5:0]card;
output reg [17:0] mesg;

   //Ace = 0000xx
	// ? =  0001xx
	// 2 =  0010xx
	// 3 =  0011xx
	// 4 =  0100xx
	// 5 =  0101xx
	// 6 =  0110xx
	// 7 =  0111xx
	// 8 =  1000xx
	// 9 =  1001xx
	// ? =  1010xx
	// ? =  1011xx
	// 10 = 1100xx
	// J =  1101xx
	// Q =  1110xx
	// K =  1111xx
	
	assign card_value = card >> 3'd2;
	 
	 always @(*)
	 begin
		case(card_value)
			4'b0000: mesg = {9'h120, 9'h141} ; //A
			4'b0010: mesg = {9'h120, 9'h132}; //2
			4'b0011: mesg = {9'h120, 9'h133}; //3
			4'b0100: mesg = {9'h120, 9'h134}; //4
			4'b0101: mesg = {9'h120, 9'h135}; //5
			4'b0110: mesg = {9'h120, 9'h136}; //6
			4'b0111: mesg = {9'h120, 9'h137}; //7
			4'b1000: mesg = {9'h120, 9'h138}; //8
			4'b1001: mesg = {9'h120, 9'h139}; //9
			4'b1100: mesg = {9'h131, 9'h130}; //10
			4'b1101: mesg = {9'h120, 9'h14A}; //J
			4'b1110: mesg = {9'h120, 9'h151}; //Q
			4'b1111: mesg = {9'h120, 9'h14B}; //K
			
			default: mesg = {9'h13F, 9'h13F}; //??
		endcase

	end


endmodule 

module determineScore( value, mesg);
input [4:0] value;
output reg [17:0] mesg;

always@(*)
begin
  case(value)
    5'b00000: mesg <= {9'h120, 9'h130 }; //0
	 5'b00001: mesg <= {9'h120, 9'h131 }; //1
	 5'b00010: mesg <= {9'h120, 9'h132 }; //2
	 5'b00011: mesg <= {9'h120, 9'h133 }; //3
	 5'b00100: mesg <= {9'h120, 9'h134 }; //4
	 5'b00101: mesg <= {9'h120, 9'h135 }; //5
	 5'b00110: mesg <= {9'h120, 9'h136 }; //6
	 5'b00111: mesg <= {9'h120, 9'h137 }; //7
	 5'b01000: mesg <= {9'h120, 9'h138 }; //8
	 5'b01001: mesg <= {9'h120, 9'h139 }; //9
	 5'b01010: mesg <= {9'h120, 9'h130 }; //10
	 5'b01011: mesg <= {9'h131, 9'h131 }; //11
	 5'b01100: mesg <= {9'h131, 9'h132 }; //12
	 5'b01101: mesg <= {9'h131, 9'h133 }; //13
	 5'b01110: mesg <= {9'h131, 9'h134 }; //14
	 5'b01111: mesg <= {9'h131, 9'h135 }; //15
	 5'b10000: mesg <= {9'h131, 9'h136 }; //16
	 5'b10001: mesg <= {9'h131, 9'h137 }; //17
	 5'b10010: mesg <= {9'h131, 9'h138 }; //18
	 5'b10011: mesg <= {9'h131, 9'h139 }; //19
	 5'b10100: mesg <= {9'h132, 9'h130 }; //20
	 5'b10101: mesg <= {9'h132, 9'h131 }; //21
	 5'b10110: mesg <= {9'h132, 9'h132 }; //22
	 5'b10111: mesg <= {9'h132, 9'h133 }; //23
	 5'b11000: mesg <= {9'h132, 9'h134 }; //24
	 5'b11001: mesg <= {9'h132, 9'h135 }; //25
	 5'b11010: mesg <= {9'h132, 9'h136 }; //26
	 5'b11011: mesg <= {9'h132, 9'h137 }; //27
	 5'b11100: mesg <= {9'h132, 9'h138 }; //28
	 5'b11101: mesg <= {9'h132, 9'h139 }; //29
	 5'b11110: mesg <= {9'h133, 9'h130 }; //30
	 5'b11111: mesg <= {9'h133, 9'h131 }; //31
	 endcase
end

endmodule
