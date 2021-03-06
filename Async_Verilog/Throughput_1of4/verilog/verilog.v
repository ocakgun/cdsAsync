// Driver to send / receive tokens into an e1of4 FIFO

module Throughput_1of4(Tx, Txe, Rx, Rxe,  // Circuit Tx/Rx signals
                       RESET, VDD, GND);
inout VDD, GND;
output RESET;
output [3:0] Tx;
input Txe;
input [3:0] Rx;
output Rxe;
////////////////////////////////////////////////
parameter RST_HOLD=1000;  // Assume ps timescale
parameter NO_TOKENS=10;   // # Tokens to insert
parameter FINISH=0;

integer TxTokenCount;
integer RxTokenCount;
integer i;
////////////////////////////////////////////////
reg resetReg;
reg goReg;
reg [1:0] TxReg;

reg [1:0] RxReg;
wire [1:0] dataRx;
wire validRx;

reg allTokensRxd;
////////////////////////////////////////////////
Bin2QDI_1of4          Transmit (Tx,     TxReg,   goReg, Txe, resetReg, VDD, GND);
QDI2Bin_1of4          Receive  (dataRx, validRx, Rxe,   Rx,  resetReg, VDD, GND);
assign RESET = resetReg;
////////////////////////////////////////////////
task Init;
    begin
        i = 0;
        RxTokenCount = 0;
        TxTokenCount = 0;

        resetReg <= 1'b1;  // Reset not asserted yet
        goReg <= 1'b0;     // Nothing being sent yet
        TxReg <= 2'b11;    // Clear Tx Data Register
        RxReg <= 2'b0;     // Clear Rx Data Register
        allTokensRxd <= 1'b0; 

        #1; // Allow initial and final conditions to be interchangable
        $display(" %M: %t ps - Asserting Reset...", $time); 
        resetReg <= 1'b0;  // Assert Reset
        #RST_HOLD;         
        $display(" %M: %t ps - De-Asserting Reset...", $time); 
        resetReg <= 1'b1;  // Stop Asserting Reset
        #RST_HOLD;
    end
endtask

task SendTokens;            // Task to send tokens
    input [1:0] data;   
    begin
        wait(Txe);
        TxReg <= data;
        goReg <= 1'b1;
        TxTokenCount = TxTokenCount + 1;
        $display(" %M: %t ps - Sent token w/ data = %b.", $time, TxReg);
		@(negedge goReg);
    end
endtask

////////////////////////////////////////////////
// Main Description 
////////////////////////////////////////////////
initial begin
    Init;

    for (i = 0; i < NO_TOKENS; i = i + 1) begin
        SendTokens(2'b11);
    end
    
    wait(RxTokenCount==TxTokenCount);
    wait(~validRx);
    if (FINISH) begin
        #RST_HOLD;
        $finish();
    end
end

always @(posedge validRx) begin
    RxTokenCount=RxTokenCount+1;
    RxReg <= dataRx;
    $display(" %M: %t - Received token %d, data = %b", $time, RxTokenCount, dataRx);
end

always @(negedge Txe) begin
    goReg <= 1'b0;
end

endmodule

