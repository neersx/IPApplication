-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.naw_ListNameAlias
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameAlias]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameAlias.'
	Drop procedure [dbo].[naw_ListNameAlias]
	Print '**** Creating Stored Procedure dbo.naw_ListNameAlias...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.naw_ListNameAlias
(
	@pnRowCount		int		= null OUTPUT,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey 		int		= null,	-- Returns empty result set if @pnNameKey is null
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	naw_ListNameAlias
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Name Alias.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------  
-- 28 Feb 2006  LP	RFC3216	1	Procedure created
-- 06 Mar 2006	TM	RFC3215	2	Make @pnNameKey parameter optioal and return empty result set 
--					if @pnNameKey is null. Set @pnRowCount parameter.
-- 28 Aug 2006	SF	RFC4214	3	Added RowKey
-- 12 Mar 2009	DV	RFC7598	4	Added Checksum for name alias and NameAliasType
-- 02 Mar 2010	MS	RFC100147 5	Correct the sorting by changing the FNA.ALIASTYPE to 
--					FNA. ALIASDESCRIPTION in order by clause
-- 04 Jun 2010	MF	18703	6	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE and can be included in the Select
-- 11 Apr 2013	DV	R13270	7	Increase the length of nvarchar to 11 when casting or declaring integer


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int

Declare @sSQLString		nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
and @pnNameKey is not null
Begin
	Set @sSQLString = "
	Select	@pnNameKey 		as 'NameKey',
		FNA.ALIASDESCRIPTION	as 'AliasType',
		NA.ALIAS		as 'Alias',
		C.COUNTRY		as 'Country',
		P.PROPERTYNAME		as 'PropertyName',
		CAST(NA.NAMENO as nvarchar(11)) + '^' + CAST(checksum(NA.ALIAS)as nvarchar(20)) + '^' + CAST(checksum(NA.ALIASTYPE) as nvarchar(20)) + '^' +CAST(NA.ALIASNO as nvarchar(11))  as 'RowKey'
	from NAMEALIAS NA
	join dbo.fn_FilterUserAliasTypes(@pnUserIdentityId,@sLookupCulture, null, @pbCalledFromCentura) FNA
					on (FNA.ALIASTYPE = NA.ALIASTYPE)
	left join COUNTRY C	 on (C.COUNTRYCODE = NA.COUNTRYCODE)
	left join PROPERTYTYPE P on (P.PROPERTYTYPE= NA.PROPERTYTYPE)
	where NA.NAMENO = @pnNameKey
	order by FNA.ALIASDESCRIPTION, C.COUNTRY, P.PROPERTYNAME, NA.ALIAS"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura

	Set @pnRowCount = @@RowCount
End
If @nErrorCode = 0
and @pnNameKey is null
Begin
	Select	null as 'NameKey',
		null as 'AliasType',
		null as 'Alias',
		null as 'Country',
		null as 'PropertyName'
	where 1=2

	Set @pnRowCount = @@RowCount
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameAlias to public
GO