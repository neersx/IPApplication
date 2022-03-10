-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchNameLanguage
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchNameLanguage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchNameLanguage.'
	Drop procedure [dbo].[naw_FetchNameLanguage]
End
Print '**** Creating Stored Procedure dbo.naw_FetchNameLanguage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchNameLanguage
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int 		-- Mandatory
)
as
-- PROCEDURE:	naw_FetchNameLanguage
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Name Language business entity.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Nov 2011	KR	R9095	1	Procedure created
-- 11 Apr 2013	DV	R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer

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
		L.TABLECODE		as 'LanguageCode',
		L.DESCRIPTION		as 'Language',
		P.PROPERTYTYPE		as 'PropertyTypeCode',
		P.PROPERTYNAME		as 'PropertyName',
		NL.SEQUENCENO		as 'Sequence',
		A.ACTION		as 'ActionCode',
		A.ACTIONNAME		as 'ActionDescription',
		CAST(NL.NAMENO		as nvarchar(11)) + '^' + CAST(NL.SEQUENCENO as nvarchar(20)) as 'RowKey'
	from NAMELANGUAGE NL
	left join TABLECODES L		on (L.TABLECODE = NL.LANGUAGE and L.TABLETYPE = 47)
	left join PROPERTYTYPE P	on (P.PROPERTYTYPE=NL.PROPERTYTYPE)
	left join ACTIONS A		on (A.ACTION = NL.ACTION)
	where NL.NAMENO = @pnNameKey
	order by NL.SEQUENCENO, L.TABLECODE, P.PROPERTYNAME"

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

Grant execute on dbo.naw_FetchNameLanguage to public
GO
