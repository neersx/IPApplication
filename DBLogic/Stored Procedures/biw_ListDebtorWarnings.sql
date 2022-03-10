-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_ListDebtorWarnings] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_ListDebtorWarnings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_ListDebtorWarnings].'
	drop procedure dbo.[biw_ListDebtorWarnings]
end
print '**** Creating procedure dbo.[biw_ListDebtorWarnings]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_ListDebtorWarnings]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture			nvarchar(10) 	= null,
				@pbCalledFromCentura		bit		= 0,
				@pnItemEntityNo			int,
				@pnItemTransNo			int		= null,
				@pdtTransDate			datetime,
				@psDebtorTableName		nvarchar(50)	= null
as
-- PROCEDURE :	biw_ListDebtorWarnings
-- VERSION :	8
-- DESCRIPTION:	A procedure that returns warnings for a debtor on a bill.
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC			Version Description
-- -----------	-------		---------------	------- ----------------------------------------------- 
-- 30-Apr-2010	AT	RFC9092		1	Procedure created
-- 14-Jul-2010	AT	RFC7273		2	Return ErrorXML only. Return Billing Cap Warning.
-- 03-Aug-2010	AT	RFC7273		3	Fixed return of existing draft items list.
-- 02-Feb-2012	AT	RFC11864	4	Return warnings for debtors in debtor table.
-- 27-Jun-2013	KR	RFC13590	5	Return table even if there are no warnings so at the front end getting the sequence is right.
-- 05 Jul 2013	vql	R13629		6	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 26 Sep 2013	mz	R13629		7	Add distinct when inserting into #DEBTORS.
-- 14 Nov 2018  AV  75198/DR-45358	8   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on
set concat_null_yields_null off

Declare		@nErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(max)
Declare		@sExistingDraftOpenItemNo	nvarchar(30)
Declare		@nThresholdPercent int
Declare		@sAlertXML nvarchar(2000)

Set @nErrorCode = 0
Set @pdtTransDate = dbo.fn_DateOnly(@pdtTransDate)


Create table #DEBTORS
(
	DEBTORNAMENO	int,
	DRAFTOPENITEMNOS nvarchar(1000) COLLATE database_default NULL,
	BILLINGCAP	decimal(12,2),
	BILLINGCAPSTART	datetime NULL,
	BILLINGCAPEND	datetime NULL,
	BILLEDAMOUNT	decimal (12,2) null
)

Create table #DEBTORWARNINGS
(
	DEBTORNAMENO	int,
	WARNINGXML	nvarchar(1000) COLLATE database_default NULL,
	SEVERITY	int
)

If (@nErrorCode = 0 and @pnItemTransNo is not null and @pnItemEntityNo is not null)
Begin
	Set @sSQLString = "Insert into #DEBTORS (DEBTORNAMENO)
				Select ACCTDEBTORNO FROM OPENITEM
				Where ITEMENTITYNO= @pnItemEntityNo
				and ITEMTRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnItemEntityNo int,
				@pnItemTransNo int',
				@pnItemEntityNo = @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo
End
Else If (@psDebtorTableName is not null and @psDebtorTableName != '')
Begin
	Set @sSQLString = "Insert into #DEBTORS (DEBTORNAMENO)
			Select distinct NAMENO FROM " + @psDebtorTableName

	exec @nErrorCode=sp_executesql @sSQLString
End

-- Check if Draft bill exists for debtors
if (@nErrorCode = 0)
Begin
	Set @sSQLString ="UPDATE #DEBTORS
			SET DRAFTOPENITEMNOS = CSV 
			FROM (
				SELECT DEBTORNAMENO,
					(SELECT SUBSTRING(
						(SELECT ', ' + OPENITEMNO
						FROM OPENITEM 
						WHERE #DEBTORS.DEBTORNAMENO = OPENITEM.ACCTDEBTORNO
						and OPENITEM.ACCTENTITYNO = @pnItemEntityNo
						AND STATUS = 0
						and ITEMTYPE = 510"

	if (@pnItemTransNo is not null)
	Begin
		Set @sSQLString = @sSQLString + CHAR(10) + "and ITEMTRANSNO != @pnItemTransNo"
	End
	
	Set @sSQLString =@sSQLString +CHAR(10) + "FOR XML PATH('')),3,1000)) AS CSV
		FROM #DEBTORS) AS DRAFTITEMSLIST
		WHERE DRAFTITEMSLIST.DEBTORNAMENO = #DEBTORS.DEBTORNAMENO"


		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnItemEntityNo int,
				@pnItemTransNo int',
				@pnItemEntityNo = @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo

		
		If (@nErrorCode = 0 and @@ROWCOUNT > 0)
		Begin
			Set @sSQLString ="Insert into #DEBTORWARNINGS (DEBTORNAMENO, WARNINGXML, SEVERITY)
					SELECT DEBTORNAMENO, dbo.fn_GetAlertXML('BI4', 'Draft bill(s) exist for this debtor: {0}',
								DRAFTOPENITEMNOS, null, null, null, null),
					2
					FROM #DEBTORS
					where DRAFTOPENITEMNOS IS NOT NULL"
					
			exec @nErrorCode=sp_executesql @sSQLString
		End
End

-- Calculate the billing cap
If (@nErrorCode = 0)
Begin
/*
This is how I work out the start dates.
NumberOfPeriodsToStartOfCurrentPeriod = (Periods between start date and trans date) - MODULO(PeriodsBetweenStartDateAndTransDate, BillingCapPeriod)
Start date =  BillingCapStartDate + NumberOfPeriodsToStartOfCurrentPeriod
EndDate = (StartDate + BillingCapPeriods) - 1 day

BILLINGCAPSTARTDATE as BillingCapStartDate, 
@pdtTransDate as ,
((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate))) as MonthsBetweenStartAndTransDate,
((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate))) % BILLINGCAPPERIOD as ExtraPeriods,
((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD) as MonthsToFirstMonth,

*/
	
	Set @sSQLString = "
		UPDATE #DEBTORS SET BILLINGCAP = I.BILLINGCAP,
		BILLINGCAPSTART =
			CASE WHEN I.BILLINGCAPRESETFLAG = 1 THEN
				case when BILLINGCAPPERIODTYPE = 'D' THEN
					DATEADD(dd, ((datediff(dd,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(dd,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)
				when BILLINGCAPPERIODTYPE = 'W' THEN
					DATEADD(ww, ((datediff(ww,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(ww,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)
				when BILLINGCAPPERIODTYPE = 'M' THEN
					DATEADD(mm, ((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)
				when BILLINGCAPPERIODTYPE = 'Y' THEN
					DATEADD(yy, ((datediff(yy,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(yy,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)
				End
			ELSE
				I.BILLINGCAPSTARTDATE
			END,
		BILLINGCAPEND =
			CASE WHEN I.BILLINGCAPRESETFLAG = 1 THEN
				case when BILLINGCAPPERIODTYPE = 'D' THEN
					DATEADD(dd, BILLINGCAPPERIOD, DATEADD(dd, ((datediff(dd,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(dd,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)) - 1
				when BILLINGCAPPERIODTYPE = 'W' THEN
					DATEADD(ww, BILLINGCAPPERIOD, DATEADD(ww, ((datediff(ww,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(ww,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)) - 1
				when BILLINGCAPPERIODTYPE = 'M' THEN
					DATEADD(mm, BILLINGCAPPERIOD, DATEADD(mm, ((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(mm,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)) - 1
				when BILLINGCAPPERIODTYPE = 'Y' THEN
					DATEADD(yy, BILLINGCAPPERIOD, DATEADD(yy, ((datediff(yy,BILLINGCAPSTARTDATE,@pdtTransDate))) - ((datediff(yy,BILLINGCAPSTARTDATE,@pdtTransDate)) % BILLINGCAPPERIOD), BILLINGCAPSTARTDATE)) - 1
				End
			ELSE
				case when BILLINGCAPPERIODTYPE = 'D' THEN
					DATEADD(dd, BILLINGCAPPERIOD, BILLINGCAPSTARTDATE) - 1
				when BILLINGCAPPERIODTYPE = 'W' THEN
					DATEADD(ww, BILLINGCAPPERIOD, BILLINGCAPSTARTDATE) - 1
				when BILLINGCAPPERIODTYPE = 'M' THEN
					DATEADD(mm, BILLINGCAPPERIOD, BILLINGCAPSTARTDATE) - 1
				when BILLINGCAPPERIODTYPE = 'Y' THEN
					DATEADD(yy, BILLINGCAPPERIOD, BILLINGCAPSTARTDATE) - 1
				End
			END
		FROM IPNAME I 
		WHERE I.NAMENO = #DEBTORS.DEBTORNAMENO"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pdtTransDate datetime',
		@pdtTransDate = @pdtTransDate

End

If @nErrorCode = 0 and exists (select * from #DEBTORS WHERE BILLINGCAP IS NOT NULL AND BILLINGCAP > 0)
Begin
	Set @sSQLString = "
		Select @nThresholdPercent = ISNULL(COLINTEGER,0)
		from SITECONTROL
		where CONTROLID = 'Billing Cap Threshold Percent'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nThresholdPercent	int			OUTPUT',
				  @nThresholdPercent	= @nThresholdPercent 	OUTPUT

	If (@nErrorCode = 0)
	Begin
		Set @sSQLString = "
			Update D
			set BILLEDAMOUNT = AGG.DebtorTotal
			from
			(
				SELECT D.DEBTORNAMENO, sum(CASE WHEN OIC.CASEID IS NULL THEN OI.LOCALVALUE ELSE OIC.LOCALVALUE END) AS 'DebtorTotal'
				FROM #DEBTORS D 
				JOIN OPENITEM OI on (OI.ACCTDEBTORNO = D.DEBTORNAMENO
							and OI.ACCTENTITYNO = @pnItemEntityNo)
				LEFT JOIN OPENITEMCASE OIC ON
					( OI.ITEMENTITYNO = OIC.ITEMENTITYNO 
					AND OI.ITEMTRANSNO = OIC.ITEMTRANSNO 
					AND OI.ACCTENTITYNO = OIC.ACCTENTITYNO 
					AND OI.ACCTDEBTORNO = OIC.ACCTDEBTORNO)
				WHERE  OI.STATUS = 1  
				AND  OI.ITEMTYPE = 510 
				AND (OIC.CASEID IS NULL OR (OIC.STATUS IN (0,1,2,9)))
				AND OI.POSTDATE between D.BILLINGCAPSTART and D.BILLINGCAPEND
				GROUP BY D.DEBTORNAMENO
			) AS AGG
			JOIN #DEBTORS D ON (D.DEBTORNAMENO = AGG.DEBTORNAMENO)
		"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnItemEntityNo	int',
				  @pnItemEntityNo	= @pnItemEntityNo
	End
End

If exists(select * from #DEBTORS, SITECONTROL SC
			WHERE SC.CONTROLID = 'Billing Cap Threshold Percent' AND ISNULL(BILLEDAMOUNT,0) >= (BILLINGCAP * (1 - (cast(ISNULL(SC.COLINTEGER,0) as decimal(5,2)) / 100))) 
	)
Begin
	Set @sSQLString ="Insert into #DEBTORWARNINGS (DEBTORNAMENO, WARNINGXML, SEVERITY)
			SELECT DEBTORNAMENO, dbo.fn_GetAlertXML('BI5', 'The Billing Cap for this debtor is approaching or has been exceeded.\n    Billing Cap: {0}\n    Amount Billed: {1}\n    Cap Period End: {2}',
						BILLINGCAP, BILLEDAMOUNT, convert(nvarchar, BILLINGCAPEND, 112), null, null),
			2
			FROM #DEBTORS, SITECONTROL SC
			WHERE SC.CONTROLID = 'Billing Cap Threshold Percent'
			AND ISNULL(BILLEDAMOUNT,0) >= (BILLINGCAP * (1 - (cast(ISNULL(SC.COLINTEGER,0) as decimal(5,2)) / 100)))"
			
	exec @nErrorCode=sp_executesql @sSQLString		
End



If (@nErrorCode = 0)
Begin
	Select DEBTORNAMENO as 'DebtorNameKey',
	WARNINGXML as 'WarningXML',
	SEVERITY as 'Severity'
	from #DEBTORWARNINGS
	where WARNINGXML IS NOT NULL
End

drop table #DEBTORWARNINGS

return @nErrorCode
go

grant execute on dbo.[biw_ListDebtorWarnings]  to public
go
