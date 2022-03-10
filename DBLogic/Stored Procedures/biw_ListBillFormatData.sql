-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ListBillFormatData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListBillFormatData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListBillFormatData.'
	Drop procedure [dbo].[biw_ListBillFormatData]
End
Print '**** Creating Stored Procedure dbo.biw_ListBillFormatData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_ListBillFormatData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnBillFormatKey	int		= null,
	@pnRowNumber		int		= 0, --0:get last, 1:get first
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	biw_ListBillFormatData
-- VERSION:	9
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the details of a single bill format.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 20 Jan 2010	LP	RFC8203	1	Procedure created
-- 08 Apr 2010  LP      RFC8203	2	Fix logic for returning consolidation values.
-- 23 Apr 2010  LP      R100225	3	Fix logic for returning Consolidate By Case values.
-- 19 May 2010	LP	RFC7276	4	Return FORMATPROFILEID as FormatProfileKey.
-- 24 Jun 2010	MS	RFC7269	5	Added ConsolidateMAR in the select list	
-- 06 Dec 2011	AT	R10458	6	Return SORTTAXCODE.	
-- 31 Jan 2012	KR	R10832	7	Changed SINGLECASE value for Debtor Only and Multiple Case to match with c/s
-- 02 Nov 2015	vql	R53910	8	Adjust formatted names logic (DR-15543).
-- 17 Jul 2018  MS      R73287  9       Added rdl extension check in where condition

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSelect	nvarchar(max)
declare @nIndex		int		-- the bill format id to start the search from
declare @sWhere		nvarchar(1000)
declare @sOrderBy	nvarchar(1000)
declare @nLastRow	int

-- Initialise variables
Set @nErrorCode = 0
Set @sWhere = " WHERE UPPER(RIGHT(BILLFORMATREPORT, 3)) = 'RDL'"
Set @sOrderBy = 'ORDER BY FORMATNAME'
Set @sSelect = ""

-- Set maximum row number
If @nErrorCode = 0
Begin
	Select @nLastRow = COUNT(BILLFORMATID)
	from BILLFORMAT
End

-- Get last row if none specified
If @nErrorCode = 0
and @pnRowNumber = 0
Begin
	Set @pnRowNumber = @nLastRow
End


-- Construct the query
If @nErrorCode = 0
Begin
	
	If @pnBillFormatKey is not null
	and @pnBillFormatKey <> ""	-- retrieve the specific Bill Format record
	Begin
		Set @sWhere = @sWhere + ' AND B.BILLFORMATID = ' + convert(nvarchar(10),@pnBillFormatKey)
	End	
	
	-- Bill Format result set
	
	Set @sSelect = @sSelect + char(10)+
		"WITH OrderedRows AS (
		Select 
			B.BILLFORMATID as RowKey,
			B.BILLFORMATID as BillFormatKey,
			B.FORMATNAME as BillFormatName,
			B.LANGUAGE as LanguageKey,
			B.ENTITYNO as EntityKey,
			dbo.fn_FormatNameUsingNameNo(BE.NAMENO, null) as EntityName,
			B.CASETYPE as CaseTypeKey,	
			CT.CASETYPEDESC as CaseTypeDescription,
			B.ACTION as ActionKey,
			B.EMPLOYEENO as StaffKey,
			dbo.fn_FormatNameUsingNameNo(EMP.NAMENO, null) as StaffName,
			B.BILLFORMATDESC as BillFormatDescription,
			B.BILLFORMATREPORT as ReportTemplateFileName,
			B.OFFICEID as OfficeKey,
			B.DEBITNOTE as DebitNoteKey,
			B.COVERINGLETTER as CoverLetterKey,
			B.PROPERTYTYPE as PropertyTypeKey,
			PT.PROPERTYNAME as PropertyTypeDescription,
			CASE WHEN B.RENEWALWIP = 0 THEN convert(bit,1) ELSE convert(bit,0) END as IsNonRenewalWip,
			CASE WHEN B.RENEWALWIP = 1 THEN convert(bit,1) ELSE convert(bit,0) END as IsRenewalWip,
			CASE WHEN B.SINGLECASE = 2 THEN convert(bit,1) ELSE convert(bit,0) END as IsDebtorOnly,
			CASE WHEN B.SINGLECASE = 1 THEN convert(bit,1) ELSE convert(bit,0) END as IsSingleCase,
			CASE WHEN B.SINGLECASE = 0 THEN convert(bit,1) ELSE convert(bit,0) END as IsMultiCase,
			ROW_NUMBER() OVER("+@sOrderBy+") as RowNumber," + char(10)+ 		
			CASE WHEN @pnRowNumber = 1 THEN +"cast (1 as bit)" ELSE +"cast (0 as bit)" END + "as IsFirst," +char(10)+						
			CASE WHEN @pnRowNumber = @nLastRow THEN +"cast (1 as bit)" ELSE +"cast (0 as bit)" END + "as IsLast," +char(10)+
			"CAST(ISNULL(B.CONSOLIDATECHTYP,0) as bit) as ConsolidateChargeType,
			CASE WHEN ISNULL(B.CONSOLIDATESC,0) = 0 THEN 0 
			     WHEN B.CONSOLIDATESC > 10 THEN B.CONSOLIDATESC - 10 
			     ELSE B.CONSOLIDATESC END as ConsolidateSC,
			CASE WHEN B.CONSOLIDATESC > 10 THEN convert(bit,1) ELSE convert(bit,0) END as ConsolidateSCByCase,
			CASE WHEN ISNULL(B.CONSOLIDATEPD,0) = 0 THEN 0 
			     WHEN B.CONSOLIDATEPD > 10 THEN B.CONSOLIDATEPD - 10   
			     ELSE B.CONSOLIDATEPD END as ConsolidatePD,
			CASE WHEN B.CONSOLIDATEPD > 10 THEN convert(bit,1) ELSE convert(bit,0) END as ConsolidatePDByCase,
			CASE WHEN ISNULL(B.CONSOLIDATEOR,0) = 0 THEN 0 
			     WHEN B.CONSOLIDATEOR > 10 THEN B.CONSOLIDATEOR - 10
			     ELSE B.CONSOLIDATEOR END as ConsolidateOR,
			CASE WHEN B.CONSOLIDATEOR > 10 THEN convert(bit,1) ELSE convert(bit,0) END as ConsolidateORByCase,
			CASE WHEN ISNULL(B.CONSOLIDATEDISC,0) = 0 THEN 0 
			     WHEN B.CONSOLIDATEDISC > 10 THEN B.CONSOLIDATEDISC - 10
			     ELSE B.CONSOLIDATEDISC END as ConsolidateDISC,
			CASE WHEN B.CONSOLIDATEDISC > 10 THEN convert(bit,1) ELSE convert(bit,0) END as ConsolidateDISCByCase,
			CASE WHEN ISNULL(B.CONSOLIDATEMAR,0) = 0 THEN 0 
			     WHEN B.CONSOLIDATEMAR > 10 THEN B.CONSOLIDATEMAR - 10
			     ELSE B.CONSOLIDATEMAR END as ConsolidateMAR,
			CASE WHEN B.CONSOLIDATEMAR > 10 THEN convert(bit,1) ELSE convert(bit,0) END as ConsolidateMARByCase,	
			CASE WHEN B.DETAILSREQUIRED & 1 = 1 THEN convert(bit,1) ELSE convert(bit,0) END as DisplayDate,
			CASE WHEN B.DETAILSREQUIRED & 2 = 2 THEN convert(bit,1) ELSE convert(bit,0) END as DisplayStaff,
			CASE WHEN B.DETAILSREQUIRED & 4 = 4 THEN convert(bit,1) ELSE convert(bit,0) END as DisplayTime,
			CASE WHEN B.DETAILSREQUIRED & 8 = 8 THEN convert(bit,1) ELSE convert(bit,0) END as DisplayChargeRate,			
			CASE WHEN B.DETAILSREQUIRED & 16 = 16 THEN convert(bit,1) ELSE convert(bit,0) END as DisplayCase,
			CASE WHEN B.DETAILSREQUIRED & 32 = 32 THEN convert(bit,1) ELSE convert(bit,0) END as DisplayWipCode,
			CASE WHEN B.EXPENSEGROUPTITLE IS NOT NULL THEN convert(bit,1) ELSE convert(bit,0) END as IsExpensesGrouped,
			B.EXPENSEGROUPTITLE as ExpenseGroupName,
			ISNULL(B.SORTDATE,0) as SortDate,
			ISNULL(B.SORTCASE,0) as SortCase,
			ISNULL(B.SORTWIPCATEGORY,0) as SortWip,
			ISNULL(B.SORTCASETITLE,0) as SortCaseTitle,
			ISNULL(B.SORTCASEDEBTORREF,0) as SortCaseDebtor,
			B.FORMATPROFILEID as BillProfileKey,
			FP.FORMATDESC as BillProfileName,
			ISNULL(B.SORTTAXCODE,0) AS SortTaxCode
		From BILLFORMAT B
		left join NAME BE on (BE.NAMENO = B.ENTITYNO)
		left join NAME EMP on (B.EMPLOYEENO = EMP.NAMENO)
		left join CASETYPE CT on (B.CASETYPE = CT.CASETYPE)
		left join PROPERTYTYPE PT on (B.PROPERTYTYPE = PT.PROPERTYNAME)
		left join FORMATPROFILE FP on (B.FORMATPROFILEID = FP.FORMATID)
		"
	Exec (@sSelect + @sWhere + ") Select * from OrderedRows where RowNumber = " + @pnRowNumber)
	
	Select 	@nErrorCode =@@ERROR
	
	
	
End

Return @nErrorCode
GO

Grant execute on dbo.biw_ListBillFormatData to public
GO
