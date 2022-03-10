-----------------------------------------------------------------------------------------------------------------------------
-- Creation of XML_AgentRenewalInstrLetter
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[XML_AgentRenewalInstrLetter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.XML_AgentRenewalInstrLetter.'
	drop procedure dbo.XML_AgentRenewalInstrLetter
end
print '**** Creating procedure dbo.XML_AgentRenewalInstrLetter...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.XML_AgentRenewalInstrLetter 
		@psXMLActivityRequestRow	ntext
AS
-- PROCEDURE :	XML_AgentRenewalInstrLetter
-- VERSION :	15
-- DESCRIPTION:	Generate renewal instructions for cases in CPAXML format.
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 24 May 2006	DL	12388	1	Procedure created
-- 14 Jul 2006	DL	12388	2	Bugs fixed
-- 18 Jul 2006	AT	12388	3	Modified elements to conform to CPA-XML v0.6
-- 05 Dec 2006	DL	13115	4	Bugs fixed
-- 29 Jan 2007	DL	13114	5	Add default database collation to temp tables
-- 13 Feb 2007  DL	13115	6	Add parent element <PaymentDetails> 
-- 12 Jun 2007	MF	14908	7	Use a best fit search to get the RateNos that apply to a Case for
--					a given Charge Type.
-- 18 Jun 2007	AT	14908	8	Continue processing if FeesCalc returns error.
-- 24 Jan 2008	RC	15849	9	File naming conventioned changed to indicate which type of file
-- 17 Jun 2008	DL	16531	10	Change @sSQLUserParam to nvarchar(40)
-- 10 Aug 2008	DL	16723	11	Tag requests to enable DocGen to attach the bulk output file to these cases.
-- 15 Dec 2008	MF	17136	12	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 04 Jun 2010	MF	18703	13	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be null here
-- 01 Jul 2010	MF	18758	14	Increase the column size of Instruction Type to allow for expanded list.
-- 14 Sep 2015	DL	R51576	15	Include transaction count in header for GBTM11 file

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

Declare	@nErrorCode 		int,
	@sErrorMsg		nvarchar(4000),
	@sErrorMsgSaved		nvarchar(1000),
	@sLinkedCasesTableName  nvarchar(50),
	@sSQLString 		nvarchar(4000),
	@sSQLString1 		nvarchar(4000),
	@sSQLString2 		nvarchar(4000),
	@sSQLString3 		nvarchar(4000),
	@sSQLString4 		nvarchar(4000),
	@sSQLString5 		nvarchar(4000),
	@sSQLString6 		nvarchar(4000),
	@sSQLString7 		nvarchar(4000),
	@sInstructionTypes	nvarchar(200),
	@hDocument 		int,			-- handle to the XML parameter
	@nCaseIdParam		int,			-- this is the case id extracted from @psXMLActivityRequestRow
	@dtWhenRequestedParam	datetime,
	@sSQLUserParam		nvarchar(40),
	@nActivityId		int,
	@nCaseId		int,			
	@sIRN			nvarchar(30),
	@dtWhenRequested	datetime,
	@sSQLUser		nvarchar(40),
	@nLetterNo		smallint,
	@nNumberOfLinkedCases	int,
	@nCurrentRow		int,

	@dCurrentDateTime 		datetime, 
	@sSenderRequestIdentifier	nvarchar(14),
	@sSenderProducedDateTime	nvarchar(22),
	@sReceiver			nvarchar(30),
	@sSender			nvarchar(30),
	@sFileName			nvarchar(50),

	@sMappedCaseType		nvarchar(50),
	@sMappedPropertyType		nvarchar(50),
	@bFoundMappingCaseTypeFlag	bit,
	@bFoundMappingPropertyFlag	bit,

	@nStructureId			int,
	@sInputCode			nvarchar(50),
	@nInputSchemeId			int,
	@nOutputSchemeId		int,

	@sCaseType		nvarchar(50),
	@bCaseTypeFlag		bit,
	@bPropertyTypeFlag	bit,
	@sPropertyType		nvarchar(50),
	@sCountryCode		nvarchar(50),
	@sLocalClasses		nvarchar(254),
	@sIntClasses		nvarchar(254),
	@sDisbCurrency		nvarchar(3),

	@nNumberTypeStructureId	int,
	@nSchemeIdCPAINPRO	int,
	@nSchemeIdCPAXML	int,
	@nRateNo		int, 
	@nDisAmount 		decimal(11,2),
	@nDisAmountTotal	decimal(11,2),
	@nNumberOfRateNo	int,
	@nRateNoIndex		int,
	@bDebug			bit


set @nErrorCode = 0
set @bDebug = 0


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


If @nErrorCode = 0	
Begin	
	Exec sp_xml_removedocument @hDocument 
	Set @nErrorCode	  = @@Error
End

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
	   Raiserror ('There is no agent for this case.',16,1)
	   Return -1
	End
	
	-- Get Sender =
	-- _H Alias against Agent or 
	-- _H Alias against HOME NAME CODE or
	-- Name code of HOME NAME NO (site control)
	-- if none defined then raise error.
	Set @sSQLString="
	Select @sSender = isnull(
		(Select NA.ALIAS 
		from NAMEALIAS NA
		where NA.ALIASTYPE = '_H'
		and NA.COUNTRYCODE  is null
		and NA.PROPERTYTYPE is null
		and NA.NAMENO=(	select N.NAMENO 
				from NAME N
				join CASENAME CN ON (CN.NAMENO = N.NAMENO)
				join CASES C ON (C.CASEID = CN.CASEID) 
				where C.CASEID =  @nCaseIdParam 
				And CN.NAMETYPE = 'A')) ,
		isnull (

			(select NA.ALIAS 
			from NAMEALIAS NA
			where NA.ALIASTYPE = '_H'
			and NA.COUNTRYCODE  is null
			and NA.PROPERTYTYPE is null
			and NA.NAMENO=(	select SC.COLINTEGER 
					from SITECONTROL SC
					where SC.CONTROLID = 'HOMENAMENO') ),
			(select NAMECODE
			from NAME 
			where NAMENO=(select SC.COLINTEGER 
					from SITECONTROL SC
					where SC.CONTROLID = 'HOMENAMENO') )
			)
		) "
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@sSender		nvarchar(30)	OUTPUT,
				  @nCaseIdParam		int	',
				  @sSender		= @sSender	OUTPUT,
				  @nCaseIdParam		= @nCaseIdParam


	If @nErrorCode = 0 and @sSender is null
	Begin
	   Raiserror ('There is no valid sender for this case.',16,1)
	   Return -1
	End


End




-- Generate a unique table name from the newid() 
If @nErrorCode = 0
Begin
	select @sLinkedCasesTableName = '##' + replace(newid(),'-','_')
	set @nErrorCode=@@error
End


-- Create a temporary table to be used for storing cases with same criteria
-- which can be merged in the same XML output file.
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Create table " + @sLinkedCasesTableName +" (
				RowPosition		smallint identity(1,1),
				CASEID			int,
				WHENREQUESTED		datetime,
				SQLUSER			nvarchar(40) collate database_default,
				MCASETYPE		nvarchar(50) collate database_default,
				MCASETYPEFLAG		bit,
				MPROPERTYTYPE		nvarchar(50) collate database_default,
				MPROPERTYTYPEFLAG	bit,
				AGENTRENEWALFEE		decimal(11,2),
				CURRENCY		nvarchar(3) collate database_default
				)"
	Exec @nErrorCode=sp_executesql @sSQLString
End


-- Get cases that can be merged into the same XML. These cases are stored in temp table @sLinkedCasesTableName
If @nErrorCode = 0
Begin
	Exec @nErrorCode=dbo.cs_GetLinkedCases 
			@psXMLActivityRequestRow = @psXMLActivityRequestRow, 
			@psLinkedCasesTable 	= @sLinkedCasesTableName
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


-- number of cases associated with the same agent
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select @nNumberOfLinkedCases=count(*)
	from " + @sLinkedCasesTableName

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nNumberOfLinkedCases	int	OUTPUT',
			  @nNumberOfLinkedCases=@nNumberOfLinkedCases	OUTPUT
End


--- Transaction HEADER --
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

	-- Get receiver 
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
		AND CN.NAMETYPE = 'A' ) )
	set @nErrorCode=@@error

	-- Get Filename
	--RC changed from:
	--Set @sFileName = @sReceiver + '_' + @sSenderRequestIdentifier + '.xml'
	Set @sFileName = @sReceiver + '_GBTM11_' + @sSenderRequestIdentifier + '.xml'
	

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
						'Inprotech' as 'SenderSoftwareName',
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
				),
				(Select null, --<TransactionSummaryDetails>	-- R51576
					(Select 'Transactions' as 'CountTypeCode',
					'Number of transactions included in file' as 'CountDescription',
					" + cast( @nNumberOfLinkedCases as nvarchar(13)) + " as 'Count'
					for XML PATH('CountSummary'), TYPE) 
					for XML Path('TransactionSummaryDetails'), TYPE)		    			
				for XML PATH('TransactionHeader'), TYPE
				"
		exec(@sSQLString)
		set @nErrorCode=@@error
	End
End


-- PREPARE TRANSACTION DATA FOR BODY  --
-- Get details data for each case
-- 1. Get mapping code for CASETYPE and PROPERTYTYPE from inpro to CPAXML scheme 
-- 2. Calculate Agent renewal fee
If @nErrorCode = 0
Begin
	-- Get schema id
	Select @nSchemeIdCPAXML=SCHEMEID 
	from ENCODINGSCHEME 
	where SCHEMECODE = 'CPAXML'

	Select @nSchemeIdCPAINPRO=SCHEMEID 
	from ENCODINGSCHEME 
	where SCHEMECODE = 'CPAINPRO'

	Set @nOutputSchemeId = @nSchemeIdCPAXML
	Set @nInputSchemeId = @nSchemeIdCPAINPRO


	-- Get NUMBERTYPE Structure id
	Select @nNumberTypeStructureId = STRUCTUREID 
	from MAPSTRUCTURE 
	where TABLENAME = 'NUMBERTYPES' 
	and KEYCOLUMNAME = 'NUMBERTYPE'  

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


	Set @nCurrentRow = 1
	-- Get mapping codes for all cases in the temp table @sLinkedCasesTableName
	While (@nErrorCode = 0) and  (@nCurrentRow <= @nNumberOfLinkedCases)
	Begin
	    If @bDebug = 1
	    	print ('Get mapping code for all cases.  current row is : ' + cast(@nCurrentRow as char(3)))

	    Set @sSQLString="
   	    	Select 	@nCaseId =LC.CASEID,
			@sIRN	= C.IRN,
			@dtWhenRequested = LC.WHENREQUESTED,
			@sCaseType=C.CASETYPE, 
		       	@sPropertyType=C.PROPERTYTYPE
   	    	from " + @sLinkedCasesTableName +" LC
	    	join CASES C on (C.CASEID = LC.CASEID)
   	    	where LC.RowPosition = @nCurrentRow "
	    Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nCaseId		int     	OUTPUT,
		  @sIRN			nvarchar(30)	OUTPUT,
		  @dtWhenRequested	datetime	OUTPUT,
		  @sCaseType		nvarchar(50)	OUTPUT,
		  @sPropertyType	nvarchar(50)	OUTPUT, 	
		  @nCurrentRow		int',
		  @nCaseId		= @nCaseId		OUTPUT,
		  @sIRN			= @sIRN			OUTPUT,
		  @dtWhenRequested	= @dtWhenRequested	OUTPUT,
		  @sCaseType		= @sCaseType		OUTPUT,
		  @sPropertyType	= @sPropertyType	OUTPUT, 	
		  @nCurrentRow		= @nCurrentRow

		-- Get CASETYPE mapping code
		Set @sMappedCaseType=null
		Set @bFoundMappingCaseTypeFlag=null

		If (@nErrorCode = 0) and (@sCaseType is not null)
		Begin
			Exec @nErrorCode = dbo.cs_GetMappingCode 
						@psMappedCode		= @sMappedCaseType OUTPUT,
						@pbFoundMappingFlag	= @bFoundMappingCaseTypeFlag OUTPUT,
						@psMapStructureTableName= 'CASETYPE',
						@psInputCode		= @sCaseType,
						@pnInputSchemeId	= @nInputSchemeId,
						@pnOutputSchemeId	= @nOutputSchemeId
		End

		-- Get PROPERTYTYPE mapping code
		Set @sMappedPropertyType=null
		Set @bFoundMappingPropertyFlag=null

		If (@nErrorCode = 0) and (@sPropertyType is not null)
		Begin
			Exec @nErrorCode= dbo.cs_GetMappingCode 
				@psMappedCode		= @sMappedPropertyType OUTPUT,
				@pbFoundMappingFlag	= @bFoundMappingPropertyFlag OUTPUT,
				@psMapStructureTableName= 'PROPERTYTYPE',
				@psInputCode		= @sPropertyType,
				@pnInputSchemeId	= @nInputSchemeId,
				@pnOutputSchemeId	= @nOutputSchemeId 
		End

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

		While @nRateNo is not null
		and   @nErrorCode = 0
		Begin
 			If @bDebug = 1
			    print ('Get fee for all cases.  current row is : ' + cast(@nRateNoIndex as char(3)))

			-- calculate the fee for each RATENO for the RATETYPE

			Exec @nErrorCode = dbo.FEESCALC 	
						@psIRN		 = @sIRN, 
						@pnRateNo 	 = @nRateNo,
						@prsDisbCurrency = @sDisbCurrency OUTPUT, 
						@prnDisbAmount 	 = @nDisAmount	  OUTPUT

			If (@nErrorCode = 0) and (@nDisAmount is not null)
				set @nDisAmountTotal = @nDisAmountTotal + @nDisAmount

			-- Ignore error code -2 and continue processing.
			If (@nErrorCode = -2)
				Set @nErrorCode = 0
			
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

		End -- While @nRateNo is not null

		-- Save the fee in the temp table
		If @nErrorCode = 0
		Begin
		    	Set  @sSQLString="
					Update "+ @sLinkedCasesTableName +" 
					set	AGENTRENEWALFEE   = @nDisAmountTotal,
						CURRENCY	  = @sDisbCurrency,
						MPROPERTYTYPE	  = @sMappedPropertyType,
						MPROPERTYTYPEFLAG = @bFoundMappingPropertyFlag,
						MCASETYPE	  = @sMappedCaseType,
						MCASETYPEFLAG	  = @bFoundMappingCaseTypeFlag
					where  RowPosition = @nCurrentRow"

		    	Exec @nErrorCode=sp_executesql @sSQLString,
				      			N'@nDisAmountTotal		decimal(11,2),
							  @sDisbCurrency		nvarchar(3),
							  @sMappedPropertyType		nvarchar(50),
							  @sMappedCaseType		nvarchar(50),
							  @bFoundMappingCaseTypeFlag	bit,
							  @bFoundMappingPropertyFlag	bit,
							  @nCurrentRow			int',	
			  			 	  @nDisAmountTotal		= @nDisAmountTotal,
							  @sDisbCurrency  		= @sDisbCurrency,
					  		  @sMappedPropertyType		= @sMappedPropertyType,
							  @sMappedCaseType		= @sMappedCaseType,
							  @bFoundMappingCaseTypeFlag	= @bFoundMappingCaseTypeFlag,
					  		  @bFoundMappingPropertyFlag	= @bFoundMappingPropertyFlag, 
			  				  @nCurrentRow	  		= @nCurrentRow
		End


		-- next row index
	   Set @nCurrentRow = @nCurrentRow + 1
   
	End  /* WHILE LOOP for linked cases */
End



-- For each case to be processed, if there is no mapping  
-- then log error message in ACTIVITYREQUEST.SYSTEMMESSAGE.
set @sErrorMsgSaved = null
If @nErrorCode = 0
Begin
        If @bDebug = 1
   	   PRINT('Checking mapping...')

	Set @nCurrentRow = 1
	While (@nErrorCode = 0) and  (@nCurrentRow <= @nNumberOfLinkedCases)
	Begin
	    Set @sSQLString="
   	    	Select 	@nCaseId =LC.CASEID,
			@sIRN	= C.IRN,
			@dtWhenRequested = LC.WHENREQUESTED,
			@sSQLUser = LC.SQLUSER,
			@sCaseType=LC.MCASETYPE, 
		       	@sPropertyType=LC.MPROPERTYTYPE,
			@bCaseTypeFlag = LC.MCASETYPEFLAG,
			@bPropertyTypeFlag = LC.MPROPERTYTYPEFLAG
   	    	from " + @sLinkedCasesTableName +" LC
	    	join CASES C on (C.CASEID = LC.CASEID)
   	    	where LC.RowPosition = @nCurrentRow "
	    Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nCaseId		int     	OUTPUT,
		  @sIRN			nvarchar(30)	OUTPUT,
		  @dtWhenRequested	datetime	OUTPUT,
		  @sSQLUser		nvarchar(40)	OUTPUT,
		  @sCaseType		nvarchar(50)	OUTPUT,
		  @sPropertyType	nvarchar(50)	OUTPUT, 	
		  @bCaseTypeFlag	bit		OUTPUT,
		  @bPropertyTypeFlag	bit		OUTPUT,
		  @nCurrentRow		int',
		  @nCaseId		= @nCaseId		OUTPUT,
		  @sIRN			= @sIRN			OUTPUT,
		  @dtWhenRequested	= @dtWhenRequested	OUTPUT,
		  @sSQLUser		= @sSQLUser		OUTPUT,
		  @sCaseType		= @sCaseType		OUTPUT,
		  @sPropertyType	= @sPropertyType	OUTPUT,
		  @bCaseTypeFlag	= @bCaseTypeFlag	OUTPUT,
		  @bPropertyTypeFlag	= @bPropertyTypeFlag	OUTPUT,
		  @nCurrentRow		= @nCurrentRow

		Set @sErrorMsg = NULL

		-- No mapping found for CASETYPE 
		If (@nErrorCode = 0) and (@bCaseTypeFlag != 1)
		Begin
			Set @sErrorMsg = 'IRN:'+@sIRN + ' - Cannot find mapping for CASETYPE [' + @sCaseType + ']'
		End

		-- No mapping found for PROPERTYTYPE
		If (@nErrorCode = 0) and (@bPropertyTypeFlag != 1)
		Begin
			If @sErrorMsg IS NOT NULL
				Set @sErrorMsg = @sErrorMsg + '; PROPERTYTYPE [' + @sPropertyType + ']... '
			Else
				Set @sErrorMsg = 'IRN:'+@sIRN + ' - Cannot find mapping for PROPERTYTYPE [' + @sPropertyType + ']'
		End
	    	
		If @bDebug = 1
			Print('ERROR MESSAGE IS: ' + @sErrorMsg )

		If @sErrorMsg is not null and @sErrorMsgSaved is null
			set @sErrorMsgSaved = @sErrorMsg

		Set @nCurrentRow = @nCurrentRow + 1

	End /* While loop */

	-- Raise error

	If @sErrorMsgSaved is not null
	begin
		set @nErrorCode = -1
		Raiserror (@sErrorMsgSaved,16,1)
		Return -1
	end

End


-- TRANSACTION BODY FOR EACH CASE --
-- Build the transaction body based on all the linked cases in the temp table @sLinkedCasesTableName
Set @nCurrentRow = 1

While (@nErrorCode = 0) and  (@nCurrentRow <= @nNumberOfLinkedCases)
Begin
    Set @sSQLString="
 	   	Select 	@nCaseId =LC.CASEID,
			@sIRN	= C.IRN,
			@sCaseType=LC.MCASETYPE, 
       	@sPropertyType=LC.MPROPERTYTYPE,
			@sCountryCode = ISNULL(CO.ALTERNATECODE, C.COUNTRYCODE),
			@sLocalClasses = C.LOCALCLASSES,
			@sIntClasses   = C.INTCLASSES
  	    	from "+ @sLinkedCasesTableName +" LC
	    	join CASES C on (C.CASEID = LC.CASEID)
			left join COUNTRY CO on (CO.COUNTRYCODE = C.COUNTRYCODE)
       	where LC.RowPosition = @nCurrentRow "

    Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nCaseId		int     	OUTPUT,
		  @sIRN			nvarchar(30)	OUTPUT,
		  @sCaseType		nvarchar(50)	OUTPUT,
		  @sPropertyType	nvarchar(50)	OUTPUT, 	
		  @sCountryCode		nvarchar(50)	OUTPUT,
		  @sLocalClasses	nvarchar(254)	OUTPUT,
		  @sIntClasses		nvarchar(254)	OUTPUT,
		  @nCurrentRow		int',
		  @nCaseId		= @nCaseId		OUTPUT,
		  @sIRN			= @sIRN			OUTPUT,
		  @sCaseType		= @sCaseType		OUTPUT,
		  @sPropertyType	= @sPropertyType	OUTPUT, 	
		  @sCountryCode		= @sCountryCode		OUTPUT,
		  @sLocalClasses	= @sLocalClasses	OUTPUT,
		  @sIntClasses		= @sIntClasses		OUTPUT,
		  @nCurrentRow		= @nCurrentRow



   If @nErrorCode = 0
   Begin	
		If @bDebug = 1
  			print ('create transaction body for case number : ' + cast(@nCurrentRow as varchar ) + ' of ' + CAST(@nNumberOfLinkedCases AS nvarchar ) )

		Set @sSQLString1 = "
		Select 2 as TAG, 0 as PARENT,
		null AS [TransactionBody!2!], 
		" + cast(@nCurrentRow as varchar) + " AS [TransactionBody!2!TransactionIdentifier!element], -- Transaction Identifier (sequential number)
		null AS [TransactionContentDetails!3!TransactionCode!element],
		null AS [TransactionData!4!],
	
		null AS [CaseDetails!5!SenderCaseIdentifier!element],		-- CASES.CASEID
		null AS [CaseDetails!5!SenderCaseReference!element],		-- CASES.IRN
		null AS [CaseDetails!5!CaseTypeCode!element],			-- CASES.CASETYPE (MAP REQ)
		null AS [CaseDetails!5!CasePropertyTypeCode!element],		-- CASES.PROPERTYTYPE (MAP REQ)
		null AS [CaseDetails!5!CaseCountryCode!element],		-- CASES.COUNTRYCODE
	
		null AS [IdentifierNumberDetails!6!IdentifierNumberCode!element],
		null AS [IdentifierNumberDetails!6!IdentifierNumberText!element],
	
		null AS [GoodsServicesDetails!7!ClassificationTypeCode!element],  -- 'Nice' 
		null AS [ClassDescriptionDetails!8!],
		null AS [ClassDescription!9!ClassNumber!element],
	
		null AS [GoodsServicesDetails!7!ClassificationTypeCode!element],  -- 'Domestic'
		null AS [ClassDescriptionDetails!8!],
		null AS [ClassDescription!9!ClassNumber!element],
	
		null AS [PaymentDetails!10!],
		null AS [Payment!11!],
		null AS [PaymentFeeDetails!12!],
		null AS [PaymentFee!13!],
		null AS [FeeAmount!14!],
		null AS [FeeAmount!14!currencyCode] 
		
		union all
	
		-- transaction code
		select 3 as TAG, 2 as PARENT,
		null, null,		
		'Renewal Instruction', 				-- Transaction code (Hardcoded)
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null, null, null, 
		null, null, null, null, null
	
		"
	
	
		Set @sSQLString2 = "
	
		union all
	
		-- Transaction Data
		select 4 as TAG, 3 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null, 
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null
	
		union all 
	
		-- Case Details
		select 5 as TAG, 4 as PARENT,
		null, null, null, null,
		"+  cast(@nCaseId as varchar) +", 			-- CASEID
		'"+ @sIRN +"', 						-- IRN		
		'"+ @sCaseType +"',					-- CaseType (MAPPED)
		'"+ @sPropertyType +"',					-- PropertyType	(MAPPED)
		'"+ @sCountryCode +"',					-- Country code
		null, null, null, null, null, 
		null, null, null, null, null, 
		null, null, null, null
		
		"
	
	
		Set @sSQLString3 = "
		union all 
	
		-- Identifier Number Details: official number for number type 'Registration/Grant'
		select 6 as TAG, 5 as PARENT,
		null, null, null, null, null, 
		null, null, null, null,
		'Registration/Grant', 
		O.OFFICIALNUMBER,			-- OfficialNumber, 
		null, null, null, null, null, 
		null, null, null, null, null, 
		null, null
		from OFFICIALNUMBERS O
		where O.CASEID = "+ cast(@nCaseId as varchar) +" 
		and O.ISCURRENT = 1
		and O.NUMBERTYPE = (select EX.CODE
			from ENCODEDVALUE E
			join MAPPING M ON (M.INPUTCODEID = E.CODEID)
			join ENCODEDVALUE EX ON (EX.CODEID = M.OUTPUTCODEID)
			where E.STRUCTUREID = "+ cast(@nNumberTypeStructureId as varchar) +"
			and E.SCHEMEID = "+ cast(@nSchemeIdCPAXML as varchar) +"
			and E.CODE = 'REGISTRATION/GRANT'
			and M.STRUCTUREID = "+ cast(@nNumberTypeStructureId as varchar) +" 
			and EX.STRUCTUREID = "+ cast(@nNumberTypeStructureId as varchar) +"
			and EX.SCHEMEID = "+ cast(@nSchemeIdCPAINPRO as varchar) +" )
		-- 
	
		union all 
	
		-- Good and Services
		-- Classification type code 'Nice'
		select 7 as TAG, 5 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null,
		'Nice', 					-- Good and Services (Hard code)
		null, null, null, null, null,
		null, null, null, null, null,
		null
	
		"
	
	
		Set @sSQLString4 = "
	
		union all 
	
		-- ClassDescriptionDetails
		select 8 as TAG, 7 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null
	
		union all 
	
		-- ClassDescription
		select 9 as TAG, 8 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null, 
		CC.Parameter as IntClasses,			-- Case International Classes
		null, null, null, null, null, 
		null, null, null, null
		from dbo.fn_Tokenise('"+ @sIntClasses +"', NULL) CC
	
		"
	
	
		Set @sSQLString5 = "
	
		union all 
	
		-- Good and Services
		-- Classification type code 'Domestic'
		select 7 as TAG, 5 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null,
		'Domestic', 					-- hard code
		null, null, null, null, null,			
		null, null, null, null, null,
		null
	
		union all 
	
		-- ClassDescriptionDetails
		select 8 as TAG, 7 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null
	
		"
	
	
		Set @sSQLString6 = "
	
		union all 
	
		-- ClassDescription for 'Domestic'
		select 9 as TAG, 8 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null, 
		CC.Parameter as LocalClasses, 		-- Case Local Classes
		null, null, null, null, null, 
		null, null, null, null
		from dbo.fn_Tokenise('"+ @sLocalClasses +"', NULL) CC
		
	
		-------
	
		union all 
	
		-- PaymentDetails
		select 10 as TAG, 4 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null
		from "+ @sLinkedCasesTableName +" LC
		where LC.RowPosition = "+ cast(@nCurrentRow as varchar) +"
		and LC.AGENTRENEWALFEE is not null

	
		union all 
	
		-- Payment
		select 11 as TAG, 10 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null
		from "+ @sLinkedCasesTableName +" LC
		where LC.RowPosition = "+ cast(@nCurrentRow as varchar) +"
		and LC.AGENTRENEWALFEE is not null

	
		union all 
	
		-- PaymentFeeDetails
		select 12 as TAG, 11 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null
		from "+ @sLinkedCasesTableName +" LC
		where LC.RowPosition = "+ cast(@nCurrentRow as varchar) +"
		and LC.AGENTRENEWALFEE is not null

	
		"
	
	
		Set @sSQLString7 = "
	
		union all 
	
		-- PaymentFee
		select 13 as TAG, 12 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null
		from "+ @sLinkedCasesTableName +" LC
		where LC.RowPosition = "+ cast(@nCurrentRow as varchar) +"
		and LC.AGENTRENEWALFEE is not null

	
		union all 
	
		-- Fee Amount
	
		select 14 as TAG, 13 as PARENT,
		null, null, null, null, null, 
		null, null, null, null, null,
		null, null, null, null, null, 
		null, null, null, null, null,
		null,
		LC.AGENTRENEWALFEE, 
		LC.CURRENCY
		from "+ @sLinkedCasesTableName +" LC
		where LC.RowPosition = "+ cast(@nCurrentRow as varchar) +"
		and LC.AGENTRENEWALFEE is not null
	
		for xml explicit
		"
	
		exec(@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString5+@sSQLString6+@sSQLString7)
		set @nErrorCode=@@error

   End

   -- next case in the linked case table
   Set @nCurrentRow = @nCurrentRow + 1


End  /* loop */



-- Save the filename into ACTIVYTYREQUEST table to enable centura to save the file with the same name
If @nErrorCode = 0 
Begin
	If @bDebug = 1
		Print('SAVE FILENAME INTO FILENAME COLUMN. FILE NAME IS : ' + @sFileName )

	Update ACTIVITYREQUEST
	set FILENAME = @sFileName
	where CASEID = @nCaseIdParam
	and  SQLUSER = @sSQLUserParam
	and WHENREQUESTED = @dtWhenRequestedParam

	set @nErrorCode=@@error
End

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
	where	 ( LC.CASEID 	!= "+ cast(@nCaseIdParam as nvarchar) +"
			or	cast(LC.WHENREQUESTED as nvarchar)!= '"+ cast(@dtWhenRequestedParam as nvarchar) +"'
			or	LC.SQLUSER	!= '"+ @sSQLUserParam +"')" 

	exec @nErrorCode=sp_executesql @sSQLString
	
End			



-- Now drop the temporary table 
if exists(select * from tempdb.dbo.sysobjects where name = @sLinkedCasesTableName)
Begin

	Set @sSQLString = "drop table " +  @sLinkedCasesTableName
	exec @nErrorCode=sp_executesql @sSQLString
End


If @bDebug = 1
	If @nErrorCode = 0
		Print('XML SUCCESSFULLY GENERATED.')
	Else
		Print('XML GENERATION FAILED.')


RETURN @nErrorCode
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.XML_AgentRenewalInstrLetter to public
go
