-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetBillCases] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetBillCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetBillCases].'
	drop procedure dbo.[biw_GetBillCases]
end
print '**** Creating procedure dbo.[biw_GetBillCases]...'
print ''
go

-- quoted identifier required for XML object
set QUOTED_IDENTIFIER on
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetBillCases]
		@pnUserIdentityId	int,		-- Mandatory
		@psCulture		nvarchar(10) 	= null,
		@pbCalledFromCentura	bit		= 0,
		@pnItemEntityNo		int = null,
		@pnItemTransNo		int = null,
		@psMergeXMLKeys		nvarchar(max)	= null
				
as
-- PROCEDURE :	biw_GetBillCases
-- VERSION :	11
-- DESCRIPTION:	A procedure that returns all of the cases associated to an OpenItem
--
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC	Version Description
-- -----------	-------	------	------- ----------------------------------------------- 
-- 14-Oct-2009	AT	RFC3605	1	Procedure created.
-- 03-May-2010	AT	RFC9092	2	Use translations.
-- 10-May-2010	AT	RFC9092	3	Return unposted diary entries.
-- 20-May-2010	AT	RFC9092	4	Return Language.
-- 27-May-2010	AT	RFC9092	5	Return tax data.
-- 02-mAY-2011	AT	RFC7956	6	Return cases for multiple draft bills.
-- 01-May-2013  MS      R11732  7       Return cases from function fn_GetBillCases
-- 25-Sep-2013	vql	DR1210	8	Return Case multi-debtor flag.
-- 02 Nov 2015	vql	R53910	9	Adjust formatted names logic (DR-15543).
-- 16 Apr 2018	AK	R53897	10	added order by IRN (DR-15708).
-- 15 Oct 2018  MS  DR-43550 11     Return Office Entity 

set nocount on
SET CONCAT_NULL_YIELDS_NULL on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@sWhere		nvarchar(1000)
Declare		@sJoin		nvarchar(1000)
Declare		@sLookupCulture	nvarchar(10)
Declare		@bBillStatus	bit
Declare		@XMLKeys	XML
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
	set @ErrorCode = @@ERROR
End

If (@pnItemEntityNo is not null and @pnItemTransNo is not null)
Begin
		set @sSQLString = 'Select @bBillStatus = STATUS 
		From OPENITEM 
		Where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo'

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@bBillStatus	bit OUTPUT,
				@pnItemTransNo	int,
				  @pnItemEntityNo	int',
				  @bBillStatus=@bBillStatus OUTPUT,
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo
End

If (@pnItemEntityNo is not null and @pnItemTransNo is not null)
Begin
	If (@bWIPSplitDebtor != 1)
	Begin
		Insert into #MultiDebtorCase(CASEID,ISMULTIDEBTORCASE)
		Select distinct CASEID, case when count(*) > 1 then 1 else 0 end
		from CASENAME 
		where CASEID in (select CASEID from dbo.fn_GetBillCases(@pnItemTransNo,@pnItemEntityNo))
		and NAMETYPE = 'D'
		group by CASEID,NAMETYPE
	End
	Else
	Begin
		Insert into #MultiDebtorCase(CASEID,ISMULTIDEBTORCASE)
		Select distinct CN.CASEID, 1
		from CASENAME CN
		join  dbo.fn_GetBillCases(@pnItemTransNo,@pnItemEntityNo) B on (B.CASEID = CN.CASEID)
		where NAMETYPE in ('D','Z')
		group by CN.CASEID, CN.NAMETYPE
		having COUNT(*) > 1		
	End
End

If @ErrorCode = 0
Begin
        Set @sSQLString = 'Select DISTINCT
			C.CASEID as ''CaseKey'',
			C.IRN as ''IRN'',
			' + dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura) + ' as ''Title'',
			C.CASETYPE as ''CaseTypeCode'',
			' + dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura) + ' as ''CaseTypeDescription'',
			C.COUNTRYCODE as ''CountryCode'',
			C.PROPERTYTYPE as ''PropertyType'',
			OIC.TOTALCREDITS as ''TotalCredits'',
			OI.ACTION AS ''OpenAction'',
			C.PROFITCENTRECODE as ProfitCentreCode,
			CASE WHEN OI.MAINCASEID = C.CASEID THEN 1 ELSE 0 END as ''IsMainCase'', --, GET IS MAIN CASE
			OI.LANGUAGE as ''LanguageKey'',
			TC.DESCRIPTION as ''LanguageDescription'',
			dbo.fn_GetSourceCountry(OI.EMPLOYEENO, C.CASEID) as ''BillSourceCountryCode'',
			C.TAXCODE as ''TaxCode'',
			' + dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura) + ' as ''TaxDescription'',
			ISNULL(TRC.RATE, TRCDEFAULT.RATE) as ''TaxRate'',
			OI.ITEMTRANSNO as ''ItemTransNo'',
			case when MD.ISMULTIDEBTORCASE = 1 then 1 else 0 end as ''IsMultiDebtorCase'',
                        SN.NAMENO as ''OfficeEntity''
			From OPENITEM OI
			cross apply dbo.fn_GetBillCases(OI.ITEMTRANSNO, OI.ITEMENTITYNO) BC
			Join CASES C on (C.CASEID = BC.CASEID)
			Join CASETYPE CT on (CT.CASETYPE = C.CASETYPE)
			left join #MultiDebtorCase MD on (MD.CASEID = C.CASEID)
			left join (SELECT SUM(LOCALVALUE) * -1 AS TOTALCREDITS, CASEID FROM OPENITEMCASE GROUP BY CASEID) AS OIC on (OIC.CASEID = C.CASEID)
			left join TABLECODES TC on (TC.TABLECODE = OI.LANGUAGE)
			Left Join TAXRATES TR on (TR.TAXCODE = C.TAXCODE)
			Left Join TAXRATESCOUNTRY TRC on (TRC.TAXCODE = C.TAXCODE
					and TRC.COUNTRYCODE = C.COUNTRYCODE)
			Left Join TAXRATESCOUNTRY TRCDEFAULT on (TRC.TAXCODE = C.TAXCODE
					and TRC.COUNTRYCODE = ''ZZZ'')
                        left join OFFICE O on (O.OFFICEID = C.OFFICEID)
                        left join SPECIALNAME SN on (SN.NAMENO = O.ORGNAMENO and SN.ENTITYFLAG = 1)'  
End

If (@ErrorCode = 0)
Begin
	If (@pnItemTransNo is not null and @pnItemEntityNo is not null)
	Begin
		Set @sWhere = char(10) + 'Where OI.ITEMTRANSNO = @pnItemTransNo
		and OI.ITEMENTITYNO = @pnItemEntityNo'
		
		Set @sSQLString = @sSQLString + @sWhere
	End
	Else
	Begin
		Set @XMLKeys = cast(@psMergeXMLKeys as XML)
		
		Set @sJoin = char(10) + 'JOIN (
		select	K.value(N''ItemEntityNo[1]'',N''int'') as ItemEntityNo,
			K.value(N''ItemTransNo[1]'',N''int'') as ItemTransNo
		from @XMLKeys.nodes(N''/Keys/Key'') KEYS(K)
			) as XM on (XM.ItemEntityNo = OI.ITEMENTITYNO
				and XM.ItemTransNo = OI.ITEMTRANSNO)'
		
		Set @sSQLString = @sSQLString + @sJoin 
	End
	Set @sSQLString = @sSQLString + ' order by C.IRN '
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int,
				  @XMLKeys		xml',
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo,
				  @XMLKeys = @XMLKeys
End

If (@ErrorCode = 0 and (@bBillStatus = 0 or @bBillStatus is null))
Begin
	Set @sSQLString = 'Select distinct 
			D.CASEID as ''CaseKey'',
			N.NAMENO as ''NameKey'',
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as ''Name'',
			D.STARTTIME as ''StartTime'', 
			D.TOTALTIME as ''TotalTime'', 
			D.TIMEVALUE as ''TimeValue''
			From	DIARY D  	
			join 	NAME N on (N.NAMENO = D.EMPLOYEENO) 
			Where	D.WIPENTITYNO is null  	
			And	D.TRANSNO is null   	
			And	D.TIMEVALUE > 0  
			And	D.ISTIMER = 0  
			and D.CASEID in (select WIP.CASEID 
					From BILLEDITEM OI
					Join WORKINPROGRESS WIP on (WIP.ENTITYNO = OI.WIPENTITYNO
								and WIP.TRANSNO = OI.WIPTRANSNO
								and WIP.WIPSEQNO = OI.WIPSEQNO)'
				

	Set @sSQLString = @sSQLString + isnull(@sJoin,'') + isnull(@sWhere,'') + ')'

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int,
				  @XMLKeys		xml',
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo,
				  @XMLKeys = @XMLKeys
End


return @ErrorCode
go

grant execute on dbo.[biw_GetBillCases]  to public
go
