if exists (select * from sysobjects where type='TR' and name = 'tu_CaseNameContact')
begin
	PRINT 'Refreshing trigger tu_CaseNameContact...'
	DROP TRIGGER tu_CaseNameContact
end
go

CREATE TRIGGER tu_CaseNameContact
ON CASENAME
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	tu_CaseNameContact  
-- VERSION:	8
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
-- 02-Aug-2006	MF	SQA13131 3	Revisit. Failed testing.
-- 23-Jan-2007	MF	SQA14169 4	Duplicate key error on Insert into ACCOUNTCASECONTACT.  Add DISTINCT
--					clause to the SELECT.
-- 20-Feb-2009	MF	SQA17136 5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 26-Feb-2009	MF	RFC7647	 6	Improve performance by pulling SITECONTROL out of main statements. 
-- 17 Mar 2009	MF	SQA17490 7	Ignore if trigger is being fired as a result of the audit details being updated
-- 13-May-2009	MF	SQA17633 8	Improve performance by introducing an interim step before DELETE from ACCOUNTCASECONTACT.

If NOT UPDATE(LOGDATETIMESTAMP)
and  ( UPDATE(CASEID)
    or UPDATE(NAMETYPE)
    or UPDATE(NAMENO))
Begin

	Declare @nErrorCode 	int	
	Declare @nRowCount 	int
	declare @sSQLString	nvarchar(4000)
	Declare @sNameTypeList	nvarchar(200)
	Declare @sCaseTypeList	nvarchar(200)
	
	-- A Temporary Table is being used because we need to use
	-- dynamic SQL later as a performance improvement
	Create table #TEMPCASENAME(
			CASEID		int		not null,
			ACCOUNTID	int		not null
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
		-------------------------------------------------
		-- PERFORMANCE TUNING IMPROVEMENT
		-- Load details from deleted and inserted tables
		-- into temporary table so that dynamic SQL may
		-- be used.
		-------------------------------------------------	
		insert into #TEMPCASENAME(CASEID, ACCOUNTID)
		Select distinct CN.CASEID, AN.ACCOUNTID
		from (	select CASEID, NAMETYPE, NAMENO
			from deleted 
			UNION ALL
			select CASEID,NAMETYPE, NAMENO
			from inserted) CN
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
			from #TEMPCASENAME CN
			join ACCOUNTCASECONTACT ACC on (ACC.ACCOUNTCASEID=CN.CASEID
						    and ACC.ACCOUNTID=CN.ACCOUNTID)
			Select  @nErrorCode=@@Error
		End

		If  @nErrorCode=0
		and @nRowCount>0
		Begin
			-- This was a performance improvement step
			-- so the list of Name Types can be embedded 
			-- into the dynamic SQL.
			select @sNameTypeList=dbo.fn_WrapQuotes(@sNameTypeList,1,0)			

			Set @sSQLString="
			Insert into ACCOUNTCASECONTACT (ACCOUNTID, ACCOUNTCASEID, CASEID, NAMETYPE, NAMENO, SEQUENCE)
			select distinct NT.ACCOUNTID, NT.CASEID, NT.CASEID,substring(NT.NAMESTUFF,3,3), convert(int,substring(NT.NAMESTUFF,6,11)), convert(int,substring(NT.NAMESTUFF,17,11))
			-- We need to get a single CASENAME row for each Case which presented a problem as
			-- the user may be linked to multiple name and allow access via multiple Name Types.
			-- The solution is to give certain hardcoded NameTypes a relative weighting in order to
			-- determine which NameType to use.
			from #TEMPCASENAME CN
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
	      			join CASENAME CN	  on (CN.NAMENO=N.NAMENO)
				where A.ISINTERNAL = 0
				and CN.NAMETYPE in ("+@sNameTypeList+")
				group by A.ACCOUNTID, CN.CASEID) NT	on (NT.CASEID=CN.CASEID
									and NT.ACCOUNTID=CN.ACCOUNTID)"

			exec @nErrorCode=sp_executesql @sSQLString
		End
	End

	if @nErrorCode <> 0
	Begin
		Raiserror  ( 'Error %d extracting AccountCaseContact information', 16,1, @nErrorCode)
		Rollback
	End
End
go