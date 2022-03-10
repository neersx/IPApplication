-----------------------------------------------------------------------------------------------------------------------------
-- Creation of tb_ChangeTableCode
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[tb_ChangeTableCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.tb_ChangeTableCode.'
	Drop procedure [dbo].[tb_ChangeTableCode]
End
Print '**** Creating Stored Procedure dbo.tb_ChangeTableCode...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.tb_ChangeTableCode
(
	@pnOldTableCode		int,
	@pnNewTableCode		int	= null	OUTPUT-- Null if a new code is to be assigned automatically
)
as
-- PROCEDURE:	tb_ChangeTableCode
-- VERSION:	2
-- DESCRIPTION:	Used to modify the TABLECODE value. This is required when a system
--		required code has already been allocated on a client database.
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 24-Jun-2010  MF	18409	1	Procedure created
-- 07 Jul 2011	DL	RFC10830 2	Specify database collation default to temp table columns of type varchar, nvarchar and char

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
-- old TableCode
------------------------
If not exists (select 1 from TABLECODES where TABLECODE=@pnOldTableCode)
and @ErrorCode=0
Begin
	RAISERROR('@pnOldTableCode does not exist in TABLECODE table', 14, 1)
	Set @ErrorCode = @@ERROR
End

----------------------------
-- Validate that the new 
-- TableCode has not already
-- been used.
----------------------------
If  @pnNewTableCode is not null
and @ErrorCode = 0 
Begin
	If exists (select 1 from TABLECODES where TABLECODE=@pnNewTableCode)
	Begin
		RAISERROR('@pnNewTableCode cannot be used as it already exists in TABLECODE table', 14, 1)
		Set @ErrorCode = @@ERROR
	End
End
--------------------------------------------------
-- If a replacement TableCode has not be supplied
-- then allocate the next number automatically.
--------------------------------------------------
If @pnNewTableCode is null
and @ErrorCode = 0 
Begin
	------------------------------------------------
	-- Keep this transaction as short as possible to 
	-- avoid locking the LASTINTERNALCODE table
	------------------------------------------------
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	------------------------------------------------------
	-- Get the next available TABLECODE value to use.
	------------------------------------------------------
	Set @sSQLString="
	Update LASTINTERNALCODE
	set INTERNALSEQUENCE=INTERNALSEQUENCE+1,
	    @pnNewTableCode =INTERNALSEQUENCE+1
	from LASTINTERNALCODE 
	where TABLENAME='TABLECODES'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnNewTableCode		int	OUTPUT',
				  @pnNewTableCode=@pnNewTableCode	OUTPUT

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
-- Copy the details of the existing TABLECODE
-- rows to the new TableCode. 
---------------------------------------------
If @ErrorCode=0
Begin
	Set @TranCountStart = @@TranCount

	Set @sSQLString="
	insert into TABLECODES(TABLECODE,TABLETYPE,DESCRIPTION,USERCODE)
	select @pnNewTableCode,TABLETYPE,DESCRIPTION,USERCODE
	from TABLECODES T
	where T.TABLECODE=@pnOldTableCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldTableCode	int,
					  @pnNewTableCode	int',
					  @pnOldTableCode,
					  @pnNewTableCode

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
-- to the TABLECODES table and save these in 
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

	where C.TABLE_NAME='TABLECODES'
	and C.CONSTRAINT_TYPE='PRIMARY KEY'
	order by 1,2

	Select  @ErrorCode=@@Error,
		@nRowCount=@@Rowcount
End

--------------------------------------------
-- For each table and column referencing the
-- TABLECODES table, construct an UPDATE
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
	-- the TABLECODES table.
	-------------------------------------
	Select @sSQLString='UPDATE '+TABLENAME+' set '+COLUMNNAME+'=@pnNewTableCode WHERE '+COLUMNNAME+'=@pnOldTableCode'
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
						N'@pnOldTableCode	int,
						  @pnNewTableCode	int',
						  @pnOldTableCode,
						  @pnNewTableCode

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
-- Now remove the old TableCode
-------------------------------
If @ErrorCode=0
Begin
	Set @TranCountStart = @@TranCount

	Set @sSQLString="Delete TABLECODES where TABLECODE=@pnOldTableCode"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnOldTableCode	int',
					  @pnOldTableCode

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

Grant execute on dbo.tb_ChangeTableCode to public
GO
