`define			dw	 32		// Data bus Width
`define			aw	 32		// Address bus Width
`define			sw   `dw / 8	// Number of Select Lines
`define			mbusw  `aw + `sw + `dw +4 	//address width + byte select width + dat width + cyc + we + stb +cab , input from master interface
`define			sbusw	 3	//  ack + err + rty, input from slave interface
`define			mselectw  8	// number of masters
`define			sselectw  8	// number of slavers


// Define the following to enable logic to generate the first few instructions at reset
//`define OR1200_BOOT_LOGIC
