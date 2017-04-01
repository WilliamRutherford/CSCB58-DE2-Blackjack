

module blackJack(
    input clk,
	 input [5:0] pScore,
	 input [5:0] dScore,
    input swhit,   //card given to player
    input swpass, //player stops receiving/turn passed to dealer
    input swreset, //reset game to start
	 output dealerTurn,
	 output [2:0] stateValues,
	 output [1:0] gameResult,
	 output winner,
	 output loser
);

//wire [5:0] pScore;
//wire [5:0] dScore;
//wire [5:0] pHand;
//wire [5:0] dHand;
wire [2:0] state;
wire pBust;
wire dBust;
wire pBj;
wire dBj;
wire pHit;
wire dHit;
wire pWin;
wire pLose;
wire initiate;
wire [2:0] out;

winOrBust p(
   .clk(clk),
   .handTotal(pScore),
   .bust(pBust),
   .bj(pBj)
);

winOrBust d(
   .clk(clk),
	.handTotal(dScore),
   .bust(dBust),
   .bj(dBj)
);

wire gamereset;

wire hit;
wire pass;
wire win;
wire lose;

control c(.clk(clk), .initiate(initiate), .reset(swreset), .pHit(swhit), .pPass(swpass), .pBust(pBust), .dBust(dBust), .pBj(pBj), .dBj(dBj), 
			.state(state), .dHit(dHit), .hit(hit), .pass(pass), .pWin(win), .pLose(lose), .gamereset(gamereset));

gameState blackjackGame(.clk(clk),
    .reset(gamereset),
    .hit(hit),
    .pass(pass),
    .win(win),
    .lose(lose),
    .state(state),
    .initiate(initiate),
	 .result(out));

assign stateValues = out;
assign dealerTurn = dHit;
assign gameResult = {win,lose};
assign winner = win;
assign loser = lose;


endmodule

// CONTROL MODULE

module control(
    input clk,
    input initiate,
    input reset,
	 input pHit,
	 input pPass,
    input pBust,
    input dBust,
    input pBj,
	 input dBj,
    input [2:0] state,
    //output reg [5:0] pHand,
    //output reg [5:0] dHand,
    output reg dHit,
    output reg hit,
	 output reg pass,
    output reg pWin,
    output reg pLose,
	 output reg gamereset
    //output reg [5:0] pScore,
    //output reg [5:0] dScore
);



//turn states
//000 = Game start.  Score is 0, no hand dealt.
//001 = first card to player
//010 = second card to player
//011 = first card to house
//100 = player hits
//101 = player passes and dealer hits
//110 = payer wins (house loses)
//111 = player loses (house wins)
initial dHit <= 0;
always @(posedge clk) 
begin
hit <= pHit;
pass <= pPass;
//pWin <= 0;
//pLose <= 0;
gamereset <= reset;