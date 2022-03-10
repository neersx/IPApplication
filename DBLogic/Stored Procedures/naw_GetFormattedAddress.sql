-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_GetFormattedAddress
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_GetFormattedAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_GetFormattedAddress.'
	Drop procedure [dbo].[naw_GetFormattedAddress]
End
Print '**** Creating Stored Procedure dbo.naw_GetFormattedAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_GetFormattedAddress
(
	@psFormattedAddress	nvarchar(254)	= null	OUTPUT,
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10)	= null,
	@psStreet		nvarchar(254)	= null,
	@psCity			nvarchar(30)	= null,
	@psStateCode		nvarchar(20)	= null,
	@psPostCode		nvarchar(10)	= null,
	@psCountryCode		nvarchar(3)	= null
)
as
-- PROCEDURE:	naw_GetFormattedAddress
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Format an address from individual components

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Jun 2006	SW	RFC3764	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @psCulture is not null
Begin
	Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
End 

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select 		@psFormattedAddress = dbo.fn_FormatAddress
							(@psStreet,
							 NULL,
							 @psCity,
							 S.STATE,
							 S.STATENAME,
							 @psPostCode,
							 C.COUNTRY,
							 C.POSTCODEFIRST,
							 C.STATEABBREVIATED,
							 dbo.fn_GetTranslation(C.POSTCODELITERAL,null,C.POSTCODELITERAL_TID,@sLookupCulture),
							 Coalesce(C.ADDRESSSTYLE, HC.ADDRESSSTYLE))
		from		(Select 1 as txt) [DUMMY]
		left join	STATE S		on (S.STATE = @psStateCode)
		left join	COUNTRY C	on (C.COUNTRYCODE = @psCountryCode)
		left join	SITECONTROL SC	on (SC.CONTROLID = 'HOMECOUNTRY')
		left join	COUNTRY HC	on (HC.COUNTRYCODE = SC.COLCHARACTER)"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psFormattedAddress	nvarchar(254)		OUTPUT,
				  @sLookupCulture	nvarchar(10),
				  @psStreet		nvarchar(254),
				  @psCity		nvarchar(30),
				  @psStateCode		nvarchar(20),
				  @psPostCode		nvarchar(10),
				  @psCountryCode	nvarchar(3)',
				  @psFormattedAddress	= @psFormattedAddress	OUTPUT,
				  @sLookupCulture	= @sLookupCulture,
				  @psStreet		= @psStreet,
				  @psCity		= @psCity,
				  @psStateCode		= @psStateCode,
				  @psPostCode		= @psPostCode,
				  @psCountryCode	= @psCountryCode


End

Return @nErrorCode
GO

Grant execute on dbo.naw_GetFormattedAddress to public
GO
