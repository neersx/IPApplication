-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_DataValidation 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_DataValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_DataValidation.'
	drop procedure dbo.ip_DataValidation
end
print '**** Creating procedure dbo.ip_DataValidation...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_DataValidation	
		@pnUserIdentityId		int,			-- Mandatory
		@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed	
		@psFunctionalArea		nchar(1)	= 'C',	-- The area of functionality the data validation is against
		@pnCaseId			int		= null,	-- Key of Case if it is being validated
		@pnNameNo			int		= null,	-- Key of Name if it is being validated
		@pnTransactionNo		int		= null,	-- The database transaction number if it is known
		@psTableName			nvarchar(60)	= null, -- Optional temporary table of Cases (CASEID) or Names (NAMENO) to be validated.
		@pbDeferredValidations		bit		= 0,	-- Tells the procedure to process any outstanding Validation Requests that were deferred
		@pbPrintFlag			bit		= 0,	-- Flag used in debugging to print out constructed SQL
		@pnBackgroundProcessId          int	        = null	-- Background Process Id 
		  
as
---PROCEDURE :	ip_DataValidation
-- VERSION :	20
-- DESCRIPTION:	This procedure is called to apply user defined "sanity checks".
--		One or more rules that have been defined within the DATAVALIDATION table
--		are matched against the data to be validated. If the rule has a Doc Item
--		associated with it then execution of that Doc Item will be checked to see
--		if a row is returned.  If so then this will cause a message to be sent
--		back to the calling procedure for display in the user interace.
--
--		NOTE :	The procedure may be called in various ways to apply the data validations
--		======	on a range of different records as per the following supplied parameters:
--
--			@psFunctionalArea='C'		The specific Case will be validated
--			@pnCaseId supplied		(deferred checks will be batched)
--
--			@psFunctionalArea='C'		The entire Cases table will be validated
--			@pnCaseId is null
--
--			@psFunctionalArea='C'		All of the Case rows whose CASEIDs exist in the
--			@pnCaseId is null		temporary table will be validated.
--			@psTableName supplied
--
--			@psFunctionalArea='N'		The specific Name will be validated
--			@pnNameNo supplied		(deferred checks will be batched)
--
--			@psFunctionalArea='N'		The entire Names table will be validated
--			@pnNameNo is null
--
--			@psFunctionalArea='N'		All of the Name rows whose NAMENOs exist in the
--			@pnNameNo is null		temporary table will be validated.
--			@psTableName supplied
--
--			@psFunctionalArea=NULL		Validation checks that are marked for deferred
--			@pbDeferredValidations=1	processing are batched when a specific Case or Name
--							is validated and finds a rule tagged for deferred
--							processing.  Calling the procedure with this flag
--							set will process all previously deferred requests. 
--------------------------------------------------------------------------------------------------------------
--		R U L E S   F O R   U S E R   D E F I N E D   V A L I D A T I O N   S Q L
--		-------------------------------------------------------------------------
--		Validation rules may be linked to user defined SQL to access whether the data is valid or not.
--		The following coding rules must be adhered to for the user define SQL to operate.
--
--		Types of SQL Allowed
--		====================
--			SELECT statement
--			SELECT that calls a User Defined Function
--			EXEC of a stored procedure
--
--		Input Parameters Allowed
--		========================
--			SELECT		=:CaseId	Mandatory for Case validation (no space after "=")
--					=:NameNo	Mandatory for Name validation (no space after "=")
--					LOGTRANSACTIONNO=:TransactionNo
--							Optional. If the SQL can be restricted to look at
--							data changed by the provided transaction no.  If no
--							transaction number is available then this code will
--							be replaced by "LOGDATETIMESTAMP is not null" at the
--							time of execution.
--
--			Stored Proc	4 paramaters are required in the definition of a stored procedure
--					used for validation. Each parameter is optional so should include
--					the "=NULL" to allow no value to be passed.
--					The parameters may be named anything as the procedure will not be 
--					called using named parameters. The purpose of the parameters must 
--					conform to the following :
--
--					Parameter 1	Either @pnCaseId OR @pnNameNo	INT	= NULL 
--							Identifies either a specific 
--							CASE or a specific NAME to be 
--							validated.
--
--					Parameter 2	@pnTransactionNo		INT	= NULL
--							Optionally identifies the
--							database transaction that
--							resulted in the validation. This
--							can then be used in the validation
--							to focus on specific data or
--							look at the audit logs to identify
--							specific changes.

--					Parameter 3	@psTableName			nvarchar(60)=NULL
--							If multiple Cases or Names are
--							to be validated then the NAME
--							of the table will be provided
--							that can be joined to on either
--							NAMENO or CASEID.
--
--					Parameter 4	@pnValidationId			INT	= NULL
--							This will be used in conjunction
--							with Parameter 3 when the name
--							of the table is provided. A
--							second column named VALIDATIONID
--							will exist in the name table.
--							Only rows from that table whose
--							VALIDATIONID matches the value
--							passed in this parameter are 
--							required to be validated by the
--							stored procedure.
--
--
--		Output Expected
--		===============
--			For either a direct SELECT or a call to a Stored Procedure the output must consist 
--			of two NAMED columns. The names of the columns can be anything as long as they are
--			used.
--			Examples :	Select C.CASEID as CASEID, 1 as Result
--					Select N.NAMENO, 'Email address must be entered' as Result
--
--			Multiple rows are allowed although repeating values should be
--			removed to ensure they are not repeated in the user interface.
--
--			Output is only required when the validation test has FAILED.
--			The columns returned do not require a specific name however their content must 
--			conform to the following:
--
--			Column 1	This column will identify the record the validation has occurred
--					against.  It will contain :
--						CASEID	- when Case(s) are being validated
--						NAMENO	- when Name(s) are being validated.
--					A value in this column indicates that the validation has failed. By
--					default the message to be returned to the user will be the message
--					that has been defined against the Data Validation rule in the field
--					called "Display Message". If language translation versions of this
--					message have been provided then the Display Message will be shown in
--					user required language.
--
--			Column 2	
--					An optional text message may be returned by the SELECT or stored procedure.
--					If a value is returned then it will replace the display message defined
--					against the Data Validation rule. The advantage of this approach is that the 
--					message can vary depending on specific data and can also embed 
--					data that was extracted from the record being validated.
--
--					No language translation occurs using this method.
--					One or more rows of data may be returned.
--					The message is effectively unlimited in size as it may return
--					a string of data as NVARCHAR(max) in length.
--
--			
--------------------------------------------------------------------------------------------------------------
--	
-- MODIFICATION
-- Date		Who	No	Version	Description
-- ====         ===	=== 	=======	=====================================================================
-- 20 Jul 2010	MF	9316	1	Procedure created.
-- 06 Sep 2010	MF	9316	2	Modifiy names of result columns
-- 21 Dec 2010	MF	10123	3	Correction to misspelt column OCCURRDFLAG which should be OCCURREDFLAG.
-- 10 Jan 2011	MF	10157	4	Certain columns used for matching the Data Validation rules to Cases
--					are to also include a NOT column to allow negative matching.
-- 21 Feb 2011  DV      100466  5       Store the result of the asynchrous call in a variable rather than returning it as a table.
-- 18 Mar 2011	MF	10378	6	When deferred requests are processed we need to return the UserIdentity of who originally
--					generated the request
-- 20 Mar 2011	MF	10379	7	Data validations that fail at the point of data entry or when deferred entries are processed,
--					are to write a log row to record the user that triggered the fail.
-- 31 Aug 2012	ASH	100753	8	Use NAMENO instead of CASEID for tables related to NAME.
-- 29 Nov 2012	MF	12990	9	Correction to code checking the logging tables for changes against made to a particular column. The
--					LOGTRANSACTIONNO column of the _iLOG table should have been joined to same column of the table being logged.
-- 28 May 2013	DL	10030	10	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 11 Jul 2013  SW      DR229   11      Changes for inserting SanityCheckResults in SanityCheckResult table
--                                      Applied null checks on generation of TransactionKey and updated BackgroundProcess Table   
-- 11 Jul 2013  SW      DR229   12      Reverted the reusability of from, where clause strings. 
-- 14 Oct 2014	DL	R39102	13	Use service broker instead of OLE Automation to run the command asynchronoulsly

-- 14 Oct 2015	MF	54079	13	The search of the DATAVALIDATION table to determine which rules to use, is not correctly ensuring that characteristics
--					matched on also have the exclude flag (e.g. NOTCASECATEGORY) turned off.
-- 25 Nov 2016	MF	69976	14	When searching for DATAVALIDATION rules for a particular USEDASFLAG value the query is usind the logical AND to check if the
--					same BIT value is turned on against the NAME row being validated. This concept does not work when the USEDBY flag in the
--					rule is 0 as everything will match.
-- 28 Dec 2016	MF	70286	15	The logic for matching on Status (Pending, Registered or Dead) is incorrect for Dead cases (StatusFlag=0).  Very similar bug as 
--					described above in RFC69976.
-- 12 Jan 2017	MF	69976	16	Revisit after test fail.  If the data validation rule is for a Client, then it must explicitly specify either Organisation or Individual.
--					The bug wsa that a Client Organisation was being treated as if it was Client for either an Organisation or an Individual.
-- 04 Aug 2017	MF	72112	17	Change the call to start asynchronous processing to use ipu_ScheduleAsyncCommand.
-- 24 Oct 2017	AK	R72645	18	Make compatible with case sensitive server with case insensitive database.
-- 07 Sep 2018	AV	74738	19	Set isolation level to read uncommited.
-- 23 Sep 2019	vql	DR50492	20	Non-deferred validations logging will be handled in the front end.
		
set nocount on
set concat_null_yields_null off
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Create Table #TEMPCOLUMNLIST(	TABLENAME	nvarchar(40)	collate database_default NOT NULL,
				COLUMNNAME	nvarchar(40)	collate database_default NOT NULL,
				TABLECODE	int		NOT NULL,
				MODIFIEDFLAG	bit		default(0),
				ROWNO		int		identity(1,1)
				)

Create Table #TEMPCASEEVENT(	EVENTNO		int		NOT NULL,
				CYCLE		int		NOT NULL,
				OCCURREDFLAG	tinyint		NOT NULL,
				ROWNO		int		identity(1,1)
				)

Create Table #TEMPCASENAME(	NAMETYPE	nvarchar(3)	collate database_default NOT NULL,
				NAMENO		int		NOT NULL,
				FAMILYNO	int		NULL,
				ROWNO		int		identity(1,1)
				)

Create Table #TEMPDATAVALIDATION(
				ROWNO		int		identity(1,1),
				VALIDATIONID	int		NOT NULL, 
				CASEID		int		NULL,
				NAMENO		int		NULL,
				DEFERREDFLAG	bit		NOT NULL, 
				IDENTITYID	int		NULL,
				SQL_QUERY	nvarchar(4000)	collate database_default NULL	-- Limited to 4000 so I can use REPLACE function
				)

Create Table #TEMPRESULT(	ROWNO		int		identity(1,1),
				VALIDATIONID	int		NULL,	-- Initially inserted with NULL and then subsequently updated.
				RECORDKEY	int		NOT NULL,
				RESULT		nvarchar(max)	collate database_default NOT NULL
				)

		 	
Declare	@ErrorCode		int
Declare	@TranCountStart		int
Declare	@nRowCount		int	
Declare @nCaseEventCount	int
Declare	@nCaseNameCount		int
Declare @nHomeNameNo		int
Declare	@nItemType		int
Declare	@nValidationId		int
Declare	@nObject		int
Declare @nRetry			int
Declare @nRowNo			int
Declare @nInsertOutput          int

Declare	@nObjectExist		bit


Declare @sLookupCulture		nvarchar(10)
Declare @sTableName		nvarchar(80)

Declare @sColumnList		nvarchar(1000)
Declare @sSQLProc		nvarchar(1000)
declare	@sCommand		varchar(max)
Declare @sSQLSelect		nvarchar(max)
Declare	@sSQLString		nvarchar(max)
Declare	@sSQLUpdate		nvarchar(max)
Declare @sSQLQuery		nvarchar(max)
Declare @sXMLString		nvarchar(max)		-- Deferred Validation Ids as XML
Declare	@sErrorMessage	        nvarchar(254)
Declare @sFromString	        nvarchar(max)
Declare @sOrderBy		nvarchar(max)
Declare @sOrderByCase           nvarchar(max)

------------------------------
--
-- I N I T I A L I S A T I O N
--
------------------------------
Set @ErrorCode = 0
Set @nRowCount = 0
Set @nCaseEventCount = 0
Set @nCaseNameCount  = 0
Set @sLookupCulture  = dbo.fn_GetLookupCulture(@psCulture, null, 0)

-----------------------------------------------
-- Get the transaction number currently held in
-- relation to the SPID. This will be available
-- to check audit log rows for data changes.
-- This is required if a specific Case or Name
-- is being validated.
-----------------------------------------------
If  @pnTransactionNo is null and @psTableName is null
and (@pnCaseId is not null OR @pnNameNo is not null)
and @ErrorCode = 0
Begin
	select	@pnTransactionNo=cast(substring(context_info,5,4)  as int)
	from master.dbo.sysprocesses
	where spid=@@SPID
	and substring(context_info,5, 4)<>0x0000000
	
	Set @ErrorCode=@@Error
End
--------------------------------------------------
--
-- P A R A M E T E R   V A L I D A T I O N
--
--------------------------------------------------
-- Validate the input parameters before attempting
-- to create the Case
--------------------------------------------------
If  @pnTransactionNo is null and @psTableName is null 
and (@pnCaseId is not null OR @pnNameNo is not null)
and @ErrorCode=0
Begin
	RAISERROR('No database transaction can be determined. The calling code must insert a row into TRANSACTIONINFO and load sysprocesses for the SPID', 14, 1)
	Set @ErrorCode = @@ERROR
End

If  @pnCaseId is not null
and @pnNameNo is not null
and @ErrorCode=0
Begin
	RAISERROR('Only one of the parameters @pnCaseId and @pnNameNo may have a value', 14, 1)
	Set @ErrorCode = @@ERROR
End

If  @psFunctionalArea not in ('C','N')
and @ErrorCode=0
Begin
	RAISERROR('The parameter @psFunctionalArea must have a value of "C" or "N" to validate against Cases or Names respectively', 14, 1)
	Set @ErrorCode = @@ERROR
End

----------------------------------------------------
--
-- W H A T   C O L U M N S   H A V E   R U L E S
--
----------------------------------------------------
-- Extract from the validation rules the specific 
-- Table.Column combinations that have been 
-- referenced in a rule. 
-- We will then check which of these have actually 
-- had data changed in this db transaction.
-- For a column to be eligible to be checked for 
-- changes it must have an _iLOG audit log table
-- or view in existence.
----------------------------------------------------
-- This is only performed when a specific Case or a
-- Name is being validated.
----------------------------------------------------
If @ErrorCode=0
and (@pnCaseId is not null OR @pnNameNo is not null)
Begin
	If @psFunctionalArea='N'
	Begin
		Set @sSQLString="
		insert into #TEMPCOLUMNLIST(TABLENAME,COLUMNNAME, TABLECODE)
		Select distinct substring(TC.DESCRIPTION,1,patindex('%.%',TC.DESCRIPTION)-1)  as TABLENAME,
				substring(TC.DESCRIPTION,  patindex('%.%',TC.DESCRIPTION)+1,80) as COLUMNNAME,
				TC.TABLECODE
		from DATAVALIDATION DV with (NOLOCK)
		join TABLECODES TC		  on (TC.TABLECODE =DV.COLUMNNAME)
		-- Logging table must exist
		join INFORMATION_SCHEMA.TABLES TB on (TB.TABLE_NAME=substring(TC.DESCRIPTION,1,patindex('%.%',TC.DESCRIPTION)-1)+'_iLOG')
		where patindex('%.%',TC.DESCRIPTION)>1
		and substring(TC.DESCRIPTION,1,patindex('%.%',TC.DESCRIPTION)-1)
			 in ('ADDRESS','ASSOCIATEDNAME','EMPLOYEE','INDIVIDUAL','IPNAME','NAME','NAMEADDRESS','NAMEALIAS','NAMEIMAGE',
			     'NAMEINSTRUCTIONS','NAMELANGUAGE','NAMETELECOM','NAMETEXT','ORGANISATION','TELECOMMUNICATION')
		order by TABLENAME, COLUMNNAME"
	End
	Else Begin
		Set @sSQLString="
		insert into #TEMPCOLUMNLIST(TABLENAME,COLUMNNAME, TABLECODE)
		Select distinct substring(TC.DESCRIPTION,1,patindex('%.%',TC.DESCRIPTION)-1)  as TABLENAME,
				substring(TC.DESCRIPTION,  patindex('%.%',TC.DESCRIPTION)+1,80) as COLUMNNAME,
				TC.TABLECODE
		from DATAVALIDATION DV with (NOLOCK)
		join TABLECODES TC                on (TC.TABLECODE =DV.COLUMNNAME)
		-- Logging table must exist
		join INFORMATION_SCHEMA.TABLES TB on (TB.TABLE_NAME=substring(TC.DESCRIPTION,1,patindex('%.%',TC.DESCRIPTION)-1)+'_iLOG')
		where patindex('%.%',TC.DESCRIPTION)>1
		and substring(TC.DESCRIPTION,1,patindex('%.%',TC.DESCRIPTION)-1)
			 in ('CASES','CASEBUDGET','CASECHECKLIST','CASEIMAGE','CASELOCATION','CASEEVENT','CASENAME','CASETEXT','PROPERTY','RELATEDCASE')
		order by TABLENAME, COLUMNNAME"
	End

	Exec @ErrorCode=sp_executesql @sSQLString

	Set @nRowCount=@@Rowcount
End

--------------------------------------------
-- Get the name of the first table that has
-- columns defined in the validation rules
--------------------------------------------
If  @nRowCount>0
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sTableName=TABLENAME
	from #TEMPCOLUMNLIST
	where ROWNO=1"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sTableName	nvarchar(80)	OUTPUT',
				  @sTableName=@sTableName	OUTPUT

	-- Reset the Row Count
	Set @nRowCount=0
End

----------------------------------------------------
--
-- W H A T   C O L U M N S   H A V E   C H A N G E D
--
----------------------------------------------------
-- Loop through each of the columns included in the
-- Data Validation rules and update the Modified 
-- Flag for those where data has been modified for
-- that column.
----------------------------------------------------
While @sTableName is not null
  and @ErrorCode=0
Begin
	---------------------------------------------------
	-- For each table that has defined a column within
	-- the data validation rules, generate SQL to check
	-- if that column was modified or inserted during
	-- the database transaction.
	---------------------------------------------------
	Set @sSQLString=null

	SELECT @sSQLString = CASE WHEN(@sSQLString is not null)  THEN @sSQLString+char(10)+
								      "			 or   T.COLUMNNAME=CASE WHEN(checksum(C."
								 ELSE "			      T.COLUMNNAME=CASE WHEN(checksum(C."
			     END + COLUMNNAME+")<>checksum(L."+COLUMNNAME+") OR (L.LOGACTION='I' and C."+COLUMNNAME+" is not null)) THEN '"+COLUMNNAME+"' END"
	FROM #TEMPCOLUMNLIST
	WHERE TABLENAME = @sTableName
	order by COLUMNNAME

	Set @ErrorCode=@@Error
	---------------------------------
	-- Check the data associated with
	-- the Case functional areas.
	---------------------------------
	If  @psFunctionalArea='C'
	and @pnCaseId is not null
	and @ErrorCode=0
	Begin

		-----------------------------------
		-- Construct the SQL that will 
		-- check the specific table for the
		-- columns that have been modified
		-- and update the Column List if
		-- the column has been updated.
		-----------------------------------
		If @sTableName in ('CASES','PROPERTY','CASELOCATION','CASEIMAGE')
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from "+@sTableName+" C
			join "+@sTableName+"_iLOG L	on (L.CASEID=C.CASEID
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='"+@sTableName+"')
			Where C.CASEID=@pnCaseId
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End
		Else
		If @sTableName in ('CASECHECKLIST')
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from CASECHECKLIST C
			join CASECHECKLIST_iLOG L on (L.CASEID=C.CASEID
						and L.QUESTIONNO=C.QUESTIONNO
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='CASECHECKLIST')
			Where C.CASEID=@pnCaseId
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End
		Else
		If @sTableName in ('CASEEVENT')
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from CASEEVENT C
			join CASEEVENT_iLOG L	on (L.CASEID=C.CASEID
						and L.EVENTNO=C.EVENTNO
						and L.CYCLE  =C.CYCLE
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='CASEEVENT')
			Where C.CASEID=@pnCaseId
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End
		Else
		If @sTableName in ('CASENAME')
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from CASENAME C
			join CASENAME_iLOG L	on (L.CASEID=C.CASEID
						and L.NAMETYPE=C.NAMETYPE
						and L.NAMENO=C.NAMENO
						and L.SEQUENCE=C.SEQUENCE
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='CASENAME')
			Where C.CASEID=@pnCaseId
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End
		Else
		If @sTableName in ('CASETEXT')
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from CASETEXT C
			join CASETEXT_iLOG L	on (L.CASEID=C.CASEID
						and L.TEXTTYPE=C.TEXTTYPE
						and L.TEXTNO=C.TEXTNO
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='CASETEXT')
			Where C.CASEID=@pnCaseId
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End
		Else
		If @sTableName in ('OFFICIALNUMBERS')
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from OFFICIALNUMBERS C
			join OFFICIALNUMBERS_iLOG L on (L.CASEID=C.CASEID
						and L.NUMBERTYPE=C.NUMBERTYPE
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='OFFICIALNUMBERS')
			Where C.CASEID=@pnCaseId
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End
		Else
		If @sTableName in ('RELATEDCASE')
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from RELATEDCASE C
			join RELATEDCASE_iLOG L on (L.CASEID=C.CASEID
						and L.RELATIONSHIPNO=C.RELATIONSHIPNO
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='RELATEDCASE')
			Where C.CASEID=@pnCaseId
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End
		
		If @pbPrintFlag=1
		Begin
			PRINT ''
			PRINT @sSQLString
		End

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnCaseId		int,
						  @pnTransactionNo	int',
						  @pnCaseId       =@pnCaseId,
						  @pnTransactionNo=@pnTransactionNo

		Set @nRowCount=@nRowCount+@@rowcount
	End
	---------------------------------
	-- Check the data associated with
	-- the Name functional areas.
	---------------------------------
	Else If  @psFunctionalArea='N'
	     and @pnNameNo is not null
	     and @ErrorCode=0
	Begin
		-----------------------------------
		-- Construct the SQL that will 
		-- check the specific table for the
		-- columns that have been modified
		-- and update the Column List if
		-- the column has been updated.
		-----------------------------------

		If @sTableName in ('ASSOCIATEDNAME','INDIVIDUAL','IPNAME','NAME','NAMEADDRESS','NAMEALIAS','NAMEIMAGE','NAMEINSTRUCTIONS','NAMELANGUAGE',
				   'NAMETELECOM','NAMETEXT','ORGANISATION')
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from "+@sTableName+" C
			join "+@sTableName+"_iLOG L	on (L.NAMENO=C.NAMENO
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='"+@sTableName+"')
			Where C.CASEID=@pnNameNo
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End
		Else
		If @sTableName='EMPLOYEE'
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from EMPLOYEE C
			join EMPLOYEE_iLOG L	on (L.EMPLOYEENO=C.EMPLOYEENO
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='EMPLOYEE')
			Where C.EMPLOYEENO=@pnNameNo
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End
		Else
		If @sTableName='ADDRESS'
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from ADDRESS C
			join NAMEADDRESS NA	on (NA.ADDRESSCODE=C.ADDRESSCODE_
			join ADDRESS_iLOG L	on (L.ADDRESSCODE=C.ADDRESSCODE
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='ADDRESS')
			Where NA.NAMENO=@pnNameNo
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End
		Else
		If @sTableName='TELECOMMUNICATION'
		Begin
			Set @sSQLString="
			Update T
			Set MODIFIEDFLAG=1
			from TELECOMMUNICATION C
			join NAMETELECOM NT	on (NT.TELECODE=C.TELECODE
			join TELECOMMUNICATION_iLOG L
						on (L.TELECODE=C.TELECODE
						and L.LOGTRANSACTIONNO=C.LOGTRANSACTIONNO)
			join #TEMPCOLUMNLIST T	on (T.TABLENAME='ADDRESS')
			Where NT.NAMENO=@pnNameNo
			and   C.LOGTRANSACTIONNO=@pnTransactionNo
			and (" + @sSQLString + ")"
		End

		If @pbPrintFlag=1
		Begin
			PRINT ''
			PRINT @sSQLString
		End

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnNameNo		int,
						  @pnTransactionNo	int',
						  @pnNameNo       =@pnNameNo,
						  @pnTransactionNo=@pnTransactionNo

		Set @nRowCount=@nRowCount+@@rowcount
	End
	----------------------------------
	-- Get the next TABLENAME that has
	-- Columns defined in the data
	-- validation rules.
	----------------------------------
	Set @sSQLString="
	Select @sTableName=min(TABLENAME)
	from #TEMPCOLUMNLIST
	where TABLENAME>@sTableName"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sTableName	nvarchar(80)	OUTPUT',
				  @sTableName=@sTableName	OUTPUT
End

-------------------------------------------
-- String together a list of the tablecodes
-- that represent the database columns that
-- have changed.
-------------------------------------------
If  @nRowCount>0
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sColumnList=CASE WHEN(@sColumnList is NULL) THEN convert(varchar,T.TABLECODE) ELSE @sColumnList+','+convert(varchar,T.TABLECODE) END
	From #TEMPCOLUMNLIST T
	Where MODIFIEDFLAG=1"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sColumnList	nvarchar(1000)	output',
				  @sColumnList=@sColumnList	output
End	

--------------------------------------------
--
-- W H A T   D A T A   H A S   C H A N G E D
--
--------------------------------------------
-- Data Validation rules may be defined that
-- are specific to certain explicit data:
--	EVENTNO;
--	NAMETYPE, NAMENO
-- If rules exist for these then we need to
-- capture the specific data values that
-- are to be checked for validation.
--------------------------------------------
-- This only applies if a specific Case has
-- just been updated and is being validated.
--------------------------------------------
If  @psFunctionalArea='C'
and @pnCaseId is not null
and @ErrorCode=0
Begin
	------------------------------
	-- Get details of CaseEvents
	-- that have changed if a rule
	-- exists for the EventNo.
	------------------------------
	If exists(select 1 from DATAVALIDATION with (NOLOCK) where EVENTNO is not null)
	Begin
		Set @sSQLString="
		Insert into #TEMPCASEEVENT(EVENTNO, CYCLE, OCCURREDFLAG)
		Select distinct CE.EVENTNO, CE.CYCLE, CE.OCCURREDFLAG
		from DATAVALIDATION DV with (NOLOCK)
		join CASEEVENT CE on (CE.EVENTNO=DV.EVENTNO)
		where CE.CASEID=@pnCaseId
		and CE.LOGTRANSACTIONNO=@pnTransactionNo"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCaseId		int,
					  @pnTransactionNo	int',
					  @pnCaseId		=@pnCaseId,
					  @pnTransactionNo	=@pnTransactionNo

		Set @nCaseEventCount=@@Rowcount
	End

	------------------------------
	-- Get details of CASENAMEs
	-- that have rules defined.
	-- These are not restricted to
	-- the TransactioNo.
	------------------------------
	If exists(select 1 from DATAVALIDATION with (NOLOCK) where  FUNCTIONALAREA='C' and (NAMETYPE is not null OR NAMENO is not null OR FAMILYNO is not null))
	Begin
		Set @sSQLString="
		Insert into #TEMPCASENAME (NAMETYPE, NAMENO, FAMILYNO)
		Select distinct CN.NAMETYPE, CN.NAMENO, N.FAMILYNO
		from DATAVALIDATION DV with (NOLOCK)
		join CASENAME CN on ((CN.NAMETYPE=DV.NAMETYPE and CN.NAMENO=DV.NAMENO)
				   or(CN.NAMETYPE=DV.NAMETYPE and DV.NAMENO   is null)
				   or(CN.NAMENO  =DV.NAMENO   and DV.NAMETYPE is null)
				   or DV.FAMILYNO is not null)
		join NAME N      on (  N.NAMENO  =CN.NAMENO
				 and ( N.FAMILYNO=DV.FAMILYNO or DV.FAMILYNO  is null))
		where CN.CASEID=@pnCaseId
		and DV.FUNCTIONALAREA='C'"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCaseId		int',
					  @pnCaseId		=@pnCaseId

		Set @nCaseNameCount=@@Rowcount
	End
End

--------------------------------------------------
--
-- G E T   T H E   D A T A   V A L I D A T I O N S
--
--------------------------------------------------
-- Now that we know the database columns that have
-- changed and the relevant data values that have
-- changed, we can now determine the defined
-- Data Validation checks to be executed.
--------------------------------------------------
If @ErrorCode=0
Begin
	---------------------------------------
	-- First prepare the SQL SELECT from
	-- the ITEM ready to execute.
	-- Replace any embedded parameters in
	-- the user defined SQL with the values
	-- associated with the data to be 
	-- validated. 
	---------------------------------------
	-- The user defined SELECT may include
	-- the following parameters:
	--	@pnTransactionNo	int
	--	@pnCaseId		int
	--	@pnNameNo		int
	---------------------------------------

	If @pnTransactionNo is not null
		Set @sSQLSelect="replace(cast(IT.SQL_QUERY as nvarchar(4000)), ':TransactionNo',"+ isnull(cast(@pnTransactionNo as varchar),'')+")"
	Else
		Set @sSQLSelect="replace(cast(IT.SQL_QUERY as nvarchar(4000)), 'LOGTRANSACTIONNO=:TransactionNo','LOGDATETIMESTAMP is not null')"

	If  @pnCaseId is null
	and @pnNameNo is null
	Begin
		--------------------------------------
		-- If a single specific Case or Name
		-- is not being validated then use the
		-- NAMENO or CASEID from the table
		-- #TEMPDATAVALIDATION.
		--------------------------------------
		If  @psFunctionalArea='C'
		OR  @pbDeferredValidations=1
			Set @sSQLSelect="replace("+@sSQLSelect+", '=:CaseId',' in (select CASEID from #TEMPDATAVALIDATION where VALIDATIONID='+cast(DV.VALIDATIONID as nvarchar)+')')"
		
		If  @psFunctionalArea='N'
		OR  @pbDeferredValidations=1
			Set @sSQLSelect="replace("+@sSQLSelect+", '=:NameNo',' in (select NAMENO from #TEMPDATAVALIDATION where VALIDATIONID='+cast(DV.VALIDATIONID as nvarchar)+')')"

	End
	Else Begin
		If @pnCaseId is not null
			Set @sSQLSelect="replace("+@sSQLSelect+", ':CaseId',"+cast(@pnCaseId as varchar)+")"

		If @pnNameNo is not null
			Set @sSQLSelect="replace("+@sSQLSelect+", ':NameNo',"+cast(@pnNameNo as varchar)+")"
	End

	Set @sSQLSelect="Insert into #TEMPRESULT(RECORDKEY,RESULT)"+char(10)+char(9)+char(9)+char(9)+char(9)+
			"Select X.*"+char(10)+char(9)+char(9)+char(9)+char(9)+
			"from ("+'"+'+@sSQLSelect+'+"'+") X"

	-------------------------------
	-- Now construct the SQL to use
	-- if the ITEM is pointing to
	-- a stored procedure to call.
	-------------------------------
	If  @pnCaseId is null
	and @pnNameNo is null
	Begin
		Set @sSQLProc=	'Insert into #TEMPRESULT(RECORDKEY,RESULT) exec "+cast(IT.SQL_QUERY as nvarchar(4000))+" DEFAULT, DEFAULT,'+"'#TEMPDATAVALIDATION',"+'"+'+'cast(DV.VALIDATIONID as nvarchar)'
	End
	Else Begin
		Set @sSQLProc=	'Insert into #TEMPRESULT(RECORDKEY,RESULT) exec "+cast(IT.SQL_QUERY as nvarchar(4000))+"'+"'"+cast(isnull(@pnCaseId,@pnNameNo) as varchar)+"','"+isnull(cast(@pnTransactionNo as varchar),'')+"'"+'"'
	End
End

If  @pbDeferredValidations=1
and @ErrorCode=0
Begin
	-----------------------------
	-- Data Validations that have 
	-- previously been deferred.
	-----------------------------
	Set @sSQLString="
	Insert into #TEMPDATAVALIDATION(VALIDATIONID, CASEID, NAMENO, DEFERREDFLAG, IDENTITYID, SQL_QUERY)
	Select  DV.VALIDATIONID,
		C.CASEID,
		N.NAMENO,
		0,
		DR.LOGIDENTITYID,"

	Set @sSQLString=+@sSQLString+"
		CASE WHEN(IT.ITEM_TYPE=0)
			THEN "+'"'+@sSQLSelect+'"'+"
		     WHEN(IT.ITEM_TYPE>0)
			THEN "+'"'+@sSQLProc+"
		END
	from DATAVALIDATIONREQUEST DR
	join DATAVALIDATION DV on (DV.VALIDATIONID=DR.VALIDATIONID)
	left join CASES C on (C.CASEID=DR.CASEID)
	left join NAME  N on (N.NAMENO=DR.NAMENO)
	left join ITEM IT		on (IT.ITEM_ID=DV.ITEM_ID)
	left join INSTRUCTIONFLAG I	on (I.INSTRUCTIONCODE=dbo.fn_StandingInstruction (C.CASEID,DV.INSTRUCTIONTYPE)
					and I.FLAGNUMBER     =DV.FLAGNUMBER)
	Where DV.INUSEFLAG = 1"

End
Else If  @psFunctionalArea='C'
     and @pbDeferredValidations=0
     and @ErrorCode=0
Begin
	-----------------------------
	-- Date Validations for Cases
	-----------------------------
	Set @sSQLString="
	Insert into #TEMPDATAVALIDATION(VALIDATIONID, CASEID, DEFERREDFLAG, SQL_QUERY)
	Select  DISTINCT
		DV.VALIDATIONID,
		C.CASEID,"

	If @pnCaseId is not null
		----------------------------------
		-- Deferred validations only apply
		-- to Case specific validations.
		----------------------------------
		Set @sSQLString=@sSQLString+"
		DV.DEFERREDFLAG,"
	Else
		Set @sSQLString=@sSQLString+"
		0,"

	Set @sSQLString=+@sSQLString+"
		CASE WHEN(IT.ITEM_TYPE=0)
			THEN "+'"'+@sSQLSelect+'"'+"
		     WHEN(IT.ITEM_TYPE>0)
			THEN "+'"'+@sSQLProc+"
		END
	from CASES C"

	---------------------------------------------
	-- If restricted table of Cases is being
	-- validated then JOIN to the temporary table
	---------------------------------------------
	If @psTableName is not null
		Set @sSQLString=@sSQLString+char(10)+char(9)+"join "+@psTableName+" T on (T.CASEID=C.CASEID)"

	Set @sSQLString=@sSQLString+"
	left join PROPERTY P on (P.CASEID=C.CASEID)
	left join STATUS CS  on (CS.STATUSCODE=C.STATUSCODE)
	left join STATUS RS  on (RS.STATUSCODE=P.RENEWALSTATUS)"

	If @nCaseEventCount>0
		Set @sSQLString=@sSQLString+char(10)+"	cross join #TEMPCASEEVENT CE"

	If @nCaseNameCount>0
		Set @sSQLString=@sSQLString+char(10)+"	cross join #TEMPCASENAME CN"

	
	Set @sSQLString=@sSQLString++"
	cross join DATAVALIDATION DV
	left  join ITEM IT		on (IT.ITEM_ID=DV.ITEM_ID)
	left  join INSTRUCTIONFLAG I	on (I.INSTRUCTIONCODE=dbo.fn_StandingInstruction (C.CASEID,DV.INSTRUCTIONTYPE)
					and I.FLAGNUMBER     =DV.FLAGNUMBER)
	Where DV.INUSEFLAG     = 1
	and (DV.FUNCTIONALAREA ='C'               or DV.FUNCTIONALAREA  is null)
	and (DV.OFFICEID       =C.OFFICEID        or DV.OFFICEID        is null)
	and ((DV.CASETYPE       =C.CASETYPE     and isnull(DV.NOTCASETYPE,    0)=0) or DV.CASETYPE        is null or (DV.NOTCASETYPE=1     AND DV.CASETYPE    <> C.CASETYPE))
	and ((DV.COUNTRYCODE    =C.COUNTRYCODE  and isnull(DV.NOTCOUNTRYCODE, 0)=0) or DV.COUNTRYCODE     is null or (DV.NOTCOUNTRYCODE=1  AND DV.COUNTRYCODE <> C.COUNTRYCODE))
	and ((DV.PROPERTYTYPE   =C.PROPERTYTYPE and isnull(DV.NOTPROPERTYTYPE,0)=0) or DV.PROPERTYTYPE    is null or (DV.NOTPROPERTYTYPE=1 AND DV.PROPERTYTYPE<> C.PROPERTYTYPE))
	and ((DV.CASECATEGORY   =C.CASECATEGORY and isnull(DV.NOTCASECATEGORY,0)=0) or DV.CASECATEGORY    is null or (DV.NOTCASECATEGORY=1 AND DV.CASECATEGORY<> isnull(C.CASECATEGORY,'')))
	and ((DV.SUBTYPE        =C.SUBTYPE      and isnull(DV.NOTSUBTYPE,     0)=0) or DV.SUBTYPE         is null or (DV.NOTSUBTYPE=1      AND DV.SUBTYPE     <> isnull(C.SUBTYPE,     '')))
	and ((DV.BASIS          =P.BASIS        and isnull(DV.NOTBASIS,       0)=0) or DV.BASIS           is null or (DV.NOTBASIS=1        AND DV.BASIS       <> isnull(P.BASIS,       '')))
	and (DV.LOCALCLIENTFLAG=C.LOCALCLIENTFLAG or DV.LOCALCLIENTFLAG is null)
	and (DV.FLAGNUMBER     =I.FLAGNUMBER      or DV.FLAGNUMBER      is null)
	-- STATUSFLAG  0 = Dead; 1 = Pending; 2 = Registered
	and ((DV.STATUSFLAG=0 AND (CS.LIVEFLAG=0 OR RS.LIVEFLAG=0))								-- Dead
	 OR  (DV.STATUSFLAG=1 AND ISNULL(CS.LIVEFLAG,1)=1  AND ISNULL(RS.LIVEFLAG,1)=1 AND ISNULL(CS.REGISTEREDFLAG,0)=0)	-- Pending
	 OR  (DV.STATUSFLAG=2 AND ISNULL(CS.LIVEFLAG,1)=1  AND ISNULL(RS.LIVEFLAG,1)=1 AND ISNULL(CS.REGISTEREDFLAG,0)=1)	-- Registered	
	 OR  (DV.STATUSFLAG=3 AND ISNULL(CS.LIVEFLAG,1)=1  AND ISNULL(RS.LIVEFLAG,1)=1)						-- Pending or Registered (just need to test Case is live)
	 OR   DV.STATUSFLAG is null)
	 "

	If @pnCaseId is not null
		Set @sSQLString=@sSQLString+char(10)+
		"	and C.CASEID=@pnCaseId	"

	-----------------------------------------------
	-- If a single Case is being validated then the
	-- specific columns found to have changed will
	-- be considered.
	-- If multiple Cases are being validated then
	-- all validation rules restricted to specific
	-- columns and values will also be considered.
	-----------------------------------------------
	If @nCaseNameCount>0
		Set @sSQLString=@sSQLString+char(10)+
		"	and (DV.FAMILYNO       =CN.FAMILYNO       or DV.FAMILYNO       is null)"+char(10)+
		"	and (DV.NAMENO         =CN.NAMENO         or DV.NAMENO         is null)"+char(10)+
		"	and (DV.NAMETYPE       =CN.NAMETYPE       or DV.NAMETYPE       is null)"
	Else 
	If @pnCaseId is not null
		Set @sSQLString=@sSQLString+char(10)+
		"	and DV.FAMILYNO is null"+char(10)+
		"	and DV.NAMENO   is null"+char(10)+
		"	and DV.NAMETYPE is null"

	If @nCaseEventCount>0
		Set @sSQLString=@sSQLString+char(10)+
		"	and (DV.EVENTNO        =CE.EVENTNO        or DV.EVENTNO         is null)"+char(10)+
		"	and((DV.EVENTDATEFLAG  =1 and CE.OCCURREDFLAG=1) or (DV.EVENTDATEFLAG=2 and CE.OCCURREDFLAG=0) or (DV.EVENTDATEFLAG=3 and CE.OCCURREDFLAG<9) or DV.EVENTDATEFLAG is null)"
	Else
	If @pnCaseId is not null
		Set @sSQLString=@sSQLString+char(10)+
		"	and DV.EVENTNO       is null"+char(10)+
		"	and DV.EVENTDATEFLAG is null"

	If @sColumnList is not null
		Set @sSQLString=@sSQLString+char(10)+
		"	and (DV.COLUMNNAME in ("+@sColumnList+") or DV.COLUMNNAME is null)"
	Else 
	If @pnCaseId is not null
		Set @sSQLString=@sSQLString+char(10)+
		"	and DV.COLUMNNAME is null"
End
ELSE If  @psFunctionalArea='N'
     and @pbDeferredValidations=0
     and @ErrorCode=0
Begin
	---------------------------
	-- Get the HomeNameNo so it
	-- can be used when getting
	-- the Standing Instruction
	---------------------------
	Set @sSQLString="
	Select @nHomeNameNo=COLINTEGER
	From   SITECONTROL
	where  CONTROLID='HOMENAMENO'"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nHomeNameNo		int	OUTPUT',
				  @nHomeNameNo=@nHomeNameNo	OUTPUT

	-----------------------------
	-- Date Validations for Names
	-----------------------------
	Set @sSQLString="
	Insert into #TEMPDATAVALIDATION(VALIDATIONID, NAMENO, DEFERREDFLAG, SQL_QUERY)
	Select	DISTINCT
		DV.VALIDATIONID,
		N.NAMENO,"

	If @pnNameNo is not null
		----------------------------------
		-- Deferred validations only apply
		-- to Name specific validations.
		----------------------------------
		Set @sSQLString=@sSQLString+"
		DV.DEFERREDFLAG,"
	Else
		Set @sSQLString=@sSQLString+"
		0,"

	Set @sSQLString=+@sSQLString+"
		CASE WHEN(IT.ITEM_TYPE=0)
			THEN "+'"'+@sSQLSelect+'"'+"
		     WHEN(IT.ITEM_TYPE>0)
			THEN "+'"'+@sSQLProc+"
		END
	from NAME N"

	---------------------------------------------
	-- If restricted table of Names is being
	-- validated then JOIN to the temporary table
	---------------------------------------------
	If @psTableName is not null
		Set @sSQLString=@sSQLString+char(10)+char(9)+"join "+@psTableName+" T on (T.NAMENO=N.NAMENO)"

	Set @sSQLString=@sSQLString+"
	left join ADDRESS A		on (A.ADDRESSCODE=N.STREETADDRESS)
	left join IPNAME IP		on (IP.NAMENO=N.NAMENO)
	cross join DATAVALIDATION DV
	left  join ITEM IT		on (IT.ITEM_ID=DV.ITEM_ID)
	left  join INSTRUCTIONFLAG I	on (I.INSTRUCTIONCODE=dbo.fn_StandingInstructionForName (N.NAMENO,DV.INSTRUCTIONTYPE,@nHomeNameNo)
					and I.FLAGNUMBER     =DV.FLAGNUMBER)
	Where DV.INUSEFLAG     = 1
	and (DV.FUNCTIONALAREA ='N'                or DV.FUNCTIONALAREA  is null)
	and (DV.NAMENO         =N.NAMENO           or DV.NAMENO          is null)
	and (DV.COUNTRYCODE    =A.COUNTRYCODE      or DV.COUNTRYCODE     is null)
	and (DV.LOCALCLIENTFLAG=IP.LOCALCLIENTFLAG or DV.LOCALCLIENTFLAG is null)
	and (DV.FAMILYNO       =N.FAMILYNO         or DV.FAMILYNO        is null)	
	and (DV.SUPPLIERFLAG   =N.SUPPLIERFLAG     or DV.SUPPLIERFLAG    is null)	
	and (DV.CATEGORY       =IP.CATEGORY        or DV.CATEGORY        is null)	
	and (DV.FLAGNUMBER     =I.FLAGNUMBER       or DV.FLAGNUMBER      is null)
	and((DV.USEDASFLAG=0 and N.USEDASFLAG in (0,4,8,12,16))
	  OR(DV.USEDASFLAG=1 and N.USEDASFLAG in (1,3,5))
	  OR(DV.USEDASFLAG=2 and N.USEDASFLAG in (2,3))
	  OR(DV.USEDASFLAG=3 and N.USEDASFLAG in (3))
	  OR(DV.USEDASFLAG=4 and N.USEDASFLAG in (4))
	  OR(DV.USEDASFLAG=5 and N.USEDASFLAG in (5))
	  OR(DV.USEDASFLAG>5 and (DV.USEDASFLAG & N.USEDASFLAG)=DV.USEDASFLAG)
                                                   or DV.USEDASFLAG      is null)"

	If @pnNameNo is not null
		Set @sSQLString=@sSQLString+char(10)+
		"	and N.NAMENO=@pnNameNo"

	If @sColumnList is not null
		Set @sSQLString=@sSQLString+char(10)+
		"	and (DV.COLUMNNAME in ("+@sColumnList+") or DV.COLUMNNAME is null)"
	Else 
	If @pnNameNo is not null
		Set @sSQLString=@sSQLString+char(10)+
		"	and DV.COLUMNNAME is null"
End

If @ErrorCode=0
Begin
	----------------------------------
	-- Append an ORDER BY clause so all
	-- rows with the same VALIDATIONID
	-- are contiguous.
	----------------------------------
	Set @sSQLString=@sSQLString+"
	Order By DV.VALIDATIONID"

	----------------------------------
	-- Execute the constructed SQL
	-- to return the Data Validatation
	-- rules to be applied.
	----------------------------------
	If @pbPrintFlag=1
	Begin
		PRINT ''
		PRINT @sSQLString
	End

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnNameNo		int,
					  @pnCaseId		int,
					  @nHomeNameNo		int',
					  @pnNameNo   =@pnNameNo,
					  @pnCaseId   =@pnCaseId,
					  @nHomeNameNo=@nHomeNameNo
	--------------------------------
	-- The number of Data Validation
	-- rows returned
	--------------------------------
	Set @nRowCount=@@rowcount
End

--------------------------------------------------
--
-- E X E C U T E   U S E R   D E F I N E D   S Q L
--
--------------------------------------------------
If  @nRowCount>0
and @ErrorCode=0
Begin
	---------------------------------------
	-- Get the first Data Validation row
	-- that has user defined SQL associated
	-- with it.
	---------------------------------------
	If @ErrorCode=0
	Begin
		Set @nRowNo = null

		Set @sSQLString="
		Select @sSQLQuery    =T.SQL_QUERY, 
		       @nRowNo       =T.ROWNO,
		       @nValidationId=T.VALIDATIONID
		from #TEMPDATAVALIDATION T
		where T.ROWNO = (select min(T1.ROWNO)
				 from #TEMPDATAVALIDATION T1
				 where SQL_QUERY is not null
				 and isnull(T1.DEFERREDFLAG,0)=0)"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nValidationId	int		OUTPUT,
					  @nRowNo		int		OUTPUT,
					  @sSQLQuery		nvarchar(4000)	OUTPUT',
					  @nValidationId=@nValidationId		OUTPUT,
					  @nRowNo	=@nRowNo		OUTPUT,
					  @sSQLQuery	=@sSQLQuery		OUTPUT
	End

	--------------------------------------
	-- Initialise the SQL that will update 
	-- each inserted #TEMPRESULT row with 
	-- the ValidationId that applies.
	--------------------------------------
	Set @sSQLUpdate='Update #TEMPRESULT set VALIDATIONID=@nValidationId where VALIDATIONID is null'

	------------------------------------
	-- Loop through each data validation 
	-- with SQL associated with it so 
	-- that it can be executed.
	------------------------------------
	While @nRowNo is not null
	and   @ErrorCode=0
	Begin
		----------------------------------------
		-- Now that specific validation checks
		-- have been identified we will need to 
		-- execute any associated SQL to test
		-- if that Validation Check has failed.
		----------------------------------------
		-- The SQL may be a SELECT statement or
		-- a stored procedure however they have
		-- both been appended to Insert a result
		-- into the temporary table #TEMPRESULT.
		-- Multiple rows may be returned.
		----------------------------------------
		If @pbPrintFlag=1
		Begin
			PRINT ''
			PRINT @sSQLQuery
		End


		exec @ErrorCode=sp_executesql @sSQLQuery

		Set @nRowCount=@@Rowcount

		If @nRowCount>0
		and @ErrorCode=0
		Begin
			-------------------------------------------
			-- Now update the newly inserte #TEMPRESULT
			-- rows with the VALIDATIONID that applies.
			-------------------------------------------
			exec @ErrorCode=sp_executesql @sSQLUpdate,
						N'@nValidationId	int',
						  @nValidationId=@nValidationId
		End

		---------------------------------------
		-- Get the next Data Validation row
		-- that has user defined SQL associated
		-- with it.
		---------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSQLQuery    =T.SQL_QUERY, 
			       @nRowNo       =T.ROWNO,
			       @nValidationId=T.VALIDATIONID
			from #TEMPDATAVALIDATION T
			where T.ROWNO = (select min(T1.ROWNO)
					 from #TEMPDATAVALIDATION T1
					 where SQL_QUERY is not null
					 and isnull(T1.DEFERREDFLAG,0)=0
					 and T1.ROWNO>@nRowNo
					 and T1.VALIDATIONID>@nValidationId)"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nValidationId	int		OUTPUT,
						  @nRowNo		int		OUTPUT,
						  @sSQLQuery		nvarchar(4000)	OUTPUT',
						  @nValidationId=@nValidationId		OUTPUT,
						  @nRowNo	=@nRowNo		OUTPUT,
						  @sSQLQuery	=@sSQLQuery		OUTPUT

			Set @nRowCount=@@RowCount

			If @nRowCount=0
				Set @nRowNo=null
		End
	End -- End of WHILE Loop
End
----------------------------------------
--
-- D E F E R R E D   V A L I D A T I O N
--
----------------------------------------
If @ErrorCode=0
Begin
	-----------------------------------
	-- Extract any Validation rules that
	-- have deferred checking into a
	-- variable, formatted as XML.
	-----------------------------------
	set @sXMLString=convert(nvarchar(max),
		(Select VALIDATIONID
		from #TEMPDATAVALIDATION
		where DEFERREDFLAG=1
		order by VALIDATIONID
		for XML Path(''), Root('DeferredValidation'), TYPE))

	Set @ErrorCode=@@Error
	
	If @sXMLString is not null
	and @ErrorCode is not null
	Begin
		--------------------------------------
		-- Send the extracted data to a stored 
		-- procedure where it will be inserted
		-- into a table for later processing.
		--------------------------------------
		-- The procedure will be started as a
		-- separate asynchronous process so as
		-- to not be impacted by a ROLLBACK
		-- that might be issued by the calling
		-- procedure of this Stored Procedure.
		--------------------------------------

		--------------------------------------
		-- Build command line to run procedure 
		-- using Service Broker (rfc39102)
		--------------------------------------
		            
		Set @sCommand = 'dbo.ip_InsertDataValidation '

		Set @sCommand = @sCommand + "'" + convert(varchar,@pnUserIdentityId) + "',"

		If @pnCaseId is null
			Set @sCommand = @sCommand + 'null,'
		else
			Set @sCommand = @sCommand + convert(varchar,@pnCaseId) + ','

		If @pnNameNo is null
			Set @sCommand = @sCommand + 'null,'
		else
			Set @sCommand = @sCommand + convert(varchar,@pnNameNo) + ','

		Set @sCommand = @sCommand +"'"+@sXMLString+"'" 
		
		---------------------------------------------------------------
		-- Run the command asynchronously using Service Broker (rfc39102)
		--------------------------------------------------------------- 
		exec @ErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
	End
End

------------------------------------
--
-- R E T U R N   T H E   R E S U L T
--
------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	DV.FUNCTIONALAREA	as 'FunctionalArea', 
	        T.CASEID		as 'CaseKey', 
		T.NAMENO		as 'NameKey', 
		DV.VALIDATIONID		as 'ValidationKey', 
		DV.WARNINGFLAG		as 'IsWarning', 
		CASE WHEN(IR.ROLEID=DV.ROLEID) 
			THEN cast(1 as bit)
			ELSE cast(0 as bit)
		END			as 'CanOverride', 
		DV.PROGRAMCONTEXT	as 'ProgramContext',
		CASE WHEN(isnull(R.RESULT,'1')='1') 
			THEN "+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','DISPLAYMESSAGE',null,'DV',@sLookupCulture,0)+" 
			ELSE R.RESULT 
		END			as 'DisplayMessage',
		isnull(T.IDENTITYID,@pnUserIdentityId)
					as 'UserIdentityKey'
	from #TEMPDATAVALIDATION T
	join DATAVALIDATION DV		on (DV.VALIDATIONID=T.VALIDATIONID)
	left join #TEMPRESULT R		on (R.RECORDKEY=isnull(T.CASEID,T.NAMENO)
					and R.VALIDATIONID=T.VALIDATIONID)
	left join IDENTITYROLES IR	on (IR.IDENTITYID=@pnUserIdentityId
					and IR.ROLEID    =DV.ROLEID
					and isnull(DV.WARNINGFLAG,0)=0)
	Where isnull(T.DEFERREDFLAG,0)=0
	and(R.RESULT is not null OR SQL_QUERY is null)
	order by T.IDENTITYID, T.CASEID, T.NAMENO, DV.WARNINGFLAG, DV.VALIDATIONID"	

	If @pbPrintFlag=1
	Begin
		PRINT ''
		PRINT @sSQLString
	End

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	int',
				  @pnUserIdentityId=@pnUserIdentityId

	Set @nRowCount=@@Rowcount
End


------------------------------------
--
-- INSERT RESULTS IN  SANITYCHECKRESULT
--
------------------------------------
If @pnBackgroundProcessId is not null and @psTableName is not null
BEGIN
	Set @sSQLString = "Insert into SANITYCHECKRESULT (PROCESSID, CASEID,ISWARNING,CANOVERRIDE,DISPLAYMESSAGE)
				Select
				@pnBackgroundProcessId,	 
				T.CASEID ,		 		 
				DV.WARNINGFLAG , 
				CASE WHEN(IR.ROLEID=DV.ROLEID) 
					THEN cast(1 as bit)
					ELSE cast(0 as bit)
				END ,		
				CASE WHEN(isnull(R.RESULT,'1')='1') 
				     THEN "+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','DISPLAYMESSAGE',null,'DV',@sLookupCulture,0)+" 
			             ELSE R.RESULT 
				END 
				from #TEMPDATAVALIDATION T
	                        join DATAVALIDATION DV	on (DV.VALIDATIONID=T.VALIDATIONID)
	                        left join #TEMPRESULT R	on (R.RECORDKEY=isnull(T.CASEID,T.NAMENO)
					                    and R.VALIDATIONID=T.VALIDATIONID)
	                        left join IDENTITYROLES IR on (IR.IDENTITYID=@pnUserIdentityId
					                        and IR.ROLEID    =DV.ROLEID
					                        and isnull(DV.WARNINGFLAG,0)=0)
	                        Where isnull(T.DEFERREDFLAG,0)=0
	                        and(R.RESULT is not null OR SQL_QUERY is null)"
	
	
	If @pbPrintFlag=1
	Begin
		PRINT ''
		PRINT @sSQLString
	End	

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				@pnBackgroundProcessId  int',
				@pnUserIdentityId       = @pnUserIdentityId,
				@pnBackgroundProcessId  = @pnBackgroundProcessId

	Set @nRowCount=@@Rowcount
END


------------------------------------
--
-- L O G   E R R O R S   R A I S E D
--
------------------------------------
If  @ErrorCode=0
and @nRowCount>0
and @psTableName is null -- Logging is only required for updated Cases.
Begin
	-----------------------------------
	-- Extract any Validation rules that
	-- have returned an Error into a
	-- variable, formatted as XML.
	-----------------------------------
	set @sXMLString=convert(nvarchar(max),
		(Select	Distinct
			I.IDENTITYID,
			DV.VALIDATIONID,
			T.CASEID, 
			T.NAMENO
		from #TEMPDATAVALIDATION T
		join DATAVALIDATION DV		on (DV.VALIDATIONID=T.VALIDATIONID)
		join USERIDENTITY I		on (I.IDENTITYID   =isnull(T.IDENTITYID,@pnUserIdentityId))
		left join #TEMPRESULT R		on (R.RECORDKEY=isnull(T.CASEID,T.NAMENO)
						and R.VALIDATIONID=T.VALIDATIONID)
		Where isnull(T.DEFERREDFLAG,0)=0
		and isnull(DV.WARNINGFLAG,0)  =0		-- Only Errors are to be logged
		and(R.RESULT is not null OR SQL_QUERY is null)
		order by I.IDENTITYID, T.CASEID, T.NAMENO, DV.VALIDATIONID
		for XML Path('LogRow'), Root('LogValidation'), TYPE))

	Set @ErrorCode=@@Error
	
	If @sXMLString is not null
	and @ErrorCode is not null
	Begin
		---------------------------------------
		-- The extracted data will be passed to
		-- a stored procedure  for insertion 
		-- into thd DATAVALIDATIONFAILLOG table
		---------------------------------------

		If @pbDeferredValidations=1
		Begin
			-- Deferred validations can be be logged immediately
			-- as these will not be subject to a ROLLBACK from 
			-- 
			exec @ErrorCode=dbo.ip_InsertDataValidationFailLog
							@pnUserIdentityId,
							@sXMLString
		End
	End
End

--------------------------------------------------
--
-- R E M O V E   D E F E R R E D   R E Q U E S T S
--
--------------------------------------------------

Set @nRetry = 3

While @nRetry>0
and   @pbDeferredValidations=1
and   @ErrorCode=0
Begin
	Begin TRY
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		-----------------------------------------
		-- Delete rows from DATAVALIDATIONREQUEST
		-- that have just been processed.
		-----------------------------------------
		Set @sSQLString="
		Delete DR
		from DATAVALIDATIONREQUEST DR
		join #TEMPDATAVALIDATION T	on (T.VALIDATIONID=DR.VALIDATIONID
						and(T.CASEID=DR.CASEID OR T.NAMENO=DR.NAMENO))"

		Exec @ErrorCode=sp_executesql @sSQLString		

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
		
		-- Terminate the WHILE loop
		Set @nRetry=-1
	END TRY	

	---------------------------------
	-- D E A D L O C K   V I C T I M   
	--       P R O C E S S I N G
	---------------------------------
	BEGIN CATCH
		------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
		------------------------------------------
		If ERROR_NUMBER()=1205
		Begin
			Set @nRetry=@nRetry-1
			WAITFOR DELAY '0:0:05'	-- pause for 5 seconds
		End
		Else
			Set @nRetry=-1
			
		If XACT_STATE()<>0
			Rollback Transaction
		
		If @nRetry<1
			Set @ErrorCode=ERROR_NUMBER()
	END CATCH
END -- While loop


---------------------------------------
-- Update BACKGROUNDPROCESS table 
---------------------------------------	
If @pnBackgroundProcessId is not null 
Begin
	If @ErrorCode = 0
	Begin				
		Set @sSQLString = "Update BACKGROUNDPROCESS
				Set STATUS = 2,
				    STATUSDATE = getdate()
				Where PROCESSID = @pnBackgroundProcessId"

		exec @ErrorCode = sp_executesql @sSQLString,
			N'@pnBackgroundProcessId	int',
			@pnBackgroundProcessId  = @pnBackgroundProcessId		
	End
	Else
	Begin
		Set @sSQLString="Select @sErrorMessage = description
			from master..sysmessages
			where error=@ErrorCode
			and msglangid=(SELECT msglangid FROM master..syslanguages WHERE name = @@LANGUAGE)"

		exec @ErrorCode = sp_executesql @sSQLString,
			N'@sErrorMessage	nvarchar(254) output,
			  @ErrorCode	int',
			  @sErrorMessage	= @sErrorMessage output,
			  @ErrorCode	= @ErrorCode

		---------------------------------------
		-- Update BACKGROUNDPROCESS table 
		---------------------------------------	
		Set @sSQLString = "Update BACKGROUNDPROCESS
					Set STATUS = 3,
					    STATUSDATE = getdate(),
					    STATUSINFO = @sErrorMessage
					Where PROCESSID = @pnBackgroundProcessId"

		exec @ErrorCode = sp_executesql @sSQLString,
			N'@pnBackgroundProcessId	int,
			  @sErrorMessage	nvarchar(254)',
			  @pnBackgroundProcessId = @pnBackgroundProcessId,
			  @sErrorMessage	= @sErrorMessage
	End	
	
	IF @psTableName is not null
	Begin
		---------------------------------------
		-- Drop temporary table 
		---------------------------------------	
		Set @sSQLString = "Drop table "+CHAR(10)+ @psTableName
		exec @ErrorCode = sp_executesql @sSQLString		
	End
End

return @ErrorCode
go

grant execute on dbo.ip_DataValidation  to public
go

