-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_GetDiscountRate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_GetDiscountRate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_GetDiscountRate.'
	drop procedure dbo.pt_GetDiscountRate
end
print '**** Creating procedure dbo.pt_GetDiscountRate...'
print ''
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc dbo.pt_GetDiscountRate 
	@pnBillToNo		int, 
	@psWIPType		varchar(6)	=NULL,
	@psWIPCategory		varchar(2)	=NULL,
	@psPropertyType		varchar(1)	=NULL, 
	@psAction		varchar(2)	=NULL,
	@pnEmployeeNo		int		=NULL,
	@pnProductCode		int		=NULL,
	@prnDiscountRate 	decimal(6,3) output,
	@prnBaseOnAmount	decimal(1,0) output,
	@pnOwner		int		=NULL,
	@psWIPCode		nvarchar(12)	=NULL,
	@psCaseType		nchar(2)	=NULL,
        @psCountryCode          nvarchar(3)     =NULL
as

-- PROCEDURE :	pt_GetDiscountRate
-- VERSION :	8
-- DESCRIPTION:	Determines the rate of discount to be applied for a given
--		combination of characteristics
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  	Number	Version Change
-- ------------ ---- 	------	------- ------------------------------------------- 
-- 21 Feb 2002	MF	SQA6948		Include WIPCATEGORY as part of the selection criteria for determining
--					the discount rate.
-- 21 Feb 2002	MF	SQA7172		Return a flag that indicates if the discount is to be applied to the amount
--					before any margins have been added to the calculated amount.
-- 21 Feb 2002	MF	SQA7217 	Extend Discounts to include WIP Type and Employee
-- 28 Feb 2005	DW	11071		Added @pnProductCode as a new parameter
-- 20 Jun 2005	JEK		3	RFC2629	Implement sp_executesql for performance.
-- 08 Mar 2006	MF	12379	4	Minor changes to comments
-- 08 Jun 2006	DW	12351	5	Added new input parameter @pnOwner.
-- 07 May 2007	CR	14322	6	Extended logic to also refer to Discounts stored against Margin Profiles.
-- 19 Jun 2012	KR	12005	7	Add WIPCODE and CASETYPE to the Discount calculation
-- 01 Jun 2015	MS	R35907	8	Added COUNTRYCODE to the Discount calculation

set nocount on

declare	@ErrorCode	int
declare	@sRateAndFlag	char(10)
declare @sSQLString	nvarchar(4000)
declare @nMarginProfileNo int

Select	@ErrorCode=0

-- for the current Name and WIP item select the most appropriate Margin Profile recorded for that Name
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	@nMarginProfileNo = right(
		MAX	(
			CASE WHEN WIPTYPEID is NULL THEN '0' ELSE '1' END+
			cast(MARGINPROFILENO as char(8))  
			)	
		, 8) -- Last 8 is the margin profile number (implicitly cast)
	from NAMEMARGINPROFILE
	Where NAMENO=@pnBillToNo
	and  CATEGORYCODE=@psWIPCategory
	and (WIPTYPEID=@psWIPType OR WIPTYPEID is null)"

	exec @ErrorCode=sp_executesql @sSQLString,
		N'@nMarginProfileNo	int			OUTPUT,
		  @pnBillToNo		int,
		  @psWIPCategory 	nvarchar(3),
		  @psWIPType		nvarchar(6)',
		  @nMarginProfileNo	= @nMarginProfileNo	OUTPUT,
		  @pnBillToNo		= @pnBillToNo,
		  @psWIPCategory 	= @psWIPCategory,
		  @psWIPType		= @psWIPType
End

If @ErrorCode=0
Begin
	Set @sSQLString = "
	SELECT	@sRateAndFlag=
		Substring(
			max (	CASE WHEN NAMENO		is NULL THEN '0' ELSE '1' END+
				CASE WHEN MARGINPROFILENO	is NULL THEN '0' ELSE '1' END+
				CASE WHEN WIPCODE		is NULL THEN '0' ELSE '1' END+
				CASE WHEN WIPTYPEID     	is NULL THEN '0' ELSE '1' END+
				CASE WHEN WIPCATEGORY   	is NULL THEN '0' ELSE '1' END+
				CASE WHEN PRODUCTCODE   	is NULL THEN '0' ELSE '1' END+
                                CASE WHEN COUNTRYCODE           is NULL THEN '0' ELSE '1' END+
				CASE WHEN CASETYPE		is NULL THEN '0' ELSE '1' END+
	 			CASE WHEN PROPERTYTYPE		is NULL THEN '0' ELSE '1' END+
				CASE WHEN ACTION		is NULL THEN '0' ELSE '1' END+
				CASE WHEN CASEOWNER		is NULL THEN '0' ELSE '1' END+
				CASE WHEN EMPLOYEENO		is NULL THEN '0' ELSE '1' END+
				convert(char(9),isnull(DISCOUNTRATE ,0))+
				convert(char(1),isnull(BASEDONAMOUNT,0))), 13,10)
	FROM  DISCOUNT  
	WHERE (NAMENO 	   	= @pnBillToNo     	OR NAMENO	     	IS NULL)
	AND ( MARGINPROFILENO	= @nMarginProfileNo	OR MARGINPROFILENO	IS NULL)
	AND ( WIPCODE		= @psWIPCode		OR WIPCODE		IS NULL)
	AND ( WIPTYPEID    	= @psWIPType      	OR WIPTYPEID    	IS NULL)
	AND ( WIPCATEGORY  	= @psWIPCategory  	OR WIPCATEGORY  	IS NULL)
        AND ( COUNTRYCODE       = @psCountryCode        OR COUNTRYCODE          IS NULL)
	AND ( CASETYPE 		= @psCaseType		OR CASETYPE		IS NULL)
	AND ( PROPERTYTYPE 	= @psPropertyType	OR PROPERTYTYPE		IS NULL)
	AND ( ACTION	   	= @psAction	     	OR ACTION	     	IS NULL)
	AND ( CASEOWNER	   	= @pnOwner	     	OR CASEOWNER    	IS NULL)
	AND ( EMPLOYEENO   	= @pnEmployeeNo   	OR EMPLOYEENO   	IS NULL)
	AND ( PRODUCTCODE   	= @pnProductCode  	OR PRODUCTCODE  	IS NULL)"

	exec @ErrorCode=sp_executesql @sSQLString,
		N'@sRateAndFlag		char(10)	OUTPUT,
		  @pnBillToNo		int, 
		  @nMarginProfileNo	int,
		  @psWIPType		varchar(6),
		  @psWIPCategory	varchar(2),
		  @psPropertyType	varchar(1), 
		  @psAction		varchar(2),
		  @pnEmployeeNo		int,
		  @pnProductCode	int,
		  @pnOwner		int,
		  @psWIPCode		nvarchar(12),
		  @psCaseType		nchar(2),
                  @psCountryCode        nvarchar(3)',
		  @sRateAndFlag		= @sRateAndFlag	OUTPUT,
		  @pnBillToNo		= @pnBillToNo,
		  @nMarginProfileNo	= @nMarginProfileNo,
		  @psWIPType		= @psWIPType,
		  @psWIPCategory	= @psWIPCategory,
		  @psPropertyType	= @psPropertyType,
		  @psAction		= @psAction,
		  @pnEmployeeNo		= @pnEmployeeNo,
		  @pnProductCode	= @pnProductCode,
		  @pnOwner		= @pnOwner,
		  @psWIPCode		= @psWIPCode,
		  @psCaseType		= @psCaseType,
                  @psCountryCode        = @psCountryCode

End

If @ErrorCode=0
begin
	Set @prnDiscountRate=convert(decimal(6,3),isnull(substring(@sRateAndFlag,1,9),'0'))
	Set @prnBaseOnAmount=convert(decimal(1,0),isnull(substring(@sRateAndFlag,10,1),'0'))
end

Return @ErrorCode
go

grant execute on dbo.pt_GetDiscountRate to public
go
