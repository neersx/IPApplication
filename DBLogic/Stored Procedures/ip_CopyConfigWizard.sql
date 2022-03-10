-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_CopyConfigWizard
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].ip_CopyConfigWizard') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_CopyConfigWizard.'
	drop procedure dbo.ip_CopyConfigWizard
	print '**** Creating procedure dbo.ip_CopyConfigWizard...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE dbo.ip_CopyConfigWizard
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnFunction			int		= 1,	 -- indicates the behaviour expected of the stored procedure
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psErrorStatusTable	nvarchar(200) = null -- a temp table to store any error occurred in this sp.


AS

-- PROCEDURE :	ip_CopyConfigWizard
-- VERSION :	21
-- DESCRIPTION:	Calls the procedures required for loading the Law Update Service data
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 18 Jan 2012	AvdA		1	Procedure created based on ip_RulesWizard
-- 28 Mar 2012	AvdA		2	Reinstate call to ip_CopyConfigTempTablesExist 
-- 22 May 2012	AvdA		3	Remove policing request
-- 11 Jun 2012	AvdA		4	Drop constraints before updating tables
-- 31 Jul 2012	AvdA		5	Regenerate - reset table order alpha
--  7 Sep 2012	AvdA		6	Remove TABLEATTRIBUTES
--  3 Oct 2012	AvdA		7	Add GROUPMEMBERS
-- 09 Oct 2012  DH		8	Added Policing insert
-- 11 Feb 2013	DH		9	Clean up comments
-- 19 Feb 2013  DH		10	Fix policing delete, exec as string
-- 05 May 2014	MF	S22069	11	Dropping and restoring Referential Integrity was not correctly considering the 
--					@ErrorCode which allowed errors to be ignored and the code reset back to zero.
--					This allowed for the database changes to be committed even though in error.
-- 02 Oct 2014	MF	32711	12	Add copy functionality for TOPICCONTROLFILTER	
-- 17 Dec 2014	AK	32711	13	Removed STATUSSEQUENCE references
-- 03 Apr 2017	MF	71020	14	Add copy functionality for TOPICUSAGE
-- 01 May 2017	MF	71205	15	Add copy functionality for ROLESCONTROL
-- 21 May 2018	MF	74025	16	Disable the _Sync triggers for SCREENCONTROL, TOPICCONTROL & TOPICCONTROLFILTER before
--					the configuration copy, and then enable them again after completion.
-- 21 Aug 2019	MF	DR-42774 17	Add copy functionality for PROGRAM
-- 21 Aug 2019	MF	DR-36783 18	Add copy functionality for FORMFIELDS
-- 21 Aug 2019	MF	DR-51238 18	Added CONFIGURATIONITEMGROUP table
-- 23 Sep 2019	DL	DR-42023 19	Copy Config is not reporting any errors from the stored procedure it calls
-- 06 Dec 2019	MF	DR-28833 20	Added EVENTTEXTTYPE table
-- 23 Mar 2020	BS	DR-57435 21	DB public role missing execute permission on some stored procedures and functions

set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF

Declare	@ErrorCode		int
Declare	@nTranCountStart	int
Declare	@nTransNo		int
Declare	@nBatchNo		int
Declare	@nOfficeID		int
Declare	@nLogMinutes		int
Declare	@sUserName		nvarchar(40)
Declare @sSQLString		nvarchar(max)
Declare @bAllTempTablesExist	bit
Declare @bHexNumber		varbinary(128)
Declare @sError			nvarchar(max)

-- Initialize variables
Set @ErrorCode=0
Set @sUserName	= @psUserName
Set @bAllTempTablesExist = 0

--------------------------------------
-- Initialise variables that will be 
-- loaded into CONTEXT_INFO for access
-- by the audit triggers
--------------------------------------

If @ErrorCode=0
and @pnFunction > 0
Begin
	Set @sSQLString="
	Select @nOfficeID=COLINTEGER
	from SITECONTROL
	where CONTROLID='Office For Replication'

	Select @nLogMinutes=COLINTEGER
	from SITECONTROL
	where CONTROLID='Log Time Offset'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nOfficeID	int		OUTPUT,
				  @nLogMinutes	int		OUTPUT',
				  @nOfficeID  = @nOfficeID	OUTPUT,
				  @nLogMinutes=@nLogMinutes	OUTPUT
End

If @ErrorCode=0
and @pnFunction > 0
Begin
	-- A separate database transaction will be used to insert the TRANSACTIONINFO
	-- row to ensure the lock on the database is kept to a minimum as this table
	-- will be used extensively by other processes.

	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Allocate a transaction id that can be accessed by the audit logs
	-- for inclusion.
	Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE,BATCHNO) values(getdate(),@nBatchNo)
			Set @nTransNo=SCOPE_IDENTITY()"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nBatchNo int,
				  @nTransNo	int	OUTPUT',
				  @nBatchNo=@nBatchNo,
				  @nTransNo=@nTransNo	OUTPUT

	--------------------------------------------------------------
	-- Load a common area accessible from the database server with
	-- the UserIdentityId, TransactionNo just generated and other
	-- identifiers. This will be used by the audit logs.
	--------------------------------------------------------------

	Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4)+ 
			substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
			substring(cast(isnull(@nBatchNo,'') as varbinary),1,4) +
			substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
			substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
	SET CONTEXT_INFO @bHexNumber

	-- Commit or Rollback the transaction
	
	If @@TranCount > @nTranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

If @ErrorCode=0
Begin
	---------------------------------------------------------------------------------------------
	--	Disable SCREENCONTROL' triggers														--
	---------------------------------------------------------------------------------------------

	IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tI_SCREENCONTROL_Sync' and is_disabled = 0) 
	  BEGIN 
	      ALTER TABLE [dbo].[SCREENCONTROL] DISABLE TRIGGER [tI_SCREENCONTROL_Sync]
	  END 

	IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tU_SCREENCONTROL_Sync' and is_disabled = 0) 
	  BEGIN 
	      ALTER TABLE [dbo].[SCREENCONTROL] DISABLE TRIGGER [tU_SCREENCONTROL_Sync]
	  END 

	IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tD_SCREENCONTROL_Sync' and is_disabled = 0) 
	  BEGIN 
	      ALTER TABLE [dbo].[SCREENCONTROL] DISABLE TRIGGER [tD_SCREENCONTROL_Sync]
	  END 

	---------------------------------------------------------------------------------------------
	--	Disable TOPICCONTROL' triggers															--
	---------------------------------------------------------------------------------------------

	IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tI_TOPICCONTROL_Sync' and is_disabled = 0) 
	  BEGIN 
	      ALTER TABLE [dbo].[TOPICCONTROL] DISABLE TRIGGER [tI_TOPICCONTROL_Sync]
	  END 

	IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tU_TOPICCONTROL_Sync' and is_disabled = 0) 
	  BEGIN 
	      ALTER TABLE [dbo].[TOPICCONTROL] DISABLE TRIGGER [tU_TOPICCONTROL_Sync]
	  END 

	IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tD_TOPICCONTROL_Sync' and is_disabled = 0) 
	  BEGIN 
	      ALTER TABLE [dbo].[TOPICCONTROL] DISABLE TRIGGER [tD_TOPICCONTROL_Sync]
	  END 

	---------------------------------------------------------------------------------------------
	--	Disable TOPICCONTROLFILTER' triggers													--
	---------------------------------------------------------------------------------------------

	IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tI_TOPICCONTROLFILTER_Sync' and is_disabled = 0) 
	  BEGIN 
	      ALTER TABLE [dbo].[TOPICCONTROLFILTER] DISABLE TRIGGER [tI_TOPICCONTROLFILTER_Sync]
	  END 
	IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tU_TOPICCONTROLFILTER_Sync' and is_disabled = 0) 
	  BEGIN 
	      ALTER TABLE [dbo].[TOPICCONTROLFILTER] DISABLE TRIGGER [tU_TOPICCONTROLFILTER_Sync]
	  END 

	IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tD_TOPICCONTROLFILTER_Sync' and is_disabled = 0) 
	  BEGIN 
	      ALTER TABLE [dbo].[TOPICCONTROLFILTER] DISABLE TRIGGER [tD_TOPICCONTROLFILTER_Sync]
	  END 
End

If @ErrorCode=0 
and @pnFunction > 0
Begin

	BEGIN TRY		-- DR-42023 Trapping error for displaying

	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Paste generated code here 
	-- Add constraint removal and replacement
	----------------------------------------------------------------------------------------------------------

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ACCT_TRANS_TYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ACTIONS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ADJUSTMENT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE AIRPORT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ALERTTEMPLATE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ALIASTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ANALYSISCODE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE APPLICATIONBASIS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ASSOCIATEDNAME NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ATTRIBUTES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE B2BELEMENT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE B2BTASKEVENT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE BUSINESSFUNCTION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE BUSINESSRULECONTROL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CASECATEGORY NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CASERELATION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CASETYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CHARGERATES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CHARGETYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CHECKLISTITEM NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CHECKLISTLETTER NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CHECKLISTS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CONFIGURATIONITEM NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CONFIGURATIONITEMGROUP NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE COPYPROFILE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CORRESPONDTO NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE COUNTRY NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE COUNTRYFLAGS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE COUNTRYGROUP NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE COUNTRYTEXT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CPAEVENTCODE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CPANARRATIVE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CRITERIA NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CRITERIA_ITEMS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CRITERIACHANGES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CULTURE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CULTURECODEPAGE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DATASOURCE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DATATOPIC NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DATAVALIDATION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DATAVIEW NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DATESLOGIC NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DEBTOR_ITEM_TYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DEBTORSTATUS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DELIVERYMETHOD NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DETAILCONTROL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DETAILDATES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DETAILLETTERS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DOCUMENT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DOCUMENTDEFINITION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DOCUMENTDEFINITIONACTINGAS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DUEDATECALC NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDEREQUESTTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULECASE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULECASEEVENT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULECASENAME NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULECASETEXT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULEOFFICIALNUMBER NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULERELATEDCASE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ELEMENT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ELEMENTCONTROL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ENCODEDVALUE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ENCODINGSCHEME NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ENCODINGSTRUCTURE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTCATEGORY NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTCONTROL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTCONTROLNAMEMAP NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTCONTROLREQEVENT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTSREPLACED NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTTEXTTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTUPDATEPROFILE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EXTERNALSYSTEM NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEATURE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEATUREMODULE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEATURETASK NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEESCALCALT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEESCALCULATION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEETYPES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FIELDCONTROL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FILELOCATIONOFFICE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FORMFIELDS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FREQUENCY NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE GROUPMEMBERS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE GROUPS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE HOLIDAYS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE IMPORTANCE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE INHERITS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE INSTRUCTIONFLAG NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE INSTRUCTIONLABEL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE INSTRUCTIONS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE INSTRUCTIONTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE IRFORMAT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ITEM NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ITEM_GROUP NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ITEM_NOTE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
		Set @sSQLString="ALTER TABLE LANGUAGE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE LETTER NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MAPPING NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MAPSCENARIO NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MAPSTRUCTURE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MODULE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MODULECONFIGURATION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MODULEDEFINITION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMECRITERIA NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMECRITERIAINHERITS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMEGROUPS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMEINSTRUCTIONS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMERELATION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMETYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NARRATIVE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NARRATIVERULE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NUMBERTYPES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE OFFICE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End
	
	If @ErrorCode=0
	Begin
		alter table OFFICE disable trigger all
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PAYMENTMETHODS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PERMISSIONS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PORTAL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PORTALMENU NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PORTALSETTING NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PORTALTAB NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PORTALTABCONFIGURATION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROFILEATTRIBUTES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROFILEPROGRAM NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROFILES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROFITCENTRE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROFITCENTRERULE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROGRAM NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROPERTYTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROTECTCODES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE QUANTITYSOURCE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE QUERYCONTEXT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE QUERYDATAITEM NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE QUESTION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RATES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE REASON NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RECORDALELEMENT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RECORDALTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RECORDTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RELATEDEVENTS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE REMINDERS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE REQATTRIBUTES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RESOURCE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ROLE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ROLESCONTROL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ROLETASKS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ROLETOPICS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SCREENCONTROL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SCREENS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SELECTIONTYPES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE STATE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE STATUS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE STATUSCASETYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SUBJECT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SUBJECTAREA NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SUBJECTAREATABLES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SUBTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TABCONTROL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TABLECODES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TABLETYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TASK NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TAXRATESCOUNTRY NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TEXTTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TITLES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TMCLASS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICCONTROL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICCONTROLFILTER NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICDATAITEMS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICDEFAULTSETTINGS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICUSAGE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TRANSACTIONREASON NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDACTDATES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDACTION NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDATENUMBERS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDBASIS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDBASISEX NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDCATEGORY NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDCHECKLISTS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDEXPORTFORMAT NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDPROPERTY NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDRELATIONSHIPS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDSTATUS NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDSUBTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDTABLECODES NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE WINDOWCONTROL NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE WIPATTRIBUTE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE WIPCATEGORY NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE WIPTEMPLATE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE WIPTYPE NOCHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End


	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ACCT_TRANS_TYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ACTIONS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ADJUSTMENT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_AIRPORT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ALERTTEMPLATE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ALIASTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ANALYSISCODE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_APPLICATIONBASIS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ATTRIBUTES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_B2BELEMENT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_B2BTASKEVENT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_BUSINESSFUNCTION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_BUSINESSRULECONTRO_ @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CASECATEGORY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CASERELATION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CASETYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CHARGERATES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CHARGETYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CHECKLISTITEM @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CHECKLISTLETTER @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CHECKLISTS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CONFIGURATIONITEMGROUP @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CONFIGURATIONITEM @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_COPYPROFILE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CORRESPONDTO @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_COUNTRY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_COUNTRYFLAGS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_COUNTRYGROUP @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_COUNTRYTEXT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CPAEVENTCODE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CPANARRATIVE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CRITERIA @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CRITERIA_ITEMS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CRITERIACHANGES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CULTURE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_CULTURECODEPAGE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DATASOURCE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DATATOPIC @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DATAVALIDATION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DATAVIEW @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DATESLOGIC @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DEBTOR_ITEM_TYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DEBTORSTATUS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DELIVERYMETHOD @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DETAILCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DETAILDATES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DETAILLETTERS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DOCUMENT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DOCUMENTDEFINITION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DOCUMENTDEFINITION_ @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_DUEDATECALC @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EDEREQUESTTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EDERULECASE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EDERULECASEEVENT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EDERULECASENAME @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EDERULECASETEXT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EDERULEOFFICIALNUM_ @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EDERULERELATEDCASE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ELEMENT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ELEMENTCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ENCODEDVALUE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ENCODINGSCHEME @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ENCODINGSTRUCTURE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EVENTCATEGORY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EVENTCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EVENTCONTROLNAMEMA_ @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EVENTCONTROLREQEVE_ @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EVENTS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EVENTSREPLACED @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EVENTTEXTTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EVENTUPDATEPROFILE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_EXTERNALSYSTEM @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_FEATURE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_FEATUREMODULE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_FEATURETASK @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_FEESCALCALT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_FEESCALCULATION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_FEETYPES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_FIELDCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_FILELOCATIONOFFICE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_FREQUENCY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_GROUPMEMBERS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_GROUPS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_HOLIDAYS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_IMPORTANCE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_INHERITS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_INSTRUCTIONFLAG @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_INSTRUCTIONLABEL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_INSTRUCTIONS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_INSTRUCTIONTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_IRFORMAT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ITEM @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ITEM_GROUP @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ITEM_NOTE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_LANGUAGE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_LETTER @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_FORMFIELDS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_MAPPING @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_MAPSCENARIO @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_MAPSTRUCTURE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_MODULE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_MODULECONFIGURATIO_ @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_MODULEDEFINITION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_NAMECRITERIA @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_NAMECRITERIAINHERI_ @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_NAMEGROUPS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_NAMERELATION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_NAMETYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_NARRATIVE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_NARRATIVERULE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_NUMBERTYPES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_OFFICE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PAYMENTMETHODS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PERMISSIONS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PORTAL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PORTALMENU @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PORTALSETTING @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PORTALTAB @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PORTALTABCONFIGURA_ @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PROFILEATTRIBUTES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PROFILEPROGRAM @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PROFILES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PROFITCENTRE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PROFITCENTRERULE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PROGRAM @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PROPERTYTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_PROTECTCODES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_QUANTITYSOURCE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_QUERYCONTEXT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_QUERYDATAITEM @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_QUESTION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_RATES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_REASON @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_RECORDALELEMENT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_RECORDALTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_RECORDTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_RELATEDEVENTS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_REMINDERS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_REQATTRIBUTES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_RESOURCE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ROLE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ROLESCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ROLETASKS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_ROLETOPICS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_SCREENCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_SCREENS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_SELECTIONTYPES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_STATE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_STATUS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_STATUSCASETYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
	exec @ErrorCode=ip_cc_SUBJECT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_SUBJECTAREA @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_SUBJECTAREATABLES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_SUBTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TABCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TABLECODES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TABLETYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TASK @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TAXRATESCOUNTRY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TEXTTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TITLES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TMCLASS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TOPICCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TOPICCONTROLFILTER @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TOPICDATAITEMS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TOPICDEFAULTSETTIN_ @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TOPICS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TOPICUSAGE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_TRANSACTIONREASON @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDACTDATES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDACTION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDATENUMBERS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDBASIS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDBASISEX @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDCATEGORY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDCHECKLISTS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDEXPORTFORMAT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDPROPERTY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDRELATIONSHIPS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDSTATUS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDSUBTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_VALIDTABLECODES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_WINDOWCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_WIPATTRIBUTE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_WIPCATEGORY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_WIPTEMPLATE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	If @ErrorCode=0
		exec @ErrorCode=ip_cc_WIPTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo


	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ACCT_TRANS_TYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ACTIONS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ADJUSTMENT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE AIRPORT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ALERTTEMPLATE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ALIASTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ANALYSISCODE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE APPLICATIONBASIS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ASSOCIATEDNAME CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ATTRIBUTES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE B2BELEMENT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE B2BTASKEVENT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE BUSINESSFUNCTION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE BUSINESSRULECONTROL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CASECATEGORY CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CASERELATION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CASETYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CHARGERATES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CHARGETYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CHECKLISTITEM CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CHECKLISTLETTER CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CHECKLISTS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CONFIGURATIONITEM CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CONFIGURATIONITEMGROUP CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE COPYPROFILE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CORRESPONDTO CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE COUNTRY CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE COUNTRYFLAGS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE COUNTRYGROUP CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE COUNTRYTEXT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CPAEVENTCODE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CPANARRATIVE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CRITERIA CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CRITERIA_ITEMS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CRITERIACHANGES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CULTURE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE CULTURECODEPAGE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DATASOURCE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DATATOPIC CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DATAVALIDATION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DATAVIEW CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DATESLOGIC CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DEBTOR_ITEM_TYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DEBTORSTATUS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DELIVERYMETHOD CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DETAILCONTROL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DETAILDATES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DETAILLETTERS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DOCUMENT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DOCUMENTDEFINITION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DOCUMENTDEFINITIONACTINGAS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE DUEDATECALC CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDEREQUESTTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULECASE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULECASEEVENT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULECASENAME CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULECASETEXT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULEOFFICIALNUMBER CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EDERULERELATEDCASE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ELEMENT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ELEMENTCONTROL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ENCODEDVALUE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ENCODINGSCHEME CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ENCODINGSTRUCTURE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTCATEGORY CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTCONTROL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTCONTROLNAMEMAP CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTCONTROLREQEVENT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTSREPLACED CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTTEXTTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EVENTUPDATEPROFILE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE EXTERNALSYSTEM CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEATURE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEATUREMODULE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEATURETASK CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEESCALCALT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEESCALCULATION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FEETYPES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FIELDCONTROL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FILELOCATIONOFFICE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FORMFIELDS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE FREQUENCY CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE GROUPMEMBERS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE GROUPS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE HOLIDAYS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE IMPORTANCE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE INHERITS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE INSTRUCTIONFLAG CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE INSTRUCTIONLABEL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE INSTRUCTIONS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE INSTRUCTIONTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE IRFORMAT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ITEM CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ITEM_GROUP CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ITEM_NOTE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
		Set @sSQLString="ALTER TABLE LANGUAGE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE LETTER CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MAPPING CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MAPSCENARIO CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MAPSTRUCTURE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MODULE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MODULECONFIGURATION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE MODULEDEFINITION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMECRITERIA CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMECRITERIAINHERITS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMEGROUPS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMEINSTRUCTIONS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMERELATION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NAMETYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NARRATIVE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NARRATIVERULE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE NUMBERTYPES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE OFFICE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End
	
	If @ErrorCode=0
	Begin
		alter table OFFICE enable trigger all
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PAYMENTMETHODS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PERMISSIONS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PORTAL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PORTALMENU CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PORTALSETTING CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PORTALTAB CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PORTALTABCONFIGURATION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROFILEATTRIBUTES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROFILEPROGRAM CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROFILES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROFITCENTRE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROFITCENTRERULE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROGRAM CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROPERTYTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE PROTECTCODES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE QUANTITYSOURCE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE QUERYCONTEXT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE QUERYDATAITEM CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE QUESTION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RATES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE REASON CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RECORDALELEMENT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RECORDALTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RECORDTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RELATEDEVENTS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE REMINDERS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE REQATTRIBUTES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE RESOURCE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ROLE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ROLESCONTROL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ROLETASKS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE ROLETOPICS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SCREENCONTROL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SCREENS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SELECTIONTYPES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE STATE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE STATUS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE STATUSCASETYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SUBJECT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SUBJECTAREA CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SUBJECTAREATABLES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE SUBTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TABCONTROL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TABLECODES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TABLETYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TASK CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TAXRATESCOUNTRY CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TEXTTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TITLES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TMCLASS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICCONTROL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICCONTROLFILTER CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICDATAITEMS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICDEFAULTSETTINGS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TOPICUSAGE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE TRANSACTIONREASON CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDACTDATES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDACTION CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDATENUMBERS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDBASIS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDBASISEX CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDCATEGORY CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDCHECKLISTS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDEXPORTFORMAT CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDPROPERTY CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDRELATIONSHIPS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDSTATUS CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDSUBTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE VALIDTABLECODES CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE WINDOWCONTROL CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE WIPATTRIBUTE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE WIPCATEGORY CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE WIPTEMPLATE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="ALTER TABLE WIPTYPE CHECK CONSTRAINT ALL"
		Exec @ErrorCode=sp_executesql @sSQLString
	End
-- end of generated code section
----------------------------------------------------------------------------------------------------------

--Copy Policing insert

	If @ErrorCode=0
	Begin

		--Only delete where name matches the temp import table
		set @sSQLString="
		Delete P 
		from POLICING P
		join CCImport_POLICING CCP on CCP.POLICINGNAME = P.POLICINGNAME
		where P.SYSGENERATEDFLAG = 0"

		exec @ErrorCode=sp_executesql @sSQLString
	End
	
	If @ErrorCode=0
	Begin

		-- Now insert the CC prefix rows.
		Set @sSQLString= "
		Insert into POLICING(
			DATEENTERED,
			POLICINGSEQNO,
			POLICINGNAME,
			SYSGENERATEDFLAG,
			ONHOLDFLAG,
			IRN,
			PROPERTYTYPE,
			COUNTRYCODE,
			DATEOFACT,
			ACTION,
			EVENTNO,
			NAMETYPE,
			NAMENO,
			CASETYPE,
			CASECATEGORY,
			SUBTYPE,
			FROMDATE,
			UNTILDATE,
			NOOFDAYS,
			LETTERDATE,
			CRITICALONLYFLAG,
			CRITLETTERSFLAG,
			CRITREMINDFLAG,
			UPDATEFLAG,
			REMINDERFLAG,
			ADHOCFLAG,
			CRITERIAFLAG,
			DUEDATEFLAG,
			CALCREMINDERFLAG,
			EXCLUDEPROPERTY,
			EXCLUDECOUNTRY,
			EXCLUDEACTION,
			EMPLOYEENO,
			CASEID,
			CRITERIANO,
			CYCLE,
			TYPEOFREQUEST,
			COUNTRYFLAGS,
			FLAGSETON,
			SQLUSER,
			DUEDATEONLYFLAG,
			LETTERFLAG,
			BATCHNO,
			IDENTITYID,
			ADHOCNAMENO,
			ADHOCDATECREATED,
			RECALCEVENTDATE,
			CASEOFFICEID,
			SCHEDULEDDATETIME,
			PENDING,
			SPIDINPROGRESS,
			EMAILFLAG,
			NOTES)
		select
			I.DATEENTERED,
			I.POLICINGSEQNO,
			I.POLICINGNAME,
			I.SYSGENERATEDFLAG,
			I.ONHOLDFLAG,
			I.IRN,
			I.PROPERTYTYPE,
			I.COUNTRYCODE,
			I.DATEOFACT,
			I.ACTION,
			I.EVENTNO,
			I.NAMETYPE,
			I.NAMENO,
			I.CASETYPE,
			I.CASECATEGORY,
			I.SUBTYPE,
			I.FROMDATE,
			I.UNTILDATE,
			I.NOOFDAYS,
			I.LETTERDATE,
			I.CRITICALONLYFLAG,
			I.CRITLETTERSFLAG,
			I.CRITREMINDFLAG,
			I.UPDATEFLAG,
			I.REMINDERFLAG,
			I.ADHOCFLAG,
			I.CRITERIAFLAG,
			I.DUEDATEFLAG,
			I.CALCREMINDERFLAG,
			I.EXCLUDEPROPERTY,
			I.EXCLUDECOUNTRY,
			I.EXCLUDEACTION,
			I.EMPLOYEENO,
			I.CASEID,
			I.CRITERIANO,
			I.CYCLE,
			I.TYPEOFREQUEST,
			I.COUNTRYFLAGS,
			I.FLAGSETON,
			I.SQLUSER,
			I.DUEDATEONLYFLAG,
			I.LETTERFLAG,
			I.BATCHNO,
			I.IDENTITYID,
			I.ADHOCNAMENO,
			I.ADHOCDATECREATED,
			I.RECALCEVENTDATE,
			replace( I.CASEOFFICEID,char(10),char(13)+char(10)),
			I.SCHEDULEDDATETIME,
			I.PENDING,
			I.SPIDINPROGRESS,
			I.EMAILFLAG,
			I.NOTES
		from CCImport_POLICING I
		left join POLICING C	on ( C.DATEENTERED=I.DATEENTERED
						and C.POLICINGSEQNO=I.POLICINGSEQNO)
		where C.DATEENTERED is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End
	
	-- Commit transaction if successful
	If @@TranCount > @nTranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End

	END TRY		

	BEGIN CATCH  -- DR-42023 send error message to front end for displaying
		SET @ErrorCode =  ERROR_NUMBER()
		Set @sError =  ERROR_MESSAGE()

		If XACT_STATE()<>0
			Rollback Transaction

		If @psErrorStatusTable is not null
		Begin
			set @sSQLString = "Insert into " + @psErrorStatusTable + " (ERRORNO, ERRORMESSAGE) VALUES (@ErrorCode, @sError)"
			exec sp_executesql @sSQLString,
						N'@ErrorCode int, 
						@sError nvarchar(max)',
						@ErrorCode = @ErrorCode, 
						@sError = @sError
		End
	END CATCH
end

If @ErrorCode=0 
and @pnFunction > 0
Begin
	-- cleans up temp tables
	exec @ErrorCode=ip_CopyConfigTempTableCleanup @sUserName
end

-- check if all temp tables exists
If @ErrorCode=0 
and @pnFunction = 0
Begin
	exec @ErrorCode=ip_CopyConfigTempTablesExist @sUserName, @bAllTempTablesExist OUTPUT
--	set @bAllTempTablesExist =1
	select @bAllTempTablesExist as 'AllExists'
end

---------------------------------------------------------------------------------------------
-- Enable the Syncing triggers on SCREENCONTROL, TOPICCONTROL & TOPICCONTROLFILTER if they
-- exist in the database and have been disabled.
-- This code deliberately falls outside of the main database transaction and so we do not
-- need to test the value of @ErrorCode.

---------------------------------------------------------------------------------------------
--	Enable SCREENCONTROL' triggers														--
---------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tI_SCREENCONTROL_Sync' and is_disabled = 1) 
BEGIN 
	ALTER TABLE [dbo].[SCREENCONTROL] ENABLE TRIGGER [tI_SCREENCONTROL_Sync]
END 

IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tU_SCREENCONTROL_Sync' and is_disabled = 1) 
BEGIN 
	ALTER TABLE [dbo].[SCREENCONTROL] ENABLE TRIGGER [tU_SCREENCONTROL_Sync]
END 

IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tD_SCREENCONTROL_Sync' and is_disabled = 1) 
BEGIN 
	ALTER TABLE [dbo].[SCREENCONTROL] ENABLE TRIGGER [tD_SCREENCONTROL_Sync]
END 


---------------------------------------------------------------------------------------------
--	Enable TOPICCONTROL' triggers															--
---------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tI_TOPICCONTROL_Sync' and is_disabled = 1) 
BEGIN 
	ALTER TABLE [dbo].[TOPICCONTROL] ENABLE TRIGGER [tI_TOPICCONTROL_Sync]
END 

IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tU_TOPICCONTROL_Sync' and is_disabled = 1) 
BEGIN 
	ALTER TABLE [dbo].[TOPICCONTROL] ENABLE TRIGGER [tU_TOPICCONTROL_Sync]
END 

IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tD_TOPICCONTROL_Sync' and is_disabled = 1) 
BEGIN 
ALTER TABLE [dbo].[TOPICCONTROL] ENABLE TRIGGER [tD_TOPICCONTROL_Sync]
END 


---------------------------------------------------------------------------------------------
--	Enable TOPICCONTROLFILTER' triggers													--
---------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tI_TOPICCONTROLFILTER_Sync' and is_disabled = 1) 
BEGIN 
	ALTER TABLE [dbo].[TOPICCONTROLFILTER] ENABLE TRIGGER [tI_TOPICCONTROLFILTER_Sync]
END 

IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tU_TOPICCONTROLFILTER_Sync' and is_disabled = 1) 
BEGIN 
	ALTER TABLE [dbo].[TOPICCONTROLFILTER] ENABLE TRIGGER [tU_TOPICCONTROLFILTER_Sync]
END 

IF EXISTS (SELECT * FROM   sys.triggers WHERE name = 'tD_TOPICCONTROLFILTER_Sync' and is_disabled = 1) 
BEGIN 
	ALTER TABLE [dbo].[TOPICCONTROLFILTER] ENABLE TRIGGER [tD_TOPICCONTROLFILTER_Sync]
END 

RETURN @ErrorCode
GO

grant execute on ip_CopyConfigWizard  to public
go
