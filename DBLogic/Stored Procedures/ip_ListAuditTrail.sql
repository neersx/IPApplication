-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListAuditTrail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListAuditTrail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListAuditTrail.'
	Drop procedure [dbo].[ip_ListAuditTrail]
End
Print '**** Creating Stored Procedure dbo.ip_ListAuditTrail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_ListAuditTrail
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnSubjectArea		int		= null,
	@pnNameNo		int		= null,
	@pdtFromDate		datetime	= null,
	@pdtToDate		datetime	= null,
	@pbIncludeUpdates	bit		= 1,
	@pbIncludeDeletes	bit		= 1,
	@pbIncludeInserts	bit		= 1,
	@psFilterTable		nvarchar(50)	= null,
	@psFilterColumn		nvarchar(50)	= null,
	@psFilterColumnValue	nvarchar(4000)	= null,
	@psFilterKeyValue	nvarchar(50)	= null,
	@psColumnsToAudit	ntext,		-- XML list of columns to report on
	@psSortOrderColumn	nvarchar(50)	='DATECHANGED',
	@psSortOrderDirection	nchar(1)	='D',
	@pbPrintSQL		bit		= 0,	-- Set to 1 to dump our dynamic SQL statements
	@pdtSessionDate		datetime	= null, -- Filter on Session Date
	@pnSessionId		int		= null,	-- Filter on Session ID
	@pnDataSource		int		= null,	-- Filter on data source (nameno)
	@psBatchId		nvarchar(254)	= null	-- Filter on batch identifier
)
-- PROCEDURE:	ip_ListAuditTrail
-- VERSION :	38
-- DESCRIPTION:	Returns the audit trail information covering Inserts, Updates
--		and Deletes filtered by user supplied parameters. The "before"
--		and "after" versions of the data will be returned.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24-JUN-2005  MF		1	Procedure created
-- 31-JUL-2005	MF	8348	2	Add functionality to filter on a particular column
-- 02-AUG-2005	MF	11721	3	When a number of columns for one table are being reported
--					on then the generated SQL may exceed 4000 characters. 
--					Change the process so that each Column is processed separately
--					rather than in a UNION.
-- 04-AUG-2005	VL	11721	4	Change the @psColumnsToAudit parameter from nvarchar(4000) to ntext.
-- 09-SEP-2005	MF	11869	5	Expand codes in the result set to show their descriptions.
-- 04-OCT-2005	MF	11869	6	When the NAMENO is being expanded to show the NAME also show the NameCode.
-- 05-OCT-2005	MF	11939	7	Always report the primary key columns if the transaction is an Update.
-- 19-OCT-2005	MF	11978	8	If the Name being filtered on is not associated with a userid then
--					do not return any data.
-- 19-OCT-2005	MF	11979	9	The columns that have their output suppressed for the AFTER image in
--					an Update record need to also be returned as additional unsuppressed
--					columns to allow the client side software to sort on the column.
--					Reverse out 11939 as it was not implemented correctly.
-- 09-Nov-2005	MF	12045	10	Allow additional sort columns for UserId, Field and PrimaryKey
-- 29-Nov-2005	MF	12135	11	Increase the size of the column for holding the Table and Column names
-- 09-Oct-2006	MF	13560	12	Audit trail not returning data filtered by date.  Use fn_ConstructOperator
--					to format date fields to cater for Centura specific formatting problems.
-- 06-Dec-2006	MF	13968	13	Set the locking level to the lowest level for this read only procedure.
-- 10-Jan-2007	MF	13297	14	Allow additional filter criteria.
-- 17-Jan-2007	MF	13297	15	Return the LOGTRANSACTIONNO in the output.
-- 22-Jan-2007	MF	13297	16	Change of requirement.  Session Number to be replaced by Session Date and
--					Session ID.
-- 25-Jan-2007	MF	13723	17	Display workbench user that modified the date in the result.
-- 07-Mar-2007	MF	14522	18	SQL Error because @sSQLFrom variable was too small. Changed to nvarchar(4000).
-- 11-Apr-2007	MF	14675	19	For specific tables display all columns with data in them for UPDATES whereas
--					for most tables only display data that has changed.
-- 19-Apr-2007	MF	14701	20	Return the sender's batch identifier and the namecode and name of the sender.
-- 24-Apr-2007	Dev	14326	21	Striped out the domain name, which appears when using NT Authentication, 
--					before comparing username
-- 29-Jan-2008	MF	15884	22	Display all columns of DISCOUNT and MARGINPROFILERULE table. Extension of 14675.
-- 24-Feb-2008	MF	15999	23	Show full details for EXCHRATEVARIATION table. Extension of 14675.
-- 09-Apr-2008	MF	16222	24	Filtering by the name of the person who created the change is not 
--					working correctly due to a proble introduced in 14326.
-- 15-Apr-2008	MF	16244	25	Tables being filtered by the parent key are to remove any second reference to
--					that parent key.  This was previously resulting in more than one column being 
--					included in the filter resulting in no data being returned.
-- 18-Jul-2008	MF	16727	26	Truncation error when CRITERIA.DESCRIPTION exceeded 100 characters.
-- 12-Aug-2008	MF	16819	27	NameNo may have been updated so cannot use in Primary Key join on CASENAME when looking
--					for the After image of updated data. Fortunately the SEQUENCE is now unique within a NameType.
-- 14-Aug-2008	MF	16829	28	Description for Action and Relationship not appearing for AssociatedNames changes.
-- 01-Apr-2009	MF	17557	29	ADDRESS needs to be linked to the CASEID or NAMENO if their primary key has been provided.
-- 23 Jul 2009	MF	17833	30	If filtering by NAMENO and the ADDRESS table is included then add a join to NAMEADDRESS
--					so that only those ADDRESSes associated with the filtered NAMENO are reported.
-- 09 Sep 2009	MF	17973	30	Extend LOGINID to allow up to 50 characters.
-- 17 Sep 2009	MF	18070	31	Updates associated with Case tables (CASES, CASENAME, OPENACTION, CASEEVENT, RELATEDCASE, CASETEXT)
--					are to also return the CASEID row showing the IRN, even though the CASEID has not changed.
-- 02 Nov 2009	DL	18015	32	Show Name details for Name Mapping columns DATASOURCENAMENO, INPRONAMENO.
--					Show Extername name details for Name Mapping column EXTERNALNAMEID.
--					Exclude TELECOMMUNICATION details if Name Mapping column FAX is selected.
-- 01 Jul 2010	MF	18857	32	Truncation error occurring against EXTERNALNAMEID because the EXTERNAMECODE is longer than 
--					formatting was allowing.
-- 17 Jun 2011	MF	19700	33	Performance problem when displaying audit details from tables that are filtered by a CaseId where
--					the CaseId exists as a foreign key reference that is not in the Primary Key of the table being
--					reported on. This was impacted on tables such as ACTIVITYREQUEST, WORKINPROGRESS etc...  If the
--					column to be filtered on is not found in the primary key then we will drop back to a foreign
--					key column not used in the Primary Key.
-- 04 Aug 2015 DL	50808	34	Red Hand Error when running Audit Trail on a case.
--					Extend #TEMPLOG.LOGUSERID and #TEMPSORTEDRESULT.USERID from 30 to 50 characters to match LOGUSERID length.
-- 02 Nov 2015	vql	R53910	35	Adjust formatted names logic (DR-15543).
-- 24 Aug 2018	MF	74866	36	Return the OFFICE description where the OFFICE table is referenced.
-- 26 Aug 2018	MF	74866	37	Add MAINCONTACT as a code that should be translated to the underlying Name.
-- 28 Mar 2019	MF	DR-47778 38	Cater for the possibility that the Name being filtered on is associated with both a client/server login 
--					and a web user identity.

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

				-- Using VARCHAR deliberately to minimise the total table size.  We know that
				-- only single byte characters will be stored in LOGACTION and NAMEOFCOLUMN
Create table #TEMPLOG (		LOGDATETIMESTAMP	datetime	not null,
				LOGACTION		char(1)		collate database_default NOT NULL,
				LOGUSERID		nvarchar(50)	collate database_default NOT NULL,
				LOGIDENTITYID		int					 NULL,
				LOGPROGRAM		nvarchar(20)	collate database_default NULL,
				LOGTRANSACTIONNO	int					 NULL,
				NAMEOFTABLE		varchar(30)	collate database_default NOT NULL,
				NAMEOFCOLUMN		varchar(30)	collate database_default NOT NULL,
				CONTENTOFDATA		nvarchar(1809)	collate database_default NULL,
				CONTENTOFDATAAFTER	nvarchar(1809)	collate database_default NULL,
				CONTENTDESC		nvarchar(100)	collate database_default NULL,
				CONTENTDESCAFTER	nvarchar(100)	collate database_default NULL,
				PRIMARYKEY		nvarchar(100)	collate database_default NULL,
				ROWNUMBER		int		identity	
				)

Create table #TEMPSORTEDRESULT(	DATECHANGED		datetime	NULL,
				LOGACTION		char(1)		collate database_default NULL,
				TYPE			nvarchar(20)	collate database_default NULL,
				PROGRAM			nvarchar(20)	collate database_default NULL,
				USERID			nvarchar(50)	collate database_default NULL,
				LOGINID			nvarchar(50)	collate database_default NULL,
				STAFFNAME		nvarchar(50)	collate database_default NULL,
				FIELD			nvarchar(50)	collate database_default NULL,
				AUDITDATA		nvarchar(1809)	collate database_default NULL,
				PRIMARYKEY		nvarchar(100)	collate database_default NULL,
				BEFOREORAFTER		nvarchar(6)	collate database_default NULL,
				ROWNUMBER		int		NULL, 
				ORDERCOLUMN		nvarchar(1809)	collate database_default NULL,
				LOGTRANSNO		int		NULL,
				NEWORDER		int		identity
				)


declare @tbReportOn table (	COLUMNNUMBER		smallint	identity (1,1),
				TABLENAME		varchar(30)	collate database_default not null,
				COLUMNNAME		varchar(30)	collate database_default not null,
				PRIMARYKEYCOLUMN	varchar(30)	collate database_default null
				)

declare @tbPrimaryKey table (	TABLENAME		varchar(30)	collate database_default not null, 
				PRIMARYKEYCOLUMN	varchar(30)	collate database_default not null,
				PARENTFLAG		bit		not null
				)

declare	@ErrorCode		int
declare @idoc 			int

declare @nNoOfColumns		smallint
declare @nRowNumber		smallint

declare @sTableName		varchar(30)
declare @sCurrentTableName	varchar(30)
declare	@sColumnName		varchar(30)
declare @sKeyColumn		varchar(30)
declare @sDataType		nvarchar(20)
declare @sUsers			nvarchar(1000)
declare @sIdentity		nvarchar(1000)
declare @sSQLString		nvarchar(4000)
declare @sSQLFilter		nvarchar(4000)
declare @sSQLWhere		nvarchar(4000)
declare @sSQLFrom		nvarchar(4000)
declare @sSQLJoin		nvarchar(4000)
declare @sPrimaryKeyJoin	nvarchar(4000)
declare @sPrimaryKeyList	nvarchar(500)
declare @sOrderColumn		nvarchar(100)
declare @sOrderBy		nvarchar(100)
declare	@dtFilterDate		datetime
declare @bCaseKeyFilter		bit
declare	@bNameKeyFilter		bit
declare @bNameFilterFlag	bit


-- Initialise variables
Set @ErrorCode = 0

If  @ErrorCode = 0
and @psFilterColumn is not null
and @psFilterTable  is not null
Begin
	-- Get the datatype of the filter column
	Set @sSQLString="
	Select @sDataType=C.DATA_TYPE
	from INFORMATION_SCHEMA.COLUMNS C
	where C.TABLE_NAME=@psFilterTable
	and C.COLUMN_NAME =@psFilterColumn"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sDataType		nvarchar(20)	Output,
				  @psFilterTable	nvarchar(50),
				  @psFilterColumn	nvarchar(50)',
				  @sDataType	 =@sDataType		Output,
				  @psFilterTable =@psFilterTable,
				  @psFilterColumn=@psFilterColumn
End

If @ErrorCode = 0
Begin
	-- Construct the WHERE clause based on the parameters supplied

	Set @sSQLFilter= replace(
			"Where L1.LOGACTION in ("+
			CASE WHEN(@pbIncludeUpdates=1) THEN "'U'," END+
			CASE WHEN(@pbIncludeDeletes=1) THEN "'D'," END+
			CASE WHEN(@pbIncludeInserts=1) THEN "'I'" END+")",
			',)',')')	-- remove any superfluous comma

	If @pdtFromDate is not null
	or @pdtToDate   is not null
		Set @sSQLFilter=@sSQLFilter+char(10)+"and L1.LOGDATETIMESTAMP"+dbo.fn_ConstructOperator (7,'DT',@pdtFromDate,@pdtToDate,0)

	If  @psFilterColumn is not null
	and @psFilterTable is not null
	Begin
		If @pbIncludeUpdates=1
		Begin
			If @psFilterColumnValue is not null
			Begin
				If @sDataType='datetime'
				Begin
					Set @sSQLFilter=@sSQLFilter+char(10)+"and (L1."+@psFilterColumn+dbo.fn_ConstructOperator (0,'DT',@psFilterColumnValue,null,0)+" OR X."+@psFilterColumn+dbo.fn_ConstructOperator (0,'DT',@psFilterColumnValue,null,0)+")"
				End
				Else Begin
					Set @sSQLFilter=@sSQLFilter+char(10)+"and (L1."+@psFilterColumn+" LIKE '"+@psFilterColumnValue+"' OR X."+@psFilterColumn+" LIKE '"+@psFilterColumnValue+"')"
				End
			End
			Else Begin
				Set @sSQLFilter=@sSQLFilter+char(10)+"and L1."+@psFilterColumn+" is null"
			End
		End
		Else Begin
			If @psFilterColumnValue is not null
			Begin
				If @sDataType='datetime'
				Begin
					Set @sSQLFilter=@sSQLFilter+char(10)+"and L1."+@psFilterColumn+dbo.fn_ConstructOperator (0,'DT',@psFilterColumnValue,null,0)
				End
				Else Begin
					Set @sSQLFilter=@sSQLFilter+char(10)+"and L1."+@psFilterColumn+" LIKE '"+@psFilterColumnValue+"'"
				End
			End
			Else Begin
				Set @sSQLFilter=@sSQLFilter+char(10)+"and L1."+@psFilterColumn+" is null"
			End
		End
	End
	
	-- Determine the USERID from the NameNo provided
	-- Note that we plan to change logging to use IDENTITYID at some future time to 
	-- handle the Workbenches where only one USERID is actually used but individuals are identified 
	If @pnNameNo is not null
	Begin
		Select @sUsers=isnull(nullif(@sUsers+',',','),'')+"'"+U.USERID+"'"
		from USERIDENTITY UI
		join USERS U	on (U.USERID=UI.LOGINID)
		where UI.NAMENO=@pnNameNo

		Select @sIdentity=isnull(nullif(@sIdentity+',',','),'')+convert(nvarchar,UI.IDENTITYID)
		from USERIDENTITY UI
		where UI.NAMENO=@pnNameNo

		If @sUsers is not null
			--14326
			--Set @sSQLFilter=@sSQLFilter+char(10)+"and L1.LOGUSERID in ("+@sUsers+")"
			Set @sSQLFilter=@sSQLFilter+char(10)+"and (substring(L1.LOGUSERID, charindex('\',L1.LOGUSERID) + 1, len(L1.LOGUSERID)- charindex('\',L1.LOGUSERID)) in ("+@sUsers+")"
		Else If @sIdentity is null
			-- Block all rows if no User Id or Identity associated with the Name
			Set @sSQLFilter=@sSQLFilter+char(10)+"and L1.LOGUSERID <> L1.LOGUSERID"

		If @sIdentity is not null
			If @sUsers is not null
				Set @sSQLFilter=@sSQLFilter+char(10)+"OR L1.LOGIDENTITYID in ("+@sIdentity+") )"
			Else
				Set @sSQLFilter=@sSQLFilter+char(10)+"and L1.LOGIDENTITYID in ("+@sIdentity+")"
		Else if @sUsers is not null
			Set  @sSQLFilter=@sSQLFilter+')'
	End
End

If @ErrorCode = 0
Begin
	-- Get the table and column names to be reported on and load them
	-- into a table variable for ease of processing.

	exec sp_xml_preparedocument	@idoc OUTPUT, @psColumnsToAudit

	Insert into @tbReportOn (TABLENAME, COLUMNNAME)
	Select	distinct XML.TableName, XML.ColumnName
	from	OPENXML (@idoc, '//ip_ListAuditTrail/ColumnsToAudit/Table/Column',2)
	WITH (	TableName	nvarchar(30)	'../@Name/text()',
		ColumnName	nvarchar(30)	'text()'
	     )	XML
	where (XML.TableName=@psFilterTable or @psFilterTable is null)
	order by XML.TableName, XML.ColumnName
	
	Select	@ErrorCode=@@Error,
		@nNoOfColumns=@@Rowcount
	
	EXEC sp_xml_removedocument @idoc
End

-- If a Filter Key value has been provided then we know that this is for the Primary Key
-- of the parent.  The column of the parent table Primary Key will also appear in 
-- the Primary Key of each child however the column name may vary so we need to extract
-- it for each table to be reported on.
 
If (@psFilterKeyValue is not null or @pbIncludeUpdates=1)
and @pnSubjectArea    is not null
and @ErrorCode=0
Begin
	Insert into @tbPrimaryKey(TABLENAME, PRIMARYKEYCOLUMN, PARENTFLAG)
	select  T.TABLENAME,
		substring(CU1.COLUMN_NAME,1,30),
		0
	from SUBJECTAREA S
		-- Get the tables that are to be reported on
	cross join (select distinct TABLENAME from @tbReportOn) T
		-- Get the Primary Key of the parent table
	join INFORMATION_SCHEMA.TABLE_CONSTRAINTS C 		on (C.TABLE_NAME=S.PARENTTABLE
								and C.CONSTRAINT_TYPE='PRIMARY KEY')
		-- Find constraints that point to the parent Primary Key
	join INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC 	on (RC.UNIQUE_CONSTRAINT_NAME=C.CONSTRAINT_NAME)
		-- Find the foreign key constraints that point to the parent Primary Key
		-- for the tables that are to be reported on 
	join INFORMATION_SCHEMA.TABLE_CONSTRAINTS C1		on (C1.CONSTRAINT_TYPE='FOREIGN KEY'
								and C1.TABLE_NAME=T.TABLENAME
								and C1.CONSTRAINT_NAME=RC.CONSTRAINT_NAME)
		-- Now get the name of the foreign key column
	join INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU1 	on (CU1.CONSTRAINT_NAME=C1.CONSTRAINT_NAME)
		-- Ensure the Column of Parent primary key is a column of the Child Primary Key
	join INFORMATION_SCHEMA.TABLE_CONSTRAINTS C2		on (C2.CONSTRAINT_TYPE='PRIMARY KEY'
								and C2.TABLE_NAME=C1.TABLE_NAME)
	join INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU2 	on(CU2.CONSTRAINT_NAME=C2.CONSTRAINT_NAME
								and CU2.COLUMN_NAME=CU1.COLUMN_NAME)
	where S.SUBJECTAREANO=@pnSubjectArea
	UNION ALL
	select  S.PARENTTABLE,
		substring(CU.COLUMN_NAME,1,30),
		1
	from SUBJECTAREA S
		-- Get the Primary Key of the parent table
	join INFORMATION_SCHEMA.TABLE_CONSTRAINTS C 		on (C.TABLE_NAME=S.PARENTTABLE
								and C.CONSTRAINT_TYPE='PRIMARY KEY')
		-- Now get the name of the foreign key column
	join INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU 	on (CU.CONSTRAINT_NAME=C.CONSTRAINT_NAME)
	where S.SUBJECTAREANO=@pnSubjectArea

	Set @ErrorCode=@@Error

	If @ErrorCode=0
	Begin
		--------------------------------------------
		-- Some child tables will have a foreign key
		-- reference to the parent table where the
		-- referencing column is not part of the
		-- Primary Key. Include these as well.
		--------------------------------------------
		Insert into @tbPrimaryKey(TABLENAME, PRIMARYKEYCOLUMN, PARENTFLAG)
		select  T.TABLENAME,
			substring(CU1.COLUMN_NAME,1,30),
			0
		from SUBJECTAREA S
			-- Get the tables that are to be reported on
		cross join (select distinct TABLENAME from @tbReportOn) T
			-- Get the Primary Key of the parent table
		join INFORMATION_SCHEMA.TABLE_CONSTRAINTS C 		on (C.TABLE_NAME=S.PARENTTABLE
									and C.CONSTRAINT_TYPE='PRIMARY KEY')
			-- Find constraints that point to the parent Primary Key
		join INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC 	on (RC.UNIQUE_CONSTRAINT_NAME=C.CONSTRAINT_NAME)
			-- Find the foreign key constraints that point to the parent Primary Key
			-- for the tables that are to be reported on 
		join INFORMATION_SCHEMA.TABLE_CONSTRAINTS C1		on (C1.CONSTRAINT_TYPE='FOREIGN KEY'
									and C1.TABLE_NAME=T.TABLENAME
									and C1.CONSTRAINT_NAME=RC.CONSTRAINT_NAME)
			-- Now get the name of the foreign key column
		join INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU1 	on (CU1.CONSTRAINT_NAME=C1.CONSTRAINT_NAME)
			-- Only load these references if a column from 
			-- the Primary Key has not already been used.
		left join @tbPrimaryKey PK	on (PK.TABLENAME=T.TABLENAME)
		where S.SUBJECTAREANO=@pnSubjectArea
		and PK.TABLENAME is null

		Set @ErrorCode=@@Error
	End

	If @ErrorCode=0
	Begin
		--------------------------------------------------
		-- Some child tables will not have a foreign key
		-- reference to the parent table even though a
		-- column exists with the same name as the parent
		-- Primary Key. This is for "history" tables where
		-- we cannot use constraints.
		--------------------------------------------------
		Insert into @tbPrimaryKey(TABLENAME, PRIMARYKEYCOLUMN, PARENTFLAG)
		select  T.TABLENAME,
			P.PRIMARYKEYCOLUMN,
			0
		from SUBJECTAREA S
			-- Get the tables that are to be reported on
		cross join (select distinct TABLENAME from @tbReportOn) T
			-- Get the Primary Key of the parent table
		join @tbPrimaryKey P			on (P.PARENTFLAG=1)
			-- Check that the table also has a column with 
			-- the same name as the Primary Key of the parent
		join INFORMATION_SCHEMA.COLUMNS C	on (C.TABLE_NAME=T.TABLENAME
							and C.COLUMN_NAME=P.PRIMARYKEYCOLUMN)
			-- Only load these references if a column from 
			-- the Primary Key has not already been used.
		left join @tbPrimaryKey PK	on (PK.TABLENAME=T.TABLENAME)
		where S.SUBJECTAREANO=@pnSubjectArea
		and PK.TABLENAME is null

		Set @ErrorCode=@@Error
	End
	
	If @psFilterKeyValue is not null
	and @ErrorCode=0
	Begin
		Select @bNameFilterFlag=1
		from @tbPrimaryKey
		where PRIMARYKEYCOLUMN='NAMENO'
		
		set @ErrorCode=@@Error
	End

	-------------------------------------------------------------
	-- Some tables may have more than one Column that is pointing
	-- to the parent primary key.  If this is the case then only
	-- keep the entry that has the same column name as the parent
	-- primary key as this will be the main key.
	-------------------------------------------------------------
	If @ErrorCode=0
	Begin
		Delete @tbPrimaryKey
		from @tbPrimaryKey P
		where P.PARENTFLAG=0
		and exists
		(select 1 
		 from @tbPrimaryKey P1
		 join @tbPrimaryKey P2 on (P2.PARENTFLAG=1
				       and P2.PRIMARYKEYCOLUMN=P1.PRIMARYKEYCOLUMN)
		 where P1.TABLENAME=P.TABLENAME
		 and P1.PRIMARYKEYCOLUMN<>P.PRIMARYKEYCOLUMN)

		Set @ErrorCode=@@Error
	End

	-- If filtering by primary key then check if this is 
	-- for NAME or CASES. This information will be used
	-- to link ADDRESS changes either to the Name or Case
	-- being reported on.
	If  @psFilterKeyValue is not null
	and @pnSubjectArea    is not null
	and @ErrorCode=0
	Begin
		Select @bCaseKeyFilter=CASE WHEN(S.TABLENAME='CASES') THEN 1 ELSE 0 END,
		       @bNameKeyFilter=CASE WHEN(S.TABLENAME='NAME' ) THEN 1 ELSE 0 END
		from SUBJECTAREATABLES S
		where S.SUBJECTAREANO=@pnSubjectArea
		and S.TABLENAME in ('CASES','NAME')

		Set @ErrorCode=@@Error
	End
End

Set @nRowNumber=1

-- Loop through each Table and Column to be reported on
-- and construct the SQL to load the audit information for later reporting
While @nRowNumber<=@nNoOfColumns
and @ErrorCode=0
Begin
	Select	@sTableName =T.TABLENAME,
		@sColumnName=T.COLUMNNAME,
		@sKeyColumn =K.PRIMARYKEYCOLUMN
	From @tbReportOn T
	left join @tbPrimaryKey K on (K.TABLENAME=T.TABLENAME)
	Where T.COLUMNNUMBER=@nRowNumber

	Set @ErrorCode=@@Error

	-- Initialise the CurrentTableName for the first
	-- row so we can keep track of when the Table changes.
	If @nRowNumber=1
	Begin
		Set @sCurrentTableName=@sTableName
	End

	-- On the first row processed or when the Table being reported has just changed,
	-- get details of the primary key columns of the table as this will be required
	-- if Updates are being reported on and also to output the primary key details 
	-- of the data modified.

	If  (@nRowNumber=1 OR @sCurrentTableName<>@sTableName)
	and @ErrorCode=0
	Begin
		Set @sPrimaryKeyJoin=null
		Set @sPrimaryKeyList=null

		Set @sSQLString="
		select  @sPrimaryKeyJoin=@sPrimaryKeyJoin+char(10)+'and X.'+CU.COLUMN_NAME+'=L1.'+CU.COLUMN_NAME,
			@sPrimaryKeyList=nullif(@sPrimaryKeyList+'+','+')+'''['+CU.COLUMN_NAME+']''+convert(varchar,L1.'+CU.COLUMN_NAME+')'
		from INFORMATION_SCHEMA.TABLE_CONSTRAINTS C
			-- Get the columns of the Primary Key
		join INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU 	on (CU.CONSTRAINT_NAME=C.CONSTRAINT_NAME)
		where C.TABLE_NAME=@sTableName
		and C.CONSTRAINT_TYPE='PRIMARY KEY'
		-- SQA16819 NameNo may have been updated so cannot use in join.
		--          Fortunately the SEQUENCE is now unique within a NameType
		and not (CU.COLUMN_NAME='NAMENO' AND C.TABLE_NAME='CASENAME')"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sPrimaryKeyJoin	nvarchar(1000)	OUTPUT,
					  @sPrimaryKeyList	nvarchar(500)	OUTPUT,
					  @sTableName		nvarchar(30)',
					  @sPrimaryKeyJoin=@sPrimaryKeyJoin	OUTPUT,
					  @sPrimaryKeyList=@sPrimaryKeyList	OUTPUT,
					  @sTableName=@sTableName
		Set @sSQLString=null
	End

	If @ErrorCode=0
	Begin
		Set @sCurrentTableName=@sTableName

		If @pbIncludeUpdates=1
		Begin
			Set @sSQLString="SELECT L1.LOGDATETIMESTAMP, L1.LOGACTION,L1.LOGUSERID,L1.LOGIDENTITYID,L1.LOGTRANSACTIONNO,'"+@sTableName+"','"+@sColumnName+"',cast(L1."+@sColumnName+" as NVARCHAR(1809)),cast(isnull(L2."+@sColumnName+",X."+@sColumnName+") as NVARCHAR(1809)),"


			Set @sSQLFrom=
			"FROM "+@sTableName+"_iLOG L1"+char(10)+
			"LEFT JOIN "+@sTableName+"_iLOG L2 on (L1.LOGACTION='U'"+
			replace(@sPrimaryKeyJoin,'and X.',replicate(char(9),3)+'and L2.')+char(10)+
			"			and L2.LOGDATETIMESTAMP=(select min(L3.LOGDATETIMESTAMP)"+char(10)+
			"						 from "+@sTableName+"_iLOG L3"+char(10)+
			"						 where L3.LOGACTION=L3.LOGACTION"+
			replace(@sPrimaryKeyJoin,'and X.',replicate(char(9),6)+'and L3.')+char(10)+
			"						 and L3.LOGDATETIMESTAMP>L1.LOGDATETIMESTAMP))"+char(10)+
			"LEFT JOIN "+@sTableName+" X on (L1.LOGACTION='U'"+char(10)+
			"			and L2.LOGDATETIMESTAMP is null"+
			replace(@sPrimaryKeyJoin,'and X.',replicate(char(9),3)+'and X.')+")"

			-- SQA14675
			-- Only report UPDATE if the data has actually changed unless it is one of the listed tables.
			If @sTableName in ('CRITERIA',
					   'DISCOUNT',
					   'EXCHRATEVARIATION',
					   'FEESCALCULATION',
					   'MARGIN',
					   'MARGINPROFILE',
					   'MARGINPROFILERULE')
				Set @sSQLWhere="and (L1."+@sColumnName+" is not null OR L2."+@sColumnName+" is not null)"
			-- SQA18070
			-- Return the CASEID column which will then show the IRN for the Case related tables
			Else if (@sTableName in ('CASES','CASENAME','CASETEXT','CASEEVENT','OPENACTION','OFFICIALNUMBERS','RELATEDCASE') AND @sColumnName in('CASEID'))			
				Set @sSQLWhere="and (L1."+@sColumnName+" is not null OR L2."+@sColumnName+" is not null)"
			Else
				Set @sSQLWhere="and ((L1.LOGACTION='U' and checksum(L1."+@sColumnName+")<>checksum(isnull(L2."+@sColumnName+",X."+@sColumnName+"))) OR (L1.LOGACTION<>'U' and L1."+@sColumnName+" is not null))"
		End
		Else Begin
			Set @sSQLString="SELECT L1.LOGDATETIMESTAMP,L1.LOGACTION,L1.LOGUSERID,L1.LOGIDENTITYID,L1.LOGTRANSACTIONNO,'"+@sTableName+"','"+@sColumnName+"',cast(L1."+@sColumnName+" as NVARCHAR(1809)),null,"

			Set @sSQLFrom=
			"FROM "+@sTableName+"_iLOG L1"

			Set @sSQLWhere="and L1."+@sColumnName+" is not null"
		End
		
		If @sTableName='ADDRESS'
		Begin
			If @bCaseKeyFilter=1
			Begin
				Set @sSQLFrom=@sSQLFrom+char(10)+
				"join CASENAME PK on (PK.ADDRESSCODE=L1.ADDRESSCODE"+char(10)+
				"                 and PK.CASEID="+@psFilterKeyValue+")"
			End
			Else If @bNameKeyFilter=1
			Begin
				Set @sSQLFrom=@sSQLFrom+char(10)+
				"join NAME PK on (L1.ADDRESSCODE in (PK.POSTALADDRESS,PK.STREETADDRESS)"+char(10)+
				"             and PK.NAMENO="+@psFilterKeyValue+")"
			End
		End
		-- Check to see if there is any filtering that requires
		-- the transaction to be considered.
		If @pnSessionId    is not null
		or @pdtSessionDate is not null
		or @pnDataSource   is not null
		or @psBatchId      is not null
		Begin
			Set @sSQLFrom=@sSQLFrom+char(10)+
				"join TRANSACTIONINFO TS on (TS.LOGTRANSACTIONNO=L1.LOGTRANSACTIONNO)"

			If @pnSessionId    is not null
			or @pdtSessionDate is not null
			Begin
				Set @sSQLFrom=@sSQLFrom+char(10)+
					"join SESSION S on (S.SESSIONNO=TS.SESSIONNO"

				If @pnSessionId is not null
					Set @sSQLFrom=@sSQLFrom+char(10)+
						"              and S.SESSIONIDENTIFIER=@pnSessionId"

				If @pdtSessionDate is not null
					Set @sSQLFrom=@sSQLFrom+char(10)+
						"              and S.STARTDATE=@pdtSessionDate"

				Set @sSQLFrom=@sSQLFrom+')'
			End


			If @pnDataSource is not null
			Begin
				Set @sSQLFrom=@sSQLFrom+char(10)+
					"join EDESENDERDETAILS EDE on (EDE.BATCHNO=TS.BATCHNO"+char(10)+
					"                          and EDE.SENDERNAMENO=@pnDataSource"

				If @psBatchId is not null
					Set @sSQLFrom=@sSQLFrom+"                          and EDE.SENDERREQUESTIDENTIFIER=@psBatchId"

				Set @sSQLFrom=@sSQLFrom+')'
			End
		End

		-- Certain columns that are foreign keys need to be expanded to
		-- show the current associated description of that foreign key
 
		-- Cases Table
		If @sColumnName in (	'ACCOUNTCASEID',
					'BILLEDCASEID',
					'CASEID',
					'CRCASEID',
					'RELATEDCASEID',
					'TOCASEID')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.IRN, FK2.IRN"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN CASES FK1 on (FK1.CASEID=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN CASES FK2 on (FK2.CASEID=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.IRN, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN CASES FK1 on (FK1.CASEID=L1."+@sColumnName+")"
			End
		End
		-- ACTIONS Table
		Else If @sColumnName in ('ACTION')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.ACTIONNAME, FK2.ACTIONNAME"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN ACTIONS FK1 on (FK1.ACTION=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN ACTIONS FK2 on (FK2.ACTION=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.ACTIONNAME, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN ACTIONS FK1 on (FK1.ACTION=L1."+@sColumnName+")"
			End
		End
		-- ADDRESS Table
		Else If @sColumnName in('ADDRESSCODE',
					'POSTALADDRESS',
					'STREETADDRESS')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"replace(left(dbo.fn_FormatAddress(FK1.STREET1,FK1.STREET2,FK1.CITY,FK1.STATE,NULL,FK1.POSTCODE,FK1.COUNTRYCODE,0,1,NULL,7205),100), CHAR(13)+CHAR(10), ', '), replace(left(dbo.fn_FormatAddress(FK2.STREET1,FK2.STREET2,FK2.CITY,FK2.STATE,NULL,FK2.POSTCODE,FK2.COUNTRYCODE,0,1,NULL,7205),100), CHAR(13)+CHAR(10), ', ')"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN ADDRESS FK1 on (FK1.ADDRESSCODE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN ADDRESS FK2 on (FK2.ADDRESSCODE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"replace(left(dbo.fn_FormatAddress(FK1.STREET1,FK1.STREET2,FK1.CITY,FK1.STATE,NULL,FK1.POSTCODE,FK1.COUNTRYCODE,0,1,NULL,7205),100), CHAR(13)+CHAR(10), ', '), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN ADDRESS FK1 on (FK1.ADDRESSCODE=L1."+@sColumnName+")"
			End
		End
		-- APPLICATIONBASIS Table
		Else If @sColumnName in('BASIS')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.BASISDESCRIPTION, FK2.BASISDESCRIPTION"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN APPLICATIONBASIS FK1 on (FK1.BASIS=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN APPLICATIONBASIS FK2 on (FK2.BASIS=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.BASISDESCRIPTION, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN APPLICATIONBASIS FK1 on (FK1.BASIS=L1."+@sColumnName+")"
			End
		End
		-- CASECATEGORY Table
		Else If @sColumnName in('CASECATEGORY')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.CASECATEGORYDESC, FK2.CASECATEGORYDESC"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN CASECATEGORY FK1 on (FK1.CASETYPE=L1.CASETYPE AND FK1.CASECATEGORY=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN CASECATEGORY FK2 on (FK2.CASETYPE=isnull(L2.CASETYPE,X.CASETYPE) AND FK2.CASECATEGORY=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.CASECATEGORYDESC, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN CASECATEGORY FK1 on (FK1.CASETYPE=L1.CASETYPE AND FK1.CASECATEGORY=L1."+@sColumnName+")"
			End
		End
		-- CASERELATION Table
		Else If @sColumnName in('CASERELATIONSHIP',
					'FROMRELATIONSHIP',
					'RECIPRELATIONSHIP',
					'RELATIONSHIP')
		     and @sTableName not in ('ASSOCIATEDNAME')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.RELATIONSHIPDESC, FK2.RELATIONSHIPDESC"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN CASERELATION FK1 on (FK1.RELATIONSHIP=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN CASERELATION FK2 on (FK2.RELATIONSHIP=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.RELATIONSHIPDESC, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN CASERELATION FK1 on (FK1.RELATIONSHIP=L1."+@sColumnName+")"
			End
		End
		-- CASETYPE Table
		Else If @sColumnName in('CASETYPE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.CASETYPEDESC, FK2.CASETYPEDESC"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN CASETYPE FK1 on (FK1.CASETYPE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN CASETYPE FK2 on (FK2.CASETYPE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.CASETYPEDESC, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN CASETYPE FK1 on (FK1.CASETYPE=L1."+@sColumnName+")"
			End
		End
		-- COUNTRY Table
		Else If @sColumnName in('CASECOUNTRY',
					'CASECOUNTRYCODE',
					'COUNTRY',
					'COUNTRYCODE',
					'HEADERCOUNTRY',
					'HOMECOUNTRY',
					'IMPORTEDCOUNTRY',
					'INSTRUCTORCOUNTRY',
					'ISSUINGCOUNTRY',
					'NATIONALITY',
					'REJECTEDCOUNTRY',
					'TREATYCODE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.COUNTRY, FK2.COUNTRY"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN COUNTRY FK1 on (FK1.COUNTRYCODE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN COUNTRY FK2 on (FK2.COUNTRYCODE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.COUNTRY, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN COUNTRY FK1 on (FK1.COUNTRYCODE=L1."+@sColumnName+")"
			End
		End
		-- CRITERIA Table
		Else If @sColumnName in('CRITERIANO',
					'FROMCRITERIA')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), left(FK2.DESCRIPTION,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN CRITERIA FK1 on (FK1.CRITERIANO=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN CRITERIA FK2 on (FK2.CRITERIANO=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN CRITERIA FK1 on (FK1.CRITERIANO=L1."+@sColumnName+")"
			End
		End
		-- EVENTS Table
		Else If @sColumnName in('ACTEVENTNO',
					'CASEEVENTNO',
					'COMPAREEVENT',
					'DIMEVENTNO',
					'DISPLAYEVENTNO',
					'ERROREVENTNO',
					'EVENT1NO',
					'EVENT2NO',
					'EVENTNO',
					'FROMEVENT',
					'FROMEVENTNO',
					'HIDEEVENTNO',
					'LASTEVENT',
					'NOEVENTNO',
					'OTHEREVENTNO',
					'PROPERTYEVENTNO',
					'RELATEDEVENT',
					'RELATEDEVENTNO',
					'RETROEVENTNO',
					'TRIGGEREVENTNO',
					'UPDATEEVENTNO',
					'UPDATEFROMEVENT')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.EVENTDESCRIPTION, FK2.EVENTDESCRIPTION"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN EVENTS FK1 on (FK1.EVENTNO=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN EVENTS FK2 on (FK2.EVENTNO=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.EVENTDESCRIPTION, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN EVENTS FK1 on (FK1.EVENTNO=L1."+@sColumnName+")"
			End
		End
		-- EXCHRATESCHEDULE Table
		Else If @sColumnName in('EXCHSCHEDULEID')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), left(FK2.DESCRIPTION,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN EXCHRATESCHEDULE FK1 on (FK1.EXCHSCHEDULEID=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN EXCHRATESCHEDULE FK2 on (FK2.EXCHSCHEDULEID=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN EXCHRATESCHEDULE FK1 on (FK1.EXCHSCHEDULEID=L1."+@sColumnName+")"
			End
		End
		-- INSTRUCTIONS Table
		Else If @sColumnName in('INSTRUCTIONCODE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), left(FK2.DESCRIPTION,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN INSTRUCTIONS FK1 on (FK1.INSTRUCTIONCODE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN INSTRUCTIONS FK2 on (FK2.INSTRUCTIONCODE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN INSTRUCTIONS FK1 on (FK1.INSTRUCTIONCODE=L1."+@sColumnName+")"
			End
		End
		-- INSTRUCTIONTYPE Table
		Else If @sColumnName in('INSTRUCTIONTYPE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.INSTRTYPEDESC, FK2.INSTRTYPEDESC"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN INSTRUCTIONTYPE FK1 on (FK1.INSTRUCTIONTYPE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN INSTRUCTIONTYPE FK2 on (FK2.INSTRUCTIONTYPE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.INSTRTYPEDESC, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN INSTRUCTIONTYPE FK1 on (FK1.INSTRUCTIONTYPE=L1."+@sColumnName+")"
			End
		End
		-- KEYWORDS Table
		Else If @sColumnName in('KEYWORDS')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.KEYWORD, FK2.KEYWORD"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN KEYWORDS FK1 on (FK1.KEYWORDNO=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN KEYWORDS FK2 on (FK2.KEYWORDNO=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.KEYWORD, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN KEYWORDS FK1 on (FK1.KEYWORDNO=L1."+@sColumnName+")"
			End
		End
		-- LETTER Table
		Else If @sColumnName in('LETTERNO',
					'ALTERNATELETTER',
					'COVERINGLETTER',
					'DEBITNOTE',
					'DOCUMENTNO',
					'ENVELOPE',
					'OVERRIDELETTER',
					'SINGLECASELETTERNO')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.LETTERNAME,100), left(FK2.LETTERNAME,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN LETTER FK1 on (FK1.LETTERNO=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN LETTER FK2 on (FK2.LETTERNO=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.LETTERNAME,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN LETTER FK1 on (FK1.LETTERNO=L1."+@sColumnName+")"
			End
		End
		-- MARGINPROFILE Table
		Else If @sColumnName in('MARGINPROFILENO')
		Begin
			If @pbIncludeUpdates=1
			Begin
				If @sTableName='MARGINPROFILE'
					Set @sSQLString=@sSQLString+"CASE WHEN(L1.LOGACTION='U') THEN FK1.PROFILENAME END,CASE WHEN(L1.LOGACTION='U') THEN FK2.PROFILENAME END"
				Else
					Set @sSQLString=@sSQLString+"FK1.PROFILENAME, FK2.PROFILENAME"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN MARGINPROFILE FK1 on (FK1.MARGINPROFILENO=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN MARGINPROFILE FK2 on (FK2.MARGINPROFILENO=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				If @sTableName='MARGINPROFILE'
					Set @sSQLString=@sSQLString+"CASE WHEN(L1.LOGACTION='U') THEN FK1.CASETYPEDESC END,null"
				Else
					Set @sSQLString=@sSQLString+"FK1.PROFILENAME, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN MARGINPROFILE FK1 on (FK1.MARGINPROFILENO=L1."+@sColumnName+")"
			End
		End
		-- MARGINTYPE Table
		Else If @sColumnName in('MARGINTYPENO')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), left(FK2.DESCRIPTION,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN MARGINTYPE FK1 on (FK1.MARGINTYPENO=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN MARGINTYPE FK2 on (FK2.MARGINTYPENO=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN MARGINTYPE FK1 on (FK1.MARGINTYPENO=L1."+@sColumnName+")"
			End
		End
		-- NAME Table
		-- SQA18015  Show Name details for Name Mapping columns DATASOURCENAMENO, INPRONAMENO.
		Else If @sColumnName in('ACCESSSTAFFNO',
					'ACCOUNTOWNER',
					'ACCTNAMENO',
					'AGENT',
					'AGENTNO',
					'ASSOCIATENO',
					'BRANCHNAMENO',
					'CALLER',
					'CORRESPONDNAME',
					'DATASOURCENAMENO',
					'DEBTOR',
					'DEBTORNO',
					'DEFAULTNAMENO',
					'DEFAULTSOURCENO',
					'DISBEMPLOYEENO',
					'DIVISIONNO',
					'EMPLOYEENO',
					'ENTITYNO',
					'FOREIGNAGENTNO',
					'FROMNAMENO',
					'HEADERINSTRUCTOR',
					'HEADERSTAFFNAME',
					'HOMENAMENO',
					'IMPORTEDINSTRUCTOR',
					'IMPORTEDSTAFFNAME',
					'INHERITEDNAMENO',
					'INPRONAMENO',				
					'INSTRUCTOR',
					'IPOFFICE',
					'ISSUEDBY',
					'MAINCONTACT',
					'NAMEID',
					'NAMENO',
					'NEWNAMENO',
					'OWNER',
					'OWNERNO',
					'QUOTATIONNAMENO',
					'RAISEDBYNO',
					'REFERREDTO',
					'REJECTEDINSTRUCTOR',
					'REJECTEDSTAFFNAME',
					'RELATEDNAME',
					'REMINDEMPLOYEE',
					'REMITTANCENAMENO',
					'RESTRICTEDTONAME',
					'SERVEMPLOYEENO',
					'SOURCENAMENO',
					'SOURCENO',
					'SUPPLIERNAMENO',
					'TOEMPLOYEENO',
					'TRANSLATOR',
					'WIPEMPLOYEENO')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(dbo.fn_FormatNameUsingNameNo(FK1.NAMENO,DEFAULT),88)+nullif('['+FK1.NAMECODE+']','[]'), left(dbo.fn_FormatNameUsingNameNo(FK2.NAMENO,DEFAULT),88)+nullif('['+FK2.NAMECODE+']','[]')"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN NAME FK1 on (FK1.NAMENO=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN NAME FK2 on (FK2.NAMENO=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(dbo.fn_FormatNameUsingNameNo(FK1.NAMENO,DEFAULT),88)+nullif('['+FK1.NAMECODE+']','[]'), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN NAME FK1 on (FK1.NAMENO=L1."+@sColumnName+")"
			End
		End
		-- EXTERNALNAME Table
		-- SQA18015  Show Extername name details for Name Mapping column EXTERNALNAMEID.
		Else If @sColumnName in('EXTERNALNAMEID')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.EXTERNALNAME,68)+nullif('['+FK1.EXTERNALNAMECODE+']','[]'), left(FK2.EXTERNALNAME,68)+nullif('['+FK2.EXTERNALNAMECODE+']','[]')"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN EXTERNALNAME FK1 on (FK1.EXTERNALNAMEID=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN EXTERNALNAME FK2 on (FK2.EXTERNALNAMEID=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.EXTERNALNAME,68)+nullif('['+FK1.EXTERNALNAMECODE+']','[]'), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN EXTERNALNAME FK1 on (FK1.EXTERNALNAMEID=L1."+@sColumnName+")"
			End
		End
		-- NAMERELATION Table
		Else If @sColumnName in('INHERITEDRELATIONS',
					'NAMERELATIONSHIP',
					'PATHRELATIONSHIP',
					'RELATIONSHIP')
		     and @sTableName not in ('RELATEDCASE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.RELATIONDESCR, FK2.RELATIONDESCR"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN NAMERELATION FK1 on (FK1.RELATIONSHIP=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN NAMERELATION FK2 on (FK2.RELATIONSHIP=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.RELATIONDESCR, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN NAMERELATION FK1 on (FK1.RELATIONSHIP=L1."+@sColumnName+")"
			End
		End
		-- NAMETYPE Table
		Else If @sColumnName in('NAMETYPE',
					'APPLICABLENAMETYPE',
					'CHANGENAMETYPE',
					'COPIESTO',
					'COPYFROMNAMETYPE',
					'COPYTONAMETYPE',
					'DISBSTAFFNAMETYPE',
					'FUTURENAMETYPE',
					'INSTRUCTNAMETYPE',
					'INSTRUCTORNAMETYPE',
					'REQUESTORNAMETYPE',
					'RESTRICTEDBYTYPE',
					'SERVSTAFFNAMETYPE',
					'SUBSTITUTENAMETYPE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), left(FK2.DESCRIPTION,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN NAMETYPE FK1 on (FK1.NAMETYPE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN NAMETYPE FK2 on (FK2.NAMETYPE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN NAMETYPE FK1 on (FK1.NAMETYPE=L1."+@sColumnName+")"
			End
		End
		-- NUMBERTYPES Table
		Else If @sColumnName in('NUMBERTYPE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), left(FK2.DESCRIPTION,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN NUMBERTYPES FK1 on (FK1.NUMBERTYPE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN NUMBERTYPES FK2 on (FK2.NUMBERTYPE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN NUMBERTYPES FK1 on (FK1.NUMBERTYPE=L1."+@sColumnName+")"
			End
		End
		-- NAMEVARIANT Table
		Else If @sColumnName in('NAMEVARIANTNO')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.NAMEVARIANT,100), left(FK2.NAMEVARIANT,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN NAMEVARIANT FK1 on (FK1.NAMENO=L1.NAMENO AND FK1.NAMEVARIANTNO=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN NAMEVARIANT FK2 on (FK2.NAMENO=L2.NAMENO AND FK2.NAMEVARIANTNO=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.NAMEVARIANT,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN NAMEVARIANT FK1 on (FK1.NAMENO=L1.NAMENO AND FK1.NAMEVARIANTNO=L1."+@sColumnName+")"
			End
		End
		-- OFFICE Table
		Else If @sColumnName in('OFFICEID',
					'CASEOFFICEID',
					'SOURCEOFFICEID',
					'OFFICE',
					'CASEOFFICE',
					'EMPOFFICECODE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.DESCRIPTION, FK2.DESCRIPTION"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN OFFICE FK1 on (FK1.OFFICEID=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN OFFICE FK2 on (FK2.OFFICEID=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.DESCRIPTION, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN OFFICE FK1 on (FK1.OFFICEID=L1."+@sColumnName+")"
			End
		End
		-- PROPERTYTYPE Table
		Else If @sColumnName in('HEADERPROPERTY',
					'IMPORTEDPROPERTY',
					'NEWPROPERTYTYPE',
					'PAYPROPERTYTYPE',
					'PROPERTYTYPE',
					'PROPERTYTYPEKEY',
					'REJECTEDPROPERTY')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.PROPERTYNAME, FK2.PROPERTYNAME"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN PROPERTYTYPE FK1 on (FK1.PROPERTYTYPE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN PROPERTYTYPE FK2 on (FK2.PROPERTYTYPE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.PROPERTYNAME, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN PROPERTYTYPE FK1 on (FK1.PROPERTYTYPE=L1."+@sColumnName+")"
			End
		End
		-- QUESTION Table
		Else If @sColumnName in('QUESTION')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.QUESTION, FK2.QUESTION"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN QUESTION FK1 on (FK1.QUESTIONNO=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN QUESTION FK2 on (FK2.QUESTIONNO=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.QUESTION, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN QUESTION FK1 on (FK1.QUESTIONNO=L1."+@sColumnName+")"
			End
		End
		-- STATUS Table
		Else If @sColumnName in('RENEWALSTATUS',
					'STATUSCODE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.INTERNALDESC, FK2.INTERNALDESC"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN STATUS FK1 on (FK1.STATUSCODE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN STATUS FK2 on (FK2.STATUSCODE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.INTERNALDESC, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN STATUS FK1 on (FK1.STATUSCODE=L1."+@sColumnName+")"
			End
		End
		-- SUBTYPE Table
		Else If @sColumnName in('SUBTYPE',
					'CASESUBTYPE',
					'HEADERSUBTYPE',
					'IMPORTEDSUBTYPE',
					'REJECTEDSUBTYPE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.SUBTYPEDESC, FK2.SUBTYPEDESC"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN SUBTYPE FK1 on (FK1.SUBTYPE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN SUBTYPE FK2 on (FK2.SUBTYPE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.SUBTYPEDESC, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN SUBTYPE FK1 on (FK1.SUBTYPE=L1."+@sColumnName+")"
			End
		End
		-- TELECOMMUNICATION Table
		-- SQA18015 Exclude TELECOMMUNICATION details if Name Mapping column FAX is selected.
		Else If ( @sColumnName in('FAX',
					'MAINEMAIL',
					'MAINPHONE',
					'TELECODE',
					'TELEPHONE')
			AND @sTableName <> 'EXTERNALNAME' )
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(dbo.fn_FormatTelecom(null,FK1.ISD, FK1.AREACODE,FK1.TELECOMNUMBER,FK1.EXTENSION),100), left(dbo.fn_FormatTelecom(null,FK2.ISD, FK2.AREACODE,FK2.TELECOMNUMBER,FK2.EXTENSION),100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN TELECOMMUNICATION FK1 on (FK1.TELECODE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN TELECOMMUNICATION FK2 on (FK2.TELECODE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(dbo.fn_FormatTelecom(null,FK1.ISD, FK1.AREACODE,FK1.TELECOMNUMBER,FK1.EXTENSION),100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN TELECOMMUNICATION FK1 on (FK1.TELECODE=L1."+@sColumnName+")"
			End
		End
		-- TABLECODES Table
		Else If @sColumnName in('ACCOUNTTYPE',
					'ACTIONFLAG',
					'ACTIVITYCATEGORY',
					'ACTIVITYCODE',
					'ACTIVITYTYPE',
					'ADDRESSSTATUS',
					'ADDRESSSTYLE',
					'ADDRESSTYPE',
					'AMOUNTTYPE',
					'ATTACHMENTTYPE',
					'BANKOPERATIONCODE',
					'BATCHTYPE',
					'BILLINGFREQUENCY',
					'CAPACITYTOSIGN',
					'CARRIER',
					'CATEGORY',
					'CATEGORYID',
					'CONTROLACCTYPEID',
					'CREDITCARDTYPE',
					'DATAFORMATID',
					'DEBTORTYPE',
					'DELIVERYTYPE',
					'DETAILSOFCHARGES',
					'EFTFILEFORMAT',
					'ENTITYSIZE',
					'EXAMTYPE',
					'EXPORTFORMAT',
					'FILELOCATION',
					'GROUPID',
					'IMAGESTATUS',
					'IMAGETYPE',
					'ITEMTYPE',
					'JOBROLE',
					'LANGUAGE',
					'LANGUAGECODE',
					'LANGUAGENO',
					'LINETYPE',
					'MENUCODE',
					'MONTHOFYEAR',
					'NAMECATEGORY',
					'NAMEDATA',
					'NAMESTYLE',
					'PACKAGETYPE',
					'POSITIONCATEGORY',
					'PRODUCTCODE',
					'QUANTITYDESC',
					'RATETYPE',
					'RENEWALTYPE',
					'REPORTTOOL',
					'RULETYPE',
					'SEGMENT1CODE',
					'SEGMENT2CODE',
					'SEGMENT3CODE',
					'SEGMENT4CODE',
					'SEGMENT5CODE',
					'SEGMENT6CODE',
					'SEGMENT7CODE',
					'SEGMENT8CODE',
					'SEGMENT9CODE',
					'SENDMETHOD',
					'STAFFCLASS',
					'STATUS',
					'SUPPLIERTYPE',
					'TABLECODE',
					'TASKTYPE',
					'TAXTREATMENT',
					'TELECOMTYPE',
					'TEXTID',
					'TOPRODUCTCODE',
					'TYPEID',
					'TYPEOFMARK',
					'USEDEBTORTYPE',
					'VALEDICTION',
					'VARIANTREASON')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), left(FK2.DESCRIPTION,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN TABLECODES FK1 on (FK1.TABLECODE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN TABLECODES FK2 on (FK2.TABLECODE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN TABLECODES FK1 on (FK1.TABLECODE=L1."+@sColumnName+")"
			End
		End
		-- TEXTTYPE Table
		Else If @sColumnName in('TEXTTYPE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"FK1.TEXTDESCRIPTION, FK2.TEXTDESCRIPTION"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN TEXTTYPE FK1 on (FK1.TEXTTYPE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN TEXTTYPE FK2 on (FK2.TEXTTYPE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"FK1.TEXTDESCRIPTION, null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN TEXTTYPE FK1 on (FK1.TEXTTYPE=L1."+@sColumnName+")"
			End
		End
		-- WIPCATEGORY Table
		Else If @sColumnName in('CATEGORYCODE',
					'WIPCATEGORY',
					'WIPCATEGORYCODE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), left(FK2.DESCRIPTION,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN WIPCATEGORY FK1 on (FK1.CATEGORYCODE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN WIPCATEGORY FK2 on (FK2.CATEGORYCODE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN WIPCATEGORY FK1 on (FK1.CATEGORYCODE=L1."+@sColumnName+")"
			End
		End
		-- WIPTEMPLATE Table
		Else If @sColumnName in('WIPCODE',
					'ACTIVITY',
					'CREDITWIPCODE',
					'DISBWIPCODE',
					'SERVICEWIPCODE',
					'SERVWIPCODE',
					'TOWIPCODE',
					'VARWIPCODE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), left(FK2.DESCRIPTION,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN WIPTEMPLATE FK1 on (FK1.WIPCODE=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN WIPTEMPLATE FK2 on (FK2.WIPCODE=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN WIPTEMPLATE FK1 on (FK1.WIPCODE=L1."+@sColumnName+")"
			End
		End
		-- WIPTYPE Table
		Else If @sColumnName in('WIPTYPEID',
					'WIPTYPE')
		Begin
			If @pbIncludeUpdates=1
			Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), left(FK2.DESCRIPTION,100)"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN WIPTYPE FK1 on (FK1.WIPTYPEID=L1."+@sColumnName+")"+char(10)+
				"LEFT JOIN WIPTYPE FK2 on (FK2.WIPTYPEID=isnull(L2."+@sColumnName+",X."+@sColumnName+"))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"left(FK1.DESCRIPTION,100), null"

				Set @sSQLFrom=@sSQLFrom+char(10)+
				"LEFT JOIN WIPTYPE FK1 on (FK1.WIPTYPEID=L1."+@sColumnName+")"
			End
		End

		-- If no foreign key expansion is required then return Nulls into the 2 columns
		Else Begin
			Set @sSQLString=@sSQLString+"null,null"
		End
		
		-- When filtering is my NAMENO and the ADDRESS table is being reported
		-- then add a join to NAMEADDRESS so that only ADDRESSes related to the
		-- Name filter are reported		
		If @bNameFilterFlag=1
		and @sTableName='ADDRESS'
		Begin
			Set @sSQLFrom=@sSQLFrom+char(10)+
			"JOIN (select distinct ADDRESSCODE from NAMEADDRESS where NAMENO=@psFilterKeyValue) NA"+char(10)+
			"                      on (NA.ADDRESSCODE=L1.ADDRESSCODE)"
		End
		
		-- When filtering is my NAMENO and the TELECOM table is being reported
		-- then add a join to NAMEADDRESS so that only ADDRESSes related to the
		-- Name filter are reported		
		If @bNameFilterFlag=1
		and @sTableName='TELECOMMUNICATION'
		Begin
			Set @sSQLFrom=@sSQLFrom+char(10)+
			"JOIN (select distinct TELECODE from NAMETELECOM where NAMENO=@psFilterKeyValue) NT"+char(10)+
			"                      on (NT.TELECODE=L1.TELECODE)"
		End

		-- Add the concatenated string of primary key columns to the output list
		-- and the logged transaction number
		Set @sSQLString=@sSQLString+','+@sPrimaryKeyList

		-- Combine the components of the Select

		Set @sSQLString=@sSQLString+char(10)+@sSQLFrom+char(10)+@sSQLFilter+char(10)+@sSQLWhere


		-- Check if the primary key filter is also required
		If @sKeyColumn is not null
		and @psFilterKeyValue is not null
		Begin
			Set @sSQLString=@sSQLString+char(10)+
			"and L1."+@sKeyColumn+"=@psFilterKeyValue"
		End

		-- Complete the Insert statement and execute it

		Set @sSQLString="insert into #TEMPLOG(LOGDATETIMESTAMP,LOGACTION,LOGUSERID,LOGIDENTITYID,LOGTRANSACTIONNO,NAMEOFTABLE,NAMEOFCOLUMN,CONTENTOFDATA,CONTENTOFDATAAFTER,CONTENTDESC,CONTENTDESCAFTER,PRIMARYKEY)"+char(10)+
				@sSQLString

		If @pbPrintSQL = 1
		Begin
			-- Print out the executed SQL statement
			Print	''

			Print 	@sSQLString
		End

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@psFilterKeyValue	nvarchar(50),
					  @pdtSessionDate	datetime,
					  @pnSessionId		int,
					  @pnDataSource		int,
					  @psBatchId		nvarchar(254)',
					  @psFilterKeyValue=@psFilterKeyValue,
					  @pdtSessionDate  =@pdtSessionDate,
					  @pnSessionId     =@pnSessionId,
					  @pnDataSource    =@pnDataSource,
					  @psBatchId       =@psBatchId
			
		Set @nRowNumber=@nRowNumber+1
	End
End	-- End of Loop

-- Sorting may be specified by parameter however some special rules requires a special sort column to be
-- generated in some situations.  The sort rules are :
--	TYPE
--	Inserts, Update and then Deletes ascending and the reverse for descending.
--	STAFFNAME 
--	Surname, first name
--	AUDITDATA
--	Will use the BEFORE value
-- Note that the pairs of data (before and after) will always be kept together irrespective of the sort order chosen.

If @ErrorCode=0
Begin
	If  @psSortOrderColumn   ='DATECHANGED'
	Begin
		Set @sOrderColumn="CASE(T.LOGACTION) WHEN('I') THEN '1' WHEN('U') THEN '2' ELSE '3' END+T.NAMEOFTABLE"
		Set @sOrderBy =	"Order by 1 " + 
				CASE WHEN(@psSortOrderDirection='A') THEN 'ASC' ELSE 'DESC' END+
				", 5 ASC, 10 ASC, 12 ASC, 6 ASC,9 ASC, 8 DESC"
	End
	Else If  @psSortOrderColumn='TYPE'
	Begin
		Set @sOrderColumn="CASE(T.LOGACTION) WHEN('I') THEN '1' WHEN('U') THEN '2' ELSE '3' END"
		Set @sOrderBy =	"Order by 10 " + 
				CASE WHEN(@psSortOrderDirection='A') THEN 'ASC' ELSE 'DESC' END+
				", 12 ASC, 9 ASC, 8 DESC"
	End
	Else If  @psSortOrderColumn='STAFFNAME'
	Begin
		Set @sOrderColumn="NULL"
		Set @sOrderBy =	"Order by 5 " + 
				CASE WHEN(@psSortOrderDirection='A') THEN 'ASC' ELSE 'DESC' END+
				", 4 ASC, 10 ASC, 12 ASC, 9 ASC, 8 DESC"
	End
	Else If  @psSortOrderColumn='LOGINID'
	Begin
		Set @sOrderColumn="NULL"
		Set @sOrderBy =	"Order by 4 " + 
				CASE WHEN(@psSortOrderDirection='A') THEN 'ASC' ELSE 'DESC' END+
				", 10 ASC, 12 ASC, 9 ASC, 8 DESC"
	End
	Else If  @psSortOrderColumn='FIELD'
	Begin
		Set @sOrderColumn="NULL"
		Set @sOrderBy =	"Order by 6 " + 
				CASE WHEN(@psSortOrderDirection='A') THEN 'ASC' ELSE 'DESC' END+
				", 9 ASC, 8 DESC"
	End
	Else If  @psSortOrderColumn='AUDITDATA'
	Begin
		Set @sOrderColumn="CONTENTOFDATA"
		Set @sOrderBy =	"Order by 10 " + 
				CASE WHEN(@psSortOrderDirection='A') THEN 'ASC' ELSE 'DESC' END+
				", 9 ASC, 8 DESC"
	End
	Else If  @psSortOrderColumn='PRIMARYKEY'
	Begin
		Set @sOrderColumn="NULL"
		Set @sOrderBy =	"Order by 12 " + 
				CASE WHEN(@psSortOrderDirection='A') THEN 'ASC' ELSE 'DESC' END+
				", 10 ASC, 6 ASC, 9 ASC, 8 DESC"
	End
	Else Begin
		Set @sOrderColumn="T.NAMEOFTABLE"
		Set @sOrderBy =	"Order by 10" + 
				CASE WHEN(@psSortOrderDirection='A') THEN 'ASC' ELSE 'DESC' END+
				",1 ASC, 5 ASC, 12 ASC, 6 ASC,9 ASC, 8 DESC"
	End


	-- Construct the Join required to return the name of person that performed the change
	-- We can simplify this if the data returned has been filtered for a particular name.

	If @pnNameNo is not null
	Begin
		Set @sSQLJoin = "Left Join USERIDENTITY UI on (UI.IDENTITYID=T.LOGIDENTITYID)"+char(10)+char(9)+
				"Left Join NAME N on (N.NAMENO=@pnNameNo)"
	End
	Else Begin
		Set @sSQLJoin = "Left Join USERIDENTITY UI on (UI.IDENTITYID=T.LOGIDENTITYID)"+char(10)+char(9)+
				"Left Join NAME N on (N.NAMENO=isnull(	UI.NAMENO,"+char(10)+char(9)+
				"					(select min(UI1.NAMENO)"+char(10)+char(9)+
				"                               	from USERIDENTITY UI1"+char(10)+char(9)+
				"                               	where UI1.LOGINID=T.LOGUSERID)))"
	End

	-- Now load the sorted data into an interim table.  This is so the final
	-- result set can be reported with some repeating rows suprressed 
	-- without impacting on the required sort order.
	
	Set @sSQLString="
	insert into #TEMPSORTEDRESULT(DATECHANGED, TYPE, PROGRAM, LOGINID, STAFFNAME, FIELD, AUDITDATA, BEFOREORAFTER, ROWNUMBER, ORDERCOLUMN, LOGACTION, PRIMARYKEY, LOGTRANSNO, USERID)
	Select	T.LOGDATETIMESTAMP 	as [DATECHANGED],
		left(TC.DESCRIPTION,20)
				 	as [TYPE],
		T.LOGPROGRAM	 	as [PROGRAM],
		isnull(UI.LOGINID,T.LOGUSERID)
					as [LOGINID],
		left(N.NAME+CASE WHEN(N.FIRSTNAME is not null) THEN ', '+N.FIRSTNAME END,50)
				 	as [STAFFNAME],
		T.NAMEOFCOLUMN +' ('+T.NAMEOFTABLE+')'
				 	as [FIELD],
		T.CONTENTOFDATA	+ CASE WHEN(T.CONTENTDESC is not null) THEN ' {'+T.CONTENTDESC+'}' END
					as [AUDITDATA],
		CASE WHEN(T.LOGACTION='I') 
		  THEN 'AFTER' 
		  ELSE 'BEFORE' 
		END,
		T.ROWNUMBER,"+char(10)+char(9)+char(9)+
		@sOrderColumn+",
		T.LOGACTION,
		T.PRIMARYKEY,
		T.LOGTRANSACTIONNO	as [LOGTRANSNO],
		T.LOGUSERID		as [USERID]
	from #TEMPLOG T
	join TABLECODES TC on (TC.TABLETYPE=117
			   and TC.USERCODE=T.LOGACTION)"+char(10)+char(9)+
	@sSQLJoin+"
	UNION ALL
	Select	T.LOGDATETIMESTAMP,
		left(TC.DESCRIPTION,20),
		T.LOGPROGRAM,
		isnull(UI.LOGINID,T.LOGUSERID),
		left(N.NAME+CASE WHEN(N.FIRSTNAME is not null) THEN ', '+N.FIRSTNAME END,50),
		T.NAMEOFCOLUMN +' ('+T.NAMEOFTABLE+')',
		T.CONTENTOFDATAAFTER + CASE WHEN(T.CONTENTDESCAFTER is not null) THEN ' {'+T.CONTENTDESCAFTER+'}' END,
		'AFTER',
		T.ROWNUMBER,"+char(10)+char(9)+char(9)+
		@sOrderColumn+",
		T.LOGACTION,
		T.PRIMARYKEY,
		T.LOGTRANSACTIONNO,
		T.LOGUSERID
	from #TEMPLOG T
	join TABLECODES TC on (TC.TABLETYPE=117
			   and TC.USERCODE=T.LOGACTION)"+char(10)+char(9)+
	@sSQLJoin+"
	where T.LOGACTION='U'"+char(10)+char(9)+
	@sOrderBy

	If @pbPrintSQL = 1
	Begin
		-- Print out the executed SQL statement
		Print	''

		Print 	@sSQLString
	End

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnNameNo	int',
					  @pnNameNo=@pnNameNo
End

If @ErrorCode=0
Begin
	-- Now return the result set however if the data is marked as the After image and the
	-- logged action is an Update then suppress the data items that would be shown with the 
	-- before image.
	Set @sSQLString="
	Select	CASE WHEN(T.BEFOREORAFTER='AFTER' and T.LOGACTION='U') THEN NULL ELSE T.DATECHANGED	END as [DATECHANGED],
		CASE WHEN(T.BEFOREORAFTER='AFTER' and T.LOGACTION='U') THEN NULL ELSE T.TYPE		END as [TYPE],
		CASE WHEN(T.BEFOREORAFTER='AFTER' and T.LOGACTION='U') THEN NULL ELSE T.PROGRAM		END as [PROGRAM],
		CASE WHEN(T.BEFOREORAFTER='AFTER' and T.LOGACTION='U') THEN NULL ELSE T.USERID		END as [USERID],
		CASE WHEN(T.BEFOREORAFTER='AFTER' and T.LOGACTION='U') THEN NULL ELSE T.LOGINID		END as [LOGINID],
		CASE WHEN(T.BEFOREORAFTER='AFTER' and T.LOGACTION='U') THEN NULL ELSE T.STAFFNAME	END as [STAFFNAME],
		CASE WHEN(T.BEFOREORAFTER='AFTER' and T.LOGACTION='U') THEN NULL ELSE T.FIELD		END as [FIELD], 
		T.LOGTRANSNO									    as [LOGTRANSNO],
		T.AUDITDATA 									    as [AUDITDATA],
		T.PRIMARYKEY									    as [PRIMARYKEY],
		T.BEFOREORAFTER									    as [BEFOREORAFTER],
		-- SQA14701
		-- Report the sender's batchno and name if it exists
		EDE.SENDERREQUESTIDENTIFIER							    as [SENDERBATCH],
		CASE WHEN(N.NAMECODE) is not null THEN '{'+N.NAMECODE+'}'+N.NAME ELSE N.NAME END    as [SENDER],
		-- SQA11979
		-- The following columns are copies of other columns that were suppressed in the AFTER 
		-- image of an update however we need to still pass them to the calling program 
		-- unsuppressed for use in client side sorting
		T.DATECHANGED									    as [SORTDATECHANGED], 
		T.TYPE										    as [SORTTYPE], 
		T.PROGRAM									    as [SORTPROGRAM], 
		T.USERID									    as [SORTUSERID], 
		T.STAFFNAME									    as [SORTSTAFFNAME], 
		T.FIELD										    as [SORTFIELD],
		T.ROWNUMBER									    as [SORTROWNUMBER]	
	from #TEMPSORTEDRESULT T
	left join TRANSACTIONINFO TS	on (TS.LOGTRANSACTIONNO=T.LOGTRANSNO)
	left join EDESENDERDETAILS EDE	on (EDE.BATCHNO=TS.BATCHNO)
	left join NAME N		on (N.NAMENO=EDE.SENDERNAMENO)
	order by NEWORDER"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- reset the locking level

SET TRANSACTION ISOLATION LEVEL READ COMMITTED

Return @ErrorCode
GO

Grant execute on dbo.ip_ListAuditTrail to public
GO
