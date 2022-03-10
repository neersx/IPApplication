-- TRIGGER:	CPAFieldsDeletedOnCaseEvent    
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17-Nov-2004	MF	SQA10670 1	Procedure removed as removal of CASEEVENT rows is always preceeded
--					by an update to set the EVENTDATE to null.  The CPA Logging will 
--					occur as a result of the update trigger.

if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsDeletedOnCaseEvent')
begin
	PRINT 'Dropping trigger CPAFieldsDeletedOnCaseEvent...'
	DROP TRIGGER CPAFieldsDeletedOnCaseEvent
end
go
	
