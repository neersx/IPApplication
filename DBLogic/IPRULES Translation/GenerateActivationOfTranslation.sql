-- This script generates scripting to activate translation for any translatable
-- data structures that contains data.
--
-- Translation is not activated directly so that the user can choose which data
-- structures to translate by editing the script produced.
--
-- To use this script:
-- 1. Set your query analyser settings to Results in Text
-- 2. Set a specific @sTable and @sColumn you want to make translatable (Optional)
-- 3. Run this script.
-- 3. Copy the output to a new screen.
-- 4. Edit the script to remove any structures you don't want to translate
-- 5. Run the script.
--
--
-- The scripting generated performs the following steps:
--	1. Turn on the TRANSLATIONSOURCE entry (INUSE=1).
--	2. Generate TranslatedItem place holders

set QUOTED_IDENTIFIER OFF
set NOCOUNT ON

declare @sTable nvarchar(30)
declare @sColumn NVARCHAR(30)

Set @sTable = 'NAMETYPE'
Set @sColumn = 'DESCRIPTION'

declare @nErrorCode	int
declare @nSourceID	int
declare	@sTableName	nvarchar(30)
declare	@sShortColumn	nvarchar(30)
declare @sLongColumn	nvarchar(30)
declare @sTIDColumn	nvarchar(30)
declare @nRowCount	int
declare	@sSQLString	nvarchar(4000)

Set @nErrorCode = 0

if @sColumn = ''
	select '-- Edit this script to activate only the data structures you are interested in'

select 	@nSourceID = min(TRANSLATIONSOURCEID)
from	TRANSLATIONSOURCE
where	INUSE=0
and (@sTable = '' or TABLENAME = @sTable)
and (@sColumn= '' or ISNULL(SHORTCOLUMN,LONGCOLUMN) = @sColumn)

-- Process each translatable piece of data
While	(@nSourceID is not null)
and	(@nErrorCode=0)
begin

	select	@sTableName	= TABLENAME,
		@sShortColumn	= SHORTCOLUMN,
		@sLongColumn	= LONGCOLUMN,
		@sTIDColumn	= TIDCOLUMN
	FROM	TRANSLATIONSOURCE
	WHERE	TRANSLATIONSOURCEID = @nSourceID

	Set @nErrorCode=@@ERROR

	-- Check whether there is any data on the database
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 
		"select @nRowCount=count(*)
		from 	"+@sTableName
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nRowCount		int OUTPUT',
			  @nRowCount		= @nRowCount output
	End

	If @nErrorCode=0
	and @nRowCount>0
	Begin

		-- Turn on translation
		Select "print 'Activating translation for "+@sTableName+'.'+isnull(@sShortColumn,@sLongColumn)+"'

		UPDATE TRANSLATIONSOURCE
		SET INUSE=1
		WHERE TRANSLATIONSOURCEID="+cast(@nSourceID as nvarchar)+"

		exec ip_PrepareForTranslation
			@psTableName		= '"+@sTableName+"',
			@psTIDColumn		= '"+@sTIDColumn+"'"

		Set @nErrorCode=@@ERROR
	End
	
	select 	@nSourceID = min(TRANSLATIONSOURCEID)
	from	TRANSLATIONSOURCE
	where	TRANSLATIONSOURCEID > @nSourceID
	and	INUSE=0
	
	
	if ISNULL(@sColumn,'') = ''
		select 	@nSourceID = min(TRANSLATIONSOURCEID)
		from	TRANSLATIONSOURCE
		where	INUSE=0
		AND	TRANSLATIONSOURCEID > @nSourceID
		and (@sTable = '' or TABLENAME = @sTable)
	else
		SET @nSourceID = NULL

	Set @nErrorCode=@@ERROR

end

go