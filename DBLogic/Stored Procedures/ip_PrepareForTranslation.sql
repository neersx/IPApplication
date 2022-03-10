-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PrepareForTranslation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_PrepareForTranslation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_PrepareForTranslation.'
	Drop procedure [dbo].[ip_PrepareForTranslation]
End
Print '**** Creating Stored Procedure dbo.ip_PrepareForTranslation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_PrepareForTranslation
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int		= null,		-- Optional so that it can be called from a script
	@psCulture		nvarchar(5) 	= null,
	@psTableName		nvarchar(30),			-- Mandatory e.g. CASES
	@psTIDColumn		nvarchar(30)			-- Mandatory e.g. TITLE_TID
)
as
-- PROCEDURE:	ip_PrepareForTranslation
-- VERSION:	5
-- DESCRIPTION:	Create a translation place holder for every instance of a translatable data item.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Aug 2004	TM	RFC1695	1	Procedure created
-- 30 Aug 2004	JEK	RFC1695	2	Locate column name(s) from TranslationSource
-- 22 Sep 2004	JEK	RFC1695	3	Translation triggers do not cater for IDENTITY_INSERT ON.
--					Switch TranslationSource.InUse off for duration of procedure.
-- 27 Sep 2004	JEK	RFC1695	4	Need to switch off InUse for all columns in the table.
-- 29 Sep 2004	JEK	RFC1695	5	Join incorrect for original values.  Not catering for no TranslatedItems rows.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET IDENTITY_INSERT TRANSLATEDITEMS ON	

Declare	@nErrorCode			int
Declare @sSQLString			nvarchar(4000)

Declare @nTransactionCountOnEntry 	int
Declare @nTranslationSourceId		int
Declare @bTableHasIdentity		bit
Declare @TemporaryTableName		nvarchar(60)

Declare @sShortColumnName		nvarchar(30)	-- The name of the short column to be translated
Declare @sLongColumnName		nvarchar(30)	-- The name of the long column to be translated

Declare @nMaxTID			int

Declare @tblOriginalValues table
(	TIDColumn			nvarchar(30) 	collate database_default not null,
	OriginalInUse			bit		not null
)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
   Select @nTransactionCountOnEntry = @@TranCount
   BEGIN TRANSACTION
End

-- Get the Translation Source information according to the supplied parameters:
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select 	@nTranslationSourceId = TRANSLATIONSOURCEID,"+char(10)+
	"	@sShortColumnName = SHORTCOLUMN,"+char(10)+
	"	@sLongColumnName = LONGCOLUMN"+char(10)+
	"FROM TRANSLATIONSOURCE"+char(10)+
	"WHERE TABLENAME = @psTableName"+char(10)+
	"AND TIDCOLUMN = @psTIDColumn"+char(10)

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nTranslationSourceId   	int	  		OUTPUT,
					  @sShortColumnName		nvarchar(30)		OUTPUT,
					  @sLongColumnName		nvarchar(30)		OUTPUT,
					  @psTableName			nvarchar(30),
					  @psTIDColumn			nvarchar(30)',
					  @nTranslationSourceId		= @nTranslationSourceId OUTPUT,
					  @sShortColumnName		= @sShortColumnName	OUTPUT,
					  @sLongColumnName		= @sLongColumnName	OUTPUT,
					  @psTableName			= @psTableName,
					  @psTIDColumn			= @psTIDColumn
End

-- Store the original values of the InUse column for the table
If @nErrorCode = 0
Begin
	Insert into @tblOriginalValues(TIDColumn, OriginalInUse)
	Select 	TIDCOLUMN, INUSE
	from	TRANSLATIONSOURCE
	where	TABLENAME=@psTableName
End

-- Ensure TranslationSource.InUse = 0, so that the translation triggers do not fire.
If @nErrorCode = 0
Begin	
  	Update  TRANSLATIONSOURCE
	set	INUSE=0
	from 	@tblOriginalValues V
	where	V.TIDColumn = TRANSLATIONSOURCE.TIDCOLUMN
	and	TABLENAME = @psTableName
	and	V.OriginalInUse=1
End

-- Get the last identity generated in the TRANSLATEDITEMS.TID column:
If @nErrorCode = 0
Begin	
	Set @sSQLString = "
  	Select @nMaxTID = max(TID) 
	from  TRANSLATEDITEMS"	

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nMaxTID   	int	   OUTPUT',
					  @nMaxTID	= @nMaxTID OUTPUT			 
End

-- Allow for no rows on TranslatedItems
If @nErrorCode = 0
Begin
	set @nMaxTID = isnull(@nMaxTID, 0)
End

-- Find out if the passed table already has an Identity column:
If @nErrorCode = 0
Begin
	Set @sSQLString = "Set @bTableHasIdentity = OBJECTPROPERTY(OBJECT_ID('"+@psTableName+"'), 'TableHasIdentity')"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bTableHasIdentity	bit			OUTPUT',
					  @bTableHasIdentity	= @bTableHasIdentity	OUTPUT
End

-- 1) The supplied table does not have an Identity Column.
--	a) Add an identity column to the source table, generating a OffsetIdentity value from 1 to x.
--	b) Insert a TranslatedItem row for every eligible source table row, forcing the TID
--	   to be LastTID+OffsetIdentity (note there will be gaps in the sequence)
--	c) Update the source table's TID column value to be its OffsetIdentity + LastTID
--	d) Remove the identity column
If @nErrorCode = 0
and @bTableHasIdentity = 0
Begin
	Set @sSQLString = "Alter table "+@psTableName+" add OFFSETIDENTITY int	identity(1,1)"			
			 

	exec @nErrorCode = sp_executesql @sSQLString

	If @nErrorCode = 0
	and @nTranslationSourceId is not null
	Begin	
	
		Set @sSQLString = 
		"Insert into TRANSLATEDITEMS (TID, TRANSLATIONSOURCEID)"+char(10)+
	  	"Select isnull(@nMaxTID,0)+OFFSETIDENTITY, @nTranslationSourceId"+char(10)+  
		"from "+@psTableName+char(10)+
		"where ("+
		case when @sLongColumnName is null then @psTableName+"."+@sShortColumnName+" is not null" end+
		case when @sShortColumnName is null then @psTableName+"."+@sLongColumnName+" is not null" end+
		case when @sShortColumnName is not null and @sLongColumnName is not null
		then
		@psTableName+"."+@sShortColumnName+" is not null"+char(10)+
		"or    "+@psTableName+"."+@sLongColumnName+" is not null"
		end+
		")"+char(10)+
		"and "+@psTableName+"."+@psTIDColumn+" is null " 

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nTranslationSourceId   	int,
						  @nMaxTID			int',
						  @nTranslationSourceId		= @nTranslationSourceId,
						  @nMaxTID			= @nMaxTID
		Set @pnRowCount = @@RowCount
	End
	
	If @nErrorCode = 0
	and @nTranslationSourceId is not null
	Begin	
	
		Set @sSQLString = 
		"Update "+@psTableName+char(10)+
	  	"Set "+@psTIDColumn+" = @nMaxTID+OFFSETIDENTITY"+char(10)+
		"where ("+
		case when @sLongColumnName is null then @psTableName+"."+@sShortColumnName+" is not null" end+
		case when @sShortColumnName is null then @psTableName+"."+@sLongColumnName+" is not null" end+
		case when @sShortColumnName is not null and @sLongColumnName is not null
		then
		@psTableName+"."+@sShortColumnName+" is not null"+char(10)+
		"or    "+@psTableName+"."+@sLongColumnName+" is not null"
		end+
		")"+char(10)+
		"and "+@psTableName+"."+@psTIDColumn+" is null " 

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nTranslationSourceId   	int,
						  @nMaxTID			int',
						  @nTranslationSourceId		= @nTranslationSourceId,
						  @nMaxTID			= @nMaxTID
	End
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Alter table "+@psTableName+" drop column OFFSETIDENTITY"				 
	
		exec @nErrorCode = sp_executesql @sSQLString
	End

End
Else 
-- 2) The supplied tabble already has an Identity Column.
--	a) Create a temporary table with an identity column
--	b) Insert eligible source data rows with the source table identity key, and
--	   generating a OffsetIdentity value from 1 to x.
--	c) Insert a TranslatedItem row for every temp table row, forcing the TID
--	   to be LastTID+OffsetIdentity
--	d) Update the source table from the temp table setting it's TID column value
--	   to be the temp table OffsetIdentity + LastTID
--	e) Remove the temporary rable
If @nErrorCode = 0
and @bTableHasIdentity = 1
Begin
	-- Create temporary table with the identity column and the key 
	-- columns for the passed table (@psTableName):

	Set @TemporaryTableName = '##tblIdentity' + Cast(@@SPID as varchar(10)) 
	
	If exists(select * from tempdb.dbo.sysobjects where name = @TemporaryTableName)
	and @nErrorCode=0
	Begin
		Set @sSQLString = 'drop table ' + @TemporaryTableName

		exec @nErrorCode=sp_executesql @sSQLString			
	End
	
	If @nErrorCode=0
	Begin		
		Set @sSQLString = 'create table '+@TemporaryTableName+" (OFFSETIDENTITY	      	  int identity(1,1),"
						     	    +char(10)+"  ORIGINALIDENTITY int not null)"
		exec @nErrorCode=sp_executesql @sSQLString				
	End

	If @nErrorCode=0
	Begin	

		Set @sSQLString = 
		"Insert into "+@TemporaryTableName+" (ORIGINALIDENTITY)"+char(10)+ 
		"Select IDENTITYCOL"+char(10)+  
		"from "+@psTableName+char(10)+
		"where ("+
		case when @sLongColumnName is null then @psTableName+"."+@sShortColumnName+" is not null" end+
		case when @sShortColumnName is null then @psTableName+"."+@sLongColumnName+" is not null" end+
		case when @sShortColumnName is not null and @sLongColumnName is not null
		then
		@psTableName+"."+@sShortColumnName+" is not null"+char(10)+
		"or    "+@psTableName+"."+@sLongColumnName+" is not null"
		end+
		")"+char(10)+
		"and "+@psTableName+"."+@psTIDColumn+" is null " 

		exec @nErrorCode = sp_executesql @sSQLString
	End
	
	
	If @nErrorCode = 0
	and @nTranslationSourceId is not null
	Begin	
	
		Set @sSQLString = 
		"Insert into TRANSLATEDITEMS (TID, TRANSLATIONSOURCEID)"+char(10)+
	  	"Select isnull(@nMaxTID,0)+OFFSETIDENTITY, @nTranslationSourceId"+char(10)+  
		"from "+@TemporaryTableName		

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nTranslationSourceId   	int,
						  @nMaxTID			int',
						  @nTranslationSourceId		= @nTranslationSourceId,
						  @nMaxTID			= @nMaxTID
		Set @pnRowCount = @@RowCount
	End
	
	If @nErrorCode = 0
	and @nTranslationSourceId is not null
	Begin	
	
		Set @sSQLString = 
		"Update "+@psTableName+char(10)+
	  	"Set "+@psTIDColumn+" = @nMaxTID+TMR.OFFSETIDENTITY"+char(10)+
		"from "+@TemporaryTableName+" TMR"+char(10)+
		"where "+@psTableName+".IDENTITYCOL = TMR.ORIGINALIDENTITY"

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nTranslationSourceId   	int,
						  @nMaxTID			int',
						  @nTranslationSourceId		= @nTranslationSourceId,
						  @nMaxTID			= @nMaxTID
	End
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 'drop table ' + @TemporaryTableName

		exec @nErrorCode=sp_executesql @sSQLString	
	End
End

-- Ensure TranslationSource.InUse is set back to its original value.
If @nErrorCode = 0
Begin	
  	Update  TRANSLATIONSOURCE
	set	INUSE=1
	from 	@tblOriginalValues V
	where	V.TIDColumn = TRANSLATIONSOURCE.TIDCOLUMN
	and	TABLENAME = @psTableName
	and	V.OriginalInUse=1					 
End

If @@TranCount > @nTransactionCountOnEntry
Begin
   If @nErrorCode = 0
      COMMIT TRANSACTION
   Else
      ROLLBACK TRANSACTION
End

SET IDENTITY_INSERT TRANSLATEDITEMS OFF	

Return @nErrorCode
GO

Grant execute on dbo.ip_PrepareForTranslation to public
GO
