
//mux_pc_res
localparam pc_addr = 1'b0;
localparam res_addr = 1'b1;

//mux_rs1_pc_res_zero_extimm
localparam rs1 = 3'h0;
localparam pc_inc = 3'h1;
localparam src_res = 3'h2;
localparam zeroA = 3'h3;
localparam extimmA = 3'h4;

//mux_rs2_extimm_4_m4_zero_csr
localparam rs2 = 3'h0;
localparam extimmB = 3'h1;
localparam imm_4 = 3'h2;
localparam imm_m4 = 3'h3;
localparam zeroB = 3'h4;
localparam csr = 3'h5;

//mux_alu_nextpc_indata
localparam alu = 2'b00;
//localparam nextpc = 2'b01;
localparam rddata = 2'b10;
localparam nowpc = 2'b11;

//mux_ra2_rd
localparam rd = 1'b0;
localparam ra2 = 1'b1;
