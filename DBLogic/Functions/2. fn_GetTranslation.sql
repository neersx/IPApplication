-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetTranslation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_GetTranslation') and xtype='FN')
Begin
	print '**** Drop function dbo.fn_GetTranslation.'
	drop function dbo.fn_GetTranslation
	print '**** Creating function dbo.fn_GetTranslation...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_GetTranslation
(
	@psShortSourceData	nvarchar(4000),
	@ptLongSourceData	ntext,
	@pnTID			int,
	@psRequiredCulture	nvarchar(10)	
)
RETURNS nvarchar(max)
   
-- FUNCTION :	fn_GetTranslation
-- VERSION :	3
-- DESCRIPTION:	This function returns the translation for the source data.
--		If none is found, the source data is returned.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 26 Aug 2004	JEK	RFC1695	1	Function created
-- 15 Sep 2004	JEK	RFC1695	2	Rows with HasSourceChanged=1 are obsolete.
-- 14 Apr 2011	MF	RFC10475 3	Change nvarchar(4000) to nvarchar(max)
AS
Begin

Declare @sTranslatedString	nvarchar(max)
Declare @sCulture		nvarchar(10)
Declare @sLanguage		nvarchar(10)

If @pnTID is not null
Begin
	Set @sLanguage = dbo.fn_GetParentCulture(@psRequiredCulture)

	If @sLanguage is null
	Begin
		Set @sLanguage = upper(@psRequiredCulture)
	End
	Else
	Begin
		Set @sCulture = upper(@psRequiredCulture)
	End

	-- Take a match on the full culture in preference to language
	If @sCulture is not null
	Begin
		Select 	@sTranslatedString = cast(isnull(T.LONGTEXT, T.SHORTTEXT) as nvarchar(max))
		from 	TRANSLATEDTEXT T
		where 	T.TID = @pnTID 
		and 	T.CULTURE = @sCulture
		and	T.HASSOURCECHANGED = 0
	End

	-- Look for a translation for the language portion only
	If @sTranslatedString is null
	and @sLanguage is not null
	Begin
		Select 	@sTranslatedString = cast(isnull(T.LONGTEXT, T.SHORTTEXT) as nvarchar(max))
		from 	TRANSLATEDTEXT T 
		where 	T.TID = @pnTID 
		and 	T.CULTURE = @sLanguage
		and	T.HASSOURCECHANGED = 0
	End

End
	
Return coalesce(@sTranslatedString, @ptLongSourceData, @psShortSourceData)
End
GO

Grant execute on dbo.fn_GetTranslation to public
GO
