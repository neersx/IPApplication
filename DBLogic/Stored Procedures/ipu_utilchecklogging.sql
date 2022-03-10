-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_UtilCheckLogging
-----------------------------------------------------------------------------------------------------------------------------
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON
GO

if exists (select * from sysobjects where id = object_id(N'[dbo].[ipu_UtilCheckLogging]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipu_UtilCheckLogging.'
	drop procedure dbo.ipu_UtilCheckLogging
	print '**** Creating procedure dbo.ipu_UtilCheckLogging...'
	print ''
end
go

CREATE procedure dbo.ipu_UtilCheckLogging 
			@sInpromaDB  	 	varchar(20),
			@sLoggingDB    		varchar(20)
			
as
-- PROCEDURE :	ipu_UtilCheckLogging
-- VERSION :	6
-- AUTHOR :	Chris Gollner (Spruson & Ferguson)
--
-- DESCRIPTION:	This procedure will check all logging tables that exist to their parent tables and performs 2 consistency checks
--		The first check will list logging tables that are missing columns.
--		The second check will list logging tables where the column lengths are different.
--		The procedure accepts the following parameters :
--			@sInpromaDB	- the name of the database that contains the table to be logged
--			@sLoggingDB	- the name of the database where the log table is to reside
--		As logging triggers can not  log TEXT or IMAGE columns so these columns
--		are not included in the logging check process.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date         Who  	Number	Version	Change
-- ------------ ---- 	------	-------	------------------------------------------- 
-- 03-10-2002   			Procedure created.   Chris Gollner (Spruson & Ferguson)
-- 16-05-2003   			Modified procedure to cope with nvarchars ( xtype = 231 ) which would otherwise be reported as twice the size.  Chris Gollner
-- 21-05-2003   			Updated code to cater for ntext columns that have been introduced in 2.3 Service Pack 2.  Chris Gollner
--             				Added ability to handle nchar datatype ( xtype = 239) which are reported as twice the size.
-- 10 Sep 2003		SQA9222	3	Set ANSI_NULLS ON
-- 21 Oct 2003	MF	SQA9367 4	Re instate changes to hand nchar, nvarchar and ntext
-- 22 Oct 2003	MF	SQA9367	5	Reintroduced case sensitive problem with "@sLoggingDB" and "@sInpromaDB"
-- 07 Apr 2016  MS      R52206  6       Addded quotename for @sInpromaDB and @sLoggingDB to avoid sql injection


SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_PADDING OFF
set NOCOUNT ON

declare @sSQL nvarchar(4000)

select @sSQL = '

print ''Logging tables that contain insufficent columns''
select so.name ''Tablename'',  COUNT(*) ''No. of cols'',(
				select count(*)-3
				from ' + QUOTENAME(@sLoggingDB, '') + '..sysobjects SO1
				join ' + QUOTENAME(@sLoggingDB, '') + '..syscolumns sc1 on so1.id=sc1.id
				join ' + QUOTENAME(@sLoggingDB, '') + '..systypes st on st.xtype=sc1.xtype and st.name not in (''ntext'',''text'',''image'',''sysname'') 
				
				where so1.type=''u''
				and stuff(so1.name, patindex(''%_ilog'',so1.name),5,'''')=so.name
			) ''No. of logging cols'',

			(
				select rowcnt
				from ' + QUOTENAME(@sLoggingDB, '') + '..sysobjects SO1
				join ' + QUOTENAME(@sLoggingDB, '') + '..sysindexes si1 on so1.id=si1.id and (si1.indid=1 or so1.name=si1.name)
				
				where so1.type=''u''
				and stuff(so1.name, patindex(''%_ilog'',so1.name),5,'''')=so.name
			) ''No. of logged rows''





from ' + QUOTENAME(@sInpromaDB, '') + '..sysobjects so
join '+ QUOTENAME(@sInpromaDB, '') +'..syscolumns sc on so.id=sc.id
join '+ QUOTENAME(@sInpromaDB, '') +'..systypes st on st.xtype=sc.xtype and st.name not in (''ntext'',''text'',''image'',''sysname'') 
where so.type=''u''
and exists
(select * from ' + QUOTENAME(@sLoggingDB, '') + '..sysobjects so1
 where stuff(so1.name, patindex(''%_ilog'',so1.name),5,'''')=so.name)
group by so.name
having COUNT(*)<>(
			select count(*)-3
			from ' + QUOTENAME(@sLoggingDB, '') + '..sysobjects SO1
			join ' + QUOTENAME(@sLoggingDB, '') + '..syscolumns sc1 on so1.id=sc1.id
			join ' + QUOTENAME(@sLoggingDB, '') + '..systypes st on st.xtype=sc1.xtype and st.name not in (''ntext'',''text'',''image'',''sysname'')
			
			where so1.type=''u''
			and stuff(so1.name, patindex(''%_ilog'',so1.name),5,'''')=so.name
			)

'
exec sp_executesql @sSQL

select @sSQL = '


print ''Logging tables that contain columns whose data lengths are not the same''
select so.name ''Tablename'',sc.name''Column name'', sc.length''Col len'', (
				select case when st.xtype in (231,239) then sc1.length/2 else sc1.length end
				from ' + QUOTENAME(@sLoggingDB, '') + '..sysobjects SO1
				join ' + QUOTENAME(@sLoggingDB, '') + '..syscolumns sc1 on so1.id=sc1.id
				join ' + QUOTENAME(@sLoggingDB, '') + '..systypes st on st.xtype=sc1.xtype and st.name not in (''ntext'',''text'',''image'',''sysname'')
				
				where so1.type=''u''
				and stuff(so1.name, patindex(''%_ilog'',so1.name),5,'''')=so.name
				and sc1.name=sc.name
			)''Logging Col len'',
			(
				select rowcnt
				from ' + QUOTENAME(@sLoggingDB, '') + '..sysobjects SO1
				join ' + QUOTENAME(@sLoggingDB, '') + '..sysindexes si1 on so1.id=si1.id and (si1.indid=1 or so1.name=si1.name)
				
				where so1.type=''u''
				and stuff(so1.name, patindex(''%_ilog'',so1.name),5,'''')=so.name
			) ''No. of logged rows''


from ' + QUOTENAME(@sInpromaDB, '') + '..sysobjects so
join '+ QUOTENAME(@sInpromaDB, '') +'..syscolumns sc on so.id=sc.id
join '+ QUOTENAME(@sInpromaDB, '') +'..systypes st on st.xtype=sc.xtype and st.name not in (''ntext'',''text'',''image'',''sysname'') 
where so.type=''u''
and exists
(select * from ' + QUOTENAME(@sLoggingDB, '') + '..sysobjects so1
 where stuff(so1.name, patindex(''%_ilog'',so1.name),5,'''')=so.name)
and  sc.length <>(
		select  case when st.xtype in (231,239) then sc1.length/2 else sc1.length end
		from ' + QUOTENAME(@sLoggingDB, '') + '..sysobjects SO1
		join ' + QUOTENAME(@sLoggingDB, '') + '..syscolumns sc1 on so1.id=sc1.id
		join ' + QUOTENAME(@sLoggingDB, '') + '..systypes st on st.xtype=sc1.xtype and st.name not in (''ntext'',''text'',''image'',''sysname'')
		
		where so1.type=''u''
		and stuff(so1.name, patindex(''%_ilog'',so1.name),5,'''')=so.name
		and sc1.name=sc.name
		)

order by 1
'

exec sp_executesql @sSQL

go

grant execute on dbo.ipu_UtilCheckLogging  to public
go
