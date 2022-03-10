-- This script accesses the TranslationSource rules on the database and generates
-- the statements necessary to insert dummy translations for all translatable
-- data on your database that do not have translations already.


-- 1. Ensure that the TranslationSource columns you wish to use have been marked as InUse.
-- 2. Set your query analyser settings to Results in Text
-- 3. Set the culture you require below:
declare @sCulture	nvarchar(10)
Set @sCulture = 'de-at'
-- 4. Run this script.
-- 5. Copy the output to a new screen.
-- 6. Save the new script.
-- 7. Run the script.

set quoted_identifier off
set nocount on
set concat_null_yields_null off

-- Generated translations of short source data are always placed in TranslatedText.ShortText, truncating if necessary.
select
"print '-------------- Insert Test Data - short column'"+CHAR(10)+
"print 'Processing "+S.TABLENAME+"."+S.SHORTCOLUMN+"...'"+CHAR(10)+
"GO"+CHAR(10)+
CHAR(10)+
"declare @StartTime as datetime"+CHAR(10)+
"set @StartTime = getdate()"+CHAR(10)+
CHAR(10)+
"insert into TRANSLATEDTEXT (TID,CULTURE,SHORTTEXT)"+CHAR(10)+
"select 	T."+S.TIDCOLUMN+", "+dbo.fn_WrapQuotes(upper(@sCulture),0,0)+", cast("+dbo.fn_WrapQuotes(upper(@sCulture),0,0)+
		"+SPACE(1)+T."+S.SHORTCOLUMN+" as nvarchar(3900))"+CHAR(10)+
"from 	"+S.TABLENAME+" T"+CHAR(10)+
"where T."+S.SHORTCOLUMN+" is not null"+char(10)+
"and T."+S.TIDCOLUMN+" is not null "+char(10)+
"and	not exists"+CHAR(10)+
"	(select 1"+CHAR(10)+
"	from 	TRANSLATEDTEXT T1"+CHAR(10)+
"	where	T1.TID=T."+S.TIDCOLUMN+CHAR(10)+
"	and	T1.CULTURE="+dbo.fn_WrapQuotes(upper(@sCulture),0,0)+")"+CHAR(10)+

"print 'Elapsed time: '+cast(datediff(s,@StartTime, getdate()) as nvarchar)+ ' secs'"+CHAR(10)+
"GO"+CHAR(10)
from TRANSLATIONSOURCE S
WHERE 	S.INUSE = 1
and	S.SHORTCOLUMN IS NOT NULL
ORDER BY S.TABLENAME, S.SHORTCOLUMN

-- Generated translations from ntext columns that are up to 3,900 characters are stored in TranslatedText.ShortText
select
"print '-------------- Insert Test Data - ntext as short column'"+CHAR(10)+
"print 'Processing "+S.TABLENAME+"."+S.LONGCOLUMN+"...'"+CHAR(10)+
"GO"+CHAR(10)+
CHAR(10)+
"declare @StartTime as datetime"+CHAR(10)+
"set @StartTime = getdate()"+CHAR(10)+
CHAR(10)+
"insert into TRANSLATEDTEXT (TID,CULTURE,SHORTTEXT)"+CHAR(10)+
"select 	T."+S.TIDCOLUMN+", "+dbo.fn_WrapQuotes(upper(@sCulture),0,0)+", cast("+
		dbo.fn_WrapQuotes(upper(@sCulture),0,0)+"+SPACE(1)+cast(T."+S.LONGCOLUMN+" as nvarchar(4000)) as nvarchar(3900))"+CHAR(10)+
"from 	"+S.TABLENAME+" T"+CHAR(10)+
"where 	T."+S.LONGCOLUMN+" is not null"+CHAR(10)+
-- The data stored in the ntext is within the 3,900 character limit (less the generated translation prefix)
"AND 	len(cast(T."+S.LONGCOLUMN+" as nvarchar(4000))) between 1 and (3900 - (len("+dbo.fn_WrapQuotes(upper(@sCulture),0,0)+")+1))"+char(10)+
"and T."+S.TIDCOLUMN+" is not null "+char(10)+
"and	not exists"+CHAR(10)+
"	(select 1"+CHAR(10)+
"	from 	TRANSLATEDTEXT T1"+CHAR(10)+
"	where	T1.TID=T."+S.TIDCOLUMN+CHAR(10)+
"	and	T1.CULTURE="+dbo.fn_WrapQuotes(upper(@sCulture),0,0)+")"+CHAR(10)+

"print 'Elapsed time: '+cast(datediff(s,@StartTime, getdate()) as nvarchar)+ ' secs'"+CHAR(10)+
"GO"+CHAR(10)
from TRANSLATIONSOURCE S
WHERE 	S.INUSE = 1
and	S.LONGCOLUMN IS NOT NULL
ORDER BY S.TABLENAME, S.LONGCOLUMN

-- Generated translations greater than 3,900 characters are stored in TranslatedText.LongText.
select
"print '-------------- Insert Test Data - ntext as long column'"+CHAR(10)+
"print 'Processing "+S.TABLENAME+"."+S.LONGCOLUMN+"...'"+CHAR(10)+
"GO"+CHAR(10)+
CHAR(10)+
"declare @StartTime as datetime"+CHAR(10)+
"set @StartTime = getdate()"+CHAR(10)+
CHAR(10)+
"insert into TRANSLATEDTEXT (TID,CULTURE,LONGTEXT)"+CHAR(10)+
"select 	T."+S.TIDCOLUMN+", "+dbo.fn_WrapQuotes(upper(@sCulture),0,0)+", cast("+dbo.fn_WrapQuotes(upper(@sCulture),0,0)+"+SPACE(1)+"+" CAST(T."+S.LONGCOLUMN+" AS NVARCHAR(4000)) as NTEXT)"+CHAR(10)+
"from 	"+S.TABLENAME+" T"+CHAR(10)+
"where 	T."+S.TIDCOLUMN+" IS NOT NULL"+CHAR(10)+
"AND    T."+S.LONGCOLUMN+" is not null"+CHAR(10)+
-- The data stored in the ntext greater than the 3,900 character limit (less the generated translation prefix)
"AND    len(cast(T."+S.LONGCOLUMN+" as nvarchar(4000))) > (3900 - (len("+dbo.fn_WrapQuotes(upper(@sCulture),0,0)+")+1))"+CHAR(10)+
"and	not exists"+CHAR(10)+
"	(select 1"+CHAR(10)+
"	from 	TRANSLATEDTEXT T1"+CHAR(10)+
"	where	T1.TID=T."+S.TIDCOLUMN+CHAR(10)+
"	and	T1.CULTURE="+dbo.fn_WrapQuotes(upper(@sCulture),0,0)+")"+CHAR(10)+

"print 'Elapsed time: '+cast(datediff(s,@StartTime, getdate()) as nvarchar)+ ' secs'"+CHAR(10)+
"GO"+CHAR(10)
from TRANSLATIONSOURCE S
WHERE 	S.INUSE = 1
AND	S.LONGCOLUMN IS NOT NULL
ORDER BY S.TABLENAME, S.SHORTCOLUMN, S.LONGCOLUMN