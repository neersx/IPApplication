-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_QuickSearchPicklist
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[csw_QuickSearchPicklist]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.csw_QuickSearchPicklist.'
	drop procedure dbo.csw_QuickSearchPicklist
end
print '**** Creating procedure dbo.csw_QuickSearchPicklist...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create PROCEDURE [dbo].[csw_QuickSearchPicklist]
(
	@psSearchString		nvarchar(254),
	@pnUserIdentityId	int,
	@pnLimit		int
)
as
-- PROCEDURE:	csw_QuickSearchPicklist
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return predictive search suggestions for quick search field for CASES.

-- MODIFICATIONS :
-- Date		Who	Number		Version	Description
-- -----------	-------	--------	-------	-----------------------------------------------
-- 04/08/2017	MK	R71935		1	Procedure created.
-- 09/08/2017	AT	R72129		2	Only check ethical walls if function exists.
-- 17/08/2017	AT	R72000		3	Return case id.
-- 17 Aug 2017	MF	72177		4	Allow Related Cases to be suppressed from the Quick Search (AnySearch).
-- 12 Sept 2017	MF	72372		5	Case Search Type-ahead is displaying 3 rows in drop down list but only finds one when a Search icon is selected


Declare @sSQLString		nvarchar(max)
Declare @nErrorCode		int
Declare @nRowCount		int
Declare @bRowLevelSecurity	bit
Declare	@bCaseOffice		bit
Declare @bBlockCaseAccess	bit
Declare @bIsExternalUser	bit
Declare	@bSuppressRelatedCase	bit
Declare @sCaseJoin		nvarchar(200)

Set	@nErrorCode		= 0
Set	@bRowLevelSecurity	= 0
Set	@bCaseOffice		= 0
Set	@bBlockCaseAccess	= 0
Set	@bIsExternalUser	= 0

If @nErrorCode=0
Begin
	-----------------------------------------------------
	-- Check the Site Control to see if Related Case
	-- details are to be suppressed from the quick search
	-----------------------------------------------------
	Select @bSuppressRelatedCase=COLBOOLEAN
	from SITECONTROL
	where CONTROLID='Related Case Quick Search Suppressed'

	Set @nErrorCode=@@ERROR
End

If @nErrorCode=0
Begin
	---------------------------------------
	-- Check to see if the user is external
	---------------------------------------
	Select @bIsExternalUser=isnull(ISEXTERNALUSER,0)
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId

	Select @nErrorCode=@@ERROR,
	       @nRowCount =@@ROWCOUNT
End

If  @nErrorCode=0
and @nRowCount>0
Begin
	---------------------------------------
	-- Check to see if the user is impacted
	-- by Row Level Security
	---------------------------------------
	Select @bRowLevelSecurity = 1
	from IDENTITYROWACCESS U 
	join ROWACCESSDETAIL R on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = 'C'
	and U.IDENTITYID = @pnUserIdentityId

	Set @nErrorCode=@@ERROR
End

If @nErrorCode=0
Begin
	If @bRowLevelSecurity=1
	Begin
		---------------------------------------------
		-- If Row Level Security is in use for user,
		-- determine how/if Office is stored against 
		-- Cases.  It is possible to store the office
		-- directly in the CASES table or if a Case 
		-- is to have multiple offices then it is
		-- stored in TABLEATTRIBUTES.
		---------------------------------------------
		Select  @bCaseOffice = COLBOOLEAN
		from SITECONTROL
		where CONTROLID = 'Row Security Uses Case Office'

		Set @nErrorCode=@@ERROR
				
	
		---------------------------------------------
		-- Check to see if there are any Offices 
		-- held as TABLEATRRIBUTES of the Case. If
		-- not then treat as if Office is stored 
		-- directly in the CASES table.
		---------------------------------------------
		If(@bCaseOffice=0 or @bCaseOffice is null)
		and not exists (select 1 from TABLEATTRIBUTES where PARENTTABLE='CASES' and TABLETYPE=44)
			Set @bCaseOffice=1
	End
	Else Begin
		---------------------------------------------
		-- If Row Level Security is NOT in use for
		-- the current user, then check if any other 
		-- users are configured.  If they are, then 
		-- internal users that have no configuration 
		-- will be blocked from ALL cases.
		---------------------------------------------
		If @nRowCount=0
		Begin
			-------------------------------
			-- Also block result if the 
			-- @pnUserIdentityID is unknown
			-------------------------------
			Set @bBlockCaseAccess=1
		End
		ELSE
		If @bIsExternalUser=0
		Begin
			Select @bBlockCaseAccess = 1
			from IDENTITYROWACCESS U
			join USERIDENTITY UI	on (U.IDENTITYID = UI.IDENTITYID) 
			join ROWACCESSDETAIL R	on (R.ACCESSNAME = U.ACCESSNAME) 
			where R.RECORDTYPE = 'C' 
			and isnull(UI.ISEXTERNALUSER,0) = 0

			Set @nErrorCode=@@ERROR
		End
	End
End

If @bIsExternalUser = 1
Begin
	Set @sCaseJoin = 'join dbo.fn_FilterUserCases(@pnUserIdentityId, 1, null) FC ON (FC.CASEID=CI.CASEID)'+char(13)+char(10)+
		'join CASES C ON C.CASEID=CI.CASEID'
End
Else
Begin
	If exists (select * from sys.objects where name = 'fn_CasesEthicalWall')
	Begin
		Set @sCaseJoin = 'join dbo.fn_CasesEthicalWall(@pnUserIdentityId) C on (C.CASEID=CI.CASEID)'
	End
	Else
	Begin
		Set @sCaseJoin = 'join CASES C ON C.CASEID=CI.CASEID'
	End
End

If @nErrorCode=0
Begin
	Set @sSQLString='
	with CTE_CASEINDEXES
	as (	select DISTINCT CI.CASEID, 
				CASE(CI.SOURCE)
					WHEN(1) THEN ''Case Ref''
					WHEN(2) THEN ''Title''
					WHEN(3) THEN ''Family''
					WHEN(4) THEN ''Name Ref''
					WHEN(5) THEN ''Official Num''
					WHEN(6) THEN ''Case Stem''
					WHEN(7) THEN ''Related Case''
				END as [Using],
	
				CASE(CI.SOURCE)
					WHEN(1) THEN 1	-- IRN
					WHEN(6) THEN 2	-- Stem
					WHEN(5) THEN 3	-- Official Number
					WHEN(3) THEN 4	-- Case Family
					WHEN(4) THEN 5	-- Name Reference
					WHEN(2) THEN 6	-- Case Title
					WHEN(7) THEN 7	-- Related Case
				END as [SortOrder], 
				CI.GENERICINDEX
		from CASEINDEXES CI
		where CI.GENERICINDEX like @psSearchString + ''%'''+
		
		CASE WHEN(@bSuppressRelatedCase=1)
			THEN ' and CI.SOURCE<>7'
			ELSE ''
		END +'
		and	CASE(CI.SOURCE)
				WHEN(1) THEN ''1''	-- IRN
				WHEN(6) THEN ''2''	-- Stem
				WHEN(5) THEN ''3''	-- Official Number
				WHEN(3) THEN ''4''	-- Case Family
				WHEN(4) THEN ''5''	-- Name Reference
				WHEN(2) THEN ''6''	-- Case Title
				WHEN(7) THEN ''7''	-- Related Case
			END + CI.GENERICINDEX
			= (	select MIN(	CASE(CI2.SOURCE)
							WHEN(1) THEN ''1''	-- IRN
							WHEN(6) THEN ''2''	-- Stem
							WHEN(5) THEN ''3''	-- Official Number
							WHEN(3) THEN ''4''	-- Case Family
							WHEN(4) THEN ''5''	-- Name Reference
							WHEN(2) THEN ''6''	-- Case Title
							WHEN(7) THEN ''7''	-- Related Case
						END + CI2.GENERICINDEX)
				from CASEINDEXES CI2
				where CI2.CASEID=CI.CASEID' +
		
				CASE WHEN(@bSuppressRelatedCase=1)
					THEN '				and CI2.SOURCE<>7'
					ELSE ''
				END +'
				and CI2.GENERICINDEX like @psSearchString + ''%'')
		)

	select top (@pnLimit) *
	from
	(
		select
			C.CASEID AS Id,
			C.IRN, 
			CI.GENERICINDEX as ''MatchedOn'',
			CI.[Using],
			CI.[SortOrder]
		from CTE_CASEINDEXES CI' +CHAR(10)+
		
		@sCaseJoin + 
		
		CASE WHEN(@bRowLevelSecurity = 1 AND @bCaseOffice = 1)
			THEN char(10)+'		join dbo.fn_CasesRowSecurity(@pnUserIdentityId) R on (R.CASEID=CI.CASEID AND R.READALLOWED=1)'
		     WHEN(@bRowLevelSecurity = 1)
			THEN char(10)+'		join dbo.fn_CasesRowSecurityMultiOffice(@pnUserIdentityId) R on (R.CASEID=CI.CASEID AND R.READALLOWED=1)'
			ELSE ''
		END + 

		CASE WHEN(@bBlockCaseAccess=1 AND @bIsExternalUser <> 1)
			THEN char(10)+'		Where 1=0'
			ELSE ''
		END + '
		------------------------------
		-- Check KEYWORDS if there are
		-- no matching CASEINDEX rows
		------------------------------
		UNION ALL
		select
			C.CASEID AS Id,
			C.IRN, 
			KW.KEYWORD as ''MatchedOn'',
			''Keyword'' as ''Using'',
			8 as [SortOrder]
		from KEYWORDS KW
		join CASEWORDS CI on (CI.KEYWORDNO = KW.KEYWORDNO)' +CHAR(10)+
		
		@sCaseJoin + 
		
		CASE WHEN(@bRowLevelSecurity = 1 AND @bCaseOffice = 1)
			THEN char(10)+'		join dbo.fn_CasesRowSecurity(@pnUserIdentityId) R on (R.CASEID=CI.CASEID AND R.READALLOWED=1)'
		     WHEN(@bRowLevelSecurity = 1)
			THEN char(10)+'		join dbo.fn_CasesRowSecurityMultiOffice(@pnUserIdentityId) R on (R.CASEID=CI.CASEID AND R.READALLOWED=1)'
			ELSE ''
		END + '
		left join CTE_CASEINDEXES CIX on (CIX.CASEID=CI.CASEID)

		where KW.KEYWORD like @psSearchString + ''%''
		and CIX.CASEID is null' +

		CASE WHEN(@bBlockCaseAccess=1 AND @bIsExternalUser <> 1)
			THEN char(10)+'		and 1=0'
			ELSE ''
		END + '
	) X
	order by X.[SortOrder], X.IRN'

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnLimit		int,
					  @pnUserIdentityId	int,
					  @psSearchString	nvarchar(254)',
					  @pnLimit		= @pnLimit,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @psSearchString	= @psSearchString
End

return @nErrorCode
go
	

grant execute on dbo.csw_QuickSearchPicklist  to public
go