-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xl_InsertTranslatedText
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xl_InsertTranslatedText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xl_InsertTranslatedText.'
	Drop procedure [dbo].[xl_InsertTranslatedText]
End
Print '**** Creating Stored Procedure dbo.xl_InsertTranslatedText...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.xl_InsertTranslatedText
(
	@pnUserIdentityId	int,		-- Mandatory
	@pnTID			int,		-- Mandatory
	@psCultureCode 		nvarchar(10)	= null, 	
	@pbCalledFromCentura	bit,		-- Mandatory
	@ptTranslation 		ntext		= null,
	@pbHasSourceChanged	bit		= 0		-- Indicates whether the source text has changed since the translation was prepared.
)
as
-- PROCEDURE:	xl_InsertTranslatedText
-- VERSION:	1
-- DESCRIPTION:	Add new Translation in either ShortText or LongText as required by its size.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Jun 2004	TM	RFC915	1	Procedure created


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)

declare @nTranslationLength	int

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin
	Set @nTranslationLength = datalength(@ptTranslation)
End

If @nErrorCode = 0
and @nTranslationLength > 0
Begin
	Set @sSQLString = " 
	insert 	into TRANSLATEDTEXT
		(TID, 
		 CULTURE, 		 
		 SHORTTEXT,
		 LONGTEXT,
		 HASSOURCECHANGED)
	values	(@pnTID,
		 @psCultureCode,"+		
		 CASE WHEN @nTranslationLength <= 7800 	THEN "@ptTranslation" ELSE "NULL" END+","+char(10)+
		 CASE WHEN @nTranslationLength >  7800 	THEN "@ptTranslation" ELSE "NULL" END+","+char(10)+
		 "@pbHasSourceChanged
		)"

	exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnTID	 	int,
						  @psCultureCode 	nvarchar(10),
						  @ptTranslation 	ntext,
					 	  @pbHasSourceChanged	bit',
						  @pnTID	 	= @pnTID,
					  	  @psCultureCode 	= @psCultureCode,
						  @ptTranslation 	= @ptTranslation,
						  @pbHasSourceChanged	= @pbHasSourceChanged						
End

Return @nErrorCode
GO

Grant execute on dbo.xl_InsertTranslatedText to public
GO