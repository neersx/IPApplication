-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetCaseDetail] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetCaseDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetCaseDetail].'
	drop procedure dbo.[biw_GetCaseDetail]
end
print '**** Creating procedure dbo.[biw_GetCaseDetail]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetCaseDetail]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnCaseKey		int,		-- Mandatory
				@pnRaisedByStaffKey	int

as
-- PROCEDURE :	biw_GetCaseDetail
-- VERSION :	10
-- DESCRIPTION:	A procedure that returns case details
--
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC	Version Description
-- -----------	-------	------	------- ----------------------------------------------- 
-- 30-Oct-2009	AT	RFC3605	1	Procedure created.
-- 12-Apr-2010	AT	RFC3605	2	Fixed retrieval of language.
-- 04-May-2010	AT	RFC9092	3	Return unposted Time data.
-- 27-May-2010	AT	RFC9092	4	Return tax data.
-- 02-May-2011	AT	RFC7956	5	Return null as ItemTransNo.
-- 04-May-2011	AT	R10562	6	Return Case Profit Centre.
-- 25-Sep-2013	vql	DR1210	7	Return Case multi-debtor flag.
-- 21-May-2014	MF	R34646	8	When determining Case Action exclude Actions like '~%'
-- 02 Nov 2015	vql	R53910	9	Adjust formatted names logic (DR-15543).
-- 10 Oct 2018  MS      DR-43550 10     Return Office Entity 

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@sLookupCulture	nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

declare @nLanguageKey		int
declare @sLanguageDescription	nvarchar(30)
declare @sSourceCountry		nvarchar(3)
declare @sAction		nvarchar(2)
declare @bWIPSplitDebtor	bit
declare	@bMultiDebtorCase	bit

set @bMultiDebtorCase = 0

If (@ErrorCode = 0)
Begin
	Select @bWIPSplitDebtor = COLBOOLEAN from SITECONTROL where CONTROLID = 'WIP Split Multi Debtor'
	Set @ErrorCode = @@ERROR
End


if (@ErrorCode = 0)
Begin
	exec bi_GetBillingLanguage 
		@pnLanguageKey = @nLanguageKey output,
		@pnUserIdentityId = @pnUserIdentityId,
		@pnDebtorKey = null,
		@pnCaseKey = @pnCaseKey,
		@psActionKey = null,
		@pbDeriveAction = 1

	Set @ErrorCode = @@ERROR
End

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

If (@ErrorCode = 0)
Begin
	Select @sSourceCountry = dbo.fn_GetSourceCountry(@pnRaisedByStaffKey, @pnCaseKey)
End

If (@ErrorCode = 0)
Begin
	If (@bWIPSplitDebtor != 1)
	Begin
		Select @bMultiDebtorCase = case when count(*) > 1 then 1 else 0 end
		from CASENAME where CASEID = @pnCaseKey and NAMETYPE = 'D'
	End
	Else
	Begin
		Select top 1 @bMultiDebtorCase = 1
		from CASENAME
		where CASEID = @pnCaseKey and NAMETYPE in ('D', 'Z')
		group by NAMETYPE
		having count(*) > 1
	End
End

If @ErrorCode = 0
Begin
	---------------------------------------
	-- Get the last Action used by the Case
	-- excluding certain system Actions.
	---------------------------------------
	Set @sSQLString = "Select @sAction = A.ACTION
			   from(Select TOP 1 ACTION
				From OPENACTION
				where CASEID=@pnCaseKey
				and ACTION not like '~%'
				and ACTION not in ('RS','AS')
				order by POLICEEVENTS DESC, DATEUPDATED DESC) A"
	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sAction	nvarchar(2)	OUTPUT,
				  @pnCaseKey	int',
				  @sAction	= @sAction	OUTPUT,
				  @pnCaseKey	= @pnCaseKey
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
			@sAction as 'OpenAction',
			C.PROFITCENTRECODE as ProfitCentreCode,
			0 as 'IsMainCase',
			@nLanguageKey as 'LanguageKey',
			@sLanguageDescription as 'LanguageDescription',
			@sSourceCountry as 'BillSourceCountryCode',
			C.TAXCODE as 'TaxCode',
			" + dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura) + " as 'TaxDescription',
			ISNULL(TRC.RATE, TRCDEFAULT.RATE) as 'TaxRate',
			null AS 'ItemTransNo',
			@bMultiDebtorCase as 'IsMultiDebtorCase',
                        SN.NAMENO as 'OfficeEntity'
			From CASES C
			Join CASETYPE CT on (CT.CASETYPE = C.CASETYPE)
			left join (SELECT SUM(LOCALVALUE) * -1 AS TOTALCREDITS, CASEID FROM OPENITEMCASE GROUP BY CASEID) AS OIC on (OIC.CASEID = C.CASEID)
			Left Join TAXRATES TR on (TR.TAXCODE = C.TAXCODE)
			Left Join TAXRATESCOUNTRY TRC on (TRC.TAXCODE = C.TAXCODE
					and TRC.COUNTRYCODE = C.COUNTRYCODE)
			Left Join TAXRATESCOUNTRY TRCDEFAULT on (TRC.TAXCODE = C.TAXCODE
					and TRC.COUNTRYCODE = 'ZZZ')
                        left join OFFICE O on (O.OFFICEID = C.OFFICEID)
                        left join SPECIALNAME SN on (SN.NAMENO = O.ORGNAMENO and SN.ENTITYFLAG = 1)
			Where C.CASEID = @pnCaseKey"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey		int,
				 @nLanguageKey		int,
				 @sLanguageDescription	nvarchar(30),
				 @sSourceCountry	nvarchar(3),
				 @bMultiDebtorCase	bit,
				 @sAction		nvarchar(2)',
				 @pnCaseKey=@pnCaseKey,
				 @nLanguageKey		= @nLanguageKey,
				 @sLanguageDescription	= @sLanguageDescription,
				 @sSourceCountry	= @sSourceCountry,
				 @bMultiDebtorCase	= @bMultiDebtorCase,
				 @sAction		= @sAction
End

If (@ErrorCode = 0)
Begin
	Set @sSQLString = "Select distinct D.CASEID as 'CaseKey',
			N.NAMENO as 'NameKey',
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'Name',
			D.STARTTIME as 'StartTime', 
			D.TOTALTIME as 'TotalTime', 
			D.TIMEVALUE as 'TimeValue'
			From	DIARY D  	
			join 	NAME N on (N.NAMENO = D.EMPLOYEENO) 
			Where	D.WIPENTITYNO is null  	
			And	D.TRANSNO is null   	
			And	D.TIMEVALUE > 0  
			And	D.ISTIMER = 0  
			and CASEID = @pnCaseKey"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey	int',
				@pnCaseKey=@pnCaseKey
End

return @ErrorCode
go

grant execute on dbo.[biw_GetCaseDetail]  to public
go
