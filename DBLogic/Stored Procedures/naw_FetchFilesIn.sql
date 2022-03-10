                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchFilesIn									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchFilesIn]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchFilesIn.'
	Drop procedure [dbo].[naw_FetchFilesIn]
End
Print '**** Creating Stored Procedure dbo.naw_FetchFilesIn...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchFilesIn
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,		-- Mandatory
	@pbNewRow		bit		= 0,
	@psCountryCode		nvarchar(3)	= null
)
as
-- PROCEDURE:	naw_FetchFilesIn
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the FilesIn business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 11 Apr 2006	IB	RFC3762	1	Procedure created
-- 11 Apr 2013	DV	R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @sCountryCode	nvarchar(3)
Declare @sCountry	nvarchar(60)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	If @pbNewRow = 1
	Begin
		Set @sSQLString = "Select	
			@sCountryCode = C.COUNTRYCODE,
			@sCountry = "+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)+"
		from 	COUNTRY C 
		where 	C.COUNTRYCODE = @psOriginalCountryCode"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@sCountryCode		nvarchar(3) output,
				@sCountry		nvarchar(60) output,
				@psOriginalCountryCode	nvarchar(3)',
				@sCountryCode		= @sCountryCode output,
				@sCountry		= @sCountry output,
				@psOriginalCountryCode	= @psCountryCode

		If @nErrorCode = 0
		Begin
			Select 	null		as RowKey,
				@pnNameKey	as NameKey,
				@sCountryCode	as CountryCode,
				@sCountry	as CountryName,
				null		as Notes
		End

	End
	Else
	Begin
		Set @sSQLString = "Select
		CAST(F.NAMENO as nvarchar(11))+'^'+F.COUNTRYCODE		
					as RowKey,
		F.NAMENO		as NameKey,
		F.COUNTRYCODE		as CountryCode,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)+"
					as CountryName,
		"+dbo.fn_SqlTranslatedColumn('FILESIN','NOTES',null,'F',@sLookupCulture,@pbCalledFromCentura)+"
					as Notes
		from 	FILESIN F
		join	COUNTRY C on (C.COUNTRYCODE = F.COUNTRYCODE)
		where	F.NAMENO = @pnNameKey
		order by NameKey, CountryName"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnNameKey	int,
				@psCountryCode	nvarchar(3)',
				@pnNameKey	= @pnNameKey,
				@psCountryCode	= @psCountryCode
	End

End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchFilesIn to public
GO