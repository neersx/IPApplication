-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xl_ListAddressSource
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xl_ListAddressSource]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xl_ListAddressSource.'
	Drop procedure [dbo].[xl_ListAddressSource]
End
Print '**** Creating Stored Procedure dbo.xl_ListAddressSource...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.xl_ListAddressSource
(
	@pnUserIdentityId	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 1,
	@pnAddressKey		int,		--Mandatory
	@pnAddressStyle		int		= null		-- The address style to use when formatting the address.  If not provided, it will be defaulted appropriately.	
)
as
-- PROCEDURE:	xl_ListAddressSource
-- VERSION:	3
-- DESCRIPTION:	Returns the source address to be translated.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Sep 2004	TM	RFC1806	1	Procedure created
-- 15 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 17 Nov 2009	MF	SQA18134 3	Display the Country even if it is the home country.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @pnAddressKey 	as AddressKey ,		 
		dbo.fn_FormatAddress(A.STREET1, 
		                     A.STREET2,
		                     A.CITY,
		                     A.STATE,
		                     S.STATENAME,
		                     A.POSTCODE,
		                     C.POSTALNAME,
		                     C.POSTCODEFIRST,
		                     C.STATEABBREVIATED,
		                     C.POSTCODELITERAL,
		                     isnull(@pnAddressStyle, C.ADDRESSSTYLE)) 
					as FormattedAddress,
		C.STATELITERAL		as StateLiteral,
		C.POSTCODELITERAL	as PostcodeLiteral		
		from ADDRESS A 		
		left join COUNTRY C		on (C.COUNTRYCODE = A.COUNTRYCODE)
		left Join STATE S		on (S.COUNTRYCODE = A.COUNTRYCODE
						and S.STATE = A.STATE)
		where A.ADDRESSCODE = @pnAddressKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnAddressKey		int,
				  @pnAddressStyle	int',
				  @pnAddressKey 	= @pnAddressKey,
				  @pnAddressStyle	= @pnAddressStyle
	
End
	

Return @nErrorCode
GO

Grant execute on dbo.xl_ListAddressSource to public
GO
