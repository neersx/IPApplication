-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_GetFormattedName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_GetFormattedName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_GetFormattedName.'
	Drop procedure [dbo].[naw_GetFormattedName]
End
Print '**** Creating Stored Procedure dbo.naw_GetFormattedName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_GetFormattedName
(
	@psFormattedName	nvarchar(500)	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTitle		nvarchar(20) 	= null,
	@psFirstName		nvarchar(50) 	= null,
	@psMiddleName		nvarchar(50)	= null,
	@psSuffix		nvarchar(20)	= null,
	@psName			nvarchar(254) 	= null,
	@psCountryCode		nvarchar(3) 	= null,		-- The country to which the individual belongs
	@pnNameStyleKey		int		= null
)
as
-- PROCEDURE:	naw_GetFormattedName
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Format name with given params.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 May 2006	JEK	RFC3492	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = '
		Select		@psFormattedName=dbo.fn_FormatFullName(@psName, @psFirstName, @psMiddleName, @psSuffix, @psTitle, Coalesce(@pnNameStyleKey, C.NAMESTYLE, 7101))
		from		(select 1 as txt) DUMMYTABLE
		left join	COUNTRY C on (C.COUNTRYCODE = @psCountryCode)'

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psFormattedName	nvarchar(254) output,
				  @psTitle		nvarchar(20),
				  @psFirstName		nvarchar(50),
				  @psMiddleName		nvarchar(50),
				  @psSuffix		nvarchar(20),
				  @psName		nvarchar(254),
				  @psCountryCode	nvarchar(3),
				  @pnNameStyleKey	int',
				  @psFormattedName	= @psFormattedName output,
				  @psTitle		= @psTitle,
				  @psFirstName		= @psFirstName,
				  @psMiddleName		= @psMiddleName,
				  @psSuffix		= @psSuffix,
				  @psName		= @psName,
				  @psCountryCode	= @psCountryCode,
				  @pnNameStyleKey	= @pnNameStyleKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_GetFormattedName to public
GO
