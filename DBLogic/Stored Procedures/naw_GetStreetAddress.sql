-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_GetStreetAddress
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_GetStreetAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_GetStreetAddress.'
	Drop procedure [dbo].[naw_GetStreetAddress]
End
Print '**** Creating Stored Procedure dbo.naw_GetStreetAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_GetStreetAddress
(
	@pnUserIdentityId	int,			-- Mandatory
	@pnNameKey		int,			-- Mandatory
	@pnAddressKey		int			OUTPUT,
	@psFormattedAddress	nvarchar(4000)		OUTPUT
)
as
-- PROCEDURE:	naw_GetStreetAddress
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	A new stored procedure to return the street address 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 May 2006	SW	RFC3840	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = '
		Select		@pnAddressKey = N.STREETADDRESS,
				@psFormattedAddress = dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)
		from		[NAME] N
		left join	ADDRESS A	on (A.ADDRESSCODE = N.STREETADDRESS)
		left join 	COUNTRY CT	on (CT.COUNTRYCODE = A.COUNTRYCODE)
		left join 	STATE S		on (S.COUNTRYCODE = A.COUNTRYCODE
						and S.STATE = A.STATE)
		where		N.NAMENO = @pnNameKey'

	Exec @nErrorCode = sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@pnAddressKey		int			OUTPUT,
			@psFormattedAddress	nvarchar(4000)		OUTPUT',
			@pnNameKey		= @pnNameKey,
			@pnAddressKey	 	= @pnAddressKey		OUTPUT,
			@psFormattedAddress	= @psFormattedAddress	OUTPUT
End

Return @nErrorCode
GO

Grant execute on dbo.naw_GetStreetAddress to public
GO
