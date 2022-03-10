if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsUpdatedOnRelatedCase')
begin
	PRINT 'Refreshing trigger CPAFieldsUpdatedOnRelatedCase...'
	DROP TRIGGER CPAFieldsUpdatedOnRelatedCase
end
go

CREATE TRIGGER CPAFieldsUpdatedOnRelatedCase ON RELATEDCASE
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	CPAFieldsUpdatedOnRelatedCase    
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17-Nov-2004	MF	SQA10670 2	Remove the check of the CPA Logging sitecontrol.
-- 31-AUG-2005	MF	SQA10874 3	Add new columns to CPAUPDATE and initialise
-- 17 Mar 2009	MF	SQ17490	 4	Ignore if trigger is being fired as a result of the audit details being updated

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	declare @nIdentityId	int
	
	select @nIdentityId=cast(substring(context_info,1,4) as int)
	from master.dbo.sysprocesses
	where spid=@@SPID
	and substring(context_info,1,4)<>0x0000000

	Insert into CPAUPDATE(CASEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
	Select distinct i.CASEID, @nIdentityId, system_user, getdate(),'CPAFieldsUpdatedOnRelatedCase',APP_NAME()
	from inserted i
	join CASES C on (C.CASEID=i.CASEID)
	left join CPAUPDATE CPA on (CPA.CASEID=i.CASEID)
	where CPA.CASEID is null
	and C.REPORTTOTHIRDPARTY=1
END
go
