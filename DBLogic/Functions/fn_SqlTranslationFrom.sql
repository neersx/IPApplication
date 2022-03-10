-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_SqlTranslationFrom
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_SqlTranslationFrom') and xtype='FN')
Begin
	print '**** Drop function dbo.fn_SqlTranslationFrom.'
	drop function dbo.fn_SqlTranslationFrom
	print '**** Creating function dbo.fn_SqlTranslationFrom...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_SqlTranslationFrom
(
	@psTableName		nvarchar(30),	-- The name of the database table; e.g. CASEEVENT
	@psShortColumn		nvarchar(30),	-- The name of any nvarchar column to be translated; e.g. EVENTTEXT
	@psLongColumn		nvarchar(30),	-- The name of any ntext column to be translated; e.g. EVENTLONGTEXT
	@psAlias		nvarchar(50),	-- The alias to be used in the select clause for the @psTableName
	@psRequestedCulture	nvarchar(10),	-- The culture that the output is required in.
	@pbCalledFromCentura	bit		-- Will the result set be used by Centura?

)
RETURNS nvarchar(max)
   
-- FUNCTION :	fn_SqlTranslationFrom
-- VERSION :	4
-- DESCRIPTION:	This function is for use when retrieving a translation as a long string.
--		It returns the Sql fragment for use in the From clause.
--		It should be used in conjunction with fn_SqlTranslationSelect.
--		Note: returns null if no translation is required.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 07 Sep 2004	JEK	RFC1695	1	Function created
-- 15 Sep 2004	JEK	RFC1695	2	Translations with HasSourceChanged=1 are obsolete.
-- 15 May 2005	JEK	RFC2508	3	For performance reasons, the lookup culture must be extracted
--					by the calling code.
-- 14 Apr 2011	MF	4	10475	Change nvarchar(4000) to nvarchar(max)

AS
Begin

Declare @sPreparedSQL	nvarchar(max)
Declare @sTIDColumn	nvarchar(30)
Declare @sLanguage	nvarchar(10)
Declare @sXLAlias	nvarchar(55)

Set @psAlias = isnull(@psAlias,@psTableName)

If @psRequestedCulture is not null
Begin
	Set @sTIDColumn = dbo.fn_GetTranslatedTIDColumn(@psTableName, isnull(@psShortColumn, @psLongColumn))
End

-- Translation is required - return the appropriate joins
If @psRequestedCulture is not null
and @sTIDColumn is not null
Begin
	Set @sXLAlias = "XL1_"+@psAlias

	-- Join on the culture
	Set @sPreparedSQL =
	"left join TRANSLATEDTEXT "+@sXLAlias+"	on ("+@sXLAlias+".TID="+@psAlias+"."+@sTIDColumn+char(10)+
	"				and "+@sXLAlias+".CULTURE="+dbo.fn_WrapQuotes(@psRequestedCulture,0,@pbCalledFromCentura)+char(10)+
	"				and "+@sXLAlias+".HASSOURCECHANGED=0)"+char(10)

	Set @sLanguage = dbo.fn_GetParentCulture(@psRequestedCulture)

	-- If the culture contains both language and region, there may be
	-- second join on the language portion only.
	If @sLanguage is not null
	and exists (select 1 FROM TRANSLATEDTEXT WHERE CULTURE=@sLanguage)
	Begin
		Set @sXLAlias = "XL2_"+@psAlias
		Set @sPreparedSQL = @sPreparedSQL+
		"left join TRANSLATEDTEXT "+@sXLAlias+"	on ("+@sXLAlias+".TID="+@psAlias+"."+@sTIDColumn+char(10)+
		"				and "+@sXLAlias+".CULTURE="+dbo.fn_WrapQuotes(@sLanguage,0,@pbCalledFromCentura)+char(10)+
		"				and "+@sXLAlias+".HASSOURCECHANGED=0)"+char(10)

	End
End

Return @sPreparedSQL

End
GO

Grant execute on dbo.fn_SqlTranslationFrom to public
GO
