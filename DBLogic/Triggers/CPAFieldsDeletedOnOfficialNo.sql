if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsDeletedOnOfficialNo')
begin
	PRINT 'Refreshing trigger CPAFieldsDeletedOnOfficialNo...'
	DROP TRIGGER CPAFieldsDeletedOnOfficialNo
end
go
	
CREATE TRIGGER CPAFieldsDeletedOnOfficialNo ON OFFICIALNUMBERS
FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER:	CPAFieldsDeletedOnOfficialNo    
-- VERSION:	2
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17-Nov-2004	MF	SQA10670 1	Remove the check of the CPA Logging sitecontrol.
-- 31-AUG-2005	MF	SQA10874 2	Add new columns to CPAUPDATE and initialise	

	declare @nIdentityId	int
	
	select @nIdentityId=cast(substring(context_info,1,4) as int)
	from master.dbo.sysprocesses
	where spid=@@SPID
	and substring(context_info,1,4)<>0x0000000

	Insert into CPAUPDATE(CASEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
	Select distinct d.CASEID, @nIdentityId, system_user, getdate(),'CPAFieldsDeletedOnOfficialNo',APP_NAME()
	from deleted d
	join CASES C on (C.CASEID=d.CASEID)
	left join CPAUPDATE CPA on (CPA.CASEID=d.CASEID)
	where CPA.CASEID is null
	and C.REPORTTOTHIRDPARTY=1
go
