-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertDiscount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertDiscount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertDiscount.'
	Drop procedure [dbo].[naw_InsertDiscount]
End
Print '**** Creating Stored Procedure dbo.naw_InsertDiscount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_InsertDiscount
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@psActionType			nvarchar(2)	= null,		
	@pbIsPreMargin			bit		= 0,
	@pnCaseOwnerKey			int		= null,
	@pdDiscountRate			decimal(6,3),	-- Mandatory
	@pnStaffKey			int		= null,
	@pnProductCode			int		= null,
	@psPropertyType			nchar(1)	= null,
	@psWIPCategoryCode		nvarchar(3)	= null,
	@psWIPTypeCode			nvarchar(6)	= null,	
	@psWIPCode			nvarchar(12)	= null,
	@psCaseTypeKey			nchar(2)	= null,
        @psCountryCode                  nvarchar(3)     = null

)
as
-- PROCEDURE:	naw_InsertDiscount
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Name Discount.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Feb 2010	MS	RFC8607	1	Procedure created
-- 15 Jun 2012	KR	R12005	2	added CASETYPE and WIPCODE to DISCOUNT table.
-- 01 Jun 2015	MS	R35907	3	added COUNTRYCODE to DISCOUNT table.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nSequence		smallint

-- Initialise variables
Set @nErrorCode = 0
Set @nSequence	= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @nSequence = MAX(SEQUENCE) + 1 
			from DISCOUNT
			where NAMENO = @pnNameKey"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@nSequence	int		output,
				@pnNameKey	int',
				@nSequence	= @nSequence	output,
				@pnNameKey	= @pnNameKey
End

If @nErrorCode = 0
Begin
		Set @sSQLString = "Insert into DISCOUNT (
					ACTION, 
					BASEDONAMOUNT,
					CASEOWNER, 
					DISCOUNTRATE, 
					EMPLOYEENO,
					NAMENO, 
					PRODUCTCODE,
					PROPERTYTYPE, 
					SEQUENCE, 
					WIPCATEGORY,
					WIPTYPEID,
					CASETYPE,
					WIPCODE,
                                        COUNTRYCODE) 
				   values (
					@psActionType,
					@pbIsPreMargin,
					@pnCaseOwnerKey,
					@pdDiscountRate,
					@pnStaffKey,					
					@pnNameKey,
					@pnProductCode,
					@psPropertyType,
					ISNULL(@nSequence,0),
					@psWIPCategoryCode,
					@psWIPTypeCode,
					@psCaseTypeKey,
					@psWIPCode,
                                        @psCountryCode
					)" 
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey		int,
				@psActionType		nvarchar(2),
				@pbIsPreMargin		bit,
				@pnCaseOwnerKey		int,
				@pdDiscountRate		decimal(6,3),
				@pnStaffKey		int,
				@pnProductCode		int,
				@psPropertyType		nchar(1),
				@nSequence		smallint,
				@psWIPCategoryCode	nvarchar(3),
				@psWIPTypeCode		nvarchar(6),
				@psCaseTypeKey		nchar(2),
				@psWIPCode		nvarchar(12),
                                @psCountryCode          nvarchar(3)',
				@pnNameKey	 	= @pnNameKey,
				@psActionType	 	= @psActionType,
				@pbIsPreMargin	 	= @pbIsPreMargin,
				@pnCaseOwnerKey		= @pnCaseOwnerKey,
				@pdDiscountRate		= @pdDiscountRate,
				@pnStaffKey		= @pnStaffKey,
				@pnProductCode		= @pnProductCode,
				@psPropertyType		= @psPropertyType,
				@nSequence		= @nSequence,
				@psWIPCategoryCode	= @psWIPCategoryCode,
				@psWIPTypeCode		= @psWIPTypeCode,
				@psCaseTypeKey		= @psCaseTypeKey,
				@psWIPCode		= @psWIPCode,
                                @psCountryCode          = @psCountryCode
End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertDiscount to public
GO
