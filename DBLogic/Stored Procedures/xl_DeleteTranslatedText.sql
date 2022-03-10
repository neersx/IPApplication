-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xl_DeleteTranslatedText
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xl_DeleteTranslatedText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xl_DeleteTranslatedText.'
	Drop procedure [dbo].[xl_DeleteTranslatedText]
End
Print '**** Creating Stored Procedure dbo.xl_DeleteTranslatedText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.xl_DeleteTranslatedText
(
	@pnUserIdentityId	int,		-- Mandatory
	@pnTID			int,		-- Mandatory
	@pbCalledFromCentura	bit,		-- Mandatory
	@psCultureCode 		nvarchar(10)	= null, 	
	@pbHasSourceChanged	bit		= 0,		-- Indicates whether the source text has changed since the translation was prepared.	
	@ptOldTranslation 	ntext		= null,
	@pbOldHasSourceChanged	bit		= 0		-- Indicates whether the source text has changed since the translation was prepared.	
)
as
-- PROCEDURE:	xl_DeleteTranslatedText
-- VERSION:	2
-- DESCRIPTION:	Delete row from TranslatedText with matching TID and Culture.
--		Note: Concurrency checking is performed for .net but not for client/server.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Sep 2004	TM	RFC1695	1	Procedure created
-- 24 Sep 2004	TM	RFC1695	2	Correct the concurrency control logic.


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @nOldTranslationLength	int
Declare @sShortOldTranslation	nvarchar(3900)

-- Initialise variables
Set @nErrorCode 		= 0

-- Find out the length of the passed translation
If @nErrorCode = 0
Begin
	Set @nOldTranslationLength = datalength(@ptOldTranslation)
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete TRANSLATEDTEXT
	where	TID	 	 = @pnTID
	and	CULTURE		 = @psCultureCode"
	
	-- Concurrency checking is required for .net but not for client/server:
	If @pbCalledFromCentura = 0
	Begin
		If @nOldTranslationLength >  7800
		Begin
			-- Use the fn_IsNtextEqual() function to compare ntext strings
			Set @sSQLString = @sSQLString + char(10) + "
			and dbo.fn_IsNtextEqual(LONGTEXT, @ptOldTranslation) = 1"
		End
		Else Begin
			Set @sShortOldTranslation = CAST(@ptOldTranslation as nvarchar(3900))
	
			Set @sSQLString = @sSQLString + char(10) + "
			and SHORTTEXT = @sShortOldTranslation"
		End	

		Set @sSQLString = @sSQLString + char(10) + "and 	HASSOURCECHANGED = @pbOldHasSourceChanged"
	End

	exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnTID	 	int,
						  @psCultureCode 	nvarchar(10),
						  @ptOldTranslation	ntext,
						  @pbOldHasSourceChanged bit,
						  @sShortOldTranslation	nvarchar(3900)',
						  @pnTID	 	= @pnTID,
					  	  @psCultureCode 	= @psCultureCode,
						  @ptOldTranslation	= @ptOldTranslation,
						  @pbOldHasSourceChanged=@pbOldHasSourceChanged,		
						  @sShortOldTranslation = @sShortOldTranslation
End

Return @nErrorCode
GO

Grant execute on dbo.xl_DeleteTranslatedText to public
GO
