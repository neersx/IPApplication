if exists (select * from sysobjects where type='TR' and name = 'tu_CaseContact')
begin
	PRINT 'Refreshing trigger tu_CaseContact...'
	DROP TRIGGER tu_CaseContact
end
go

CREATE TRIGGER tu_CaseContact
ON CASES
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	tu_CaseContact  
-- VERSION:	6
-- DESCRIPTION:	Recalculate the AccountCaseContact information for the Account and Case

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Apr-2004	JEK	1033	 1	Procedure created
-- 28-Jul-2006	MF	SQA13131 2	Performance problem.  Previously the stored procedure
--					ua_MaintainAccountCaseContact was called for each different
--					AccountId but not limited to a specific Case.  The code from
--					ua_MaintainAccountCaseContact has been incorporated into this 
--					trigger so that all rows in the 'deleted' or 'inserted' table can 
--					be processed at once and limited to just the Cases that have changed.
-- 12-Oct-2006	MF	RFC4510	 3	Only insert rows into ACCOUNTCASECONTACT if the CaseType is being
--					changed from a CaseType that did not allow client access, to one
--					that does allow client access.
-- 20-Feb-2009	MF	SQA17136 4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 26-Feb-2009	MF	RFC7647	 5	Improve performance by pulling SITECONTROL out of main statements. 
-- 13-May-2009	MF	SQA17633 6	Improve performance by introducing an interim step before DELETE from ACCOUNTCASECONTACT.

-- Trigger is only required if the CASETYPE has changed.
If NOT UPDATE(LOGDATETIMESTAMP)
and    UPDATE(CASETYPE) 
Begin
	Declare @nErrorCode 	int
	Declare @nRowCount 	int

	Declare @sNameTypeList	nvarchar(200)
	Declare @sCaseTypeList	nvarchar(200)	

	Declare @tbCaseName table(
		CASEID		int	not null,
		ACCOUNTID	int	not null,
		NEWCASETYPE	nchar(1) collate database_default NULL,
		OLDCASETYPE	nchar(1) collate database_default NULL
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
	and @sCaseTypeList is not null
	Begin
		Insert into @tbCaseName(CASEID,ACCOUNTID,NEWCASETYPE, OLDCASETYPE)
		Select distinct C1.CASEID, AN.ACCOUNTID,left(T1.Parameter,1), left(T2.Parameter,1)
		from inserted C1
		join deleted  C2		on (C2.CASEID=C1.CASEID)
		-- Check if the WorkBenches are implemented, i.e. there are NameNos in the 
		-- ACCESSACCOUNTNAMES table.
		join CASENAME CN		on (CN.CASEID = C1.CASEID)
		join ACCESSACCOUNTNAMES AN 	on (AN.NAMENO = CN.NAMENO)
		left join dbo.fn_Tokenise(@sCaseTypeList,',') T1 on (T1.Parameter=C1.CASETYPE)
		left join dbo.fn_Tokenise(@sCaseTypeList,',') T2 on (T2.Parameter=C2.CASETYPE)
		-- The delete from ACCOUNTCASECONTACT is only necessary if 
		-- the Case Type is updated, and the result is that the new value moves 
		-- the case into or out of the Client Case Types list.
		where isnull(C1.CASETYPE,'')<>isnull(C2.CASETYPE,'')	-- redundant line that improves performance
		and  ((T1.Parameter is not null and T2.Parameter is null)
		   or (T2.Parameter is not null and T1.Parameter is null))
		
		Select	@nErrorCode=@@Error,
			@nRowCount=@@Rowcount
		
		If  @nErrorCode=0
		and @nRowCount>0
		Begin
			-- Delete all of the ACCOUNTCASECONTACT rows associated with the Case and Names deleted
			Delete ACC
			from ACCOUNTCASECONTACT ACC
			join @tbCaseName CN	on (CN.CASEID=ACC.ACCOUNTCASEID
						and CN.ACCOUNTID=ACC.ACCOUNTID)

			Select  @nErrorCode=@@Error
		End
	End
	
	If  @nErrorCode=0
	and @sNameTypeList is not null
	and @sCaseTypeList is not null
	and @nRowCount>0
	Begin
		Insert into ACCOUNTCASECONTACT (ACCOUNTID, ACCOUNTCASEID, CASEID, NAMETYPE, NAMENO, SEQUENCE)
		select distinct NT.ACCOUNTID, NT.CASEID, NT.CASEID, substring(NT.NAMESTUFF,3,3), convert(int,substring(NT.NAMESTUFF,6,11)), convert(int,substring(NT.NAMESTUFF,17,11))
		-- We need to get a single CASENAME row for each Case which presented a problem as
		-- the user may be linked to multiple name and allow access via multiple Name Types.
		-- The solution is to give certain hardcoded NameTypes a relative weighting in order to
		-- determine which NameType to use.
		from @tbCaseName C1
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
			group by A.ACCOUNTID, CN.CASEID) NT	 on (NT.CASEID =C1.CASEID
								 and NT.ACCOUNTID=C1.ACCOUNTID)
		-- The insert into ACCOUNTCASECONTACT is only necessary if 
		-- the Case Type is now in the Client Case Types list but before
		-- the Update was not.
		where C1.NEWCASETYPE is not null
		and C1.OLDCASETYPE is null

		Select  @nErrorCode=@@Error
	End
	
	if @nErrorCode <> 0
	Begin
		Raiserror  ( 'Error %d extracting AccountCaseContact information', 16,1, @nErrorCode)
		Rollback
	End
End
go