---------------------------------------------------------------------------------------------
-- Creation of dbo.pt_GetDocItemSql
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pt_GetDocItemSql]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pt_GetDocItemSql.'
	drop procedure [dbo].[pt_GetDocItemSql]
	Print '**** Creating Stored Procedure dbo.pt_GetDocItemSql...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.pt_GetDocItemSql
(
	@psSegment1		nvarchar (4000)	= null	output,	-- Segments of the SQL statement that may be concatenated together for execution.
	@psSegment2		nvarchar (4000)	= null	output,	
	@psSegment3		nvarchar (4000)	= null	output,
	@psSegment4		nvarchar (4000)	= null	output,
	@psSegment5		nvarchar (4000)	= null	output,	
	@psSegment6		nvarchar (4000)	= null	output,	
	@psSegment7		nvarchar (4000)	= null	output,	
	@psSegment8		nvarchar (4000)	= null	output,	
	@psSegment9		nvarchar (4000)	= null	output,	
	@psSegment10		nvarchar (4000)	= null	output,	
	@pnUserIdentityId	int,				-- Mandatory
	@pnDocItemKey		int,				-- Mandatory. The doc item to be extracted.
	@psSearchText1		nvarchar (254)  = null,		-- Text embedded within the doc item’s SQL statement that is to be replaced; e.g. :gstrEntryPoint
	@psReplacementText1	nvarchar (254)	= null,		-- The text that is to be substituted in the SQL statement in place of @psSearchText1.  Note: that the replacement text will be embedded exactly as supplied. If you are substituting a literal value, it must be supplied wrapped in quotes; e.g. N'1234/A'.
	@psSearchText2		nvarchar (254)	= null,	
	@psReplacementText2	nvarchar (254)	= null,	
	@psSearchText3		nvarchar (254)	= null,	
	@psReplacementText3	nvarchar (254)	= null,	
	@psSearchText4		nvarchar (254)	= null,	
	@psReplacementText4	nvarchar (254)	= null,	
	@psSearchText5		nvarchar (254)	= null,	
	@psReplacementText5	nvarchar (254)	= null	
)
AS
-- PROCEDURE:	pt_GetDocItemSql
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	This stored procedure extracts the SQL from the database, substitutes in 
--		any parameters necessary, and breaks the statement up into segments ready 
--		for execution.  It also allows for substitution of up to 5 pieces of text 
--		within the statement; e.g. replace :gstrEntryPoint with '1234/A'.

--		Doc Items are self-contained SQL statements that are run, often using parameters.  
--		These statements can be quite long, requiring them to be stored as long text.
--		In order to run a long text statement from a stored procedure, it is necessary 
--		to break it up into short text segments so that they can be executed as follows:
--		Exec @sSegment1 + @sSegment2 + @sSegment3 etc.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 13 May 2005  TM	RFC2554	1	Procedure created
-- 08 Jun 2005	JEK	RFC2690	2	Handle SQL_QUERY column of type text as well as ntext

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare	@sSQLString		nvarchar(4000)
Declare @sTempTableName		nvarchar(50)
Declare @nDocItemLength		int
Declare @nSqlQueryDivisor	tinyint

Declare @ptrval 		varbinary(16)
Declare @nCurrentPatindex 	int
Declare @nRemainingTextLength 	int

Declare @nLenghtOfSearchText1	smallint
Declare @nLenghtOfSearchText2	smallint
Declare @nLenghtOfSearchText3	smallint
Declare @nLenghtOfSearchText4	smallint
Declare @nLenghtOfSearchText5	smallint

Declare @sUserSQL		nvarchar(4000)	-- Hold DocItem SQL that is less than 4000 characters.

-- Initialise variables
Set	@nErrorCode      	= 0
Set 	@sTempTableName	 	= '##DocItemTempTable' + Cast(@@SPID as varchar(10))

Set 	@nLenghtOfSearchText1	= len(@psSearchText1)
Set 	@nLenghtOfSearchText2	= len(@psSearchText2)
Set 	@nLenghtOfSearchText3	= len(@psSearchText3)
Set 	@nLenghtOfSearchText4	= len(@psSearchText4)
Set 	@nLenghtOfSearchText5	= len(@psSearchText5)

Set 	@psReplacementText1	= CASE WHEN @psReplacementText1 IS NOT NULL THEN @psReplacementText1 + char(10) END
Set 	@psReplacementText2	= CASE WHEN @psReplacementText2 IS NOT NULL THEN @psReplacementText2 + char(10) END
Set 	@psReplacementText3	= CASE WHEN @psReplacementText3 IS NOT NULL THEN @psReplacementText3 + char(10) END
Set 	@psReplacementText4	= CASE WHEN @psReplacementText4 IS NOT NULL THEN @psReplacementText4 + char(10) END
Set 	@psReplacementText5	= CASE WHEN @psReplacementText5 IS NOT NULL THEN @psReplacementText5 + char(10) END

-- To calculate length for ntext, we need to divide datalength by 2
-- but for text we do not
If exists (select 1 
	from INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = 'ITEM' 
	and COLUMN_NAME = 'SQL_QUERY'
	and DATA_TYPE = 'text')
Begin
	Set @nSqlQueryDivisor = 1
End
Else
Begin
	Set @nSqlQueryDivisor = 2
End

-- Get the length DocItem SQl:
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  @nDocItemLength = datalength(SQL_QUERY)/@nSqlQueryDivisor,
		@sUserSQL  	= convert(nvarchar(4000),SQL_QUERY)
	from ITEM
	where ITEM_ID = @pnDocItemKey"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nDocItemLength	int			output,
					  @sUserSQL		nvarchar(4000)		output,
					  @pnDocItemKey		int,
					  @nSqlQueryDivisor	tinyint',
					  @nDocItemLength	= @nDocItemLength	output,
					  @sUserSQL		= @sUserSQL		output,
					  @pnDocItemKey		= @pnDocItemKey,
					  @nSqlQueryDivisor	= @nSqlQueryDivisor
End	

If @nDocItemLength <=4000
Begin
	-- Replace any occurrences of @psSearchTextX in the DocItem SQL string 
	-- with the replacement text @psReplacementTextX:

	If @psSearchText1 is not null
	Begin
		Set @sUserSQL  = replace(@sUserSQL,@psSearchText1, @psReplacementText1)	
	End

	If @psSearchText2 is not null
	Begin	
		Set @sUserSQL  = replace(@sUserSQL,@psSearchText2, @psReplacementText2)	
	End

	If @psSearchText3 is not null
	Begin
		Set @sUserSQL  = replace(@sUserSQL,@psSearchText3, @psReplacementText3)	
	End

	If @psSearchText4 is not null
	Begin
		Set @sUserSQL  = replace(@sUserSQL,@psSearchText4, @psReplacementText4)	
	End

	If @psSearchText5 is not null
	Begin
		Set @sUserSQL  = replace(@sUserSQL,@psSearchText5, @psReplacementText5)	
	End	

	Set @psSegment1 = @sUserSQL
End
Else
-- Handling the long Doc Items
If @nErrorCode = 0
Begin		
	-- Create temporary table to hold any DocItem SQL that is longer
	-- than 4000 characters:

	If exists(select * from tempdb.dbo.sysobjects where name = @sTempTableName)
	Begin
		Set @sSQLString = "Drop table " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString 
	End
	
	Set @sSQLString = "Create table " + @sTempTableName + " (DocItemText ntext)"

	exec @nErrorCode = sp_executesql @sSQLString 
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Insert into " + @sTempTableName + " (DocItemText)
		select SQL_QUERY
		from ITEM
		where ITEM_ID = @pnDocItemKey"

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnDocItemKey	int',
						  @pnDocItemKey	= @pnDocItemKey
	End	

	-- Get the text pointer to the text column:
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @ptrval = TEXTPTR(DocItemText) 
		from " + @sTempTableName
	
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@ptrval	varbinary(16)	OUTPUT',
				  @ptrval	= @ptrval	OUTPUT
	End

	-- 1) Replace any occurrences of @psSearchText1 in the DocItem SQL string 
	-- with the replacement text @psReplacementText1.
	If @psSearchText1 is not null
	Begin	
		-- Get the first location of the @psSearchText1 in the DocItem SQL:
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = 
				"Select @nCurrentPatindex = patindex('%"+@psSearchText1+"%', DocItemText)-1
				from " + @sTempTableName
		
				exec @nErrorCode = sp_executesql @sSQLString,
						N'@nCurrentPatindex	int			OUTPUT',
						  @nCurrentPatindex	= @nCurrentPatindex	OUTPUT
		End

		-- Loop through the DocItem SQL and find and replace all occurrences of the @psSearchText1
		-- in the DocItem SQL.	
		While @nCurrentPatindex > 0 
		and @nCurrentPatindex is not null
		Begin	
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval @nCurrentPatindex @nLenghtOfSearchText1 @psReplacementText1"
	
				exec @nErrorCode = sp_executesql @sSQLString,
					N'@ptrval		varbinary(16),
					  @nCurrentPatindex	int,
					  @nLenghtOfSearchText1	smallint,
					  @psReplacementText1	nvarchar(254)',
					  @ptrval		= @ptrval,
					  @nCurrentPatindex	= @nCurrentPatindex,
					  @nLenghtOfSearchText1	= @nLenghtOfSearchText1,
					  @psReplacementText1	= @psReplacementText1
			End

			-- Get the next location of the @psSearchText1 in the DocItem SQL:
	
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = 
				"Select @nCurrentPatindex = patindex('%"+@psSearchText1+"%', DocItemText)-1
				FROM " + @sTempTableName
				
				exec @nErrorCode = sp_executesql @sSQLString,
							N'@nCurrentPatindex	int			OUTPUT',
							  @nCurrentPatindex	= @nCurrentPatindex	OUTPUT
			End		
		End
	End

	-- 2) Replace any occurrences of @psSearchText2 in the DocItem SQL string 
	-- with the replacement text @psReplacementText2.

	If @psSearchText2 is not null
	Begin
		-- Get the first location of the @psSearchText2 in the DocItem SQL:
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = 
				"Select @nCurrentPatindex = patindex('%"+@psSearchText2+"%', DocItemText)-1
				from " + @sTempTableName
		
				exec @nErrorCode = sp_executesql @sSQLString,
						N'@nCurrentPatindex	int			OUTPUT',
						  @nCurrentPatindex	= @nCurrentPatindex	OUTPUT
		End

		-- Loop through the DocItem SQL and find and replace all occurrences of the @psSearchText2
		-- in the DocItem SQL.	
		While @nCurrentPatindex > 0 
		and @nCurrentPatindex is not null
		Begin	
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval @nCurrentPatindex @nLenghtOfSearchText2 @psReplacementText2"
	
				exec @nErrorCode = sp_executesql @sSQLString,
					N'@ptrval		varbinary(16),
					  @nCurrentPatindex	int,
					  @nLenghtOfSearchText2	smallint,
					  @psReplacementText2	nvarchar(254)',
					  @ptrval		= @ptrval,
					  @nCurrentPatindex	= @nCurrentPatindex,
					  @nLenghtOfSearchText2	= @nLenghtOfSearchText2,
					  @psReplacementText2	= @psReplacementText2
			End

			-- Get the next location of the @psSearchText2 in the DocItem SQL:	
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = 
				"Select @nCurrentPatindex = patindex('%"+@psSearchText2+"%', DocItemText)-1
				FROM " + @sTempTableName
				
				exec @nErrorCode = sp_executesql @sSQLString,
							N'@nCurrentPatindex	int			OUTPUT',
							  @nCurrentPatindex	= @nCurrentPatindex	OUTPUT
			End		
		End
	End

	-- 3) Replace any occurrences of @psSearchText3 in the DocItem SQL string 
	-- with the replacement text @psReplacementText3.

	If @psSearchText3 is not null
	Begin
		-- Get the first location of the @psSearchText3 in the DocItem SQL:
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "
				Select @nCurrentPatindex = patindex('%"+@psSearchText3+"%', DocItemText)-1
				from " + @sTempTableName
		
				exec @nErrorCode = sp_executesql @sSQLString,
						N'@nCurrentPatindex	int			OUTPUT',
						  @nCurrentPatindex	= @nCurrentPatindex	OUTPUT
		End

		-- Loop through the DocItem SQL and find and replace all occurrences of the @psSearchText3
		-- in the DocItem SQL.				
		While @nCurrentPatindex > 0 
		and @nCurrentPatindex is not null
		Begin	
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval @nCurrentPatindex @nLenghtOfSearchText3 @psReplacementText3"
	
				exec @nErrorCode = sp_executesql @sSQLString,
					N'@ptrval		varbinary(16),
					  @nCurrentPatindex	int,
					  @nLenghtOfSearchText3	smallint,
					  @psReplacementText3	nvarchar(254)',
					  @ptrval		= @ptrval,
					  @nCurrentPatindex	= @nCurrentPatindex,
					  @nLenghtOfSearchText3	= @nLenghtOfSearchText3,
					  @psReplacementText3	= @psReplacementText3
			End
	
			-- Get the next location of the @psSearchText3 in the DocItem SQL:	
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = 
				"Select @nCurrentPatindex = patindex('%"+@psSearchText3+"%', DocItemText)-1
				FROM " + @sTempTableName
				
				exec @nErrorCode = sp_executesql @sSQLString,
							N'@nCurrentPatindex	int			OUTPUT',
							  @nCurrentPatindex	= @nCurrentPatindex	OUTPUT
			End		
		End
	End

	-- 4) Replace any occurrences of @psSearchText4 in the DocItem SQL string 
	-- with the replacement text @psReplacementText4.

	If @psSearchText4 is not null
	Begin
		-- Get the first location of the @psSearchText4 in the DocItem SQL:
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = 
				"Select @nCurrentPatindex = patindex('%"+@psSearchText4+"%', DocItemText)-1
				from " + @sTempTableName
		
				exec @nErrorCode = sp_executesql @sSQLString,
						N'@nCurrentPatindex	int			OUTPUT',
						  @nCurrentPatindex	= @nCurrentPatindex	OUTPUT
		End

		-- Loop through the DocItem SQL and find and replace all occurrences of the @psSearchText4
		-- in the DocItem SQL.			
		While @nCurrentPatindex > 0 
		and @nCurrentPatindex is not null
		Begin	
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval @nCurrentPatindex @nLenghtOfSearchText4 @psReplacementText4"
	
				exec @nErrorCode = sp_executesql @sSQLString,
					N'@ptrval		varbinary(16),
					  @nCurrentPatindex	int,
					  @nLenghtOfSearchText4	smallint,
					  @psReplacementText4	nvarchar(254)',
					  @ptrval		= @ptrval,
					  @nCurrentPatindex	= @nCurrentPatindex,
					  @nLenghtOfSearchText4	= @nLenghtOfSearchText4,
					  @psReplacementText4	= @psReplacementText4
			End
	
			-- Get the next location of the @psSearchText4 in the DocItem SQL:	
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = 
				"Select @nCurrentPatindex = patindex('%"+@psSearchText4+"%', DocItemText)-1
				FROM " + @sTempTableName
				
				exec @nErrorCode = sp_executesql @sSQLString,
							N'@nCurrentPatindex	int			OUTPUT',
							  @nCurrentPatindex	= @nCurrentPatindex	OUTPUT
			End		
		End
	End

	-- 5) Replace any occurrences of @psSearchText5 in the DocItem SQL string 
	-- with the replacement text @psReplacementText5.

	If @psSearchText5 is not null
	Begin
		-- Get the first location of the @psSearchText5 in the DocItem SQL:
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = 
				"Select @nCurrentPatindex = patindex('%"+@psSearchText5+"%', DocItemText)-1
				from " + @sTempTableName
		
				exec @nErrorCode = sp_executesql @sSQLString,
						N'@nCurrentPatindex	int			OUTPUT',
						  @nCurrentPatindex	= @nCurrentPatindex	OUTPUT
		End

		-- Loop through the DocItem SQL and find and replace all occurrences of the @psSearchText5
		-- in the DocItem SQL.			
		While @nCurrentPatindex > 0 
		and @nCurrentPatindex is not null
		Begin	
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval @nCurrentPatindex @nLenghtOfSearchText5 @psReplacementText5"
	
				exec @nErrorCode = sp_executesql @sSQLString,
					N'@ptrval		varbinary(16),
					  @nCurrentPatindex	int,
					  @nLenghtOfSearchText5	smallint,
					  @psReplacementText5	nvarchar(254)',
					  @ptrval		= @ptrval,
					  @nCurrentPatindex	= @nCurrentPatindex,
					  @nLenghtOfSearchText5	= @nLenghtOfSearchText5,
					  @psReplacementText5	= @psReplacementText5
			End
	
			-- Get the next location of the @psSearchText5 in the DocItem SQL:	
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = 
				"Select @nCurrentPatindex =  patindex('%"+@psSearchText5+"%', DocItemText)-1
				FROM " + @sTempTableName
				
				exec @nErrorCode = sp_executesql @sSQLString,
							N'@nCurrentPatindex	int			OUTPUT',
							  @nCurrentPatindex	= @nCurrentPatindex	OUTPUT
			End		
		End
	End

	-- Cut the existing DocItem SQL into required quantity (up to 10) of nvarchar(4000) strings
	-- and store them into the @psSegmentX output parameters:

	-- Note: All 10 possible segments have the same processing logic.

	If @nErrorCode = 0
	Begin		
		-- Find the length of the remaining DocItem text:
		Set @sSQLString = "
		Select @nRemainingTextLength = 	ISNULL(CASE 	WHEN DATALENGTH(DocItemText) < 8000 
								-- Get the exact length as 'UPDATETEXT' 
								-- statement produces an SQL error if
								-- delete length is out of range:
								THEN DATALENGTH(DocItemText)/2 
								ELSE 4000
						       END, 0)
		from " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nRemainingTextLength	int			OUTPUT',
						  @nRemainingTextLength	= @nRemainingTextLength	OUTPUT
	End

	If @nRemainingTextLength > 0
	Begin
		If @nErrorCode = 0
		Begin	
			-- Extract first part of the DocItem SQl text into the @psSegment1:
			Set @sSQLString = "		
			Select @psSegment1 = substring(DocItemText, 1, @nRemainingTextLength)
			from " + @sTempTableName
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@psSegment1			nvarchar(4000)		OUTPUT,
							  @nRemainingTextLength		smallint',
							  @psSegment1			= @psSegment1		OUTPUT,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	
		If @nErrorCode = 0
		Begin	
			-- Cut off the part of the text already stored in the @psSegment1 to be able to 
			-- extract next potion of text into the @psSegment2, etc.:
			Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval 0 @nRemainingTextLength"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@ptrval			varbinary(16),
							  @nRemainingTextLength		smallint',
							  @ptrval			= @ptrval,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	End

	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "		
		Select @nRemainingTextLength = 	ISNULL(CASE 	WHEN DATALENGTH(DocItemText) < 8000 
								THEN DATALENGTH(DocItemText)/2 
								ELSE 4000
							END, 0)
		from " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nRemainingTextLength	int			OUTPUT',
						  @nRemainingTextLength	= @nRemainingTextLength	OUTPUT
	End

	If @nRemainingTextLength > 0
	Begin	
		If @nErrorCode = 0
		Begin		
			Set @sSQLString = "	
			Select @psSegment2 = substring(DocItemText, 1, @nRemainingTextLength)
			from " + @sTempTableName
		
			exec @nErrorCode = sp_executesql @sSQLString,
								N'@psSegment2			nvarchar(4000)		OUTPUT,
								  @nRemainingTextLength		smallint',
								  @psSegment2			= @psSegment2		OUTPUT,
								  @nRemainingTextLength		= @nRemainingTextLength	
		End
	
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval 0 @nRemainingTextLength"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@ptrval			varbinary(16),
							  @nRemainingTextLength		smallint',
							  @ptrval			= @ptrval,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	End

	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "		
		Select @nRemainingTextLength = 	ISNULL(CASE 	WHEN DATALENGTH(DocItemText) < 8000 
								THEN DATALENGTH(DocItemText)/2 
								ELSE 4000
							END, 0)
		from " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nRemainingTextLength	int			OUTPUT',
						  @nRemainingTextLength	= @nRemainingTextLength	OUTPUT
	End

	If @nRemainingTextLength > 0
	Begin			
		If @nErrorCode = 0
		Begin		
			Set @sSQLString = "	
			Select @psSegment3 = substring(DocItemText, 1, @nRemainingTextLength)
			from " + @sTempTableName
		
			exec @nErrorCode = sp_executesql @sSQLString,
								N'@psSegment3			nvarchar(4000)		OUTPUT,
								  @nRemainingTextLength		smallint',
								  @psSegment3			= @psSegment3		OUTPUT,
								  @nRemainingTextLength		= @nRemainingTextLength	
		End
	
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval 0 @nRemainingTextLength"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@ptrval			varbinary(16),
							  @nRemainingTextLength		smallint',
							  @ptrval			= @ptrval,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	End

	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "		
		Select @nRemainingTextLength = 	ISNULL(CASE 	WHEN DATALENGTH(DocItemText) < 8000 
								THEN DATALENGTH(DocItemText)/2 
								ELSE 4000
							END, 0)
		from " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nRemainingTextLength	int			OUTPUT',
						  @nRemainingTextLength	= @nRemainingTextLength	OUTPUT
	End
	
	If @nRemainingTextLength > 0
	Begin	
		If @nErrorCode = 0
		Begin		
			Set @sSQLString = "	
			Select @psSegment4 = substring(DocItemText, 1, @nRemainingTextLength)
			from " + @sTempTableName
		
			exec @nErrorCode = sp_executesql @sSQLString,
								N'@psSegment4			nvarchar(4000)		OUTPUT,
								  @nRemainingTextLength		smallint',
								  @psSegment4			= @psSegment4		OUTPUT,
								  @nRemainingTextLength		= @nRemainingTextLength	
		End
	
	
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval 0 @nRemainingTextLength"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@ptrval			varbinary(16),
							  @nRemainingTextLength		smallint',
							  @ptrval			= @ptrval,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	End

	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "		
		Select @nRemainingTextLength = 	ISNULL(CASE 	WHEN DATALENGTH(DocItemText) < 8000 
								THEN DATALENGTH(DocItemText)/2 
								ELSE 4000
							END, 0)
		from " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nRemainingTextLength	int			OUTPUT',
						  @nRemainingTextLength	= @nRemainingTextLength	OUTPUT
	End

	If @nRemainingTextLength > 0
	Begin	
	
		If @nErrorCode = 0
		Begin		
			Set @sSQLString = "	
			Select @psSegment5 = substring(DocItemText, 1, @nRemainingTextLength)
			from " + @sTempTableName
		
			exec @nErrorCode = sp_executesql @sSQLString,
								N'@psSegment5			nvarchar(4000)		OUTPUT,
								  @nRemainingTextLength		smallint',
								  @psSegment5			= @psSegment5		OUTPUT,
								  @nRemainingTextLength		= @nRemainingTextLength	
		End
		
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval 0 @nRemainingTextLength"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@ptrval			varbinary(16),
							  @nRemainingTextLength		smallint',
							  @ptrval			= @ptrval,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	End

	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "
		Select @nRemainingTextLength = 	ISNULL(CASE 	WHEN DATALENGTH(DocItemText) < 8000 
								THEN DATALENGTH(DocItemText)/2 
								ELSE 4000
						       END, 0)
		from " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nRemainingTextLength	int			OUTPUT',
						  @nRemainingTextLength	= @nRemainingTextLength	OUTPUT
	End

	If @nRemainingTextLength > 0
	Begin	

		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "		
			Select @psSegment6 = substring(DocItemText, 1, @nRemainingTextLength)
			from " + @sTempTableName
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@psSegment6			nvarchar(4000)		OUTPUT,
							  @nRemainingTextLength		smallint',
							  @psSegment6			= @psSegment6		OUTPUT,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval 0 @nRemainingTextLength"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@ptrval			varbinary(16),
							  @nRemainingTextLength		smallint',
							  @ptrval			= @ptrval,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	End

	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "
		Select @nRemainingTextLength = 	ISNULL(CASE 	WHEN DATALENGTH(DocItemText) < 8000 
								THEN DATALENGTH(DocItemText)/2 
								ELSE 4000
						       END, 0)
		from " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nRemainingTextLength	int			OUTPUT',
						  @nRemainingTextLength	= @nRemainingTextLength	OUTPUT
	End

	If @nRemainingTextLength > 0
	Begin	

		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "		
			Select @psSegment7 = substring(DocItemText, 1, @nRemainingTextLength)
			from " + @sTempTableName
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@psSegment7			nvarchar(4000)		OUTPUT,
							  @nRemainingTextLength		smallint',
							  @psSegment7			= @psSegment7		OUTPUT,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval 0 @nRemainingTextLength"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@ptrval			varbinary(16),
							  @nRemainingTextLength		smallint',
							  @ptrval			= @ptrval,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	End

	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "
		Select @nRemainingTextLength = 	ISNULL(CASE 	WHEN DATALENGTH(DocItemText) < 8000 
								THEN DATALENGTH(DocItemText)/2 
								ELSE 4000
						       END, 0)
		from " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nRemainingTextLength	int			OUTPUT',
						  @nRemainingTextLength	= @nRemainingTextLength	OUTPUT
	End

	If @nRemainingTextLength > 0
	Begin	

		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "		
			Select @psSegment8 = substring(DocItemText, 1, @nRemainingTextLength)
			from " + @sTempTableName
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@psSegment8			nvarchar(4000)		OUTPUT,
							  @nRemainingTextLength		smallint',
							  @psSegment8			= @psSegment8		OUTPUT,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval 0 @nRemainingTextLength"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@ptrval			varbinary(16),
							  @nRemainingTextLength		smallint',
							  @ptrval			= @ptrval,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	End

	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "
		Select @nRemainingTextLength = 	ISNULL(CASE 	WHEN DATALENGTH(DocItemText) < 8000 
								THEN DATALENGTH(DocItemText)/2 
								ELSE 4000
						       END, 0)
		from " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nRemainingTextLength	int			OUTPUT',
						  @nRemainingTextLength	= @nRemainingTextLength	OUTPUT
	End

	If @nRemainingTextLength > 0
	Begin	

		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "		
			Select @psSegment9 = substring(DocItemText, 1, @nRemainingTextLength)
			from " + @sTempTableName
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@psSegment9			nvarchar(4000)		OUTPUT,
							  @nRemainingTextLength		smallint',
							  @psSegment9			= @psSegment9		OUTPUT,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval 0 @nRemainingTextLength"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@ptrval			varbinary(16),
							  @nRemainingTextLength		smallint',
							  @ptrval			= @ptrval,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	End

	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "
		Select @nRemainingTextLength = 	ISNULL(CASE 	WHEN DATALENGTH(DocItemText) < 8000 
								THEN DATALENGTH(DocItemText)/2 
								ELSE 4000
						       END, 0)
		from " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nRemainingTextLength	int			OUTPUT',
						  @nRemainingTextLength	= @nRemainingTextLength	OUTPUT
	End

	If @nRemainingTextLength > 0
	Begin	

		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "		
			Select @psSegment10 = substring(DocItemText, 1, @nRemainingTextLength)
			from " + @sTempTableName
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@psSegment10			nvarchar(4000)		OUTPUT,
							  @nRemainingTextLength		smallint',
							  @psSegment10			= @psSegment10		OUTPUT,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	
		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "UPDATETEXT " + @sTempTableName + ".DocItemText @ptrval 0 @nRemainingTextLength"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@ptrval			varbinary(16),
							  @nRemainingTextLength		smallint',
							  @ptrval			= @ptrval,
							  @nRemainingTextLength		= @nRemainingTextLength	
		End
	End

	-- At the end of processing drop the temporary table:
	If exists(select * from tempdb.dbo.sysobjects where name = @sTempTableName)
	Begin
		Set @sSQLString = "Drop table " + @sTempTableName

		exec @nErrorCode = sp_executesql @sSQLString
	End
End

Return @nErrorCode
GO

Grant exec on dbo.pt_GetDocItemSql to public
GO
