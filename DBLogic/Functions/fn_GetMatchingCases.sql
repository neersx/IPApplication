-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetMatchingCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetMatchingCases'))
begin
	print '**** Drop function dbo.fn_GetMatchingCases.'
	drop function dbo.fn_GetMatchingCases
	print '**** Creating function dbo.fn_GetMatchingCases...'
	print ''
end
go


SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetMatchingCases
(
	@psSearch		nvarchar(max),
	@pnUserIdentityId	int
) 
RETURNS 
	@tblCases	table ( CASEID int not null)
AS
-- Function :	fn_GetMatchingCases
-- VERSION :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return a list of CASEIDs for cases that match the search query.
--		The search is based on the AnySearch logic from csw_ConstructCaseWhere.
--		Currently does not filter on external users and CRM types.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 5 Jan 2017	LP	R69856	 1	Function created
-- 23 Mar 2020	BS	DR-57435 2	DB public role missing execute permission on some stored procedures and functions
Begin
	if (@psSearch = '' or @psSearch is null)
	Begin
		return
	end

	Declare @sCaseList	nvarchar(max)
	Declare @sList		nvarchar(max)

	Set @sList = ''
	Select @sList = @sList + isnull(nullif(',', ',' + @sList), '') + dbo.fn_WrapQuotes(CASETYPE,0,0)
	From dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,null, 0, 0, getdate())
	Where ACTUALCASETYPE is null

	if exists(select 1 from CASES where IRN=@psSearch)
	begin
		-- If it also matches directly on an OfficialNumber
		-- then return the rows that match directly on both
		If exists(select 1 from OFFICIALNUMBERS O 
				join NUMBERTYPES N on (N.NUMBERTYPE=O.NUMBERTYPE
						and N.ISSUEDBYIPOFFICE=1)
				where O.OFFICIALNUMBER=@psSearch)
		Begin
			insert into @tblCases
			SELECT DISTINCT XC.CASEID
			from CASES XC
			join (  SELECT C.CASEID
				FROM CASES C WITH (NOLOCK)
				where C.IRN = dbo.fn_WrapQuotes(@psSearch,0,0)
				UNION ALL
				SELECT O.CASEID
				FROM OFFICIALNUMBERS O WITH (NOLOCK)
				join NUMBERTYPES N WITH (NOLOCK) on (N.NUMBERTYPE = O.NUMBERTYPE and N.ISSUEDBYIPOFFICE=1)
				where O.OFFICIALNUMBER = @psSearch) XX on (XX.CASEID=XC.CASEID)
			join dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,null,0,0,getdate()) CT
					on (CT.CASETYPE = XC.CASETYPE)
			where (XX.CASEID is not null)
		End
		Else Begin
			insert into @tblCases
			SELECT DISTINCT XC.CASEID
			from CASES XC
			join dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,null,0,0,getdate()) CT
					on (CT.CASETYPE = XC.CASETYPE)
			where (XC.IRN = @psSearch)
		End
	End
	Else Begin
		insert into @tblCases
		SELECT DISTINCT XC.CASEID
		from CASES XC
		join dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,null,0,0,getdate()) CT
					on (CT.CASETYPE = XC.CASETYPE)
		join (SELECT CR.CASEID
			FROM CASEINDEXES CR WITH (NOLOCK)
			where CR.GENERICINDEX like @psSearch + '%'
			UNION ALL
			SELECT CW.CASEID
			FROM KEYWORDS  KW WITH (NOLOCK)
			join CASEWORDS CW WITH (NOLOCK) on (CW.KEYWORDNO = KW.KEYWORDNO)
			left join CASEINDEXES CR WITH (NOLOCK) on (CR.GENERICINDEX like @psSearch + '%' and CR.CASEID = CW.CASEID)
			where CR.CASEID is null
			and KW.KEYWORD like @psSearch + '%') XX on (XX.CASEID=XC.CASEID)

	End

RETURN 
End
Go

grant SELECT on dbo.fn_GetMatchingCases to public
GO
