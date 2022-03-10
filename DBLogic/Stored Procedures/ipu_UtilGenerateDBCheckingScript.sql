-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_UtilGenerateDBCheckingScript
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipu_UtilGenerateDBCheckingScript]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipu_UtilGenerateDBCheckingScript.'
	drop procedure dbo.ipu_UtilGenerateDBCheckingScript
	print '**** Creating procedure dbo.ipu_UtilGenerateDBCheckingScript'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE [dbo].[ipu_UtilGenerateDBCheckingScript]
	
AS

-- PROCEDURE :	ipu_UtilGenerateDBCheckingScript
-- VERSION :	8
-- DESCRIPTION:	Generates a script that can be delivered with each release to check if 
--		the database run against matches the structure of the database the script 
--		was extracted from.

-- MODIFICATION
-- Date			Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
--  2 Jun 2009	MF	RFC8095	1	Procedure created
-- 23 Jun 2009	MF	RFC8184	2	The warning message is not reporting the table name correctly when 
--					additional non standard table found.
-- 21 Sep 2011	MF	R11323	3	Ignore columns on the client database with type uniqueidentifier as these
--					are added for database replication purposes deliberately.
-- 07 Oct 2011	MF	R11373	4	Extract the VERSION for functions and stored procedures so this can be used
--					in the data comparison.
-- 08 Nov 2015	DL	R49210	5	- Add 'Carriage return' char(13) to the 'Line feed' char(10) so that the generated file does not cause the warning error 
--					  'Inconsistent Line Endings' when open in SQL Server 2012.
--					- Add 'collate database_default' to resolve collation conflict between system tables and temp table comparison.
--					- Replace old SQL Server 2000 objects e.g  sysobjects with new comparable objects  e.g sys.objects. 
--					- And only include objects with schema = dbo.
-- 31 May 2018	MF	73921	6	Include the schema name when reporting non Inprotech tables found in the database.
-- 23 Jul 2018	MF	74629	7	Extend the check to see if procedural code in Triggers, Functions and Stored Procedures have changed.  This is done by sending a CHECKSUM
--					value based on a standard collation matches the same checksum on the clients database using the same collation.
-- 31 Oct 2018	DL	DR-45102	8	Replace CRLF with LF on the files before calling CHECKSUM

Set NOCOUNT ON

Declare	@ErrorCode		int
Declare @sDBVersion		nvarchar(254)

Set @ErrorCode=0

----------------------------------
-- Get the Version of the database
-- generating the script
----------------------------------
If @ErrorCode=0
Begin
	Select @sDBVersion=COLCHARACTER
	from SITECONTROL
	where CONTROLID='DB Release Version'
	
	Set @ErrorCode=@@Error

	If @sDBVersion is null
	and @ErrorCode=0
	Begin
		RAISERROR('DB Release Version on SITECONTROL must have a value', 14, 1)
		Set @ErrorCode = @@ERROR
	End
End

If @ErrorCode=0
Begin
	Select 
	'--------------------------------------------------'+char(13)+char(10)+
	'-- D A T A B A S E   C H E C K I N G   S C R I P T'+char(13)+char(10)+
	'--------------------------------------------------'+char(13)+char(10)+
	'-- Inpro '+@sDBVersion+char(13)+char(10)+
	'-- Check TABLES & COLUMNS'+char(13)+char(10)+
	'-- Check INTEGRITY'+char(13)+char(10)+
	'-- Check TRIGGERS'+char(13)+char(10)+
	'-- Check FUNCTIONS'+char(13)+char(10)+
	'-- Check STOREDPROCEDURES'+char(13)+char(10)+
	'-- Check INDEXES'+char(13)+char(10)+char(13)+char(10)+
	'Set nocount on'+char(13)+char(10)+
	'----------------------------------'+char(13)+char(10)+
	'-- Create temporary table to store'+char(13)+char(10)+
	'-- baseline database structure'+char(13)+char(10)+
	'----------------------------------'+char(13)+char(10)+
	'Create table #TEMPBASELINE ('+char(13)+char(10)+
	'	ITEMTYPE		char(2)		collate database_default NOT NULL,'+char(13)+char(10)+
	'	OBJECTNAME		varchar(100)	collate database_default NOT NULL,'+char(13)+char(10)+
	'	SUBOBJECT		varchar(100)	collate database_default NULL,'+char(13)+char(10)+
	'	VERSION			varchar(128)	collate database_default NULL,'+char(13)+char(10)+
	'	CHECKSUMVALUE		int		                         NULL'+char(13)+char(10)+
	')'+char(13)+char(10)+char(13)+char(10)+
	
	'--------------------'+char(13)+char(10)+
	'-- Check the Version'+char(13)+char(10)+
	'-- in SITECONTROL'+char(13)+char(10)+
	'--------------------'+char(13)+char(10)+
	'If not exists(select 1 from SITECONTROL where CONTROLID=''DB Release Version'' and COLCHARACTER='''+@sDBVersion+''')'+char(13)+char(10)+
	'begin'+char(13)+char(10)+
	'	print '''' '+char(13)+char(10)+
	'	print ''**** ERROR - SITECONTROL DB Release Version is not set to '''''+@sDBVersion+''''' ****'''+char(13)+char(10)+
	'	print '''' '+char(13)+char(10)+
	'end'+char(13)+char(10)+
	'else begin'+char(13)+char(10)+
	'	print '''' '+char(13)+char(10)+
	'	print ''**** Loading temporary base line data to check database structure against ****'''+char(13)+char(10)+
	'	----------------------'+char(13)+char(10)+
	'	-- Load a row for each'+char(13)+char(10)+
	'	-- Table and Column'+char(13)+char(10)+
	'	----------------------'+char(13)+char(10)+
	'	print ''**** Loading table & column names ****'''
	
	select
	'	insert into #TEMPBASELINE(ITEMTYPE,OBJECTNAME,SUBOBJECT) values(''TC'','''+TABLE_NAME+''','''+COLUMN_NAME+''')'
	from INFORMATION_SCHEMA.COLUMNS
	join sys.objects s on (s.type='U'
	                  and s.name=TABLE_NAME)
	where TABLE_NAME not like '%iLOG%'
	and COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
	and TABLE_SCHEMA = 'dbo'
	order by TABLE_NAME, ORDINAL_POSITION
	
	Select 
	'	-----------------------'+char(13)+char(10)+
	'	-- Load a row for each'+char(13)+char(10)+
	'	-- Table and Constraint'+char(13)+char(10)+
	'	-----------------------'+char(13)+char(10)+
	'	print ''**** Loading table constraint names ****'''
	
	select distinct
	'	insert into #TEMPBASELINE(ITEMTYPE,OBJECTNAME,SUBOBJECT) values(''CN'','''+TABLE_NAME+''','''+CONSTRAINT_NAME+''')'
	from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
	where TABLE_NAME not like '%iLOG%'
	and CONSTRAINT_SCHEMA = 'dbo'
	order by 1
	
	Select 
	'	-----------------------'+char(13)+char(10)+
	'	-- Load a row for each'+char(13)+char(10)+
	'	-- Function & Procedure'+char(13)+char(10)+
	'	-----------------------'+char(13)+char(10)+
	'	print ''**** Loading functions & procedures names ****'''
	
	select 
	'	insert into #TEMPBASELINE(ITEMTYPE,OBJECTNAME, VERSION, CHECKSUMVALUE) values('+CASE(ROUTINE_TYPE) WHEN('FUNCTION') THEN '''FN''' WHEN('PROCEDURE') THEN '''SP''' END+','''+ROUTINE_NAME+''','''+isnull(dbo.fn_GetStoredProcedureVersion(ROUTINE_NAME),'')+''','+cast(CHECKSUM(CAST(Replace(s.definition, char(13)+char(10), char(10)) as NVARCHAR(max)) COLLATE Latin1_General_CI_AS) as nvarchar)+')'
	from INFORMATION_SCHEMA.ROUTINES I
	join sys.objects o on (o.name=I.ROUTINE_NAME)
	join sys.sql_modules s on (s.object_id=o.object_id)
	where I.ROUTINE_TYPE in ('FUNCTION','PROCEDURE')
	and I.ROUTINE_SCHEMA = 'dbo'
	order by I.ROUTINE_TYPE,I.ROUTINE_NAME
	
	Select 
	'	----------------------'+char(13)+char(10)+
	'	-- Load a row for each'+char(13)+char(10)+
	'	-- table trigger'+char(13)+char(10)+
	'	----------------------'+char(13)+char(10)+
	'	print ''**** Loading table triggers ****'''
	
	select 
	'	insert into #TEMPBASELINE(ITEMTYPE,OBJECTNAME, CHECKSUMVALUE) values(''TR'','''+o.name+''','+cast(CHECKSUM(CAST(Replace(s.definition, char(13)+char(10), char(10)) as NVARCHAR(max)) COLLATE Latin1_General_CI_AS) as nvarchar)+')'
	from sys.objects o
	join sys.sql_modules s on (s.object_id=o.object_id)
	where o.type='TR'
	and o.name not like '%AUDIT'
	order by o.name
	
	Select 
	'	----------------------'+char(13)+char(10)+
	'	-- Load a row for each'+char(13)+char(10)+
	'	-- Index'+char(13)+char(10)+
	'	----------------------'+char(13)+char(10)+
	'	print ''**** Loading index names ****'''
	
	select distinct
	'	insert into #TEMPBASELINE(ITEMTYPE,OBJECTNAME,SUBOBJECT) values(''IX'','''+C2.name+''','''+C1.name+''')'
	from sysindexes C1 
	join sys.objects C2 ON (C2.object_id=C1.id) 
	where C2.name not like '%iLOG%'
	and C1.name not like '_WA_Sys_%'
	order by 1
	
	Select
	'	----------------------------------------'+char(13)+char(10)+
	'	-- Now load the index on temporary table'+char(13)+char(10)+
	'	----------------------------------------'+char(13)+char(10)+
	'	print ''**** Building index on temporary table ****'''+char(13)+char(10)+
	'	print '''' '+char(13)+char(10)+
	'	Create Clustered Index XPKTEMPBASELINE ON #TEMPBASELINE'+char(13)+char(10)+
	'	(	ITEMTYPE,'+char(13)+char(10)+
	'		OBJECTNAME)'+char(13)+char(10)+char(13)+char(10)+	
	
	'	set CONCAT_NULL_YIELDS_NULL off'+char(13)+char(10)+char(13)+char(10)+
	
	'	Declare @nRowCount	int'+char(13)+char(10)+char(13)+char(10)+
	
	'	----------------------------'+char(13)+char(10)+
	'	-- Check tables on this'+char(13)+char(10)+
	'	-- database against baseline'+char(13)+char(10)+
	'	----------------------------'+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - table ''+T.OBJECTNAME+'' not found ****'''+char(13)+char(10)+
	'	from (select distinct OBJECTNAME from #TEMPBASELINE where ITEMTYPE=''TC'') T'+char(13)+char(10)+
	'	left join sys.objects s on (s.type=''U'''+char(13)+char(10)+
	'			       and s.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'	where s.name is null'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All required tables exist ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)+
	
	'	----------------------------'+char(13)+char(10)+
	'	-- Check columns on this'+char(13)+char(10)+
	'	-- database against baseline'+char(13)+char(10)+
	'	----------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - table ''+T.OBJECTNAME+'' is missing column ''+T.SUBOBJECT+'' ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	join sys.objects s on (s.type=''U'''+char(13)+char(10)+
	'			  and s.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'       left join INFORMATION_SCHEMA.COLUMNS C on (C.TABLE_NAME collate database_default=T.OBJECTNAME'+char(13)+char(10)+
	'                                              and C.COLUMN_NAME collate database_default=T.SUBOBJECT)'+char(13)+char(10)+
	'	where T.ITEMTYPE=''TC'''+char(13)+char(10)+
	'       and C.TABLE_NAME is null'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All required table columns exist ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)+
	
	'	----------------------------'+char(13)+char(10)+
	'	-- Check contraints on this'+char(13)+char(10)+
	'	-- database against baseline'+char(13)+char(10)+
	'	----------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - table ''+T.OBJECTNAME+'' is missing constraint ''+T.SUBOBJECT+'' ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	join sys.objects s on (s.type=''U'''+char(13)+char(10)+
	'			  and s.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'       left join INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C on (C.TABLE_NAME collate database_default=T.OBJECTNAME'+char(13)+char(10)+
	'                                                              and C.CONSTRAINT_NAME collate database_default=T.SUBOBJECT)'+char(13)+char(10)+
	'	where T.ITEMTYPE=''CN'''+char(13)+char(10)+
	'       and C.TABLE_NAME is null'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All required table constraints exist ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)+
	
	'	----------------------------'+char(13)+char(10)+
	'	-- Check indexes on this'+char(13)+char(10)+
	'	-- database against baseline'+char(13)+char(10)+
	'	----------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - table ''+T.OBJECTNAME+'' is missing index ''+T.SUBOBJECT+'' ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	join sys.objects s on (s.type=''U'''+char(13)+char(10)+
	'			  and s.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'	left join sysindexes C1 on (C1.name collate database_default=T.SUBOBJECT)'+char(13)+char(10)+
	'	left join sys.objects C2 on (C2.object_id=C1.id'+char(13)+char(10)+
	'                               and C2.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'	where T.ITEMTYPE=''IX'''+char(13)+char(10)+
	'	and C2.name is null'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All required table indexes exist ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)+
	
	'	----------------------------'+char(13)+char(10)+
	'	-- Check triggers on this'+char(13)+char(10)+
	'	-- database exist'+char(13)+char(10)+
	'	----------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - trigger ''+T.OBJECTNAME+ '' not found ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	left join sys.objects o on (o.type=''TR'''+char(13)+char(10)+
	'			       and o.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'	where T.ITEMTYPE=''TR'''+char(13)+char(10)+
	'	and o.name is null'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All required triggers exist ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)+
	
	'	----------------------------'+char(13)+char(10)+
	'	-- Check triggers on this'+char(13)+char(10)+
	'	-- database match code'+char(13)+char(10)+
	'	----------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - trigger ''+T.OBJECTNAME+ '' does not match standard code ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	join sys.objects o on (o.type=''TR'''+char(13)+char(10)+
	'			   and o.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'	join sys.sql_modules s on (s.object_id=o.object_id)'+char(13)+char(10)+
	'	where T.ITEMTYPE=''TR'''+char(13)+char(10)+
	'	and T.CHECKSUMVALUE<>CHECKSUM(CAST(Replace(s.definition, char(13)+char(10), char(10)) as NVARCHAR(max)) COLLATE Latin1_General_CI_AS)'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All required triggers exist ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)+

	
	'	--------------------------------'+char(13)+char(10)+
	'	-- Check functions exist on this'+char(13)+char(10)+
	'	-- database against baseline'+char(13)+char(10)+
	'	--------------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - function ''+T.OBJECTNAME+ '' not found ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	left join sys.objects o on (o.type in(''FN'',''TF'',''IF'')'+char(13)+char(10)+
	'			       and o.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'	where T.ITEMTYPE=''FN'''+char(13)+char(10)+
	'	and o.name is null'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All required functions exist ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)+
	
	'	----------------------------'+char(13)+char(10)+
	'	-- Check functions on this'+char(13)+char(10)+
	'	-- database match version on'+char(13)+char(10)+
	'	-- the baseline'+char(13)+char(10)+
	'	----------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - function ''+T.OBJECTNAME+'' version ''+isnull(dbo.fn_GetStoredProcedureVersion(R.ROUTINE_NAME),'' '')+'' mismatch with ''+T.VERSION+'' ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	join INFORMATION_SCHEMA.ROUTINES R'+char(13)+char(10)+
	'	                  on (R.ROUTINE_NAME collate database_default=T.OBJECTNAME'+char(13)+char(10)+
	'	                  and R.ROUTINE_TYPE=''FUNCTION'')'+char(13)+char(10)+
	'	where T.ITEMTYPE=''FN'''+char(13)+char(10)+
	'	and T.VERSION<>dbo.fn_GetStoredProcedureVersion(R.ROUTINE_NAME)'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All non-encrypted functions match on VERSION ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)+

	
	'	--------------------------------'+char(13)+char(10)+
	'	-- Check functions exist on this'+char(13)+char(10)+
	'	-- database against baseline'+char(13)+char(10)+
	'	--------------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - function ''+T.OBJECTNAME+ '' does not match standard code ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	join sys.objects o on (o.type in(''FN'',''TF'',''IF'')'+char(13)+char(10)+
	'			   and o.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'	join sys.sql_modules s on (s.object_id=o.object_id)'+char(13)+char(10)+
	'	where T.ITEMTYPE=''FN'''+char(13)+char(10)+
	'	and T.CHECKSUMVALUE<>CHECKSUM(CAST(Replace(s.definition, char(13)+char(10), char(10)) as NVARCHAR(max)) COLLATE Latin1_General_CI_AS)'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All non-encrypted functions match standard code ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)+
	
	'	-----------------------------------'+char(13)+char(10)+
	'	-- Check stored procedures exist on'+char(13)+char(10)+
	'	-- database against baseline'+char(13)+char(10)+
	'	-----------------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - stored procedure ''+T.OBJECTNAME+ '' not found ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	left join sys.objects o on (o.type in(''P'')'+char(13)+char(10)+
	'			       and o.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'	where T.ITEMTYPE=''SP'''+char(13)+char(10)+
	'	and o.name is null'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All required stored procedures exist ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)+
	
	'	------------------------------'+char(13)+char(10)+
	'	-- Check stored procedures on'+char(13)+char(10)+
	'	-- this database match version'+char(13)+char(10)+
	'	-- on the baseline'+char(13)+char(10)+
	'	------------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - stored procedure ''+T.OBJECTNAME+'' version ''+isnull(dbo.fn_GetStoredProcedureVersion(R.ROUTINE_NAME),'' '')+'' mismatch with ''+T.VERSION+'' ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	join INFORMATION_SCHEMA.ROUTINES R'+char(13)+char(10)+
	'	                  on (R.ROUTINE_NAME collate database_default=T.OBJECTNAME'+char(13)+char(10)+
	'	                  and R.ROUTINE_TYPE=''PROCEDURE'')'+char(13)+char(10)+
	'	where T.ITEMTYPE=''SP'''+char(13)+char(10)+
	'	and T.VERSION<>dbo.fn_GetStoredProcedureVersion(R.ROUTINE_NAME)'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All non-encrypted stored procedures match VERSION ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)
	
	Select
	'	-----------------------------------'+char(13)+char(10)+
	'	-- Check stored procedures match the'+char(13)+char(10)+
	'	-- standard code'+char(13)+char(10)+
	'	-----------------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** ERROR - stored procedure ''+T.OBJECTNAME+ '' does not match standard code ****'''+char(13)+char(10)+
	'	from #TEMPBASELINE T'+char(13)+char(10)+
	'	left join sys.objects o on (o.type in(''P'')'+char(13)+char(10)+
	'			       and o.name collate database_default =T.OBJECTNAME)'+char(13)+char(10)+
	'	left join sys.sql_modules s on (s.object_id=o.object_id)'+char(13)+char(10)+
	'	where T.ITEMTYPE=''SP'''+char(13)+char(10)+
	'	and T.CHECKSUMVALUE<>CHECKSUM(CAST(Replace(s.definition, char(13)+char(10), char(10)) as NVARCHAR(max)) COLLATE Latin1_General_CI_AS)'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	Set @nRowCount=@@Rowcount'+char(13)+char(10)+
	'	If @nRowCount=0'+char(13)+char(10)+
	'	begin'+char(13)+char(10)+
	'		print ''*** All non-encrypted stored procedures match standard code ***'''+char(13)+char(10)+
	'	end'+char(13)+char(10)
	
	-- Now generate the code that checks for additional objects
	-- on the client's database and raise a Warning message.
	Select 	
	'	---------------------------------'+char(13)+char(10)+
	'	-- Check for extra tables on this'+char(13)+char(10)+
	'	-- database compared to baseline'+char(13)+char(10)+
	'	---------------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** WARNING - table ''+SCHEMA_NAME(s.schema_id)+''.''+s.name+'' found not a standard Inprotech table ****'''+char(13)+char(10)+
	'	from sys.objects s'+char(13)+char(10)+
	'	left join #TEMPBASELINE T on (T.ITEMTYPE=''TC'''+char(13)+char(10)+
	'			          and T.OBJECTNAME=s.name collate database_default)'+char(13)+char(10)+
	'	where s.type=''U'''+char(13)+char(10)+
	'	and s.name not like ''%iLOG%'''+char(13)+char(10)+
	'	and T.OBJECTNAME is null'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	----------------------------------'+char(13)+char(10)+
	'	-- Check for extra columns on this'+char(13)+char(10)+
	'	-- database compared to baseline'+char(13)+char(10)+
	'	----------------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** WARNING - table ''+T.OBJECTNAME+'' has extra column ''+C.COLUMN_NAME+'' ****'''+char(13)+char(10)+
	'	from INFORMATION_SCHEMA.COLUMNS C'+char(13)+char(10)+
	'	join (select distinct OBJECTNAME from #TEMPBASELINE where ITEMTYPE=''TC'') T on (T.OBJECTNAME= C.TABLE_NAME collate database_default)'+char(13)+char(10)+
	'	left join #TEMPBASELINE TC on (TC.ITEMTYPE=''TC'''+char(13)+char(10)+
	'	                           and TC.OBJECTNAME=C.TABLE_NAME collate database_default'+char(13)+char(10)+
	'	                           and TC.SUBOBJECT=C.COLUMN_NAME collate database_default)'+char(13)+char(10)+
	'	where TC.SUBOBJECT is null'+char(13)+char(10)+
	'	and C.DATA_TYPE <> ''uniqueidentifier'''+char(13)+char(10)+
	'	and C.COLUMN_NAME not in (''LOGUSERID'',''LOGIDENTITYID'',''LOGTRANSACTIONNO'',''LOGDATETIMESTAMP'',''LOGAPPLICATION'',''LOGOFFICEID'')'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'	--------------------------------------'+char(13)+char(10)+
	'	-- Check for extra constraints on this'+char(13)+char(10)+
	'	-- database compared to baseline'+char(13)+char(10)+
	'	--------------------------------------'+char(13)+char(10)+
	'	Print '''''+char(13)+char(10)+
	'	Set @nRowCount=0'+char(13)+char(10)+
	'	select ''**** WARNING - table ''+T.OBJECTNAME+'' has extra constraint ''+C.CONSTRAINT_NAME+'' ****'''+char(13)+char(10)+
	'	from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C'+char(13)+char(10)+
	'	join (select distinct OBJECTNAME from #TEMPBASELINE where ITEMTYPE=''TC'') T on (T.OBJECTNAME=C.TABLE_NAME collate database_default)'+char(13)+char(10)+
	'	left join #TEMPBASELINE TC on (TC.ITEMTYPE=''CN'''+char(13)+char(10)+
	'	                           and TC.OBJECTNAME=C.TABLE_NAME collate database_default'+char(13)+char(10)+
	'	                           and TC.SUBOBJECT=C.CONSTRAINT_NAME collate database_default)'+char(13)+char(10)+
	'	where TC.SUBOBJECT is null'+char(13)+char(10)+
	'	order by 1'+char(13)+char(10)+char(13)+char(10)+
	
	'End'+char(13)+char(10)+char(13)+char(10)+
	
	'Drop table #TEMPBASELINE'
End

Return @ErrorCode
go

grant execute on dbo.ipu_UtilGenerateDBCheckingScript  to public
go