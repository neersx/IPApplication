if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsUpdatedOnNames')
begin
	PRINT 'Refreshing trigger CPAFieldsUpdatedOnNames...'
	DROP TRIGGER CPAFieldsUpdatedOnNames
end
go
	
CREATE TRIGGER CPAFieldsUpdatedOnNames ON NAME
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	CPAFieldsUpdatedOnNames    
-- VERSION:	5
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17-Nov-2004	MF	SQA10670 2	Remove the check of the CPA Logging sitecontrol.
-- 11-APR-2005	MF	SQA9249	 3	Add the name type for Division "DIV" to the list of nametypes.
-- 31-AUG-2005	MF	SQA10874 4	Add new columns to CPAUPDATE and initialise
-- 17 Mar 2009	MF	SQ17490	 5	Ignore if trigger is being fired as a result of the audit details being updated

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	IF UPDATE(NAME) 
	OR UPDATE(TITLE) 
	OR UPDATE(INITIALS) 
	OR UPDATE(FIRSTNAME) 
	OR UPDATE(POSTALADDRESS) 
	OR UPDATE(STREETADDRESS) 
	OR UPDATE(MAINPHONE) 
	OR UPDATE(FAX)
	BEGIN
		declare @nIdentityId	int
		
		select @nIdentityId=cast(substring(context_info,1,4) as int)
		from master.dbo.sysprocesses
		where spid=@@SPID
		and substring(context_info,1,4)<>0x0000000

		Insert into CPAUPDATE(NAMEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
		Select distinct CN.NAMENO, @nIdentityId, system_user, getdate(),'CPAFieldsUpdatedOnNames',APP_NAME()
		from inserted i
		join CASENAME CN on (CN.NAMENO=i.NAMENO)
		join CASES C	 on (C.CASEID=CN.CASEID)
		left join CPAUPDATE CPA on (CPA.NAMEID=CN.NAMENO)
		where CPA.NAMEID is null
		and C.REPORTTOTHIRDPARTY=1
		and CN.NAMETYPE in ('I','D','R','Z','O','DIV')
	END
END
go
