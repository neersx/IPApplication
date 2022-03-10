if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsUpdatedOnAddress')
begin
	PRINT 'Refreshing trigger CPAFieldsUpdatedOnAddress...'
	DROP TRIGGER CPAFieldsUpdatedOnAddress
end
go

CREATE TRIGGER CPAFieldsUpdatedOnAddress ON ADDRESS
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	CPAFieldsUpdatedOnAddress    
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17-Nov-2004	MF	SQA10670 2	Remove the check of the CPA Logging sitecontrol.
-- 31-AUG-2005	MF	SQA10874 3	Add new columns to CPAUPDATE and initialise
-- 17 Mar 2009	MF	SQA17490 4	Ignore if trigger is being fired as a result of the audit details being updated

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	declare @nIdentityId	int
	
	select @nIdentityId=cast(substring(context_info,1,4) as int)
	from master.dbo.sysprocesses
	where spid=@@SPID
	and substring(context_info,1,4)<>0x0000000

	Insert into CPAUPDATE(NAMEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
	Select distinct CN.NAMENO, @nIdentityId, system_user, getdate(),'CPAFieldsUpdatedOnAddress',APP_NAME()
	from inserted i
	join NAME N	 on (N.POSTALADDRESS=i.ADDRESSCODE)
	join CASENAME CN on (CN.NAMENO=N.NAMENO)
	join CASES C	 on (C.CASEID=CN.CASEID)
	left join CPAUPDATE CPA on (CPA.NAMEID=CN.NAMENO)
	where CPA.NAMEID is null
	and C.REPORTTOTHIRDPARTY=1
	and CN.NAMETYPE in ('I','D','R','Z','O')
End
go
