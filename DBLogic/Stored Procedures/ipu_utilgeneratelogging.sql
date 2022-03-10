-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_UtilGenerateLogging
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipu_UtilGenerateLogging]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipu_UtilGenerateLogging.'
	drop procedure dbo.ipu_UtilGenerateLogging
end
print '**** Creating procedure dbo.ipu_UtilGenerateLogging...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipu_UtilGenerateLogging
			@sTableName		varchar(40),
			@sInproDB  	 	varchar(40),
			@sLoggingDB    		varchar(40),
			@bPrintLog		bit	= 1
			
as
-- PROCEDURE :	ipu_UtilGenerateLogging
-- VERSION:	19
-- AUTHOR :	Chris Gollner (Spruson & Ferguson) (starting from a procedure by Chris Story and Michael Fleming)
-- DESCRIPTION:	This procedure will generate a log table and Insert, Delete and Update triggers for a specific
--		table.
--		If the log table already exists it will create a backup table first and then copy the contents
--		of the backup table into the newly created log table.
--		The backup table is NOT automatically deleted.
--		The procedure accepts the following parameters :
--			@sTableName	- the name of the table to be logged
--			@sInproDB	- the name of the database that contains the table to be logged
--			@sLoggingDB	- the name of the database where the log table is to reside
--		Note that the triggers used in the logging process cannot log TEXT or IMAGE columns so these columns
--		are not included in the log table generated.
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2005 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 Mar 2002    			Modified the table transfer due to limitation of sql_executesql and the use statement
--              			The declare cursor statement is now generated dynamically.    Chris Gollner.	
-- 19 Mar 2002    			Modified the transfer to cater for the fact that a backup table may or may not exist.
--              			Now only executes transfer code if backup table exists.  Also, the column list for the insert..select
--              			is based on the columns in the backup table and the new log table probably has more.   Chris Gollner
-- 02 Oct2002   			Corrected a problem with the data transfer from old table to new, as the object_id does not function properly
--              			when referring to a different database.   Chris Gollner
-- 16-05-2003   			Under certain CONDITIONs data from old logging tables was not being transferred 
--					to the new table when the procedure is being used to update the logging for a 
--					particular table.  Chris Gollner
-- 21-05-2003   			Updated code to cater for ntext columns that have been introduce in 2.3 
--					Service Pack 2.  Chris Gollner
-- 10 Sep 2003	MF	9222	6	SET ANSI_NULLS ON
-- 15 Sep 2003	MF	9243	7	Version problem
-- 06 Aug 2004	AB	8035	8	Add collate database_default to temp table definitions
-- 24 Feb 2005	MF	11070	9	Do not use NOT NULL against the columns generated in the log table other than on the first 3 columns (LOGDATETIMESTAMP, LOGUSERID, LOGACTION).
-- 15 Apr 2005	AB	11271	10	Collation conflict caused by stored procedures
-- 13 Jul 2005	MF	11662	11	Logging extended to include the IndentityId of the user to cater for Workbenches
--					and also to record the name of the application that instigated the change.
-- 21 Jul 2005	MF	11662	12	Remember to copy the additional log columns from backup.
-- 16 Sep 2005	MF	11884	13	Add indexes to match the primary key of the table and also the LogDatetimeStamp
-- 20 Sep 2005	MF	11884	14	Revisit. Set the database before adding the index.
-- 13 Jan 2006	MF	12199	15	Indexes generated against the log tables need to differentiate the name
--					of the index from the underlying table being logged.
-- 11 Jan 2005	vql	12151	16	Make LOGAPPLICATION column nvarchar(128). The return of APP_NAME( ).
--  2 Oct 2006	MF	13528	17	If the database being used to hold the log tables is the same as the database
--					being logged, then don't include the name of that database in the generated 
--					triggers.  This will mean that restoring the database with a different name
--					will not cause problems.
-- 27 Nov 2006	vql	13279	18	Added TRANSACTIONNO column to iLOG tables. Triggers changed to find TRANSACTIONNO from the 
--					the context_info system column and then insert this into the new TRANSACTIONNO columns.
-- 16 Feb 2006	SW	12628	19	Change grant all table access to grant REFERENCES, SELECT

SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_PADDING OFF
set NOCOUNT ON

create table #TEMPLOGOK (CONDITION	varchar(2) collate database_default null)

declare @sSQLString 	nvarchar(4000)
declare @sColumnList	nvarchar(4000)
declare @sOldColumnList	nvarchar(4000)
Declare @ErrorCode	int

-- Initialise 
Set @ErrorCode=0


-- Drop VIEW if a different database is being used for the logs

If @ErrorCode=0
Begin
	Set @sSQLString="
	if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME='" +@sTableName + "_iLOG' and TABLE_TYPE='VIEW')
	begin
		Drop VIEW dbo." + @sTableName + "_iLOG
	end"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Backup logging table, if it exists
-------------------------------------

If @ErrorCode=0
Begin
	set @sSQLString= 
	"use "+@sLoggingDB+"
	if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME='"+@sTableName+"_iLOG')
	begin
		-- Store the list of Columns that exist in the current log and also
		-- in the live table
		Select @sOldColumnList=isnull(nullif(@sOldColumnList+',',','),'')+C1.COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS C1
		left join "+@sInproDB+".INFORMATION_SCHEMA.COLUMNS C2 	
					on (C2.TABLE_NAME='"+@sTableName+"'
					and C2.COLUMN_NAME=C1.COLUMN_NAME
					and C2.DATA_TYPE not in ('ntext','text','image','sysname'))
		where C1.TABLE_NAME='"+@sTableName+"_iLOG'
		and C1.DATA_TYPE not in ('ntext','text','image','sysname')
		and (C1.COLUMN_NAME like 'LOG%' OR C2.COLUMN_NAME is not null)
		order by C1.ORDINAL_POSITION

		-- Now rename the current log table
		exec @ErrorCode=sp_rename ["+ @sTableName +"_iLOG], ["+ @sTableName +"_iLOGBAK]
	End
	use "+@sInproDB+"
	"
	--print @sSQLString
	exec sp_executesql @sSQLString,
				N'@sOldColumnList	nvarchar(4000)	OUTPUT,
				  @ErrorCode		int		OUTPUT',
				  @sOldColumnList=@sOldColumnList	OUTPUT,
				  @ErrorCode=@ErrorCode			OUTPUT

	If @ErrorCode=0
	and @bPrintLog=1
		print 'Log table backup done       for ' +@sTableName+'_iLOG'
End


-- create logging table
-----------------------
If @ErrorCode=0
Begin
	set @sSQLString=
	"Create table "+@sLoggingDB+".dbo." + @sTableName + "_iLOG (
		LOGUSERID		nvarchar(50)	collate database_default NOT NULL,
		LOGIDENTITYID		int 		NULL,
		LOGTRANSACTIONNO	int		NULL, 
		LOGDATETIMESTAMP 	datetime 	NOT NULL,
		LOGACTION 		nchar(1) 	collate database_default NOT NULL,
		LOGAPPLICATION		nvarchar(128)	collate database_default NULL"
	
	-- Construct the columns to be logged by concatenating the details of each 
	-- column onto the @sSQLString
	Select @sSQLString=isnull(nullif(@sSQLString+','+char(10),','+char(10)),'')+char(9)+char(9)+COLUMN_NAME+char(9)+
				DATA_TYPE+
				CASE WHEN(CHARACTER_MAXIMUM_LENGTH is not null) 
					THEN '('+cast(CHARACTER_MAXIMUM_LENGTH as nvarchar)+') collate database_default'
				     WHEN(DATA_TYPE='decimal')
					THEN '('+cast(NUMERIC_PRECISION as nvarchar)+','+cast(NUMERIC_SCALE as nvarchar)+')'
				END+
				' NULL'
	from INFORMATION_SCHEMA.COLUMNS 
	where TABLE_NAME=@sTableName
	and DATA_TYPE not in ('ntext','text','image','sysname')
	order by ORDINAL_POSITION
	
	Set @sSQLString=@sSQLString + ')'
	
	exec @ErrorCode=sp_executesql @sSQLString
	
	If @ErrorCode=0
	and @bPrintLog=1
		print 'Log table created           for ' +@sTableName+'_iLOG'
End

-- grant permission
-------------------
If @ErrorCode=0
Begin
	set @sSQLString = 
	"Use "+@sLoggingDB+"
	grant REFERENCES, SELECT on " + @sTableName + "_iLOG to public 
	use "+@sInproDB

	exec @ErrorCode=sp_executesql @sSQLString

	If @ErrorCode=0
	and @bPrintLog=1
		print 'Permissions granted         for '+@sTableName+'_iLOG'
End

-- If the logs are being held on a separate database then
-- generate a VIEW on the main database to point to the log table
-- This is required for the Audit enquiry to work

If  @sInproDB<>@sLoggingDB
and @ErrorCode=0
Begin
	Set @sSQLString="
	Create VIEW dbo." + @sTableName + "_iLOG
	as
	Select * from "+@sLoggingDB+".dbo." + @sTableName + "_iLOG"

	exec @ErrorCode=sp_executesql @sSQLString

	If @ErrorCode=0
	Begin
		If @bPrintLog=1
			print 'Local view granted          for '+@sTableName+'_iLOG'

		set @sSQLString = "
		grant select on "+@sInproDB+".dbo." + @sTableName + "_iLOG to public"
	
		exec @ErrorCode=sp_executesql @sSQLString
	
		If @ErrorCode=0
		and @bPrintLog=1
			print 'Permissions granted on view for '+@sTableName+'_iLOG'
	End

End

-- drop the Insert trigger
------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	if exists (select * from sysobjects where name = 'TI_iLOGGING_" +@sTableName + "' and type = 'TR')
		drop trigger dbo.TI_iLOGGING_" + @sTableName

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Now generate the new Insert trigger
If @ErrorCode=0
Begin
	set @sSQLString="
	create trigger dbo.TI_iLOGGING_" + @sTableName + " on " + @sTableName + "
	for insert as 
	begin
	 declare @nIdentityId		int
	 declare @nSessionTransNo	int

	 select @nIdentityId=cast(substring(context_info,1,4) as int)
	 from master.dbo.sysprocesses
	 where spid=@@SPID
	 and substring(context_info,1,4)<>0x0000000
	 
	 select @nSessionTransNo=cast(substring(context_info,5,4) as int)
	 from master.dbo.sysprocesses
	 where spid=@@SPID
	 and substring(context_info,5,4)<>0x0000000

	 insert into "+CASE WHEN(@sLoggingDB<>@sInproDB) THEN @sLoggingDB+".." END + @sTableName + "_iLOG
	 select system_user,@nIdentityId,@nSessionTransNo,getdate(),'I',APP_NAME(),"
	
	Select @sColumnList=isnull(nullif(@sColumnList+',',','),'')+COLUMN_NAME
	from INFORMATION_SCHEMA.COLUMNS 
	where TABLE_NAME=@sTableName
	and DATA_TYPE not in ('ntext','text','image','sysname')
	order by ORDINAL_POSITION

	Set @sSQLString=@sSQLString+char(10)+@sColumnList+char(10)+"from inserted"+char(10)+"end"

	exec @ErrorCode=sp_executesql @sSQLString	

	--print @sSQLString
	If  @ErrorCode=0
	and @bPrintLog=1
		print 'Insert trigger created      for TI_iLOGGING_' +@sTableName
End

-- drop the Update trigger
------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	if exists (select * from sysobjects where name = 'TU_iLOGGING_" +@sTableName + "' and type = 'TR')
		drop trigger dbo.TU_iLOGGING_" + @sTableName

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Now generate the new Update trigger
If @ErrorCode=0
Begin
	set @sSQLString="
	create trigger dbo.TU_iLOGGING_" + @sTableName + " on " + @sTableName + "
	for update as 
	begin
	 declare @nIdentityId		int
	 declare @nSessionTransNo	int

	 select @nIdentityId=cast(substring(context_info,1,4) as int)
	 from master.dbo.sysprocesses
	 where spid=@@SPID
	 and substring(context_info,1,4)<>0x0000000
	 
	 select @nSessionTransNo=cast(substring(context_info,5,4) as int)
	 from master.dbo.sysprocesses
	 where spid=@@SPID
	 and substring(context_info,5,4)<>0x0000000

	 insert into "+CASE WHEN(@sLoggingDB<>@sInproDB) THEN @sLoggingDB+".." END + @sTableName + "_iLOG
	 select system_user,@nIdentityId,@nSessionTransNo,getdate(),'U',APP_NAME(),"

	Set @sSQLString=@sSQLString+char(10)+@sColumnList+char(10)+"from deleted"+char(10)+"end"
	
	exec @ErrorCode=sp_executesql @sSQLString

	--print @sSQLString
	If  @ErrorCode=0
	and @bPrintLog=1
		print 'Update trigger created      for TU_iLOGGING_' +@sTableName
End

-- drop the Delete trigger
------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	if exists (select * from sysobjects where name = 'TD_iLOGGING_" +@sTableName + "' and type = 'TR')
		drop trigger dbo.TD_iLOGGING_" + @sTableName

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Now generate the new Delete trigger
If @ErrorCode=0
Begin
	set @sSQLString="
	create trigger dbo.TD_iLOGGING_" + @sTableName + " on " + @sTableName + "
	for delete as 
	begin
	 declare @nIdentityId		int
	 declare @nSessionTransNo	int

	 select @nIdentityId=cast(substring(context_info,1,4) as int)
	 from master.dbo.sysprocesses
	 where spid=@@SPID
	 and substring(context_info,1,4)<>0x0000000
	 
	 select @nSessionTransNo=cast(substring(context_info,5,4) as int)
	 from master.dbo.sysprocesses
	 where spid=@@SPID
	 and substring(context_info,5,4)<>0x0000000

	 insert into "+CASE WHEN(@sLoggingDB<>@sInproDB) THEN @sLoggingDB+".." END + @sTableName + "_iLOG
	 select system_user,@nIdentityId,@nSessionTransNo,getdate(),'D',APP_NAME(),"

	Set @sSQLString=@sSQLString+char(10)+@sColumnList+char(10)+"from deleted"+char(10)+"end"

	exec @ErrorCode=sp_executesql @sSQLString
	
	--print @sSQLString

	If  @ErrorCode=0
	and @bPrintLog=1
	Begin
		print 'Delete trigger created      for TD_iLOGGING_' +@sTableName
		print 'Logging generation complete for ' +@sTableName
	End
End

-- transfer contents of old log table to new log table
------------------------------------------

if @sOldColumnList is not null
and @ErrorCode=0
begin
	set @sSQLString="insert into "+ @sLoggingDB + ".." + @sTableName +"_iLOG("+@sOldColumnList+")"+char(10)+
			"select "+@sOldColumnList+char(10)+
			"from "+ @sLoggingDB + ".." + @sTableName +"_iLOGBAK"

	exec @ErrorCode=sp_executesql @sSQLString

	-- If copy successful then drop the backup of the log
	If @ErrorCode=0
	Begin
		Set @sSQLString="drop table "+ @sLoggingDB + ".." + @sTableName +"_iLOGBAK"

		exec @ErrorCode=sp_executesql @sSQLString
	End
End

-- generate an index to mirror the primary key of the base table

If @ErrorCode=0
begin
	Set @sSQLString=null

	select  @sSQLString=isnull(nullif(@sSQLString+','+char(10),','+char(10)),'')+char(9)+char(9)+COLUMN_NAME+char(9)+'ASC'
	from INFORMATION_SCHEMA.TABLE_CONSTRAINTS C 
		-- Find constraints that point to the parent Primary Key
		-- Now get the name of the foreign key column
	join INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU on (CU.CONSTRAINT_NAME=C.CONSTRAINT_NAME)
	where C.TABLE_NAME=@sTableName
	and C.CONSTRAINT_TYPE='PRIMARY KEY'

	If @sSQLString is not null
	Begin
		set @sSQLString=
		'Use '+@sLoggingDB+char(10)+
		'CREATE INDEX XIE1'+@sTableName+'_iLOG ON '+@sTableName+'_iLOG ('+char(10)+@sSQLString+')'

		exec @ErrorCode=sp_executesql @sSQLString
	
		--print @sSQLString
	
		If  @ErrorCode=0
		and @bPrintLog=1
		Begin
			print 'Index to mirror Primary Key created for XIE1' +@sTableName+'_iLOG'
		End
	End
End

-- generate an index against the Logging details

If @ErrorCode=0
begin
	set @sSQLString='Use '+@sLoggingDB+char(10)+
			'CREATE INDEX XIE2'+@sTableName+'_iLOG ON '+@sTableName+'_iLOG ('+char(10)+
			'LOGDATETIMESTAMP ASC, LOGIDENTITYID ASC, LOGUSERID ASC)'+char(10)+
			'Use '+@sInproDB

	exec @ErrorCode=sp_executesql @sSQLString

	--print @sSQLString

	If  @ErrorCode=0
	and @bPrintLog=1
	Begin
		print 'Index created for XIE2' +@sTableName+'_iLOG'
	End
End

If  @ErrorCode=0
and @bPrintLog=1
Begin
	print 'Logging generation complete for ' +@sTableName
End

Return @ErrorCode
GO

grant execute on dbo.ipu_UtilGenerateLogging to public
go
