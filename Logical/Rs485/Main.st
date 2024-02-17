
PROGRAM _INIT
	(* Insert code here *)
	Terminal.Commands.open:= TRUE;												(*enable terminal statemachine by default*)						
	Terminal.Commands.m_first:= TRUE;
	 
END_PROGRAM

PROGRAM _CYCLIC
	(* Insert code here *)
	
	CASE Terminal.Steps OF
		FRM_WAIT:
		
			IF Terminal.Commands.open = TRUE THEN								(*command for sender activation*)
				Terminal.Steps  := FRM_OPEN;
			END_IF
		
		FRM_OPEN:
			
			Terminal.FRM_xopen_0.enable:= TRUE;
			Terminal.FRM_xopen_0.device:=ADR('IF9');
			Terminal.FRM_xopen_0.mode:= ADR('/BD=9600 /PA=E /DB=8 /SB=1 /PHY=RS485');
			Terminal.FRM_xopen_0.config := ADR(Terminal.FRM_xopenConfig);
		
			Terminal.FRM_xopenConfig.idle:=4;
			Terminal.FRM_xopenConfig.delimc:=0;
			Terminal.FRM_xopenConfig.delim[0]:=0;
			Terminal.FRM_xopenConfig.tx_cnt := 2;
			Terminal.FRM_xopenConfig.rx_cnt:=2;
			Terminal.FRM_xopenConfig.tx_len:=255;
			Terminal.FRM_xopenConfig.rx_len:=255;
			Terminal.FRM_xopenConfig.argc:=0;
			Terminal.FRM_xopenConfig.argv:=0;
		
			IF (Terminal.FRM_xopen_0.status = 0) THEN
				Terminal.Steps:= FRM_GBUF;
			ELSE
				Terminal.Steps := FRM_OPEN;
			END_IF;	
				
		FRM_GBUF:
		
			Terminal.FRM_gbuf_0.enable:= TRUE;
			Terminal.FRM_gbuf_0.ident:=Terminal.FRM_xopen_0.ident;
			send_buffer:= Terminal.FRM_gbuf_0.buffer;
		
			IF Terminal.FRM_gbuf_0.status= FALSE THEN
				memset(send_buffer,0,Terminal.FRM_gbuf_0.buflng);
				Terminal.Steps:= FRM_PREPARE_SENDDATA;
			ELSE 
				Terminal.Steps:= FRM_GBUF;
			END_IF;
				
		FRM_PREPARE_SENDDATA:
				
			SENDBUFFER_length := 10;
			SENDBUFFER[0] := 1;     // Start of frame or control byte
			SENDBUFFER[1] := 49;    // ASCII value of '1'
			SENDBUFFER[2] := 48;    // ASCII value of '0'
			SENDBUFFER[3] := 49;    // ASCII value of '1'
			SENDBUFFER[4] := 2;     // Control byte or identifier
			SENDBUFFER[5] := 56;    // ASCII value of '8'
			SENDBUFFER[6] := 69;    // ASCII value of 'E'
			SENDBUFFER[7] := 3;     // Control byte or identifier
			SENDBUFFER[8] := 49;    // ASCII value of '1'
			SENDBUFFER[9] := 52;    // ASCII value of '4'
				
			memcpy(send_buffer,ADR(SENDBUFFER),Terminal.FRM_gbuf_0.buflng);(*copy Data to Sendbuffer*)
			Terminal.Steps := FRM_WRITE;
				
		FRM_WRITE:
				
			Terminal.FRM_write_0.enable := TRUE;
			Terminal.FRM_write_0.ident := Terminal.FRM_xopen_0.ident;				(*ident from FRM_xopen()*)
			Terminal.FRM_write_0.buffer := send_buffer;								(*sendbuffer*)
			Terminal.FRM_write_0.buflng := SENDBUFFER_length;	
				
			IF Terminal.FRM_write_0.status = 0 THEN
				IF Terminal.Commands.close = TRUE THEN								(*requst to close the serial port*)
					Terminal.Commands.open := FALSE;								(*disable command open_send*)
					Terminal.Steps := FRM_CLOSE;
				ELSE
					Terminal.Steps := FRM_READ;										(*writing successful --> goto listen mode "FRM_READ"*)
				END_IF
			ELSE 
				Terminal.Steps := FRM_WRITE;											(*operation not finished yet --> call again*)										(*function returned errorcode --> check help*)
			END_IF
				
		FRM_ROBUF:	(*--- release sendbuffer in case of no successful write operation*)
		
			Terminal.FRM_robuf_0.enable := TRUE;
			Terminal.FRM_robuf_0.buffer := Terminal.FRM_gbuf_0.buffer;				(*sendbuffer*)
			Terminal.FRM_robuf_0.buflng := Terminal.FRM_gbuf_0.buflng;				(*buffer length*)
			Terminal.FRM_robuf_0.ident := Terminal.FRM_xopen_0.ident;				(*ident open*)

		
			IF Terminal.FRM_robuf_0.status = 0 THEN
				Terminal.Steps := FRM_GBUF;											(*released buffer successful --> get next sendbuffer*)
			ELSE 
				Terminal.Steps := FRM_ROBUF;											(*operation not finished yet --> call again*)
			END_IF			
		
		FRM_READ:	(*--- read data from serial interface*)
		
			Terminal.FRM_read_0.enable := TRUE;
			Terminal.FRM_read_0.ident := Terminal.FRM_xopen_0.ident;												
			
			IF Terminal.FRM_read_0.status = 0 THEN
				Terminal.Steps := FRM_COPY_RD_DATA;									(*system returned a valid data --> next step*)
			ELSIF Terminal.FRM_read_0.status = frmERR_NOINPUT THEN
				Terminal.Steps := FRM_READ;											(*no data available --> call again*)
			ELSE 
				Terminal.Steps := FRM_RBUF;											(*received Frame with defective characters, skip data*)
			END_IF	
		
		FRM_COPY_RD_DATA:(*--- copy data out of the receive buffer*)
		
			//		memset(ADR(READBUFFER_1),0,SIZEOF(READBUFFER_1));		(*clear read_data buffer*)
			(*copy and evaluate read data*)
			memcpy(ADR(READBUFFER_1),Terminal.FRM_read_0.buffer, Terminal.FRM_read_0.buflng);			
			Terminal.Steps := FRM_RBUF;												(*release read buffer*)
			
		FRM_RBUF:	(*--- release readbuffer*)
		
			(*Parameters for FRM_rbuf()*)
			Terminal.FRM_rbuf_0.enable := TRUE;
			Terminal.FRM_rbuf_0.ident := Terminal.FRM_xopen_0.ident;				(*ident from FRM_xopen()*)
			Terminal.FRM_rbuf_0.buffer := Terminal.FRM_read_0.buffer;				(*read buffer*)
			Terminal.FRM_rbuf_0.buflng := Terminal.FRM_read_0.buflng;				(*length of sendbuffer*)
			
			IF Terminal.FRM_rbuf_0.status = 0 THEN
				Terminal.Steps := FRM_GBUF;											(*send accnowledge -> aquire sendbuffer first*)
			ELSE 			
				Terminal.Steps := FRM_GBUF;//BRIN_IEC_CHECK											(*buffer is invalid --> read again*)
			END_IF			
		
		FRM_CLOSE:	(*--- close the interface*)
		
			Terminal.FRM_close_0.enable := TRUE;
			Terminal.FRM_close_0.ident := Terminal.FRM_xopen_0.ident;				(*ident from FRM_xopen()*)															(*call the FRM_close() function*)
			
			IF Terminal.FRM_close_0.status = 0 THEN
				Terminal.Commands.close := FALSE;									(*disable close command*)
				Terminal.Commands.m_first := TRUE;								(*mark as "first" for next open*)											(*closed interface successfully --> wait step*)
			ELSE 
				Terminal.Steps := FRM_CLOSE;											(*operation not finished yet --> call again*)
			END_IF			
				
		
	END_CASE;
	
	Terminal.FRM_xopen_0();
	Terminal.FRM_gbuf_0();
	Terminal.FRM_write_0();
	Terminal.FRM_robuf_0();	
	Terminal.FRM_read_0();
	Terminal.FRM_rbuf_0(); 
	Terminal.FRM_close_0();
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

