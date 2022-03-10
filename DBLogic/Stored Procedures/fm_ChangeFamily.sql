
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fm_ChangeFamily
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fm_ChangeFamily]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fm_ChangeFamily.'
	Drop procedure [dbo].[fm_ChangeFamily]
	Print '**** Creating Stored Procedure dbo.fm_ChangeFamily...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.fm_ChangeFamily
(
	@psOldFamily		nvarchar(20),
	@psNewFamily		nvarchar(20)
)
as
-- PROCEDURE:	fm_ChangeFamily
-- VERSION:	1
-- SCOPE:	Inprotech
-- DESCRIPTION:	Used to modify the FAMILY from one value to another.
--		The FAMILY is used in multiply places and referential integrity
--		will stop it from just being updated in the base CASEFAMILY table.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 28-Feb-2017	MF	70730	1	Procedure created

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
-- old FAMILTY
------------------------
If not exists (select 1 from CASEFAMILY where FAMILY=@psOldFamily)
and @ErrorCode=0
Begin
	RAISERROR('@psOldFamily does not exist in CASEFAMILY table', 14, 1)
	Set @ErrorCode = @@ERROR
End

Select @TranCountStart = @@TranCount

Begin TRANSACTION

-----------------------------------------
-- Copy the details of the existing
-- CASEFAMILY row with the NewCASEFAMILY if
-- it does not already exist.
-----------------------------------------
If @ErrorCode=0
and not exists (select 1 from CASEFAMILY where FAMILY=@psNewFamily)
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
		where F.TABLE_NAME='CASEFAMILY'
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
		set @sFromColumnList=replace(@sFromColumnList,'F.FAMILY,','@psNewFamily,')
		
		Set @sSQLString="
		Insert into CASEFAMILY("+@sIntoColumnList+")
		Select "+@sFromColumnList+"
		From CASEFAMILY F
		left join CASEFAMILY I on (I.FAMILY=@psNewFamily)
		where F.FAMILY=@psOldFamily
		and I.FAMILY is NULL"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldFamily nvarchar(20),
					  @psNewFamily nvarchar(20)',
					  @psOldFamily,
					  @psNewFamily
	End
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update CASES
	set FAMILY=@psNewFamily
	where FAMILY=@psOldFamily"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldFamily nvarchar(20),
					  @psNewFamily nvarchar(20)',
					  @psOldFamily,
					  @psNewFamily
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update COSTTRACKALLOC
	set FAMILY=@psNewFamily
	where FAMILY=@psOldFamily"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldFamily nvarchar(20),
					  @psNewFamily nvarchar(20)',
					  @psOldFamily,
					  @psNewFamily
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update COSTTRACKLINE
	set FAMILY=@psNewFamily
	where FAMILY=@psOldFamily"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldFamily nvarchar(20),
					  @psNewFamily nvarchar(20)',
					  @psOldFamily,
					  @psNewFamily
End

if @ErrorCode=0
Begin
	If exists(select 1 from sysobjects where type='TR' and name='InsertFAMILYSEARCHRESULT_ids')
	Begin
		alter table FAMILYSEARCHRESULT
		    disable trigger InsertFAMILYSEARCHRESULT_ids

		Set @ErrorCode=@@ERROR
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		update FAMILYSEARCHRESULT
		set FAMILY=@psNewFamily
		where FAMILY=@psOldFamily"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@psOldFamily nvarchar(20),
						  @psNewFamily nvarchar(20)',
						  @psOldFamily,
						  @psNewFamily
	End

	If @ErrorCode=0
	Begin
		alter table FAMILYSEARCHRESULT
		    enable trigger all

		Set @ErrorCode=@@ERROR
	End
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	update TRANSADJUSTMENT
	set TOFAMILY=@psNewFamily
	where TOFAMILY=@psOldFamily"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldFamily nvarchar(20),
					  @psNewFamily nvarchar(20)',
					  @psOldFamily,
					  @psNewFamily
End

---------------------------------
-- Now remove the Old FAMILY
---------------------------------
if  @ErrorCode=0
and not exists(select 1 from PROTECTCODES where FAMILY=@psOldFamily)
Begin
	Set @sSQLString="
	delete from CASEFAMILY
	where FAMILY=@psOldFamily"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOldFamily nvarchar(20)',
					  @psOldFamily
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

Grant execute on dbo.fm_ChangeFamily to public
GO