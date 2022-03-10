--biw_GetCaseDetailsFromCaseList
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetCaseDetailsFromCaseList] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetCaseDetailsFromCaseList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetCaseDetailsFromCaseList].'
	drop procedure dbo.[biw_GetCaseDetailsFromCaseList]
end
print '**** Creating procedure dbo.[biw_GetCaseDetailsFromCaseList]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetCaseDetailsFromCaseList]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnCaseListKey		int,					-- Mandatory
				@pnRaisedByStaffKey		int
			

as
-- PROCEDURE :	biw_GetCaseDetailsFromCaseList
-- VERSION :	6
-- DESCRIPTION:	A procedure that returns all the case details from a case list
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC	Version Description
-- -----------	-------	------	------- ----------------------------------------------- 
-- 07-Jan-2010	AT	RFC3605	1	Procedure created.
-- 27-May-2010	AT	RFC9092	2	Return tax data.
-- 05-Jul-2010	AT	RFC9092	3	Fix case sensitivity issue.
-- 02-May-2011	AT	RFC7956	4	Return null as ItemTransNo.
-- 25-Sep-2013	vql	DR1210	5	Return Case multi-debtor flag.
-- 10 Oct 2018  MS      DR43550 6       Return Office Entity 

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@nPrimeCaseKey int
declare		@nLanguageKey int
declare		@sLanguageDescription nvarchar(30)
Declare		@sLookupCulture	nvarchar(10)
Declare		@bWIPSplitDebtor bit


Create table #MultiDebtorCase
(
	CASEID int,
	ISMULTIDEBTORCASE bit
)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

If (@ErrorCode = 0)
Begin
	Select @bWIPSplitDebtor = COLBOOLEAN from SITECONTROL where CONTROLID = 'WIP Split Multi Debtor'
	Set @ErrorCode = @@ERROR
End

If (@ErrorCode = 0)
Begin
	Set @sSQLString = "SELECT @nPrimeCaseKey = CASEID
						FROM CASELISTMEMBER CLM
						Where CASELISTNO = @pnCaseListKey
						and PRIMECASE = 1"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nPrimeCaseKey	int OUTPUT,
					@pnCaseListKey int',
					@nPrimeCaseKey = @nPrimeCaseKey output,
					@pnCaseListKey = @pnCaseListKey
End

If (@ErrorCode = 0 and @nPrimeCaseKey is not null)
Begin

	exec @ErrorCode = bi_GetBillingLanguage
				@pnLanguageKey = @nLanguageKey output,
				@pnUserIdentityId = @pnUserIdentityId,
				@pnDebtorKey = null,
				@pnCaseKey = @nPrimeCaseKey,
				@psActionKey = null,
				@pbDeriveAction = 1

	if (@ErrorCode = 0 and @nLanguageKey is not null)
	Begin
		Set @sSQLString = "Select @sLanguageDescription = " + dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,NULL,@sLookupCulture,@pbCalledFromCentura) + "
					From TABLECODES 
					Where TABLECODE = @nLanguageKey"


		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sLanguageDescription	nvarchar(30) output,
						@nLanguageKey int',
						@sLanguageDescription = @sLanguageDescription output,
						@nLanguageKey = @nLanguageKey
	End
End

If (@ErrorCode = 0)
Begin
	If (@bWIPSplitDebtor != 1)
	Begin
		Insert into #MultiDebtorCase(CASEID,ISMULTIDEBTORCASE)
		Select distinct CN.CASEID, case when count(*) > 1 then 1 else 0 end
		from CASENAME CN
		join CASELISTMEMBER CL on (CN.CASEID = CL.CASEID)
		where CL.CASELISTNO = @pnCaseListKey
		and NAMETYPE = 'D'
		group by CN.CASEID,CN.NAMETYPE
	End
	Else
	Begin
		Insert into #MultiDebtorCase(CASEID,ISMULTIDEBTORCASE)
		Select distinct CN.CASEID, 1
		from CASENAME CN
		join CASELISTMEMBER CL on (CN.CASEID = CL.CASEID)
		where CL.CASELISTNO = @pnCaseListKey
		and NAMETYPE in ('D','Z')
		group by CN.CASEID, CN.NAMETYPE
		having COUNT(*) > 1			
	End
End

If @ErrorCode = 0
Begin
	Set @sSQLString = "Select
			C.CASEID as 'CaseKey',
			C.IRN as 'IRN',
			" + dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura) + " as 'Title',
			C.CASETYPE as 'CaseTypeCode',
			" + dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura) + " as 'CaseTypeDescription',
			C.COUNTRYCODE as 'CountryCode',
			C.PROPERTYTYPE as 'PropertyType',
			OIC.TOTALCREDITS as 'TotalCredits',
			CASE WHEN CLM.PRIMECASE = 1 then OA.ACTION ELSE NULL END as 'OpenAction',
			C.PROFITCENTRECODE as ProfitCentreCode,
			CLM.PRIMECASE as 'IsMainCase',
			Case when CLM.PRIMECASE = 1 then @nLanguageKey else null END as 'LanguageKey',
			Case when CLM.PRIMECASE = 1 then @sLanguageDescription else null END as 'LanguageDescription',
			dbo.fn_GetSourceCountry(@pnRaisedByStaffKey, C.CASEID) as 'BillSourceCountryCode',
			C.TAXCODE as 'TaxCode',
			" + dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura) + " as 'TaxDescription',
			ISNULL(TRC.RATE, TRCDEFAULT.RATE) as 'TaxRate',
			null as 'ItemTransNo',
			case when MD.ISMULTIDEBTORCASE = 1 then 1 else 0 end as 'IsMultiDebtorCase',
                        SN.NAMENO as 'OfficeEntity'
			From CASELISTMEMBER CLM
			Join CASES C on (C.CASEID = CLM.CASEID)
			left join #MultiDebtorCase MD on (MD.CASEID = C.CASEID)
			Join CASETYPE CT on (CT.CASETYPE = C.CASETYPE)
			Left Join (Select TOP 1 OA.ACTION, OA.CASEID 
						From OPENACTION OA join CASELISTMEMBER CLM ON (CLM.CASEID = OA.CASEID)
						Where CLM.CASELISTNO = @pnCaseListKey
						and CLM.PRIMECASE = 1
						ORDER BY POLICEEVENTS DESC, DATEUPDATED DESC) as OA on (OA.CASEID = C.CASEID)
			Left Join (SELECT SUM(LOCALVALUE) * -1 AS TOTALCREDITS, CASEID FROM OPENITEMCASE GROUP BY CASEID) AS OIC on (OIC.CASEID = C.CASEID)
			Left Join TAXRATES TR on (TR.TAXCODE = C.TAXCODE)
			Left Join TAXRATESCOUNTRY TRC on (TRC.TAXCODE = C.TAXCODE
					and TRC.COUNTRYCODE = C.COUNTRYCODE)
			Left Join TAXRATESCOUNTRY TRCDEFAULT on (TRC.TAXCODE = C.TAXCODE
					and TRC.COUNTRYCODE = 'ZZZ')
                        left join OFFICE O on (O.OFFICEID = C.OFFICEID)
                        left join SPECIALNAME SN on (SN.NAMENO = O.ORGNAMENO and SN.ENTITYFLAG = 1)
			Where CLM.CASELISTNO = @pnCaseListKey
			order by CLM.PRIMECASE DESC, IRN"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'	@pnCaseListKey int,
					@nLanguageKey int,
					@sLanguageDescription nvarchar(30),
					@pnRaisedByStaffKey int',
					@pnCaseListKey=@pnCaseListKey,
					@nLanguageKey = @nLanguageKey,
					@sLanguageDescription = @sLanguageDescription,
					@pnRaisedByStaffKey = @pnRaisedByStaffKey
End

return @ErrorCode
go

grant execute on dbo.[biw_GetCaseDetailsFromCaseList]  to public
go
