-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_SqlTranslationSelect
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_SqlTranslationSelect') and xtype='FN')
Begin
	print '**** Drop function dbo.fn_SqlTranslationSelect.'
	drop function dbo.fn_SqlTranslationSelect
	print '**** Creating function dbo.fn_SqlTranslationSelect...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_SqlTranslationSelect
(
	@psTableName		nvarchar(30),	-- The name of the database table; e.g. CASEEVENT
	@psShortColumn		nvarchar(30),	-- The name of any nvarchar column to be translated; e.g. EVENTTEXT
	@psLongColumn		nvarchar(30),	-- The name of any ntext column to be translated; e.g. EVENTLONGTEXT
	@psAlias		nvarchar(50),	-- The alias to be used in the select clause for the @psTableName
	@psRequestedCulture	nvarchar(10),	-- The culture that the output is required in.
	@pbCalledFromCentura	bit		-- Will the result set be used by Centura?

)
RETURNS nvarchar(max)
   
-- FUNCTION :	fn_SqlTranslationSelect
-- VERSION :	3
-- DESCRIPTION:	This function is for use when retrieving a translation as a long string.
--		It returns the Sql fragment for use in the Select clause.
--		It should be used in conjunction with fn_SqlTranslationFrom.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 07 Sep 2004	JEK	RFC1695	1	Function created
-- 15 May 2005	JEK	RFC2508	2	For performance reasons, the lookup culture must be extracted
--					by the calling code.
-- 14 Apr 2011	MF	RFC10475 3	Change nvarchar(4000) to nvarchar(max)

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

-- No translation is required, so return a basic select clause
If @psRequestedCulture is null
or @sTIDColumn is null
Begin

	If @psLongColumn is not null
	and @psShortColumn is not null
	Begin
		Set @sPreparedSQL = "isnull("+@psAlias+"."+@psLongColumn+","+
					@psAlias+"."+@psShortColumn+")"
	End
	Else If @psLongColumn is null
	Begin
		Set @sPreparedSQL = @psAlias+"."+@psShortColumn

		-- Centura can only handle up to 254 characters as
		-- a short string, so longer nvarchar data may need to be 
		-- treated explicitly as a long string.
		If @pbCalledFromCentura=1
		Begin
			Set @sPreparedSQL = "cast("+@sPreparedSQL+" as ntext)"
		End
	End
	Else
	Begin
		Set @sPreparedSQL = @psAlias+"."+@psLongColumn
	End

End
-- Implement selects from translation table join(s)
Else
Begin
	-- The data from the first join.
	Set @sXLAlias = "XL1_"+@psAlias
	Set @sPreparedSQL = "coalesce("+@sXLAlias+".LONGTEXT,"+@sXLAlias+".SHORTTEXT"

	Set @sLanguage = dbo.fn_GetParentCulture(@psRequestedCulture)

	-- If the culture contains both language and region, there may be
	-- second join on the language portion only.
	If @sLanguage is not null
	and exists (select 1 FROM TRANSLATEDTEXT WHERE CULTURE=@sLanguage)
	Begin
		Set @sXLAlias = "XL2_"+@psAlias
		Set @sPreparedSQL = @sPreparedSQL+","+@sXLAlias+".LONGTEXT,"+@sXLAlias+".SHORTTEXT"
	End

	-- Add the source columns as defaults if the tanslation is not found.
	If @psLongColumn is not null
	Begin
		Set @sPreparedSQL = @sPreparedSQL+","+@psAlias+"."+@psLongColumn
	End

	If @psShortColumn is not null
	Begin
		Set @sPreparedSQL = @sPreparedSQL+","+@psAlias+"."+@psShortColumn
	End

	-- Finish the coalesce
	Set @sPreparedSQL = @sPreparedSQL + ")"

End

Return @sPreparedSQL

End
GO

Grant execute on dbo.fn_SqlTranslationSelect to public
GO
