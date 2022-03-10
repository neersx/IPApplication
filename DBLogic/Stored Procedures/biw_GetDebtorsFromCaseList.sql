-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetDebtorsFromCaseList] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetDebtorsFromCaseList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetDebtorsFromCaseList].'
	drop procedure dbo.[biw_GetDebtorsFromCaseList]
end
print '**** Creating procedure dbo.[biw_GetDebtorsFromCaseList]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetDebtorsFromCaseList]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnCaseListKey		int		= null,	-- return all debtors in a case list
				@pnCaseKey		int		= null,	-- return all debtors in a single case,
				@psCaseKeyCSVList		nvarchar(max) = null,
				@pbUseRenewalDebtor	bit		= 0,	-- use renewal debtor, if true return renewal debtors, if false
										-- return debtors, if null return both
                                @psAction               nvarchar(2)     = null -- case action used in the bill
as
-- PROCEDURE :	biw_GetDebtorsFromCaseList
-- VERSION :	24
-- DESCRIPTION:	A procedure that returns all of the debtors associated to a Case List
--
--		*******************************************
--		NOTE: If adding columns, you need to also add the same columns to biw_GetBillDebtors and biw_GetDebtorDetails
--		*******************************************
--
-- COPYRIGHT:	Copyright 1993 - 2014 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 29-Jan-2010	AT	RFC3605		1	Procedure created.
-- 03-May-2010	AT	RFC9092		2	Add additional columns.
-- 07-May-2010	AT	RFC9135		3	Return Bill Format Profile.
-- 11-May-2010	AT	RFC9092		4	Modify to return debtor list for 1 case only.
-- 11-Jul-2010	AT	RFC7278		5	Return BillMapProfile
-- 15-Jul-2010	AT	RFC7271		6	Return AddressChangeReason
-- 10-Aug-2010	AT	RFC9403		7	Return Renewal Debtor.
-- 06-Sep-2010	AT	RFC9741		8	Filter expired debtors.
-- 12-Apr-2011	AT	RFC10473		9	Return Send Bills To name of debtor if available.
-- 04-Jan-2012	AT	RFC9165		10	Return Buy Rate.
-- 01-Feb-2012	AT	RFC11864		11	Return Send Bills To name separately.
-- 29-Aug-2012	LP	RFC10474		12	Return IsClient flag.
-- 30-Jan-2013	DV	RFC100777	13	Call fn_GetBestMatchAssociatedNameNo to get the best match Associated Name
-- 13-Feb-2013	DV	RFC13175	14	Remove OfficeKey from the result set
-- 29-Apr-2012	MS	R11732		15	Retreive ReferenceNo from CASENAME rather than having null value
-- 19-Aug-2013	vql	DR-641		16	Return both Renewal Debtors and Debtors depending on pbUseRenewalDebtor.
-- 12-Sep-2014  SS	RFC39345	17	Added parameter to send list of CaseIDs in comma separated form
-- 02 Nov 2015	vql	R53910		18	Adjust formatted names logic (DR-15543).
-- 13 Feb 2017	DV	R64225		19	Check if associated name has debotor name type classification
-- 07 Feb 2018  MS      R72578          20      Added case action logic for fetching best fit debtor
-- 07 Mar 2018  AK      R73598          21      added HasOfficeInEu in resultset
-- 11 Oct 2018  MS      DR-43550        22      Return Office Entity 
-- 30 Oct 2019  MS      DR-53313        23      Return FormattedNameWithCode column
-- 24 Mar 2020	LP	DR-7536		24	Return null Language columns

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(max)
Declare		@sWhere		nvarchar(max)
Declare		@sLookupCulture	nvarchar(10)
Declare		@bDebtorHasSameNameType bit

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

If @ErrorCode = 0
Begin 
	Set @sSQLString="
				Select @bDebtorHasSameNameType= CASE WHEN PICKLISTFLAGS & 16 = 16 then 1 else 0 end 
				from NAMETYPE 
				where NAMETYPE='D'"

				exec @ErrorCode = sp_executesql @sSQLString,
							N'@bDebtorHasSameNameType	bit			output',
							  @bDebtorHasSameNameType	= @bDebtorHasSameNameType	output
End

If @ErrorCode = 0
Begin
	Set @sSQLString = "
			Select 
			N.NAMENO as NameNo,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'FormattedName',
                        dbo.fn_ApplyNameCodeStyle(dbo.fn_FormatNameUsingNameNo(N.NAMENO, null), NT.SHOWNAMECODE, N.NAMECODE) as FormattedNameWithCode,
			ISNULL(CN.BILLPERCENTAGE, 100) as 'BillPercentage',
			null as 'Currency',
			null as 'BuyExchangeRate',
			null as 'SellExchangeRate',
			2 as 'DecimalPlaces',
			null as 'RoundBilledValues',
			CN.REFERENCENO as 'ReferenceNo',
			null as 'AttentionName',
			null as 'Address',
			null as 'TotalCredits',
			null as 'Instructions',
			null as 'TaxCode',
			null AS 'TaxDescription',
			null AS 'TaxRate',
			null AS 'AttentionNameKey',
			null AS 'AddressKey',
			CN.CASEID AS 'CaseKey',			
			null as 'OpenItemNo',
			null as 'LogDateTimeStamp',
			1 as 'AllowMultiCase',
			null as 'BillFormatProfileKey',
			null as 'BillMapProfileKey',
			null as 'BillMapProfileDescription',
			null as 'BillingCap',
			null as 'BilledAmount',
			null as 'BillingCapStart',
			null as 'BillingCapEnd',
			null as 'AddressChangeReason',
			ASSOCN.NAMENO as 'BillToNameKey',
			0 as HasOfficeInEu,
			dbo.fn_FormatNameUsingNameNo(ASSOCN.NAMENO, null) as 'BillToFormattedName',
			case when I.NAMENO IS NULL then 0 else 1 end as 'IsClient',"			
			+dbo.fn_SqlTranslatedColumn('NT','DESCRIPTION',null,null,@sLookupCulture,@pbCalledFromCentura) + " as 'NameTypeDescription',
			NT.NAMETYPE as 'NameType',
            null as 'OfficeEntity',
			null as 'LanguageKey',
			null as 'LanguageDescription'
			From "
			
			Set @sWhere = "Where " + 
				Case 
				when @pbUseRenewalDebtor is null
					then "CND.NAMETYPE in ('D', 'Z') "
				when (@pbUseRenewalDebtor = 0)
					then "CND.NAMETYPE in ('D') "
				else
					"CND.NAMETYPE in ('Z') "
				End + "
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
			Else If (@psCaseKeyCSVList is not null and @psCaseKeyCSVList != '')
			Begin
				Set @sWhere = @sWhere  + char(10) + " in (" +  @psCaseKeyCSVList + ")"
			End
			
			If (@pbUseRenewalDebtor = 1)
			Begin
				-- Construct CaseName table for renewal debtor with debtor fallback
				Set @sSQLString = @sSQLString + char(10) + "(SELECT DISTINCT ISNULL(CNZNN, CNDNN) AS NAMENO, 
										ISNULL(CNZCID,CNDCID) AS CASEID,
										ISNULL(CNZBP,CNDBP) AS BILLPERCENTAGE, 
										ISNULL(CNZED, CNDED) AS EXPIRYDATE, 
										CNZREF AS REFERENCENO,
										CNZTYPE AS NAMETYPE
								FROM (SELECT CND.NAMETYPE AS CNDNT, CND.NAMENO AS CNDNN, CND.CASEID AS CNDCID, 
									CND.BILLPERCENTAGE AS CNDBP, CND.EXPIRYDATE AS CNDED, 
									CNZ.NAMETYPE AS CNZNT, CNZ.NAMENO AS CNZNN, CNZ.CASEID AS CNZCID, 
									CNZ.BILLPERCENTAGE AS CNZBP, CNZ.EXPIRYDATE AS CNZED, CNZ.REFERENCENO as CNZREF,
									NT.NAMETYPE as CNZTYPE
									FROM CASENAME CND 
									join NAMETYPE NT on (NT.NAMETYPE = CND.NAMETYPE)
									LEFT JOIN CASENAME CNZ on (CNZ.CASEID = CND.CASEID AND CNZ.NAMETYPE = 'Z'
												and (CNZ.EXPIRYDATE is null OR CNZ.EXPIRYDATE > GetDate())
					)" + char(10) + @sWhere + ") as CNX"
			End
			Else
			Begin
				-- Construct CaseName table for debtor only
				Set @sSQLString = @sSQLString + char(10) + "(Select NAMETYPE, NAMENO, CASEID, BILLPERCENTAGE, EXPIRYDATE, REFERENCENO
								FROM CASENAME CND" + char(10) + @sWhere 
								
			End
			
			Set @sSQLString = @sSQLString + char(10) + ") as CN
				OUTER APPLY dbo.fn_GetBestMatchAssociatedNameNo(CN.NAMENO,CN.CASEID,'BIL', @psAction, @bDebtorHasSameNameType, @pbUseRenewalDebtor)  AN
				Join NAME N on (N.NAMENO = CN.NAMENO)
				Left Join NAME ASSOCN on (ASSOCN.NAMENO = AN.RELATEDNAME)
				left join IPNAME I on (I.NAMENO = CN.NAMENO)
				join NAMETYPE NT on (NT.NAMETYPE = CN.NAMETYPE)"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'	@pnCaseListKey	int,
					@pnCaseKey	int,
					@bDebtorHasSameNameType bit,
					@pbUseRenewalDebtor bit,
                                        @psAction       nvarchar(2)',
					@pnCaseListKey=@pnCaseListKey,
					@pnCaseKey=@pnCaseKey,
					@bDebtorHasSameNameType=@bDebtorHasSameNameType,
					@pbUseRenewalDebtor=@pbUseRenewalDebtor,
                                        @psAction = @psAction

End

return @ErrorCode
go

grant execute on dbo.[biw_GetDebtorsFromCaseList]  to public
go
