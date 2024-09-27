module gpio #(parameter        nrOfInputs = 8,
              parameter        nrOfOutputs = 8,
              parameter [31:0] Base = 32'h40000000)
            ( input wire                    clock,
                                            reset,
              input wire [nrOfInputs-1:0]   externalInputs,
              output wire [nrOfOutputs-1:0] externalOutputs,

              // here the bus interface is defined
              input wire         beginTransactionIn,
                                 endTransactionIn,
                                 readNotWriteIn,
                                 dataValidIn,
                                 busErrorIn,
                                 busyIn,
              input wire [31:0]  addressDataIn,
              input wire [3:0]   byteEnablesIn,
              input wire [7:0]   burstSizeIn,
              output wire        endTransactionOut,
                                 dataValidOut,
                                 busErrorOut,
              output wire [31:0] addressDataOut);

  /*
   *
   * Here we flipflop all bus signals and define a "transaction active" indicator
   *
   */
  reg        s_transactionActiveReg, s_readNotWriteReg, s_beginTransactionReg;
  reg [31:2] s_addressDataInReg;
  reg [3:0]  s_byteEnablesReg;
  reg [7:0]  s_burstSizeReg;
  
  always @(posedge clock)
    begin
      s_beginTransactionReg  <= beginTransactionIn;
      s_transactionActiveReg <= (reset == 1'b1 || endTransactionIn == 1'b1) ? 1'b0 :
                                (beginTransactionIn == 1'b1) ? 1'b1 : s_transactionActiveReg;
      s_readNotWriteReg      <= (beginTransactionIn == 1'b1) ? readNotWriteIn : s_readNotWriteReg;
      s_addressDataInReg     <= (beginTransactionIn == 1'b1) ? addressDataIn[31:2] : s_addressDataInReg;
      s_byteEnablesReg       <= (beginTransactionIn == 1'b1) ? byteEnablesIn : s_byteEnablesReg;
      s_burstSizeReg         <= (beginTransactionIn == 1'b1) ? burstSizeIn : s_burstSizeReg;
    end
  
  /*
   *
   * Here we determine the control and error signals
   *
   */
  wire s_isMyAction      = (s_addressDataInReg == Base[31:2]) ? s_transactionActiveReg : 1'b0;
  wire s_isCorrectAction = (s_byteEnablesReg == 4'hF && s_burstSizeReg == 8'd0) ? s_isMyAction : 1'b0;
  wire s_isWriteAction   = s_isMyAction & s_isCorrectAction & ~s_readNotWriteReg;
  wire s_isReadAction    = s_isMyAction & s_isCorrectAction & s_readNotWriteReg;
  
  assign busErrorOut = s_isMyAction & ~s_isCorrectAction;
  
  /*
   *
   * Here we define the write action
   *
   */
  reg [nrOfOutputs-1:0] s_externalOutputsReg;
  
  assign externalOutputs = s_externalOutputsReg;
  
  always @(posedge clock)
    s_externalOutputsReg <= (reset == 1'b1) ? {nrOfOutputs{1'b0}} :
                            (s_isWriteAction == 1'b1 && dataValidIn == 1'b1) ? addressDataIn[nrOfOutputs-1:0] :
                            s_externalOutputsReg;

  /*
   *
   * Here we define the input signals
   *
   */
  reg [nrOfInputs-1:0] s_externalInputsReg;
  reg s_dataValidOutReg, s_endTransReg;
  reg [31:0] s_addressDataOutReg;
  
  assign dataValidOut      = s_dataValidOutReg;
  assign endTransactionOut = s_endTransReg;
  assign addressDataOut    = s_addressDataOutReg;
  
  always @(posedge clock) 
    begin
      s_externalInputsReg <= externalInputs;
      s_dataValidOutReg   <= (reset == 1'b1) ? 1'b0 :
                             (s_isReadAction == 1'b1 && s_beginTransactionReg == 1'b1) ? 1'b1 :
                             (busyIn == 1'b1) ? s_dataValidOutReg : 1'b0;
      s_addressDataOutReg <= (reset == 1'b1) ? 32'd0 :
                             (s_isReadAction == 1'b1 && s_beginTransactionReg == 1'b1) ? { {(32-nrOfOutputs){1'b0}} , s_externalInputsReg } :
                             (busyIn == 1'b1) ? s_addressDataOutReg : 32'd0;
      s_endTransReg       <= s_dataValidOutReg & ~busyIn;
    end               
endmodule
