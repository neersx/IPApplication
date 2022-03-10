-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ListBillRules
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListBillRules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListBillRules.'
	Drop procedure [dbo].[biw_ListBillRules]
End
Print '**** Creating Stored Procedure dbo.biw_ListBillRules...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ListBillRules
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnRuleType			int,
 	@pnCaseId			int		=null,
 	@pnDebtorNo			int		= null,
 	@pnEntityNo			int		= null,
 	@pnNameCategory			int		= null,
 	@pnLocalClientFlag		decimal(1,0)	= null, 	 		
	@psCaseType			nchar(2)	= null,
	@psPropertyType			nchar(2)	= null,
	@psCaseAction			nvarchar(4)	= null,
	@pnBillingEntity		int		= null,
	@pnMinETBill			decimal(7,2)	= null,
	@psWipCode			nvarchar(12)	= null,
	@psCaseCountry			nvarchar(6)	= null,
	@pnBestCriteriaOnly		bit		= 0,
	@pbExactMatch			bit		= 0,		
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure.
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null
)

as
-- PROCEDURE:	biw_ListBillRules
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions Pty Limited
-- DESCRIPTION:	Lists the Bill Rule records on the basis of Filter Criteria

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 21 Oct 2011	KR	R9451	1	Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
declare @sSQLString		nvarchar(max)
declare @sSelect		nvarchar(max)
declare @sFrom			nvarchar(4000)
Declare @sOrder			nvarchar(1000)	-- the SQL sort order
Declare @sLookupCulture		nvarchar(10)
Declare @nCount			int
Declare @nColumnNo		tinyint
declare @sColumn		nvarchar(100)
declare @sQualifier		nvarchar(50)
declare @sCorrelationSuffix	nvarchar(20)
declare @sPublishName		nvarchar(50)
declare @sTableColumn		nvarchar(1000)
declare @nOrderPosition		tinyint
declare @sOrderDirection	nvarchar(5)
Declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @pnFilterGroupIndex	int

-- Initialise variables
Set @nErrorCode			= 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nCount = 1
Set @pnFilterGroupIndex = 1


If @nErrorCode = 0 
Begin	
	Set @sFrom = " from dbo.fn_GetBillRuleRows"+char(10)+
        "(@pnRuleType,"+char(10)+
        "@pnCaseId,"+char(10)+
        "@pnDebtorNo,"+char(10)+		
        "@pnEntityNo,"+char(10)+		
        "@pnNameCategory,"+char(10)+
        "@pnLocalClientFlag,"+char(10)+	
        "@psCaseType,"+char(10)+	
        "@psPropertyType,"+char(10)+
        "@psCaseAction,"+char(10)+
        "@pnBillingEntity,"+char(10)+
        "@pnMinETBill,"+char(10)+
        "@psWipCode,"+char(10)+
        "@psCaseCountry,"+char(10)+
        "@pbExactMatch"+char(10)+        
        ") T"

End


If @nErrorCode=0
and @pnBestCriteriaOnly = 1
Begin
	Set @sSelect = 'Select  TOP 1 '
End
Else
Begin
	Set @sSelect = 'Select '
End

If @nErrorCode=0
Begin
	Set @sSelect = @sSelect + ' T.RULESEQNO,  T.RULETYPE,  T.DEBTORNO,  T.CASEID, T.ENTITYNO,  
				    T.NAMECATEGORY,  T.LOCALCLIENTFLAG,  T.CASETYPE,
				    T.PROPERTYTYPE, T.CASEACTION, T.MINIMUMNETBILL, 
				    T.WIPCODE, T.CASECOUNTRY'	
End
If @nErrorCode=0
Begin
	Set @sSQLString = @sSQLString + @sSelect + @sFrom
End
--select @sSQLString

if @nErrorCode = 0
begin
exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnRuleType		int		OUTPUT,
			@pnCaseId		int		OUTPUT,
			@pnDebtorNo		int		OUTPUT,
			@pnEntityNo		int		OUTPUT,
 			@pnNameCategory		int		OUTPUT,
 			@pnLocalClientFlag	decimal(1,0)	OUTPUT, 	 		
			@psCaseType		nchar(2)	OUTPUT,
			@psPropertyType		nchar(2)	OUTPUT,
			@psCaseAction		nvarchar(4)	OUTPUT,
			@pnBillingEntity	int		OUTPUT,
			@pnMinETBill		decimal(7,2)	OUTPUT,
			@psWipCode		nvarchar(12)	OUTPUT,
			@psCaseCountry		nvarchar(6)	OUTPUT,
			@pbExactMatch		bit',
			@pnRuleType		= @pnRuleType		OUTPUT,
			@pnCaseId		= @pnCaseId		OUTPUT,
			@pnDebtorNo		= @pnDebtorNo		OUTPUT,
			@pnEntityNo		= @pnEntityNo		OUTPUT,
 			@pnNameCategory		= @pnNameCategory	OUTPUT,
 			@pnLocalClientFlag	= @pnLocalClientFlag	OUTPUT, 	 		
			@psCaseType		= @psCaseType		OUTPUT,
			@psPropertyType		= @psPropertyType	OUTPUT,
			@psCaseAction		= @psCaseAction		OUTPUT,
			@pnBillingEntity	= @pnBillingEntity	OUTPUT,
			@pnMinETBill		= @pnMinETBill		OUTPUT,
			@psWipCode		= @psWipCode		OUTPUT,
			@psCaseCountry		= @psCaseCountry	OUTPUT,
			@pbExactMatch		= @pbExactMatch
                
        Set @pnRowCount=@@Rowcount 
        
        If @nErrorCode=0
        Begin
	        set @sSQLString='select @pnRowCount as SearchSetTotalRows'  

	        exec @nErrorCode=sp_executesql @sSQLString,
				        N'@pnRowCount	int',
				          @pnRowCount=@pnRowCount
        End

End

Return @nErrorCode
GO

Grant execute on dbo.biw_ListBillRules to public
GO


