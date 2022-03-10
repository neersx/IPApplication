-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_InsertTranslatedText
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_InsertTranslatedText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_InsertTranslatedText.'
	Drop procedure [dbo].[ipn_InsertTranslatedText]
End
Print '**** Creating Stored Procedure dbo.ipn_InsertTranslatedText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipn_InsertTranslatedText
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10), 	-- the language in which output is to be expressed
	@psTableName		nvarchar(100),	-- Mandatory
	@psTIDColumnName	nvarchar(100),	-- Mandatory
	@psText			ntext		= null,
	@pnTID			int 		= null 	output	-- pass this in if a TID already exists
)
as
-- PROCEDURE:	ipn_InsertTranslatedText
-- VERSION:	3
-- DESCRIPTION:	Generates a TID and Inserts translated text.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 May 2008	AT	RFC5438	1	Procedure created
-- 30 OCT 2010	ASH	RFC9788 2       Insert in LONGTEXT column if datalength of @psText is greater than 508.
-- 15 May 2013	MS	R13490	3	Change @psCulture length from 5 to 10 as some cultures are getting truncated


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(300)

-- Initialise variables
Set @nErrorCode = 0

-- Check that we are using a translatable table/column
If @nErrorCode = 0 
	and exists(Select 1 From TRANSLATIONSOURCE Where TABLENAME=@psTableName and TIDCOLUMN=@psTIDColumnName and INUSE = 1)
	and @pnTID is null
Begin
	-- insert the TRANSLATEDITEM (TID auto generated)
	-- The insert trigger won't insert this for us because the value of the column will be null on the main table.
	-- It is null because the language being inserted is not the native db language.
	Set @sSQLString = "Insert into TRANSLATEDITEMS(TRANSLATIONSOURCEID)
				Select TRANSLATIONSOURCEID
				From TRANSLATIONSOURCE TS
				Where TS.TABLENAME = @psTableName
				and TS.TIDCOLUMN = @psTIDColumnName
				and TS.INUSE = 1

			Select @pnTID=@@IDENTITY"
	
	exec @nErrorCode = sp_executesql @sSQLString, 
					N'@psTableName nvarchar(100),
					@psTIDColumnName nvarchar(100),
					@pnTID int output',
					@psTableName=@psTableName,
					@psTIDColumnName=@psTIDColumnName,
					@pnTID=@pnTID output
End

If (@nErrorCode = 0 and @pnTID is not null)
Begin
	-- insert a row even if the text is null.
	If (datalength(@psText) <= 508)
	Begin
		Insert into TRANSLATEDTEXT(TID, CULTURE, SHORTTEXT)
		values(@pnTID, @psCulture, @psText)
	End
	Else
	Begin
		Insert into TRANSLATEDTEXT(TID, CULTURE, LONGTEXT)
		values(@pnTID, @psCulture, @psText)
	End
End

Set @nErrorCode = @@ERROR

Return @nErrorCode
GO

Grant execute on dbo.ipn_InsertTranslatedText to public
GO
