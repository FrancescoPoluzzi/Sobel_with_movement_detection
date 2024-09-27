module ramDmaCi #( parameter [7:0] customIdDMA = 8'h00,  parameter [7:0] customIdSobel = 8'h01)
                 ( input wire         start,
                                      clock,
                                      reset,
                   input wire [31:0]  valueA,
                                      valueB,
                   input wire [7:0]   ciN,
                   output wire        done ,
                   output wire [31:0] result,

                   // Here the required bus signals are defined
                   output wire        requestTransaction,
                   input wire         transactionGranted,
                   input wire         endTransactionIn,
                                      dataValidIn,
                                      busErrorIn,
                                      busyIn,
                   input wire [31:0]  addressDataIn,
                   output reg         beginTransactionOut,
                                      readNotWriteOut,
                                      endTransactionOut,
                   output wire        dataValidOut,
                   output reg [3:0]   byteEnablesOut,
                   output reg [7:0]   burstSizeOut,
                   output wire [31:0] addressDataOut);

  /*
   *
   * Here we define the custom instruction control signals
   *
   */
  wire s_isMyCi = (ciN == customIdDMA) ? start : 1'b0;
  wire s_isSramWrite = (valueA[31:10] == 22'd0) ? s_isMyCi & valueA[9] : 1'b0;
  wire s_isSramRead  = s_isMyCi & ~valueA[9];
  reg s_isSramReadReg;
  
  assign done   = (s_isMyCi & valueA[9]) | s_isSramReadReg | s_isMyCiSobel;
  
  always @(posedge clock) s_isSramReadReg = ~reset & s_isSramRead;

  /*
   *
   * Here we define the sdram control registers
   *
   */
  reg[31:0] s_busStartAddressReg;
  reg[8:0]  s_memoryStartAddressReg;
  reg[9:0]  s_blockSizeReg;
  reg[7:0]  s_usedBurstSizeReg;
  //register that holds the treshold value for the sobel filter. 
  //The treshold value idetermines the sensibility of the edge detection
  //The higher the value the less edges are detected (0 to 255)
  reg[7:0]  s_sobelTresholdReg;
  
  always @(posedge clock)
    begin
      s_busStartAddressReg    <= (reset == 1'b1) ? 32'd0 :
                                 (s_isMyCi == 1'b1 && valueA[12:9] == 4'b0011) ? valueB : s_busStartAddressReg;
      s_memoryStartAddressReg <= (reset == 1'b1) ? 9'd0 :
                                 (s_isMyCi == 1'b1 && valueA[12:9] == 4'b0101) ? valueB[8:0] : s_memoryStartAddressReg;
      s_blockSizeReg          <= (reset == 1'b1) ? 10'd0 :
                                 (s_isMyCi == 1'b1 && valueA[12:9] == 4'b0111) ? valueB[9:0] : s_blockSizeReg;
      s_usedBurstSizeReg      <= (reset == 1'b1) ? 8'd0 :
                                 (s_isMyCi == 1'b1 && valueA[12:9] == 4'b1001) ? valueB[7:0] : s_usedBurstSizeReg;
      s_sobelTresholdReg      <= (reset==1'b1)  ? 8'd127 : 
                                 (s_isMyCi == 1'b1 && valueA[12:9] == 4'b1101) ? valueB[7:0] : s_sobelTresholdReg;
    end

  /*
   *
   * Here we define all bus-in registers
   *
   */
  reg s_endTransactionInReg, s_dataValidInReg;
  reg [31:0] s_addressDataInReg;
  
  always @(posedge clock)
    begin
      s_endTransactionInReg <= endTransactionIn;
      s_dataValidInReg      <= dataValidIn;
      s_addressDataInReg    <= addressDataIn;
    end

  /*
   *
   * Here we map the dual-ported memory
   *
   */
  
  reg [9:0] s_ramCiAddressReg;
  wire s_ramCiWriteEnable;
  wire [31:0] s_busRamData;
  
  dualPortSSRAM #( .bitwidth(32),
                   .nrOfEntries(668)) memory
                 ( .clockA(clock), 
                   .clockB(~clock),
                   .writeEnableA(writeEnableSobel), 
                   .writeEnableB(s_ramCiWriteEnable),
                   .addressA(addressSobel), 
                   .addressB(s_ramCiAddressReg),
                   .dataInA(s_sobelDataInReg), 
                   .dataInB(s_addressDataInReg),
                   .dataOutA(sobelDataOut), 
                   .dataOutB(s_busRamData));
  
  /*
   *
   * Here we define the dma-state-machine
   *
   */
  localparam [3:0] IDLE = 4'd0;
  localparam [3:0] INIT = 4'd1;
  localparam [3:0] REQUEST_BUS = 4'd2;
  localparam [3:0] SET_UP_TRANSACTION = 4'd3;
  localparam [3:0] DO_READ = 4'd4;
  localparam [3:0] WAIT_END = 4'd5;
  localparam [3:0] DO_WRITE = 4'd6;
  localparam [3:0] END_TRANSACTION_ERROR = 4'd7;
  localparam [3:0] END_WRITE_TRANSACTION = 4'd8;
  
  reg [3:0] s_dmaCurrentStateReg, s_dmaNextState;
  reg       s_busErrorReg;
  reg       s_isReadBurstReg;
  reg[8:0]  s_wordsWrittenReg;
  
  // a dma action is requested by the ci:
  wire s_requestDmaIn = (valueA[12:9] == 4'b1011) ? s_isMyCi & valueB[0] & ~valueB[1] : 1'b0;
  wire s_requestDmaOut = (valueA[12:9] == 4'b1011) ? s_isMyCi & ~valueB[0] & valueB[1] : 1'b0;
  wire s_dmaIsBusy = (s_dmaCurrentStateReg == IDLE) ? 1'b0 : 1'b1;
  wire s_dmaDone;
  
  // here we define the next state
  always @*
    case (s_dmaCurrentStateReg)
      IDLE                  : s_dmaNextState <= (s_requestDmaIn == 1'b1 || s_requestDmaOut == 1'b1) ? INIT : IDLE;
      INIT                  : s_dmaNextState <= REQUEST_BUS;
      REQUEST_BUS           : s_dmaNextState <= (transactionGranted == 1'b1) ? SET_UP_TRANSACTION : REQUEST_BUS;
      SET_UP_TRANSACTION    : s_dmaNextState <= (s_isReadBurstReg == 1'b1) ? DO_READ : DO_WRITE;
      DO_READ               : s_dmaNextState <= (busErrorIn == 1'b1) ? WAIT_END:
                                                (s_endTransactionInReg == 1'b1 && s_dmaDone == 1'b1) ? IDLE :
                                                (s_endTransactionInReg == 1'b1) ? REQUEST_BUS : DO_READ;
      WAIT_END              : s_dmaNextState <= (s_endTransactionInReg == 1'b1) ? IDLE : WAIT_END;
      DO_WRITE              : s_dmaNextState <= (busErrorIn == 1'b1) ? END_TRANSACTION_ERROR :
                                                (s_wordsWrittenReg[8] == 1'b1 && busyIn == 1'b0) ? END_WRITE_TRANSACTION : DO_WRITE;
      END_WRITE_TRANSACTION : s_dmaNextState <= (s_dmaDone == 1'b1) ? IDLE : REQUEST_BUS;
      default               : s_dmaNextState <= IDLE;
    endcase
  
  always @(posedge clock)
    begin
      s_dmaCurrentStateReg <= (reset == 1'b1) ? IDLE : s_dmaNextState;
      s_busErrorReg        <= (reset == 1'b1 || s_dmaCurrentStateReg == INIT) ? 1'b0 :
                              (s_dmaCurrentStateReg == WAIT_END || s_dmaCurrentStateReg == END_TRANSACTION_ERROR) ? 1'b1 : s_busErrorReg;
      s_isReadBurstReg     <= (s_dmaCurrentStateReg == IDLE) ? s_requestDmaIn : s_isReadBurstReg;
    end

  /*
   *
   * Here we define the shadow registers used by the dma-controller
   *
   */
  reg[31:0] s_busStartAddressShadowReg;
  reg[9:0]  s_blockSizeShadowReg;
  wire s_doBusWrite = (s_dmaCurrentStateReg == DO_WRITE) ? ~busyIn & ~s_wordsWrittenReg[8] : 1'b0;

  /* the second condition is the special case where the end of transaction collides with the last data valid in */
  assign s_dmaDone = (s_blockSizeShadowReg == 10'd0 ||
                      (s_blockSizeShadowReg == 10'd1 && s_endTransactionInReg == 1'b1 && s_dataValidInReg == 1'b1)) ? 1'b1 : 1'b0;
  assign s_ramCiWriteEnable = (s_dmaCurrentStateReg == DO_READ) ? s_dataValidInReg : 1'b0;
  
  always @(posedge clock)
    begin 
      //at end of window line, increase buststartaddress to skip the image line
      s_busStartAddressShadowReg <= (s_dmaCurrentStateReg == INIT) ? s_busStartAddressReg :
                                    ((s_dmaCurrentStateReg==DO_READ && s_endTransactionInReg == 1'b1 )||(s_dmaCurrentStateReg==END_WRITE_TRANSACTION) ) ?
                                     s_busStartAddressShadowReg + 32'd640 : s_busStartAddressShadowReg;
      s_blockSizeShadowReg       <= (s_dmaCurrentStateReg == INIT) ? s_blockSizeReg :
                                    (s_ramCiWriteEnable == 1'b1 || s_doBusWrite == 1'b1) ? s_blockSizeShadowReg - 10'd1 : s_blockSizeShadowReg;
      s_ramCiAddressReg          <= (s_dmaCurrentStateReg == INIT) ? {1'b0,s_memoryStartAddressReg} :
                                    (s_ramCiWriteEnable == 1'b1 || s_doBusWrite == 1'b1) ? s_ramCiAddressReg + 10'd1 : s_ramCiAddressReg;
    end
  
  /*
   *
   * Here we define the bus-out signals
   *
   */
  reg   s_dataOutValidReg;
  reg [31:0] s_addressDataOutReg;
  wire [9:0] s_maxBurstSize = {2'd0,s_usedBurstSizeReg} + 10'd1;
  wire [9:0] s_restingBlockSize = s_blockSizeShadowReg - 10'd1;
  wire [7:0] s_usedBurstSize = (s_blockSizeShadowReg > s_maxBurstSize) ? s_usedBurstSizeReg : s_restingBlockSize[7:0];
  
  assign requestTransaction = (s_dmaCurrentStateReg == REQUEST_BUS) ? 1'd1 : 1'd0;
  assign dataValidOut = s_dataOutValidReg;
  assign addressDataOut = s_addressDataOutReg;
  
  always @(posedge clock)
    begin
      beginTransactionOut <= (s_dmaCurrentStateReg == SET_UP_TRANSACTION) ? 1'b1 : 1'b0;
      readNotWriteOut     <= (s_dmaCurrentStateReg == SET_UP_TRANSACTION) ? s_isReadBurstReg : 1'b0;
      byteEnablesOut      <= (s_dmaCurrentStateReg == SET_UP_TRANSACTION) ? 4'hF : 4'd0;
      burstSizeOut        <= (s_dmaCurrentStateReg == SET_UP_TRANSACTION) ? s_usedBurstSize : 8'd0;
      s_addressDataOutReg <= (s_dmaCurrentStateReg == DO_WRITE && busyIn == 1'b1) ? s_addressDataOutReg :
                             (s_doBusWrite == 1'b1) ? s_busRamData : 
                             (s_dmaCurrentStateReg == SET_UP_TRANSACTION) ? {s_busStartAddressShadowReg[31:2],2'd0} : 32'd0;
      s_wordsWrittenReg   <= (s_dmaCurrentStateReg == SET_UP_TRANSACTION) ? {1'b0,s_usedBurstSize} : 
                             (s_doBusWrite == 1'b1) ? s_wordsWrittenReg - 9'd1 : s_wordsWrittenReg;
      endTransactionOut   <= (s_dmaCurrentStateReg == END_TRANSACTION_ERROR || s_dmaCurrentStateReg == END_WRITE_TRANSACTION) ? 1'b1 : 1'b0;
      s_dataOutValidReg   <= (busyIn == 1'b1 && s_dmaCurrentStateReg == DO_WRITE) ? s_dataOutValidReg : s_doBusWrite;
    end

  /*
   *
   * Here we define the result value
   *
   */
  reg[31:0] s_result;
  
  always @*
    case (valueA[12:10])
      3'b000    : s_result <= {31'd0,sobelStatusRegister};
      3'b001    : s_result <= s_busStartAddressReg;
      3'b010    : s_result <= {23'd0,s_memoryStartAddressReg};
      3'b011    : s_result <= {22'd0,s_blockSizeReg};
      3'b100    : s_result <= {24'd0,s_usedBurstSizeReg};
      3'b101    : s_result <= {30'd0,s_busErrorReg,s_dmaIsBusy};
      default   : s_result <= 32'd0;
    endcase
  
  assign result = (s_isSramReadReg == 1'b1) ? s_result : 32'd0;

  // SOBEL with movement detection 

  wire isMyCiSobel = (ciN == customIdSobel) ? start : 1'b0;

  reg s_isMyCiSobel;
  always @(posedge clock) s_isMyCiSobel <= (reset==1'b1) ? 1'b0 : isMyCiSobel;
                                            
  reg [2:0] counterSobel;                  // counter for the 3x3 window
  wire sobel_done, counter_done;           // flags for the end of the sobel computation
  wire [4:0] windowIndex;
  
  assign windowIndex = (counterSobel == 3'd0||counterSobel == 3'd1) ? 5'd0:
                       (counterSobel == 3'd2) ? 5'd4:
                       (counterSobel == 3'd3) ? 5'd6:
                       (counterSobel == 3'd4) ? 5'd10:
                       (counterSobel == 3'd5) ? 5'd12:
                        5'd16;
  reg [7:0] window [17:0];                 // 3x6 window  
  reg [8:0]  initialCounterWord;                   // counter for the pixels on the image, it extends the 32-bit address to a 8-bit one
  reg [7:0] counterWindow;                 // counter for the positions taken by the window 
  wire [31:0] sobelDataOut;
  reg [31:0] s_sobelDataOut;              // output of the memory to the sobel modules
  always @* s_sobelDataOut <= sobelDataOut;
  wire [31:0] s_sobelDataIn;                 
  reg [31:0] s_sobelDataInReg;            // input of the memory from the sobel module
  always @(posedge clock) s_sobelDataInReg <= s_sobelDataIn;   
  // start address for the sobel filtering, it is either 0 or 238, the opposite of the start address of the dma, to allow the ping pong buffer
  wire [9:0] sobelMemoryStartAddress;
  assign sobelMemoryStartAddress = (s_memoryStartAddressReg==9'd0)? 10'd238 : 10'd0; // start address for the sobel memory allowing the ping pong buffer. 
  wire [9:0] addressSobel = (s_SobelCurrentStateReg == SOBEL_FILTER) ? addressSobelWrite :
                              (s_SobelCurrentStateReg==FILL_COMPARISON_BUFFER || (s_SobelCurrentStateReg==FILL_WINDOW && counterSobel==3'd7))? addressSobelComparison :
                               addressSobelRead;
  reg [9:0] addressSobelRead;          // address to read the from the memory and fill the window
  reg [9:0] addressSobelWrite;         // address to write the sobel+movement detection output
  reg [9:0] addressSobelComparison;   // address to read the pixels of the previous frame, to perform the movement detection
  wire writeEnableSobel;
  assign writeEnableSobel = (s_SobelCurrentStateReg == SOBEL_FILTER ) ? 1'b1 : 1'b0; // enable the write operation only when the sobel filter is applied
  assign counter_done = (counterSobel == 3'd7) ? 1'b1 : 1'b0;  // when the window has been filled
  assign sobel_done = (counterWindow == 8'd223) ? 1'b1 : 1'b0; // when the whole image has been processed

  localparam [1:0] IDLE_SOBEL = 2'd0;                 // idle state
  localparam [1:0] FILL_WINDOW = 2'd1;              // fill the 3x6 window
  localparam [1:0] FILL_COMPARISON_BUFFER = 2'd2;  // read the same pixel of the previous frame for movement detection
  localparam [1:0] SOBEL_FILTER = 2'd3;           // apply the sobel filter for 4 pixels at a time and perform the movement detection

  reg [1:0] s_SobelCurrentStateReg, s_SobelNextState;
  wire sobelStatusRegister;
  assign sobelStatusRegister = (s_SobelCurrentStateReg == IDLE_SOBEL) ? 1'b0 : 1'b1; // to wait for the end of the sobel filter
  integer i;
  reg[31:0] comparisonBuffer;  // buffer to store the values of the previous frame

  // SOBEL state machine
 always @* 
    case (s_SobelCurrentStateReg)
      IDLE_SOBEL       : s_SobelNextState <= (s_isMyCiSobel) ? FILL_WINDOW : IDLE_SOBEL;
      FILL_WINDOW      : s_SobelNextState  <= (counter_done) ? FILL_COMPARISON_BUFFER : FILL_WINDOW;
      FILL_COMPARISON_BUFFER : s_SobelNextState  <=  SOBEL_FILTER;
      SOBEL_FILTER     : s_SobelNextState  <=  (sobel_done) ? IDLE_SOBEL  : FILL_WINDOW;
      default          : s_SobelNextState  <= IDLE_SOBEL;
    endcase

always @(posedge clock)
    begin
      s_SobelCurrentStateReg <= (reset==1'b1) ? IDLE_SOBEL : s_SobelNextState;
    end

always @(posedge clock)
begin
    counterWindow <= (s_SobelCurrentStateReg == IDLE_SOBEL) ? 8'd0 : 
                     (s_SobelCurrentStateReg == SOBEL_FILTER) ? counterWindow + 1 : counterWindow;
    initialCounterWord <= (s_SobelCurrentStateReg == IDLE_SOBEL) ? sobelMemoryStartAddress:
                      (counterSobel==3'd5)? ((counterWindow[3:0] == 4'd15) ? initialCounterWord + 9'd2 :
                      initialCounterWord + 9'd1) : initialCounterWord;
    addressSobelRead <= (s_SobelCurrentStateReg == SOBEL_FILTER || s_SobelCurrentStateReg == IDLE_SOBEL)? {1'b0,initialCounterWord}:
                      (s_SobelCurrentStateReg == FILL_WINDOW)? 
                      ((counterSobel == 3'd1 || counterSobel == 3'd3) ? addressSobelRead + 10'd16 :(counterSobel > 4) ? addressSobelRead :addressSobelRead + 10'd1) :
                       addressSobelRead;
    addressSobelComparison <= addressSobelWrite + 10'd239 + {1'b0,s_memoryStartAddressReg}; //position where to read the sobel values of the previous iteration
    addressSobelWrite <= (s_SobelCurrentStateReg == IDLE_SOBEL)? sobelMemoryStartAddress :
                     (s_SobelCurrentStateReg == SOBEL_FILTER)? addressSobelWrite+1 : addressSobelWrite;
    comparisonBuffer <=(reset==1'b1)? 32'b0 : ( (s_SobelCurrentStateReg == FILL_COMPARISON_BUFFER) ? s_sobelDataOut : comparisonBuffer);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
    if(s_SobelCurrentStateReg == IDLE_SOBEL)begin
                      for (i=0; i<18; i=i+1)begin
                             window[i] <= 8'd0 ;
                      end
    end
    if(counterSobel != 3'd7 && counterSobel!=3'd0 )begin
      window[windowIndex] <= (s_SobelCurrentStateReg == FILL_WINDOW) ? s_sobelDataOut[7:0] : window[windowIndex];
      window[windowIndex+1] <= (s_SobelCurrentStateReg == FILL_WINDOW) ? s_sobelDataOut[15:8] : window[windowIndex+1];
      window[windowIndex+2] <= (s_SobelCurrentStateReg == FILL_WINDOW && (windowIndex==5'd0 || windowIndex==5'd12 || windowIndex==5'd6 ) ) ? s_sobelDataOut[23:16] : window[windowIndex+2];
      window[windowIndex+3] <= (s_SobelCurrentStateReg == FILL_WINDOW && (windowIndex==5'd0 || windowIndex==5'd12 || windowIndex==5'd6 ) ) ? s_sobelDataOut[31:24] : window[windowIndex+3];
    end
    else begin
      window[windowIndex] <= window[windowIndex];
      window[windowIndex+1] <= window[windowIndex+1];
      window[windowIndex+2] <= window[windowIndex+2];
      window[windowIndex+3] <= window[windowIndex+3];
    end
    counterSobel <= (s_SobelCurrentStateReg == FILL_WINDOW) ? counterSobel + 1 : 3'd0; 
end

/// Calculate Gx for 4 pixels
wire signed [9:0] Gx_0 = window[0] - window[2] + ((window[6]<<1)) - ((window[8])<<<1) + window[12] - window[14];
wire signed [9:0] Gx_1 = window[1] - window[3] + ((window[7]<<1)) - ((window[9])<<<1) + window[13] - window[15];
wire signed [9:0] Gx_2 = window[2] - window[4] + ((window[8]<<1)) - ((window[10])<<<1) + window[14] - window[16];
wire signed [9:0] Gx_3 = window[3] - window[5] + ((window[9]<<1)) - ((window[11])<<<1) + window[15] - window[17];

// Calculate Gy for 4 pixels
wire signed [9:0] Gy_0 = window[12] + (window[13]<<<1) + window[14] - (window[0] + (window[1]<<1) + window[2]);
wire signed [9:0] Gy_1 = window[13] + (window[14]<<<1) + window[15] - (window[1] + (window[2]<<1) + window[3]);
wire signed [9:0] Gy_2 = window[14] + (window[15]<<<1) + window[16] - (window[2] + (window[3]<<1) + window[4]);
wire signed [9:0] Gy_3 = window[15] + (window[16]<<<1) + window[17] - (window[3] + (window[4]<<1) + window[5]);

// Compute absolute values of Gx and Gy
wire [9:0] abs_Gx_0 = (Gx_0 < 0) ? -Gx_0 : Gx_0;
wire [9:0] abs_Gx_1 = (Gx_1 < 0) ? -Gx_1 : Gx_1;
wire [9:0] abs_Gx_2 = (Gx_2 < 0) ? -Gx_2 : Gx_2;
wire [9:0] abs_Gx_3 = (Gx_3 < 0) ? -Gx_3 : Gx_3;

wire [9:0] abs_Gy_0 = (Gy_0 < 0) ? -Gy_0 : Gy_0;     
wire [9:0] abs_Gy_1 = (Gy_1 < 0) ? -Gy_1 : Gy_1;
wire [9:0] abs_Gy_2 = (Gy_2 < 0) ? -Gy_2 : Gy_2;
wire [9:0] abs_Gy_3 = (Gy_3 < 0) ? -Gy_3 : Gy_3;

// Sum the absolute values to get the gradient magnitude
wire [7:0] sum_0 =  (abs_Gx_0 + abs_Gy_0 < {2'd0, s_sobelTresholdReg}) ? 8'd127 : ((comparisonBuffer[7]==comparisonBuffer[6])?  8'd0 : 8'd255) ;
wire [7:0] sum_1 =  (abs_Gx_1 + abs_Gy_1 < {2'd0, s_sobelTresholdReg}) ? 8'd127 : ((comparisonBuffer[15]==comparisonBuffer[14])?  8'd0 : 8'd255) ;
wire [7:0] sum_2 =  (abs_Gx_2 + abs_Gy_2 < {2'd0, s_sobelTresholdReg}) ? 8'd127 : ((comparisonBuffer[23]==comparisonBuffer[22])?  8'd0 : 8'd255) ;
wire [7:0] sum_3 =  (abs_Gx_3 + abs_Gy_3 < {2'd0, s_sobelTresholdReg}) ? 8'd127 : ((comparisonBuffer[31]==comparisonBuffer[30])?  8'd0 : 8'd255) ;

// Combine the results into the output bus
assign s_sobelDataIn = {sum_3, sum_2, sum_1, sum_0};

endmodule


/*
SOBEL_X_0= 1*(1) + 9*(-1) + 7*(1) + 6*(-2) + 4*(2) + 3*(-1)
SOBEL_Y_0= 1*(-1) + 2*(-2) + 3*(-1) + 7*(1) + 8*(2) + 9*(1)
SOBEL_X_0= 1*(1) + 9*(-1) + 7*(1) + 6*(-2) + 4*(2) + 3*(-1)
SOBEL_Y_0= 1*(-1) + 2*(-2) + 3*(-1) + 7*(1) + 8*(2) + 9*(1)
SOBEL_X_0= 1*(1) + 9*(-1) + 7*(1) + 6*(-2) + 4*(2) + 3*(-1)
SOBEL_Y_0= 1*(-1) + 2*(-2) + 3*(-1) + 7*(1) + 8*(2) + 9*(1)
MATRIX {
          1  2  3
          4  5  6
          7  8  9
        }
filter x {1  0  -1
          2  0  -2
          1  0  -1}       
filter y {-1 -2 -1
          0  0  0
          1  2  1}
matrix_indices {0  1  2  3  4  5 
                6  7  8  9  10 11 
                12 13 14 15 16 17}
*/

