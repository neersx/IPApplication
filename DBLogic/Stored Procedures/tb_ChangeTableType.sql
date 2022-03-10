-----------------------------------------------------------------------------------------------------------------------------
-- Creation of tb_ChangeTableType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[tb_ChangeTableType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.tb_ChangeTableType.'
	Drop procedure [dbo].[tb_ChangeTableType]
End
Print '**** Creating Stored Procedure dbo.tb_ChangeTableType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.tb_ChangeTableType
(
	@pnOldTableType		int,
	@pnNewTableType		int	= null	OUTPUT-- Null if a new code is to be assigned automatically
)
as
-- PROCEDURE:	tb_ChangeTableType
-- VERSION:	1
-- DESCRIPTION:	Used to modify the TABLETYPE value. This is required when a system
--		required code has already been allocated on a client database.
-- COPYRIGHT:	Copyright 1993 - 2015 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 23-Sep-2015	AT		52817	1		Procedure created based off tb_ChangeTableCode.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @tblChildReferences table(
		SEQUENCENO		int		identity(1,1),
		TABLENAME		nvarchar(100)	collate database_default NOT NULL, 
		COLUMNNAME		nvarchar(100)	collate database_default NOT NULL
		)

Declare @ErrorCode 	int
Declare @TranCountStart	int
Declare @nRowCount	int
Declare @nSequenceNo	int

Declare @sSQLString	nvarchar(4000)

Set @ErrorCode=0

--------------------------------
-- D A T A   V A L I D A T I O N
-- Validate the input parameters
--------------------------------

------------------------
-- Validate existence of 
-- old TableType
------------------------
If not exists (select 1 from TABLETYPE where TABLETYPE=@pnOldTableType)
and @ErrorCode=0
Begin
	RAISERROR('@pnOldTableType does not exist in TABLETYPE table', 14, 1)
	Set @ErrorCode = @@ERROR
End

----------------------------
-- Validate that the new 
-- TableType has not already
-- been used.
----------------------------
If  @pnNewTableType is not null
and @ErrorCode = 0 
Begin
	If exists (select 1 from TABLETYPE where TABLETYPE=@pnNewTableType)
	Begin
		RAISERROR('@pnNewTableType cannot be used as it already exists in TABLETYPE table', 14, 1)
		Set @ErrorCode = @@ERROR
	End
End
--------------------------------------------------
-- If a replacement TableType has not be supplied
-- then allocate the next number automatically.
--------------------------------------------------
If @pnNewTableType is null
and @ErrorCode = 0 
Begin
	------------------------------------------------
	-- Keep this transaction as short as possible to 
	-- avoid locking the LASTINTERNALCODE table
	------------------------------------------------
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	------------------------------------------------------
	-- Get the next available TABLETYPE value to use.
	------------------------------------------------------
	Set @sSQLString="
	Update LASTINTERNALCODE
	set INTERNALSEQUENCE=INTERNALSEQUENCE+1,
	    @pnNewTableType =INTERNALSEQUENCE+1
	from LASTINTERNALCODE 
	where TABLENAME='TABLETYPE'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnNewTableType		int	OUTPUT',
				  @pnNewTableType=@pnNewTableType	OUTPUT

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

---------------------------------------------
-- Copy the details of the existing TABLETYPE
-- rows to the new TableType. 
---------------------------------------------
If @ErrorCode=0
Begin
	Set @TranCountStart = @@TranCount
	
	Set @sSQLString="
	insert into TABLETYPE(TABLETYPE,TABLENAME,MODIFIABLE,ACTIVITYFLAG,DATABASETABLE)
	select @pnNewTableType,TABLENAME,MODIFIABLE,ACTIVITYFLAG,DATABASETABLE
	from TABLETYPE T
	where T.TABLETYPE=@pnOldTableType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldTableType	int,
					  @pnNewTableType	int',
					  @pnOldTableType,
					  @pnNewTableType

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

------------------------------------------------
-- Find all tables with referential constraints
-- to the TABLETYPE table and save these in 
-- a temporary table along with the column name.
------------------------------------------------
If @ErrorCode=0
Begin
	insert into @tblChildReferences(TABLENAME, COLUMNNAME)
	select  CU.TABLE_NAME, CU.COLUMN_NAME
	From INFORMATION_SCHEMA.TABLE_CONSTRAINTS C
		-- Find constraints that point to the parent Primary Key
	join INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC 	on (RC.UNIQUE_CONSTRAINT_NAME=C.CONSTRAINT_NAME)
		-- Now get the name of the foreign key column
	join INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU 	on (CU.CONSTRAINT_NAME=RC.CONSTRAINT_NAME)

	where C.TABLE_NAME='TABLETYPE'
	and C.CONSTRAINT_TYPE='PRIMARY KEY'
	order by 1,2

	Select  @ErrorCode=@@Error,
		@nRowCount=@@Rowcount
End

--------------------------------------------
-- For each table and column referencing the
-- TABLETYPE table, construct an UPDATE
-- statement to change the referenced
-- tablecode.
--------------------------------------------
Set @nSequenceNo=1

While @nSequenceNo<=@nRowCount
and @ErrorCode=0
Begin
	-------------------------------------
	-- Construct the UPDATE statement for
	-- the table and column referencing
	-- the TABLETYPE table.
	-------------------------------------
	Select @sSQLString='UPDATE '+TABLENAME+' set '+COLUMNNAME+'=@pnNewTableType WHERE '+COLUMNNAME+'=@pnOldTableType'
	from @tblChildReferences
	where SEQUENCENO=@nSequenceNo

	Set @ErrorCode=@@Error

	--------------------------------
	-- To keep table locks as short
	-- as possible, each referencing
	-- table will be updated within
	-- its own database transaction.
	--------------------------------
	If @ErrorCode=0
	Begin
		Set @TranCountStart = @@TranCount

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnOldTableType	int,
						  @pnNewTableType	int',
						  @pnOldTableType,
						  @pnNewTableType

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
	
	--------------------------------
	-- Increment the SequenceNo to
	-- get the next table.columnname
	--------------------------------
	Set @nSequenceNo=@nSequenceNo+1
End

-------------------------------
-- Now remove the old TableType
-------------------------------
If @ErrorCode=0
Begin
	Set @TranCountStart = @@TranCount

	Set @sSQLString="Delete TABLETYPE where TABLETYPE=@pnOldTableType"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldTableType	int',
					  @pnOldTableType

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

Return @ErrorCode
GO

Grant execute on dbo.tb_ChangeTableType to public
GO
