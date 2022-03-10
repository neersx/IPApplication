-----------------------------------------------------------------------------------------------------------------------------
-- Creation of XML_AgentRenewalInstrLetter2
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[XML_AgentRenewalInstrLetter2]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.XML_AgentRenewalInstrLetter2.'
	Drop procedure [dbo].[XML_AgentRenewalInstrLetter2]
End
Print '**** Creating Stored Procedure dbo.XML_AgentRenewalInstrLetter2...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE dbo.XML_AgentRenewalInstrLetter2 
		@psXMLActivityRequestRow	ntext
AS
-- PROCEDURE :	XML_AgentRenewalInstrLetter2
-- VERSION :	8
-- DESCRIPTION:	Generate renewal instructions (BPOEDI) for cases in CPAXML format.
--						Note: Can only be run on SQL Server 2005 and later.
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who		SQA#	Version	Change
-- ------------	-----	-------	----------------------------------------------- 
-- 18/05/2007	DL	14726	1	Procedure created
-- 19 Jun 2007	MF	14726	2	Use a best fit search to get the RateNos that apply to a Case for
--					a given Charge Type.
-- 07 Jan 2008	RC	15894	3	File naming conventioned changed to indicate which type of file
-- 17 Jun 2008	DL	16531	4	Change @sSQLUserParam to nvarchar(40)
-- 10 Aug 2008	DL	16723	5	Tag requests to enable DocGen to attach the bulk output file to these cases.
-- 15 Dec 2008	MF	17136	6	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 04 Jun 2010	MF	18703	7	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be null	
-- 20 Jan 2012  DL	S20161	8	Fix error for 'FormattedName/MiddleName' if FIRSTNAME contains trailing spaces

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


-- Temp working table to store all Standing Instructions for each Case. 
-- Required to identify the Rates that apply by Case
Create table #TEMPCASEINSTRUCTIONS (
			CASEID			int		NOT NULL,
			INSTRUCTIONTYPE		nvarchar(3)	collate database_default NOT NULL, 
			INSTRUCTIONCODE		smallint	NOT NULL)

-- Temp working table to store all CHARGERATES.RATENO for a  CHARGERATES.CHARGETYPENO
Create table #TEMPCHARGERATES (
			CASEID			int		NOT NULL,
 			RATENO			int		NOT NULL
			)


Declare	@nErrorCode 			int,
	@sLinkedCasesTableName  	nvarchar(100),
	@sSQLString 			nvarchar(4000),
	@sSQLString1 			nvarchar(4000),
	@sSQLString2 			nvarchar(4000),
	@sSQLString3 			nvarchar(4000),
	@sSQLString4 			nvarchar(4000),
	@sSQLString5 			nvarchar(4000),
	@sSQLString6 			nvarchar(4000),
	@sSQLStringLast			nvarchar(4000),
	@sInstructionTypes		nvarchar(200),
	@nActivityId		int,
	@hDocument 			int,			-- handle to the XML parameter
	@nCaseIdParam			int,			-- this is the case id extracted from @psXMLActivityRequestRow
	@dtWhenRequestedParam		datetime,
	@sSQLUserParam			nvarchar(40),
  	@nCPASchemaId			int,
	@nInproSchemaId			int,
	@nRateNo			int, 
	@nNumberOfRateNo		int,
	@nRateNoIndex			int,
	@nDisAmount 			decimal(11,2),
	@nDisAmountTotal		decimal(11,2),
	@nServAmountTotal 		decimal(11,2),
	@nServAmount 			decimal(11,2),
	@nLateMonth 			int,
	@sDisbCurrency			nvarchar(3),
	@nNumberOfLinkedCases		int,
	@nCurrentRow			int,
	@sNumberTypeRegGrant		nvarchar(50),
	@sTempTableCaseClass		nvarchar(100),		
	@nTranCountStart		int,		
	@nCaseId			int,			
	@sIRN				nvarchar(30),
	@nLetterNo			smallint,
	@sAlertXML			nvarchar(250),
	@dCurrentDateTime 		datetime, 
	@sSenderRequestIdentifier	nvarchar(14),
	@sSenderProducedDateTime	nvarchar(22),
	@sReceiver			nvarchar(30),
	@sSender			nvarchar(30),
	@sFileName			nvarchar(50),
	@bDebug				bit


set @nErrorCode = 0
set @bDebug = 0
set @nCPASchemaId = -3
set @nInproSchemaId = -1


-----------------------------------------------------------------------------------------------------------------------------
-- Only allow stored procedure run if the data base version is >=9 (SQL Server 2005 or later)
-----------------------------------------------------------------------------------------------------------------------------
If  (Select left( cast(SERVERPROPERTY('ProductVersion') as varchar), CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') as varchar))-1)   ) <= 8
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML("ed2", "This document can only be generated for databases on SQL Server 2005 or later.", null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End



-- Collect the key for the Activity Request row that has been passed as an XML parameter using OPENXML functionality.
If @nErrorCode = 0
Begin	
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @psXMLActivityRequestRow
	Set 	@nErrorCode = @@Error
End

-- Now select the key from the xml, at the same time joining it to the ACTIVITYREQUEST table.
If @nErrorCode = 0
Begin
	Set @sSQLString="
	select 	@nCaseIdParam = CASEID,
		@dtWhenRequestedParam = WHENREQUESTED,
		@sSQLUserParam = SQLUSER,
		@nLetterNo = LETTERNO
		from openxml(@hDocument,'ACTIVITYREQUEST',2)
		with ACTIVITYREQUEST "
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nCaseIdParam		int     	OUTPUT,
		  @dtWhenRequestedParam	datetime	OUTPUT,
		  @sSQLUserParam	nvarchar(40)	OUTPUT,
		  @nLetterNo		smallint	OUTPUT, 	
		  @hDocument		int',
		  @nCaseIdParam		= @nCaseIdParam		OUTPUT,
		  @dtWhenRequestedParam	= @dtWhenRequestedParam	OUTPUT,
		  @sSQLUserParam	= @sSQLUserParam	OUTPUT,
		  @nLetterNo		= @nLetterNo		OUTPUT,	
		  @hDocument 		= @hDocument
End

-- remove the document ignoring error checking.
Exec sp_xml_removedocument @hDocument 

If @nErrorCode = 0	
Begin
	-- Get the current request key (ACTIVITYID) using the alternate (old) key. 
	-- Note: OPENXML does not seem to allow extract of IDENTITY column.
	select @nActivityId=ACTIVITYID 
	from  ACTIVITYREQUEST 
	where CASEID = @nCaseIdParam 
	and WHENREQUESTED = @dtWhenRequestedParam 
	and SQLUSER = @sSQLUserParam

	set @nErrorCode = @@ERROR
End


--Ensure the case has valid Agent and Sender
If @nErrorCode = 0	
Begin	
	-- is agent exist for the case
	If not exists(select 1 from CASENAME CN where CN.CASEID=@nCaseIdParam and CN.NAMETYPE='A')
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML("ed6", "There is no agent for this case.", null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End


	If @nErrorCode = 0
	Begin
		-- Get Sender =
		-- _B Alias against HOME NAME CODE
		-- if none defined then raise error.
		Set @sSQLString="
		Select @sSender = NA.ALIAS 
				from NAMEALIAS NA
				where NA.ALIASTYPE = '_B'
				and NA.COUNTRYCODE  is null
				and NA.PROPERTYTYPE is null
				and NA.NAMENO=(	select SC.COLINTEGER 
						from SITECONTROL SC
						where SC.CONTROLID = 'HOMENAMENO')
			"
	
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@sSender		nvarchar(30)	OUTPUT,
					  @nCaseIdParam		int	',
					  @sSender		= @sSender	OUTPUT,
					  @nCaseIdParam		= @nCaseIdParam

		If @nErrorCode = 0 and @sSender is null
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML("ed7", "There is no valid GBPTO Account No. for the home name.  Please add an alias type [GBPTO Account No] against the Home Name.", null, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @nErrorCode = @@ERROR
		End
	End
End


-- Get cases that are currently in the ACTIVITYREQUEST table that can be batched into the same file.
-- i.e. cases that have the same agent and requesting the same letter. 
If @nErrorCode = 0
Begin
	-- create a temp table to store these cases
	select @sLinkedCasesTableName = '##' + replace(newid(),'-','_')
	set @nErrorCode=@@error

	If @nErrorCode = 0
	Begin
		Set @sSQLString="
		Create table " + @sLinkedCasesTableName +" (
					ROWID		smallint identity(1,1),
					CASEID		int,
					WHENREQUESTED	datetime,
					SQLUSER		nvarchar(40) collate database_default,
					RENEWALFEE	decimal(11,2),
					CURRENCY	nvarchar(3) collate database_default,
					LATEFEE		decimal(11,2),
					LATEMONTH	int
					)"
		Exec @nErrorCode=sp_executesql @sSQLString
	End


	-- Get cases that can be merged into the same XML. 
	If @nErrorCode = 0
	Begin
		Exec @nErrorCode=dbo.cs_GetLinkedCases 
				@psXMLActivityRequestRow = @psXMLActivityRequestRow, 
				@psLinkedCasesTable 	= @sLinkedCasesTableName
	End
End

-- Check to see if standing instructions are required to be derived for the Case(s)
-- in order to determine what RateNos are associated with the Charge Types.
If  @nErrorCode = 0 
Begin
	Set @sSQLString="
	Select @sInstructionTypes=CASE WHEN(@sInstructionTypes is not null) 
						THEN @sInstructionTypes+','+C.INSTRUCTIONTYPE
						ELSE C.INSTRUCTIONTYPE
				  END
	from (	select distinct CR.INSTRUCTIONTYPE
		from SITECONTROL S
		join CHARGERATES CR	on (CR.CHARGETYPENO=CAST(S.COLCHARACTER as int))
		where S.CONTROLID='Agent Renewal Fee'
		and CR.INSTRUCTIONTYPE is not null) C"

	Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@sInstructionTypes	nvarchar(200)	output',
				  @sInstructionTypes=@sInstructionTypes	output
End

-- Get the standing instruction for each Case if required
If @nErrorCode = 0
and @sInstructionTypes is not null
Begin
	Exec @nErrorCode=dbo.cs_GetStandingInstructionsBulk 
			@psInstructionTypes	=@sInstructionTypes,
			@psCaseTableName	=@sLinkedCasesTableName
End
	


--- Prepare data for Transaction HEADER 
If @nErrorCode = 0
Begin

	-- Get timestamp
	Select @dCurrentDateTime = getdate()

	-- Get @sSenderRequestIdentifier as Timestamp in format CCYYMMDDHHMMSS
	Select  @sSenderRequestIdentifier = RTRIM( CONVERT(char(4), year(@dCurrentDateTime))) 
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dCurrentDateTime)))) + CONVERT(char(2), month(@dCurrentDateTime)))
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dCurrentDateTime)))) + CONVERT(char(2), day(@dCurrentDateTime)))
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dCurrentDateTime)))) + CONVERT(char(2), datepart(hh,@dCurrentDateTime)))
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dCurrentDateTime)))) + CONVERT(char(2), datepart(mi,@dCurrentDateTime)))
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dCurrentDateTime)))) + CONVERT(char(2), datepart(ss,@dCurrentDateTime)))

	-- Get @sSenderProducedDateTime as Timestamp in format CCYY-MM-DDTHH:MM:SS.OZ 
	Select  @sSenderProducedDateTime = RTRIM( CONVERT(char(4), year(@dCurrentDateTime))) + '-' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dCurrentDateTime)))) + CONVERT(char(2), month(@dCurrentDateTime))) + '-' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dCurrentDateTime)))) + CONVERT(char(2), day(@dCurrentDateTime))) + 'T' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dCurrentDateTime)))) + CONVERT(char(2), datepart(hh,@dCurrentDateTime))) + ':' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dCurrentDateTime)))) + CONVERT(char(2), datepart(mi,@dCurrentDateTime))) + ':' +
	+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dCurrentDateTime)))) + CONVERT(char(2), datepart(ss,@dCurrentDateTime))) + '.0Z'

	-- Get the receiver (i.e. GBPTO)
	-- The receiver is the EDE Identifier alias against the case agent or the case agent name code
	set @sSQLString = "
		Select @sReceiver = isnull(
			(Select NA.ALIAS 
			From NAMEALIAS NA
			Where NA.ALIASTYPE = '_E'
			and NA.COUNTRYCODE  is null
			and NA.PROPERTYTYPE is null
			And NA.NAMENO=(	Select N.NAMENO 
					From NAME N
					JOIN CASENAME CN ON (CN.NAMENO = N.NAMENO)
					JOIN CASES C ON (C.CASEID = CN.CASEID) 
					WHERE C.CASEID =  @nCaseIdParam 
					And CN.NAMETYPE = 'A')) ,
			(Select N.NAMECODE 			-- receiver (CASE'S AGENT NAMECODE)
			FROM NAME N
			JOIN CASENAME CN ON (CN.NAMENO = N.NAMENO)
			JOIN CASES C ON (C.CASEID = CN.CASEID) 
			WHERE C.CASEID = @nCaseIdParam  
			AND CN.NAMETYPE = 'A' ) )"
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@sReceiver			nvarchar(30)	OUTPUT,
			  @nCaseIdParam		int	',
			  @sReceiver			= @sReceiver	OUTPUT,
			  @nCaseIdParam		= @nCaseIdParam

	-- Get Filename
	--RC changed from:
	--Set @sFileName = @sReceiver + '_' + @sSenderRequestIdentifier + '.xml'
	Set @sFileName = @sReceiver + '_BPOEDI_' + @sSenderRequestIdentifier + '.xml'

end
	

-------------------------------------------------------------------------------------------
------------------------------ Transaction HEADER -----------------------------------------
-------------------------------------------------------------------------------------------
If @nErrorCode = 0
Begin
	-- Create transaction header
	set @sSQLString = "
		Select 		
			(Select  
				'Agent Instruction' as 'SenderRequestType',
				'"+ @sSenderRequestIdentifier +"' as 'SenderRequestIdentifier',
				'"+ @sSender +"' as 'Sender', 
				'1.0' as 'SenderXSDVersion',
				(Select 
					'CPA Inprotech' as 'SenderSoftwareName',
					SC.COLCHARACTER as 'SenderSoftwareVersion'
					from SITECONTROL SC WHERE CONTROLID = 'DB Release Version' 
			   	for XML PATH('SenderSoftware'), TYPE
				),
				'"+ @sFileName +"'  as 'SenderFilename', 
				'"+ @sSenderProducedDateTime +"' as 'SenderProducedDateTime'
		   	for XML PATH('SenderDetails'), TYPE
			),
			(Select 
				'"+ @sReceiver +"' as 'Receiver'
				for XML PATH('ReceiverDetails'), TYPE
			)
			for XML PATH('TransactionHeader'), TYPE
			"
	exec(@sSQLString)
	set @nErrorCode=@@error
End







-- PREPARE TRANSACTION DATA FOR BODY  --
-- Calculate Agent renewal fee, late fee
-- Get mapping codes
If @nErrorCode = 0
Begin

	-- Get Inprotech Official Number code for 'REGISTRATION/GRANT' from CPAINPRO STANDARD MAPPING.  
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Select @sNumberTypeRegGrant = EX.CODE
			from MAPSTRUCTURE MS
			join ENCODEDVALUE E on (E.STRUCTUREID = MS.STRUCTUREID)
			join MAPPING M ON (M.INPUTCODEID = E.CODEID AND M.STRUCTUREID = E.STRUCTUREID)
			join ENCODEDVALUE EX ON (EX.CODEID = M.OUTPUTCODEID AND EX.STRUCTUREID = E.STRUCTUREID)
			where MS.TABLENAME = 'NUMBERTYPES'
			and E.SCHEMEID = @nCPASchemaId
			and UPPER(E.CODE) = 'REGISTRATION/GRANT'
			and EX.SCHEMEID = @nInproSchemaId"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@sNumberTypeRegGrant		nvarchar(50) output,
			@nCPASchemaId					int,
			@nInproSchemaId				int',
			@sNumberTypeRegGrant		= @sNumberTypeRegGrant output,
			@nCPASchemaId				= @nCPASchemaId,
			@nInproSchemaId			= @nInproSchemaId

		If @nErrorCode = 0 and @sNumberTypeRegGrant is null
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML("ed5", "There is no valid Inprotech mapping for Number Type REGISTRATION/GRANT.  Please add the required mapping.", null, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @nErrorCode = @@ERROR
		End

	End	





	-- Tokenised CASES.LOCALCLASSES and CASES.INTCLASSES and store in a temp table
	If @nErrorCode = 0
	Begin
		-- Generate a unique table name from the newid() 
		select @sTempTableCaseClass = '##' + replace(newid(),'-','_')

		-- and create the table	
		If @nErrorCode = 0
		Begin
			Set @sSQLString="
			Create table " + @sTempTableCaseClass +" (
						CASEID						int,
						CLASSTYPE					nvarchar(3) collate database_default,
						CLASS							nvarchar(250) collate database_default,
						SEQUENCENO					int
						)"
			Exec @nErrorCode=sp_executesql @sSQLString
		End

		-- load cases id into table for parsing case classes
		If @nErrorCode = 0
		Begin		
			Set @sSQLString = "Insert into "+ @sTempTableCaseClass +" (CASEID) 
					Select distinct CASEID 
					from " + @sLinkedCasesTableName 
			Exec @nErrorCode=sp_executesql @sSQLString
		End		

		-- Now tokenise case classes
		If @nErrorCode = 0
		Begin
			Exec @nErrorCode=ede_TokeniseCaseClass @sTempTableCaseClass	
		End
	End



	-- Get all RATENO associated with charge type "Agent Renewal Fee"
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into #TEMPCHARGERATES (CASEID, RATENO)
		select	distinct C.CASEID, H.RATENO
		from	SITECONTROL S
		cross join "+@sLinkedCasesTableName+" T
		      join CASES C		    on (C.CASEID=T.CASEID)
		left  join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID=T.CASEID)
		left  join INSTRUCTIONFLAG F	    on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE)
		      join CHARGERATES H on (H.CHARGETYPENO=CAST(S.COLCHARACTER as int)
					and(CASE WHEN(H.CASETYPE     is null) THEN '0' ELSE '1' END+
					    CASE WHEN(H.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
					    CASE WHEN(H.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
					    CASE WHEN(H.CASECATEGORY is null) THEN '0' ELSE '1' END+
					    CASE WHEN(H.SUBTYPE      is null) THEN '0' ELSE '1' END+
		    			    CASE WHEN(H.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
	  						=(	select max(CASE WHEN(H1.CASETYPE     is null) THEN '0' ELSE '1' END+
									   CASE WHEN(H1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
									   CASE WHEN(H1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
									   CASE WHEN(H1.CASECATEGORY is null) THEN '0' ELSE '1' END+
									   CASE WHEN(H1.SUBTYPE      is null) THEN '0' ELSE '1' END+
						    			   CASE WHEN(H1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
								from CHARGERATES H1
								where H1.CHARGETYPENO   =H.CHARGETYPENO
								and   H1.RATENO         =H.RATENO
								and  (H1.CASETYPE       =C.CASETYPE         OR H1.CASETYPE        is null)
								and  (H1.PROPERTYTYPE   =C.PROPERTYTYPE     OR H1.PROPERTYTYPE    is null)
								and  (H1.COUNTRYCODE    =C.COUNTRYCODE	    OR H1.COUNTRYCODE     is null)
								and  (H1.CASECATEGORY   =C.CASECATEGORY     OR H1.CASECATEGORY    is null)
								and  (H1.SUBTYPE        =C.SUBTYPE          OR H1.SUBTYPE         is null)
								and  (H1.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H1.INSTRUCTIONTYPE is null)
								and  (H1.FLAGNUMBER     =F.FLAGNUMBER       OR H1.FLAGNUMBER      is null))
					and  (H.CASETYPE       =C.CASETYPE         OR H.CASETYPE        is null)
					and  (H.PROPERTYTYPE   =C.PROPERTYTYPE     OR H.PROPERTYTYPE    is null)
					and  (H.COUNTRYCODE    =C.COUNTRYCODE      OR H.COUNTRYCODE     is null)
					and  (H.CASECATEGORY   =C.CASECATEGORY     OR H.CASECATEGORY    is null)
					and  (H.SUBTYPE        =C.SUBTYPE          OR H.SUBTYPE         is null)
					and  (H.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H.INSTRUCTIONTYPE is null)
					and  (H.FLAGNUMBER     =F.FLAGNUMBER       OR H.FLAGNUMBER      is null))
		where S.CONTROLID='Agent Renewal Fee'
		order by 1,2"
	
		exec @nErrorCode=sp_executesql @sSQLString
	
		Set @nNumberOfRateNo = @@ROWCOUNT
	End

	-- number of cases associated with the same agent
	If @nErrorCode = 0
	Begin
		Set @sSQLString="
		Select @nNumberOfLinkedCases=count(*)
		from  " + @sLinkedCasesTableName

		exec @nErrorCode= sp_executesql @sSQLString,
				N'@nNumberOfLinkedCases	int	OUTPUT',
				  	@nNumberOfLinkedCases=@nNumberOfLinkedCases	OUTPUT
	End



	-- Get Renewal fee and late fee for all cases in the temp table @sLinkedCasesTableName
	Set @nCurrentRow = 1
	While (@nErrorCode = 0) and  (@nCurrentRow <= @nNumberOfLinkedCases)
	Begin
		Set @sSQLString="
			Select 	@nCaseId =LC.CASEID,
			@sIRN	= C.IRN
			from " + @sLinkedCasesTableName +" LC
			join CASES C on (C.CASEID = LC.CASEID)
			where LC.ROWID = @nCurrentRow "

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@nCaseId		int     	OUTPUT,
						  @sIRN			nvarchar(30)	OUTPUT,
						  @nCurrentRow		int',
						  @nCaseId	= @nCaseId		OUTPUT,
						  @sIRN		= @sIRN			OUTPUT,
						  @nCurrentRow	= @nCurrentRow

		-- Get the first RateNo to process for the Case.
		Set @sSQLString="
		Select @nRateNo=min(RATENO)
		from #TEMPCHARGERATES
		where CASEID=@nCaseId"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nRateNo		int	OUTPUT,
					  @nCaseId		int',
					  @nRateNo=@nRateNo		OUTPUT,
					  @nCaseId=@nCaseId


		-- Get Agent Renewal Fee for the case
		Set @nDisAmountTotal = 0
		Set @nDisAmount = 0
		Set @nServAmountTotal = 0
		Set @nServAmount = 0
		Set @nLateMonth = 0

		While @nRateNo is not null
		and   @nErrorCode = 0
		Begin
 		   	If @bDebug = 1
				print ('Get fee for all cases.  Current RateNo is : ' + cast(@nRateNo as varchar))

			-- calculate the fee for each RATENO for the RATETYPE
			Exec @nErrorCode = dbo.FEESCALC 	
						@psIRN	  = @sIRN, 
						@pnRateNo = @nRateNo,
						@prsDisbCurrency   = @sDisbCurrency	OUTPUT, 
						@prnDisbAmount	   = @nDisAmount	OUTPUT,	-- Renewal Fee
						@prnServAmount	   = @nServAmount	OUTPUT,	-- Late Fee
						@pnServPeriodCount = @nLateMonth	OUTPUT	-- Late Month

			If (@nErrorCode = 0) 
			Begin
				set @nDisAmountTotal  = @nDisAmountTotal  + isnull(@nDisAmount,0)
				set @nServAmountTotal = @nServAmountTotal + isnull(@nServAmount,0)
			End

			-- Reset error code if no fee could be calculated
			If @nErrorCode=-2
				Set @nErrorCode=0

			If @nErrorCode <> 0
			Begin
				Set @sAlertXML = dbo.fn_GetAlertXML("ed9", "Error occurred when fees are calculated for case IRN {1}, Rate Number {2}.  Letter generation failed.", @sIRN, @nRateNo, null, null, null)
				RAISERROR(@sAlertXML, 14, 1)
				Set @nErrorCode = @@ERROR
			End

			-- get the next rateno for the current Case
	
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				Select @nRateNo=min(RATENO)
				from #TEMPCHARGERATES
				where CASEID=@nCaseId
				and RATENO>@nRateNo"
		
				exec @nErrorCode=sp_executesql @sSQLString,
								N'@nRateNo		int	OUTPUT,
								  @nCaseId		int',
								  @nRateNo=@nRateNo		OUTPUT,
								  @nCaseId=@nCaseId
			End

		End /* While @nRateNoIndex <= @nNumberOfRateNo */

		/* Save the fee in the temp table */
		If @nErrorCode = 0 and @nDisAmountTotal != 0
		Begin
		    	Set  @sSQLString="
			Update "+ @sLinkedCasesTableName +" 
			set	RENEWALFEE = @nDisAmountTotal,
				CURRENCY	= @sDisbCurrency,
				LATEFEE  = @nServAmountTotal,
				LATEMONTH	= @nLateMonth
			where  ROWID = @nCurrentRow"

		    	Exec @nErrorCode=sp_executesql @sSQLString,
				      		N'@nDisAmountTotal	decimal(11,2),
						  @sDisbCurrency	nvarchar(3),
						  @nServAmountTotal	decimal(11,2),
						  @nLateMonth		int,
						  @nCurrentRow		int',	
		  				  @nDisAmountTotal	= @nDisAmountTotal,
						  @sDisbCurrency	= @sDisbCurrency,
						  @nServAmountTotal	= @nServAmountTotal,
						  @nLateMonth		= @nLateMonth,
		  				  @nCurrentRow		= @nCurrentRow
		End

		-- next row index
	   Set @nCurrentRow = @nCurrentRow + 1
	End  /* WHILE LOOP for linked cases */
End



-------------------------------------------------------------------------------------------
------------------------------ Transaction BODY -----------------------------------------
-------------------------------------------------------------------------------------------
If @nErrorCode = 0
Begin
	Set @sSQLString1 = ""
	Set @sSQLString2 = ""
	Set @sSQLString3 = ""
	Set @sSQLString4 = ""
	Set @sSQLString5 = ""
	Set @sSQLString6 = ""
	Set @sSQLStringLast = ""

	Set @sSQLString1 = "	
	Select 
		(
		Select 	-- <TransactionBody>
			TT.ROWID  as 'TransactionIdentifier',
		   ( 
		   Select    -- <TransactionContentDetails>
		      'Renewal Instruction' as 'TransactionCode', 
		      (
		      Select 	-- <TransactionData>
		         null,
		        (	
		        select 	-- <CaseDetails>
		            C.CASEID as 'SenderCaseIdentifier', 
		            C.IRN 'SenderCaseReference', 
						isnull(CTV.CASETYPE_CPAXML, C.CASETYPE) as 'CaseTypeCode',
						isnull(PTV.PROPERTYTYPE_CPAXML, C.PROPERTYTYPE) as 'CasePropertyTypeCode', 
						isnull(COU.ALTERNATECODE, C.COUNTRYCODE) as 'CaseCountryCode',
		     	      ( 
						Select 		-- <IdentifierNumberDetails>
							isnull(NTV.NUMBERTYPE_CPAXML, ONS.NUMBERTYPE) as 'IdentifierNumberCode',  
							ONS.OFFICIALNUMBER as 'IdentifierNumberText'
							from OFFICIALNUMBERS ONS
							join NUMBERTYPE_VIEW NTV ON (NTV.NUMBERTYPE_INPRO = ONS.NUMBERTYPE AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
							where ONS.CASEID = C.CASEID
							and ONS.ISCURRENT = 1
							and ONS.NUMBERTYPE = '" + @sNumberTypeRegGrant + "' 
		               for XML PATH('IdentifierNumberDetails'), TYPE
		            )
	"

	Set @sSQLString2 = ",
		            ( 
		            Select	-- <EventDetails>  for event 'Next Renewal Date' only
						   isnull(EV.EVENT_CPAXML, E.EVENTDESCRIPTION) as 'EventCode', 
							replace( convert(nvarchar(10), CE.EVENTDATE, 111), '/', '-') as 'EventDate', 
							replace( convert(nvarchar(10), isnull(CE.EVENTDATE, CE.EVENTDUEDATE), 111), '/', '-') as 'EventDueDate', 
						   CE.CYCLE as 'EventCycle', 
						   CE.EVENTTEXT as 'EventText'
							from CASES CX
							left Join (	select min(O.CYCLE) as [CYCLE], O.CASEID
									from OPENACTION O
									join SITECONTROL SC on (SC.CONTROLID='Main Renewal Action')
									where O.ACTION=SC.COLCHARACTER
									and O.POLICEEVENTS=1
									group by O.CASEID) OA on (OA.CASEID=CX.CASEID)
							left Join CASEEVENT CE	on (CE.CASEID = OA.CASEID
										and CE.EVENTNO = -11
										and CE.CYCLE=OA.CYCLE)
							left join EVENT_VIEW EV on (EV.EVENT_INPRO = CE.EVENTNO AND EV.EVENT_CPAXML is not null)
							left join EVENTS E on (E.EVENTNO = CE.EVENTNO)
							Where CX.CASEID=C.CASEID
		               for XML PATH('EventDetails'), TYPE
		            )
	"

	Set @sSQLString3 = ",
		            ( 
		     	      Select	-- <NameDetails>
							isnull(NTV.NAMETYPE_CPAXML, CN.NAMETYPE) as 'NameTypeCode', 
							CN.SEQUENCE as 'NameSequenceNumber',
							CN.REFERENCENO as 'NameReference',
			            (
			            Select   --<AddressBook>
		                  null,
				            (
				            Select --<FormattedNameAddress>
		                     null, 
		                     (
		                     Select -- <Name>
									   N.NAMECODE as 'SenderNameIdentifier', 
	                        	N.TITLE as 'FormattedName/NamePrefix',

										-- NAME.USEDASFLAG & 1 = 1 is Individual, else Organization.
										Case when (N.USEDASFLAG & 1 = 1) then
											left (N.FIRSTNAME, charindex(' ', N.FIRSTNAME))
										end as 'FormattedName/FirstName',

										Case when (N.USEDASFLAG & 1 = 1 and (charindex(' ', ltrim(rtrim(N.FIRSTNAME)))>0)) then
											right (ltrim(rtrim(N.FIRSTNAME)), len(ltrim(rtrim(N.FIRSTNAME))) - charindex(' ', ltrim(rtrim(N.FIRSTNAME))))  
										end as 'FormattedName/MiddleName',

										Case when (N.USEDASFLAG & 1 = 1) then
		                        	N.NAME 
										end as 'FormattedName/LastName',

										Case when not (N.USEDASFLAG & 1 = 1) then
		                        	N.NAME 
										end as 'FormattedName/OrganizationName'

	                        	from NAME N
										left join INDIVIDUAL IND on (IND.NAMENO = N.NAMENO)
									   where N.NAMENO = CN.NAMENO 
		                        for XML PATH('Name'), TYPE
		                     )
		                     for XML PATH('FormattedNameAddress'), TYPE
		                  )  -- <FormattedNameAddress>
	                     for XML PATH('AddressBook'), TYPE
	                  )  -- <AddressBook>
			
							from CASENAME CN
							join NAMETYPE_VIEW NTV on (NTV.NAMETYPE_INPRO = CN.NAMETYPE and NTV.NAMETYPE_CPAXML is not null)
							where CN.CASEID = C.CASEID
							and CN.NAMETYPE in ('O', 'I')
                     for XML PATH('NameDetails'), TYPE
                  )  -- <NameDetails>
	"

	Set @sSQLString4 = ",
		     	      ( 
		            Select     	-- <GoodsServicesDetails> for International classes 'Nice' 
		               'Nice' as 'ClassificationTypeCode',
		     	         ( 
		               Select     	-- <ClassDescriptionDetails>  
								null,
								(
								Select  -- <ClassDescription>
			                  IC.CLASS as 'ClassNumber'
			                  from  " + @sTempTableCaseClass + " IC
			                  where IC.CASEID =  C.CASEID
									and IC.CLASSTYPE = 'INT'
									and IC.CLASS is not null
									order by IC.SEQUENCENO
		                  	for XML PATH('ClassDescription'), TYPE
								)
		                  for XML PATH('ClassDescriptionDetails'), TYPE
		               )  
	                  from  CASES LC
	                  where LC.CASEID =  C.CASEID
							and LC.INTCLASSES IS NOT NULL
		               for XML PATH('GoodsServicesDetails'), TYPE
		            ),
		     	      ( 
		            Select     	-- <GoodsServicesDetails> for Local classes 'Domestic' 
		               'Domestic' as 'ClassificationTypeCode',
		     	         ( 
		               Select     	-- <ClassDescriptionDetails>  
								null,
								(
								Select	-- <ClassDescription>
			                  IC.CLASS as 'ClassNumber'
			                  from  " + @sTempTableCaseClass + " IC
			                  where IC.CASEID =  C.CASEID
									and IC.CLASSTYPE = 'LOC'
									order by IC.SEQUENCENO
			                  for XML PATH('ClassDescription'), TYPE
								)	
		                  for XML PATH('ClassDescriptionDetails'), TYPE
		               )  
	                  from  CASES LC
	                  where LC.CASEID =  C.CASEID
							and LC.LOCALCLASSES IS NOT NULL
		               for XML PATH('GoodsServicesDetails'), TYPE
		            )
	"

	Set @sSQLString5 = "	
						from CASES C
						left join CASETYPE_VIEW CTV on (CTV.CASETYPE_INPRO = C.CASETYPE AND CTV.CASETYPE_CPAXML IS NOT NULL)
						left join PROPERTYTYPE_VIEW PTV on (PTV.PROPERTYTYPE_INPRO = C.PROPERTYTYPE AND PTV.PROPERTYTYPE_CPAXML IS NOT NULL)
						left join COUNTRY COU on (COU.COUNTRYCODE = C.COUNTRYCODE)
						where C.CASEID = TT.CASEID
	               for XML PATH('CaseDetails'), TYPE
					)  -- <CaseDetails>
	"


	Set @sSQLString6 = ",	
					(
					Select		-- <PaymentDetails>
						(
						select 	-- <Payment>
							(	
				        	select 	-- <PaymentFeeDetails>
								null,
								(
								Select 		-- <PaymentFee>  renewal fee
									'Renewal Fee' as 'FeeIdentifier',  
									TTX.CURRENCY as 'FeeAmount/@currencyCode', 
									TTX.RENEWALFEE as 'FeeAmount'
									from " + @sLinkedCasesTableName + " TTX 
									where TTX.CASEID = TT.CASEID
									and TTX.RENEWALFEE is not null
									for XML PATH('PaymentFee'), TYPE
								),
								(
								Select 		-- <PaymentFee>  late fee
									'Late Fee' as 'FeeIdentifier',  
									TT.CURRENCY as 'FeeAmount/@currencyCode', 
									TT.LATEFEE as 'FeeAmount', 
									TT.LATEMONTH as 'FeeUnitQuantity'
									from " + @sLinkedCasesTableName + " TTX 
									where TTX.CASEID = TT.CASEID
									and isnull(TTX.LATEFEE,0) != 0
									for XML PATH('PaymentFee'), TYPE
								)
								from " + @sLinkedCasesTableName + " TTX 
								where TTX.CASEID = TT.CASEID
								and (TTX.RENEWALFEE is not null or TTX.LATEFEE is not null)
								for XML PATH('PaymentFeeDetails'), TYPE
							)	-- <PaymentFeeDetails>
							for XML PATH('Payment'), TYPE
						)	-- <Payment>
						for XML PATH('PaymentDetails'), TYPE
					)	-- <PaymentDetails>

	"

	Set @sSQLStringLast = "	
            	for XML PATH('TransactionData'), TYPE
				) 	-- <TransactionData>
	      	for XML PATH('TransactionContentDetails'), TYPE
			)	-- <TransactionContentDetails>
			
			from " + @sLinkedCasesTableName + " TT
			where TT.CASEID = MAIN.CASEID 
			for XML PATH(''), ROOT('TransactionBody')
		) as TransBody
		from  " + @sLinkedCasesTableName + " MAIN "
	
	exec(@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString5+@sSQLString6+@sSQLStringLast)
	set @nErrorCode=@@error

End



-- Save the filename into ACTIVYTYREQUEST table to enable centura to save the file with the same name
If @nErrorCode = 0 
Begin
	-- Start a new transaction
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	Update ACTIVITYREQUEST
	set FILENAME = @sFileName
	where CASEID = @nCaseIdParam
	and  SQLUSER = @sSQLUserParam
	and WHENREQUESTED = @dtWhenRequestedParam

	set @nErrorCode=@@error

	-- Flag rows as processed
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = "
		Update ACTIVITYREQUEST 
		set PROCESSED = 1, 
		GROUPACTIVITYID = 	"+ cast(@nActivityId as nvarchar(30)) +",		-- tag requests as processed together with the current request
		HOLDFLAG = 1, 
		WHENOCCURRED = getdate(),
		FILENAME = '"+ @sFileName +"'
		from ACTIVITYREQUEST AR
 		join " + @sLinkedCasesTableName +" LC  ON ( LC.CASEID 	 = AR.CASEID
				and	LC.WHENREQUESTED = AR.WHENREQUESTED
				and	LC.SQLUSER	 = AR.SQLUSER )
		where ( LC.CASEID 	!= "+ cast(@nCaseIdParam as nvarchar) +"
				or	cast(LC.WHENREQUESTED as nvarchar)!= '"+ cast(@dtWhenRequestedParam as nvarchar) +"'
				or	LC.SQLUSER	!= '"+ @sSQLUserParam +"')"

		exec @nErrorCode=sp_executesql @sSQLString
	End			

	-- Commit transaction if successful
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION  
		Else
			ROLLBACK TRANSACTION
	End
End

If @nErrorCode <> 0 AND @sAlertXML IS NULL
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML("ed8", "An error has occurred.  Letter generation failed.", null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End


-- Now drop the temporary table 
if exists(select * from tempdb.dbo.sysobjects where name = @sLinkedCasesTableName)
Begin
	Set @sSQLString = "drop table " +  @sLinkedCasesTableName
	exec sp_executesql @sSQLString
End

if exists(select * from tempdb.dbo.sysobjects where name = @sTempTableCaseClass)
Begin
	Set @sSQLString = "drop table " +  @sTempTableCaseClass
	exec sp_executesql @sSQLString
End



RETURN @nErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.XML_AgentRenewalInstrLetter2 to public
go
