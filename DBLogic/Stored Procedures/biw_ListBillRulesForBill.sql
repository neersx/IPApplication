-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ListBillRulesForBill
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListBillRulesForBill]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListBillRulesForBill.'
	Drop procedure [dbo].[biw_ListBillRulesForBill]
End
Print '**** Creating Stored Procedure dbo.biw_ListBillRulesForBill...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ListBillRulesForBill
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure.

 	@pnDebtorKey			int,
 	@pnCaseKey			int		= null,
 	@pnEntityKey			int		= null,
 	@psActionKey			nvarchar(4) = null
)

as
-- PROCEDURE:	biw_ListBillRulesForBill
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions Pty Limited
-- DESCRIPTION:	Lists the Bill Rule records on the basis of Filter Criteria

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 21 Oct 2011	KR	R9451	1	Procedure created (biw_ListBillRules)
-- 01 Nov 2011	AT	R9451	2	Created new version of biw_ListBillRules to work with Billing Wizard.
-- 19 Dec 2011	AT	R11649	3	Fixed case sensitive syntax error in order by.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
declare @sSQLString		nvarchar(max)
declare @sSelect		nvarchar(max)
declare @sFrom			nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @nRuleType		int

Declare @nNameCategory		int
Declare @bLocalClientFlag	bit

Declare @sCaseType		nchar(2)
Declare @sPropertyType		nchar(2)
Declare @sCaseAction		nvarchar(4)
Declare @sCaseCountry		nvarchar(6)


-- Initialise variables
Set @nErrorCode			= 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	-- Derive debtor criteria
	Set @sSQLString = 'SELECT @nNameCategory = CATEGORY,
				@bLocalClientFlag = LOCALCLIENTFLAG
				FROM IPNAME WHERE NAMENO = @pnDebtorKey'
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nNameCategory	int output,
			@bLocalClientFlag	bit output,
			@pnDebtorKey		int',
			@nNameCategory		= @nNameCategory output,
			@bLocalClientFlag	= @bLocalClientFlag output,
			@pnDebtorKey		= @pnDebtorKey
End

If @nErrorCode = 0 and @pnCaseKey is not null
Begin
	-- Derive Case criteria
	Set @sSQLString = 'SELECT @sCaseType = CASETYPE,
				  @sPropertyType = PROPERTYTYPE,
				  @sCaseAction = (select TOP 1 ACTION FROM OPENACTION WHERE CASEID = @pnCaseKey
							ORDER BY POLICEEVENTS DESC, DATEUPDATED DESC),
				  @sCaseCountry = COUNTRYCODE
			FROM CASES
			WHERE CASEID = @pnCaseKey'	
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@sCaseType		nchar(2) output,
			@sPropertyType		nchar(2) output,
			@sCaseAction		nvarchar(4) output,
			@sCaseCountry		nvarchar(6) output,
			@pnCaseKey		int',
			@sCaseType		= @sCaseType output,
			@sPropertyType		= @sPropertyType output,
			@sCaseAction		= @sCaseAction output,
			@sCaseCountry		= @sCaseCountry output,
			@pnCaseKey		= @pnCaseKey
End

If @nErrorCode = 0 
Begin
	Set @sFrom = "from dbo.fn_GetBillRuleRows"+char(10)+
        "(@nRuleType,"+char(10)+
        "null,"+char(10)+
        "@pnCaseKey,"+char(10)+
        "@pnDebtorKey,"+char(10)+		
        "@pnEntityKey,"+char(10)+		
        "@nNameCategory,"+char(10)+
        "@bLocalClientFlag,"+char(10)+	
        "@sCaseType,"+char(10)+	
        "@sPropertyType,"+char(10)+
        "isnull(@psActionKey,@sCaseAction),"+char(10)+
        "@sCaseCountry,"+char(10)+
        "@bExactMatch"+char(10)+        
        ") as T"
End

if @nErrorCode = 0 and @pnEntityKey is null
Begin
	-- Try and derive the Entity to get the other rules
	Set @sSelect = 'Select @pnBillingEntityKey = (SELECT TOP 1 T.BILLINGENTITY'
	
	Set @sSQLString = @sSelect + char(10) + @sFrom + ' order by T.BESTFITSCORE Desc)'
				
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnBillingEntityKey	int output,
			@nRuleType		int,
			@pnCaseKey		int,
			@pnDebtorKey		int,
			@pnEntityKey		int,
 			@nNameCategory		int,
 			@bLocalClientFlag	bit,
			@sCaseType		nchar(2),
			@sPropertyType		nchar(2),
			@sCaseAction		nvarchar(4),
			@psActionKey		nvarchar(4),
			@sCaseCountry		nvarchar(6),
			@bExactMatch		bit',
			@pnBillingEntityKey	= @pnEntityKey output,
			@nRuleType		= 22,
			@pnCaseKey		= @pnCaseKey,
			@pnDebtorKey		= @pnDebtorKey,
			@pnEntityKey		= null,
 			@nNameCategory		= @nNameCategory,
 			@bLocalClientFlag	= @bLocalClientFlag,
			@sCaseType		= @sCaseType,
			@sPropertyType		= @sPropertyType,
			@sCaseAction		= @sCaseAction,
			@psActionKey		= @psActionKey,
			@sCaseCountry		= @sCaseCountry,
			@bExactMatch		= 0
End

-- Now return the rules
If @nErrorCode=0
Begin
	Set @sSelect = 'Select 
			T.RULESEQNO as RuleSeqNo,
			T.RULETYPE as RuleType,
			T.BILLINGENTITY as BillingEntity,
			T.WIPCODE as WIPCode,
			T.MINIMUMNETBILL as MinimumNetBill,
			T.DEBTORNO as DebtorKey,
			T.CASEID as CaseKey,
			T.ENTITYNO as EntityKey,
			T.NAMECATEGORY as NameCategory,
			T.LOCALCLIENTFLAG as LocalClientFlag,
			T.CASETYPE as CaseType,
			T.PROPERTYTYPE as PropertyType,
			T.CASEACTION as CaseAction,
			T.CASECOUNTRY as CaseCountry,
			T.BESTFITSCORE as BestFitScore'
End

if @nErrorCode = 0
begin
	Set @sSQLString = @sSelect + char(10) + @sFrom + char(10) +
				'order by RuleType, BestFitScore Desc'
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nRuleType		int,
			@pnCaseKey		int,
			@pnDebtorKey		int,
			@pnEntityKey		int,
 			@nNameCategory		int,
 			@bLocalClientFlag	bit,
			@sCaseType		nchar(2),
			@sPropertyType		nchar(2),
			@sCaseAction		nvarchar(4),
			@psActionKey		nvarchar(4),
			@sCaseCountry		nvarchar(6),
			@bExactMatch		bit',
			@nRuleType		= @nRuleType,
			@pnCaseKey		= @pnCaseKey,
			@pnDebtorKey		= @pnDebtorKey,
			@pnEntityKey		= @pnEntityKey,
 			@nNameCategory		= @nNameCategory,
 			@bLocalClientFlag	= @bLocalClientFlag,
			@sCaseType		= @sCaseType,
			@sPropertyType		= @sPropertyType,
			@sCaseAction		= @sCaseAction,
			@psActionKey		= @psActionKey,
			@sCaseCountry		= @sCaseCountry,
			@bExactMatch		= 0
End

--print @nRuleType
--print @pnCaseKey
--print @pnDebtorKey
--print @pnEntityKey
--print @nNameCategory
--print @bLocalClientFlag
--print @sCaseType
--print @sPropertyType
--print isnull(@psActionKey, @sCaseAction)
--print @sCaseCountry

Return @nErrorCode
GO

Grant execute on dbo.biw_ListBillRulesForBill to public
GO


