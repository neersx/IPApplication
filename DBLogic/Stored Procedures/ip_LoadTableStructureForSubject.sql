-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_LoadTableStructureForSubject
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_LoadTableStructureForSubject]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_LoadTableStructureForSubject.'
	Drop procedure [dbo].[ip_LoadTableStructureForSubject]
End
Print '**** Creating Stored Procedure dbo.ip_LoadTableStructureForSubject...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- The procedure is recursively called.
-- This CREATE will stop a warning message appearing.
CREATE PROCEDURE dbo.ip_LoadTableStructureForSubject
as
go

ALTER PROCEDURE dbo.ip_LoadTableStructureForSubject
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pnDepth		tinyint		= 1	-- Internally used parameter for recursive calls
)
as
-- PROCEDURE:	ip_LoadTableStructureForSubject
-- VERSION :	6
-- DESCRIPTION:	Returns the table and columns that have been logged for a given subject area

-- MODIFICATIONS :
-- Date		Who	Version	Change	Description
-- ------------	-------	-------	------	----------------------------------------------- 
-- 24-JUN-2005  MF	1		Procedure created
-- 14-JUL-2005	MF	2	SQA8238	Format the Display Name in the output result set as
--					COLUMN_NAME (TABLE_NAME)
-- 16-Sep-2005	MF	3	11869	Don't return SEQUENCE columns
-- 15-Mar-2007	MF	4	14569	Clear out the SUBJECTAREATABLES when procedure starts.
--					Manually load tables that do cannot be grouped logically
--					from the foreign key constraints.
-- 13-JUL-2007	MF	5	15029	Make certain that the row being inserted into SUBJECTAREATABLES
--					does not already exist
-- 17-03-2010	DL	6	18677	Not all children tables of audit subjects are generated for auditing

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@ErrorCode		int
declare @nChildCount		smallint
declare @sSQLString		nvarchar(4000)
declare @sTempTables		nvarchar(50)
declare @sTempColumns		nvarchar(50)

-- Initialise variables
Set @ErrorCode = 0

-- The first time the procedure is called
-- clear out the SUBECTAREATABLES

If @ErrorCode=0
and @pnDepth=1
Begin
	Set @sSQLString="delete from SUBJECTAREATABLES"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Initialise the SUBJECTAREATABLES with the Parent table for each Subject Area.
 
If (select count(*) from SUBJECTAREATABLES)=0
Begin
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into SUBJECTAREATABLES (SUBJECTAREANO, TABLENAME,DEPTH)
		select S.SUBJECTAREANO, S.PARENTTABLE, 1
		from SUBJECTAREA S"
		--where S.SUBJECTAREANO=@pnSubjectArea"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnDepth		tinyint',
					  @pnDepth=@pnDepth
	End
End

-- Return Child Tables where primary key of Parent Table
-- is referenced by Child Table.  A flag is required
-- to indicate if the Child primary key incorporates
-- the pointer back to the Parent.

-- Return Child Tables where primary key of Parent
-- is included in Primary Key of Child.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into SUBJECTAREATABLES (SUBJECTAREANO, TABLENAME,DEPTH)
	select  distinct T.SUBJECTAREANO, C1.TABLE_NAME, @pnDepth+1
	from SUBJECTAREATABLES T
		-- Get the Primary Key of the parent table
	join INFORMATION_SCHEMA.TABLE_CONSTRAINTS C 		on (C.TABLE_NAME=T.TABLENAME
								and C.CONSTRAINT_TYPE='PRIMARY KEY')
		-- Find constraints that point to the parent Primary Key
	join INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC 	on (RC.UNIQUE_CONSTRAINT_NAME=C.CONSTRAINT_NAME)
		-- Find the foreign key constraints that point to the parent Primary Key
		-- for the tables that are to be reported on 
	join INFORMATION_SCHEMA.TABLE_CONSTRAINTS C1		on (C1.CONSTRAINT_TYPE='FOREIGN KEY'
								and C1.CONSTRAINT_NAME=RC.CONSTRAINT_NAME)
		-- Now get the name of the foreign key column
	join INFORMATION_SCHEMA.KEY_COLUMN_USAGE  KC 		on (KC.CONSTRAINT_NAME=C1.CONSTRAINT_NAME)
		-- Ensure the Column of Parent primary key is a column of the Child Primary Key
	join INFORMATION_SCHEMA.TABLE_CONSTRAINTS C2		on (C2.CONSTRAINT_TYPE='PRIMARY KEY'
								and C2.TABLE_NAME=C1.TABLE_NAME)
		-- Make certain that the parent key column has the same key column position as the foreign key
		-- SQL18477 change to left join to allow parent key column not to be part of child primary key.  
	left join INFORMATION_SCHEMA.KEY_COLUMN_USAGE  KC2 		on (KC2.CONSTRAINT_NAME=C2.CONSTRAINT_NAME
								and KC2.COLUMN_NAME=KC.COLUMN_NAME
								and KC2.ORDINAL_POSITION=KC.ORDINAL_POSITION)
	left join SUBJECTAREATABLES S				on (S.SUBJECTAREANO=T.SUBJECTAREANO
								and S.TABLENAME=C1.TABLE_NAME)
	where T.DEPTH=@pnDepth
	and S.SUBJECTAREANO is null"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnDepth	tinyint',
				  @pnDepth=@pnDepth
	
	Set @nChildCount=@@Rowcount
End

-- If rows have been added to the list of tables then call
-- the stored procedure recursively to load the next level
-- of child tables.
If @ErrorCode=0
Begin
	If @nChildCount>0
	and @pnDepth<16		-- limit on level of recursive calls
	Begin
		Set @pnDepth=@pnDepth+1
		
		exec @ErrorCode=dbo.ip_LoadTableStructureForSubject
						@pnUserIdentityId,
						@psCulture,
						@pnDepth
	End
End

-------------------------------------------------------------------
-- The following section is to manually load tables that logically
-- belong in a subject area however the foreign key constraints
-- do not naturally cause the table to be loaded.
-- These tables will be loaded as the final step when the recursive
-- procedure is in its final step.
-------------------------------------------------------------------
If @pnDepth=2
Begin
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Insert into SUBJECTAREATABLES(SUBJECTAREANO, TABLENAME,DEPTH)
		select S.SUBJECTAREANO, 'ADDRESS', 3
		from SUBJECTAREA S
		left join SUBJECTAREATABLES ST	on (ST.SUBJECTAREANO=S.SUBJECTAREANO
						and ST.TABLENAME='ADDRESS')
		where S.PARENTTABLE='NAME'
		and ST.SUBJECTAREANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Insert into SUBJECTAREATABLES(SUBJECTAREANO, TABLENAME,DEPTH)
		select S.SUBJECTAREANO, 'TELECOMMUNICATION', 3
		from SUBJECTAREA S
		left join SUBJECTAREATABLES ST	on (ST.SUBJECTAREANO=S.SUBJECTAREANO
						and ST.TABLENAME='TELECOMMUNICATION')
		where S.PARENTTABLE='NAME'
		and ST.SUBJECTAREANO is null"
	
		exec @ErrorCode=sp_executesql @sSQLString
	End
End

Return @ErrorCode
GO

Grant execute on dbo.ip_LoadTableStructureForSubject to public
GO
