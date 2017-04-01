

module adder(clk, card_point, out, hit, pass, reset, count2, dealerTurn);
input [3:0] card_point;
input hit, pass, reset, clk, count2, dealerTurn;
output reg [5:0] out;

reg count = 0;
reg [5:0] out_n = 0;



always @(posedge clk)
begin
if(reset == 1) begin
count = 0;
out = 6'd0;
out_n = 6'd0;
end else if(count == 0 && reset == 0 && dealerTurn == 0) begin
out_n = out_n + card_point;
//count = count +1'd1;
end else if (count == 1 && reset == 0 && dealerTurn == 0) begin
out_n = out_n + card_point;
count = count + 1'd1;
//out = out_n;
end else if(pass==0 && hit==1 && count > 1 && count2==1 && card_point==1 && out_n < 4'd11 && dealerTurn == 0)begin
out_n = out_n + card_point +4'd10;
//out = out_n;
end else if(pass==0 && hit==1 && count > 1 && dealerTurn == 0) begin
out_n = out_n + card_point;
//out = out_n;
//end else if(pass==1 || hit==0 && count > 1 && dealerTurn == 0) begin
//out = out_n;
end
out = out_n;
end
endmodule

module adderD(clk, card_point, out, reset, count2, dealerTurn);
input [3:0] card_point;
input reset, clk, count2, dealerTurn;
output reg [5:0] out;

reg count = 0; 
reg [5:0] out_n = 0;

always @(posedge clk)
begin
if(reset == 1) begin
count = 0;
out = 6'd0;
out_n = 6'd0;
end else if(count == 0 && reset == 0 && dealerTurn == 1) begin
out_n = out_n + card_point;
count = count +1'd1;
//out = out_n;
end else if(count != 0 && count2==1 && card_point==1 && out_n < 4'd11 && dealerTurn == 1)begin
out_n = out_n + card_point +4'd10;
//out = out_n;
end else if(count != 0 && out_n < 5'd17 && dealerTurn == 1) begin
out_n = out_n + card_point;
//out = out_n;
//end else if(count != 0 && out_n >= 17 && dealerTurn == 1) begin
//out <= out_n;
end
out = out_n;
end
endmodule
