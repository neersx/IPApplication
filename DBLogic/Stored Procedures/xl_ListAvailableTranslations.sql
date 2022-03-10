-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.xl_ListAvailableTranslations
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xl_ListAvailableTranslations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xl_ListAvailableTranslations.'
	Drop procedure [dbo].[xl_ListAvailableTranslations]
	Print '**** Creating Stored Procedure dbo.xl_ListAvailableTranslations...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.xl_ListAvailableTranslations
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	xl_ListAvailableTranslations
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of available translations.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Oct 2005  TM	RFC3144	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select DISTINCT	
	TL.CULTURE 		as Culture,   	
	TL.LANGUAGEDESCRIPTION 	as LanguageDescription
	From TRANSLATEDTEXT TT 
	Join dbo.fn_TranslationLanguage(@psCulture, @pbCalledFromCentura) TL on (TL.CULTURE = TT.CULTURE)
	order by LanguageDescription"


	exec @nErrorCode = sp_executesql @sSQLString,
					N'@psCulture		nvarchar(10),
					  @pbCalledFromCentura	bit',
					  @psCulture		= @psCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura
	
	Set @pnRowCount = @@Rowcount
End




Return @nErrorCode
GO

Grant execute on dbo.xl_ListAvailableTranslations to public
GO
