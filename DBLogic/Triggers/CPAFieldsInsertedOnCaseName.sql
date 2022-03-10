if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsInsertedOnCaseName')
begin
	PRINT 'Refreshing trigger CPAFieldsInsertedOnCaseName...'
	DROP TRIGGER CPAFieldsInsertedOnCaseName
end
go
	
CREATE TRIGGER CPAFieldsInsertedOnCaseName ON CASENAME
FOR INSERT NOT FOR REPLICATION AS
-- TRIGGER:	CPAFieldsInsertedOnCaseName    
-- VERSION:	5
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17-Nov-2004	MF	SQA10670 2	Remove the check of the CPA Logging sitecontrol.
-- 11-APR-2005	MF	SQA9249	 3	Add the name type for Division "DIV" to the list of nametypes.
-- 31-AUG-2005	MF	SQA10874 4	Add new columns to CPAUPDATE and initialise
-- 25-FEB-2009	MF	SQA12579 5	Change of Agent against a case should trigger case to be reported to CPA.


	declare @nIdentityId	int
	
	select @nIdentityId=cast(substring(context_info,1,4) as int)
	from master.dbo.sysprocesses
	where spid=@@SPID
	and substring(context_info,1,4)<>0x0000000

	Insert into CPAUPDATE(CASEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
	Select distinct i.CASEID, @nIdentityId, system_user, getdate(),'CPAFieldsInsertedOnCaseName',APP_NAME()
	from inserted i
	join CASES C on (C.CASEID=i.CASEID)
	left join CPAUPDATE CPA on (CPA.CASEID=i.CASEID)
	where CPA.CASEID is null
	and C.REPORTTOTHIRDPARTY=1
	and i.NAMETYPE in ('A','I','D','R','Z','O','DIV')

	Insert into CPAUPDATE(NAMEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
	Select distinct i.NAMENO, @nIdentityId, system_user, getdate(),'CPAFieldsInsertedOnCaseName',APP_NAME()
	from inserted i
	join CASES C on (C.CASEID=i.CASEID)
	left join CPAUPDATE CPA on (CPA.NAMEID=i.NAMENO)
	where CPA.NAMEID is null
	and C.REPORTTOTHIRDPARTY=1
	and i.NAMETYPE in ('A','I','D','R','Z','O','DIV')
go
