-----------------------------------------------------------------------------------------------------------------------------
-- Creation of bi_ListWorksheetWip
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[bi_ListWorksheetWip]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.bi_ListWorksheetWip.'
	Drop procedure [dbo].[bi_ListWorksheetWip]
	Print '**** Creating Stored Procedure dbo.bi_ListWorksheetWip...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.bi_ListWorksheetWip
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLFilterCriteria	ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura	bit		= 0
)
AS 
-- PROCEDURE:	bi_ListWorksheetWip
-- VERSION:	11
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	InPro.net
-- DESCRIPTION:	This stored procedure produces the main result set for the Billing Worksheet Report.  
--		A number of other procedures are used to produce the necessary sub-reports (see bi_ListWorksheetXxx).
--		This result set contains a list of Work in Progress items ready for billing that match the supplied
--		filter criteria.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22 Apr 2005  TM	RFC2554	1	Procedure created. 
-- 02 May 2005	TM	RFC2554	2	The join to Diary should be using D.EntityNo, not D.EmployeeNo.
--					Produce extra columns for calls to child procedures.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 31 May 2005	TM	RFC2554	4	Show staff member name formatted for display instead of abbreviated name.
-- 31 May 2005	TM	RFC2554	5	Staff member name formatted for display not for envelop.
-- 01 Jun 2005	TM	RFC2554	6	SupplierKey is returned instead of the SupplierName.
-- 24 Nov 2005	LP	RFC1017	7	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the result set
-- 19 Sep 2013  MS      DR1006  8       Fix daterange check for Billing worksheet
-- 02 Nov 2015	vql	R53910	9	Adjust formatted names logic (DR-15543).
-- 31 Aug 2017  MS	R71887	10	Added new fields for Billing Worksheet Extended version report
-- 31 Oct 2018	DL	DR-45102	11	Replace control character (word hyphen) with normal sql editor hyphen

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int
Declare @sSQLString			nvarchar(4000)

Declare @bIsExternalUser		bit
Declare @dtDateRangeFrom		datetime	-- Return WIP with item dates between these dates. From and/or To value must be provided.
Declare @dtDateRangeTo			datetime
Declare @sPeriodRangeType		nvarchar(2)	-- Type: D-Days, W-Weeks, M-Months, Y-Years 
Declare @nPeriodRangeFrom		smallint	-- Must be zero or above. Always supplied in conjunction with Type.		
Declare @nPeriodRangeTo			smallint
Declare @dtDateRangeHold		datetime

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint

Declare @bIsRenewalDebtor		bit

Declare @sWIPWhere			nvarchar(4000)
Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set     @nErrorCode = 0			

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser = ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	= @bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	= @pnUserIdentityId
End

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML
	
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

-- Extract the FromDate and ToDate from the filter criteria:
If @nErrorCode = 0
Begin
	Set @sSQLString = 	
	"Select @dtDateRangeFrom	= DateRangeFrom,"+CHAR(10)+
	"	@dtDateRangeTo		= DateRangeTo,"+CHAR(10)+
	"	@sPeriodRangeType	= CASE WHEN PeriodRangeType = 'D' THEN 'dd'"+CHAR(10)+
	"				       WHEN PeriodRangeType = 'W' THEN 'wk'"+CHAR(10)+
	"				       WHEN PeriodRangeType = 'M' THEN 'mm'"+CHAR(10)+
	"				       WHEN PeriodRangeType = 'Y' THEN 'yy'"+CHAR(10)+
	"				  END,"+CHAR(10)+
	"	@nPeriodRangeFrom	= PeriodRangeFrom,"+CHAR(10)+
	"	@nPeriodRangeTo		= PeriodRangeTo,"+CHAR(10)+
	"	@bIsRenewalDebtor	= IsRenewalDebtor"+CHAR(10)+	
	"from	OPENXML (@idoc, '//wp_ListWorkInProgress/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      DateRangeFrom		datetime	'ItemDate/DateRange/From/text()',"+CHAR(10)+
	"	      DateRangeTo		datetime	'ItemDate/DateRange/To/text()',"+CHAR(10)+
	"	      PeriodRangeFrom		smallint	'ItemDate/PeriodRange/From/text()',"+CHAR(10)+
	"	      PeriodRangeTo		smallint	'ItemDate/PeriodRange/To/text()',"+CHAR(10)+
	"	      PeriodRangeType		nvarchar(2)	'ItemDate/PeriodRange/Type/text()',"+CHAR(10)+	
	"	      IsRenewalDebtor		bit		'Debtor/@IsRenewalDebtor/text()'"+CHAR(10)+
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @dtDateRangeFrom		datetime		output,
				  @dtDateRangeTo 		datetime		output,
				  @sPeriodRangeType		nvarchar(2)		output,
				  @nPeriodRangeFrom		smallint		output,
				  @nPeriodRangeTo		smallint		output,
				  @bIsRenewalDebtor		bit			output',
				  @idoc				= @idoc,
				  @dtDateRangeFrom		= @dtDateRangeFrom	output,
				  @dtDateRangeTo 		= @dtDateRangeTo 	output,
				  @sPeriodRangeType		= @sPeriodRangeType	output,
				  @nPeriodRangeFrom		= @nPeriodRangeFrom 	output,
				  @nPeriodRangeTo		= @nPeriodRangeTo	output,
				  @bIsRenewalDebtor		= @bIsRenewalDebtor	output

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc	
End

-- If Period Range and Period Type are supplied, these are used to calculate WIP From date
-- and To date before proceeding.  The dates are calculated by adding the period and type to the 
-- current date.  	

If  (@sPeriodRangeType is not null
and (@nPeriodRangeFrom is not null
 or  @nPeriodRangeTo   is not null))
and  @nErrorCode=0
Begin		
	If @nPeriodRangeFrom is not null
	Begin
		Set @sSQLString = "Set @dtDateRangeFrom = dateadd("+@sPeriodRangeType+", "+"-"+"@nPeriodRangeFrom, '" + convert(nvarchar(25),getdate()) + "')"

		execute sp_executesql @sSQLString,
				N'@dtDateRangeFrom	datetime 		output,
 				  @sPeriodRangeType	nvarchar(2),
				  @nPeriodRangeFrom	smallint',
  				  @dtDateRangeFrom	= @dtDateRangeFrom 	output,
				  @sPeriodRangeType	= @sPeriodRangeType,
				  @nPeriodRangeFrom	= @nPeriodRangeFrom				  
	End

	If @nPeriodRangeTo is not null
	Begin
		Set @sSQLString = "Set @dtDateRangeTo = dateadd("+@sPeriodRangeType+", "+"-"+"@nPeriodRangeTo, '" + convert(nvarchar(25),getdate()) + "')"

		execute sp_executesql @sSQLString,
				N'@dtDateRangeTo	datetime 		output,
 				  @sPeriodRangeType	nvarchar(2),
				  @nPeriodRangeTo	smallint',
  				  @dtDateRangeTo	= @dtDateRangeTo 	output,
				  @sPeriodRangeType	= @sPeriodRangeType,
				  @nPeriodRangeTo	= @nPeriodRangeTo				
	End				  	

	-- For the PeriodRange filtering swap around @dtDateRangeFrom and @dtDateRangeTo:
	Set @dtDateRangeHold 	= @dtDateRangeFrom
	Set @dtDateRangeFrom 	= @dtDateRangeTo
	Set @dtDateRangeTo 	= @dtDateRangeHold
	
End	

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE  clause  ****/
/****                                       ****/
/***********************************************/

If   @nErrorCode=0
and (datalength(@ptXMLFilterCriteria) <> 0
or   datalength(@ptXMLFilterCriteria) is not null)
Begin
	exec @nErrorCode=dbo.wp_FilterWip
				@psReturnClause		= @sWIPWhere	  	OUTPUT, 
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,		
				@pbIsExternalUser	= @bIsExternalUser,	
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,	
				@pbCalledFromCentura	= @pbCalledFromCentura	
End

If   @nErrorCode = 0
Begin
	Set @sSQLString = "
	;WITH CTE as (
	Select 	W.ENTITYNO	as EntityKey,   
		N.NAME as EntityName,
		W.CASEID	as CaseKey,
		C.IRN	as CaseRef,
		CN.NAMENO as DebtorKey,
		W.ACCTCLIENTNO	as WipNameKey,
		dbo.fn_FormatNameUsingNameNo(NW.NAMENO, null) as WipName,
		NW.NAMECODE as WipNameCode,
		W.TRANSDATE	as ItemDate,
		WTM.WIPTYPEID	as WipTypeKey,
		"+dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura)
				+ " as WipType,
		ISNULL(W.LONGNARRATIVE, W.SHORTNARRATIVE)
				as Narrative,
		W.EMPLOYEENO	as StaffKey,
		dbo.fn_FormatNameUsingNameNo(N2.NAMENO, null)
				as StaffName,
		dbo.fn_FormatNameUsingNameNo(N3.NAMENO, null)
				as SupplierName,
		isnull(DATEPART(HOUR,W.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, W.TOTALTIME),0)
				as TotalMinutes,
		W.FOREIGNCURRENCY as ForeignCurrencyCode,
		@sLocalCurrencyCode as LocalCurrencyCode, 
		@nLocalDecimalPlaces as LocalDecimalPlaces,
		W.CHARGEOUTRATE as ChargeOutRate,
		W.BALANCE	as LocalBalance,
		W.FOREIGNBALANCE as ForeignBalance,
		CASE WHEN W.STATUS = 2 THEN CAST(1 as bit) END	
				as IsLocked,
		D.NOTES		as DiaryNotes,
		@bIsRenewalDebtor as IsRenewalDebtor,	
		@dtDateRangeFrom as FromDate,
		@dtDateRangeTo	as ToDate,
		CASE WHEN W.FOREIGNCOST is not null THEN W.FOREIGNCOST + CHAR(10) + W.FOREIGNCURRENCY
			ELSE W.LOCALCOST
			END as OriginalCost,
		W.LOCALCOST as LocalCost,
		W.FOREIGNCOST as ForeignCost,
		W.INVOICENUMBER as InvoiceNumber,
		CASE WHEN SC2.COLBOOLEAN = 1
			THEN SC.COLCHARACTER 	
			ELSE COALESCE(IPC.CURRENCY, IP.CURRENCY, SC.COLCHARACTER)
		END as BillCurrencyCode,
		WC.CATEGORYSORT as CategorySort, 
		WT.WIPTYPESORT as WipTypeSort
	from WORKINPROGRESS W 
	join WIPTEMPLATE WTM 		on (WTM.WIPCODE = W.WIPCODE)	
	join WIPTYPE WT 		on (WT.WIPTYPEID = WTM.WIPTYPEID)	
	join WIPCATEGORY WC 		on (WC.CATEGORYCODE = WT.CATEGORYCODE)
	join NAME N 	 		on (N.NAMENO = W.ENTITYNO)
	left join NAME N2		on (N2.NAMENO = W.EMPLOYEENO)	
	left join NAME N3		on (N3.NAMENO = W.ASSOCIATENO)
	left join DIARY D		on (D.WIPENTITYNO = W.ENTITYNO
					and D.TRANSNO = W.TRANSNO)
	left join CASES C		on (C.CASEID = W.CASEID)
	left join NAME NW		on (NW.NAMENO = W.ACCTCLIENTNO)
	left join IPNAME IP		on (IP.NAMENO = NW.NAMENO)
	left join CASENAME CN	on (CN.CASEID = C.CASEID and CN.NAMETYPE = CASE WHEN @bIsRenewalDebtor = 1 THEN 'Z' ELSE 'D' END)
	left join IPNAME IPC	on (IPC.NAMENO = CN.NAMENO)
	left join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY')
	left join SITECONTROL SC2 	on (SC2.CONTROLID= 'Bill Foreign Equiv')
	where exists (Select 1"+char(10)+
	@sWIPWhere+char(10)+
	"and XW.ENTITYNO=W.ENTITYNO"+char(10)+
	"and XW.TRANSNO=W.TRANSNO"+char(10)+	
	"and XW.WIPSEQNO=W.WIPSEQNO))"+char(10)+"
	SELECT EntityKey, CaseKey, WipNameKey, ItemDate, WipTypeKey, WipType, Narrative, StaffKey, StaffName, SupplierName, TotalMinutes, ForeignCurrencyCode, LocalCurrencyCode,
	LocalDecimalPlaces, ChargeOutRate, LocalBalance, ForeignBalance, IsLocked, DiaryNotes, IsRenewalDebtor, FromDate, ToDate, LocalCost, ForeignCost, InvoiceNumber, BillCurrencyCode,
	CASE WHEN ForeignCurrencyCode = BillCurrencyCode THEN ForeignBalance 
		WHEN LocalCurrencyCode = BillCurrencyCode THEN LocalBalance 
		ELSE (Select dbo.fn_GetBilledValue(@pnUserIdentityId, BillCurrencyCode, CaseKey, ISNULL(WipNameKey, DebtorKey), CASE When SupplierName is not null THEN 1 ELSE 0 END, LocalBalance))
	END as Value
	From CTE    
	order by EntityName, CaseRef, WipName, WipNameCode, CategorySort, WipTypeSort, StaffName, ItemDate"
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId 	int,
					  @bIsRenewalDebtor	bit,
					  @dtDateRangeFrom	datetime,
					  @dtDateRangeTo	datetime,
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint',					 
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @bIsRenewalDebtor	= @bIsRenewalDebtor,
					  @dtDateRangeFrom	= @dtDateRangeFrom,
					  @dtDateRangeTo	= @dtDateRangeTo,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces
	Set @pnRowCount=@@Rowcount	
End


Return @nErrorCode
GO

Grant execute on dbo.bi_ListWorksheetWip to public
GO
