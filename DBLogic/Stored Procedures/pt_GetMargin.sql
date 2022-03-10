-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_GetMargin
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_GetMargin]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_GetMargin.'
	drop procedure dbo.pt_GetMargin
end
print '**** Creating procedure dbo.pt_GetMargin...'
print ''
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create procedure dbo.pt_GetMargin
	@prnMarginPercentage 	decimal(6,3)	output,
	@prnMarginAmount	decimal(10,2)	output, 	
	@prsMarginCurrency 	nvarchar(3)	output,
	@psWIPCategory 		nvarchar(3),
	@pnEntityNo		int		=NULL,
	@psWIPType		nvarchar(6)	=NULL,
	@pnCaseId		int		=NULL,
	@pnInstructor		int		=NULL,
	@pnDebtor		int		=NULL,
	@psInstructorCountry	nvarchar(3)	=NULL,
	@psDebtorCountry	nvarchar(3)	=NULL,
	@psPropertyType		nchar(1)	=NULL,
	@psAction		nvarchar(2)	=NULL,
	@pdtEffectiveDate	datetime	=NULL,
	@psDebtorCurrency	nvarchar(3)	=NULL,
	@pnAgent		int		=NULL,
	@psCountryCode		nvarchar(3)	=NULL,	-- SQA12361 User entered Country
	@psCaseType		nchar(1)	=NULL,	-- SQA13472 User entered Case Type
	@psCaseCategory		nvarchar(2)	=NULL,	-- SQA13472 User entered Case Category
	@psSubType		nvarchar(2)	=NULL,	-- SQA13472 User entered SubType
	@prnMarginNo		int		=NULL output,	-- SQA16917
	@prnMarginCap	decimal(10,2)=NULL	output,		-- SQA18298	
	@psWIPCode			nvarchar(6)	= NULL			-- SQA11749
as

-- PROCEDURE :	pt_GetMargin
-- VERSION :	14
-- DESCRIPTION:	
-- CALLED BY :	FEESCALC, FEESCALCEXTENDED
-- COPYRIGHT :	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Version	Change	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Feb 2002	MF	1	SQA6948	Include WIPCATEGORY as part of the selection criteria for determining
--					the discount rate.
-- 21 Feb 2002	MF	2	SQA7172	Return a flag that indicates if the discount is to be applied to the amount
--					before any margins have been added to the calculated amount.
-- 12 May 2004	DW	3	SQA9917	Extended the stored procedure to return fixed margins via two additional parameters. 
-- 14 May 2004	JB	4	SQA9917	Added the output parameters @prnMarginAmount and @prsMarginCurrency and simplified 
--					the code to get the margin no (key) in 1st select then data in 2nd select
-- 20 Jun 2005	JEK	5	RFC2629	Implement sp_executesql for performance.
-- 26 Oct 2005	DW	6	SQA9931	Extend best fit to include debtor currency.
-- 12 Dec 2005	MF	7	SQA11941 Additional best fit parameters to determine the Margin using Agent, Margin Type
--					and the Country of the Case.  The Margin Type is first determined by getting
--					the Margin Profile for the Name and WIP Category/Type then using the Profile
--					determining the Margin Type for the Country and Property Type of the Case.
-- 06 Jan 2006	MF	8	SQA11941 Rework. Error in testing
-- 06 Jul 2006	MF	9	SQA12361 Additional parameters to allow calculations to be performed when a CASEID
--					 is not passed as a parameter but case characteristics are.
-- 25 Sep 2006	MF	10	SQA13472 Add Case Type, Category and Sub Type as selection characteristics for
--					 determining the Margin.
-- 07 May 2007	CR	11	SQA14311 Added Case Type, Category and Sub Type as selection characteristics for
--					 determining the Margin Type. Update parameter @sAction to be @psAction.
-- 01 June 2007	CR	12	SQA14311 Changed the order of criteria
-- 03 Oct  2008 Dw	13	SQA16917 Added new parameter to return the margin identifier	
-- 24 Feb  2010 Dw	14	SQA18298 Added new parameter to return the margin cap
-- 06 Jul  2010 Dw	15	SQA11749 Added new parameter @psWIPCode	
	

Set nocount on
Set concat_null_yields_null off

Declare	@nErrorCode 		int,
	@nMarginProfileNo	int,
	@nMarginTypeNo		int,
	@nMarginNo 		int,
	@nRecordCnt 		int,
	@sSQLString		nvarchar(4000)

Set @nErrorCode=0

-- Determine the Margin Profile to use for this Name (Debtor or Instructor)
-- depending upon the WIP Category and WIP Type.
If @nErrorCode=0
and isnull(@pnDebtor, @pnInstructor) is not null
Begin
	Set @sSQLString="
	Select	@nMarginProfileNo = right(
		MAX	(
			CASE WHEN WIPTYPEID is NULL THEN '0' ELSE '1' END+
			cast(MARGINPROFILENO as char(8))  
			)	
		, 8) -- Last 8 is the margin profile number (implicitly cast)
	from NAMEMARGINPROFILE
	Where NAMENO=isnull(@pnDebtor, @pnInstructor)
	and  CATEGORYCODE=@psWIPCategory
	and (WIPTYPEID=@psWIPType OR WIPTYPEID is null)"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@nMarginProfileNo	int			OUTPUT,
		  @psWIPCategory 	nvarchar(3),
		  @psWIPType		nvarchar(6),
		  @pnInstructor		int,
		  @pnDebtor		int',
		  @nMarginProfileNo	= @nMarginProfileNo	OUTPUT,
		  @psWIPCategory 	= @psWIPCategory,
		  @psWIPType		= @psWIPType,
		  @pnInstructor		= @pnInstructor,
		  @pnDebtor		= @pnDebtor
End

-- If a Margin Profile has been found then determine if a Margin Type is known
-- for the Property Type and Country Code of the Case.
If  @nErrorCode=0
and @nMarginProfileNo is not null
and(@pnCaseId is not null or @psCountryCode is not null or @psPropertyType is not null)
Begin
	Set @sSQLString="
	Select	@nMarginTypeNo = right(
		MAX	(
			CASE WHEN M.COUNTRYCODE  	is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.CASETYPE		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.PROPERTYTYPE	is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.ACTION		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.CASECATEGORY	is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.SUBTYPE		is NULL THEN '0' ELSE '1' END+
			cast(M.MARGINTYPENO as char(8))  
			)	
		, 8) -- Last 8 is the margin profile number (implicitly cast)
	from MARGINPROFILERULE M
	left join CASES C on (C.CASEID=@pnCaseId)
	Where M.MARGINPROFILENO=@nMarginProfileNo
	AND (M.COUNTRYCODE	=isnull(C.COUNTRYCODE, @psCountryCode)  OR M.COUNTRYCODE	IS NULL)
	AND (M.CASETYPE		= isnull(C.CASETYPE,@psCaseType) 	OR M.CASETYPE 		IS NULL)
	AND (M.PROPERTYTYPE 	= @psPropertyType			OR M.PROPERTYTYPE	IS NULL)
	AND (M.ACTION 		= @psAction		 		OR M.ACTION            	IS NULL)
	AND (M.CASECATEGORY	= isnull(C.CASECATEGORY,@psCaseCategory)
									OR M.CASECATEGORY   	IS NULL)
	AND (M.SUBTYPE		= isnull(C.SUBTYPE,@psSubType) 		OR M.SUBTYPE	       	IS NULL)"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nMarginTypeNo	int		OUTPUT,
				  @pnCaseId		int,
				  @nMarginProfileNo	int,
				  @psCountryCode	nvarchar(3),
				  @psCaseType		nchar(1),				 
				  @psPropertyType	nchar(1), 
				  @psAction		nvarchar(2),
				  @psCaseCategory	nvarchar(2),
				  @psSubType		nvarchar(2)',
				  @nMarginTypeNo	= @nMarginTypeNo	OUTPUT,
				  @pnCaseId		= @pnCaseId,
				  @nMarginProfileNo	= @nMarginProfileNo,
				  @psCountryCode	= @psCountryCode,
				  @psCaseType		= @psCaseType,
				  @psPropertyType	= @psPropertyType,
				  @psAction		= @psAction,
				  @psCaseCategory	= @psCaseCategory,
				  @psSubType		= @psSubType
End

If @nErrorCode=0
Begin
	Set @sSQLString = "
	Select	@nMarginNo =  right(
		MAX	(
			CASE WHEN M.ENTITYNO   		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.WIPCODE   		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.WIPTYPE		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.CASEID		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.AGENT		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.MARGINTYPENO	is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.INSTRUCTOR		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.DEBTOR		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.INSTRUCTORCOUNTRY 	is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.DEBTORCOUNTRY	is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.DEBTORCURRENCY    	is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.COUNTRYCODE		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.CASETYPE		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.PROPERTYTYPE	is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.ACTION		is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.CASECATEGORY	is NULL THEN '0' ELSE '1' END+
			CASE WHEN M.SUBTYPE		is NULL THEN '0' ELSE '1' END+
			isnull(convert(char(8), M.EFFECTIVEDATE,112),'00000000') + 
			cast(M.MARGINNO as char(8))  
			)	
		, 8) -- Last 8 is the margin number (implicitly cast)
	from MARGIN M
	left join CASES C	on (C.CASEID=@pnCaseId)
	left join CASENAME CN	on ( CN.CASEID=C.CASEID
				and  CN.NAMETYPE='A'
				and (CN.EXPIRYDATE   is null or CN.EXPIRYDATE  >getdate())
				and (CN.COMMENCEDATE is null or CN.COMMENCEDATE<getdate()) )
	where M.WIPCATEGORY	= @psWIPCategory
	AND (M.ENTITYNO 	= @pnEntityNo		OR M.ENTITYNO          IS NULL)
	AND (M.WIPCODE		= @psWIPCode		OR M.WIPCODE           IS NULL) 
	AND (M.WIPTYPE		= @psWIPType		OR M.WIPTYPE           IS NULL) 
	AND (M.CASEID		= @pnCaseId		OR M.CASEID            IS NULL) 
	AND (M.AGENT		= isnull(@pnAgent,CN.NAMENO)
							OR M.AGENT	       IS NULL)
	AND (M.MARGINTYPENO	= @nMarginTypeNo	OR M.MARGINTYPENO      IS NULL)
	AND (M.INSTRUCTOR 	= @pnInstructor		OR M.INSTRUCTOR        IS NULL) 
	AND (M.DEBTOR		= @pnDebtor		OR M.DEBTOR            IS NULL) 
	AND (M.INSTRUCTORCOUNTRY= @psInstructorCountry	OR M.INSTRUCTORCOUNTRY IS NULL) 
	AND (M.DEBTORCOUNTRY 	= @psDebtorCountry	OR M.DEBTORCOUNTRY     IS NULL) 
	AND (M.DEBTORCURRENCY 	= @psDebtorCurrency	OR M.DEBTORCURRENCY    IS NULL) 
	AND (M.COUNTRYCODE	= isnull(C.COUNTRYCODE,@psCountryCode) 
							OR M.COUNTRYCODE       IS NULL)
	AND (M.CASETYPE		= isnull(C.CASETYPE,@psCaseType) 
							OR M.CASETYPE	       IS NULL)
	AND (M.PROPERTYTYPE 	= @psPropertyType	OR M.PROPERTYTYPE      IS NULL)
	AND (M.ACTION 		= @psAction		OR M.ACTION            IS NULL) 
	AND (M.CASECATEGORY	= isnull(C.CASECATEGORY,@psCaseCategory) 
							OR M.CASECATEGORY      IS NULL)
	AND (M.SUBTYPE		= isnull(C.SUBTYPE,@psSubType) 
							OR M.SUBTYPE	       IS NULL)
	AND (M.EFFECTIVEDATE	<= isnull(@pdtEffectiveDate,getdate()) or M.EFFECTIVEDATE IS NULL)"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@nMarginNo		int		OUTPUT,
		  @psWIPCategory 	nvarchar(3),
		  @pnEntityNo		int,
		  @psWIPCode		nvarchar(6),
		  @psWIPType		nvarchar(6),
		  @pnCaseId		int,
		  @pnAgent		int,
		  @nMarginTypeNo	int,
		  @pnInstructor		int,
		  @pnDebtor		int,
		  @psInstructorCountry	nvarchar(3),
		  @psDebtorCountry	nvarchar(3),
		  @psCountryCode	nvarchar(3),
		  @pdtEffectiveDate	datetime,
		  @psDebtorCurrency	nvarchar(3),
		  @psCaseType		nchar(1),
		  @psPropertyType	nchar(1),
		  @psAction		nvarchar(2),
		  @psCaseCategory	nvarchar(2),
		  @psSubType		nvarchar(2)',
		  @nMarginNo		= @nMarginNo	OUTPUT,
		  @psWIPCategory 	= @psWIPCategory,
		  @pnEntityNo		= @pnEntityNo,
		  @psWIPCode		= @psWIPCode,
		  @psWIPType		= @psWIPType,
		  @pnCaseId		= @pnCaseId,
		  @pnAgent		= @pnAgent,
		  @nMarginTypeNo	= @nMarginTypeNo,
		  @pnInstructor		= @pnInstructor,
		  @pnDebtor		= @pnDebtor,
		  @psInstructorCountry	= @psInstructorCountry,
		  @psDebtorCountry	= @psDebtorCountry,
		  @psCountryCode	= @psCountryCode,
		  @pdtEffectiveDate	= @pdtEffectiveDate,
		  @psDebtorCurrency	= @psDebtorCurrency,
		  @psCaseType		= @psCaseType,
		  @psPropertyType	= @psPropertyType,
		  @psAction		= @psAction,
		  @psCaseCategory	= @psCaseCategory,
		  @psSubType		= @psSubType

	-- Now we have worked out which margin is the best-fit we can get the details
	If @nErrorCode = 0
	Begin
		If @nMarginNo is null -- Nothing was found
		Begin
			Set @prnMarginPercentage = null
			Set @prnMarginAmount = null
			Set @prsMarginCurrency = null
		End
		Else
		Begin
			Set @sSQLString = "
			Select 	@prnMarginPercentage=MARGINPERCENTAGE,
				@prnMarginAmount = MARGINAMOUNT,
				@prsMarginCurrency = MARGINCURRENCY,
				@prnMarginCap = MARGINCAP
			from 	MARGIN
			where	MARGINNO = @nMarginNo"

			exec @nErrorCode=sp_executesql @sSQLString,
				N'@prnMarginPercentage 	decimal(6,3)		OUTPUT,
				  @prnMarginAmount	decimal(10,2)		OUTPUT, 	
				  @prsMarginCurrency 	nvarchar(3)		OUTPUT,
				  @prnMarginCap	decimal(10,2)		OUTPUT,
				  @nMarginNo		int',
				  @prnMarginPercentage 	= @prnMarginPercentage	OUTPUT,
				  @prnMarginAmount	= @prnMarginAmount	OUTPUT, 	
				  @prsMarginCurrency 	= @prsMarginCurrency	OUTPUT,
				  @prnMarginCap	= @prnMarginCap	OUTPUT,
				  @nMarginNo		= @nMarginNo

		End
		-- 16917 return the margin identifier
		Set @prnMarginNo = @nMarginNo
	End
End

Return @nErrorCode
go

grant execute on dbo.pt_GetMargin to public
go
