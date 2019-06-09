
localparam [2:0] DRAM_CMD_LOADMODE  = 3'b000;
localparam [2:0] DRAM_CMD_REFRESH   = 3'b001;
localparam [2:0] DRAM_CMD_PRECHARGE = 3'b010;
localparam [2:0] DRAM_CMD_ACTIVE    = 3'b011;
localparam [2:0] DRAM_CMD_WRITE     = 3'b100;
localparam [2:0] DRAM_CMD_READ      = 3'b101;
localparam [2:0] DRAM_CMD_NOP       = 3'b111;

localparam [2:0] IDLE = 3'h0;
localparam [2:0] ACT = 3'h1;
localparam [2:0] PRECH = 3'h2;
localparam [2:0] NOP = 3'h3;
localparam [2:0] REFRESH = 3'h4;
localparam [2:0] READ = 3'h5;
localparam [2:0] WRITE = 3'h6;

//CAS Latency
localparam Tcac = 2;
localparam Trcd = 2;
localparam Tdpl = 2;
//Trac = Tcac + Trcd
localparam Trac = 4;
localparam Trc = 8;
localparam Tras = 5;
localparam Trp = 2;
localparam Trrd = 2;
