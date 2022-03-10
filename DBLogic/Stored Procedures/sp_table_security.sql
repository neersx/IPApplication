-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sp_table_security
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[sp_table_security]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.sp_table_security'
	drop procedure dbo.sp_table_security
end
print '**** Creating procedure dbo.sp_table_security...'
print ''
go

SET QUOTED_IDENTIFIER OFF    
go
SET ANSI_NULLS  OFF 
go

CREATE PROCEDURE dbo.sp_table_security
( 
	@objname 		nvarchar(776) = NULL,		-- object name we're after
	@username           	varchar(30) = null, 		-- the user name no longer used, use the connected user
       	@security_level     	int output,
       	@update_col_list    	varchar(254) = null output
)
AS
-- PROCEDURE :	sp_table_security
-- VERSION :	2.1.0
-- DESCRIPTION:	
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 09/12/1996	AWF	Remove the need for a temporary table
-- 31/12/1996	AWF	Cater for Aliased users
-- 18/02/1997	AWF	Use the login name not the user name for checking if a valid user
-- 12/06/1997	AWF	Fix bug with non alias users
-- 28/07/1997	AWF	Cater for the system administrator having full rights
-- 29/02/2000	AWF	SqlServer 7 specific version with performance improvements
-- 10/10/2000	AB	Added if clause to check which sp_table_security to create depending on database SQLServer level
-- 07/10/2003	AB	Change formatting for Clear Case generation
-- 27/09/2013	DL	Resolve compatibility with SQL Server 2012

-- PRELIMINARY
set nocount on

-- declarations
declare     @sl_select    	int,
            @sl_delete    	int,
       	    @sl_insert    	int,
            @sl_update    	int,
       	    @sl_select_columns  int,
       	    @sl_update_columns  int

-- constants assignment
select @sl_select = 1
select @sl_delete = 2
select @sl_insert = 4
select @sl_update = 8
select @sl_update_columns = 16
select @sl_select_columns = 32
select @security_level = 0
select @update_col_list = null

if (@objname is NULL or @username is NULL)
begin
	--raiserror 20001 'Syntax is "table_security table-name, user-name, security-level output"'
	raiserror ( 'Syntax is "table_security table-name, user-name, security-level output"', 16, 1)
	return 1
end

-- Make sure the @objname is local to the current database.
declare	@dbname	sysname
select @dbname = parsename(@objname,3) 

if @dbname is not null and @dbname <> db_name()
begin
	raiserror(15250,-1,-1)
	return(1)
end

declare @tbname sysname
select @tbname = parsename(@objname,1) 
if @tbname is null 
begin
	--raiserror 20007 'A table name must be supplied'
	raiserror ( 'A table name must be supplied', 16, 1)
        return (1)
end

declare @objid int
select @objid = id from sysobjects where id = object_id(@tbname) and xtype = 'U'
if @objid is null 
begin
	--raiserror 20007 'No such table exists in the database.'
	raiserror ('No such table exists in the database.', 16,1)
        return (1)
end

declare @objpermissions int
select @objpermissions = permissions(@objid)
if @objpermissions&1=1
	select @security_level = @security_level|@sl_select
else if @objpermissions&4096=4096	-- select specific columns
begin
	Select @security_level = @security_level|@sl_select_columns
end

if @objpermissions&2=2
	Select @security_level = @security_level|@sl_update
else if @objpermissions&8192=8192	-- update specific columns
begin
	Select @security_level = @security_level|@sl_update_columns
	declare @granted_column varchar(80)
	DECLARE cols_cursor CURSOR FOR
	SELECT COL_NAME(object_id(@tbname), ORDINAL_POSITION)
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = @tbname
		OPEN cols_cursor
		FETCH NEXT FROM cols_cursor
		INTO @granted_column
		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- This is executed as long as the previous fetch succeeds.
			if permissions(@objid,@granted_column)&2=2
			begin
				if @update_col_list is null
					select @update_col_list = @granted_column
				else
					select @update_col_list = @update_col_list + ',' + @granted_column
			end
			FETCH NEXT FROM cols_cursor
			INTO @granted_column
	END  
	CLOSE cols_cursor
	DEALLOCATE cols_cursor
end

if @objpermissions&8=8
	Select @security_level = @security_level|@sl_insert

if @objpermissions&16=16
	Select @security_level = @security_level|@sl_delete

return 0
go

SET ANSI_NULLS ON 
go

grant execute on dbo.sp_table_security to public
go
