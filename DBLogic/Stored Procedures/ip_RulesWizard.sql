-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesWizard
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesWizard]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesWizard.'
	drop procedure dbo.ip_RulesWizard
end
print '**** Creating procedure dbo.ip_RulesWizard...'
print ''
go


set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go


CREATE PROCEDURE dbo.ip_RulesWizard
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnFunction			int		= 1,	 -- indicates the behaviour expected of the stored procedure
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psErrorStatusTable	nvarchar(200) = null -- a temp table to store any error occurred in this sp (applicable to copy config only DR-42023).

AS

-- PROCEDURE :	ip_RulesWizard
-- VERSION :	19
-- DESCRIPTION:	Calls the procedures required for loading the Law Update Service data
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 22 Mar 2004	AvdA		1	Procedure created
-- 14 Jul 2004	AvdA		2	Modify to be both pre and post procedure for the data wizard.
-- 16 Jul 2004	MF		3	Call the stored procedures to apply the updates.
-- 29 Jul 2004	MF	10225	4	Add REMINDERS table
-- 8 Feb 2005	PK	10796	5	Remove Drop Table commands into sp ip_RulesTempTableCleanup
--					and remove pre/post parameter and drop tables on completion
-- 21 Feb 05	PK	10985	6	Add new section if @pnFunction = 0 then check if all temp tables exists
--					for the specified user
-- 24 Oct 2006	MF	13466	7	Two new tables for INSTRUCTIONTYPE and INSTRUCTIONLABEL
-- 30 Nov 2006  JP	13807	8	Added parameter @pnSourceNo and also passed this to all ip rules stored procedures
-- 21 May 2007	MF	13936	9	Load the SiteControl row that identifies the date and time that the rules
--					were exported.
-- 16 Aug 2007	MF	15018	10	New table TABLEATTRIBUTES
-- 24 Jan 2008	DL	14297	11	Call stored procedure Ip_RulesCreatePolicingRequests to create POLICING rows.
-- 05 Mar 2008	MF	16058	12	No longer require to load COUNTRYFLAGS so remove call to procedure for loading.
-- 25 Mar 2008	MF	14297	13	Set Transaction No before rule changes are applied to database.  This will then
--					easily enable those rules that have been updated to be identified.
-- 11 Dec 2008	MF	17136	14	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 12 Jul 2013	MF	R13596	15	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	16	Revisit of RFC13596. Cannot use #TEMPCRITERIA as this is out of scope when SQL is executed from
--					client/server.
-- 07 Aug 2015	MF	R50954	17	CRITERIAALLOWED table should not be recreated until it is about to be loaded.
-- 06 Jun 2016	MF	R62518	18	Load EVENTS table before CASERELATION.
-- 23 Sep 2019	DL	DR-42023 19 Copy Config is not reporting any errors from the stored procedure it calls
--								Note: copy config and law update are called from the same front end function.
--								However DR-42023 is only applied to copy config.  The param @psErrorStatusTable is added so that it does not error when running law update.
--

set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF

Declare	@ErrorCode		int
Declare	@nTranCountStart	int
Declare	@nTransNo		int
Declare	@nBatchNo		int
Declare	@nOfficeID		int
Declare	@nLogMinutes		int
Declare	@sUserName		nvarchar(40)
Declare @sSQLString		nvarchar(4000)
Declare @bAllTempTablesExist	bit
Declare @bInterimTableExists	bit
Declare @bHexNumber		varbinary(128)

-- Initialize variables
Set @ErrorCode=0
Set @sUserName	= @psUserName
Set @bAllTempTablesExist = 0

--------------------------------------
-- Drop CRITERIAALLOWED if it exists
--------------------------------------
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('"+@sUserName+".CRITERIAALLOWED')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".CRITERIAALLOWED"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @pnFunction > 0
and @ErrorCode = 0
Begin
	--------------------------------------
	-- Initialise variables that will be 
	-- loaded into CONTEXT_INFO for access
	-- by the audit triggers
	--------------------------------------

	If @ErrorCode=0
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

	If  @ErrorCode=0
	Begin
		---------------------------------------------------
		-- Create an interim table to hold the criteria
		-- that are allowed to be imported for the purpose
		-- of creating or update laws on the receiving
		-- database
		---------------------------------------------------
		Set @sSQLString="CREATE TABLE "+@sUserName+".CRITERIAALLOWED (CRITERIANO int not null PRIMARY KEY)"
		exec @ErrorCode=sp_executesql @sSQLString
	end
	
	If @ErrorCode=0 
	Begin
		-----------------------------------------
		-- Load the CRITERIA that are candidates
		-- to be imported into a temporary table.
		-- This allows rules defined by a firm to
		-- block or allow criteria.
		-----------------------------------------
		set @sSQLString="
		insert into "+@sUserName+".CRITERIAALLOWED (CRITERIANO)
		select distinct C.CRITERIANO
		from "+@sUserName+".Imported_CRITERIA C
		left join CRITERIA C1 on (C1.CRITERIANO = dbo.fn_GetCriteriaNoForLawImportBlocking( C.CASETYPE,	
												    C.ACTION,
												    C.PROPERTYTYPE,
												    C.COUNTRYCODE,
												    C.CASECATEGORY,
												    C.SUBTYPE,
												    C.BASIS,
												    C.DATEOFACT) )
		where isnull(C1.RULEINUSE,0)=0"
		
		exec @ErrorCode=sp_executesql @sSQLString
			
		Set @nTranCountStart = @@TranCount
		BEGIN TRANSACTION

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesPROPERTYTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesCOUNTRY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesACTIONS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesCASECATEGORY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesSUBTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesAPPLICATIONBASIS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesSTATUS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesEVENTS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesCASERELATION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesNUMBERTYPES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesADJUSTMENT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesLETTER @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesTABLETYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesTABLECODES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesITEM @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesINSTRUCTIONTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesINSTRUCTIONLABEL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesVALIDATENUMBERS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesCOUNTRYTEXT @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesTMCLASS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesCOUNTRYGROUP @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

	-- SQA16058
	--	If @ErrorCode=0
	--		exec @ErrorCode=ip_RulesCOUNTRYFLAGS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesTABLEATTRIBUTES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesVALIDSTATUS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesVALIDPROPERTY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesVALIDACTION @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesVALIDCATEGORY @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesVALIDSUBTYPE @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesVALIDBASIS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesVALIDACTDATES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesVALIDRELATIONSHIPS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesCRITERIA @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesDETAILCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesEVENTCONTROL @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesINHERITS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesDETAILDATES @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesDETAILLETTERS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesDUEDATECALC @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesDATECOMPARISON @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesRELATEDEVENTS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesDATESLOGIC @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
			exec @ErrorCode=ip_RulesREMINDERS @pnFunction=2, @psUserName=@psUserName, @pnSourceNo=@pnSourceNo

		If @ErrorCode=0
		Begin
			If exists(select 1 from SITECONTROL where CONTROLID like 'IPRULES 20%')
			Begin
				Delete from SITECONTROL where CONTROLID like 'IPRULES 20%'
				Set @ErrorCode=@@Error
			End

			If @ErrorCode=0
			Begin
				If not exists(select 1 from SITECONTROL where CONTROLID='CPA Law Update Service')
				Begin
					Set @sSQLString="
					insert into SITECONTROL(CONTROLID, DATATYPE, COMMENTS, COLCHARACTER)
					select	S.CONTROLID,
						S.DATATYPE,
						S.COMMENTS,
						S.COLCHARACTER
					from "+@sUserName+".Imported_SITECONTROL S
					where S.CONTROLID='CPA Law Update Service'"
				End
				Else Begin
					Set @sSQLString="
					Update SITECONTROL
					Set COLCHARACTER=I.COLCHARACTER
					from SITECONTROL S
					join "+@sUserName+".Imported_SITECONTROL I on (I.CONTROLID=S.CONTROLID)
					where S.CONTROLID='CPA Law Update Service'"
				End

				Exec @ErrorCode=sp_executesql @sSQLString
			End
		End

		-- Commit transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	end

	--------------------------------------------------------------------
	-- SQA14297 
	-- Policing Requests are raised after the database has been updated
	-- with new rules as it allows those rules that have been updated or
	-- inserted by this transaciton to easily be identified.
	--------------------------------------------------------------------
	If  @ErrorCode=0
	Begin
		exec @ErrorCode= Ip_RulesCreatePolicingRequests
						@pnRowCount=@pnRowCount	OUTPUT,
						@pnTransNo =@nTransNo
	End

	If @ErrorCode=0 
	Begin
		-- cleans up temp tables
		exec @ErrorCode=ip_RulesTempTableCleanup @sUserName
	end
End

-- check if all temp tables exists
If @ErrorCode=0 
and @pnFunction = 0
Begin
	exec @ErrorCode=ip_RulesTempTablesExist @sUserName, @bAllTempTablesExist OUTPUT
	select @bAllTempTablesExist as 'AllExists'
end

RETURN @ErrorCode
go

grant execute on dbo.ip_RulesWizard  to public
go
