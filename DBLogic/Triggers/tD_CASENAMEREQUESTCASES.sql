if exists (select * from sysobjects where type='TR' and name = 'tD_CASENAMEREQUESTCASES')
begin
	PRINT 'Refreshing trigger tD_CASENAMEREQUESTCASES...'
	DROP TRIGGER tD_CASENAMEREQUESTCASES
end
go	

CREATE TRIGGER  tD_CASENAMEREQUESTCASES ON CASENAMEREQUESTCASES FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER :	tD_CASENAMEREQUESTCASES
-- VERSION :	1
-- DESCRIPTION:	This trigger deletes the parent CASENAMEREQUEST row if after the 
-- 		delete of CASENAMEREQUESTCASES the CASENAMEREQUEST row has no
--		more child rows.
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 	
-- 30 Jul 2009	MF	17919	1	Trigger created 	

Begin
	-----------------------------------------------------
	-- If the CASENAMEREQUEST row has no child rows
	-- with the same REQUESTNO in the CASENAMEREQUESTCASE
	-- table then it can be deleted.
	-----------------------------------------------------
	Delete CNR
	from CASENAMEREQUEST CNR
	join deleted d	on (d.REQUESTNO=CNR.REQUESTNO)		
	left join CASENAMEREQUESTCASES C on (C.REQUESTNO=CNR.REQUESTNO)
	where C.REQUESTNO is null
End
go
