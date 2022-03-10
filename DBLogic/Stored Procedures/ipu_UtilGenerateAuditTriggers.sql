-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_UtilGenerateAuditTriggers
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipu_UtilGenerateAuditTriggers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipu_UtilGenerateAuditTriggers.'
	drop procedure dbo.ipu_UtilGenerateAuditTriggers
	print '**** Creating procedure dbo.ipu_UtilGenerateAuditTriggers'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE [dbo].[ipu_UtilGenerateAuditTriggers]
			@psTable	varchar(128),	-- Mandatory
			@pbPrintLog	bit	= 1,
			@pbPrintSQL	bit	= 0

AS

-- PROCEDURE :	ipu_UtilGenerateAuditTriggers
-- VERSION :	42 -- NOTE : Modify the variable @sVersion
-- DESCRIPTION:	Generates the triggers required for data translation and audit management for a specific table.
--		This stored procedure combines functionality that previously existed in the following procedures:
--		- util_GenerateTranslationTriggers
--		- ipu_UtilGenerateLogging
--		The triggers are dynamically generated so that the one trigger looks after a number of tasks:
--		-- Generation of TID value for translation 
--		-- initialising audit column values and updating base triggering table
--		-- where required inserting audit rows into log tables.

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
--  3 Dec 2007	MF	15192	1	Procedure created
-- 14 Jan 2008	MF	15655	2	Add LOGDATETIMESTAMP to the main index of the log table
-- 25 Jan 2008	MF	15865	3	Allow LOGDATETIMESTAMP to be varied by an offset time in
--					order to standardise times across multiple replication sites
--					in different timezones.
--					Alternatively allow firms using SQLServer 2005 (or higher)
--					to use getutcdate() instead of getdate(). This will use the
--					Greenwich Mean Time as the logged datetime stamp.
-- 22 Feb 2008	DL	5241	4	Ensure trailing space trimming (SET ANSI_PADDING OFF) will not 
--					cause issue with string concatenation.
-- 10 Apr 2008	MF	16230	5	Generated code being truncated on large table (EVENTCONTROL) with 
--					translation of Text column turned on. Also ensure INSTEAD OF trigger
--					updates all columns event if the translation columns have not changed.
-- 09 May 2008	MF	16386	6	Don't just check Translation colums for TEXT or NTEXT to determine if
--					Instead Of trigger is to be used.  Check all columns for the table.
-- 14 May 2008	MF	16410	7	Specific code for the ALERT table to clear out ALERTDATE if the 
--					DUEDATE is changed.  This will then allow Policing to calculate the
--					correct ALERTDATE and to send any Reminders that should have already
--					been sent.
-- 29 May 2008	MF	16386	8	Revisit to also allow NAMETEXT to be generated as BEFORE trigger.
-- 30 Jun 2008	MF	16616	9	Not handling Tables where the LOG... columns are not the last columns
--					in the database.
-- 05 Sep 2008	MF	16892	10	Generation of audit triggers needs to ignore ROWGUID columns put in place
--					replication.
-- 11 Dec 2008	MF	17136	11	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Nov 2009	MF	18253	12	SQL Error when more than one table uses the same Primary Key constraint name.
--					When getting columns in primary key ensure the table name in the CONSTRAINT_COLUMN_USAGE
--					matches against TABLE_CONSTRAINTS.TABLE_NAME
-- 27 Aug 2010	MF	RFC9316	13	When a an audit log table is created, generate rows into TABLECODE for TableType -502 for each
--					column of the table. These are then able to be used in the sanity data validation checking.
-- 01 Nov 2010	MF	18494	14	Revisit of 16410. The DueDate on the ALERT may now be modified by the occurrence of an Event that
--					is linked to the Alert as a Trigger Event.  When this occurs Policing will update the DUEDATE and
--					recalculate the ALERTDATE so it that situation the ALERTDATE does not need to be set to null.
-- 17 Jun 2011	MF	19700	15	If CASEID, NAMENO or EMPLOYEENO exists in the table to be logged and is not the first column
--					of the primary key index, then generate another index for each of these.  This will have a 
--					positive impact on performance when viewing log details.
-- 12 Jul 2011	DL	SQA19795 16	Specify collate database default for temp table.
-- 29 Aug 2011	MF	19917	17	If the position of a column changes or if the data type changes then this should trigger the
--					regeneration of the audit log.
-- 29 Aug 2011	MF	19918	18	Revist of 19700 to force the index creation if they do not already exist.
-- 08 Sep 2011	DL	19178	19	Handle data type XML and nvarchar(max)
-- 14 Sep 2011	MF	R11295	20	Allow DOMAINNAME\Username to be optionally captured in log
--					Allow the audit log table to include an identity column (user request).
-- 20 Sep 2011	MF	R11295	21	Revisit after test failed.
-- 30 Sep 2011	MF	20015	22	Revisit of R11295. Problem when logging existed in a different database and logging had been turned off and then reinstated.
-- 04 Oct 2011	MF	R11295	23	Revisit of R11295. @bUsernameOnly was not being applied in one situations.
-- 11 Nov 2011	MF	20138	24	Views pointing to Logging tables held on a different database are sometimes being dropped and not recreated.
-- 11 May 2012	MF	R12290	25	Additional index required on log tables to improve performance on certain reports requiring CASEID reporting.
-- 26 Jul 2012	MF	R12556	26	Reference to database names should be wrapped in [ ] cater for special characters used in the DB_Name.
-- 04 Jan 2013	MF	R13083	27	Strip the time from dates being inserted into CASEEVENT.
-- 19 Feb 2013	MF	R13239	28	Rework of R13083 to ensure columns that have a substring of EVENTDATE included in their name are not impacted.
-- 25 Feb 2013	MF	R13239	29	Extended to cater for tables where EVENTDATE may appear as the first or last column. (Thanks to Adri Koopman, Novagraaf)
-- 17 Jun 2013	MF	R13578	30	Changed the reference to the TID column (C.Name --> C.TIDcolumn) on several locations,
--					due to a NULL TID during INSERT (Thanks to Adri Koopman, Novagraaf)
-- 14 Jan 2014	MF	R30061	31	Translatable column being updated is not having its TID column set if the TID column was null to start with.
--					(Correction provided by Adri Koopman, Novagraaf)
-- 01 Apr 2014	MF	R33042	32	Revisit of RFC13083. The time was not being fully removed when using CAST.  Change to Conver(nvarchar(),EVENTDATE,106).
-- 13 Mar 2015	MF	R45370	33	Correction to error when primary key being generated on audit log table.
-- 14 Apr 2015	MF	R46624	34	Inserts should write the log row for the insert record before any subsequent update row is inserted. This only makes a 
--					difference when the Site Contro "iLOG table has Identity" is set to true as the generated sequence number was out of order.
-- 29 Jul 2016	MF	64248	35	The generated audit triggers are to look after the updating of CASEEVENT for EventNo=-14. This tracks when a component of Cases
--					has changed. This will be done for the following tables that make up a the core content of a Case:
--					CASES,CASEBUDGET,CASECHECKLIST,CASEIMAGE,CASELOCATION,CASEEVENT,CASENAME,CASETEXT,PROPERTY,RELATEDCASE,OFFICIALNUMBERS,NAMEINSTRUCTIONS,ALERT,
--					CRMCASESTATUSHISTORY,OPPORTUNITY,JOURNAL,CLASSFIRSTUSE,DESIGNELEMENT,TABLEATTRIBUTES
-- 23 Aug 2016	MF	66043	36	The generated INSERT trigger should not have the test : "If NOT UPDATE(LOGDATETIMESTAMP)" as this will block the trigger if the LOGDATEIMESTAMP
--					column is referenced.
-- 19 Jan 2017	MF	70371	37	When determining if the table has changed, we need to also consider the definition of the columns and not just whether new columns have been added.
-- 17 Aug 2018	MF	74751	38	Revisit of 64248 to include the CASEEVENTTEXT table so that changes to that table will trigger the update of the EventNo=-14.
-- 18 Oct 2018	MF	DR-45012 39	Some columns use the same TID column for the translation, ensure the UPDATE references that TID only once.
-- 14 Nov 2018  AV  75198/DR-45358	40   Date conversion errors when creating cases and opening names in Chinese DB
-- 27 Mar 2019	DV	DR-42320 41 Add extraction of componentid from contextinfo and use componentname in LOGAPPLICATION
-- 09 Sep 2019	BS	DR-52401 42 Fix made for SDR-28526 regarding collation issue

Set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF

Declare	@tbColumns 	table (	Name		nvarchar(50)	collate database_default,
				TIDColumn	nvarchar(50)	collate database_default,
				RelatedColumn	nvarchar(50)	collate database_default,
				Display		nvarchar(50)	collate database_default,
				DataType	nvarchar(60)	collate database_default,
				Type		nvarchar(20)	collate database_default,
				Length		smallint,
				KeyNo		int,
				IsIdentity	bit,
				IsRowGuid	bit,		-- check if column is rowguid identifier
				Position	tinyint	identity)

declare @tblTableCodes table(	TABLECODE		int		identity(1,1),
				DESCRIPTION		nvarchar(80)	collate database_default not null,
				USERCODE		nchar(1)	collate database_default not null )

declare @nRowCount		int
declare @nNextTableCode		int

Declare @nColCount		tinyint	
Declare @nLastKeyPos		tinyint
Declare	@bTableHasText		bit
Declare @bLogRequired		bit
Declare @bTableHasChanged	bit
Declare @bUseGetUtcDate		bit
Declare	@bNeedCaseIdIndex	bit
Declare	@bNeedNameNoIndex	bit
Declare	@bNeedEmployeeNoIndex	bit

Declare	@bUseLogSequence	bit
Declare	@bUsernameOnly		bit
Declare @bIndexExists		bit

Declare	@sSQLString		nvarchar(max)

Declare @sMessage		varchar(250)
Declare @sSQLStringMax		nvarchar(max)
Declare @sOldColumnList		nvarchar(max)
Declare @sColumnList		nvarchar(max)
Declare	@sColumnListEventDate	nvarchar(max)		-- Added for modified EVENTDATE handling
Declare @sLogColumnList		nvarchar(max)
Declare @sLogColumnListEventDate nvarchar(max)
Declare @sFullColumnList	nvarchar(max)
Declare	@sTIDColumnList		nvarchar(max)
Declare @sKeyColumns		nvarchar(max)
Declare @sKeyJoins		nvarchar(max)
Declare @sSqlMsg		nvarchar(max)
Declare @sIdentityColumn	nvarchar(30)
Declare @sVersion		nvarchar(3)

Declare @sInproDB		nvarchar(128)
Declare @sLoggingDB		nvarchar(128)

Declare	@ErrorCode		int

Set @ErrorCode=0

-----------------------------------------------------
-- Update this to be the same as the VERSION number 
-- of this stored procedure so it can be used in the 
-- generation of the trigger.
-----------------------------------------------------
Set @sVersion='42'

-- Check that all of the columns required
-- for the audit exist on the table
 
If 6<>(SELECT count(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @psTable AND COLUMN_NAME in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID'))
BEGIN
	Set @sMessage = 'One or more audit columns (LOGUSERID, LOGIDENTITY, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGAPPLICATION, LOGOFFICEID) missing from table '+@psTable+'. Trigger generation terminated.'
	RAISERROR(@sMessage, 16, 1)
	Set @ErrorCode = @@Error
END

if @ErrorCode = 0
begin
	-- Check if the iLOG table will get
	-- an Identity column (Added by A3, version 18a)
	set @sSQLString="
	select	@bUseLogSequence = SC.COLBOOLEAN
	from	dbo.SITECONTROL SC
	where	SC.CONTROLID = 'iLOG table has Identity'

	select	@bUseLogSequence = ISNULL(@bUseLogSequence,0)"
	
	exec @ErrorCode = sp_executesql @sSQLString,
				N'@bUseLogSequence	bit	OUTPUT',
				  @bUseLogSequence		OUTPUT
End

If @ErrorCode = 0
begin
	-- Check if username or domainname\username
	-- will be stored in LOGUSERID (Added by A3, version 18a)
	set @sSQLString="
	select	@bUsernameOnly = SC.COLBOOLEAN
	from	dbo.SITECONTROL SC
	where	SC.CONTROLID = 'Log Username only'

	select	@bUsernameOnly = ISNULL(@bUsernameOnly,0)"
	
	exec @ErrorCode = sp_executesql @sSQLString,
				N'@bUsernameOnly	bit	OUTPUT',
				  @bUsernameOnly		OUTPUT
end

If @ErrorCode=0
Begin
	-- Get the database name for both
	-- the data and the logging tables.

	Set @sSQLString="
	Select @sInproDB='['+DB_NAME()+']'

	Select @sLoggingDB=S.COLCHARACTER,
	       @bUseGetUtcDate=S1.COLBOOLEAN
	from SITECONTROL S
	left join SITECONTROL S1 on (S1.CONTROLID='Log Time as GMT')
	where S.CONTROLID='Logging Database'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sInproDB		nvarchar(128)	OUTPUT,
				  @sLoggingDB		nvarchar(128)	OUTPUT,
				  @bUseGetUtcDate	bit		OUTPUT',
				  @sInproDB=@sInproDB			OUTPUT,
				  @sLoggingDB=@sLoggingDB		OUTPUT,
				  @bUseGetUtcDate=@bUseGetUtcDate	OUTPUT

	If isnull(ltrim(rtrim(@sLoggingDB)),'')=''
	and @sInproDB is not Null
		Set @sLoggingDB=@sInproDB
	Else
	If  substring(ltrim(@sLoggingDB),1,1)<>'['
		Set @sLoggingDB='['+@sLoggingDB+']'
End

------------------------------------
-- Drop VIEW if a different database 
-- is being used for the logs
------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME='" +@psTable + "_iLOG' and TABLE_TYPE='VIEW')
	begin
		Drop VIEW dbo." + @psTable + "_iLOG
	end"

	exec @ErrorCode=sp_executesql @sSQLString
End
-------------------------------------
-- Backup logging table, if it exists
-------------------------------------
If @ErrorCode=0
Begin
	set @sSQLString= 
	"use "+@sLoggingDB+";
	if not exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME='"+@psTable+"_iLOG')
	Begin
		Set @bTableHasChanged=1
		
		if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME='"+@psTable+"_iLOGBAK')
		Begin
			-- Getting the columns in any backup of the log table that match
			-- the columns in the live table
			Select @sOldColumnList=isnull(nullif(@sOldColumnList collate database_default +',',','),'')+C1.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS C1
			left join "+@sInproDB+".INFORMATION_SCHEMA.COLUMNS C2 	
						on (C2.TABLE_NAME='"+@psTable+"'
						and C2.COLUMN_NAME collate database_default =C1.COLUMN_NAME
						and C2.DATA_TYPE not in ('ntext','text','image','sysname'))
			where C1.TABLE_NAME='"+@psTable+"_iLOGBAK'
			and C1.DATA_TYPE not in ('ntext','text','image','sysname')
			and (C1.COLUMN_NAME like 'LOG%' OR C2.COLUMN_NAME is not null)" + 
			case when @bUseLogSequence = 0 then "
			and (C1.COLUMN_NAME <> 'LOGSEQUENCE')" else "" end +"
			order by C1.ORDINAL_POSITION
		End
	End
	Else begin
		Declare @sColumnListInLog	nvarchar(max)
		Declare @sColumnListInTable	nvarchar(max)

		-- Get a list of all the columns that are currently being logged excluding
		-- the audit columns

		Select @sColumnListInLog=isnull(nullif(@sColumnListInLog collate database_default +','+char(10),','+char(10)),'')+char(9)+char(9)+COLUMN_NAME+char(9)+
					DATA_TYPE+
					CASE WHEN(ISNULL(CHARACTER_MAXIMUM_LENGTH,0) > 0)
						THEN '('+cast(CHARACTER_MAXIMUM_LENGTH as nvarchar)+')'+CASE WHEN(DATA_TYPE not like '%binary') THEN ' collate database_default' END
					     WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN
						CASE WHEN DATA_TYPE = 'xml' then ''
						     else '(max)' + CASE WHEN(DATA_TYPE not like '%binary') THEN ' collate database_default' else '' END
						END
					     WHEN(DATA_TYPE='decimal')
						THEN '('+cast(NUMERIC_PRECISION as nvarchar)+','+cast(NUMERIC_SCALE as nvarchar)+')'
					END+
					' NULL'
		from INFORMATION_SCHEMA.COLUMNS 
		where TABLE_NAME='"+@psTable+"_iLOG'
		and DATA_TYPE not in ('ntext','text','image','sysname')
		and COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION','LOGSEQUENCE')
		order by ORDINAL_POSITION


		-- Get a list of all the columns that exist on the live database table

		Select @sColumnListInTable=isnull(nullif(@sColumnListInTable collate database_default +','+char(10),','+char(10)),'')+char(9)+char(9)+COLUMN_NAME+char(9)+
					DATA_TYPE+
					CASE WHEN(ISNULL(CHARACTER_MAXIMUM_LENGTH,0) > 0)
						THEN '('+cast(CHARACTER_MAXIMUM_LENGTH as nvarchar)+')'+CASE WHEN(DATA_TYPE not like '%binary') THEN ' collate database_default' END
					     WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN
						CASE WHEN DATA_TYPE = 'xml' then ''
						     else '(max)' + CASE WHEN(DATA_TYPE not like '%binary') THEN ' collate database_default' else '' END
						END
					     WHEN(DATA_TYPE='decimal')
						THEN '('+cast(NUMERIC_PRECISION as nvarchar)+','+cast(NUMERIC_SCALE as nvarchar)+')'
					END+
					' NULL'
		from "+@sInproDB+".INFORMATION_SCHEMA.COLUMNS 
		where TABLE_NAME='"+@psTable+"'
		and DATA_TYPE not in ('ntext','text','image','sysname')
		and COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
		order by ORDINAL_POSITION

		If isnull(@sColumnListInLog,'')<> isnull(@sColumnListInTable,'')
			Set @bTableHasChanged=1"

		If @bUseLogSequence=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+
			"		Else If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='"+@psTable+"_iLOG' AND COLUMN_NAME = 'LOGSEQUENCE')"+char(10)+
			"			Set @bTableHasChanged=1"
		End
		Else Begin
			Set @sSQLString=@sSQLString+char(10)+
			"		Else If exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='"+@psTable+"_iLOG' AND COLUMN_NAME = 'LOGSEQUENCE')"+char(10)+
			"			Set @bTableHasChanged=1"
		End
		
		
		Set @sSQLString=@sSQLString+"
		Else Begin
			Select @bTableHasChanged=1
			from INFORMATION_SCHEMA.COLUMNS C1
			join INFORMATION_SCHEMA.COLUMNS C2 on (C2.TABLE_NAME='"+@psTable+"_iLOG'
							   and C2.COLUMN_NAME=C1.COLUMN_NAME)
			where C1.TABLE_NAME='"+@psTable+"'
			and C1.DATA_TYPE not in ('ntext','text','image','sysname')
			and C1.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION','LOGSEQUENCE')
			and(C1.DATA_TYPE<>C2.DATA_TYPE 
			 OR ISNULL(C1.CHARACTER_MAXIMUM_LENGTH,0)<>ISNULL(C2.CHARACTER_MAXIMUM_LENGTH,0)
			 OR ISNULL(C1.NUMERIC_PRECISION,0)       <>ISNULL(C2.NUMERIC_PRECISION,0)
			 OR ISNULL(C1.NUMERIC_SCALE,0)           <>ISNULL(C2.NUMERIC_SCALE,0) )
		End"

		Set @sSQLString=@sSQLString+"
		-- Store the list of Columns that exist in both the current log and 
		-- in the live table if the table has changed

		If @bTableHasChanged=1
		and @sOldColumnList is null
		Begin
			Select @sOldColumnList=isnull(nullif(@sOldColumnList collate database_default +',',','),'')+C1.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS C1
			left join "+@sInproDB+".INFORMATION_SCHEMA.COLUMNS C2 	
						on (C2.TABLE_NAME='"+@psTable+"'
						and C2.COLUMN_NAME collate database_default =C1.COLUMN_NAME
						and C2.DATA_TYPE not in ('ntext','text','image','sysname'))
			where C1.TABLE_NAME='"+@psTable+"_iLOG'
			and C1.DATA_TYPE not in ('ntext','text','image','sysname')
			and (C1.COLUMN_NAME like 'LOG%' OR C2.COLUMN_NAME is not null)" + 
			case when @bUseLogSequence = 0 then "
			and (C1.COLUMN_NAME <> 'LOGSEQUENCE')" else "" end +"
			order by C1.ORDINAL_POSITION
	
			if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME='"+@psTable+"_iLOGBAK')
			begin
				drop table "+@psTable+"_iLOGBAK
			End
	
			-- Now rename the current log table
			exec @ErrorCode=sp_rename ["+ @psTable +"_iLOG], ["+ @psTable +"_iLOGBAK]
		End
	End
	use "+@sInproDB+"
	"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sOldColumnList	nvarchar(max)	OUTPUT,
				  @bTableHasChanged	bit		OUTPUT,
				  @ErrorCode		int		OUTPUT',
				  @sOldColumnList=@sOldColumnList	OUTPUT,
				  @bTableHasChanged=@bTableHasChanged	OUTPUT,
				  @ErrorCode=@ErrorCode			OUTPUT

	If @ErrorCode=0
	and @pbPrintLog=1
	and @sOldColumnList is not null
		raiserror('Log table backup done       for %s_iLOG',0,1,@psTable) with nowait
End
-----------------------------------------------------
-- Check to see if logging for the table is required.
-----------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bLogRequired=LOGFLAG
	from AUDITLOGTABLES
	where TABLENAME=@psTable"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@bLogRequired		bit	OUTPUT,
				  @psTable		varchar(128)',
				  @bLogRequired=@bLogRequired	OUTPUT,
				  @psTable=@psTable
End

-------------------------------------------------
-- Get a list of the columns to be logged which 
-- excludes the audit columns as they will have 
-- current values inserted into them when the log 
-- is written.
-------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sLogColumnList=isnull(nullif(@sLogColumnList+',',','),'')+COLUMN_NAME
	from INFORMATION_SCHEMA.COLUMNS 
	where TABLE_NAME=@psTable
	and DATA_TYPE not in ('ntext','text','image','sysname')
	and COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
	order by ORDINAL_POSITION"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sLogColumnList	varchar(4000)	OUTPUT,
				  @psTable		varchar(128)',
				  @sLogColumnList=@sLogColumnList	OUTPUT,
				  @psTable=@psTable


	-- Get a special ColumnList for modified EVENTDATE handling (Adri Koopman, Novagraaf)
	Select @sLogColumnListEventDate = REPLACE(',' + @sLogColumnList + ',',',EVENTDATE,',',convert(nvarchar,EVENTDATE,112),')
	select @sLogColumnListEventDate = SUBSTRING(@sLogColumnListEventDate, 2, LEN(@sLogColumnListEventDate)-2)

End
-----------------------------------
-- Create logging table if required
-----------------------------------
If  @ErrorCode=0
and @bLogRequired=1
and @bTableHasChanged=1
Begin
	set @sSQLString=
	"Create table "+@sLoggingDB+".dbo." + @psTable + "_iLOG (" +
	case when @bUseLogSequence = 1 then "
		LOGSEQUENCE		int		IDENTITY(1,1) NOT NULL," else "" end + "
		LOGUSERID		nvarchar(50)	collate database_default NOT NULL,
		LOGIDENTITYID		int 		NULL,
		LOGTRANSACTIONNO	int		NULL, 
		LOGDATETIMESTAMP 	datetime 	NOT NULL,
		LOGACTION 		nchar(1) 	collate database_default NOT NULL,
		LOGOFFICEID		int		NULL,
		LOGAPPLICATION		nvarchar(128)	collate database_default NULL"
	
	-- Construct the columns to be logged by concatenating the details of each 
	-- column onto the @sSQLString1
	Select @sSQLString=isnull(nullif(@sSQLString+','+char(10),','+char(10)),'')+char(9)+char(9)+COLUMN_NAME+char(9)+
				DATA_TYPE+
				CASE WHEN(ISNULL(CHARACTER_MAXIMUM_LENGTH,0) > 0)
					THEN '('+cast(CHARACTER_MAXIMUM_LENGTH as nvarchar)+')'+CASE WHEN(DATA_TYPE not like '%binary') THEN ' collate database_default' END
				     WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN
					CASE WHEN DATA_TYPE = 'xml' then ''
					     else '(max)' + CASE WHEN(DATA_TYPE not like '%binary') THEN ' collate database_default' else '' END
					END
				     WHEN(DATA_TYPE='decimal')
					THEN '('+cast(NUMERIC_PRECISION as nvarchar)+','+cast(NUMERIC_SCALE as nvarchar)+')'
					ELSE ''
				END+
				' NULL'
	from INFORMATION_SCHEMA.COLUMNS 
	where TABLE_NAME=@psTable
	and DATA_TYPE not in ('ntext','text','image','sysname')
	and COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION','LOGSEQUENCE')
	order by ORDINAL_POSITION

	Set @sSQLString=isnull(@sSQLString,'') + ')'

	exec @ErrorCode = sp_executesql @sSQLString

	Set @sSQLString=''
	
	If @ErrorCode=0
	and @pbPrintLog=1
		raiserror('Log table created           for %s_iLOG',0,1,@psTable) with nowait

	-------------------
	-- Grant permission
	-------------------
	If @ErrorCode=0
	Begin
		set @sSQLString = 
		"Use "+@sLoggingDB+";
		grant REFERENCES, SELECT, INSERT on " + @psTable + "_iLOG to public;
		use "+@sInproDB + ";"
	
		exec @ErrorCode=sp_executesql @sSQLString
	
		If  @ErrorCode=0
		and @pbPrintLog=1
			raiserror('Permissions granted         for %s_iLOG',0,1,@psTable) with nowait
	End

	---------------------------------------
	-- RFC9316
	-- Insert rows into TABLECODES for each 
	-- column of the table being logged.
	---------------------------------------
	If @ErrorCode=0
	Begin
		Set @nRowCount=0
		--------------------------------------------------
		-- Load the columns that may have validation rules
		-- associated with Case transactions. We must use
		-- the Audit Log Tables as these are required to
		-- detect whether data has changed and will
		-- trigger a data validation rule to fire.
		--------------------------------------------------
		If @psTable in ('CASES','CASEBUDGET','CASECHECKLIST','CASEIMAGE','CASELOCATION',
					'CASEEVENT','CASEEVENTTEXT','CASENAME','CASETEXT','PROPERTY','RELATEDCASE')
		Begin
			insert into @tblTableCodes (DESCRIPTION, USERCODE)
			select C1.TABLE_NAME + '.' + C1.COLUMN_NAME , 'C'
			from INFORMATION_SCHEMA.COLUMNS C1
			join INFORMATION_SCHEMA.COLUMNS C2 on (C2.TABLE_NAME =C1.TABLE_NAME+'_iLOG'
							   and C2.COLUMN_NAME=C1.COLUMN_NAME)
			left join TABLECODES TC	on (TC.TABLETYPE=-502
						and TC.DESCRIPTION=C1.TABLE_NAME + '.' + C1.COLUMN_NAME)
			where C1.TABLE_NAME=@psTable
			and C1.COLUMN_NAME not in ('CASEID','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
			and C1.COLUMN_NAME not like ('%_TID')
			and TC.TABLECODE is null
			order by 1

			Select	@ErrorCode=@@Error,
				@nRowCount=@@rowcount
		End
		Else If @psTable in ('ADDRESS','ASSOCIATEDNAME','EMPLOYEE','INDIVIDUAL','IPNAME','NAME','NAMEADDRESS','NAMEALIAS','NAMEIMAGE',
				     'NAMEINSTRUCTIONS','NAMELANGUAGE','NAMETELECOM','NAMETEXT','ORGANISATION','TELECOMMUNICATION')
		Begin
			-- Load the columns that may have validation rules
			-- associated with Name transactions
			insert into @tblTableCodes (DESCRIPTION, USERCODE)
			select C1.TABLE_NAME + '.' + C1.COLUMN_NAME , 'N'
			from INFORMATION_SCHEMA.COLUMNS C1
			join INFORMATION_SCHEMA.COLUMNS C2 on (C2.TABLE_NAME =C1.TABLE_NAME+'_iLOG'
							   and C2.COLUMN_NAME=C1.COLUMN_NAME)
			left join TABLECODES TC	on (TC.TABLETYPE=-502
						and TC.DESCRIPTION=C1.TABLE_NAME + '.' + C1.COLUMN_NAME)
			where C1.TABLE_NAME in ('ADDRESS','ASSOCIATEDNAME','EMPLOYEE','INDIVIDUAL','IPNAME','NAME','NAMEADDRESS','NAMEALIAS','NAMEIMAGE',
					        'NAMEINSTRUCTIONS','NAMELANGUAGE','NAMETELECOM','NAMETEXT','ORGANISATION','TELECOMMUNICATION')
			and C1.COLUMN_NAME not in ('NAMENO','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
			and C1.COLUMN_NAME not like ('%_TID')
			and TC.TABLECODE is null
			order by 1

			Select	@ErrorCode=@@Error,
				@nRowCount=@@rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			-- Update the LASTINTERNALCODES table

			Update LASTINTERNALCODE
			set @nNextTableCode =INTERNALSEQUENCE,
			    INTERNALSEQUENCE=INTERNALSEQUENCE+@nRowCount
			Where TABLENAME='TABLECODES'

			Insert into TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION, USERCODE) 
			select @nNextTableCode+TABLECODE, -502, DESCRIPTION, USERCODE
			from @tblTableCodes

			If @pbPrintLog=1
				raiserror('**** Data successfully added to TABLECODES table.',0,1) with nowait
		End
	End
End

-----------------------------------------------------------------
-- If the logs are being held on a separate database then
-- generate a VIEW on the main database to point to the log table
-- This is required for the Audit enquiry to work
-----------------------------------------------------------------
If  @sInproDB<>@sLoggingDB
and @bLogRequired=1
and @ErrorCode=0
Begin
	Set @sSQLString="
	Create VIEW dbo." + @psTable + "_iLOG
	as
	Select * from "+@sLoggingDB+".dbo." + @psTable + "_iLOG"

	exec @ErrorCode=sp_executesql @sSQLString

	If @ErrorCode=0
	Begin
		If @pbPrintLog=1
			raiserror('Local view granted          for %s_iLOG',0,1,@psTable) with nowait

		set @sSQLString = "
		grant select, insert on "+@sInproDB+".dbo." + @psTable + "_iLOG to public"
	
		exec @ErrorCode=sp_executesql @sSQLString
	
		If @ErrorCode=0
		and @pbPrintLog=1
			raiserror('Permissions granted on view for %s_iLOG',0,1,@psTable) with nowait
	End
	
	---------------------------------------
	-- RFC9316
	-- Insert rows into TABLECODES for each 
	-- column of the table being logged.
	---------------------------------------
	If @ErrorCode=0
	Begin
		Set @nRowCount=0
		--------------------------------------------------
		-- Load the columns that may have validation rules
		-- associated with Case transactions. We must use
		-- the Audit Log Tables as these are required to
		-- detect whether data has changed and will
		-- trigger a data validation rule to fire.
		--------------------------------------------------
		If @psTable in ('CASES','CASEBUDGET','CASECHECKLIST','CASEIMAGE','CASELOCATION','CASEEVENT','CASENAME','CASETEXT','PROPERTY','RELATEDCASE')
		Begin
			insert into @tblTableCodes (DESCRIPTION, USERCODE)
			select C1.TABLE_NAME + '.' + C1.COLUMN_NAME , 'C'
			from INFORMATION_SCHEMA.COLUMNS C1
			join INFORMATION_SCHEMA.COLUMNS C2 on (C2.TABLE_NAME =C1.TABLE_NAME+'_iLOG'
							   and C2.COLUMN_NAME=C1.COLUMN_NAME)
			left join TABLECODES TC	on (TC.TABLETYPE=-502
						and TC.DESCRIPTION=C1.TABLE_NAME + '.' + C1.COLUMN_NAME)
			where C1.TABLE_NAME=@psTable
			and C1.COLUMN_NAME not in ('CASEID','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
			and C1.COLUMN_NAME not like ('%_TID')
			and TC.TABLECODE is null
			order by 1

			Select	@ErrorCode=@@Error,
				@nRowCount=@@rowcount
		End
		Else If @psTable in ('ADDRESS','ASSOCIATEDNAME','EMPLOYEE','INDIVIDUAL','IPNAME','NAME','NAMEADDRESS','NAMEALIAS','NAMEIMAGE',
				     'NAMEINSTRUCTIONS','NAMELANGUAGE','NAMETELECOM','NAMETEXT','ORGANISATION','TELECOMMUNICATION')
		Begin
			-- Load the columns that may have validation rules
			-- associated with Name transactions
			insert into @tblTableCodes (DESCRIPTION, USERCODE)
			select C1.TABLE_NAME + '.' + C1.COLUMN_NAME , 'N'
			from INFORMATION_SCHEMA.COLUMNS C1
			join INFORMATION_SCHEMA.COLUMNS C2 on (C2.TABLE_NAME =C1.TABLE_NAME+'_iLOG'
							   and C2.COLUMN_NAME=C1.COLUMN_NAME)
			left join TABLECODES TC	on (TC.TABLETYPE=-502
						and TC.DESCRIPTION=C1.TABLE_NAME + '.' + C1.COLUMN_NAME)
			where C1.TABLE_NAME in ('ADDRESS','ASSOCIATEDNAME','EMPLOYEE','INDIVIDUAL','IPNAME','NAME','NAMEADDRESS','NAMEALIAS','NAMEIMAGE',
					     'NAMEINSTRUCTIONS','NAMELANGUAGE','NAMETELECOM','NAMETEXT','ORGANISATION','TELECOMMUNICATION')
			and C1.COLUMN_NAME not in ('NAMENO','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
			and C1.COLUMN_NAME not like ('%_TID')
			and TC.TABLECODE is null
			order by 1

			Select	@ErrorCode=@@Error,
				@nRowCount=@@rowcount
		End

		If  @ErrorCode=0
		and @nRowCount>0
		Begin
			-- Update the LASTINTERNALCODES table

			Update LASTINTERNALCODE
			set @nNextTableCode =INTERNALSEQUENCE,
			    INTERNALSEQUENCE=INTERNALSEQUENCE+@nRowCount
			Where TABLENAME='TABLECODES'

			Insert into TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION, USERCODE) 
			select @nNextTableCode+TABLECODE, -502, DESCRIPTION, USERCODE
			from @tblTableCodes

			If @pbPrintLog=1
				PRINT '**** Data successfully added to TABLECODES table.'
		End
	End
End
-------------------------------------------------------------------------
-- Get all of the columns for the table and identify those columns that
-- are part of the primary key.  Also return the associated TID column if
-- there is one and any other Column sharing the same TID Column.
-------------------------------------------------------------------------
If @ErrorCode=0
Begin
	insert into @tbColumns(Name, TIDColumn, RelatedColumn, DataType, Type, Length, KeyNo, IsIdentity, IsRowGuid)
	select	Name,
		TIDColumn,
		RelatedColumn,
		DataType = x.Type +
				case when (x.Type like '%binary') or (x.Type like '%char')
					then N'(' + case when x.Length > 0 then cast(x.Length as nvarchar) else 'max' end + ')' +
					case when x.collation_name is NULL then '' else ' collate database_default' end
				     when x.Type = 'decimal'
					then N'(' + cast(x.precision as nvarchar)+','+cast(x.scale as nvarchar)+')'
					else ''
				end,
		Type,
		Length,
		KeyNo,
		IsIdentity,
		IsRowGuid
	from (	Select	Name = C.name,
			C.column_id,
			TIDColumn = TS.TIDCOLUMN,
		-- Where 2 columns point to the same TIDColumn then save the name of the other column
			RelatedColumn = CASE WHEN(TS.SHORTCOLUMN=C.name) THEN TS.LONGCOLUMN ELSE TS.SHORTCOLUMN END,
			Type = T.name,
			C.collation_name,
			C.precision,
			C.scale,
			Length = CASE WHEN(T.name in ('nchar','nvarchar')) THEN C.max_length/2 ELSE C.max_length END,
			KeyNo = K.index_column_id,
			IsIdentity = COLUMNPROPERTY(O.object_id, C.name, 'IsIdentity'),
			IsRowGuid = COLUMNPROPERTY(O.object_id, C.name, 'IsRowGuidCol') 
		from	sys.tables O
		inner	join	sys.columns C
			on	C.object_id=O.object_id
		inner	join	sys.types   T
			on	T.user_type_id=C.user_type_id
			and	T.system_type_id=C.system_type_id
		left	join	sys.indexes I
			on	I.object_id=O.object_id
		--	and	I.name = kc.name
			and	(I.is_primary_key = 1 or I.name like 'XPK%')
		left	join	sys.index_columns K
			on	K.object_id=I.object_id
			and	K.index_id=I.index_id
			and	K.column_id=C.column_id
		left	join	TRANSLATIONSOURCE TS
			on	TS.TABLENAME=O.name
			and	C.name in (TS.SHORTCOLUMN, TS.LONGCOLUMN)
		where	O.name = @psTable
		and	T.name not in ('sysname') ) x
	order by isnull(x.KeyNo,999), x.column_id
	
	select	@nColCount=@@Rowcount,
		@ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	-- Save the Identity column name
	-- if one exists

	select @sIdentityColumn=Name
	from @tbColumns
	where IsIdentity=1

	Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	-- Get the Position of the last column 
	-- that is part of the primary key.
	
	select @nLastKeyPos=isnull(max(Position),1)
	from @tbColumns
	where KeyNo is not null

	Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	-- Get a concatenated string of Columns
	-- (excluding Identity columns and audit columns)

	Select @sColumnList = ISNULL(NULLIF(@sColumnList + ',', ','),'')  + Name
	from @tbColumns
	where IsIdentity=0
	and Name not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
	order by Position

	Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	-- Get a special ColumnList for modified EVENTDATE handling (Adri Koopman, Novagraaf)
	Select @sColumnListEventDate = REPLACE(',' + @sColumnList + ',',',EVENTDATE,',',convert(nvarchar,EVENTDATE,112),')
	select @sColumnListEventDate = SUBSTRING(@sColumnListEventDate, 2, LEN(@sColumnListEventDate)-2)
End

If @ErrorCode=0
Begin
	-- Get a concatenated string of all Columns

	Select @sFullColumnList = ISNULL(NULLIF(@sFullColumnList + ',', ','),'')  + Name
	from @tbColumns
	order by Position

	Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	-- Get a concatenated string of TID Columns

	Select @sTIDColumnList = ISNULL(NULLIF(@sTIDColumnList + ',', ','),'')  + Name
	from @tbColumns C
	join TRANSLATIONSOURCE T on (T.TABLENAME=@psTable
				 and T.TIDCOLUMN=C.Name)
	where C.Name like '%\_TID' escape '\'
	order by Position

	Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	-- Get a concatenated string of the columns that are part of the
	-- primary key
	select @sKeyColumns = ISNULL(NULLIF(@sKeyColumns + ',', ','),'')  + Name
	from @tbColumns
	where KeyNo is not null
	order by KeyNo

	Set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	-- Construct a set of joins for the columns 
	-- that are part of the primary key

	select @sKeyJoins=ISNULL(NULLIF(@sKeyJoins + ' and ',' and '),'')+'t.'+Name+'=i.'+Name
	from @tbColumns
	where KeyNo is not null
	order by KeyNo

	Set @ErrorCode=@@Error

	If @ErrorCode=0
	and @sKeyJoins is null
	Begin
		Set @sMessage = 'Audit triggers cannot be generated for table %s. Table must have a primary key.'
		RAISERROR(@sMessage, 16, 1, @psTable)
		Set @ErrorCode = @@Error
	End
End

If @ErrorCode=0
Begin
	-- If a column is either 'text' or 'ntext'
	-- then a flag will be set to cause the triggers to be generated as INSTEAD OF triggers.
	-- This is because an AFTER trigger cannot reference a column that is defined as 'text' or 'ntext'
	
	if exists(	select 1
			from @tbColumns
			where DataType in ('text','ntext'))
	Begin
		Set @bTableHasText=1
	End
	Else Begin
		Set @bTableHasText=0
	End
End

--------------------------------------------------------------------------------------
--
-- Generation of the DELETE trigger
--
--------------------------------------------------------------------------------------
If @ErrorCode=0
Begin

	Set @sSQLString="
	if exists (select * from sysobjects where name = 'TD_iLOGGING_" +@psTable + "' and type = 'TR')
	Begin
		If @pbPrintLog=1
			raiserror('Dropping trigger                TD_iLOGGING_"+@psTable+"',0,1) with nowait

		drop trigger dbo.TD_iLOGGING_" + @psTable+"
	End

	if exists (select * from sysobjects where type='TR' and name = 'tD_"+@psTable+"_Translation')
	begin
		If @pbPrintLog=1
			raiserror('Dropping trigger                TD_"+@psTable+"_Translation',0,1) with nowait

		DROP TRIGGER tD_"+@psTable+"_Translation
	end

	if exists (select * from sysobjects where type='TR' and name = 'tD_"+@psTable+"_Audit')
	begin
		If @pbPrintLog=1
			raiserror('Dropping trigger                TD_"+@psTable+"_Audit',0,1) with nowait

		DROP TRIGGER tD_"+@psTable+"_Audit
	end"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pbPrintLog		bit',
				  @pbPrintLog=@pbPrintLog
End

If @ErrorCode=0
and (@bLogRequired=1 
 OR  @sTIDColumnList is not null
 OR  @psTable in ('CASES','CASEBUDGET','CASECHECKLIST','CASEIMAGE','CASELOCATION','CASEEVENT','CASEEVENTTEXT','CASENAME','CASETEXT','PROPERTY','RELATEDCASE',
		  'OFFICIALNUMBERS','NAMEINSTRUCTIONS','ALERT','CRMCASESTATUSHISTORY','OPPORTUNITY','JOURNAL','CLASSFIRSTUSE','DESIGNELEMENT','TABLEATTRIBUTES'))
Begin
	Set @sSQLString="	
	CREATE TRIGGER tD_"+@psTable+"_Audit on "+@psTable+" AFTER DELETE NOT FOR REPLICATION 
	as
	-- TRIGGER :	tD_"+@psTable+"_Audit
	-- VERSION :	"+@sVersion+"
	-- DESCRIPTION:"

	If @sTIDColumnList is not null
	Begin
		Set @sSQLString=@sSQLString+"
	--		Removal of parent TRANSLATIONITEM data when referenced TID no longer required."
	End

	If @bLogRequired=1
	Begin
		Set @sSQLString=@sSQLString+"
	--		Write Audit Logs recording details of deleted rows."
	End

	Set @sSQLString=@sSQLString+"
	-- MODIFICATIONS :
	-- Date		Who	Change	Version	Description
	-- -----------	-------	------	-------	----------------------------------------------- 
	-- "+convert(nvarchar, getdate(),106)+"	MF		1	Trigger created
	
	Begin"
	
	If  @bLogRequired=1
	OR  @psTable in ('CASES','CASEBUDGET','CASECHECKLIST','CASEIMAGE','CASELOCATION','CASEEVENT','CASEEVENTTEXT','CASENAME','CASETEXT','PROPERTY','RELATEDCASE',
			 'OFFICIALNUMBERS','NAMEINSTRUCTIONS','ALERT','CRMCASESTATUSHISTORY','OPPORTUNITY','JOURNAL','CLASSFIRSTUSE','DESIGNELEMENT','TABLEATTRIBUTES')
	Begin	
	
		Set @sSQLString=@sSQLString+"
		declare @nIdentityId		int
		declare @nSessionTransNo	int
		declare @nOfficeId		int
		declare @nOffset		int
		declare @dtCurrentDate		datetime
		declare @nComponentId int
		declare @sApplicationName nvarchar(128)

		Set @sApplicationName = APP_NAME()
		
		select	@nIdentityId    =CASE WHEN(substring(context_info,1,4) <>0x0000000) THEN cast(substring(context_info,1,4)  as int) END,
			@nSessionTransNo=CASE WHEN(substring(context_info,5,4) <>0x0000000) THEN cast(substring(context_info,5,4)  as int) END,
			@nOfficeId      =CASE WHEN(substring(context_info,13,4)<>0x0000000) THEN cast(substring(context_info,13,4) as int) END,
			@nOffset	=CASE WHEN(substring(context_info,17,4)<>0x0000000) THEN cast(substring(context_info,17,4) as int) END,
			@nComponentId	=CASE WHEN(substring(context_info,21,4)<>0x0000000) THEN cast(substring(context_info,21,4) as int) END
		from master.dbo.sysprocesses
		where spid=@@SPID
		and(substring(context_info,1, 4)<>0x0000000
		 or substring(context_info,5, 4)<>0x0000000
		 or substring(context_info,13,4)<>0x0000000
		 or substring(context_info,17,4)<>0x0000000
		 or substring(context_info,21,4)<>0x0000000)"

		If @bUseGetUtcDate=1
		Begin
			Set @sSQLString=@sSQLString+"

			Set @dtCurrentDate=getutcdate()"
		End
		Else Begin
			Set @sSQLString=@sSQLString+"

			if @nComponentId is not null 
			Begin
				Select @sApplicationName = ISNULL((SELECT INTERNALNAME
				from COMPONENTS where COMPONENTID = @nComponentId),@sApplicationName)
			End

			if @nOffset is null
			Begin
				select @nOffset=COLINTEGER
				from SITECONTROL
				where CONTROLID='Log Time Offset'
			End

			Set @dtCurrentDate=dateadd(mi,isnull(@nOffset,0),getdate())"
		End
	End
	
	If @psTable in ('CASES','CASEBUDGET','CASECHECKLIST','CASEIMAGE','CASELOCATION','CASEEVENT','CASEEVENTTEXT','CASENAME','CASETEXT','PROPERTY','RELATEDCASE',
			'OFFICIALNUMBERS','NAMEINSTRUCTIONS','ALERT','CRMCASESTATUSHISTORY','OPPORTUNITY','JOURNAL','CLASSFIRSTUSE','DESIGNELEMENT','TABLEATTRIBUTES')
	Begin
		------------------------------------
		-- For the main Case related tables,
		-- update or insert the CASEVENT for
		-- EventNo -14 using todays date.
		------------------------------------
		If @psTable='TABLEATTRIBUTES'
			Set @sSQLString=@sSQLString+"
			Update CASEEVENT
			set 	EVENTDATE=convert(varchar, @dtCurrentDate, 112), 
				OCCURREDFLAG=1,
				LOGUSERID=SYSTEM_USER,
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
			from deleted d
			join CASEEVENT T1 on (T1.CASEID=cast(d.GENERICKEY as numeric)
					  and T1.EVENTNO=-14 
					  and T1.CYCLE=1)
			where(T1.EVENTDATE<>convert(varchar, @dtCurrentDate, 112) OR T1.OCCURREDFLAG<>1)
			and d.PARENTTABLE='CASES'
			and isnumeric(d.GENERICKEY)=1"
		Else
			Set @sSQLString=@sSQLString+"
			Update CASEEVENT
			set 	EVENTDATE=convert(varchar, @dtCurrentDate, 112), 
				OCCURREDFLAG=1,
				LOGUSERID=SYSTEM_USER,
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
			from deleted d
			join CASEEVENT T1 on (T1.CASEID=d.CASEID and T1.EVENTNO=-14 and T1.CYCLE=1)
			where(T1.EVENTDATE<>convert(varchar, @dtCurrentDate, 112) OR T1.OCCURREDFLAG<>1)"
		
		If @psTable='CASEEVENT'
			Set @sSQLString=@sSQLString+CHAR(10)+
			"		and d.EVENTNO<>-14"
		
		If @psTable='TABLEATTRIBUTES'
			Set @sSQLString=@sSQLString+"
			
			insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGOFFICEID, LOGAPPLICATION)
			select distinct cast(d.GENERICKEY as numeric), -14, 1, convert(varchar, @dtCurrentDate, 112), 1, SYSTEM_USER, @nIdentityId, @nSessionTransNo, @dtCurrentDate, @nOfficeId, @sApplicationName 
			from deleted d
			join CASES C on (C.CASEID=cast(d.GENERICKEY as numeric))
			left join CASEEVENT T1 on (T1.CASEID=C.CASEID and T1.EVENTNO=-14 and T1.CYCLE=1)
			where T1.CASEID is null
			and d.PARENTTABLE='CASES'
			and isnumeric(d.GENERICKEY)=1"
		Else
			Set @sSQLString=@sSQLString+"
			
			insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGOFFICEID, LOGAPPLICATION)
			select distinct d.CASEID, -14, 1, convert(varchar, @dtCurrentDate, 112), 1, SYSTEM_USER, @nIdentityId, @nSessionTransNo, @dtCurrentDate, @nOfficeId, @sApplicationName 
			from deleted d
			join CASES C on (C.CASEID=d.CASEID)
			left join CASEEVENT T1 on (T1.CASEID=d.CASEID and T1.EVENTNO=-14 and T1.CYCLE=1)
			where T1.CASEID is null"
		
		If @psTable='CASEEVENT'
			Set @sSQLString=@sSQLString+CHAR(10)+
			"		and d.EVENTNO<>-14"
	End
	
	If @bLogRequired=1
	Begin	
		Set @sSQLString=@sSQLString+"

		insert into "+CASE WHEN(@sLoggingDB<>@sInproDB) THEN @sLoggingDB+".." END + @psTable + "_iLOG
			(LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGACTION, LOGOFFICEID, LOGAPPLICATION,
			 " + @sLogColumnList + ")
		select " +
		case when @bUsernameOnly = 1
			then "dbo.fn_SystemUser()"
			else "SYSTEM_USER"
		end + ",@nIdentityId,@nSessionTransNo,@dtCurrentDate,'D',@nOfficeId,@sApplicationName ,"

		Set @sSQLString=@sSQLString+char(10)+char(9)+char(9)+@sLogColumnList+char(10)+char(9)+char(9)+"from deleted"
	End

	If @sTIDColumnList is not null
	Begin
		Set @sSQLString=@sSQLString+"

		delete TRANSLATEDITEMS
		from deleted
		join TRANSLATEDITEMS TI	on (TI.TID in ("+@sTIDColumnList+"))"
	End
	
	Set @sSQLString=@sSQLString+"
	End"

	if @pbPrintSQL = 1
	begin
		select	@sSqlMsg = 'select @sSQLString as tD_' + @psTable + '_Audit'
		exec sp_executesql @sSqlMsg, N'@sSQLString nvarchar(max)', @sSQLString
	end

	exec @ErrorCode=sp_executesql @sSQLString

	If @pbPrintLog=1
	and @ErrorCode=0
		raiserror('Delete trigger created      for tD_%s_Audit',0,1,@psTable) with nowait

End -- Generation of DELETE Trigger

--------------------------------------------------------------------------------------
--
-- Generation of the INSERT trigger
--
--------------------------------------------------------------------------------------
If @ErrorCode=0
Begin

	Set @sSQLString="
	if exists (select * from sysobjects where name = 'TI_iLOGGING_" +@psTable + "' and type = 'TR')
	Begin
		If @pbPrintLog=1
			raiserror('Dropping trigger                TI_iLOGGING_"+@psTable+"',0,1) with nowait

		drop trigger dbo.TI_iLOGGING_" + @psTable+"
	End 

	if exists (select * from sysobjects where type='TR' and name = 'tI_"+@psTable+"_Translation')
	begin
		If @pbPrintLog=1
			raiserror('Dropping trigger                tI_"+@psTable+"_Translation',0,1) with nowait

		DROP TRIGGER tI_"+@psTable+"_Translation
	end

	if exists (select * from sysobjects where type='TR' and name = 'tI_"+@psTable+"_Audit')
	begin
		If @pbPrintLog=1
			raiserror('Dropping trigger                tI_"+@psTable+"_Audit',0,1) with nowait

		DROP TRIGGER tI_"+@psTable+"_Audit
	end"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pbPrintLog		bit',
				  @pbPrintLog=@pbPrintLog
End

set @sSQLString=''

If @ErrorCode=0
Begin
	Set @sSQLString="
	CREATE TRIGGER tI_"+@psTable+"_Audit on "+@psTable+CASE WHEN(@bTableHasText=0) THEN " AFTER " ELSE " INSTEAD OF " END+" INSERT NOT FOR REPLICATION 
	as
	-- TRIGGER :	tI_"+@psTable+"_Audit
	-- VERSION :	"+@sVersion+"
	-- DESCRIPTION:	Gets audit details for inclusion into the row about to be inserted"

	If @sTIDColumnList is not null
	Begin
		Set @sSQLString=@sSQLString+"
	--		Generate a TID for each column containing data that is eligible for translation
	--		by inserting a row in the TRANSLATEDITEMS table and updating the associated
	--		TID column(s) on the "+@psTable+" table."
	End

	If @bLogRequired=1
	Begin
		Set @sSQLString=@sSQLString+"
	--		Write Audit Logs recording details of inserted rows."
	End
	
	If @bTableHasText=1
	Begin
		Set @sSQLString=@sSQLString+"
	--		NOTE : This trigger fires BEFORE the insert into the base table so that the values
	--		       for the TID columns can be determined and included in the initial INSERT."
	END

	Set @sSQLString=@sSQLString+"
	-- MODIFICATIONS :
	-- Date		Who	Change	Version	Description
	-- -----------	-------	------	-------	----------------------------------------------- 
	-- "+convert(varchar, getdate(),106)+"	MF		1	Trigger created

	Begin"

	-- The trigger needs to extract details for inclusion into the audit columns.
	Set @sSQLString=@sSQLString+"
		declare @nIdentityId		int
		declare @nSessionTransNo	int
		declare @nOfficeId		int
		declare @nOffset		int
		declare @dtCurrentDate		datetime
		declare @nComponentId int
		declare @sApplicationName nvarchar(128)

		Set @sApplicationName = APP_NAME()
		
		select	@nIdentityId    =CASE WHEN(substring(context_info,1,4) <>0x0000000) THEN cast(substring(context_info,1,4)  as int) END,
			@nSessionTransNo=CASE WHEN(substring(context_info,5,4) <>0x0000000) THEN cast(substring(context_info,5,4)  as int) END,
			@nOfficeId      =CASE WHEN(substring(context_info,13,4)<>0x0000000) THEN cast(substring(context_info,13,4) as int) END,
			@nOffset	=CASE WHEN(substring(context_info,17,4)<>0x0000000) THEN cast(substring(context_info,17,4) as int) END,
			@nComponentId	=CASE WHEN(substring(context_info,21,4)<>0x0000000) THEN cast(substring(context_info,21,4) as int) END
		from master.dbo.sysprocesses
		where spid=@@SPID
		and(substring(context_info,1, 4)<>0x0000000
		 or substring(context_info,5, 4)<>0x0000000
		 or substring(context_info,13,4)<>0x0000000
		 or substring(context_info,17,4)<>0x0000000
		 or substring(context_info,21,4)<>0x0000000)"

	If @bUseGetUtcDate=1
	Begin
		Set @sSQLString=@sSQLString+"

		Set @dtCurrentDate=getutcdate()"
	End
	Else Begin
		Set @sSQLString=@sSQLString+"

		if @nComponentId is not null 
		Begin
			Select @sApplicationName = ISNULL((SELECT INTERNALNAME
			from COMPONENTS where COMPONENTID = @nComponentId),@sApplicationName)
		End

		if @nOffset is null
		Begin
			select @nOffset=COLINTEGER
			from SITECONTROL
			where CONTROLID='Log Time Offset'
		End

		Set @dtCurrentDate=dateadd(mi,isnull(@nOffset,0),getdate())"
	End
	
	If @psTable in ('CASES','CASEBUDGET','CASECHECKLIST','CASEIMAGE','CASELOCATION','CASEEVENT','CASEEVENTTEXT','CASENAME','CASETEXT','PROPERTY','RELATEDCASE',
			'OFFICIALNUMBERS','NAMEINSTRUCTIONS','ALERT','CRMCASESTATUSHISTORY','OPPORTUNITY','JOURNAL','CLASSFIRSTUSE','DESIGNELEMENT','TABLEATTRIBUTES')
	Begin
		------------------------------------
		-- For the main Case related tables,
		-- update or insert the CASEVENT for
		-- EventNo -14 using todays date.
		------------------------------------
		If @psTable='TABLEATTRIBUTES'
			Set @sSQLString=@sSQLString+"
			Update CASEEVENT
			set 	EVENTDATE=convert(varchar, @dtCurrentDate, 112), 
				OCCURREDFLAG=1,
				LOGUSERID=SYSTEM_USER,
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
			from inserted i
			join CASEEVENT T1 on (T1.CASEID=cast(i.GENERICKEY as numeric)
					  and T1.EVENTNO=-14 
					  and T1.CYCLE=1)
			where(T1.EVENTDATE<>convert(varchar, @dtCurrentDate, 112) OR T1.OCCURREDFLAG<>1)
			and i.PARENTTABLE='CASES'
			and isnumeric(i.GENERICKEY)=1"
		Else
			Set @sSQLString=@sSQLString+"
			Update CASEEVENT
			set 	EVENTDATE=convert(varchar, @dtCurrentDate, 112), 
				OCCURREDFLAG=1,
				LOGUSERID=SYSTEM_USER,
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
			from inserted i
			join CASEEVENT T1 on (T1.CASEID=i.CASEID and T1.EVENTNO=-14 and T1.CYCLE=1)
			where(T1.EVENTDATE<>convert(varchar, @dtCurrentDate, 112) OR T1.OCCURREDFLAG<>1)"
		
		If @psTable='CASEEVENT'
			Set @sSQLString=@sSQLString+CHAR(10)+
			"		and i.EVENTNO<>-14"
		
		If @psTable='TABLEATTRIBUTES'
			Set @sSQLString=@sSQLString+"
			
			insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGOFFICEID, LOGAPPLICATION)
			select distinct cast(i.GENERICKEY as numeric), -14, 1, convert(varchar, @dtCurrentDate, 112), 1, SYSTEM_USER, @nIdentityId, @nSessionTransNo, @dtCurrentDate, @nOfficeId, @sApplicationName 
			from inserted i
			join CASES C on (C.CASEID=cast(i.GENERICKEY as numeric))
			left join CASEEVENT T1 on (T1.CASEID=C.CASEID and T1.EVENTNO=-14 and T1.CYCLE=1)
			where T1.CASEID is null
			and i.PARENTTABLE='CASES'
			and isnumeric(i.GENERICKEY)=1"
		Else
			Set @sSQLString=@sSQLString+"
			
			insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGOFFICEID, LOGAPPLICATION)
			select distinct i.CASEID, -14, 1, convert(varchar, @dtCurrentDate, 112), 1, SYSTEM_USER, @nIdentityId, @nSessionTransNo, @dtCurrentDate, @nOfficeId, @sApplicationName 
			from inserted i
			join CASES C on (C.CASEID=i.CASEID)
			left join CASEEVENT T1 on (T1.CASEID=i.CASEID and T1.EVENTNO=-14 and T1.CYCLE=1)
			where T1.CASEID is null"
		
		If @psTable='CASEEVENT'
			Set @sSQLString=@sSQLString+CHAR(10)+
			"		and i.EVENTNO<>-14"
	End

	If @bLogRequired=1
	Begin		
		Set @sSQLString=@sSQLString+"
		
		insert into "+CASE WHEN(@sLoggingDB<>@sInproDB) THEN @sLoggingDB+".." END + @psTable + "_iLOG
			(LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGACTION, LOGOFFICEID, LOGAPPLICATION,
			 " + @sLogColumnList + ")
		select " +
			case when @bUsernameOnly = 1
				then "dbo.fn_SystemUser()"
				else "SYSTEM_USER"
			end + ",@nIdentityId,@nSessionTransNo,@dtCurrentDate,'I',@nOfficeId,@sApplicationName ,"
		Set @sSQLString=@sSQLString+char(10)+char(9)+char(9)+@sLogColumnListEventDate+char(10)+char(9)+char(9)+"from inserted"
	End
	
	If @sTIDColumnList is null
	Begin
		-- No translations required so TID does not need to be determined.
		If @bTableHasText=1
		Begin
			-- If table has TEXT column then an INSTEAD OF trigger is used so
			-- we need to finish the INSERT along with the audit column details
			Set @sSQLString=@sSQLString+" 	
			insert into "+@psTable+"(LOGUSERID,LOGIDENTITYID,LOGTRANSACTIONNO,LOGDATETIMESTAMP,LOGOFFICEID,LOGAPPLICATION,"+@sColumnList+")
			select " +
				case when @bUsernameOnly = 1
					then "dbo.fn_SystemUser()"
					else "SYSTEM_USER"
				end + ",@nIdentityId,@nSessionTransNo,@dtCurrentDate,@nOfficeId,@sApplicationName ,"+@sColumnListEventDate+"
			from inserted"
		End
		Else Begin
			-- If table does not have TEXT column then an AFTER trigger is used
			-- so the inserted row must be updated with the additional audit details
			Set @sSQLString=@sSQLString+"

			Update "+@psTable+"
			set 	LOGUSERID=" +
				case when @bUsernameOnly = 1
					then "dbo.fn_SystemUser()"
					else "SYSTEM_USER"
				end + ",
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
			from inserted i
			join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")"	
		End
	End
	-- Translations exist
	Else Begin
	  If @bTableHasText=0
	  Begin
		-- If the table does not have a TEXT column then an AFTER trigger is being generated
		Set @sSQLString=@sSQLString+"

		If not exists(select 1 from TRANSLATIONSOURCE where TABLENAME='"+@psTable+"' and INUSE=1)
		Begin
			Update "+@psTable+"
			set 	LOGUSERID=" +
				case when @bUsernameOnly = 1
					then "dbo.fn_SystemUser()"
					else "SYSTEM_USER"
				end + ",
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
			from inserted i
			join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")
		End
		Else Begin"
					
	  End
	  Else Begin
		Set @sSQLString=@sSQLString+"

		If not exists(select 1 from TRANSLATIONSOURCE where TABLENAME='"+@psTable+"' and INUSE=1)
		Begin
			insert into "+@psTable+"(LOGUSERID,LOGIDENTITYID,LOGTRANSACTIONNO,LOGDATETIMESTAMP,LOGOFFICEID,LOGAPPLICATION,"+@sColumnList+")
			select " +
			case when @bUsernameOnly = 1
				then "dbo.fn_SystemUser()"
				else "SYSTEM_USER"
			end + ",@nIdentityId,@nSessionTransNo,@dtCurrentDate,@nOfficeId,@sApplicationName ,"+@sColumnList+"
			from inserted
		End
		Else Begin"
	  End

	  -- If translation columns exist (TID) then get the values
	  -- to be included in the row about to be inserted

	  Set @sSQLString=@sSQLString+"
			-- declare a variable to save the last inserted TID
			declare @nStartTID	int
	
			-- declare a table variable to hold the detail of each row being inserted
			-- that requires a TID and load it
			declare @tbROWS table (
				ROWNUMBER		int identity(1,1),"

	  -- Include the columns of the primary key into the table variable
	  Select @sSQLString = @sSQLString+char(10)+char(9)+char(9)+char(9)+char(9)+C.Name+char(9)+char(9)+C.DataType+
		--CASE WHEN(C.Type in ('char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext'))
		--	THEN ' collate database_default'
		--END +
		','
	  from @tbColumns C
	  where C.Position<=@nLastKeyPos
	  order by C.Position

	  Set @sSQLString=@sSQLString+"
				TIDCOLUMN		nvarchar(30) collate database_default,
				TRANSLATIONSOURCEID	int)

			insert into @tbROWS("+@sKeyColumns+", TIDCOLUMN, TRANSLATIONSOURCEID)"

	  Select @sSQLString=@sSQLString+"
 			select i."+replace(@sKeyColumns,',',',i.')+", TS.TIDCOLUMN, TS.TRANSLATIONSOURCEID
			from inserted i
			join TRANSLATIONSOURCE TS	on (TS.TABLENAME='"+@psTable+"'
							and TS.TIDCOLUMN='"+C.TIDColumn+"'
							and TS.INUSE    =1)
			where i."+C.Name+" is not null"+
			CASE WHEN(C.RelatedColumn is not null) THEN "
				and i."+C.RelatedColumn+" is null"
			END+
			CASE WHEN((select count(*) from @tbColumns C1 where C1.Position>C.Position and C1.TIDColumn is not null)>0)
				THEN "		
					union"
			END
	  from @tbColumns C
	  where C.TIDColumn is not null
	  order by C.Position

	  Set @sSQLString=@sSQLString+"

			-- Now load a TRANSLATEDITEMS row for each TID to be generated 
			-- The TID will be generated automatically from the Identity column
			insert into TRANSLATEDITEMS(TRANSLATIONSOURCEID)
			select TRANSLATIONSOURCEID
			from @tbROWS
	
			-- Get the value of the last identity column value inserted into TRANSLATEDITEMS
			-- table.  This is required so that we can determine a unique TID value for each
			-- column that has had a TRANSLATEDITEMS row insert when inserting the "+@psTable+" table 
			Select @nStartTID=SCOPE_IDENTITY() - (select ISNULL(COUNT(*),0) from @tbROWS)"


	  -- If the table does not include a Text column then the trigger will have fired after the  
	  -- Insert so we now need to Update the row with the new TID column values
	  If @bTableHasText=0
	  Begin
		Set @sSQLString=@sSQLString+"

			Update "+@psTable+"
			Set"
	
		Select @sSQLString=@sSQLString+char(10)+
			char(9)+char(9)+char(9)+C.TIDColumn+
			"=(select @nStartTID+t.ROWNUMBER from @tbROWS t where "+@sKeyJoins+" and t.TIDCOLUMN='"+C.TIDColumn+"')"+
			CASE WHEN((select count(*) from @tbColumns C1 where C1.Position>C.Position and C1.TIDColumn is not null)>0) THEN ',' else '' END
		from @tbColumns C
		left join @tbColumns C1 on (C1.TIDColumn=C.TIDColumn	-- DR-45012 Some columns use the same TID column for the translation
					and C1.Position >C.Position)	--          ensure the UPDATE references that TID only once.
		Where C.TIDColumn is not null
		and C1.Name is null
		and C.Name not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGOFFICEID','LOGAPPLICATION','LOGACTION')
		order by C.Position
	
		Set @sSQLString=@sSQLString+",
			LOGUSERID=" +
			case when @bUsernameOnly = 1
				then "dbo.fn_SystemUser()"
				else "SYSTEM_USER"
			end + ",
			LOGIDENTITYID=@nIdentityId,
			LOGTRANSACTIONNO=@nSessionTransNo,
			LOGDATETIMESTAMP=@dtCurrentDate,
			LOGOFFICEID=@nOfficeId,
			LOGAPPLICATION=@sApplicationName 
			from inserted i
			join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")"			
	  End
	  Else Begin
		-- If there are no Identity columns then the trigger is fired as a Replacement for
		-- the original Insert and so now we must perform the Insert of the data into the
		-- database along with the TID column values
	
		Set @sSQLString=@sSQLString+"

			-- Now load the "+@psTable+" table along with any TID values
			insert into "+@psTable+" ("+@sColumnList+",LOGUSERID,LOGIDENTITYID,LOGTRANSACTIONNO,LOGDATETIMESTAMP,LOGOFFICEID,LOGAPPLICATION)
			select "

		Select @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+
			CASE WHEN(C.Name like '%\_TID' escape '\')
				THEN "(select @nStartTID+t.ROWNUMBER from @tbROWS t where "+@sKeyJoins+" and t.TIDCOLUMN='"+C.TIDColumn+"')"
				ELSE "i."+C.Name
			END+','
		from @tbColumns C
		where IsIdentity=0
		and C.Name not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGOFFICEID','LOGAPPLICATION','LOGACTION')
		order by C.Position
	
		Set @sSQLString=@sSQLString+"
			" +
			case when @bUsernameOnly = 1
				then "dbo.fn_SystemUser()"
				else "SYSTEM_USER"
			end + ",@nIdentityId,@nSessionTransNo,@dtCurrentDate,@nOfficeId,@sApplicationName 
			from inserted i"
 	  End

	  Set @sSQLString=@sSQLString+char(10)+char(9)+char(9)+'End'
	
	END

	Set @sSQLString=@sSQLString+"
	End"

	if @pbPrintSQL = 1
	begin
		select	@sSqlMsg = 'select @sSQLString as tI_' + @psTable + '_Audit'
		exec sp_executesql @sSqlMsg, N'@sSQLString nvarchar(max)', @sSQLString
	end

	exec	@ErrorCode = sp_executesql @sSQLString

	If @pbPrintLog=1
	and @ErrorCode=0
		raiserror('Insert trigger created      for tI_%s_Audit',0,1,@psTable) with nowait
End

--------------------------------------------------------------------------------------
--
-- Generation of the UPDATE trigger
--
--------------------------------------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString=''

	Set @sSQLString="
	if exists (select * from sysobjects where name = 'TU_iLOGGING_" +@psTable + "' and type = 'TR')
	Begin
		If @pbPrintLog=1
			raiserror('Dropping trigger                TU_iLOGGING_"+@psTable+"',0,1) with nowait

		drop trigger dbo.TU_iLOGGING_" + @psTable+"
	End 

	if exists (select * from sysobjects where type='TR' and name = 'tU_"+@psTable+"_Translation')
	begin
		If @pbPrintLog=1
			raiserror('Dropping trigger                tU_"+@psTable+"_Translation',0,1) with nowait

		DROP TRIGGER tU_"+@psTable+"_Translation
	end

	if exists (select * from sysobjects where type='TR' and name = 'tU_"+@psTable+"_Audit')
	begin
		If @pbPrintLog=1
			raiserror('Dropping trigger                tU_"+@psTable+"_Audit',0,1) with nowait

		DROP TRIGGER tU_"+@psTable+"_Audit
	end"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pbPrintLog		bit',
				  @pbPrintLog=@pbPrintLog
End

/**************
-- The NAMETEXT table has a TEXT column however we wish to force the generation of 
-- an AFTER trigger due to an existing SQLServer error

If upper(@psTable)='NAMETEXT'
Begin
	Set @bTableHasText=0
End
*************/

If @ErrorCode=0
Begin
	Set @sSQLString="
	CREATE TRIGGER tU_"+@psTable+"_Audit on "+@psTable+CASE WHEN(@bTableHasText=0) THEN " AFTER " ELSE " INSTEAD OF " END+" UPDATE NOT FOR REPLICATION 
	as
	-- TRIGGER :	tU_"+@psTable+"_Audit
	-- VERSION :	"+@sVersion+"
	-- DESCRIPTION:	Gets audit details for inclusion into the row about to be updated"

	If @sTIDColumnList is not null
	Begin
		Set @sSQLString=@sSQLString+"
	--		Generate a TID for each column containing data that is eligible for translation
	--		by inserting a row in the TRANSLATEDITEMS table and updating the associated
	--		TID column(s) on the "+@psTable+" table."
	End

	If @bLogRequired=1
	Begin
		Set @sSQLString=@sSQLString+"
	--		Write Audit Logs recording details of updated rows."
	End
	
	If @bTableHasText=1
	Begin
		Set @sSQLString=@sSQLString+"
	--		NOTE : This trigger fires BEFORE the update into the base table so that the values
	--		       for the TID columns can be determined and included in the initial UPDATE."
	END

	Set @sSQLString=@sSQLString+"
	-- MODIFICATIONS :
	-- Date		Who	Change	Version	Description
	-- -----------	-------	------	-------	----------------------------------------------- 
	-- "+convert(varchar, getdate(),106)+"	MF		1	Trigger created

	If NOT UPDATE(LOGDATETIMESTAMP)
	Begin"

	-- The trigger needs to extract details for inclusion into the audit columns.
	Set @sSQLString=@sSQLString+"
		declare @nIdentityId		int
		declare @nSessionTransNo	int
		declare @nOfficeId		int
		declare @nOffset		int
		declare @dtCurrentDate		datetime
		declare @nComponentId int
		declare @sApplicationName nvarchar(128)

		Set @sApplicationName = APP_NAME()		
				
		select	@nIdentityId    =CASE WHEN(substring(context_info,1,4) <>0x0000000) THEN cast(substring(context_info,1,4)  as int) END,
			@nSessionTransNo=CASE WHEN(substring(context_info,5,4) <>0x0000000) THEN cast(substring(context_info,5,4)  as int) END,
			@nOfficeId      =CASE WHEN(substring(context_info,13,4)<>0x0000000) THEN cast(substring(context_info,13,4) as int) END,
			@nOffset	=CASE WHEN(substring(context_info,17,4)<>0x0000000) THEN cast(substring(context_info,17,4) as int) END,
			@nComponentId	=CASE WHEN(substring(context_info,21,4)<>0x0000000) THEN cast(substring(context_info,21,4) as int) END
		from master.dbo.sysprocesses
		where spid=@@SPID
		and(substring(context_info,1, 4)<>0x0000000
		 or substring(context_info,5, 4)<>0x0000000
		 or substring(context_info,13,4)<>0x0000000
		 or substring(context_info,17,4)<>0x0000000
		 or substring(context_info,21,4)<>0x0000000)"

	If @bUseGetUtcDate=1
	Begin
		Set @sSQLString=@sSQLString+"

		Set @dtCurrentDate=getutcdate()"
	End
	Else Begin
		Set @sSQLString=@sSQLString+"

		if @nComponentId is not null 
		Begin
			Select @sApplicationName = ISNULL((SELECT INTERNALNAME
			from COMPONENTS where COMPONENTID = @nComponentId),@sApplicationName)
		End

		if @nOffset is null
		Begin
			select @nOffset=COLINTEGER
			from SITECONTROL
			where CONTROLID='Log Time Offset'
		End

		Set @dtCurrentDate=dateadd(mi,isnull(@nOffset,0),getdate())"
	End
	
	If @psTable in ('CASES','CASEBUDGET','CASECHECKLIST','CASEIMAGE','CASELOCATION','CASEEVENT','CASEEVENTTEXT','CASENAME','CASETEXT','PROPERTY','RELATEDCASE',
			'OFFICIALNUMBERS','NAMEINSTRUCTIONS','ALERT','CRMCASESTATUSHISTORY','OPPORTUNITY','JOURNAL','CLASSFIRSTUSE','DESIGNELEMENT','TABLEATTRIBUTES')
	Begin
		------------------------------------
		-- For the main Case related tables,
		-- update or insert the CASEVENT for
		-- EventNo -14 using todays date.
		------------------------------------
		If @psTable='TABLEATTRIBUTES'
			Set @sSQLString=@sSQLString+"
			Update CASEEVENT
			set 	EVENTDATE=convert(varchar, @dtCurrentDate, 112), 
				OCCURREDFLAG=1,
				LOGUSERID=SYSTEM_USER,
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName
			from inserted i
			join CASEEVENT T1 on (T1.CASEID=cast(i.GENERICKEY as numeric)
					  and T1.EVENTNO=-14 
					  and T1.CYCLE=1)
			where(T1.EVENTDATE<>convert(varchar, @dtCurrentDate, 112) OR T1.OCCURREDFLAG<>1)
			and i.PARENTTABLE='CASES'
			and isnumeric(i.GENERICKEY)=1"
		Else
			Set @sSQLString=@sSQLString+"
			Update CASEEVENT
			set 	EVENTDATE=convert(varchar, @dtCurrentDate, 112), 
				OCCURREDFLAG=1,
				LOGUSERID=SYSTEM_USER,
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName
			from inserted i
			join CASEEVENT T1 on (T1.CASEID=i.CASEID and T1.EVENTNO=-14 and T1.CYCLE=1)
			where(T1.EVENTDATE<>convert(varchar, @dtCurrentDate, 112) OR T1.OCCURREDFLAG<>1)"
		
		If @psTable='CASEEVENT'
			Set @sSQLString=@sSQLString+CHAR(10)+
			"		and i.EVENTNO<>-14"
		
		If @psTable='TABLEATTRIBUTES'
			Set @sSQLString=@sSQLString+"
			
			insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGOFFICEID, LOGAPPLICATION)
			select distinct cast(i.GENERICKEY as numeric), -14, 1, convert(varchar, @dtCurrentDate, 112), 1, SYSTEM_USER, @nIdentityId, @nSessionTransNo, @dtCurrentDate, @nOfficeId, @sApplicationName 
			from inserted i
			join CASES C on (C.CASEID=cast(i.GENERICKEY as numeric))
			left join CASEEVENT T1 on (T1.CASEID=C.CASEID and T1.EVENTNO=-14 and T1.CYCLE=1)
			where T1.CASEID is null
			and i.PARENTTABLE='CASES'
			and isnumeric(i.GENERICKEY)=1"
		Else
			Set @sSQLString=@sSQLString+"
			
			insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGOFFICEID, LOGAPPLICATION)
			select distinct i.CASEID, -14, 1, convert(varchar, @dtCurrentDate, 112), 1, SYSTEM_USER, @nIdentityId, @nSessionTransNo, @dtCurrentDate, @nOfficeId, @sApplicationName 
			from inserted i
			join CASES C on (C.CASEID=i.CASEID)
			left join CASEEVENT T1 on (T1.CASEID=i.CASEID and T1.EVENTNO=-14 and T1.CYCLE=1)
			where T1.CASEID is null"
		
		If @psTable='CASEEVENT'
			Set @sSQLString=@sSQLString+CHAR(10)+
			"		and i.EVENTNO<>-14"
	End

	If @sTIDColumnList is null
	Begin
		-- No translations required so TID does not need to be determined.
		If @bTableHasText=1
		Begin
			-- If table has TEXT column then an INSTEAD OF trigger is used so
			-- we need to finish the UPDATE along with the audit column details

			Set @sSQLString=@sSQLString+" 
				-- Apply the UPDATE of all columns and also audit details
				Update "+@psTable+"
				set"

			-- SQA16410
			-- Special code for the ALERT date to clear out the ALERTDATE if the DUEDATE
			-- is modified. When Policing is asked to calculate the ALERTDATE it recognises
			-- an empty field and forces a reminder to be sent if the first reminder should
			-- have already been sent.
			If @psTable='ALERT'
				Set @sSQLString=@sSQLString+char(9)+"ALERTDATE=CASE WHEN(i.DUEDATE<>d.DUEDATE and i.TRIGGEREVENTNO is null) THEN NULL ELSE i.ALERTDATE END,"
		
			Select @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+C.Name+"="+CASE WHEN(C.Name='EVENTDATE') THEN "convert(nvarchar,i.EVENTDATE,112)" ELSE "i."+C.Name END+","
			from @tbColumns C
			where C.KeyNo is null
			and C.IsIdentity=0
			and C.IsRowGuid=0
			and C.Name not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGOFFICEID','LOGAPPLICATION')
			order by C.Position
			
			Set @sSQLString=@sSQLString+"
				LOGUSERID=" +
				case when @bUsernameOnly = 1
					then "dbo.fn_SystemUser()"
					else "SYSTEM_USER"
				end + ",
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
				from inserted i
				join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")"

			-- SQA16410
			If @psTable='ALERT'
				Set @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+"join deleted d on (d.EMPLOYEENO=i.EMPLOYEENO and d.ALERTSEQ=i.ALERTSEQ)"
		End
		Else Begin
			-- If table does not have TEXT column then an AFTER trigger is used
			-- so the inserted row must be updated with the additional audit details
			Set @sSQLString=@sSQLString+"

			Update "+@psTable+"
			set"

			-- SQA16410
			-- Special code for the ALERT date to clear out the ALERTDATE if the DUEDATE
			-- is modified. When Policing is asked to calculate the ALERTDATE it recognises
			-- an empty field and forces a reminder to be sent if the first reminder should
			-- have already been sent.
			If @psTable='ALERT'
				Set @sSQLString=@sSQLString+char(9)+"ALERTDATE=CASE WHEN(i.DUEDATE<>d.DUEDATE and i.TRIGGEREVENTNO is null) THEN NULL ELSE i.ALERTDATE END,"

			Set @sSQLString=@sSQLString+"
			 	LOGUSERID=" +
				case when @bUsernameOnly = 1
					then "dbo.fn_SystemUser()"
					else "SYSTEM_USER"
				end + ",
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
			from inserted i
			join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")"

			-- SQA16410
			If @psTable='ALERT'
				Set @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+"join deleted d on (d.EMPLOYEENO=i.EMPLOYEENO and d.ALERTSEQ=i.ALERTSEQ)"
		End
	End
	-- Translations exist
	Else Begin
	  If @bTableHasText=0
	  Begin
		-- If the table does not have a TEXT column then an AFTER trigger is being generated
		Set @sSQLString=@sSQLString+"

		If not exists(select 1 from TRANSLATIONSOURCE where TABLENAME='"+@psTable+"' and INUSE=1)
		Begin
			-- Just the audit columns need updating if no translations are required
			Update "+@psTable+"
			set 	LOGUSERID=" +
				case when @bUsernameOnly = 1
					then "dbo.fn_SystemUser()"
					else "SYSTEM_USER"
				end + ",
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
			from inserted i
			join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")
		End
		Else Begin"
					
	  End
	  Else Begin
		-- Text column exists so an INSTEAD of trigger has been generated
		Set @sSQLString=@sSQLString+"

		If not exists(select 1 from TRANSLATIONSOURCE where TABLENAME='"+@psTable+"' and INUSE=1)
		Begin
			-- Translations do not need to be generated

			-- Apply the UPDATE of all columns and also audit details
			Update "+@psTable+"
			set"
		
			Select @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+C.Name+"=i."+C.Name+","
			from @tbColumns C
			where C.KeyNo is null
			and C.IsIdentity=0
			and C.IsRowGuid=0
			and C.Name not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGOFFICEID','LOGAPPLICATION')
			order by C.Position
		
		Set @sSQLString=@sSQLString+" 
			LOGUSERID=" +
			case when @bUsernameOnly = 1
				then "dbo.fn_SystemUser()"
				else "SYSTEM_USER"
			end + ",
			LOGIDENTITYID=@nIdentityId,
			LOGTRANSACTIONNO=@nSessionTransNo,
			LOGDATETIMESTAMP=@dtCurrentDate,
			LOGOFFICEID=@nOfficeId,
			LOGAPPLICATION=@sApplicationName 
			from inserted i
			join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")
		End
		Else Begin"
	  End

	  Set @sSQLString=@sSQLString+"
			-- variable for number of new TID rows to insert
			declare @nNewTID	int
			declare	@nStartTID	int
		
			-- declare a variable to save the last inserted TID value
			declare @nMaxTID	int
		
			-- declare a table variable to hold the detail of each row being inserted
			-- that requires a TID and load it
			declare @tbROWS table (
				ROWNUMBER		int identity(1,1),"

	  -- Include the columns of the primary key into the table variable
	  Select @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+char(9)+C.Name+char(9)+char(9)+C.DataType+
		--CASE WHEN(C.Type in ('char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext'))
		--	THEN ' collate database_default'
		--END +
		','
	  from @tbColumns C
	  where C.Position<=@nLastKeyPos
	  and C.Name not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGOFFICEID','LOGAPPLICATION')
	  order by C.Position

	  Set @sSQLString=@sSQLString+"
				TIDCOLUMN		nvarchar(30) collate database_default,
				TRANSLATIONSOURCEID	int)

			-- NEW columns to be translated
			-- Columns flagged for translation that have a value but do 
			-- not have a TID value are to generate a TID value"

	  If upper(@psTable)='NAMETEXT'
	  Begin
		Set @sSQLString=@sSQLString+"

			insert into @tbROWS(NAMENO,TEXTTYPE, TIDCOLUMN, TRANSLATIONSOURCEID)
			select i.NAMENO,i.TEXTTYPE, TS.TIDCOLUMN, TS.TRANSLATIONSOURCEID
			from inserted i
			join TRANSLATIONSOURCE TS	on (TS.TABLENAME='NAMETEXT'
							and TS.TIDCOLUMN='TEXT_TID'
							and TS.INUSE    =1)
			where i.TEXT_TID is null"
	  End
	  Else Begin
		Set @sSQLString=@sSQLString+"

			insert into @tbROWS("+@sKeyColumns+", TIDCOLUMN, TRANSLATIONSOURCEID)"
	
		select @sSQLString=@sSQLString+"
			select i."+replace(@sKeyColumns,',',',i.')+", TS.TIDCOLUMN, TS.TRANSLATIONSOURCEID
			from inserted i
			join TRANSLATIONSOURCE TS	on (TS.TABLENAME='"+@psTable+"'
							and TS.TIDCOLUMN='"+C.TIDColumn+"'
							and TS.INUSE    =1)
			where i."+C.Name+" is not null
			and   i."+C.TIDColumn+" is null"+
		CASE WHEN((select count(*) from @tbColumns C1 where C1.Position>C.Position and C1.TIDColumn is not null)>0)
			THEN "		
			union"
		END
		from @tbColumns C
		where C.TIDColumn is not null
		order by C.Position
	  End

	  set @sSQLString=@sSQLString+"

			Set @nNewTID=@@Rowcount

			-- Now load a TRANSLATEDITEMS row for each TID to be generated 
			-- The TID will be generated automatically from the Identity column
			If @nNewTID>0
			Begin
				insert into TRANSLATEDITEMS(TRANSLATIONSOURCEID)
				select TRANSLATIONSOURCEID
				from @tbROWS
		
				-- Get the value of the last identity column value inserted into TRANSLATEDITEMS
				-- table.  This is required so that we can determine a unique TID value for each
				-- column that has had a TRANSLATEDITEMS row insert when inserting the "+@psTable+" table 
				Select @nMaxTID=SCOPE_IDENTITY()
				Select @nStartTID = @nMaxTID - @nNewTID
			End"

	  If @bTableHasText=1
	  Begin 
		set @sSQLString=@sSQLString+"
			If 1=0"
	
		select @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+"OR UPDATE("+C.Name+")"
		from @tbColumns C
		where C.TIDColumn is not null
		order by C.Position
	
		set @sSQLString=@sSQLString+"
			Begin
				-- Finally apply the UPDATE to the "+@psTable+" table
				Update "+@psTable+"
				set"
	
		Select @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+char(9)+C.Name+"="+
			CASE WHEN(C.Name like '%\_TID' escape '\' and C1.Name is not null) 
				THEN "
					CASE	WHEN(i."+C1.Name+" is null"+
						CASE WHEN(C1.RelatedColumn is not null) THEN " and i."+C1.RelatedColumn+" is null" END+
									") THEN NULL
					    	WHEN(i."+C.Name+" is null)
						  THEN (select @nStartTID+t.ROWNUMBER from @tbROWS t where "+@sKeyJoins+" and t.TIDCOLUMN='"+C.Name+"')
						ELSE i."+C.Name+"
					END"
				ELSE "i."+C.Name
			END+","
		from @tbColumns C
		-- If this is a TID column then get the associated column being
		-- translated.  Only return the first associated column if the TID
		-- column has been used more than once
		left join @tbColumns C1	on (C1.Position=(select min(C2.Position)
							 from @tbColumns C2
							 where C2.TIDColumn=C.Name))
		where C.KeyNo is null
		and C.IsIdentity=0
		and C.IsRowGuid=0
		and C.Name not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGOFFICEID','LOGAPPLICATION')
		order by C.Position
	
		Set @sSQLString=@sSQLString+"
				LOGUSERID=" +
				case when @bUsernameOnly = 1
					then "dbo.fn_SystemUser()"
					else "SYSTEM_USER"
				end + ",
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
				from inserted i
				join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")"
	  End
	  Else If upper(@psTable)='NAMETEXT'
	  Begin
		Set @sSQLString=@sSQLString+"
			If 1=0"
	
		select @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+"OR UPDATE("+C.Name+")"
		from @tbColumns C
		where C.TIDColumn is not null
		order by C.Position
	
		Set @sSQLString=@sSQLString+"
			Begin
				-- Apply the UPDATE of TID column to the "+@psTable+" table
				Update NAMETEXT
				set
				TEXT_TID=	CASE	WHEN(i.TEXT_TID is null)
							  THEN (select @nStartTID+t.ROWNUMBER from @tbROWS t where t.NAMENO=i.NAMENO and t.TEXTTYPE=i.TEXTTYPE and t.TIDCOLUMN='TEXT_TID')
							ELSE i.TEXT_TID
						END,
				LOGUSERID=" +
				case when @bUsernameOnly = 1
					then "dbo.fn_SystemUser()"
					else "SYSTEM_USER"
				end + ",
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 	
				from inserted i
				join NAMETEXT T1 on (T1.NAMENO=i.NAMENO and T1.TEXTTYPE=i.TEXTTYPE)"
	  End
	  Else Begin
		Set @sSQLString=@sSQLString+"
			If 1=0"
	
		select @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+"OR UPDATE("+C.Name+")"
		from @tbColumns C
		where C.TIDColumn is not null
		order by C.Position
		
		Set @sSQLString=@sSQLString+"
			Begin
				-- Apply the UPDATE of TID columns to the "+@psTable+" table
				Update "+@psTable+"
				set"
	
		Select @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+char(9)+C.Name+"="+
			CASE WHEN(C.Name like '%\_TID' escape '\' and C1.Name is not null) 
				THEN "
					CASE	WHEN(i."+C1.Name+" is null"+
						CASE WHEN(C1.RelatedColumn is not null) THEN " and i."+C1.RelatedColumn+" is null" END+
									") THEN NULL
					    	WHEN(i."+C.Name+" is null)
						  THEN (select @nStartTID+t.ROWNUMBER from @tbROWS t where "+@sKeyJoins+" and t.TIDCOLUMN='"+C.Name+"')
						ELSE i."+C.Name+"
					END"
				ELSE "i."+C.Name
			END+","
		from @tbColumns C
		-- If this is a TID column then get the associated column being
		-- translated.  Only return the first associated column if the TID
		-- column has been used more than once
		left join @tbColumns C1	on (C1.Position=(select min(C2.Position)
							 from @tbColumns C2
							 where C2.TIDColumn=C.Name))
		where C.Name like '%\_TID' escape '\'
		and C.IsIdentity=0
		and C.IsRowGuid=0
		order by C.Position
	
		Set @sSQLString=@sSQLString+"
				LOGUSERID=" +
				case when @bUsernameOnly = 1
					then "dbo.fn_SystemUser()"
					else "SYSTEM_USER"
				end + ",
				LOGIDENTITYID=@nIdentityId,
				LOGTRANSACTIONNO=@nSessionTransNo,
				LOGDATETIMESTAMP=@dtCurrentDate,
				LOGOFFICEID=@nOfficeId,
				LOGAPPLICATION=@sApplicationName 
				from inserted i
				join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")"
	  End

	  Set @sSQLString=@sSQLString+"
	
				-- TRANSLATION TEXT to be flagged for update
				-- If the text has been changed and the TID exists then set the HASSOURCECHANGED
				-- flag on to indicate that the translation requires review"
	
	  If upper(@psTable)='NAMETEXT'
	  Begin
		Select @sSQLString=@sSQLString+"

				Update TRANSLATEDTEXT
				set HASSOURCECHANGED=1
				from inserted i
				join TRANSLATEDTEXT TT on (TT.TID=i."+C.TIDColumn+")"
		From  @tbColumns C
		where C.TIDColumn is not null
		order by C.Position
	  End
	  Else Begin
		Set @sSQLString=@sSQLString+"
	
				-- TRANSLATIONS and TID to be REMOVED
				-- If the text has been set to NULL but the TID exists then the translation is
				-- to be removed."
	
		select @sSQLString=@sSQLString+"
				If UPDATE("+C.Name+")
				Begin
					delete TRANSLATEDITEMS
					from inserted i
					join TRANSLATEDITEMS TI	on (TI.TID=i."+C.TIDColumn+")
					where i."+C.Name+" is null"+
					CASE WHEN(C.RelatedColumn is not null) 
						THEN char(10)+char(9)+char(9)+"and i."+C.RelatedColumn+" is null" 
					END+"
			
					update TRANSLATEDTEXT
					set HASSOURCECHANGED=1
					from inserted i
					join deleted t	on ("+@sKeyJoins+")
					join TRANSLATEDTEXT TT	on (TT.TID=i."+C.TIDColumn+")
					where "+
					CASE WHEN(C.Type like '%text')
						THEN "dbo.fn_IsNtextEqual(i."+C.Name+",t."+C.Name+")=0"
						ELSE "i."+C.Name+"<>t."+C.Name
					END+
					CASE WHEN(C.RelatedColumn is not null)
						THEN char(10)+char(9)+char(9)+"or (t."+C.Name+" is not null and i."+C.Name+" is null and i."+C.RelatedColumn+" is not null)"
					END+"
				End
			"
		from @tbColumns C
		where C.TIDColumn is not null
		order by C.Position
	  End

	  Set @sSQLString=@sSQLString+char(10)+
			+char(9)+"		End"+char(10)+
			+char(9)+"		Else"+char(10)+
			+char(9)+"			Update "+@psTable+char(10)+
			+char(9)+"			set"

	  Select @sSQLString=@sSQLString+char(10)+char(9)+char(9)+char(9)+char(9)+C.Name+"=i."+C.Name+","
	  from @tbColumns C
	  where C.KeyNo is null
	  and C.IsIdentity=0
	  and C.IsRowGuid=0
	  and C.Name not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGOFFICEID','LOGAPPLICATION')
	  order by C.Position

	  Set @sSQLString=@sSQLString+char(10)+
			+char(9)+"			LOGUSERID=" +
							case when @bUsernameOnly = 1
								then "dbo.fn_SystemUser()"
								else "SYSTEM_USER"
							end + ","+char(10)+
			+char(9)+"			LOGIDENTITYID=@nIdentityId,"+char(10)+
			+char(9)+"			LOGTRANSACTIONNO=@nSessionTransNo,"+char(10)+
			+char(9)+"			LOGDATETIMESTAMP=@dtCurrentDate,"+char(10)+
			+char(9)+"			LOGOFFICEID=@nOfficeId,"+char(10)+
			+char(9)+"			LOGAPPLICATION=@sApplicationName "+char(10)+
			+char(9)+"			from inserted i"+char(10)+
			+char(9)+"			join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")"+char(10)+
			+char(9)+"	End"
	End -- Translation Exists

	If @bLogRequired=1
	Begin
		Set @sSQLString=@sSQLString+"
		
		insert into "+CASE WHEN(@sLoggingDB<>@sInproDB) THEN @sLoggingDB+".." END + @psTable + "_iLOG
			(LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGACTION, LOGOFFICEID, LOGAPPLICATION,
			 " + @sLogColumnList + ")
		select " +
		case when @bUsernameOnly = 1
			then "dbo.fn_SystemUser()"
			else "SYSTEM_USER"
		end + ",@nIdentityId,@nSessionTransNo,@dtCurrentDate,'U',@nOfficeId,@sApplicationName ,"

		Set @sSQLString=@sSQLString+char(10)+char(9)+char(9)+@sLogColumnListEventDate+char(10)+char(9)+char(9)+"from deleted"
	End

	Set @sSQLString=@sSQLString+"
	End"

	if @pbPrintSQL = 1
	begin
		select	@sSqlMsg = 'select @sSQLString as tU_' + @psTable + '_Audit'
		exec sp_executesql @sSqlMsg, N'@sSQLString nvarchar(max)', @sSQLString
	end

	exec	@ErrorCode = sp_executesql @sSQLString

	If @pbPrintLog=1
	and @ErrorCode=0
		raiserror('Update trigger created      for tU_%s_Audit',0,1,@psTable) with nowait
End

if  @bLogRequired=1
and @bTableHasChanged=1
and @ErrorCode=0
Begin
	------------------------------------------------------
	-- Transfer contents of old log table to new log table
	------------------------------------------------------	
	if @sOldColumnList is not null
	and @ErrorCode=0
	begin
		if @sInproDB = @sLoggingDB
			set @sSQLString = ""
		else	
			set @sSQLString = "use " + @sLoggingDB + char(10)

		set @sSQLString = @sSQLString + "declare @sIDcol sysname, @bIdentIns bit" + char(10) +
						"select	@sIDcol = c.name" + char(10) +
						"from	sys.columns c" + char(10) +
						"where	c.object_id = object_id(N'dbo." + @psTable + "_iLOG')" + char(10) +
						"and	c.is_identity = 1" + char(10) + 
						"select @bIdentIns = case when @@rowcount > 0 then 1 else 0 end" + char(10) +
						"if	@bIdentIns = 1" + char(10) +
						"	select	@bIdentIns = case when charindex(@sIDcol, '" + @sOldColumnList + "') > 0 then 1 else 0 end" + char(10)

		set @sSQLString = @sSQLString + "if @bIdentIns = 1"+char(10)+
						"	set identity_insert " + @psTable + "_iLOG ON" + char(10)

		set @sSQLString = @sSQLString + "insert into " + @psTable +"_iLOG(" + char(10) + "	" +@sOldColumnList+")"+char(10)+
						"select	"+@sOldColumnList+char(10)+
						"from " + @psTable +"_iLOGBAK"

		set @sSQLString = @sSQLString + char(10) + "if @bIdentIns = 1"+char(10)+
							   "	set identity_insert " + @psTable + "_iLOG OFF"

		if @sInproDB <> @sLoggingDB
			set	@sSQLString = @sSQLString + char(10) + "use " + @sInproDB

		raiserror('Start with copy data       from %s_iLOGBAK to %s_iLOG',0,1,@psTable,@psTable) with nowait

		exec @ErrorCode=sp_executesql @sSQLString

		-- If copy successful then drop the backup of the log
		If @ErrorCode=0
		Begin
			Set @sSQLString="drop table "+ @sLoggingDB + ".." + @psTable +"_iLOGBAK"
	
			exec @ErrorCode=sp_executesql @sSQLString
		End
	End
End

if  @bLogRequired=1
and @ErrorCode=0
Begin	
	----------------------------------------------------------------
	-- generate an index to mirror the primary key of the base table
	----------------------------------------------------------------	
	If @ErrorCode=0
	begin
		Set @sSQLString=null
	
		select  @sSQLString=isnull(nullif(@sSQLString+','+char(10),','+char(10)),'')+char(9)+char(9)+COLUMN_NAME+char(9)+'ASC'
		from INFORMATION_SCHEMA.TABLE_CONSTRAINTS C 
			-- Find constraints that point to the parent Primary Key
			-- Now get the name of the foreign key column
		join INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU on (CU.CONSTRAINT_NAME=C.CONSTRAINT_NAME
								   and CU.TABLE_NAME=C.TABLE_NAME)
		where C.TABLE_NAME=@psTable
		and C.CONSTRAINT_TYPE='PRIMARY KEY'
		
		--------------------------------------------------
		-- Check the first column of the Index about to be 
		-- generated to determine if an additional index
		-- is required.
		--------------------------------------------------
		If @sSQLString not like 'CASEID%'
		and exists(select 1 from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=@psTable and COLUMN_NAME='CASEID')
			Set @bNeedCaseIdIndex=1
		
		If @sSQLString not like 'NAMENO%'
		and exists(select 1 from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=@psTable and COLUMN_NAME='NAMENO')
			Set @bNeedNameNoIndex=1
		
		If @sSQLString not like 'EMPLOYEENO%'
		and exists(select 1 from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=@psTable and COLUMN_NAME='EMPLOYEENO')
			Set @bNeedEmployeeNoIndex=1
	
		If @sSQLString is not null
		Begin

			-- SQA15655
			-- Suffix the primary key colums with LOGDATETIMESTAMP to improve performance
			-- of the Audit Enquiry

			set @sSQLString=
			"Use "+@sLoggingDB+char(10)+
			"if not exists(select 1"+char(10)+
			"	from sysobjects O"+char(10)+
			"	join sysindexes I on (I.id=O.id) "+char(10)+
			"	where O.type = 'U'"+char(10)+
			"	and O.name = '"+@psTable+"_iLOG'"+char(10)+
			"	and I.name = 'XIE1"+@psTable+"_iLOG')"+char(10)+
			"begin"+char(10)+
			"	CREATE INDEX XIE1"+@psTable+"_iLOG ON "+@psTable+"_iLOG ("+char(10)+@sSQLString+",LOGDATETIMESTAMP)"
		
			If @pbPrintLog=1
			Begin
				Set @sSQLString=@sSQLString+char(10)+
				"	raiserror('Index to mirror Primary Key created for XIE1"+@psTable+"_iLOG',0,1) with nowait"
			End

			Set @sSQLString=@sSQLString+char(10)+"End"+char(10)+"Use "+@sInproDB

			exec @ErrorCode=sp_executesql @sSQLString
		End
	End
	
	------------------------------------------------
	-- generate an index against the Logging details
	------------------------------------------------
	If @ErrorCode=0
	Begin
		set @sSQLString=
		"Use "+@sLoggingDB+char(10)+
		"if not exists(select 1"+char(10)+
		"	from sysobjects O"+char(10)+
		"	join sysindexes I on (I.id=O.id) "+char(10)+
		"	where O.type = 'U'"+char(10)+
		"	and O.name = '"+@psTable+"_iLOG'"+char(10)+
		"	and I.name = 'XIE2"+@psTable+"_iLOG')"+char(10)+
		"begin"+char(10)+
		"	CREATE INDEX XIE2"+@psTable+"_iLOG ON "+@psTable+"_iLOG ("+char(10)+"LOGDATETIMESTAMP ASC, LOGIDENTITYID ASC, LOGUSERID ASC)"

		If @psTable='POLICING'
			Set @sSQLString=@sSQLString+char(10)+"	INCLUDE ([LOGACTION])"
	
		If @pbPrintLog=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+
			"	raiserror('Index created for XIE2"+@psTable+"_iLOG',0,1) with nowait"
		End

		Set @sSQLString=@sSQLString+char(10)+"End"+char(10)+"Use "+@sInproDB

		exec @ErrorCode=sp_executesql @sSQLString
	End
	
	------------------------------------------------
	-- generate an index against the CASEID
	------------------------------------------------
	If @ErrorCode=0
	and @bNeedCaseIdIndex=1
	Begin
		set @sSQLString=
		"Use "+@sLoggingDB+char(10)+
		"if not exists(select 1"+char(10)+
		"	from sysobjects O"+char(10)+
		"	join sysindexes I on (I.id=O.id) "+char(10)+
		"	where O.type = 'U'"+char(10)+
		"	and O.name = '"+@psTable+"_iLOG'"+char(10)+
		"	and I.name = 'XIE3"+@psTable+"_iLOG')"+char(10)+
		"begin"+char(10)+
		"	CREATE INDEX XIE3"+@psTable+"_iLOG ON "+@psTable+"_iLOG ("+char(10)+"CASEID ASC)"
	
		If @pbPrintLog=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+
			"	raiserror('Index created for XIE3"+@psTable+"_iLOG on CASEID',0,1) with nowait"
		End

		Set @sSQLString=@sSQLString+char(10)+"End"+char(10)+"Use "+@sInproDB

		exec @ErrorCode=sp_executesql @sSQLString
		
	
		------------------------------------------------
		-- generate an index against the Logging details
		------------------------------------------------
		If @ErrorCode=0
		Begin
			set @sSQLString=
			"Use "+@sLoggingDB+char(10)+
			"if not exists(select 1"+char(10)+
			"	from sysobjects O"+char(10)+
			"	join sysindexes I on (I.id=O.id) "+char(10)+
			"	where O.type = 'U'"+char(10)+
			"	and O.name = '"+@psTable+"_iLOG'"+char(10)+
			"	and I.name = 'XIE6"+@psTable+"_iLOG')"+char(10)+
			"begin"+char(10)+
			"	CREATE INDEX XIE6"+@psTable+"_iLOG ON "+@psTable+"_iLOG ("+char(10)+"LOGTRANSACTIONNO ASC, LOGACTION ASC, LOGDATETIMESTAMP ASC, CASEID ASC)"
		
			If @pbPrintLog=1
			Begin
				Set @sSQLString=@sSQLString+char(10)+
				"	raiserror('Index created for XIE6"+@psTable+"_iLOG',0,1) with nowait"
			End

			Set @sSQLString=@sSQLString+char(10)+"End"+char(10)+"Use "+@sInproDB

			exec @ErrorCode=sp_executesql @sSQLString
		End
	End
	
	------------------------------------------------
	-- generate an index against the NAMENO
	------------------------------------------------
	If @ErrorCode=0
	and @bNeedNameNoIndex=1
	Begin
		set @sSQLString=
		"Use "+@sLoggingDB+char(10)+
		"if not exists(select 1"+char(10)+
		"	from sysobjects O"+char(10)+
		"	join sysindexes I on (I.id=O.id) "+char(10)+
		"	where O.type = 'U'"+char(10)+
		"	and O.name = '"+@psTable+"_iLOG'"+char(10)+
		"	and I.name = 'XIE4"+@psTable+"_iLOG')"+char(10)+
		"begin"+char(10)+
		"	CREATE INDEX XIE4"+@psTable+"_iLOG ON "+@psTable+"_iLOG ("+char(10)+"NAMENO ASC)"
	
		If @pbPrintLog=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+
			"	raiserror('Index created for XIE4"+@psTable+"_iLOG on NAMENO',0,1) with nowait"
		End

		Set @sSQLString=@sSQLString+char(10)+"End"+char(10)+"Use "+@sInproDB

		exec @ErrorCode=sp_executesql @sSQLString
	End
	
	------------------------------------------------
	-- generate an index against the EMPLOYEENO
	------------------------------------------------
	If @ErrorCode=0
	and @bNeedEmployeeNoIndex=1
	Begin
		set @sSQLString=
		"Use "+@sLoggingDB+char(10)+
		"if not exists(select 1"+char(10)+
		"	from sysobjects O"+char(10)+
		"	join sysindexes I on (I.id=O.id) "+char(10)+
		"	where O.type = 'U'"+char(10)+
		"	and O.name = '"+@psTable+"_iLOG'"+char(10)+
		"	and I.name = 'XIE5"+@psTable+"_iLOG')"+char(10)+
		"begin"+char(10)+
		"	CREATE INDEX XIE5"+@psTable+"_iLOG ON "+@psTable+"_iLOG ("+char(10)+"EMPLOYEENO ASC)"
	
		If @pbPrintLog=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+
			"	raiserror('Index created for XIE5"+@psTable+"_iLOG on EMPLOYEENO',0,1) with nowait"
		End

		Set @sSQLString=@sSQLString+char(10)+"End"+char(10)+"Use "+@sInproDB

		exec @ErrorCode=sp_executesql @sSQLString
	End
	
	if @ErrorCode = 0
	and @bUseLogSequence = 1
	begin		
		-------------------------------------------------------
		-- Check if a Primary Key has been created against
		-- the generated audit log table.  If not then generate
		-- it using the LOGSEQUENCE column.
		-------------------------------------------------------	
		set @bIndexExists = 1

		set @sSQLString="Use "+@sLoggingDB+char(10)+
		"select	@bIndexExists=COUNT(*)
		from	sys.tables t
		inner	join	sys.indexes i
			on	i.object_id = t.object_id
			and	(i.is_primary_key = 1 or i.name like 'XPK%')
		where	t.name = '"+@psTable+"_iLOG'"	--RFC45370
		exec @ErrorCode = sp_executesql @sSQLString,
					N'@bIndexExists	bit		OUTPUT',
					  @bIndexExists=@bIndexExists	OUTPUT

		if @ErrorCode = 0
		and @bIndexExists = 0
		begin
			set @sSQLString = 'Use '+@sLoggingDB+char(10)+
					'ALTER TABLE ' + @psTable + '_iLOG WITH NOCHECK ADD CONSTRAINT XPK' + @psTable + '_iLOG'+char(10)+
					'PRIMARY KEY CLUSTERED (LOGSEQUENCE)'+char(10)+
					'Use '+@sInproDB
			exec @ErrorCode=sp_executesql @sSQLString

			If  @ErrorCode=0
			and @pbPrintLog=1
			Begin
				raiserror('Primary key created for XPK%s_iLOG',0,1,@psTable) with nowait
			End
		end
	End
	
	If  @ErrorCode=0
	and @pbPrintLog=1
	Begin
		raiserror('Logging generation complete for %s',0,1,@psTable) with nowait
	End
End

Return @ErrorCode
go

grant execute on dbo.ipu_UtilGenerateAuditTriggers  to public
go