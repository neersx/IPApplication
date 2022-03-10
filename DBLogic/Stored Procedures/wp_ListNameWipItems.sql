-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ListNameWipItems 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_ListNameWipItems ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_ListNameWipItems.'
	Drop procedure [dbo].[wp_ListNameWipItems ]
	Print '**** Creating Stored Procedure dbo.wp_ListNameWipItems...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wp_ListNameWipItems
(
	@pnRowCount		int	= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey  		int		= null,
	@pnGroupKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
AS 
-- PROCEDURE:	wp_ListNameWipItems 
-- VERSION:	10
-- SCOPE:	InPro.net
-- DESCRIPTION:	Populates the NameWorkInProgressData data set for a single name or group.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 19 Jan 2005  TM	RFC1533	1	Procedure created. 
-- 02 Feb 2005	TM	RFC1533	2	Add CaseKey column to the WipItem result set.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 25 Nov 2005	LP	RFC1017	4	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--						ac_GetLocalCurrencyDetails and add to the Header result set
-- 17 Jul 2006	SW	RFC3828	5	Pass getdate() to fn_Permission..
-- 18 Sep 2006	LP	RFC4329	6	Add RowKey column to the WipItem result set.
-- 13 Sep 2011	ASH	R11175  7	Maintain WIP Text in foreign languages.
-- 20 Oct 2011	ASH	R11441	8	Convert TRANSNO column to navarchar(11) data type. 
-- 01 Dec 2011	ASH	R11576	9	Convert small int WIPSEQNO column to navarchar(6) data type.  
-- 02 Nov 2015	vql	R53910	10	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int
Declare @sSQLString			nvarchar(4000)

Declare @bIsExternalUser		bit
Declare @bIsWIPItemsAvailable		bit
Declare @nBalanceDebtorOnlyWIP		decimal(11,2)	
Declare @nBalanceForCaseWIP		decimal(11,2)
Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint

Declare @sLookupCulture		nvarchar(10)
Declare @dtToday		datetime

set @dtToday = getdate()
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

-- Check whether the Work In Progress Items topic security (120) is available
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  @bIsWIPItemsAvailable = IsAvailable
	from dbo.fn_GetTopicSecurity(@pnUserIdentityId, 120, default, @dtToday) FT"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bIsWIPItemsAvailable	bit			OUTPUT,
					  @pnUserIdentityId	int,
					  @dtToday		datetime',
					  @bIsWIPItemsAvailable	= @bIsWIPItemsAvailable	OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @dtToday		= @dtToday
End

-- Calculate any debtor only WIP recorded directly against the name:
If @nErrorCode = 0
and @bIsWIPItemsAvailable = 1
Begin	
	Set @sSQLString = "
	Select  @nBalanceDebtorOnlyWIP = 	ISNULL(SUM(ISNULL(W.BALANCE,0)),0)		
	from WORKINPROGRESS W"+char(10)+
	CASE	WHEN @pnGroupKey is not null
		THEN "join NAME N		on (N.NAMENO = W.ACCTCLIENTNO"+char(10)+
		     "				and N.FAMILYNO = @pnGroupKey)"
	END+char(10)+
	"where W.STATUS <> 0
	and   W.TRANSDATE <= getdate()
	and   W.CASEID is null"+char(10)+
	CASE	WHEN @pnNameKey is not null
		THEN "and   W.ACCTCLIENTNO = @pnNameKey"
	END

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nBalanceDebtorOnlyWIP	decimal(11,2)			OUTPUT,
				  @pnNameKey			int,
				  @pnGroupKey			smallint',
				  @nBalanceDebtorOnlyWIP	= @nBalanceDebtorOnlyWIP	OUTPUT,
				  @pnNameKey			= @pnNameKey,
				  @pnGroupKey			= @pnGroupKey	
End

-- Calculate WIP for Cases for which this name is the debtor:
If @nErrorCode = 0
Begin 	
	Set @sSQLString = "
	Select  @nBalanceForCaseWIP = 	ISNULL(dbo.fn_RoundLocalCurrency(SUM(ISNULL(W.BALANCE,0)*CN.BILLPERCENTAGE/100)),0)						    	 
	from WORKINPROGRESS W
	join CASENAME CN	on (CN.CASEID = W.CASEID
				and CN.NAMETYPE = 'D' 
				and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"+char(10)+
	CASE	WHEN @pnGroupKey is not null
		THEN "join NAME N		on (N.NAMENO = CN.NAMENO"+char(10)+
		     "				and N.FAMILYNO = @pnGroupKey)"
	END+char(10)+
	"where W.STATUS <> 0
	and W.TRANSDATE <= getdate()
	and W.CASEID is not null"+char(10)+
	CASE	WHEN @pnNameKey is not null
		THEN "and CN.NAMENO = @pnNameKey"
	END

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nBalanceForCaseWIP	decimal(11,2)		OUTPUT,
				  @pnNameKey		int,
				  @pnGroupKey		smallint',
				  @nBalanceForCaseWIP	= @nBalanceForCaseWIP	OUTPUT,
				  @pnNameKey		= @pnNameKey,
				  @pnGroupKey		= @pnGroupKey	
End

-- Populate the Header reesult set:
If @nErrorCode = 0
Begin 
	Select  @nBalanceDebtorOnlyWIP+@nBalanceForCaseWIP
					as 'LocalTotal',
		@sLocalCurrencyCode	as 'LocalCurrencyCode',
		@nLocalDecimalPlaces	as 'LocalDecimalPlaces'
	where   @bIsWIPItemsAvailable = 1
End

-- Populating WipItem result set
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	-- WIP recorded directly against the name
	"Select"+char(10)+
	"W.ENTITYNO 		as EntityNo,"+char(10)+   
	"W.TRANSNO 		as TransNo,"+char(10)+
	"W.WIPSEQNO 		as WipSeqNo,"+char(10)+
	"W.TRANSDATE 		as ItemDate,"+char(10)+
	"W.WIPCODE 		as WipCode,"+char(10)+
	--Services, Disbursements, Overheads
	+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)+char(10)+
				+ "as WipCategory,"+char(10)+
	+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WTM',@sLookupCulture,@pbCalledFromCentura)+char(10)+
				+ "as WipDescription,"+char(10)+
	"ISNULL("+ dbo.fn_SqlTranslatedColumn('WORKINPROGRESS',null,'LONGNARRATIVE','W',@sLookupCulture,@pbCalledFromCentura)+", "+ dbo.fn_SqlTranslatedColumn('WORKINPROGRESS','SHORTNARRATIVE',null,'W',@sLookupCulture,@pbCalledFromCentura)+")"+char(10)+ 
	"			as Narrative,"+char(10)+
	-- Use the hours and minutes of the WorkInProgress.TotalTime to calculate TotalMinutes.
	"datediff(mi,convert(datetime, substring(convert(nvarchar,W.TOTALTIME,121),1,11)+'00:00:00.000',121),W.TOTALTIME)"+char(10)+
	"			as TotalMinutes,"+char(10)+
	"ISNULL(W.FOREIGNCURRENCY,@sLocalCurrencyCode)"+char(10)+
	"			as ItemCurrencyCode,"+char(10)+
	"W.CHARGEOUTRATE 	as ChargeOutRate,"+char(10)+
	"STAFF.NAMENO 		as StaffKey,"+char(10)+
	"dbo.fn_FormatNameUsingNameNo(STAFF.NAMENO,NULL)"+char(10)+
	"			as StaffName,"+char(10)+
	"STAFF.NAMECODE		as StaffCode,"+char(10)+
	"TRS.STATUS_ID 		as StatusKey,"+char(10)+
	+dbo.fn_SqlTranslatedColumn('TRANSACTION_STATUS','STATUS_DESCRIPTION',null,'TRS',@sLookupCulture,@pbCalledFromCentura)+char(10)+
				+ "as Status,"+char(10)+
	"DATEDIFF(dd,W.TRANSDATE,GETDATE())"+char(10)+ 	
	"			as Age,"+char(10)+
	"W.LOCALVALUE 		as LocalValue,"+char(10)+
	"W.BALANCE 		as LocalBalance,"+char(10)+
	"W.FOREIGNVALUE		as ForeignValue,"+char(10)+
	"W.FOREIGNBALANCE 	as ForeignBalance,"+char(10)+
	"SUP.NAMENO 		as SupplierKey,"+char(10)+
	"dbo.fn_FormatNameUsingNameNo(SUP.NAMENO,NULL)"+char(10)+
	"			as SupplierName,"+char(10)+
	"SUP.NAMECODE 		as SupplierCode,"+char(10)+
	"W.INVOICENUMBER 	as InvoiceNumber,"+char(10)+
	"TC.USERCODE 		as ProductCode,"+char(10)+
	+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+char(10)+
				+ "as ProductDescription,"+char(10)+
	"W.ACCTENTITYNO		as EntityKey,"+char(10)+		 
	"dbo.fn_FormatNameUsingNameNo(EN.NAMENO,NULL)"+char(10)+
	" 			as EntityName,"+char(10)+
	"EN.NAMECODE 		as EntityNameCode,"+char(10)+
	"CASE WHEN W.CASEID is null THEN W.ACCTCLIENTNO ELSE CN.NAMENO END as NameKey,"+char(10)+
	"CASE WHEN W.CASEID is null THEN dbo.fn_FormatNameUsingNameNo(NCL.NAMENO,NULL)"+char(10)+
	"     ELSE dbo.fn_FormatNameUsingNameNo(NFC.NAMENO,NULL) END"+char(10)+
	"			as Name,"+char(10)+
	"CASE WHEN W.CASEID is null THEN NCL.NAMECODE ELSE NFC.NAMECODE END as NameCode,"+char(10)+
	"C.IRN 			as CaseReference,"+char(10)+
	"W.CASEID		as CaseKey,"+char(10)+
	"CASE WHEN W.CASEID is null THEN 100 ELSE CN.BILLPERCENTAGE END as BillPercentage,"+char(10)+
	"CASE WHEN W.CASEID is null THEN W.BALANCE ELSE"+char(10)+
	"ISNULL(dbo.fn_RoundLocalCurrency(W.BALANCE*CN.BILLPERCENTAGE/100),0) END as BillableBalance,"+char(10)+
	"CONVERT(nvarchar(11), W.ENTITYNO) +'^'+ CONVERT(nvarchar(11),W.TRANSNO) +'^'+ CONVERT(nvarchar(6),W.WIPSEQNO) as RowKey" +char(10)+
	"from WORKINPROGRESS W"+char(10)+
	"join WIPTEMPLATE WTM 		on (WTM.WIPCODE = W.WIPCODE)"+char(10)+	
	"join WIPTYPE WT 		on (WT.WIPTYPEID = WTM.WIPTYPEID)"+char(10)+	
	"join WIPCATEGORY WC 		on (WC.CATEGORYCODE = WT.CATEGORYCODE)"+char(10)+
	"join NAME N 			on (N.NAMENO = W.ENTITYNO)"+char(10)+
	"join TRANSACTION_STATUS TRS 	on (TRS.STATUS_ID = W.STATUS)"+char(10)+
	"left join NAME STAFF 		on (STAFF.NAMENO = W.EMPLOYEENO)"+char(10)+
	"left join NAME SUP 		on (SUP.NAMENO = W.ASSOCIATENO)"+char(10)+
	"left join TABLECODES TC 	on (TC.TABLECODE = W.PRODUCTCODE)"+char(10)+
	"left join NAME EN 		on (EN.NAMENO = W.ACCTENTITYNO)"+char(10)+
	"left join CASENAME CN		on (CN.CASEID = W.CASEID"+char(10)+
	"				and CN.NAMETYPE = 'D'"+char(10)+ 
	"				and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"+char(10)+
	"left join NAME NFC		on (NFC.NAMENO = CN.NAMENO)"+char(10)+
	"left join NAME NCL 		on (NCL.NAMENO = W.ACCTCLIENTNO)"+char(10)+   
	"left join CASES C 		on (C.CASEID = W.CASEID)"+char(10)+ 
	"where W.STATUS<>0"+char(10)+ -- Draft items will not be shown.
	"and W.TRANSDATE<=getdate()"+char(10)+
	-- Empty dataset should be produced if the user does not have access to the Work In Progress Items information 
	-- security topic.  
	"and @bIsWIPItemsAvailable = 1"+char(10)+
	CASE	WHEN @pnNameKey is not null
		THEN "and @pnNameKey = CASE WHEN W.CASEID is null THEN W.ACCTCLIENTNO ELSE CN.NAMENO END"
	END+char(10)+
	CASE	WHEN @pnGroupKey is not null
		THEN "and @pnGroupKey = CASE WHEN W.CASEID is null THEN NCL.FAMILYNO ELSE NFC.FAMILYNO END"
	END+char(10)+
	"order by W.TRANSDATE,WTM.DESCRIPTION"  

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnGroupKey		smallint,
					  @pnUserIdentityId 	int,
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint,
					  @bIsWIPItemsAvailable	bit',					 
					  @pnNameKey      	= @pnNameKey,
					  @pnGroupKey		= @pnGroupKey,
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces,
					  @bIsWIPItemsAvailable	= @bIsWIPItemsAvailable

	Set @pnRowCount=@@Rowcount	

End

Return @nErrorCode
GO

Grant execute on dbo.wp_ListNameWipItems to public
GO
