if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsUpdatedOnProperty')
begin
	PRINT 'Refreshing trigger CPAFieldsUpdatedOnProperty...'
	DROP TRIGGER CPAFieldsUpdatedOnProperty
end
go

CREATE TRIGGER CPAFieldsUpdatedOnProperty ON PROPERTY
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	CPAFieldsUpdatedOnProperty    
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
	IF UPDATE(NOOFCLAIMS) 
	OR UPDATE(RENEWALTYPE) 
	BEGIN
		declare @nIdentityId	int
		
		select @nIdentityId=cast(substring(context_info,1,4) as int)
		from master.dbo.sysprocesses
		where spid=@@SPID
		and substring(context_info,1,4)<>0x0000000

		Insert into CPAUPDATE(CASEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
		Select distinct i.CASEID, @nIdentityId, system_user, getdate(),'CPAFieldsUpdatedOnProperty',APP_NAME()
		from inserted i
		join CASES C on (C.CASEID=i.CASEID)
		left join CPAUPDATE CPA on (CPA.CASEID=i.CASEID)
		where CPA.CASEID is null
		and C.REPORTTOTHIRDPARTY=1
	END
END
go
