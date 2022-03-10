set quoted_identifier off
set nocount on
set concat_null_yields_null off

declare @sSQLString 	as nvarchar(4000)
declare @sCulture	as nvarchar(10)
declare @sTableName	as nvarchar(30)
declare @sShortColumn	as nvarchar(30)
declare @sLongColumn	as nvarchar(30)
declare @bCalledFromCentura as bit
declare @sLookupCulture	as nvarchar(10)

-- Translation Testing
-- Test generation and execution of translation Sql.

-- This script generates SQL to test the following permutations, for each
-- combination of Culture/TableName/ShortColumn/LongColumn set below
-- 1. Values returned by intermediate (helper) functions for Centura
-- 2. Centura translation as a short string
-- 3. Centura translation as a long string
-- 4. Values returned by intermediate (helper) functions for .net
-- 5. .net translation as a short string
-- 6. .net translation as a long string

-- Recommended tests:
-- 1. TID is not in use
-- 2. There are no translations for the culture
-- 3. Culture with combined language and region (e.g. de-AT)
--	3.1 Exact match
--	3.2 Defaulting to language version
-- 4. Culture with language portion only (e.g. de)
-- 5. Culture valid for .net, but not Centura (e.g. zh-CN)

Set @sCulture = 'zh-cn'

-- Recommended tests: 
-- each of short only, long only, short and long source data
Set @sTableName = 'MODULE'
Set @sShortColumn = 'TITLE'
Set @sLongColumn = NULL

--Set @sTableName = 'NAMETEXT'
--Set @sShortColumn = NULL
--Set @sLongColumn = 'TEXT'

--Set @sTableName = 'CASEEVENT'
--Set @sShortColumn = 'EVENTTEXT'
--Set @sLongColumn = 'EVENTLONGTEXT'



-- Test short translations for Centura

Set @bCalledFromCentura = 0

select 	@sCulture as Culture,
	dbo.fn_GetParentCulture(@sCulture) as ParentCulture,
	dbo.fn_GetLookupCulture(@sCulture,null,@bCalledFromCentura) as LookupCulture,
	dbo.fn_GetTranslatedTIDColumn(@sTableName,isnull(@sShortColumn,@sLongColumn)) as TIDColumn

Set @sLookupCulture = dbo.fn_GetLookupCulture(@sCulture,null,@bCalledFromCentura)

If @sShortColumn is not null
and @sLongColumn is not null
Begin
	Set @sSQLString =
		"select 	T."+@sShortColumn+", T."+@sLongColumn+", "+CHAR(10)+
		dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sLookupCulture,@bCalledFromCentura)+" as Translation"+CHAR(10)+
		", len("+dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sLookupCulture,@bCalledFromCentura)+") as TranslationLength"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		"WHERE T."+@sShortColumn+" IS NOT NULL"+CHAR(10)+
		"OR T."+@sLongColumn+" IS NOT NULL"+CHAR(10)+
		"AND T."+@sLongColumn+" NOT LIKE ''"

End

If @sShortColumn is not null
and @sLongColumn is null
Begin
	Set @sSQLString =
		"select 	T."+@sShortColumn+CHAR(10)+
		", "+dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as Translation"+CHAR(10)+
		", len("+dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+") as TranslationLength"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		"WHERE T."+@sShortColumn+" IS NOT NULL"+CHAR(10)

End

If @sShortColumn is null
and @sLongColumn is not null
Begin
	Set @sSQLString =
		"select 	T."+@sLongColumn+", "+CHAR(10)+
		dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as Translation"+CHAR(10)+
		", len("+dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+") as TranslationLength"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		"WHERE T."+@sLongColumn+" IS NOT NULL"+CHAR(10)+
		"AND T."+@sLongColumn+" NOT LIKE ''"

End

print 'Short Centura sql: '
print @sSQLString

exec sp_executesql @sSQLString

-- Test long translations for Centura

If @sShortColumn is not null
and @sLongColumn is not null
Begin
	Set @sSQLString =
		"select 	T."+@sShortColumn+", T."+@sLongColumn+", "+CHAR(10)+
		dbo.fn_SqlTranslationSelect(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as LongTranslation"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		dbo.fn_SqlTranslationFrom(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+
		"WHERE T."+@sShortColumn+" IS NOT NULL"+CHAR(10)+
		"OR T."+@sLongColumn+" IS NOT NULL"+CHAR(10)+
		"AND T."+@sLongColumn+" NOT LIKE ''"

End


If @sShortColumn is not null
and @sLongColumn is null
Begin
	Set @sSQLString =
		"select 	T."+@sShortColumn+CHAR(10)+
		", "+dbo.fn_SqlTranslationSelect(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as LongTranslation"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		dbo.fn_SqlTranslationFrom(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+
		"WHERE T."+@sShortColumn+" IS NOT NULL"+CHAR(10)

End

If @sShortColumn is null
and @sLongColumn is not null
Begin
	Set @sSQLString =
		"select 	T."+@sLongColumn+", "+CHAR(10)+
		dbo.fn_SqlTranslationSelect(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as LongTranslation"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		dbo.fn_SqlTranslationFrom(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+
		"WHERE T."+@sLongColumn+" IS NOT NULL"+CHAR(10)+
		"AND T."+@sLongColumn+" NOT LIKE ''"

End

print 'Long Centura sql: '
print @sSQLString

exec sp_executesql @sSQLString

-- Test short translations for .net

Set @bCalledFromCentura = 0

select 	@sCulture as Culture,
	dbo.fn_GetParentCulture(@sCulture) as ParentCulture,
	dbo.fn_GetLookupCulture(@sCulture,null,@bCalledFromCentura) as LookupCulture,
	dbo.fn_GetTranslatedTIDColumn(@sTableName,isnull(@sShortColumn,@sLongColumn)) as TIDColumn


If @sShortColumn is not null
and @sLongColumn is not null
Begin
	Set @sSQLString =
		"select 	T."+@sShortColumn+", T."+@sLongColumn+", "+CHAR(10)+
		dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as Translation"+CHAR(10)+
		", len("+dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+") as TranslationLength"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		"WHERE T."+@sShortColumn+" IS NOT NULL"+CHAR(10)+
		"OR T."+@sLongColumn+" IS NOT NULL"+CHAR(10)+
		"AND T."+@sLongColumn+" NOT LIKE ''"

End

If @sShortColumn is not null
and @sLongColumn is null
Begin
	Set @sSQLString =
		"select 	T."+@sShortColumn+CHAR(10)+
		", "+dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as Translation"+CHAR(10)+
		", len("+dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+") as TranslationLength"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		"WHERE T."+@sShortColumn+" IS NOT NULL"+CHAR(10)

End

If @sShortColumn is null
and @sLongColumn is not null
Begin
	Set @sSQLString =
		"select 	T."+@sLongColumn+", "+CHAR(10)+
		dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as Translation"+CHAR(10)+
		", len("+dbo.fn_SqlTranslatedColumn(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+") as TranslationLength"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		"WHERE T."+@sLongColumn+" IS NOT NULL"+CHAR(10)+
		"AND T."+@sLongColumn+" NOT LIKE ''"

End

print 'Short .net sql: '
print @sSQLString

exec sp_executesql @sSQLString

-- Test long translations for .net

If @sShortColumn is not null
and @sLongColumn is not null
Begin
	Set @sSQLString =
		"select 	T."+@sShortColumn+", T."+@sLongColumn+", "+CHAR(10)+
		dbo.fn_SqlTranslationSelect(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as LongTranslation"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		dbo.fn_SqlTranslationFrom(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+
		"WHERE T."+@sShortColumn+" IS NOT NULL"+CHAR(10)+
		"OR T."+@sLongColumn+" IS NOT NULL"+CHAR(10)+
		"AND T."+@sLongColumn+" NOT LIKE ''"

End


If @sShortColumn is not null
and @sLongColumn is null
Begin
	Set @sSQLString =
		"select 	T."+@sShortColumn+CHAR(10)+
		", "+dbo.fn_SqlTranslationSelect(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as LongTranslation"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		dbo.fn_SqlTranslationFrom(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+
		"WHERE T."+@sShortColumn+" IS NOT NULL"+CHAR(10)

End

If @sShortColumn is null
and @sLongColumn is not null
Begin
	Set @sSQLString =
		"select 	T."+@sLongColumn+", "+CHAR(10)+
		dbo.fn_SqlTranslationSelect(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+" as LongTranslation"+CHAR(10)+
		"from	"+@sTableName+" T"+CHAR(10)+
		dbo.fn_SqlTranslationFrom(@sTableName,@sShortColumn,@sLongColumn,'T',@sCulture,@bCalledFromCentura)+
		"WHERE T."+@sLongColumn+" IS NOT NULL"+CHAR(10)+
		"AND T."+@sLongColumn+" NOT LIKE ''"

End

print 'Long .net sql: '
print @sSQLString

exec sp_executesql @sSQLString