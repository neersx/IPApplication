
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of tl_ChangeTitle
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[tl_ChangeTitle]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.tl_ChangeTitle.'
	Drop procedure [dbo].[tl_ChangeTitle]
	Print '**** Creating Stored Procedure dbo.tl_ChangeTitle...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.tl_ChangeTitle
(
	@psOldTitle		nvarchar(20),
	@psNewTitle		nvarchar(20),
	@psNewFullTitle		nvarchar(30)	= NULL, 
	@pbClearFullTitle	bit		= 0
)
as
-- PROCEDURE:	tl_ChangeTitle
-- VERSION:	1
-- SCOPE:	Inprotech
-- DESCRIPTION:	Used to modify the TITLE from one value to another.
--		The TITLE may be used in multiply places and if referential integrity
--		exists it will stop it from just being updated in the base TITLES table.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 1-Mar-2017	MF	70765	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 		int
Declare @TranCountStart		int

Declare @sSQLString		nvarchar(max)
Declare	@sIntoColumnList	nvarchar(max)
Declare	@sFromColumnList	nvarchar(max)

Declare	@bFamilyExists	bit

Set 	@ErrorCode      = 0
Set	@bFamilyExists= 0


--------------------------------
-- D A T A   V A L I D A T I O N
-- Validate the input parameters
--------------------------------

------------------------
-- Validate existence of 
-- old TITLE
------------------------
If not exists (select 1 from TITLES where TITLE=@psOldTitle)
and @ErrorCode=0
Begin
	RAISERROR('@psOldTitle does not exist in TITLES table', 14, 1)
	Set @ErrorCode = @@ERROR
End

Select @TranCountStart = @@TranCount

Begin TRANSACTION

-----------------------------------------
-- Copy the details of the existing
-- TITLES row with the New TITLE if
-- it does not already exist.
-----------------------------------------
If @ErrorCode=0
and not exists (select 1 from TITLES where TITLE=@psNewTitle)
Begin
	-------------------------------------
	-- Get the list of columns to copy --
	-------------------------------------
	If @ErrorCode=0
	Begin
		Set @sIntoColumnList=null

		Set @sSQLString="
		Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
			@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS F 
		where F.TABLE_NAME='TITLES'
		and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
		and F.COLUMN_NAME not like '%_TID'
		and F.DATA_TYPE not in ('sysname','uniqueidentifier')
		and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
		order by F.ORDINAL_POSITION"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@sIntoColumnList	nvarchar(max)	OUTPUT,
					  @sFromColumnList	nvarchar(max)	OUTPUT',
					  @sIntoColumnList=@sIntoColumnList	OUTPUT,
					  @sFromColumnList=@sFromColumnList	OUTPUT
	End

	If @ErrorCode=0
	Begin
		set @sFromColumnList=replace(@sFromColumnList,'F.TITLE,','@psNewTitle,')
		
		Set @sSQLString="
		Insert into TITLES("+@sIntoColumnList+")
		Select "+@sFromColumnList+"
		From TITLES F
		left join TITLES I on (I.TITLE=@psNewTitle)
		where F.TITLE=@psOldTitle
		and I.TITLE is NULL"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTitle nvarchar(20),
					  @psNewTitle nvarchar(20)',
					  @psOldTitle,
					  @psNewTitle
	End
End

If @ErrorCode=0
and(@psNewFullTitle is not null
 or @pbClearFullTitle=1)
Begin
	Set @sSQLString="
	update TITLES
	set FULLTITLE=@psNewFullTitle
	where TITLE=@psNewTitle"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psNewFullTitle nvarchar(30),
					  @psNewTitle	  nvarchar(20)',
					  @psNewFullTitle,
					  @psNewTitle
End
	

if @ErrorCode=0
Begin
	Set @sSQLString="
	update NAME
	set TITLE=@psNewTitle
	where TITLE=@psOldTitle"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTitle nvarchar(20),
					  @psNewTitle nvarchar(20)',
					  @psOldTitle,
					  @psNewTitle
End

---------------------------------
-- Now remove the Old TITLE
---------------------------------
if  @ErrorCode=0
Begin
	Set @sSQLString="
	delete from TITLES
	where TITLE=@psOldTitle"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTitle nvarchar(20)',
					  @psOldTitle
End

-----------------------------------
-- Commit the transaction if it has 
-- successfully completed
-----------------------------------
If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
	Begin
		COMMIT TRANSACTION
	End
	Else Begin
		ROLLBACK TRANSACTION
	End
End

Return @ErrorCode
GO

Grant execute on dbo.tl_ChangeTitle to public
GO