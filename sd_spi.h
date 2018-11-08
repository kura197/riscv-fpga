//CMD0
//reset and stay idle
localparam CMD0 = 8'h40;

//CMD1
//excute initiation
localparam CMD1 = 8'h41;

//CMD8
//SDHC??
localparam CMD8 = 8'h48;

//CMD9
//read CSD
localparam CMD9 = 8'h49;

//CMD10
//read CID
localparam CMD10 = 8'h4a;

//CMD13
//read status register
localparam CMD13 = 8'h4d;

//CMD16
//configure length of block
localparam CMD16 = 8'h50;

//CMD17
//read data 
localparam CMD17 = 8'h51;

//CMD58
//read OCR register 
localparam CMD58 = 8'h7a;


//SD initiation
localparam ACMD41 = 8'h69;

//need for ADMD41
localparam CMD55 = 8'h77;

//response type
localparam R1 = 2'h0;
localparam R2 = 2'h1;
localparam R3 = 2'h2;
localparam R7 = 2'h3;
