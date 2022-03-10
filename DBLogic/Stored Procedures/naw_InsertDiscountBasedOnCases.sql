-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertDiscountBasedOnCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertDiscountBasedOnCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertDiscountBasedOnCases.'
	Drop procedure [dbo].[naw_InsertDiscountBasedOnCases]
End
Print '**** Creating Stored Procedure dbo.naw_InsertDiscountBasedOnCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertDiscountBasedOnCases
(	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@psPropertyType			nchar(1),	-- Mandatory
	@pnSequence			int,
	@pnFromCases			int		= null,
	@pnToCases			int		= null,	
	@pnDiscountRate                 decimal(6,3)    = null  
)
as
-- PROCEDURE:	naw_InsertDiscountBasedOnCases
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Discount Rates based on number of Filings

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Jul 2010	MS	RFC7275	1	Procedure created
-- 06 Feb 2013  MS      R100593 2       Set nocount off and remove select list for LOGDATETIMESTAMP and SEQUENCE
-- 28 May 2014	MF	R34860	3	Change parameters from TINYINT to INT to accommodate value > 255.


SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nSequence		tinyint

-- Initialise variables
Set @nErrorCode = 0
			
If @nErrorCode = 0
Begin
	If @nSequence is null
	Begin
		Set @nSequence = 1
	End
	
	Set  @sSQLString = 
	       "Insert into DISCOUNTBASEDONNOOFCASES 
	       (
	               NAMENO, 
	               PROPERTYTYPE,
	               SEQUENCE, 
	               FROMCASES, 
	               TOCASES, 
	               DISCOUNTRATE
	       )
	       values
	       (
	               @pnNameKey, 
	               @psPropertyType, 
	               @pnSequence, 
	               @pnFromCases, 
	               @pnToCases, 
	               @pnDiscountRate
	        )"
	       
	       exec @nErrorCode = sp_executesql @sSQLString,
	               N'@psPropertyType	nchar(1),
	                 @pnSequence		int,
	                 @pnFromCases		int,
	                 @pnToCases		int,
	                 @pnDiscountRate	decimal(6,3),
	                 @pnNameKey		int',
	                 @psPropertyType	= @psPropertyType,
	                 @pnSequence		= @pnSequence,
	                 @pnFromCases		= @pnFromCases, 
	                 @pnToCases		= @pnToCases,
	                 @pnDiscountRate	= @pnDiscountRate, 
	                 @pnNameKey		= @pnNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertDiscountBasedOnCases to public
GO
