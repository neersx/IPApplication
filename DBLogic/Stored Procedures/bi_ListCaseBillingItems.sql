-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.bi_ListCaseBillingItems   
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[bi_ListCaseBillingItems   ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.bi_ListCaseBillingItems   .'
	Drop procedure [dbo].[bi_ListCaseBillingItems   ]
End
Print '**** Creating Stored Procedure dbo.bi_ListCaseBillingItems   ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.bi_ListCaseBillingItems   
(
	@pnRowCount		int		= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbIsExternalUser 	bit		= null,
	@pnCaseKey  		int		-- Mandatory
)
AS
-- PROCEDURE:	bi_ListCaseBillingItems   
-- VERSION:	15
-- DESCRIPTION:	Populates CaseBillingItemsData dataset. Lists information regarding
--		the billing of the case. Results should only be returned if the user
--		has access to the requested CaseKey.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 25-Sep-2003  TM		1	Procedure created
-- 03-Oct-2003	MF	RFC519	2	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 07-Oct-2003	TM	RFC405	3 	Case Billing web part. Make the row count the 
--					first parameter and name it @pnRowCount.
-- 13-Oct-2003	MF	RFC533	4	If the user is not on USERIDENTITY table then treat as if External User
-- 06-Dec-2003	JEK	RFC406	5	Implement topic level security.
-- 12-Feb-2004	TM	RFC771	6	For an Internal User add the following new columns: Add the following new columns:
--					CaseReference, DisbursementsBilledTotal, OverheadsBilledTotal, ForeignBalance, 
--					LocalBalance, NameCode, EntityNameCode
-- 18-Feb-2004	TM	RFC976	7	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 04-Mar-2004	TM	RFC1032	8	In the Header Result Set and the BillingItem Result Set pass @pnCaseKey as 
--					the @pnCaseKey to the fn_FilterUserCases.
-- 23-May-2005	TM	RFC2594	9	Only perform one lookup of the Billing History subject.
-- 24 Nov 2005	LP	RFC1017	10	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Header result set
-- 13 Jul 2006	SW	RFC3828	11	Pass getdate() to fn_Permission..
-- 05 Aug 2006	AU	RFC4270	12	Return a RowKey and CaseKey for the BillingItem result-set.
-- 29 Oct 2007	SW	RFC5857	13	Implement security check for external user
-- 15 Apr 2013	DV	R13270	14	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	15	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

Declare @sSQLString 		nvarchar(4000)

Declare	@nBilledToDate		decimal(11,2)
Declare @nServicesBilled	decimal(11,2)
Declare @nDisbursements		decimal(11,2)

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @nFilterCaseKey			int
Declare @sClientReferenceNo		nvarchar(80)

Declare @bIsBillingRequired	bit
Declare @dtToday		datetime

Set 	@nErrorCode 		= 0
Set	@pnRowCount		= 0
Set	@dtToday		= getdate()

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= 0
End

-- We need to determine if the user is external and 
-- check whether the Billing History information is required

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@pbIsExternalUser=UI.ISEXTERNALUSER,
		@bIsBillingRequired=CASE WHEN TS.IsAvailable = 1 THEN 1 ELSE 0 END
	from USERIDENTITY UI
	left join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 101, default, @dtToday) TS
					on (TS.IsAvailable=1)
	where UI.IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pbIsExternalUser		bit			OUTPUT,
				  @bIsBillingRequired		bit			OUTPUT,
				  @pnUserIdentityId		int,
				  @dtToday			datetime',
				  @pbIsExternalUser		=@pbIsExternalUser	OUTPUT,
				  @bIsBillingRequired		=@bIsBillingRequired 	OUTPUT,
				  @pnUserIdentityId		=@pnUserIdentityId,
				  @dtToday			=@dtToday

	If @pbIsExternalUser is null
		Set @pbIsExternalUser=1
End

-- Security check, and also prepare variables for CASE result set while checking security
If @nErrorCode = 0
and @pbIsExternalUser = 1
Begin
	Set @sSQLString = "
		Select	@nFilterCaseKey		= CASEID,
			@sClientReferenceNo	= CLIENTREFERENCENO
		from	dbo.fn_FilterUserCases(@pnUserIdentityId,1,@pnCaseKey) FC"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @pnCaseKey			int,
					  @nFilterCaseKey		int			OUTPUT,
					  @sClientReferenceNo		nvarchar(80)		OUTPUT',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnCaseKey			= @pnCaseKey,
					  @nFilterCaseKey		= @nFilterCaseKey	OUTPUT,	
					  @sClientReferenceNo		= @sClientReferenceNo	OUTPUT
	
End
Else
Begin
	Set @nFilterCaseKey = @pnCaseKey
End

-- Populating Header Result Set

-- @nBilledToDate   - Total billed for the case to debtors. 
-- @nServicesBilled - Break down the bill for service charges and store the result in 
--          	      the @nServicesBilled variable.
-- @nDisbursements  - Break down the bill for disbursements charges.
If @nErrorCode = 0
Begin 
	Set @sSQLString = "
	Select @nBilledToDate   = sum(-WH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))),
	       @nServicesBilled = sum(CASE WHEN WT.CATEGORYCODE = 'SC' 
				    	   THEN (-WH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))) 
					   ELSE 0 
				      END)"

	-- Extract the disbursements charges and overhead charges for an Internal User.  	
	If @pbIsExternalUser = 0
	Begin
		Set @sSQLString = @sSQLString + ',' + CHAR(10) + "
		@nDisbursements = sum(CASE WHEN WT.CATEGORYCODE = 'PD' 
				    	   THEN (-WH.LOCALTRANSVALUE * (ISNULL(OI.BILLPERCENTAGE/100, 1)))
					   ELSE 0 
				      END)" 		
		 
	End

	Set @sSQLString = @sSQLString + CHAR(10) + "		     	
	from OPENITEM OI
	join WORKHISTORY WH 		on (WH.REFENTITYNO = OI.ITEMENTITYNO   
					and WH.REFTRANSNO  = OI.ITEMTRANSNO   
					and WH.MOVEMENTCLASS = 2)
	left join WIPTEMPLATE WTP 	on (WTP.WIPCODE = WH.WIPCODE)
	left join WIPTYPE WT 		on (WT.WIPTYPEID = WTP.WIPTYPEID)
	where OI.STATUS = 1 
	and   WH.CASEID = @nFilterCaseKey"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nBilledToDate 	decimal(11, 2)     OUTPUT,
					  @nServicesBilled 	decimal(11, 2) 	   OUTPUT,
					  @nDisbursements	decimal(11, 2)	   OUTPUT,
					  @nFilterCaseKey	int,
					  @pnUserIdentityId	int',
					  @nBilledToDate 	= @nBilledToDate   OUTPUT,
					  @nServicesBilled 	= @nServicesBilled OUTPUT,
					  @nDisbursements	= @nDisbursements  OUTPUT,
					  @nFilterCaseKey 	= @nFilterCaseKey,
					  @pnUserIdentityId	= @pnUserIdentityId
End

-- Populating Header Result Set
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select	C.CASEID 		as 'CaseKey',"+
		-- If the user is an External User then return their Reference
		CASE WHEN(@pbIsExternalUser=1)
			THEN char(10)+"		@sClientReferenceNo	as 'YourReference',"
			    +char(10)+" 	C.IRN			as 'OurReference',"
			ELSE char(10)+"		C.IRN			as 'CaseReference'," 
		END		
		+"		
		C.CURRENTOFFICIALNO	as 'CurrentOfficialNumber',
		@nServicesBilled	as 'ServicesBilledTotal',
		-- 'ServicesPercentage' is rounded to an integer. 
		convert(int, round(@nServicesBilled/CASE WHEN @nBilledToDate = 0 
					    	         THEN 1 
					    	         ELSE @nBilledToDate 
				       		    END * 100,0))
		      			as 'ServicesPercentage',"+		
		-- Case Expenses total should only be returned for an External User.
		CASE WHEN(@pbIsExternalUser=1)
			THEN+char(10)+" 	(@nBilledToDate - @nServicesBilled)"
		 	    +char(10)+"			as 'ExpensesBilledTotal',"
			    +char(10)+"	(100 - convert(int," 
			    +char(10)+"		      round(@nServicesBilled/CASE WHEN @nBilledToDate = 0" 
			    +char(10)+"		    	         		  THEN 1" 
			    +char(10)+" 	    	         		  ELSE @nBilledToDate" 
			    +char(10)+"	       		    	   	     END * 100,0)))"
			    +char(10)+"			as 'ExpensesPercentage',"			      
			-- If the user is an Internal User then split BilledTotal into DisbursementsBilledTotal 
			-- and OverheadsBilledTotal  
			ELSE char(10)+"		@nDisbursements	as 'DisbursementsBilledTotal',"
			    +char(10)+"		convert(int,round(@nDisbursements/CASE WHEN @nBilledToDate = 0" 
			    +char(10)+"		    	         	      THEN 1" 
			    +char(10)+" 	    	         	      ELSE @nBilledToDate" 
			    +char(10)+"	       		    	   	 END * 100,0))"
			    +char(10)+"			as 'DisbursementsPercentage',"	
			    +char(10)+" 		(@nBilledToDate - @nServicesBilled - @nDisbursements)"	
			    +char(10)+"			as 'OverheadsBilledTotal',"
			    -- Calculate Overhead Percentage as 100 - ServicesPercentage - DisbursementPercentage
			    -- to avoide rounding errors.
			    +char(10)+"		(100 - convert(int," 
			    +char(10)+"		       round(@nServicesBilled/CASE WHEN @nBilledToDate = 0" 
			    +char(10)+"		    	         		   THEN 1" 
			    +char(10)+" 	    	         		   ELSE @nBilledToDate" 
			    +char(10)+"	       		    	   	      END * 100,0))"
			    +char(10)+"	    	- "
			    +char(10)+"	      	convert(int,round(@nDisbursements/CASE WHEN @nBilledToDate = 0" 
			    +char(10)+"		    	         		       THEN 1" 
			    +char(10)+" 	    	         		       ELSE @nBilledToDate" 
			    +char(10)+"	       		    	   	          END * 100,0)))"				
			    +char(10)+"			as 'OverheadsPercentage',"	
		END		
		+"					
		@nBilledToDate 		as 'BilledTotal',
		@sLocalCurrencyCode	as 'LocalCurrencyCode',
		@nLocalDecimalPlaces	as 'LocalDecimalPlaces' 
	from CASES C"+
/*
	-- If the user is an External User then we need to add the additional join 
	-- to the filtered list of Cases to ensure that the user actually has access
	-- to the Case
	CASE WHEN(@pbIsExternalUser=1)
		THEN char(10)+"	left join dbo.fn_FilterUserCases(@pnUserIdentityId, 1, @pnCaseKey) FC 
					on (FC.CASEID=C.CASEID)"
	END	
	+*/"
	where C.CASEID = @nFilterCaseKey
	-- Return an emtpy result set if the user does not have access to the Billing History topic
	and @bIsBillingRequired = 1"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @nFilterCaseKey	int,
					  @sClientReferenceNo	nvarchar(80),
					  @nBilledToDate 	decimal(11, 2),
					  @nServicesBilled 	decimal(11, 2),
					  @nDisbursements	decimal(11, 2),
					  @bIsBillingRequired	bit,
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @nFilterCaseKey      	= @nFilterCaseKey,
					  @sClientReferenceNo	= @sClientReferenceNo,
					  @nBilledToDate 	= @nBilledToDate,
					  @nServicesBilled 	= @nServicesBilled,
					  @nDisbursements	= @nDisbursements,
					  @bIsBillingRequired	= @bIsBillingRequired,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces					  
					
End

-- Populating BillingItem Result Set
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	CAST(OI.ITEMENTITYNO 	as nvarchar(11))+'^'+
		CAST(OI.ITEMTRANSNO 	as nvarchar(11))+'^'+
		CAST(OI.ACCTENTITYNO 	as nvarchar(11))+'^'+
		CAST(OI.ACCTDEBTORNO 	as nvarchar(11))
					as 'RowKey',
		@nFilterCaseKey		as 'CaseKey',
		OI.ITEMENTITYNO		as 'ItemEntityNo', 
		OI.ITEMTRANSNO		as 'ItemTransNo',
		OI.ACCTENTITYNO		as 'AcctEntityNo',
		OI.ACCTDEBTORNO		as 'AcctDebtorNo',
		OI.OPENITEMNO		as 'OpenItemNo',
		OI.ITEMDATE 		as 'ItemDate',
		ISNULL(OI.CURRENCY, @sLocalCurrencyCode)
					as 'ItemCurrencyCode',
		OI.LOCALVALUE		as 'LocalValue',
		OI.FOREIGNVALUE		as 'ForeignValue',"+		
		-- If the user is an External User then return the CaseServices and the CaseExpenses columns.
		CASE WHEN(@pbIsExternalUser=1) 
		     THEN char(10)+"	
				-- Service Charges (WT.CATEGORYCODE = 'SC') bill amount pure item
				convert(decimal(11,2),
				sum(CASE WHEN WT.CATEGORYCODE = 'SC' 
					 THEN (-WH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))) 
					 ELSE 0 
				    END))		as 'CaseServices',
				convert(decimal(11,2),
				(sum(-WH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1)))
				 - 
				 sum(CASE WHEN WT.CATEGORYCODE = 'SC' 
					  THEN (-WH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))) 
					  ELSE 0 
				     END)))		as 'CaseExpenses',"				      
		     -- If the user is an Internal User then replace Case Services and Case Expenses columns
		     -- with the ForeignBalance and LocalBalance. 
		     ELSE char(10)+"		CASE WHEN TS1.IsAvailable=1 THEN OI.FOREIGNBALANCE ELSE NULL END as 'ForeignBalance',"+char(10)+
				      "		CASE WHEN TS1.IsAvailable=1 THEN OI.LOCALBALANCE   ELSE NULL END as 'LocalBalance',"
		END		
		+"
		convert(decimal(11,2),		
		sum(-WH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))))
					as 'CaseTotal',
		OI.ACCTDEBTORNO		as 'NameKey',
		dbo.fn_FormatFullName(DEBTOR.NAME, DEBTOR.FIRSTNAME, DEBTOR.MIDDLENAME, DEBTOR.SUFFIX, null, null)
					as 'Name',
		OI.ACCTENTITYNO		as 'EntityKey',
		dbo.fn_FormatFullName(ENTITY.NAME, ENTITY.FIRSTNAME, ENTITY.MIDDLENAME, ENTITY.SUFFIX, null, null)
					as 'EntityName',
		DEBTOR.NAMECODE		as 'NameCode',
		ENTITY.NAMECODE		as 'EntityNameCode'
	from  OPENITEM OI 
	join  WORKHISTORY WH 		on (WH.REFENTITYNO = OI.ITEMENTITYNO 
					and WH.REFTRANSNO  = OI.ITEMTRANSNO 
					and WH.MOVEMENTCLASS = 2) 
	join CASES C			on (C.CASEID=WH.CASEID)"+
/*
	-- If the user is an External User then we need to add the additional join 
	-- to the filtered list of Cases to ensure that the user actually has access
	-- to the Case
	CASE WHEN(@pbIsExternalUser=1)
		THEN char(10)+"	left join dbo.fn_FilterUserCases(@pnUserIdentityId, 1, @pnCaseKey) FC 
					on (FC.CASEID=C.CASEID)"
	END	
	+*/"
	join  NAME DEBTOR 		on (DEBTOR.NAMENO = OI.ACCTDEBTORNO) 
	join  NAME ENTITY 		on (ENTITY.NAMENO = OI.ACCTENTITYNO) 
	left join WIPTEMPLATE WTP 	on (WTP.WIPCODE = WH.WIPCODE)
	left join WIPTYPE WT 		on (WT.WIPTYPEID = WTP.WIPTYPEID)
	left join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 200, default, @dtToday) TS1
					on (TS1.IsAvailable=1)
	where OI.STATUS = 1 
	and   WH.CASEID = @nFilterCaseKey 
	-- Return an emtpy result set if the user does not have access to the Billing History topic
	and   @bIsBillingRequired = 1
	group by OI.ITEMENTITYNO, OI.ITEMTRANSNO, OI.ACCTENTITYNO, OI.ACCTDEBTORNO,
		 OI.OPENITEMNO, OI.ITEMDATE, OI.CURRENCY, OI.LOCALVALUE, OI.ACCTDEBTORNO, 
		 OI.FOREIGNVALUE, DEBTOR.NAME, DEBTOR.FIRSTNAME, DEBTOR.MIDDLENAME, DEBTOR.SUFFIX,
		 OI.ACCTENTITYNO, ENTITY.NAME, ENTITY.FIRSTNAME, ENTITY.MIDDLENAME, ENTITY.SUFFIX, 
		 OI.FOREIGNBALANCE, OI.LOCALBALANCE, DEBTOR.NAMECODE, ENTITY.NAMECODE, TS1.IsAvailable  
	order by 'ItemDate' DESC, 'OpenItemNo'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @nFilterCaseKey	int,
					  @bIsBillingRequired	bit,
					  @sLocalCurrencyCode	nvarchar(3),
					  @dtToday		datetime',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @nFilterCaseKey       = @nFilterCaseKey,
					  @bIsBillingRequired	= @bIsBillingRequired,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @dtToday		= @dtToday	

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.bi_ListCaseBillingItems    to public
GO
