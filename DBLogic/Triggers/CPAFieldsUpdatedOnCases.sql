if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsUpdatedOnCases')
begin
	PRINT 'Refreshing trigger CPAFieldsUpdatedOnCases...'
	DROP TRIGGER CPAFieldsUpdatedOnCases
end
go

CREATE TRIGGER CPAFieldsUpdatedOnCases ON CASES
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	CPAFieldsUpdatedOnCases    
-- VERSION:	7
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17-Nov-2004	MF	SQA10670 2	Remove the check of the CPA Logging sitecontrol.
-- 18-Apr-2005	MF	SQA11279 3	Monitor changes against CASETYPE, COUNTRYCODE, 
--					PROPERTYTYPE, CASECATEGORY, SUBTYPE
-- 28-Apr-2005	MF	SQA11307 4	Monitor changes against OFFICEID
-- 31-AUG-2005	MF	SQA10874 5	Add new columns to CPAUPDATE and initialise
-- 28-JUL-2006	MF	SQA13099 6	Changing the IRN should trigger the case to be reported to CPA
-- 17 Mar 2009	MF	SQA17490 7	Ignore if trigger is being fired as a result of the audit details being updated

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	IF UPDATE(NOOFCLASSES) 
	OR UPDATE(STOPPAYREASON)
	OR UPDATE(EXTENDEDRENEWALS)
	OR UPDATE(ENTITYSIZE)   
	OR UPDATE(INTCLASSES)
	OR UPDATE(LOCALCLASSES)
	OR UPDATE(TITLE)
	OR UPDATE(NOINSERIES) 
	OR UPDATE(REPORTTOTHIRDPARTY)
	OR UPDATE(CASETYPE)
	OR UPDATE(COUNTRYCODE)
	OR UPDATE(PROPERTYTYPE)
	OR UPDATE(CASECATEGORY)
	OR UPDATE(SUBTYPE)
	OR UPDATE(OFFICEID)
	OR UPDATE(IRN)
	BEGIN
		declare @nIdentityId	int
		
		select @nIdentityId=cast(substring(context_info,1,4) as int)
		from master.dbo.sysprocesses
		where spid=@@SPID
		and substring(context_info,1,4)<>0x0000000

		Insert into CPAUPDATE(CASEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
		Select distinct i.CASEID, @nIdentityId, system_user, getdate(),'CPAFieldsUpdatedOnCases',APP_NAME()
		from inserted i
		join deleted d on (d.CASEID=i.CASEID)
		left join CPAUPDATE CPA on (CPA.CASEID=i.CASEID)
		where CPA.CASEID is null
		and (i.REPORTTOTHIRDPARTY=1 or d.REPORTTOTHIRDPARTY=1)
	END
END
go
