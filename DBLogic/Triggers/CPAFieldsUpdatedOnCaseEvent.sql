if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsUpdatedOnCaseEvent')
begin
	PRINT 'Refreshing trigger CPAFieldsUpdatedOnCaseEvent...'
	DROP TRIGGER CPAFieldsUpdatedOnCaseEvent
end
go
	
CREATE TRIGGER CPAFieldsUpdatedOnCaseEvent ON CASEEVENT
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	CPAFieldsUpdatedOnCaseEvent    
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

	Insert into CPAUPDATE(CASEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
	Select distinct i.CASEID, @nIdentityId, system_user, getdate(),'CPAFieldsUpdatedOnCaseEvent',APP_NAME()
	from inserted i
	join CASES C on (C.CASEID=i.CASEID)
	join SITECONTROL S	on (S.COLINTEGER=i.EVENTNO)
	left join CPAUPDATE CPA on (CPA.CASEID=i.CASEID)
	where CPA.CASEID is null
	and C.REPORTTOTHIRDPARTY=1
	and (S.CONTROLID like 'CPA TM%'
	 or  S.CONTROLID like 'CPA P%'
	 or  S.CONTROLID like 'CPA D%'
	 or  S.CONTROLID like 'CPA Date%'
	 or  S.CONTROLID like 'CPA Rejected Event')
End
go
