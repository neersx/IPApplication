if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsDeletedOnCaseName')
begin
	PRINT 'Refreshing trigger CPAFieldsDeletedOnCaseName...'
	DROP TRIGGER CPAFieldsDeletedOnCaseName
end
go

CREATE TRIGGER CPAFieldsDeletedOnCaseName ON CASENAME
FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER:	CPAFieldsDeletedOnCaseName    
-- VERSION:	5
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17-Nov-2004	MF	SQA10670 2	Remove the check of the CPA Name Logging sitecontrol.
-- 11-APR-2005	MF	SQA9249	 3	Add the name type for Division "DIV" to the list of nametypes.
-- 31-AUG-2005	MF	SQA10874 4	Add new columns to CPAUPDATE and initialise
-- 25-FEB-2009	MF	SQA12579 5	Change of Agent against a case should trigger case to be reported to CPA.

/******************************************************************************************************************/
/*** CPA Interface specific manul trigger									***/
/******************************************************************************************************************/     
/*tD_CASENAME non-existent cut and paste whole trigger definition BEGIN*/

	declare @nIdentityId	int
	
	select @nIdentityId=cast(substring(context_info,1,4) as int)
	from master.dbo.sysprocesses
	where spid=@@SPID
	and substring(context_info,1,4)<>0x0000000

	Insert into CPAUPDATE(CASEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
	Select distinct d.CASEID, @nIdentityId, system_user, getdate(),'CPAFieldsDeletedOnCaseName',APP_NAME()
	from deleted d
	join CASES C on (C.CASEID=d.CASEID)
	left join CPAUPDATE CPA on (CPA.CASEID=d.CASEID)
	where CPA.CASEID is null
	and C.REPORTTOTHIRDPARTY=1
	and d.NAMETYPE in ('A','I','D','R','Z','O','DIV')
go
