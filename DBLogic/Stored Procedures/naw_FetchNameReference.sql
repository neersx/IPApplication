-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchNameReference
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchNameReference]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchNameReference.'
	Drop procedure [dbo].[naw_FetchNameReference]
End
Print '**** Creating Stored Procedure dbo.naw_FetchNameReference...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchNameReference
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int 		-- Mandatory
)
as
-- PROCEDURE:	naw_FetchNameReference
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Name Reference (Name Alias) business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Oct 2008	PS	RFC6461	1	Procedure created
-- 12 Mar 2009	DV	RFC7598	2	Added Checksum name alias and name Alias type
-- 04 Jun 2010	MF	SQA187033	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE and should be check for Null values
-- 02 Jul 2010  PA  RFC9423 4   Fix the bugs and added the new fields ALIASNO, COUNTRYCODE and PROPERTYTYPE to retrive the vaules in edit mode
-- 11 Apr 2013	DV	R13270	5	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


If @nErrorCode = 0
and @pnNameKey is not null
Begin
	Set @sSQLString = "
	Select	@pnNameKey 		as 'NameKey',
		FNA.ALIASDESCRIPTION	as 'AliasType',
		NA.ALIAS		as 'Alias',
		NA.ALIASTYPE		as 'AliasTypeKey',
        NA.ALIASNO          as 'AliasNo',
        C.COUNTRYCODE       as 'CountryCode',
		C.COUNTRY		as 'Country',
        P.PROPERTYTYPE		as 'PropertyTypeCode',
		P.PROPERTYNAME		as 'PropertyName',
		CAST(NA.NAMENO		as nvarchar(11)) + '^' + CAST(checksum(NA.ALIAS)as nvarchar(20)) + '^' + CAST(checksum(NA.ALIASTYPE) as nvarchar(20)) + '^' + CAST(checksum(NA.ALIASNO) as nvarchar(10)) as 'RowKey'
	from NAMEALIAS NA
	join dbo.fn_FilterUserAliasTypes(@pnUserIdentityId,@sLookupCulture, null, @pbCalledFromCentura) FNA
					on (FNA.ALIASTYPE = NA.ALIASTYPE)
	left join COUNTRY C		on (C.COUNTRYCODE =NA.COUNTRYCODE)
	left join PROPERTYTYPE P	on (P.PROPERTYTYPE=NA.PROPERTYTYPE)
	where NA.NAMENO = @pnNameKey
	order by FNA.ALIASTYPE, C.COUNTRY, P.PROPERTYNAME, NA.ALIAS"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura
End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchNameReference to public
GO
