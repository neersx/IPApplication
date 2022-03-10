	/******************************************************************************************************************/
	/*** SQA8777 Add triggers for UPDATE and INSERT on CASES							***/
	/***	     raise an error 50,000 with message 'Duplicate Case Reference' for 					***/
	/***	     changed IRN <> "<Generate Reference>"								***/
	/***	     changed IRN already exists in CASES								***/
	/*** 	     50,000 is selected becuase ODBC converts this to 20,035, the InPro MapErr32.sql converts this	***/
	/***	     to 805 which is treated by InPro as a duplicate error.						***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'tI_UniqueCaseReference')
	   begin
	    PRINT 'Refreshing trigger tI_UniqueCaseReference...'
	    DROP TRIGGER tI_UniqueCaseReference
	   end
	go

	CREATE  TRIGGER tI_UniqueCaseReference ON CASES FOR INSERT, UPDATE not for replication AS
	begin
	   if update(IRN)
	   begin
		   declare @IRNDUPLICATE integer
		   select @IRNDUPLICATE = 
			CASE WHEN (i.IRN != '<Generate Reference>') 
			     AND (i.IRN in (select IRN from CASES where CASES.CASEID != i.CASEID)) 
			THEN 1  else 0
		       	END 
		   from inserted i
		   IF @IRNDUPLICATE = 1
		   begin
		   	Raiserror  ('Duplicate Case Reference', 16,1, 50000)
			rollback transaction
		   end
	   end
	end
	go
