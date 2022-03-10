-- This scriPT activates translation for all possible data.  This involves:
--	1. Mark all TranslationSource entries as InUse
--	2. Remove any obsolete translations caused by upgrades (TranslatedText.HasSourceChanged=1)
--	3. Generate TranslatedItem place holders for all translatable data
--	4. Generate translation test data for all translatable data for the following cultures:
--		4a. PT-BR
--		4b. PT
--		4c. ZH-CHS (simplified Chinese) - not available to client/server programs

set QUOTED_IDENTIFIER OFF

declare @nSourceID	int
declare	@sTableName	nvarchar(30)
declare	@sShortColumn	nvarchar(30)
declare @sLongColumn	nvarchar(30)
declare @sTIDColumn	nvarchar(30)
declare @nRowCount	int
declare	@sSQLString	nvarchar(4000)
declare @sCulture	nvarchar(10)

print 'Mark all TranslationSource entries as not in use so triggers do not fire'
update	TRANSLATIONSOURCE
set	INUSE=0

print 'Remove obsolete translations'
delete from TRANSLATEDTEXT
where	HASSOURCECHANGED=1

select 	@nSourceID = min(TRANSLATIONSOURCEID)
from	TRANSLATIONSOURCE

-- Process each translatable piece of data
While	(@nSourceID is not null)
begin

	select	@sTableName	= TABLENAME,
		@sShortColumn	= SHORTCOLUMN,
		@sLongColumn	= LONGCOLUMN,
		@sTIDColumn	= TIDCOLUMN
	FROM	TRANSLATIONSOURCE
	WHERE	TRANSLATIONSOURCEID = @nSourceID

	-- Generate TranslatedItems
	exec ip_PrepareForTranslation
		@pnRowCount		= @nRowCount output,
		@psTableName		= @sTableName,
		@psTIDColumn		= @sTIDColumn
	print cast(@nRowCount as nvarchar)+' Translated Items created for '+@sTableName+'.'+@sTIDColumn

	-- Generated translations of short source data are always placed in TranslatedText.ShortText, truncating if necessary.
	If @sShortColumn is not null
	begin
		print 'Processing short column for '+@sTableName+'.'+@sShortColumn+'...'
		Set @sSQLString = 
		"insert into TRANSLATEDTEXT (TID,CULTURE,SHORTTEXT)"+CHAR(10)+
		"select T."+@sTIDColumn+", @sCulture, cast(@sCulture+
			SPACE(1)+T."+@sShortColumn+" as nvarchar(3900))"+CHAR(10)+
		"from 	"+@sTableName+" T"+CHAR(10)+
		"where T."+@sShortColumn+" is not null"+char(10)+
		"and T."+@sTIDColumn+" is not null "+char(10)+
		"and	not exists"+CHAR(10)+
		"	(select 1"+CHAR(10)+
		"	from 	TRANSLATEDTEXT T1"+CHAR(10)+
		"	where	T1.TID=T."+@sTIDColumn+CHAR(10)+
		"	and	T1.CULTURE=@sCulture)"+CHAR(10)

		set @sCulture = 'PT-BR'
		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

		set @sCulture = 'PT'
		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

		set @sCulture = 'ZH-CHS'
		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

	end

	if @sLongColumn is not null
	begin	
		-- Generated translations from ntext columns that are up to 3,900 characters are stored in TranslatedText.ShortText
		print 'Processing ntext as nvarchar for '+@sTableName+'.'+@sLongColumn+'...'

		Set @sSQLString = 
		"insert into TRANSLATEDTEXT (TID,CULTURE,SHORTTEXT)"+CHAR(10)+
		"select 	T."+@sTIDColumn+", @sCulture, cast(@sCulture+SPACE(1)+cast(T."+@sLongColumn+" as nvarchar(4000)) as nvarchar(3900))"+CHAR(10)+
		"from 	"+@sTableName+" T"+CHAR(10)+
		"where 	T."+@sLongColumn+" is not null"+CHAR(10)+
		-- The data stored in the ntext is within the 3,900 character limit (less the generated translation prefix)
		"AND 	len(cast(T."+@sLongColumn+" as nvarchar(4000))) between 1 and (3900 - (len(@sCulture)+1))"+char(10)+
		"and T."+@sTIDColumn+" is not null "+char(10)+
		"and	not exists"+CHAR(10)+
		"	(select 1"+CHAR(10)+
		"	from 	TRANSLATEDTEXT T1"+CHAR(10)+
		"	where	T1.TID=T."+@sTIDColumn+CHAR(10)+
		"	and	T1.CULTURE=@sCulture)"+CHAR(10)

		set @sCulture = 'PT-BR'
		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

		set @sCulture = 'PT'
		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

		set @sCulture = 'ZH-CHS'
		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

	end

	if @sLongColumn is not null
	begin
		-- Generated translations greater than 3,900 characters are stored in TranslatedText.LongText.
		print 'Processing ntext for '+@sTableName+'.'+@sLongColumn+'...'

		Set @sSQLString = 
		"insert into TRANSLATEDTEXT (TID,CULTURE,LONGTEXT)"+CHAR(10)+
		"select 	T."+@sTIDColumn+", @sCulture, cast(@sCulture+SPACE(1)+"+" CAST(T."+@sLongColumn+" AS NVARCHAR(4000)) as NTEXT)"+CHAR(10)+
		"from 	"+@sTableName+" T"+CHAR(10)+
		"where 	T."+@sTIDColumn+" IS NOT NULL"+CHAR(10)+
		"AND    T."+@sLongColumn+" is not null"+CHAR(10)+
		-- The data stored in the ntext greater than the 3,900 character limit (less the generated translation prefix)
		"AND    len(cast(T."+@sLongColumn+" as nvarchar(4000))) > (3900 - (len(@sCulture)+1))"+CHAR(10)+
		"and	not exists"+CHAR(10)+
		"	(select 1"+CHAR(10)+
		"	from 	TRANSLATEDTEXT T1"+CHAR(10)+
		"	where	T1.TID=T."+@sTIDColumn+CHAR(10)+
		"	and	T1.CULTURE=@sCulture)"+CHAR(10)

		set @sCulture = 'PT-BR'
		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

		set @sCulture = 'PT'
		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

		set @sCulture = 'ZH-CHS'
		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture
	end
		
	select 	@nSourceID = min(TRANSLATIONSOURCEID)
	from	TRANSLATIONSOURCE
	where	TRANSLATIONSOURCEID > @nSourceID
end

print 'Mark all TranslationSource entries as in use'
update	TRANSLATIONSOURCE
set	INUSE=1

go