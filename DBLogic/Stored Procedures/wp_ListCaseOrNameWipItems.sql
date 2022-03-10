-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ListCaseOrNameWipItems
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_ListCaseOrNameWipItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_ListCaseOrNameWipItems.'
	Drop procedure [dbo].[wp_ListCaseOrNameWipItems]
	Print '**** Creating Stored Procedure dbo.wp_ListCaseOrNameWipItems...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wp_ListCaseOrNameWipItems
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLFilterCriteria	ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura	bit		= 0
)
AS 
-- PROCEDURE:	wp_ListCaseOrNameWipItems
-- VERSION:	12
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns the details for a single case or name that are suitable
--		to show an internal user.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22 Apr 2005  TM	RFC1896	1	Procedure created. 
-- 28 Apr 2005	TM	RFC1896	2	Correct the row pattern to be '/wp_ListWorkInProgress/FilterCriteria'  
--					instead of the '/wp_ListWorkInProgress/CurrencyCode'
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 23 May 2005	TM	RFC2594	4	Modify to look up WIP subject only once.
-- 24 Nov 2005  LP	RFC1017	5	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to Header result set
-- 17 Jul 2006	SW	RFC3828	6	Pass getdate() to fn_Permission..
-- 18 Sep 2006	LP	RFC4329	7	Add RowKey column to the WipItem result set.
-- 29 Feb 2008	LP	RFC6236	8	Remove nvarchar lengths in RowKey columns for WipItem result set.
-- 13 Sep 2011	ASH	R11175  9	Maintain WIP Text in foreign languages.
-- 10 Sep 2013	MS	DR787	10	Return debtor in select list if split wip multi debtor site control is on
-- 16 Apr 2014	MF	R33427	11	Increase variables from nvarchar(4000) to nvarchar(max) to avoid truncation
--					of dynamic SQL.
-- 02 Nov 2015	vql	R53910	12	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int
Declare @sSQLString			nvarchar(max)

Declare @bIsExternalUser		bit
Declare @bIsWIPAvailable		bit

Declare	@sCurrencyCode 			nvarchar(3)
Declare @nCaseKey			int

Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime -- the end date of the current period

Declare @sWIPWhere			nvarchar(max)
Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @dtToday			datetime

Declare @bIsSplitMultiDebtor		bit
Declare @bShowAllocatedDebtorWIP        bit

set 	@dtToday = getdate()
Set     @nErrorCode = 0			

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML	
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

If @nErrorCode = 0		
Begin
	-- 1) Retrieve the Filter elements using element-centric mapping (implement 
	--    Case Insensitive searching) 
	
	Set @sSQLString = 	
	"Select @sCurrencyCode		= CurrencyCode,"+CHAR(10)+	
	-- Extract the CaseKey filter criteria to pass to the fn_FilterUserCases to improve 
	-- performance for external users
	"	@nCaseKey		= CaseKey,"+CHAR(10)+
	"       @bShowAllocatedDebtorWIP = ShowAllocatedDebtorWIP"+CHAR(10)+
	"from	OPENXML (@idoc, '/wp_ListWorkInProgress/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CurrencyCode	nvarchar(3)	'CurrencyCode/text()',"+CHAR(10)+
	"	      CaseKey		int		'CaseKey/text()',"+CHAR(10)+
	"	      ShowAllocatedDebtorWIP	bit	'ShowAllocatedDebtorWIP/text()'"+CHAR(10)+
	"     	     )"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sCurrencyCode		nvarchar(3)		output,
				  @nCaseKey			int			output,
				  @bShowAllocatedDebtorWIP      bit                     output',
				  @idoc				= @idoc,
				  @sCurrencyCode		= @sCurrencyCode	output,
				  @nCaseKey			= @nCaseKey		output,
				  @bShowAllocatedDebtorWIP      = @bShowAllocatedDebtorWIP      output
		
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc			
	
	Set @nErrorCode=@@Error
End

-- Determine the ageing periods to be used for the aged balance calculations
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetAgeingBrackets @pdtBaseDate	  = @dtBaseDate		OUTPUT,
						@pnBracket0Days   = @nAge0		OUTPUT,
						@pnBracket1Days   = @nAge1 		OUTPUT,
						@pnBracket2Days   = @nAge2		OUTPUT,
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture	  = @psCulture
End

-- Determine if the user is internal or external AND
-- Check whether the Work In Progress Items topic available:
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser = UI.ISEXTERNALUSER,
		@bIsWIPAvailable = CASE WHEN TS.IsAvailable = 1 THEN 1 ELSE 0 END
	from USERIDENTITY UI
	left join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 120, default, @dtToday) TS
			on (TS.IsAvailable = 1)
	where UI.IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit	OUTPUT,
				  @bIsWIPAvailable	bit	OUTPUT,
				  @pnUserIdentityId	int,
				  @dtToday		datetime',
				  @bIsExternalUser	= @bIsExternalUser	OUTPUT,
				  @bIsWIPAvailable	= @bIsWIPAvailable	OUTPUT,
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @dtToday		= @dtToday
End

If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select @bIsSplitMultiDebtor = COLBOOLEAN
	from SITECONTROL 	
	where CONTROLID = 'WIP Split Multi Debtor'"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsSplitMultiDebtor	bit	OUTPUT',
				  @bIsSplitMultiDebtor	= @bIsSplitMultiDebtor	OUTPUT
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
and (@bIsExternalUser = 0
 or  @bIsExternalUser is null)
Begin
	-- Populating Header Result Set
	Set @sSQLString = "
	Select 	W.CASEID	as CaseKey,
		C.IRN		as CaseReference,
		W.ENTITYNO	as EntityKey,   
		N.NAME		as EntityName,
		CASE WHEN ISNULL(@bShowAllocatedDebtorWIP,0) = 1 THEN NULL ELSE W.ACCTCLIENTNO END	
		                as WipNameKey,
		CASE WHEN ISNULL(@bShowAllocatedDebtorWIP,0) = 1 THEN NULL ELSE dbo.fn_FormatNameUsingNameNo(NW.NAMENO, null) End
				as WipName,
		CASE WHEN ISNULL(@bShowAllocatedDebtorWIP,0) = 1 THEN NULL ELSE NW.NAMECODE End	
		                as WipNameCode,
		sum(ISNULL(W.BALANCE, 0))	
				as LocalTotal,
		-- The 'ForeignTotal' should only be calculated if the @sCurrencyCode parameter
		-- is not null 
		CASE WHEN @sCurrencyCode IS NOT NULL 
	     	     THEN sum(ISNULL(W.FOREIGNBALANCE, 0))	
	     	     ELSE NULL 
		END		as ForeignTotal,
		@sCurrencyCode	as RequestedCurrencyCode,
		@sLocalCurrencyCode	as LocalCurrencyCode,
		@nLocalDecimalPlaces	as LocalDecimalPlaces 
	from WORKINPROGRESS W 
	join NAME N 	 	on (N.NAMENO = W.ENTITYNO)
	left join NAME NW	on (NW.NAMENO = W.ACCTCLIENTNO)
	left join CASES C		on (C.CASEID = W.CASEID)
	where exists (Select 1"+char(10)+
	@sWIPWhere+char(10)+
	"and XW.ENTITYNO=W.ENTITYNO"+char(10)+
	"and XW.TRANSNO=W.TRANSNO"+char(10)+	
	"and XW.WIPSEQNO=W.WIPSEQNO)"+char(10)+
	"group by W.CASEID, C.IRN, W.ENTITYNO, N.NAME,
	CASE WHEN ISNULL(@bShowAllocatedDebtorWIP,0) = 1 THEN NULL ELSE W.ACCTCLIENTNO END, 
	CASE WHEN ISNULL(@bShowAllocatedDebtorWIP,0) = 1 THEN NULL ELSE dbo.fn_FormatNameUsingNameNo(NW.NAMENO, null) END, 
	CASE WHEN ISNULL(@bShowAllocatedDebtorWIP,0) = 1 THEN NULL ELSE NW.NAMECODE END"    
 
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId 	int,
					  @sCurrencyCode	nvarchar(3),
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint,
					  @bShowAllocatedDebtorWIP      bit',					 
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sCurrencyCode	= @sCurrencyCode,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces  = @nLocalDecimalPlaces,
					  @bShowAllocatedDebtorWIP = @bShowAllocatedDebtorWIP

	-- Populating WipItem result set
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select 	W.ENTITYNO	as EntityNo,   
			W.TRANSNO	as TransNo,
			W.WIPSEQNO	as WipSeqNo,
			W.TRANSDATE	as ItemDate,
			W.WIPCODE	as WipCode,
			--Services, Disbursements, Overheads
			"+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)
					+ " as WipCategory,
			"+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WTM',@sLookupCulture,@pbCalledFromCentura)
					+ " as WipDescription,
			ISNULL("+ dbo.fn_SqlTranslatedColumn('WORKINPROGRESS',null,'LONGNARRATIVE','W',@sLookupCulture,@pbCalledFromCentura)+", "+ dbo.fn_SqlTranslatedColumn('WORKINPROGRESS','SHORTNARRATIVE',null,'W',@sLookupCulture,@pbCalledFromCentura)+") as Narrative,
			-- Use the hours and minutes of the WorkInProgress.TotalTime to calculate TotalMinutes.
			datediff(mi,convert(datetime, substring(convert(nvarchar,W.TOTALTIME,121),1,11)+'00:00:00.000', 121), W.TOTALTIME)
					as TotalMinutes,
			ISNULL(W.FOREIGNCURRENCY, @sLocalCurrencyCode)
					as ItemCurrencyCode,
			W.CHARGEOUTRATE	as ChargeOutRate,
			STAFF.NAMENO	as StaffKey,
			dbo.fn_FormatNameUsingNameNo(STAFF.NAMENO, NULL)
				 	as StaffName,
			STAFF.NAMECODE	as StaffCode,
			TRS.STATUS_ID	as StatusKey,
			DB.NAMENO	as DebtorKey,
			DB.NAMECODE	as DebtorCode,
			dbo.fn_FormatNameUsingNameNo(DB.NAMENO, NULL)
				 	as DebtorName,
			"+dbo.fn_SqlTranslatedColumn('TRANSACTION_STATUS','STATUS_DESCRIPTION',null,'TRS',@sLookupCulture,@pbCalledFromCentura)
					+ " as Status,
			DATEDIFF(dd,W.TRANSDATE,GETDATE()) 	
					as Age,
			W.LOCALVALUE	as LocalValue,
			W.BALANCE	as LocalBalance,
			W.FOREIGNVALUE	as ForeignValue,
			W.FOREIGNBALANCE as ForeignBalance,
			SUP.NAMENO	as SupplierKey,
			dbo.fn_FormatNameUsingNameNo(SUP.NAMENO, NULL)
					as SupplierName,
			SUP.NAMECODE	as SupplierCode,
			W.INVOICENUMBER	as InvoiceNumber,
			TC.USERCODE	as ProductCode,
			"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
					+ " as ProductDescription,	
			CONVERT(nvarchar(11), W.ENTITYNO) +'^'+ CONVERT(nvarchar(11),W.TRANSNO) +'^'+ CONVERT(nvarchar(6),W.WIPSEQNO) as RowKey	 
		from WORKINPROGRESS W 
		join WIPTEMPLATE WTM 		on (WTM.WIPCODE = W.WIPCODE)	
		join WIPTYPE WT 		on (WT.WIPTYPEID = WTM.WIPTYPEID)	
		join WIPCATEGORY WC 		on (WC.CATEGORYCODE = WT.CATEGORYCODE)
		join NAME N 	 		on (N.NAMENO = W.ENTITYNO)
		join TRANSACTION_STATUS TRS  	on (TRS.STATUS_ID = W.STATUS)
		left join NAME STAFF		on (STAFF.NAMENO = W.EMPLOYEENO)
		left join NAME DB		on (DB.NAMENO = W.ACCTCLIENTNO and @bIsSplitMultiDebtor = 1)
		left join NAME SUP		on (SUP.NAMENO = W.ASSOCIATENO)
		left join TABLECODES TC		on (TC.TABLECODE = W.PRODUCTCODE)
		where exists (Select 1"+char(10)+
		@sWIPWhere+char(10)+
		"and XW.ENTITYNO=W.ENTITYNO"+char(10)+
		"and XW.TRANSNO=W.TRANSNO"+char(10)+	
		"and XW.WIPSEQNO=W.WIPSEQNO)"+char(10)+
		"order by W.TRANSDATE, WTM.DESCRIPTION"  
	        
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnUserIdentityId 	int,
						  @sCurrencyCode	nvarchar(3),
						  @sLocalCurrencyCode	nvarchar(3),
						  @bIsSplitMultiDebtor	bit',					 
						  @pnUserIdentityId 	= @pnUserIdentityId,
						  @sCurrencyCode	= @sCurrencyCode,
						  @sLocalCurrencyCode	= @sLocalCurrencyCode,
						  @bIsSplitMultiDebtor	= @bIsSplitMultiDebtor
		Set @pnRowCount=@@Rowcount	
	
	End
End
Else If @nErrorCode = 0
and     @bIsExternalUser = 1
Begin
	-- Populating Header Result Set
	Set @sSQLString = "
	Select 	W.CASEID	as CaseKey,
		C.IRN		as CaseReference,
		W.ENTITYNO	as EntityKey,   
		N.NAME		as EntityName,
		sum(ISNULL(W.BALANCE, 0))	
				as LocalTotal,
		-- The 'ForeignTotal' should only be calculated if the @sCurrencyCode parameter
		-- is not null 
		CASE WHEN @sCurrencyCode IS NOT NULL 
	     	     THEN sum(ISNULL(W.FOREIGNBALANCE, 0))	
	     	     ELSE NULL 
		END		as ForeignTotal,
		@sCurrencyCode	as RequestedCurrencyCode,
		@sLocalCurrencyCode	as LocalCurrencyCode,
		@nLocalDecimalPlaces	as LocalDecimalPlaces,
		FC.CLIENTREFERENCENO
				as YourReference,
		C.CURRENTOFFICIALNO
				as CurrentOfficialNumber
	from WORKINPROGRESS W 	
	join NAME N 	 	on (N.NAMENO = W.ENTITYNO)
	left join CASES C		on (C.CASEID = W.CASEID)
	left join dbo.fn_FilterUserCases(@pnUserIdentityId, @bIsExternalUser, @nCaseKey) FC
				on (FC.CASEID = W.CASEID)
	where exists (Select 1"+char(10)+
	@sWIPWhere+char(10)+
	"and XW.ENTITYNO=W.ENTITYNO"+char(10)+
	"and XW.TRANSNO=W.TRANSNO"+char(10)+	
	"and XW.WIPSEQNO=W.WIPSEQNO)"+char(10)+
	"and (FC.CASEID is not null or W.CASEID is null)"+char(10)+
	-- Empty dataset should be produced if the user does not have access to the Work In Progress Items information 
	-- security topic.  
	"and @bIsWIPAvailable=1"+char(10)+
	"group by W.CASEID, C.IRN, W.ENTITYNO, N.NAME, FC.CLIENTREFERENCENO, C.CURRENTOFFICIALNO"    

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId 	int,
					  @bIsExternalUser	bit,
					  @sCurrencyCode	nvarchar(3),
					  @nCaseKey		int,
					  @bIsWIPAvailable	bit,
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint',
					 
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @bIsExternalUser	= @bIsExternalUser,
					  @sCurrencyCode	= @sCurrencyCode,
					  @nCaseKey		= @nCaseKey,
					  @bIsWIPAvailable	= @bIsWIPAvailable,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces  = @nLocalDecimalPlaces

	-- Populating WipItem result set
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select 	W.ENTITYNO	as EntityNo,   
			W.TRANSNO	as TransNo,
			W.WIPSEQNO	as WipSeqNo,
			W.TRANSDATE	as ItemDate,
			--Services, Disbursements, Overheads
			"+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)
					+ " as WipCategory,
			"+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WTM',@sLookupCulture,@pbCalledFromCentura)
					+ " as WipDescription,
			ISNULL("+ dbo.fn_SqlTranslatedColumn('WORKINPROGRESS',null,'LONGNARRATIVE','W',@sLookupCulture,@pbCalledFromCentura)+", "+ dbo.fn_SqlTranslatedColumn('WORKINPROGRESS','SHORTNARRATIVE',null,'W',@sLookupCulture,@pbCalledFromCentura)+") as Narrative,
			ISNULL(W.FOREIGNCURRENCY, @sLocalCurrencyCode)
					as ItemCurrencyCode,
			DATEDIFF(dd,W.TRANSDATE,GETDATE()) 	
					as Age,
			W.BALANCE	as LocalBalance,
			W.FOREIGNBALANCE as ForeignBalance,	 
			CONVERT(nvarchar(11), W.ENTITYNO) +'^'+ CONVERT(nvarchar(11),W.TRANSNO) +'^'+ CONVERT(nvarchar(6),W.WIPSEQNO) as RowKey
		from WORKINPROGRESS W 
		join WIPTEMPLATE WTM 		on (WTM.WIPCODE = W.WIPCODE)	
		join WIPTYPE WT 		on (WT.WIPTYPEID = WTM.WIPTYPEID)	
		join WIPCATEGORY WC 		on (WC.CATEGORYCODE = WT.CATEGORYCODE)
		join NAME N 	 		on (N.NAMENO = W.ENTITYNO)
		left join dbo.fn_FilterUserCases(@pnUserIdentityId, @bIsExternalUser, @nCaseKey) FC
						on (FC.CASEID = W.CASEID)
		where exists (Select 1"+char(10)+
		@sWIPWhere+char(10)+
		"and XW.ENTITYNO=W.ENTITYNO"+char(10)+
		"and XW.TRANSNO=W.TRANSNO"+char(10)+	
		"and XW.WIPSEQNO=W.WIPSEQNO)"+char(10)+
		"and (FC.CASEID is not null or W.CASEID is null)"+char(10)+
		-- Empty dataset should be produced if the user does not have access to the Work In Progress Items information 
		-- security topic.  
		"and @bIsWIPAvailable=1"+char(10)+
		"order by W.TRANSDATE, WTM.DESCRIPTION"  

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnUserIdentityId 	int,
						  @bIsExternalUser	bit,
						  @sCurrencyCode	nvarchar(3),
						  @nCaseKey		int,
						  @bIsWIPAvailable	bit,
						  @sLocalCurrencyCode	nvarchar(3)',
						 
						  @pnUserIdentityId 	= @pnUserIdentityId,
						  @bIsExternalUser	= @bIsExternalUser,
						  @sCurrencyCode	= @sCurrencyCode,
						  @nCaseKey		= @nCaseKey,
						  @bIsWIPAvailable	= @bIsWIPAvailable,
						  @sLocalCurrencyCode	= @sLocalCurrencyCode	
		Set @pnRowCount=@@Rowcount	
	
	End
End

Return @nErrorCode
GO

Grant execute on dbo.wp_ListCaseOrNameWipItems to public
GO
