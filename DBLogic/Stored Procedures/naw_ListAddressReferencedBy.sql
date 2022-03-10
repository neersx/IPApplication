-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListAddressReferencedBy
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListAddressReferencedBy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListAddressReferencedBy.'
	Drop procedure [dbo].[naw_ListAddressReferencedBy]
End
Print '**** Creating Stored Procedure dbo.naw_ListAddressReferencedBy...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListAddressReferencedBy
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnAddresskey		int			-- Mandatory
)
as
-- PROCEDURE:	naw_ListAddressReferencedBy
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Dec 2007	PG	RFC3497	1	Procedure created
-- 26 Jul 2010	SF	RFC9563	2	Ensure IsOwner flag is returned as either a 0 or a 1.
-- 24 Oct 2011	ASH	R11460  3	Cast integer columns as nvarchar(11) data type.
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

--Get address

If @nErrorCode = 0
Begin
	Set @sSQLString = "SELECT ADDRESSCODE as AddressKey,
			   dbo.fn_FormatAddress(A.STREET1, null, A.CITY, A.STATE, S.STATENAME,
			   A.POSTCODE, C.POSTALNAME, C.POSTCODEFIRST, C.STATEABBREVIATED,
			   C.POSTCODELITERAL, C.ADDRESSSTYLE) as FormattedAddress
			   from ADDRESS A
			   left join	STATE S on (S.STATE = A.STATE and S.COUNTRYCODE = A.COUNTRYCODE)
			   left join	COUNTRY C on (C.COUNTRYCODE = A.COUNTRYCODE)
			   where A.ADDRESSCODE=@pnAddresskey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnAddresskey	int',
			@pnAddresskey	 = @pnAddresskey

End

--Used by Cases
If @nErrorCode = 0
Begin
	Set @sSQLString =	"SELECT distinct @pnAddresskey as AddressKey,
				C.IRN AS IRN,"
				+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
					 + " AS NameType,
				 dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) AS NAME,
				cast(C.CASEID as nvarchar(11))+'^'+ CN.NAMETYPE +'^'+ cast (N.NAMENO as nvarchar(11)) as RowKey
				FROM CASES C
				JOIN CASENAME CN ON (C.CASEID=CN.CASEID)
				JOIN NAMETYPE NT ON (CN.NAMETYPE=NT.NAMETYPE)
				JOIN NAME N ON (CN.NAMENO=N.NAMENO)
				WHERE CN.ADDRESSCODE=@pnAddresskey
				ORDER BY C.IRN"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnAddresskey	int',
			@pnAddresskey	 = @pnAddresskey
								

End
--Used by Names
If @nErrorCode = 0
Begin
		Set @sSQLString =	"SELECT distinct @pnAddresskey as AddressKey,
					  N.NAMENO AS NameKey,
					  N.NAMECODE AS NameCode,
					  dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) AS NAME,
					  ISNULL(NA.OWNEDBY,0) as IsOwner,					
					  cast(N.NAMENO as nvarchar(11)) +'^'+ cast(NA.OWNEDBY as nvarchar(10)) as RowKey
					  FROM NAME N
					  JOIN NAMEADDRESS NA ON (NA.NAMENO=N.NAMENO)
					  WHERE NA.ADDRESSCODE=@pnAddresskey
					  ORDER BY NAME"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnAddresskey	int',
				@pnAddresskey	 = @pnAddresskey
								

End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListAddressReferencedBy to public
GO
