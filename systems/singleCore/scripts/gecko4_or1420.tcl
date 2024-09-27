set_location_assignment PIN_T22 -to clock12MHz
set_location_assignment PIN_T1 -to clock50MHz

set_location_assignment PIN_U12 -to hdmiRed[3]
set_location_assignment PIN_T12 -to hdmiRed[2]
set_location_assignment PIN_AA17 -to hdmiRed[1]
set_location_assignment PIN_AB17 -to hdmiRed[0]
set_location_assignment PIN_AA19 -to hdmiGreen[3]
set_location_assignment PIN_AB19 -to hdmiGreen[2]
set_location_assignment PIN_Y17 -to hdmiGreen[1]
set_location_assignment PIN_W15 -to hdmiGreen[0]
set_location_assignment PIN_W17 -to hdmiBlue[3]
set_location_assignment PIN_V16 -to hdmiBlue[2]
set_location_assignment PIN_U19 -to hdmiBlue[1]
set_location_assignment PIN_U15 -to hdmiBlue[0]
set_location_assignment PIN_V15 -to pixelClock
set_location_assignment PIN_P15 -to horizontalSync
set_location_assignment PIN_R14 -to activePixel
set_location_assignment PIN_R15 -to verticalSync

set_location_assignment PIN_AA11 -to nReset
set_location_assignment PIN_AB11 -to biosBypass

# Here the none used signals of the add-on card are defined
# set_location_assignment PIN_V22 -to EspTxd
# set_location_assignment PIN_V21 -to EspRxd
# set_location_assignment PIN_W20 -to EspIO7
# set_location_assignment PIN_W21 -to EspIO6
# set_location_assignment PIN_W22 -to EspIO5
# set_location_assignment PIN_U22 -to EspIO4
# set_location_assignment PIN_P21 -to EspIO10
# set_location_assignment PIN_N21 -to GPIO3
# set_location_assignment PIN_N22 -to GPIO2
# set_location_assignment PIN_M20 -to GPIO1
# set_location_assignment PIN_M21 -to GPIO0
# set_location_assignment PIN_W19 -to SD2
# set_location_assignment PIN_T14 -to SD3
# set_location_assignment PIN_AA18 -to RtcMfp

# Here the sdc-file will be included
set_global_assignment -name SDC_FILE ../scripts/clocks_sdc.tcl

set_location_assignment PIN_N5 -to sdramAddr[0]
set_location_assignment PIN_N6 -to sdramAddr[1]
set_location_assignment PIN_P4 -to sdramAddr[2]
set_location_assignment PIN_P5 -to sdramAddr[3]
set_location_assignment PIN_W6 -to sdramAddr[4]
set_location_assignment PIN_V7 -to sdramAddr[5]
set_location_assignment PIN_V6 -to sdramAddr[6]
set_location_assignment PIN_V5 -to sdramAddr[7]
set_location_assignment PIN_V1 -to sdramAddr[8]
set_location_assignment PIN_V4 -to sdramAddr[9]
set_location_assignment PIN_U2 -to sdramAddr[10]
set_location_assignment PIN_U8 -to sdramAddr[11]
set_location_assignment PIN_V2 -to sdramAddr[12]
set_location_assignment PIN_M6 -to sdramBa[0]
set_location_assignment PIN_M7 -to sdramBa[1]
set_location_assignment PIN_M1  -to sdramData[0]
set_location_assignment PIN_M2  -to sdramData[1]
set_location_assignment PIN_M3  -to sdramData[2]
set_location_assignment PIN_N1  -to sdramData[3]
set_location_assignment PIN_N2  -to sdramData[4]
set_location_assignment PIN_P1  -to sdramData[5]
set_location_assignment PIN_P2  -to sdramData[6]
set_location_assignment PIN_P3  -to sdramData[7]
set_location_assignment PIN_W1  -to sdramData[8]
set_location_assignment PIN_W2  -to sdramData[9]
set_location_assignment PIN_Y1  -to sdramData[10]
set_location_assignment PIN_Y2  -to sdramData[11]
set_location_assignment PIN_Y3  -to sdramData[12]
set_location_assignment PIN_AA1 -to sdramData[13]
set_location_assignment PIN_AB3 -to sdramData[14]
set_location_assignment PIN_AA4 -to sdramData[15]
set_location_assignment PIN_R1 -to sdramDqmN[0]
set_location_assignment PIN_V3 -to sdramDqmN[1]
set_location_assignment PIN_U7  -to sdramCke
set_location_assignment PIN_AA3 -to sdramClk
set_location_assignment PIN_M5  -to sdramCasN
set_location_assignment PIN_M4  -to sdramRasN
set_location_assignment PIN_U1  -to sdramCsN
set_location_assignment PIN_R2  -to sdramWeN

set_location_assignment PIN_P22 -to TxD
set_location_assignment PIN_N20 -to RxD

set_location_assignment PIN_U14 -to spiNCs
set_location_assignment PIN_U13 -to spiIo3
set_location_assignment PIN_V13 -to spiScl
set_location_assignment PIN_W13 -to spiSiIo0
set_location_assignment PIN_V14 -to spiSoIo1
set_location_assignment PIN_W14 -to spiIo2
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to spiSiIo0
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to spiSoIo1
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to spiIo2
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to spiIo3

set_location_assignment PIN_R16 -to SCL
set_location_assignment PIN_M22 -to camnReset
set_location_assignment PIN_N18 -to SDA
set_location_assignment PIN_Y13 -to camPclk
set_location_assignment PIN_N19 -to camHsync
set_location_assignment PIN_R17 -to camVsync
set_location_assignment PIN_P16 -to camData[0]
set_location_assignment PIN_T17 -to camData[1]
set_location_assignment PIN_P17 -to camData[2]
set_location_assignment PIN_T18 -to camData[3]
set_location_assignment PIN_R18 -to camData[4]
set_location_assignment PIN_T16 -to camData[5]
set_location_assignment PIN_R19 -to camData[6]
set_location_assignment PIN_T15 -to camData[7]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SCL
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDA
