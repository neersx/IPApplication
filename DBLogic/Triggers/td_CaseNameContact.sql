if exists (select * from sysobjects where type='TR' and name = 'td_CaseNameContact')
begin
	PRINT 'Refreshing trigger td_CaseNameContact...'
	DROP TRIGGER td_CaseNameContact
end
go

CREATE TRIGGER td_CaseNameContact
ON CASENAME
FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER:	td_CaseNameContact  
-- VERSION:	7
-- DESCRIPTION:	Recalculate the AccountCaseContact information for the Account and Case

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Apr-2004	JEK	1033	 1	Procedure created
-- 28-Jul-2006	MF	SQA13131 2	Performance problem.  Previously the stored procedure
--					ua_MaintainAccountCaseContact was called for each different
--					AccountId but not limited to a specific Case.  The code from
--					ua_MaintainAccountCaseContact has been incorporated into this 
--					trigger so that all rows in the 'deleted' table can be processed
--					at once and limited to just the Cases that have changed.
-- 02-Aug-2006	MF	SQA13131 3	Revisit. Failed testing.
-- 23-Jan-2007	MF	SQA14169 4	Duplicate key error on Insert into ACCOUNTCASECONTACT.  Add DISTINCT
--					clause to the SELECT.
-- 20-Feb-2009	MF	SQA17136 5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 26-Feb-2009	MF	RFC7647	 6	Improve performance by pulling SITECONTROL out of main statements. 
-- 13-May-2009	MF	SQA17633 7	Improve performance by introducing an interim step before DELETE from ACCOUNTCASECONTACT.

Declare @nErrorCode 	int
Declare @nRowCount 	int

Declare @sNameTypeList	nvarchar(200)
Declare @sCaseTypeList	nvarchar(200)	

Declare @tbCaseName table(
		CASEID		int	not null,
		ACCOUNTID	int	not null
		)

Set transaction isolation level read uncommitted
Set @nErrorCode = 0

-------------------------------------------
-- Get the list of NameTypes that determine
-- what Cases a client can access.
-------------------------------------------
If @nErrorCode = 0
Begin
	select @sNameTypeList=replace(COLCHARACTER, ' ', '')
	from SITECONTROL
	where CONTROLID='Client Name Types'
	
	Set @nErrorCode=@@Error
End

-------------------------------------------
-- Get the list of CaseTypes that determine
-- what Cases a client can access.
-------------------------------------------
If @nErrorCode = 0
Begin
	select @sCaseTypeList=replace(COLCHARACTER, ' ', '')
	from SITECONTROL
	where CONTROLID='Client Case Types'
	
	Set @nErrorCode=@@Error
End

If @nErrorCode=0
and @sNameTypeList is not null
and @sCaseTypeList is not null
Begin
	Insert into @tbCaseName(CASEID,ACCOUNTID)
	Select distinct CN.CASEID, AN.ACCOUNTID
	from deleted CN
	join dbo.fn_Tokenise(@sNameTypeList,',') NT on (NT.Parameter=CN.NAMETYPE)
	-- Check if the WorkBenches are implemented, i.e. there are NameNos in the 
	-- ACCESSACCOUNTNAMES table.
	join ACCESSACCOUNTNAMES AN 	on (AN.NAMENO = CN.NAMENO)
	join CASES C			on (C.CASEID = CN.CASEID)
	join dbo.fn_Tokenise(@sCaseTypeList,',') CT on (CT.Parameter=C.CASETYPE)
	
	Select	@nErrorCode=@@Error,
		@nRowCount=@@Rowcount
	
	If  @nErrorCode=0
	and @nRowCount>0
	Begin
		---------------------------------------------
		-- Delete all of the ACCOUNTCASECONTACT rows 
		-- associated with the Case and Names deleted
		---------------------------------------------
		Delete ACC
		from ACCOUNTCASECONTACT ACC
		join @tbCaseName CN	on (CN.CASEID=ACC.ACCOUNTCASEID
					and CN.ACCOUNTID=ACC.ACCOUNTID)

		Select  @nErrorCode=@@Error
	End

	If  @nErrorCode=0
	and @nRowCount>0
	Begin
		Insert into ACCOUNTCASECONTACT (ACCOUNTID, ACCOUNTCASEID, CASEID, NAMETYPE, NAMENO, SEQUENCE)
		select distinct NT.ACCOUNTID, NT.CASEID, NT.CASEID, substring(NT.NAMESTUFF,3,3), convert(int,substring(NT.NAMESTUFF,6,11)), convert(int,substring(NT.NAMESTUFF,17,11))
		-- We need to get a single CASENAME row for each Case which presented a problem as
		-- the user may be linked to multiple name and allow access via multiple Name Types.
		-- The solution is to give certain hardcoded NameTypes a relative weighting in order to
		-- determine which NameType to use.
		from @tbCaseName CN
		join (	select	A.ACCOUNTID	as ACCOUNTID,
				CN.CASEID	as CASEID, 
				min(CASE (NAMETYPE) WHEN('I') THEN '01'
						    WHEN('R') THEN '02'
						    WHEN('A') THEN '03'
						    WHEN('&') THEN '04'
						    WHEN('D') THEN '05'
						    WHEN('Z') THEN '06'
						    WHEN('O') THEN '07'
						    WHEN('J') THEN '08'
							      ELSE '10'
				    END 
					+ convert(nchar(3),CN.NAMETYPE)
					+ convert(char(11),CN.NAMENO)
					+ convert(char(11),CN.SEQUENCE)) as NAMESTUFF
	      		from ACCESSACCOUNT A
			join ACCESSACCOUNTNAMES N on (N.ACCOUNTID = A.ACCOUNTID)
	      		join CASENAME CN	on (CN.NAMENO=N.NAMENO)
			join dbo.fn_Tokenise(@sNameTypeList,',') T on (T.Parameter=CN.NAMETYPE)
			where A.ISINTERNAL = 0
			group by A.ACCOUNTID, CN.CASEID) NT	on (NT.CASEID=CN.CASEID
								and NT.ACCOUNTID=CN.ACCOUNTID)

		Select  @nErrorCode=@@Error
	End
End

if @nErrorCode <> 0
Begin
	Raiserror  ( 'Error %d extracting AccountCaseContact information', 16,1, @nErrorCode)
	Rollback
End
go