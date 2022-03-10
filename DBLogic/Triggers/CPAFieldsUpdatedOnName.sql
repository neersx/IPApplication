if exists (select * from sysobjects where type='TR' and name = 'CPAFieldsUpdatedOnName')
begin
	PRINT 'Refreshing trigger CPAFieldsUpdatedOnName...'
	DROP TRIGGER CPAFieldsUpdatedOnName
end
go
	
CREATE TRIGGER CPAFieldsUpdatedOnName ON NAME
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	CPAFieldsUpdatedOnName    
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Feb-2009	MF	SQA17412 1	A name used as an Owner against a Case should trigger the cases
--					to be reported to CPA if the Name changes.

If (UPDATE(NAME) OR UPDATE(FIRSTNAME) OR UPDATE(NAMECODE))
Begin	
	declare @nIdentityId	int
	
	select @nIdentityId=cast(substring(context_info,1,4) as int)
	from master.dbo.sysprocesses
	where spid=@@SPID
	and substring(context_info,1,4)<>0x0000000

	Insert into CPAUPDATE(CASEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
	Select distinct C.CASEID, @nIdentityId, system_user, getdate(),'CPAFieldsUpdatedOnName',APP_NAME()
	from inserted i
	join CASENAME CN	on (CN.NAMENO=i.NAMENO
				and CN.NAMETYPE='O'
				and(CN.EXPIRYDATE is null OR CN.EXPIRYDATE>getdate()))
	join CASES C		on (C.CASEID=CN.CASEID)
	left join CPAUPDATE CPA on (CPA.CASEID=CN.CASEID)
	where CPA.CASEID is null
	and C.REPORTTOTHIRDPARTY=1

	Insert into CPAUPDATE(NAMEID, INSERTIDENTITYID, INSERTUSERID, INSERTDATETIME, INSERTTRIGGER, INSERTAPPLICATION)
	Select distinct i.NAMENO, @nIdentityId, system_user, getdate(),'CPAFieldsUpdatedOnName',APP_NAME()
	from inserted i
	join CASENAME CN	on (CN.NAMENO=i.NAMENO
				and CN.NAMETYPE in ('I','D','R','Z','O','DIV')
				and(CN.EXPIRYDATE is null OR CN.EXPIRYDATE>getdate()))
	join CASES C		on (C.CASEID=CN.CASEID)
	left join CPAUPDATE CPA on (CPA.NAMEID=i.NAMENO)
	where CPA.NAMEID is null
	and C.REPORTTOTHIRDPARTY=1
End
go
