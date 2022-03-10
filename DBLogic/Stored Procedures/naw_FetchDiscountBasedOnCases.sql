-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchDiscountBasedOnCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchDiscountBasedOnCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchDiscountBasedOnCases.'
	Drop procedure [dbo].[naw_FetchDiscountBasedOnCases]
End
Print '**** Creating Stored Procedure dbo.naw_FetchDiscountBasedOnCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_FetchDiscountBasedOnCases
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture		        nvarchar(10) 	= null,		
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey		        int,		-- Mandatory
	@psPropertyType			nchar(1)	= null
)
as
-- PROCEDURE:	naw_FetchDiscountBasedOnCases
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Disocunt based on Number of Filings

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Jul 2010	MS	RFC7275	1	Procedure created
-- 11 Apr 2013	DV	R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select	
	Cast(@pnNameKey as nvarchar(11)) + '^' + D.PROPERTYTYPE + Cast(D.SEQUENCE as nvarchar(3)) 
			as 'RowKey',
	D.NAMENO	as 'NameKey',		
	CAST(Round(D.DISCOUNTRATE, @nLocalDecimalPlaces) as decimal(6, "+CAST(@nLocalDecimalPlaces as varchar(2))+"))  as 'DiscountRate',
	D.FROMCASES	as 'FromCases',
	D.TOCASES	as 'ToCases',
	D.PROPERTYTYPE	as 'PropertyType',
	D.SEQUENCE	as 'Sequence',
	D.LOGDATETIMESTAMP as 'LastModifiedDate'
	from DISCOUNTBASEDONNOOFCASES D
	where D.NAMENO = @pnNameKey" + CHAR(10) +
	CASE WHEN @psPropertyType is not null 
	THEN "and D.PROPERTYTYPE = @psPropertyType"
	END
			

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnNameKey		int,
			@psPropertyType		nchar(1),
			@nLocalDecimalPlaces	int',
			@pnNameKey		= @pnNameKey,
			@psPropertyType		= @psPropertyType,
			@nLocalDecimalPlaces	= @nLocalDecimalPlaces
END

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchDiscountBasedOnCases to public
GO
