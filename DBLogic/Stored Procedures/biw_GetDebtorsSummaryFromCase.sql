-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetDebtorsSummaryFromCase] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetDebtorsSummaryFromCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetDebtorsSummaryFromCase].'
	drop procedure dbo.[biw_GetDebtorsSummaryFromCase]
end
print '**** Creating procedure dbo.[biw_GetDebtorsSummaryFromCase]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetDebtorsSummaryFromCase]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnCaseListKey		int		= null,	-- return all debtors in a case list
				@pnCaseKey		int		= null,	-- return all debtors in a single case
				@pbUseRenewalDebtor	bit		= 0	-- use renewal debtor
as
-- PROCEDURE :	biw_GetDebtorsSummaryFromCase
-- VERSION :	2
-- DESCRIPTION:	A procedure that returns all of the debtors associated to a Case List
--		NOTE: If adding columns, you need to also add the same columns to biw_GetDebtorDetails
--
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC	        Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 29-Jan-2010	DV	RFC100508	1	Procedure created.
-- 02 Nov 2015	vql	R53910		2	Adjust formatted names logic (DR-15543).

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@sWhere		nvarchar(1000)

Set @ErrorCode = 0

If @ErrorCode = 0
Begin
	Set @sSQLString = "
			Select 
			N.NAMENO as NameNo,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'FormattedName',
			ISNULL(CN.BILLPERCENTAGE, 100) as 'BillPercentage',			
			CN.CASEID AS 'CaseKey',		
			C.IRN as 'CaseRef',
			IPN.CONSOLIDATION as 'Consolidation',							
			null as 'BilledAmount'
			From "
			
			Set @sWhere = "WHERE CND.NAMETYPE = 'D'
			and (CND.EXPIRYDATE is null
				OR CND.EXPIRYDATE > GetDate())
			and CND.CASEID "
						
			if (@pnCaseKey is not null)
			Begin
				Set @sWhere = @sWhere + "= @pnCaseKey"
			End
			Else if (@pnCaseListKey is not null)
			Begin
				Set @sWhere = @sWhere + "in (select CASEID from CASELISTMEMBER where CASELISTNO = @pnCaseListKey)"
			End
			
			If (@pbUseRenewalDebtor = 1)
			Begin
				-- Construct CaseName table for renewal debtor with debtor fallback
				Set @sSQLString = @sSQLString + char(10) + "(SELECT DISTINCT ISNULL(CNZNN, CNDNN) AS NAMENO, ISNULL(CNZCID,CNDCID) AS CASEID,
				ISNULL(CNZBP,CNDBP) AS BILLPERCENTAGE, ISNULL(CNZED, CNDED) AS EXPIRYDATE
				FROM (SELECT CND.NAMETYPE AS CNDNT, CND.NAMENO AS CNDNN, CND.CASEID AS CNDCID, CND.BILLPERCENTAGE AS CNDBP, CND.EXPIRYDATE AS CNDED, 
					CNZ.NAMETYPE AS CNZNT, CNZ.NAMENO AS CNZNN, CNZ.CASEID AS CNZCID, CNZ.BILLPERCENTAGE AS CNZBP, CNZ.EXPIRYDATE AS CNZED
					FROM CASENAME CND 
					LEFT JOIN CASENAME CNZ on (CNZ.CASEID = CND.CASEID AND CNZ.NAMETYPE = 'Z'
						and (CNZ.EXPIRYDATE is null
							OR CNZ.EXPIRYDATE > GetDate())
					)" + char(10) + @sWhere + ") as CNX"
			End
			Else
			Begin
				-- Construct CaseName table for debtor only
				Set @sSQLString = @sSQLString + char(10) + "(Select NAMETYPE, NAMENO, CASEID, BILLPERCENTAGE, EXPIRYDATE
								FROM CASENAME CND" + char(10) + @sWhere 
								
			End
			
			Set @sSQLString = @sSQLString + char(10) + ") as CN
				Left Join ASSOCIATEDNAME AN ON (AN.NAMENO = CN.NAMENO
								AND AN.RELATIONSHIP = 'BIL'
								AND AN.SEQUENCE = (SELECT MIN(SEQUENCE) FROM ASSOCIATEDNAME WHERE NAMENO = CN.NAMENO AND RELATIONSHIP = 'BIL'))
				Join NAME N on (N.NAMENO = ISNULL(AN.RELATEDNAME,CN.NAMENO))
				Join CASES C on (C.CASEID = CN.CASEID)
				Join IPNAME IPN on (N.NAMENO = IPN.NAMENO)"



	exec @ErrorCode=sp_executesql @sSQLString,
				N'	@pnCaseListKey	int,
					@pnCaseKey	int',
					@pnCaseListKey=@pnCaseListKey,
					@pnCaseKey=@pnCaseKey

End

return @ErrorCode
go

grant execute on dbo.[biw_GetDebtorsSummaryFromCase]  to public
go
