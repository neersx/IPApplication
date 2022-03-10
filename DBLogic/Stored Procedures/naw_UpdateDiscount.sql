-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateDiscount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateDiscount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateDiscount.'
	Drop procedure [dbo].[naw_UpdateDiscount]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateDiscount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateDiscount
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDiscountId                   int,            -- Mandatory
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
        @psCountryCode                  nvarchar(3)     = null,
	@pdtLogDateTimeStamp            datetime        = null
)
as
-- PROCEDURE:	naw_UpdateDiscount
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Name Discount.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Feb 2010	MS	RFC8607	1	Procedure created
-- 14 Jun 2012	KR	RFC12005	2	added CASETYPE and WIPCODE to the delete logic
-- 01 Jun 2015	MS	R35907	3	added COUNTRYCODE to DISCOUNT table and used logDateTimeStamp instead of old parameters

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "Update DISCOUNT set 
		        ACTION = @psActionType,
                        BASEDONAMOUNT = @pbIsPreMargin,
                        CASEOWNER = @pnCaseOwnerKey,
                        DISCOUNTRATE = @pdDiscountRate,
                        EMPLOYEENO = @pnStaffKey,
                        PRODUCTCODE = @pnProductCode,
                        PROPERTYTYPE = @psPropertyType,
                        WIPCATEGORY = @psWIPCategoryCode,
                        WIPTYPEID = @psWIPTypeCode,
                        WIPCODE = @psWIPCode,
                        CASETYPE = @psCaseTypeKey,
                        COUNTRYCODE = @psCountryCode
                where DISCOUNTID = @pnDiscountId
                and (LOGDATETIMESTAMP = @pdtLogDateTimeStamp or (LOGDATETIMESTAMP is null and @pdtLogDateTimeStamp is null))"

	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnDiscountId			int,
				@psActionType			nvarchar(2),
				@pbIsPreMargin			bit,
				@pnCaseOwnerKey			int,
				@pdDiscountRate			decimal(6,3),
				@pnStaffKey			int,
				@pnProductCode			int,
				@psPropertyType			nchar(1),
				@psWIPCategoryCode		nvarchar(3),
				@psWIPTypeCode			nvarchar(6),
				@psWIPCode			nvarchar(12),
				@psCaseTypeKey			nchar(2),
				@psCountryCode                  nvarchar(3),
                                @pdtLogDateTimeStamp            datetime',
				@pnDiscountId	 		= @pnDiscountId,
				@psActionType	 		= @psActionType,
				@pbIsPreMargin	 		= @pbIsPreMargin,
				@pnCaseOwnerKey			= @pnCaseOwnerKey,
				@pdDiscountRate			= @pdDiscountRate,
				@pnStaffKey			= @pnStaffKey,
				@pnProductCode			= @pnProductCode,
				@psPropertyType			= @psPropertyType,
				@psWIPCategoryCode		= @psWIPCategoryCode,
				@psWIPTypeCode			= @psWIPTypeCode,
				@psWIPCode			= @psWIPCode,
				@psCaseTypeKey			= @psCaseTypeKey,
				@psCountryCode                  = @psCountryCode,
                                @pdtLogDateTimeStamp            = @pdtLogDateTimeStamp
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateDiscount to public
GO
