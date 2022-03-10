-- This script extracts out all data that needs to be translated for a particular language (culture).
-- It locates items where the English has changed (returned with a comment **Obsolete**)
-- as well as items that have not been traslated yet.
--
-- To use this script:
--	1. Set @sCulture to the language you require
--  	   Refer to the database table CULTURE for a list of valid values.

declare @sCulture				nvarchar(10)
declare @sTable					nvarchar(30)
declare @bShowUntranslated		bit

--			*** CHOOSE YOUR LANGUAGE HERE ***
-- DE = German
-- FR = French
-- PT-BR = Portuguese for Brazil
Set @sCulture = 'FR'

-- Set @sTableName to only return results a single table.
Set @sTable = 'NAMETYPE'

-- Set this to restrict to untranslated items
-- 1 - Show all values
-- 0 - Hide items that already have a translated value.
Set @bShowUntranslated = 1

set QUOTED_IDENTIFIER OFF
SET NOCOUNT ON

declare @nSourceID		int
declare	@sTableName		nvarchar(30)
declare	@sShortColumn		nvarchar(30)
declare @sLongColumn		nvarchar(30)
declare @sTIDColumn		nvarchar(30)
declare @nRowCount		int
declare	@sSQLString		nvarchar(4000)
declare	@nShortColumnLength 	int

select 	@nSourceID = min(TRANSLATIONSOURCEID)
from	TRANSLATIONSOURCE
WHERE	INUSE=1
and (@sTable = '' or TABLENAME = @sTable)

-- Process each translatable piece of data
While	(@nSourceID is not null)
begin
	select	@sTableName	= TABLENAME,
		@sShortColumn	= SHORTCOLUMN,
		@sLongColumn	= LONGCOLUMN,
		@sTIDColumn	= TIDCOLUMN
	FROM	TRANSLATIONSOURCE
	WHERE	TRANSLATIONSOURCEID = @nSourceID

	-- Find out max length of structure's shortcolumn
	If @sShortColumn is not null
	and @sLongColumn is null
	Begin
		Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID(@sTableName),@sShortColumn,'PRECISION')
	End
	Else
	Begin
		Set @nShortColumnLength=null
	End

	Set @sSQLString = "
	select 	T."+@sTIDColumn+" as ID, '"+@sTableName+"' as TableName,
		'"+isnull(@sShortColumn,@sLongColumn)+"' as ColumnName,
		"+isnull(@sShortColumn,@sLongColumn)+" as English,
		case when TT.TID is null then '' else isnull(TT.LONGTEXT,TT.SHORTTEXT) end as Translation,
		"+case when @nShortColumnLength is not null then "'Max ("+cast(@nShortColumnLength as nvarchar)+")'+" end+"
		case when TT.HASSOURCECHANGED = 1 THEN ' **Obsolete**' else '' end as Comment
	from "+@sTableName+" T
	LEFT JOIN TRANSLATEDTEXT TT 	ON (TT.TID=T."+@sTIDColumn+"
					AND TT.CULTURE=@sCulture)
	WHERE 	T."+isnull(@sShortColumn,@sLongColumn)+" is not null
	and	datalength(T."+isnull(@sShortColumn,@sLongColumn)+") > 0"
	
	if (@bShowUntranslated != 1)
		Set @sSQLString = @sSQLString + char(10) + "and	(TT.TID IS NULL OR TT.HASSOURCECHANGED=1)"
		
	Set @sSQLString = @sSQLString + char(10) + "ORDER BY cast(T."+isnull(@sShortColumn,@sLongColumn)+" as nvarchar(4000))"

	exec sp_executesql @sSQLString,
		N'@sCulture		nvarchar(10)',
		  @sCulture		= @sCulture

	if @sTable = ''
		select 	@nSourceID = min(TRANSLATIONSOURCEID)
		from	TRANSLATIONSOURCE
		where	INUSE=1
		AND	TRANSLATIONSOURCEID > @nSourceID
	else
	BEGIN
		declare @nLastSourceId int
		Set @nLastSourceId = @nSourceID
		SET @nSourceID = NULL
		
		select 	@nSourceID = min(TRANSLATIONSOURCEID)
		from	TRANSLATIONSOURCE
		where	INUSE=1
		AND	TRANSLATIONSOURCEID > @nLastSourceId
		and TABLENAME = @sTable
	END
end

go