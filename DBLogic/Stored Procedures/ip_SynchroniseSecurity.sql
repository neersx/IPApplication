-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_SynchroniseSecurity
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_SynchroniseSecurity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_SynchroniseSecurity.'
	drop procedure dbo.ip_SynchroniseSecurity
	print '**** Creating procedure dbo.ip_SynchroniseSecurity...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create	procedure dbo.ip_SynchroniseSecurity
AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

---------------------------------------------------------------------------------------------------
-- PROCEDURE :	ip_SynchroniseSecurity
-- VERSION :	5
-- TITLE :	Synchronize SQL security with SECURITY settings in InProtech database
--
-- DESCRIPTION:	1. This procedure extracts the current table-level permissions from the
--		current database, calculates the security flag for Inprotech, compares
--		that information with the Inprotech security flag and corrects mismatches.
--		The procedure will only check permissions on tables that have been defined
--		in SECURITYTEMPLATE at least once. All other tables are left unchanged.
--		All permissions are always granted to SYSADM, regardless of the actual
--		security configuration. This is to ensure full access at all times.
--		2. Ths procedure also sets permissions for procedures and functions. These
--		are however set	undiscriminatingly to 'execute' ('select' for some functions).
--			
-- CONTEXT:	Inprotech
--
-- DEPENDENCIES: 	
--		This procedure does not use SQL's schema views for extracting permissions
--		because these are to slow. As a consequence, future versions of SQL might
--		require (minor) changes to the procedure.
--
-- RETURNS:	Returncode (0=success, -1=failure)
--
--
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 03 Apr 2001	IPsIT		1	Procedure created by Sjoerd Koneijnenburg.
-- 26 Aug 2005	IPsIT		2	Modified for general release via CPASS.
-- 07 Sep 2005	JEK		3	Implement collate database_default to avoid collation conflicts.
-- 12 Sep 2005	TM		4	Standardise stored procedure to conform to the coding standards.
-- 16 Feb 2006	SW	12628	5	Change grant all to grant DELETE, INSERT, REFERENCES, SELECT, and UPDATE

---------------------------------------------------------------------------------------------------
-----	Initialization
---------------------------------------------------------------------------------------------------
-----	Declare local variables
Declare	@nErrorCode		int,
	@nSecurityFlag_soll	int,
	@nSecurityFlag_isst	int,
	@sObjectName		sysname,
	@sObjectType		nchar(02),
	@sAccessRight		nvarchar(25),
	@sUserID		nvarchar(128),
	@sSQL			nvarchar(512),
	@TransactionCountStart 	int

-----	Declare table variable to hold current SQL permissions
Declare	@tblPERMISSIONS_SQL	table
	(
	TABLENAME		sysname		collate database_default NULL,
	USERID			nvarchar(128)	collate database_default NULL,
	SECURITYFLAG		int		NULL
	)

-----	Initialize variables
	Set	@nErrorCode	= 0

-- Commence the transaction
Set @TransactionCountStart = @@TranCount
BEGIN TRANSACTION	

---------------------------------------------------------------------------------------------------
-----	Verify permissions on tables by comparing SQL-permissions against Inprotech security
---------------------------------------------------------------------------------------------------
-----	Collect compound security flag per table/user pair from SQL database
If	@nErrorCode = 0
Begin
	Raiserror ('Collecting current SQL permissions for all tables',0,1) with nowait
	Insert	into	@tblPERMISSIONS_SQL 
		(TABLENAME, USERID, SECURITYFLAG)
	Select	tbl.name,				-- name of object (read: table)
		usr.name,				-- name of user in SQL database
		sum(case prot.action
			 when 193 then 1		-- value for 'select'
			 when 196 then 2		-- value for 'delete'
			 when 195 then 4		-- value for 'insert'
			 when 197 then 8		-- value for 'update'
				  else 0		-- default value
		    end) 
	from	sysobjects tbl				-- select all tables
	full	join	sysusers usr			-- combine with all normal users/roles
		on    ( usr.isntuser  = 1
		  or   (usr.issqluser = 1 and usr.status = 2 and usr.name <> 'dbo') )
	left	join	sysprotects prot		-- get permissions per table+user
		on	prot.id = tbl.id
		and	prot.uid = usr.uid
	where	tbl.type = 'U'
	and	tbl.name <> 'dt_properties'		-- ignore special SQL table
	group	by tbl.name, usr.name
	order 	by tbl.name, usr.name
	Set	@nErrorCode = @@error
End

-----	Declare cursor for reading table rights defined in Inprotech
If	@nErrorCode = 0
Begin
	Raiserror ('Searching incorrect SQL permissions',0,1) with nowait
	Declare	csrTABLEUSERS cursor for
		Select	sql.TABLENAME,
			sql.USERID,
			max(isnull(st.SECURITYFLAG,0)), 
			max(sql.SECURITYFLAG)
		from	@tblPERMISSIONS_SQL sql		-- lists all SQL tables
		left	join	USERPROFILES up		-- get rights for user ...
			on	up.USERID = sql.USERID
		left	join	SECURITYTEMPLATE st	-- ... and table
			on	st.NAMEOFTABLE = sql.TABLENAME
			and	st.PROFILE = up.PROFILE
		where	exists				-- if permissions are controlled via Inprotech
			(select	1
			from	SECURITYTEMPLATE
			where	NAMEOFTABLE = sql.TABLENAME)
		group	by sql.TABLENAME, sql.USERID
		having	max(isnull(st.SECURITYFLAG,0)) <> max(isnull(sql.SECURITYFLAG,0))
		order	by sql.TABLENAME, sql.USERID
	Set	@nErrorCode = @@error
End


-----	Process each table+user pair where SQL permissions are not correct
If	@nErrorCode = 0
Begin
	Raiserror ('Correcting table permissions',0,1) with nowait
	-----	Open cursor and read first table+user pair
	Open	csrTABLEUSERS
	Fetch	csrTABLEUSERS
	into	@sObjectName, @sUserID, @nSecurityFlag_soll, @nSecurityFlag_isst
	Set	@nErrorCode = @@error
	-----	Process all pairs
	While	@nErrorCode    = 0
	and	@@Fetch_Status = 0
	Begin
		-----	Initially revoke all rights
		Select	@sSQL = 'Revoke DELETE, INSERT, REFERENCES, SELECT, UPDATE on ' + @sObjectName + ' from [' + @sUserID + ']'
		Exec	(@sSQL)
		-----	Compose permissions based on securityflags in Inprotech
		Set	@sSQL   = case when (@nSecurityFlag_soll & 1) = 1 then 'SELECT,' else '' end
				+ case when (@nSecurityFlag_soll & 2) = 2 then 'DELETE,' else '' end
				+ case when (@nSecurityFlag_soll & 4) = 4 then 'INSERT,' else '' end
				+ case when (@nSecurityFlag_soll & 8) = 8 then 'UPDATE,' else '' end
		-----	Grant all rights to system administrator, regardless of Inprotech settings
		-----	all is deprecated and replaced by DELETE, INSERT, REFERENCES, SELECT, and UPDATE
		If	@sUserID = 'SYSADM'
			Select	@sSQL = 'DELETE, INSERT, REFERENCES, SELECT, UPDATE,'
		-----	Finalise and execute the grant statement
		If	@sSQL <> ''
		Begin
			Set	@sSQL 	= 'Grant ' + left(@sSQL,len(@sSQL)-1) 
					+ ' on ' + @sObjectName + ' to [' + @sUserID + ']'
			Exec	(@sSQL) 
			Set	@nErrorCode = @@error  
		End
			
		If @nErrorCode = 0
		Begin
			-----	Fetch next table_user pair
			Fetch	csrTABLEUSERS
			into	@sObjectName, @sUserID, @nSecurityFlag_soll, @nSecurityFlag_isst
			Set	@nErrorCode = @@error
		End
	End
End

-----	Release the cursor
Close	csrTABLEUSERS
Deallocate csrTABLEUSERS

---------------------------------------------------------------------------------------------------
-----	Grant execute rights to public for procedures and functions
---------------------------------------------------------------------------------------------------
-----	Declare cursor for reading user-defined procedures and functions
If	@nErrorCode = 0
Begin
	Raiserror ('Collecting SQL procedures and functions',0,1) with nowait
	Declare	csrOBJECTS cursor for
		Select	name, type, 
			case	type				-- translate type to grant type
				when 'P'  then 'EXECUTE'
				when 'FN' then 'EXECUTE'
				when 'IF' then 'SELECT'
				when 'TF' then 'SELECT'
			end
			from	sysobjects
			where	type in ('P','FN','TF','IF')	-- select procedures and functions
			and	name not like 'dt%'		-- ignore SQL system objects
			order	by type, name
	Set	@nErrorCode = @@error
End

-----	Process each procedure/function and set SQL permissions to execute/select
If	@nErrorCode = 0
Begin
	Raiserror ('Setting permissions for procedures and functions',0,1) with nowait
	-----	Open cursor and read name of first object
	Open	csrOBJECTS
	Fetch	csrOBJECTS
	into	@sObjectName, @sObjectType, @sAccessRight
	-----	Process all selected objects
	While	(@@Fetch_Status <> -1)
	and @nErrorCode = 0
	Begin
		Set	@sSQL = 'Grant ' + @sAccessRight + ' on ' + @sObjectName + ' to public'
		Exec	(@sSQL)  
		Set	@nErrorCode = @@error

		If @nErrorCode = 0
		Begin
			-----	Fetch next procedure or function
			Fetch	csrOBJECTS
			into	@sObjectName, @sObjectType, @sAccessRight
			Set	@nErrorCode = @@error
		End
	End
End

-----	Release the cursor
Close	csrOBJECTS
Deallocate csrOBJECTS

-----	Finalize with appropriate message
If @@TranCount > @TransactionCountStart
Begin		
	If @nErrorCode = 0
	Begin
		Raiserror ('Finished security synchronisation!',0,1)
		COMMIT TRANSACTION
	End
	Else Begin
		Raiserror ('One or more errors found',16,1)
		ROLLBACK TRANSACTION
	End
End	

Go


grant execute on dbo.ip_SynchroniseSecurity to public
go