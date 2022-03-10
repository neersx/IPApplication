-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_SqlTranslatedColumn
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_SqlTranslatedColumn') and xtype='FN')
Begin
	print '**** Drop function dbo.fn_SqlTranslatedColumn.'
	drop function dbo.fn_SqlTranslatedColumn
	print '**** Creating function dbo.fn_SqlTranslatedColumn...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_SqlTranslatedColumn
(
	@psTableName		nvarchar(30),	-- The name of the database table; e.g. CASEEVENT
	@psShortColumn		nvarchar(30),	-- The name of any nvarchar column to be translated; e.g. EVENTTEXT
	@psLongColumn		nvarchar(30),	-- The name of any ntext column to be translated; e.g. EVENTLONGTEXT
	@psAlias		nvarchar(50),	-- The alias to be used in the select clause for the @psTableName
	@psRequestedCulture	nvarchar(10),	-- The culture that the output is required in.
	@pbCalledFromCentura	bit	= 0	-- Will the result set be used by Centura?
)
RETURNS nvarchar(max)
   
-- FUNCTION :	fn_SqlTranslatedColumn
-- VERSION :	7
-- DESCRIPTION:	This function returns SQL to retrieve the translation for a
--		single column in a select statement.  It chooses the best
--		implementation based on the information provided and rules
--		held on the database.  If translation is not necessary,
--		an untranslated select fragment is returned.

-- MODIFICATION
-- Date		Who	No.	 Version
-- ====         ===	=== 	 =======
-- 30 Aug 2004	JEK	RFC1695	 1	Function created
-- 15 May 2005	JEK	RFC2508	 2	For performance reasons, the lookup culture must be extracted
--						by the calling code.
-- 13 Apr 2011	MF	RFC10475 	3	Change nvarchar(4000) to nvarchar(max)	
-- 28 Apr 2011	AT	RFC7956	4	Append Alias to short column.
-- 12 May 2011  DV      RFC10564 	5    	  Added @psAlias in front of @psShortColumn
-- 24 Jun 2011	AT	RFC10893 	6	Default @pbCalledFromCentura to 0 if its passed as null.
-- 25 Aug 2011	ASH	R10865  	7	Change nvarchar(4000) to nvarchar(max)

AS
Begin

Declare @sPreparedSQL	nvarchar(max)
Declare @sTIDColumn	nvarchar(30)

Set @psAlias = isnull(@psAlias,@psTableName)
Set @pbCalledFromCentura = isnull(@pbCalledFromCentura,0)

If @psRequestedCulture is not null
Begin
	Set @sTIDColumn = dbo.fn_GetTranslatedTIDColumn(@psTableName, isnull(@psShortColumn, @psLongColumn))
End

-- Translation is not required
If @psRequestedCulture is null
or @sTIDColumn is null
Begin
	If @psShortColumn is not null
	and @psLongColumn is not null
	Begin
		-- e.g. isnull(C.LONGEVENTTEXT,C.EVENTTEXT)
		Set @sPreparedSQL = "isnull("+@psAlias+"."+@psLongColumn+","+@psAlias+"."+@psShortColumn+")"
	End
	Else
	Begin
		-- e.g. C.TITLE
		Set @sPreparedSQL = @psAlias+"."+isnull(@psShortColumn, @psLongColumn)
	End

	If @psLongColumn is not null
	Begin
		If @pbCalledFromCentura = 1
		Begin
			-- e.g. cast(isnull(C.LONGEVENTTEXT,C.EVENTTEXT) as nvarchar(254))
			Set @sPreparedSQL = "cast("+@sPreparedSQL+" as nvarchar(254))"
		End
		Else
		Begin
			-- e.g. cast(isnull(C.LONGEVENTTEXT,C.EVENTTEXT) as nvarchar(max))
			Set @sPreparedSQL = "cast("+@sPreparedSQL+" as nvarchar(max))"
		End
	End
End
-- Translation is required
Else
Begin
	-- Result is limited to 254 characters for Centura
	If @pbCalledFromCentura = 1
	Begin
		Set @sPreparedSQL = "dbo.fn_GetTranslationLimited("
	End
	Else
	Begin
		Set @sPreparedSQL = "dbo.fn_GetTranslation("
	End

	-- e.g. dbo.fn_GetTranslation(C.EVENTTEXT,C.LONGEVENTTEXT,C.EVENTTEXT_TID,'DE-AT')
	Set @sPreparedSQL = @sPreparedSQL+
		case when @psShortColumn is null then 'null' else @psAlias+"."+@psShortColumn end+", "+
		case when @psLongColumn is null then 'null' else @psAlias+"."+@psLongColumn end+", "+
		@psAlias+"."+@sTIDColumn+", "+
		dbo.fn_WrapQuotes(@psRequestedCulture,0,@pbCalledFromCentura)+")" 
End

Return @sPreparedSQL
End
GO

Grant execute on dbo.fn_SqlTranslatedColumn to public
GO
