
TYPE
	TERM_STEPS : 
		(
		FRM_WAIT,
		FRM_OPEN,
		FRM_GBUF,
		FRM_PREPARE_SENDDATA,
		FRM_WRITE,
		FRM_ROBUF,
		FRM_READ,
		FRM_RBUF,
		FRM_CLOSE,
		FRM_COPY_RD_DATA
		);
	Terminal_Types : 	STRUCT 
		Steps : TERM_STEPS;
		Receive_Data : STRING[80];
		Send_Data : STRING[80];
		FRM_xopen_0 : FRM_xopen;
		FRM_xopenConfig : XOPENCONFIG;
		FRM_gbuf_0 : FRM_gbuf;
		FRM_robuf_0 : FRM_robuf;
		FRM_rbuf_0 : FRM_rbuf;
		FRM_write_0 : FRM_write;
		FRM_read_0 : FRM_read;
		FRM_close_0 : FRM_close;
		Commands : Command_Types;
	END_STRUCT;
	Command_Types : 	STRUCT 
		open : BOOL;
		close : BOOL;
		m_first : BOOL;
	END_STRUCT;
END_TYPE
