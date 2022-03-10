-- This script assumes that the Excel content has been loaded into the database
-- using DTS into a table.
-- First it removes any obsolete versions of the translations provided
-- and then it loads the new translations where there is not already
-- a translation present.

-- 1. If necessary, do a global replace on TAB$ with the name of the table you are using
-- 2. Set the @sCulture variable to the appropriate value for the translations.
--    Refer to the database table CULTURE for a list of valid values.

Declare @sCulture nvarchar(10)
Declare @sTranslationsTable nvarchar(30)
Declare @bOverrideExisting bit

--			*** CHOOSE YOUR LANGUAGE HERE ***
-- DE = German
-- FR = French
-- PT-BR = Portuguese for Brazil
-- ZH_CHS = Chinese (simplified)
Set @sCulture='FR'
Set @sTranslationsTable = 'TEMPTRANSLATION'
Set @bOverrideExisting = 1

DECLARE @sSQLString NVARCHAR(MAX)

-- Remove existing translations
Set @sSQLString = 'DELETE TRANSLATEDTEXT
				FROM ' + @sTranslationsTable + ' I WHERE TID=I.ID
				AND CULTURE=@sCulture'
				
				if (@bOverrideExisting != 1)
					Set @sSQLString = @sSQLString + char(10) + 'AND HASSOURCECHANGED=1'

exec sp_executesql @sSQLString, 
					N'@sCulture		nvarchar(10)',
					@sCulture		= @sCulture

-- Insert translations
Set @sSQLString = 'INSERT INTO TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT, LONGTEXT, HASSOURCECHANGED)
					SELECT 	T.TID,
						@sCulture,
						case when LEN(Cast(I.Translation as nvarchar(4000))) <= 3200
							 then I.Translation
							 else NULL
						end,
						case when LEN(Cast(I.Translation as nvarchar(4000))) > 3200
							 then I.Translation
							 else NULL
						end,
						0
					-- DTS table
					FROM ' + @sTranslationsTable + ' I
					-- Make sure the translation ID is still there
					JOIN TRANSLATEDITEMS 	T ON (T.TID=I.ID)
					-- Check whether the data belongs in the short/long columns
					JOIN TRANSLATIONSOURCE 	S ON (S.TRANSLATIONSOURCEID=T.TRANSLATIONSOURCEID)'
					
					if (@bOverrideExisting != 1)
					Begin
						Set @sSQLString = @sSQLString + '
						-- Make sure the translation does not already exist
						left join TRANSLATEDTEXT TT ON (TT.TID=T.TID
										AND TT.CULTURE=@sCulture)'
					End
					
					Set @sSQLString = @sSQLString + char(10) + 'and I.Translation is not null'

exec sp_executesql @sSQLString, 
					N'@sCulture		nvarchar(10)',
					@sCulture		= @sCulture



Set @sSQLString = 'DROP TABLE ' + @sTranslationsTable
exec sp_executesql @sSQLString