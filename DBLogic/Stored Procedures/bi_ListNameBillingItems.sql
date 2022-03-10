-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.bi_ListNameBillingItems
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[bi_ListNameBillingItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.bi_ListNameBillingItems.'
	Drop procedure [dbo].[bi_ListNameBillingItems]
End
Print '**** Creating Stored Procedure dbo.bi_ListNameBillingItems...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.bi_ListNameBillingItems
(
	@pnRowCount		int	= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbIsExternalUser 	bit		= null,
	@pnNameKey  		int		= null,
	@pnGroupKey		smallint	= null,
	@pbYearToDate		bit		= null
)
AS
-- PROCEDURE:	bi_ListNameBillingItems    
-- VERSION:	8
-- DESCRIPTION:	Populates NameBillingItemsData dataset. Lists information regarding
--		the billing of the name. Results should only be returned if the user
--		has access to the requested Billing History information security topic
--		and name.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18 Jan 2005  TM		1	Procedure created
-- 20 Jan 2005	TM	RFC1533	2	Rename the @sWorkAnalysisDateRangeYTD variable to be @sDateRangeYTD.
-- 24 Nov 2005	LP	RFC1017	3	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Header result set
-- 13 Jul 2006	SW	RFC3828	4	Pass getdate() to fn_Permission..
-- 04 Oct 2006	AU	RFC4397	5	Return new RowKey and GroupKey columns in BillingItem result-set.
-- 15 Apr 2013	DV	R13270	6	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	7	Adjust formatted names logic (DR-15543).
-- 25 Oct 2016	MF	69655	8	The billing YTD should exclude bills that have been reversed or are draft only.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int

Declare @sSQLString 			nvarchar(4000)
Declare @bBillingHistoryAvailable	bit

Declare @nBilledTotal			decimal(11,2)
Declare @sDateRangeYTD			nvarchar(100)
Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @dtToday			datetime

Set 	@nErrorCode 			= 0
Set	@pnRowCount			= 0
Set	@dtToday			= getdate()

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= 0
End

-- We need to determine if the user is external

-- Check whether the Billing History  topic security (101) is available
-- and extract the LocalCurrencyCode.
If @nErrorCode = 0
Begin

	Set @sSQLString = "
	Select  @bBillingHistoryAvailable 	= IsAvailable
	from dbo.fn_GetTopicSecurity(@pnUserIdentityId, 101, default, @dtToday)"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bBillingHistoryAvailable	bit				OUTPUT,
					  @pnUserIdentityId		int,
					  @dtToday			datetime',
					  @bBillingHistoryAvailable	= @bBillingHistoryAvailable	OUTPUT,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @dtToday			= @dtToday

End

If @nErrorCode=0
and @pbIsExternalUser is null
and @bBillingHistoryAvailable = 1
Begin
	Set @sSQLString="
	Select	@pbIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pbIsExternalUser		bit	OUTPUT,
				  @pnUserIdentityId		int',
				  @pbIsExternalUser=@pbIsExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId

	If @pbIsExternalUser is null
	Begin
		Set @pbIsExternalUser=1
	End
End

If @nErrorCode = 0
and @pbYearToDate = 1
and @bBillingHistoryAvailable = 1
Begin					 
	-- Find the Year to dateperiod of the financial year
	Set @sSQLString = 
	"Select @sDateRangeYTD  = '   OI.POSTPERIOD between '''" + " + substring(convert(varchar,P.PERIODID),1,4) + '01'''+" +
				 "'   and '''" + " + substring(convert(varchar,P.PERIODID),1,4) + '99'''" + char(10)+ 
	"from PERIOD P" + char(10)+ 
	"where P.PERIODID =(	select (P1.PERIODID/100)*100+01" + char(10)+
				"from PERIOD P1"+char(10)+
				"where P1.STARTDATE=(	select max(STARTDATE)" + char(10)+ 
							"from PERIOD where STARTDATE<getdate()))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@sDateRangeYTD	nvarchar(100)		OUTPUT',					 
					  @sDateRangeYTD	= @sDateRangeYTD	OUTPUT
End

-- Total billed for the case to debtors. 
If @nErrorCode = 0
and @bBillingHistoryAvailable = 1
Begin 
	Set @sSQLString = "
	Select  @nBilledTotal   	= ISNULL(SUM(ISNULL(OI.LOCALVALUE,0)),0)
	from OPENITEM OI"+char(10)+
	-- External users can only see information for names they have access to:
	CASE	WHEN @pbIsExternalUser = 1
		THEN "join dbo.fn_FilterUserNames(@pnUserIdentityId,@pbIsExternalUser) FUN"+char(10)+
		     "			on (FUN.NAMENO = OI.ACCTDEBTORNO)"
	END+char(10)+	
	"join DEBTOR_ITEM_TYPE DIT 	on (DIT.ITEM_TYPE_ID = OI.ITEMTYPE)"+char(10)+
	CASE 	WHEN @pnGroupKey is not null
		THEN "join NAME N	on (N.NAMENO = OI.ACCTDEBTORNO"+char(10)+
		     "			and N.FAMILYNO = @pnGroupKey)"
	END+char(10)+
	"where DIT.USEDBYBILLING = 1"+char(10)+
	"and OI.STATUS not in (0,9)"+char(10)+ -- Exclude draft and reversed bills
	CASE	WHEN @pbYearToDate = 1
		THEN "and "+@sDateRangeYTD
	END+char(10)+
        CASE	WHEN @pnNameKey is not null
		THEN "and OI.ACCTDEBTORNO = @pnNameKey" 
	END

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nBilledTotal 	decimal(11, 2)    	OUTPUT,
					  @pnNameKey	 	int,
					  @pnGroupKey		smallint,
					  @pnUserIdentityId	int,
					  @pbIsExternalUser	bit',
					  @nBilledTotal 	= @nBilledTotal   	OUTPUT,
					  @pnNameKey 		= @pnNameKey,
					  @pnGroupKey		= @pnGroupKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pbIsExternalUser	= @pbIsExternalUser
End

-- Populating Header Result Set
If @nErrorCode = 0
Begin
	Select	@nBilledTotal 		as 'BilledTotal',
		@sLocalCurrencyCode	as 'LocalCurrencyCode',
		@nLocalDecimalPlaces	as 'LocalDecimalPlaces' 				
End

-- Populating BillingItem Result Set
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	CAST(OI.ITEMENTITYNO as nvarchar(11))+'^'+
		CAST(OI.ITEMTRANSNO as nvarchar(11))+'^'+
		CAST(OI.ACCTENTITYNO as nvarchar(11))+'^'+
		CAST(OI.ACCTDEBTORNO as nvarchar(11))
					as 'RowKey',
		OI.ITEMENTITYNO		as 'ItemEntityNo', 
		OI.ITEMTRANSNO		as 'ItemTransNo',
		OI.ACCTENTITYNO		as 'AcctEntityNo',
		OI.ACCTDEBTORNO		as 'AcctDebtorNo',
		OI.OPENITEMNO		as 'OpenItemNo',
		OI.ITEMDATE 		as 'ItemDate',
		ISNULL(OI.CURRENCY, @sLocalCurrencyCode)
					as 'ItemCurrencyCode',
		OI.LOCALVALUE		as 'LocalValue',
		OI.FOREIGNVALUE		as 'ForeignValue',		
		OI.ACCTDEBTORNO		as 'NameKey',
		dbo.fn_FormatNameUsingNameNo(DEBTOR.NAMENO, null)
					as 'Name',
		DEBTOR.NAMECODE		as 'NameCode',
		DEBTOR.FAMILYNO		as 'GroupKey',
		OI.ACCTENTITYNO		as 'EntityKey',
		dbo.fn_FormatNameUsingNameNo(ENTITY.NAMENO, null)
					as 'EntityName',
		ENTITY.NAMECODE		as 'EntityNameCode',
		OI.FOREIGNBALANCE	as 'ForeignBalance',
		OI.LOCALBALANCE		as 'LocalBalance'
	from OPENITEM OI"+char(10)+
	-- External users can only see information for names they have access to:
	CASE	WHEN @pbIsExternalUser = 1
		THEN "join dbo.fn_FilterUserNames(@pnUserIdentityId,@pbIsExternalUser) FUN"+char(10)+
		     "			on (FUN.NAMENO = OI.ACCTDEBTORNO)"
	END+char(10)+	
	"join DEBTOR_ITEM_TYPE DIT 	on (DIT.ITEM_TYPE_ID = OI.ITEMTYPE)"+char(10)+
	CASE 	WHEN @pnGroupKey is not null
		THEN "join NAME N	on (N.NAMENO = OI.ACCTDEBTORNO"+char(10)+
		     "			and N.FAMILYNO = @pnGroupKey)"
	END+char(10)+
	"join  NAME DEBTOR 		on (DEBTOR.NAMENO = OI.ACCTDEBTORNO) 
	join  NAME ENTITY 		on (ENTITY.NAMENO = OI.ACCTENTITYNO) 	
	where DIT.USEDBYBILLING = 1"+char(10)+
	"and OI.STATUS not in (0,9)"+char(10)+ -- Exclude draft and reversed bills
	CASE	WHEN @pbYearToDate = 1
		THEN "and "+@sDateRangeYTD
	END+char(10)+
        CASE	WHEN @pnNameKey is not null
		THEN "and OI.ACCTDEBTORNO = @pnNameKey" 
	END+char(10)+
	"order by 'ItemDate' DESC, 'OpenItemNo'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @pbIsExternalUser	bit,
					  @pnNameKey		int,
					  @pnGroupKey		smallint,
					  @sLocalCurrencyCode	nvarchar(3)',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pbIsExternalUser	= @pbIsExternalUser,
					  @pnNameKey       	= @pnNameKey,
					  @pnGroupKey		= @pnGroupKey,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode	

	Set @pnRowCount = @@Rowcount
End 

Return @nErrorCode
GO

Grant execute on dbo.bi_ListNameBillingItems to public
GO
