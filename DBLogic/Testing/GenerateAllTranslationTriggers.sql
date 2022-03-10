set nocount on

-- This script accesses the TranslationSource rules on the database and generates
-- the triggers necessary to manage this data.

-- 1. Apply util_GenerateTranslationTriggers.sql to the database.
-- 2. Ensure that the TranslationSource table contains the data to be managed.
-- 3. Set your query analyser settings to Results in Text
-- 4. Run this script.
-- 5. Copy the output to a new screen.
-- 6. Save the new script as alltrigstranslation.sql
-- 7. Run the script.

declare @sTableName	nvarchar(30)


select @sTableName=min(TABLENAME) 
from TRANSLATIONSOURCE

WHILE @sTableName is not null
Begin
	exec dbo.util_GenerateTranslationTriggers @sTableName

	select @sTableName=min(TABLENAME) 
	from TRANSLATIONSOURCE
	where TABLENAME>@sTableName
End

