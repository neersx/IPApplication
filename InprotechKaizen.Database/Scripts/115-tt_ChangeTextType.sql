
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of tt_ChangeTextType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[tt_ChangeTextType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.tt_ChangeTextType.'
	Drop procedure [dbo].[tt_ChangeTextType]
	Print '**** Creating Stored Procedure dbo.tt_ChangeTextType...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.tt_ChangeTextType
(
	@psOldTextType		nvarchar(2),
	@psNewTextType		nvarchar(2),
	@pnResetOldUsedByFlag	smallint	= null,  -- 0=Cases Only, 1=Employee, 2=Individual, 4=Organisation
	@pbRemoveOldTextType	bit		= 0,
	@psRenameOldTextType	nvarchar(50)	= null
)
as
-- PROCEDURE:	tt_ChangeTextType
-- VERSION:	2
-- SCOPE:	Inprotech
-- DESCRIPTION:	Used to modify the TextType from one value to another.
--		The TextType is used in multiply places and referential integrity
--		will stop it from just being updated in the base TEXTTYPE table.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 16-Apr-2015	MF	46621	1	Procedure created
-- 20-May-2015	MF	46621	2	Revisit.  Can't use and UPDATE on the CASETEXT and
--					NAMETEXT tables when Audit Triggers are in place as the
--					the change of TEXTTYPE reverts with the triggers.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 		int
Declare @TranCountStart		int

Declare @sSQLString		nvarchar(max)
Declare	@sIntoColumnList	nvarchar(max)
Declare	@sFromColumnList	nvarchar(max)

Declare	@bTextTypeExists	bit

Set 	@ErrorCode      = 0
Set	@bTextTypeExists= 0


--------------------------------
-- D A T A   V A L I D A T I O N
-- Validate the input parameters
--------------------------------

------------------------
-- Validate existence of 
-- old TEXTTYPE
------------------------
If not exists (select 1 from TEXTTYPE where TEXTTYPE=@psOldTextType)
and @ErrorCode=0
Begin
	RAISERROR('@psOldTextType does not exist in TEXTTYPE table', 14, 1)
	Set @ErrorCode = @@ERROR
End

Select @TranCountStart = @@TranCount

Begin TRANSACTION

-----------------------------------------
-- Copy the details of the existing
-- TEXTTYPE row with the NewTextType if
-- it does not already exist.
-----------------------------------------
If @ErrorCode=0
and not exists (select 1 from TEXTTYPE where TEXTTYPE=@psNewTextType)
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
		where F.TABLE_NAME='TEXTTYPE'
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
		set @sFromColumnList=replace(@sFromColumnList,'F.TEXTTYPE','@psNewTextType')
		
		Set @sSQLString="
		Insert into TEXTTYPE("+@sIntoColumnList+")
		Select "+@sFromColumnList+"
		From TEXTTYPE F
		left join TEXTTYPE I on (I.TEXTTYPE=@psNewTextType)
		where F.TEXTTYPE=@psOldTextType
		and I.TEXTTYPE is NULL"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2),
					  @psNewTextType	nvarchar(2)',
					  @psOldTextType,
					  @psNewTextType
	End
End

-----------------------------------------
-- Rename the description of the old
-- TEXTTYPE if requested to do so and/or
-- change the USEDBYFLAG.
-----------------------------------------
If @ErrorCode=0
and(@psRenameOldTextType  is not null
 or @pnResetOldUsedByFlag is not null)
Begin
	If  @psRenameOldTextType  is not null
	and @pnResetOldUsedByFlag is not null
	Begin
		Set @sSQLString="
		Update TEXTTYPE
		Set USEDBYFLAG     =CASE WHEN(@pnResetOldUsedByFlag>0) THEN @pnResetOldUsedByFlag ELSE NULL END,
		    TEXTDESCRIPTION=@psRenameOldTextType
		where TEXTTYPE=@psOldTextType"
	End
	Else If  @psRenameOldTextType  is null
	     and @pnResetOldUsedByFlag is not null
	Begin
		Set @sSQLString="
		Update TEXTTYPE
		Set USEDBYFLAG     =CASE WHEN(@pnResetOldUsedByFlag>0) THEN @pnResetOldUsedByFlag ELSE NULL END
		where TEXTTYPE=@psOldTextType"
	End
	Else If  @psRenameOldTextType  is not null
	     and @pnResetOldUsedByFlag is null
	Begin
		Set @sSQLString="
		Update TEXTTYPE
		Set TEXTDESCRIPTION=@psRenameOldTextType
		where TEXTTYPE=@psOldTextType"
	End
		
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@psOldTextType	nvarchar(2),
				  @psRenameOldTextType	nvarchar(50),
				  @pnResetOldUsedByFlag	smallint',
				  @psOldTextType	= @psOldTextType,
				  @psRenameOldTextType	= @psRenameOldTextType,
				  @pnResetOldUsedByFlag	= @pnResetOldUsedByFlag
End


-----------------------------------------
-- Copy the details of the existing
-- CASETEXT row with the NewTextType
-----------------------------------------
If @ErrorCode=0
Begin
	-------------------------------------
	-- Get the list of columns to copy --
	-------------------------------------
	If @ErrorCode=0
	Begin
		Set @sIntoColumnList=null
		Set @sFromColumnList=null

		Set @sSQLString="
		Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
			@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS F 
		where F.TABLE_NAME='CASETEXT'
		and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
		and F.DATA_TYPE not in ('sysname','uniqueidentifier')
		and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
		order by F.ORDINAL_POSITION"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@sIntoColumnList	nvarchar(max)	OUTPUT,
					  @sFromColumnList	nvarchar(max)	OUTPUT',
					  @sIntoColumnList=@sIntoColumnList	OUTPUT,
					  @sFromColumnList=@sFromColumnList	OUTPUT
	End

	--------------------------------------------
	-- Copy the CASETEXT row with NewTextType --
	--------------------------------------------
	If @ErrorCode=0
	Begin
		set @sFromColumnList=replace(@sFromColumnList,'F.TEXTTYPE','@psNewTextType')
		
		Set @sSQLString="
		Insert into CASETEXT("+@sIntoColumnList+")
		Select "+@sFromColumnList+"
		From CASETEXT F
		left join CASETEXT I on (I.CASEID  =F.CASEID
				     and I.TEXTTYPE=@psNewTextType
				     and I.TEXTNO  =F.TEXTNO)
		where F.TEXTTYPE=@psOldTextType
		and I.CASEID is NULL"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2),
					  @psNewTextType	nvarchar(2)',
					  @psOldTextType,
					  @psNewTextType
	End

	----------------------------------------------
	-- Delete the CASETEXT row with OldTextType --
	----------------------------------------------
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Delete O
		From CASETEXT O
		join CASETEXT N on (N.CASEID  =O.CASEID
				and N.TEXTTYPE=@psNewTextType
				and N.TEXTNO  =O.TEXTNO)
		where O.TEXTTYPE=@psOldTextType"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2),
					  @psNewTextType	nvarchar(2)',
					  @psOldTextType,
					  @psNewTextType
	End
End


-----------------------------------------
-- Copy the details of the existing
-- NAMETEXT row with the NewTextType
-----------------------------------------
If @ErrorCode=0
Begin
	-------------------------------------
	-- Get the list of columns to copy --
	-------------------------------------
	If @ErrorCode=0
	Begin
		Set @sIntoColumnList=null
		Set @sFromColumnList=null

		Set @sSQLString="
		Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
			@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS F 
		where F.TABLE_NAME='NAMETEXT'
		and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
		and F.DATA_TYPE not in ('sysname','uniqueidentifier')
		and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
		order by F.ORDINAL_POSITION"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@sIntoColumnList	nvarchar(max)	OUTPUT,
					  @sFromColumnList	nvarchar(max)	OUTPUT',
					  @sIntoColumnList=@sIntoColumnList	OUTPUT,
					  @sFromColumnList=@sFromColumnList	OUTPUT
	End

	--------------------------------------------
	-- Copy the NAMETEXT row with NewTextType --
	--------------------------------------------
	If @ErrorCode=0
	Begin
		set @sFromColumnList=replace(@sFromColumnList,'F.TEXTTYPE','@psNewTextType')
	
		Set @sSQLString="
		Insert into NAMETEXT("+@sIntoColumnList+")
		Select "+@sFromColumnList+"
		From NAMETEXT F
		left join NAMETEXT I on (I.NAMENO  =F.NAMENO
				     and I.TEXTTYPE=@psNewTextType)
		where F.TEXTTYPE=@psOldTextType
		and I.NAMENO is NULL"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2),
					  @psNewTextType	nvarchar(2)',
					  @psOldTextType,
					  @psNewTextType
	End

	----------------------------------------------
	-- Delete the NAMETEXT row with OldTextType --
	----------------------------------------------
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Delete O
		From NAMETEXT O
		join NAMETEXT N on (N.NAMENO  =O.NAMENO
				and N.TEXTTYPE=@psNewTextType)
		where O.TEXTTYPE=@psOldTextType"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2),
					  @psNewTextType	nvarchar(2)',
					  @psOldTextType,
					  @psNewTextType
	End
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update EDERULECASETEXT
	set TEXTTYPE=@psNewTextType
	where TEXTTYPE=@psOldTextType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2),
					  @psNewTextType	nvarchar(2)',
					  @psOldTextType,
					  @psNewTextType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update SCREENCONTROL
	set TEXTTYPE=@psNewTextType
	where TEXTTYPE=@psOldTextType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2),
					  @psNewTextType	nvarchar(2)',
					  @psOldTextType,
					  @psNewTextType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CASETYPE
	set KOTTEXTTYPE=@psNewTextType
	where KOTTEXTTYPE=@psOldTextType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2),
					  @psNewTextType	nvarchar(2)',
					  @psOldTextType,
					  @psNewTextType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update NAMETYPE
	set KOTTEXTTYPE=@psNewTextType
	where KOTTEXTTYPE=@psOldTextType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2),
					  @psNewTextType	nvarchar(2)',
					  @psOldTextType,
					  @psNewTextType
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update TOPICCONTROLFILTER
	set FILTERVALUE=@psNewTextType
	where FILTERVALUE=@psOldTextType
	and FILTERNAME='TextTypeKey'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2),
					  @psNewTextType	nvarchar(2)',
					  @psOldTextType,
					  @psNewTextType
End

---------------------------------
-- Now remove the Old Text Type
---------------------------------
if  @ErrorCode=0
and @pbRemoveOldTextType=1
and not exists(select 1 from PROTECTCODES where TEXTTYPE=@psOldTextType)
Begin
	Set @sSQLString="
	delete from TEXTTYPE
	where TEXTTYPE=@psOldTextType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldTextType	nvarchar(2)',
					  @psOldTextType
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

Grant execute on dbo.tt_ChangeTextType to public
GO