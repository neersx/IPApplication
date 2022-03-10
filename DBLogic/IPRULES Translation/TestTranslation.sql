-- This script tests that no errors occur when a particular translation is
-- switech to the main language fo the database.  This involves:
--	1. Generate dummy translations for any data that is not already translated
--	2. Switch the translation to be the main language for the database
--
-- This is currently performed for Culture=DE only.
-- Update culture variables below to extend for other languages.

set QUOTED_IDENTIFIER OFF

declare @nSourceID	int
declare	@sTableName	nvarchar(30)
declare	@sShortColumn	nvarchar(30)
declare @sLongColumn	nvarchar(30)
declare @sTIDColumn	nvarchar(30)
declare @nRowCount	int
declare	@sSQLString	nvarchar(4000)
declare @sCulture	nvarchar(10)
declare @sCulture2	nvarchar(10)
declare @sCulture3	nvarchar(10)
declare @nErrorCode	int

set @sCulture='DE'
-- Set these as more languages are supported
set @sCulture2=null
set @sCulture3=null

set @nErrorCode = 0

-- Generate dummy translations where necessary
select 	@nSourceID = min(TRANSLATIONSOURCEID)
from	TRANSLATIONSOURCE
where	INUSE=1

-- Process each translatable piece of data
While	(@nSourceID is not null)
begin

	select	@sTableName	= TABLENAME,
		@sShortColumn	= SHORTCOLUMN,
		@sLongColumn	= LONGCOLUMN,
		@sTIDColumn	= TIDCOLUMN
	FROM	TRANSLATIONSOURCE
	WHERE	TRANSLATIONSOURCEID = @nSourceID

	-- Generated translations of short source data are always placed in TranslatedText.ShortText, truncating if necessary.
	If @sShortColumn is not null
	begin
		print 'Generating translations short column for '+@sTableName+'.'+@sShortColumn+'...'
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

		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

		If @sCulture2 is not null
		Begin
			exec sp_executesql @sSQLString,
				N'@sCulture		nvarchar(10)',
				  @sCulture		= @sCulture2
		End

		If @sCulture3 is not null
		Begin
			exec sp_executesql @sSQLString,
				N'@sCulture		nvarchar(10)',
				  @sCulture		= @sCulture3
		End

	end

	if @sLongColumn is not null
	begin	
		-- Generated translations from ntext columns that are up to 3,900 characters are stored in TranslatedText.ShortText
		print 'Generating translations ntext as nvarchar for '+@sTableName+'.'+@sLongColumn+'...'

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

		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

		If @sCulture2 is not null
		Begin
			exec sp_executesql @sSQLString,
				N'@sCulture		nvarchar(10)',
				  @sCulture		= @sCulture2
		End

		If @sCulture3 is not null
		Begin
			exec sp_executesql @sSQLString,
				N'@sCulture		nvarchar(10)',
				  @sCulture		= @sCulture3
		End
	end

	if @sLongColumn is not null
	begin
		-- Generated translations greater than 3,900 characters are stored in TranslatedText.LongText.
		print 'Generating translations ntext for '+@sTableName+'.'+@sLongColumn+'...'

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

		exec sp_executesql @sSQLString,
			N'@sCulture		nvarchar(10)',
			  @sCulture		= @sCulture

		If @sCulture2 is not null
		Begin
			exec sp_executesql @sSQLString,
				N'@sCulture		nvarchar(10)',
				  @sCulture		= @sCulture2
		End

		If @sCulture3 is not null
		Begin
			exec sp_executesql @sSQLString,
				N'@sCulture		nvarchar(10)',
				  @sCulture		= @sCulture3
		End

	end
		
	select 	@nSourceID = min(TRANSLATIONSOURCEID)
	from	TRANSLATIONSOURCE
	where	TRANSLATIONSOURCEID > @nSourceID
	and	INUSE=1
end

-- Switch the culture in as the main translation
print 'Switching to language '+@sCulture
exec @nErrorCode=ip_SwitchDatabaseLanguage
	@psSwtichOutCulture='EN',
	@psSwitchInCulture=@sCulture

If @sCulture2 is not null
and @nErrorCode = 0
Begin
	print 'Switching to language '+@sCulture2
	exec @nErrorCode=ip_SwitchDatabaseLanguage
		@psSwtichOutCulture=@sCulture,
		@psSwitchInCulture=@sCulture2
End

If @sCulture3 is not null
and @nErrorCode = 0
Begin
	print 'Switching to language '+@sCulture3
	exec @nErrorCode=ip_SwitchDatabaseLanguage
		@psSwtichOutCulture=@sCulture2,
		@psSwitchInCulture=@sCulture3
End

go