module Deck_Draw(SW, KEY, LEDR, LEDG, CLOCK_50, LCD_ON, LCD_BLON, LCD_RW, LCD_EN, LCD_RS, LCD_DATA, HEX7, HEX6, HEX5, HEX4);
input  [2:0]KEY;
input [2:0] SW;
input LCD_ON;
input LCD_BLON;
input LCD_RW;
input LCD_EN;
input LCD_RS;
input [7:0] LCD_DATA;
input CLOCK_50;
output [8:0]LEDR;
output [1:0]LEDG;
output [6:0]HEX7;
output [6:0]HEX6;
output [6:0]HEX5;
output [6:0]HEX4;

hex_display d1(.IN(scoreD[3:0]), .OUT(HEX4));
hex_display d10(.IN(scoreD[5:4]), .OUT(HEX5));

hex_display p1(.IN(scoreP[3:0]), .OUT(HEX6));
hex_display p10(.IN(scoreP[5:4]), .OUT(HEX7));

wire [3:0] card_points;
wire [5:0] scoreP;
wire [5:0] scoreD;
wire counter;
wire dealerTurn;
wire win  = 0;
wire lose = 0;

	Deck deck1(.go(KEY[1]), .reset(KEY[0]), .clk(KEY[2]), .card_points(card_points), .result(LEDR[5:0]), .counter2(counter));
	adder a1(.clk(KEY[2]), .card_point(card_points), .out(scoreP), .hit(SW[2]), .pass(SW[1]), .reset(SW[0]), .count2(counter),
				.dealerTurn(dealerTurn));
	adderD a2(.clk(KEY[2]), .card_point(card_points), .out(scoreD), .reset(SW[0]), .count2(counter), .dealerTurn(dealerTurn));
	blackJack bjgame(.clk(KEY[2]), .pScore(scoreP), .dScore(scoreD), .swhit(SW[2]), .swpass(SW[1]), .swreset(SW[0]), .dealerTurn(dealerTurn), 
						  .stateValues(LEDR[8:6]), .gameResult(LEDG[1:0]), .winner(win), .loser(lose));
	
	blackjack_lcd display(.dValue(scoreD), .pValue(scoreP), .gameOver(lose), .playerWon(win), .clk(CLOCK_50), .currCard(result), 
								 .LCD_ON(LCD_ON), .LCD_BLON(LCD_BLON), .LCD_RW(LCD_RW), .LCD_EN(LCD_EN), .LCD_RS(LCD_RS), .LCD_DATA(LCD_DATA));

endmodule


module Deck(go, reset, clk, card_points, result, counter2);
	
	input go;
	input reset;
	input clk;
	output reg [3:0] card_points = 0;
	output reg [5:0] result = 0;
	output reg counter2 = 0;
	
	
	reg counter = 0;
	
	
	wire [5:0] out;
	reg lsrf_enable;
	
	reg [5:0] card_num;
	
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
	
	lfsr l1(.out(out), .enable(lsrf_enable), .clk(clk), .reset(reset));
	always @(posedge clk) 
	   begin
		 if(go && ~lsrf_enable) begin
		
		  lsrf_enable = 1'b1;
		
		end else if( lsrf_enable) begin
			counter = 1;
			result = out;
			
			card_num = result >> 2;
			
			if( card_num != 1'b0 && card_num < 4'd9 ) 
			    begin
			
				result = result + 4'b0100;
			    end
			 
			 else if( card_num != 1'b0 && card_num != 4'b1110)
				begin
				
			   result = result + 5'b01100;
			
			   end
		
		 end
		else if(reset)begin
			lsrf_enable = 0;
		end
	
	end 
	
	always @(posedge clk) 
	   begin
			case(result)
			6'b0000: card_points <= 4'd1;
			6'b0010: card_points <= 4'd2;
			6'b0011: card_points <= 4'd3;
			6'b0100: card_points <= 4'd4;
			6'b0101: card_points <= 4'd5;
			6'b0110: card_points <= 4'd6;
			6'b0111: card_points <= 4'd7;
			6'b1000: card_points <= 4'd8;
			6'b1001: card_points <= 4'd9;
			6'b1100: card_points <= 4'd10;
			6'b1101: card_points <= 4'd10;
			6'b1110: card_points <= 4'd10;
			6'b1111: card_points <= 4'd10;
			endcase
		end
	
	always @(posedge clk) 
	   begin
			if (result == 6'b0000xx && counter2 == 0)
			begin
				counter2 <= counter2 + 1;
			end else if (result == 6'b0000xx && counter2 == 1) begin
			   counter2 <= counter2 + 1;
				end
		end

endmodule

module lfsr    (
 out             ,  // Output of the counter
enable          ,  // Enable  for counter
clk             ,  // clock input
reset              // reset input
);

 //----------Output Ports--------------
 output [5:0] out;
 //------------Input Ports--------------

 input enable, clk, reset;
 //------------Internal Variables--------
 reg [5:0] out;
wire        linear_feedback;
reg [15:0] counter;
 
 //-------------Code Starts Here-------
 assign linear_feedback =  ! (out[4] ^ out[2]) ^ counter [8] ;
 assign linear_feedbac =  (out[1] ^ out[0]) ^ (!counter [3]) ;
always @(posedge clk)
begin
    counter = counter + linear_feedback;
	 if (reset) begin // active high reset
		out <= counter % 7'b0100000 ;
	end else if (enable) begin
		out <= {linear_feedbac,
				out[3],
				 out[2],out[1],
				 out[0], linear_feedback};
	   counter = counter + out;

	 end 
 end
 
 endmodule // End Of Module counter
 
 module card_display(IN, OUT);
    input [5:0] IN;
	 output reg [7:0] OUT;
	 
	 wire card_value = IN << 2;
	 
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
	
	 
	 always @(*)
	 begin
		case(card_value)
			4'b0000: OUT = 7'b0001000; //A
			4'b0010: OUT = 7'b0100100; //2
			4'b0011: OUT = 7'b0110000; //3
			4'b0100: OUT = 7'b0011001; //4
			4'b0101: OUT = 7'b0010010; //5
			4'b0110: OUT = 7'b0000010; //6
			4'b0111: OUT = 7'b1111000; //7
			4'b1000: OUT = 7'b0000000; //8
			4'b1001: OUT = 7'b0011000; //9
			4'b1100: OUT = 7'b1000000; //10
			4'b1101: OUT = 7'b1100001; //J
			4'b1110: OUT = 7'b0100011; //Q
			4'b1111: OUT = 7'b1001001; //K
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule

module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule
