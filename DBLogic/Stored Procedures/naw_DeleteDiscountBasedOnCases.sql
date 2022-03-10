-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteDiscountBasedOnCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteDiscountBasedOnCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteDiscountBasedOnCases.'
	Drop procedure [dbo].[naw_DeleteDiscountBasedOnCases]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteDiscountBasedOnCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_DeleteDiscountBasedOnCases
(	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@psPropertyType			nchar(1),	-- Mandatory
	@pnSequence			tinyint,	-- Mandatory	
	@pdLastModifiedDate             datetime        = null   
)
as
-- PROCEDURE:	naw_DeleteDiscountBasedOnCases
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Discount Rates based on number of Filings

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Jul 2010	MS	RFC7275	1	Procedure created
-- 06 Feb 2013  MS      R100593 2       Set nocount off for code

SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
			
If @nErrorCode = 0
Begin		
	Set  @sSQLString = 
	       "Delete FROM DISCOUNTBASEDONNOOFCASES		
		WHERE NAMENO = @pnNameKey
		AND PROPERTYTYPE = @psPropertyType
		AND SEQUENCE = @pnSequence
		AND CAST(LOGDATETIMESTAMP as nvarchar(20)) = CAST(@pdLastModifiedDate as nvarchar(20))"
	       
	       exec @nErrorCode = sp_executesql @sSQLString,
	               N'@psPropertyType	nchar(1),
	                 @pnSequence		tinyint,	                 
	                 @pnNameKey		int,
	                 @pdLastModifiedDate	datetime',
	                 @psPropertyType	= @psPropertyType,
	                 @pnSequence		= @pnSequence,	                
	                 @pnNameKey		= @pnNameKey,
	                 @pdLastModifiedDate	= @pdLastModifiedDate	                  
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteDiscountBasedOnCases to public
GO
