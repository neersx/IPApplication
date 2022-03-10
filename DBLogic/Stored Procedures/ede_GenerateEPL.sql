-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_GenerateEPL
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_GenerateEPL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.ede_GenerateEPL.'
	Drop procedure [dbo].[ede_GenerateEPL]
end
Print '**** Creating Stored Procedure dbo.ede_GenerateEPL...'
Print ''
GO



SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE [dbo].[ede_GenerateEPL] 
		@psXMLActivityRequestRow	ntext
AS
-- PROCEDURE :	ede_GenerateEPL
-- VERSION :	33
-- DESCRIPTION:	Generate EDE EPL files in CPAXML format for an EDE batch.
-- COPYRIGHT: 	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
--
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 22/01/2007	DL	12304	1	Procedure created
-- 26/02/2007	DL	12304	2	Bug fixed.
-- 08/03/2007	DL	14531	3	Break down the XML into lines for each transaction
-- 20/12/2007	DL	15740	4	Bugs fixing.
-- 06/02/2008	DL	15771	5	Add an attribute sequentialNumber="1"  to the element <TransactionMessageDetails> 
--					where the EDETRANSACTIONBODY.TRANSNARRATIVECODE is retrieved 
-- 14/02/2008	DL	15960	6	Incorrect data in elements <ReceiverCaseReference> and <SenderCaseReference> for rejected transactions.
-- 04/03/2008	DL	16053	7	Add attribute sequenceNumber to element <Phone>, <Fax>, <Email>
-- 06/03/2008	DL	16044	8	- Retrieve renewal dates of the current cycle
--					- Add name salutation (SQA16047)
--					- Incorrect FirstName & MiddleName if NAME.FIRSTNAME is a single value.
--					- Change SenderXSDVersion from 1.0 to 1.1 to synchronise with the current CPA-XML version
-- 28/03/2008	DL	16100	9	-- Determining Receiver Name Code for EPL when there are multiple mappings.
--					-- Also report live case details rather than draft case if transaction is mapped to live case
-- 21/04/2008	DL	16268	10	Performance enhancement
--					- copy mappings from views to temp tables so that views are only recalcuated once rather then one for each case.
--					- add index to temp tables.
-- 22/04/2008	AT	16233	11	Derive Division case names.
-- 04/06/2008	DL	16439	12	Ensure all mapped events are included in report.
-- 16/06/2008	AT	16533	13	Return all parts of phone/fax numbers.
-- 18/06/2008	DL	16439	14	Further performance enhancement by avoid using function fn_tokenise in the main XML retrieval query.
-- 07/07/2008	AT	16533	15	Fix return of phone/fax numbers.
-- 21/11/2008	DL	17144	16	Fix bug - <TransactionReturnCode> should be filtered by TRANSACTIONMESSAGE.TRANSACTIONTYPE
-- 11 Dec 2008	MF	17136	17	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROL
-- 18/12/2008	DL	17233	18	Always use event 'APPLICATION' (-4) for displaying event details for associated cases.
-- 17/03/2009	DL	16975	19	Make Transaction Identifier for EPL to be the same as Inbound data
-- 24/03/2009	DL	17519	20	Priority number incorrectly being reported as registration number for rejected cases
-- 21/05/2009	DL	17694	21	Return ALTERNATE COUNTRY CODE instead of COUNTRYCODE fields in rejected name and cases transactions
-- 29/05/2009	mf	17748	22	Reduce locking level to ensure other activities are not blocked.
-- 01/07/2009	DL	17837	23	ReceiverCaseReference to be populated based on incoming data.
-- 04 Jun 2010	MF	18703	24	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null.
-- 20 Jan 2012  DL	S20161	25	Fix error for 'FormattedName/MiddleName' if FIRSTNAME contains trailing spaces
-- 22/02/2012	DL	20266	26	Introduce new stop reason code of N. Retrieve StopReasonCode from TABLECODES 168 instead of hardcoding
-- 30/02/2012	NML	20412	27	Change to map output caseid internal to external ID dbo.fn_InternaltoExternal
-- 10/09/2012	DL	20904	28	EPL is sometimes not reporting on Next Affidavit date
-- 8/12/2012	NML		29	Remove NGB 9999999
-- 31/05/2013	MOS	21484	30	Added @nameno parameter taken from @nBatchNo to function dbo.fn_InternaltoExternal
-- 11/01/2019	DL	DR-46493 31	Add Family and FamilyTitle to CaseDetails.
-- 29/07/2019	DL	DR-50608 32	Pass DEFAULT parameter to fn_GetMappingCode
-- 19 May 2020	DL	DR-58943 33	Ability to enter up to 3 characters for Number type code via client server	
 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


-- Temp table to hold transactions of a batch
-- ROWID is the transaction order in the batch
CREATE TABLE #TEMPTRANSACTION(
	ROWID				int,
	BATCHNO				int,
	TRANSACTIONIDENTIFIER		nvarchar(50) collate database_default,
	TRANSACTIONCODE			nvarchar(50) collate database_default,
	TRANSACTIONTYPE			nvarchar(30) collate database_default,
	CASEID				int,
	NAMENO				int
	)

CREATE INDEX X1TEMPTRANSACTION ON #TEMPTRANSACTION
(
	CASEID
)

CREATE INDEX X2TEMPTRANSACTION ON #TEMPTRANSACTION
(
	BATCHNO, TRANSACTIONIDENTIFIER
)
 

-- Temp tables to copy data mappings from views.
-- The report query will use these tables instead of the views to enhance performance 
-- as the views are regenerated each time they are accessed. 
CREATE TABLE #BASIS_VIEW(	BASIS_INPRO		NVARCHAR(2)	collate database_default, 
				BASIS_CPAXML		NVARCHAR(50)	collate database_default)
				
CREATE TABLE #CASECATEGORY_VIEW(CASECATEGORY_INPRO	NVARCHAR(2)	collate database_default, 
				CASECATEGORY_CPAXML	NVARCHAR(50)	collate database_default)
				
CREATE TABLE #CASETYPE_VIEW(	CASETYPE_INPRO		NCHAR(1)	collate database_default, 
				CASETYPE_CPAXML		NVARCHAR(50)	collate database_default)
				
CREATE TABLE #EVENT_VIEW(	EVENT_INPRO		INT, 
				EVENT_CPAXML		NVARCHAR(50) collate database_default)
				
CREATE INDEX X1EVENT_VIEW ON #EVENT_VIEW(EVENT_INPRO)
CREATE INDEX X2EVENT_VIEW ON #EVENT_VIEW(EVENT_CPAXML)

CREATE TABLE #NAMETYPE_VIEW(	NAMETYPE_INPRO		NVARCHAR(3)	collate database_default, 
				NAMETYPE_CPAXML		NVARCHAR(50)	collate database_default)
				
CREATE TABLE #NUMBERTYPE_VIEW(	NUMBERTYPE_INPRO	NVARCHAR(3)	collate database_default, 
				NUMBERTYPE_CPAXML	NVARCHAR(50)	collate database_default)
				
CREATE TABLE #PROPERTYTYPE_VIEW(PROPERTYTYPE_INPRO	NCHAR(1)	collate database_default, 
				PROPERTYTYPE_CPAXML	NVARCHAR(50)	collate database_default)
				
CREATE TABLE #RELATIONSHIP_VIEW(RELATIONSHIP_INPRO	NVARCHAR(3)	collate database_default, 
				RELATIONSHIP_CPAXML	NVARCHAR(50)	collate database_default)
				
CREATE TABLE #SUBTYPE_VIEW(	SUBTYPE_INPRO		NVARCHAR(2)	collate database_default,
				SUBTYPE_CPAXML		NVARCHAR(50)	collate database_default)
				
CREATE TABLE #TEXTTYPE_VIEW(	TEXTTYPE_INPRO		NVARCHAR(2)	collate database_default, 
				TEXTTYPE_CPAXML		NVARCHAR(50)	collate database_default)
				
-- temp table contains pre-tokenised string.
CREATE TABLE #SiteCtrlClientTextType(
				Parameter		NVARCHAR(255)	collate database_default)
				
CREATE TABLE #SiteCtrlNameTypes(Parameter		NVARCHAR(255)	collate database_default)

CREATE TABLE #DivisionNameTypes(Parameter		NVARCHAR(255)	collate database_default)



Declare	@hDocument 				int,
	@nActivityId				int,
	@sSQLUser				nvarchar(40),
	@nBatchNo				int,

	@sFileName				nvarchar(254),
	@dCurrentDateTime 			datetime,
	@sSenderRequestIdentifier		nvarchar(14),
	@sSenderProducedDateTime		nvarchar(22),
	@sSender				nvarchar(30),
  	@nCPASchemaId				int,
	@nInproSchemaId				int,
	@sStructureTableName  			nvarchar(50),
	@sInputCode				nvarchar(50),
	@sDataInstructorCode			nvarchar(3),
	@sSiteCtrlClientTextType		nvarchar(254),
	@sSiteCtrlNameTypes 			nvarchar(254),
	@sDivisionNameTypes			nvarchar(254),

	@sCaseClassTableName			nvarchar(100),
	@sTokenisedAddressTableName		nvarchar(100),
	@sTempEPLTableName			nvarchar(100),

	@sSQLString 				nvarchar(4000),
	@sSQLString1 				nvarchar(4000),
	@sSQLString2 				nvarchar(4000),
	@sSQLString3 				nvarchar(4000),
	@sSQLString4 				nvarchar(4000),
	@sSQLString4A 				nvarchar(4000),
	@sSQLString5 				nvarchar(4000),
	@sSQLString5A 				nvarchar(4000),
	@sSQLString6 				nvarchar(4000),
	@sSQLString7 				nvarchar(4000),
	@sSQLString8 				nvarchar(4000),
	@sSQLString9 				nvarchar(4000),
	@sSQLString10 				nvarchar(4000),
	@sSQLString11				nvarchar(4000),
	@sSQLString12 				nvarchar(4000),
	@sSQLString13 				nvarchar(4000),
	@sSQLStringLast				nvarchar(4000),
	@bDebug					bit,
	@sAlertXML				nvarchar(250),
	@nErrorCode 				int

	-- SQA17748 Reduce the locking level to avoid blocking other processes
	set transaction isolation level read uncommitted

	Set @nErrorCode = 0
	set @bDebug = 1

	-----------------------------------------------------------------------------------------------------------------------------
	-- Only allow stored procedure run if the data base version is >=9 (SQL Server 2005 or later)
	-----------------------------------------------------------------------------------------------------------------------------
	If  (Select left( cast(SERVERPROPERTY('ProductVersion') as varchar), CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') as varchar))-1)   ) <= 8
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML("edn", "This document can only be generated for databases on SQL Server 2005 or later.", null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
	

	-- Create a temp table to hold XML data for each transaction in a batch.
	-- This table will allow the XML be sorted in the transaction order as stored in the batch
	If @nErrorCode = 0
	Begin
		-- Generate a unique table name from the newid() 
		Set @sSQLString="Select @sTempEPLTableName = '##' + replace(newid(),'-','_')"
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@sTempEPLTableName nvarchar(100) OUTPUT',
			@sTempEPLTableName = @sTempEPLTableName OUTPUT

		-- Note: Need to implement this as dynamic SQL to allow stored procedure to run on SQL Server older than 2005
		-- without giving error due to new XML data type.
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="
				CREATE TABLE "+ @sTempEPLTableName +" (
					ROWID				int,
					XMLSTR			XML
					)"
			exec @nErrorCode=sp_executesql @sSQLString
		End
	End

	--------------------------------------------------------------------------------------------------------------------

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
		select 	
			@nActivityId = ACTIVITYID,
			@sSQLUser = SQLUSER,
			@nBatchNo = BATCHNO
			from openxml(@hDocument,'ACTIVITYREQUEST',2)
			with (ACTIVITYID int,
				SQLUSER nvarchar(40),
				BATCHNO int) "
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'	@nActivityId		int		OUTPUT,
				@sSQLUser		nvarchar(40) 	OUTPUT,
				@nBatchNo		int     	OUTPUT,
		  		@hDocument		int',
				@nActivityId	= @nActivityId	OUTPUT,
				@sSQLUser		= @sSQLUser 	OUTPUT,
			  	@nBatchNo		= @nBatchNo		OUTPUT,
			  	@hDocument 		= @hDocument
	End


	If @nErrorCode = 0	
	Begin	
		Exec sp_xml_removedocument @hDocument 
		Set @nErrorCode	  = @@Error
	End

	--------------------------------------------------------------------------------------------------------------------


	
	--Ensure the Sender exists
	If @nErrorCode = 0	
	Begin	
		-- Get Sender = _H Alias against HOME NAME CODE 
		Set @sSQLString="
		Select @sSender = NA.ALIAS 
					from SITECONTROL SC
		join NAMEALIAS NA on (NA.NAMENO=SC.OLINTEGER
				  and NA.ALIASTYPE='_H'
				  and NA.COUNTRYCODE  is null
				  and NA.PROPERTYTYPE is null)
		where SC.CONTROLID = 'HOMENAMENO'"
	
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@sSender		nvarchar(30)	OUTPUT',
					  @sSender		= @sSender	OUTPUT
	
		If @nErrorCode = 0 and @sSender is null
		Begin
		   Raiserror ('There is no valid sender for this case.  Please set up Alias of type _H for the Name specified in site control HOMENAMENO',16,1)
		   Return -1
		End
	End
	
	-- Get the Division name types
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Select @sDivisionNameTypes = COLCHARACTER
				FROM SITECONTROL WHERE CONTROLID = 'Division Name Types'"
	
		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@sDivisionNameTypes nvarchar(254) OUTPUT',
					@sDivisionNameTypes=@sDivisionNameTypes OUTPUT

		If @nErrorCode = 0
		Begin	
			Set @sSQLString = "insert into #DivisionNameTypes (Parameter)
			select Parameter from fn_Tokenise( @sDivisionNameTypes, null)" 

			Exec @nErrorCode=sp_executesql @sSQLString,
				N'@sDivisionNameTypes	nvarchar(254)',
				  @sDivisionNameTypes	= @sDivisionNameTypes 
		End

	End


	-- Global temp table to hold tokenised ADDRESS.STREET1 separated by carriage return character
	-- This table is used for holding Live Case Name or Processed Name transactions address STREET1.
	If @nErrorCode = 0
	Begin
		-- Generate a unique table name from the newid() 
		Set @sSQLString="Select @sTokenisedAddressTableName = '##' + replace(newid(),'-','_')"
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@sTokenisedAddressTableName nvarchar(100) OUTPUT',
			@sTokenisedAddressTableName = @sTokenisedAddressTableName OUTPUT
	

		-- and create the table	
		If @nErrorCode = 0
		Begin
			Set @sSQLString="
			Create table " + @sTokenisedAddressTableName + "(
						ADDRESSCODE	int,
						ADDRESSLINE	nvarchar(254) collate database_default,
						SEQUENCENUMBER	int
						)"
			Exec @nErrorCode=sp_executesql @sSQLString

			If @nErrorCode = 0
			Begin
				Set @sSQLString="
				CREATE INDEX X1TokeniseAddress ON " + @sTokenisedAddressTableName + " 
				(
					ADDRESSCODE
				) "
				Exec @nErrorCode=sp_executesql @sSQLString
			End

		End
	End
	

	-- copy mapping data from views to temp tables
	If @nErrorCode = 0	
	Begin
		Set @sSQLString="Insert into #BASIS_VIEW (BASIS_INPRO, BASIS_CPAXML)
		select BASIS_INPRO, BASIS_CPAXML from BASIS_VIEW"
		exec @nErrorCode=sp_executesql @sSQLString
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="Insert into #CASECATEGORY_VIEW (CASECATEGORY_INPRO, CASECATEGORY_CPAXML)
			select CASECATEGORY_INPRO, CASECATEGORY_CPAXML from CASECATEGORY_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="Insert into #CASETYPE_VIEW (CASETYPE_INPRO, CASETYPE_CPAXML)
				select CASETYPE_INPRO, CASETYPE_CPAXML from CASETYPE_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
		If @nErrorCode = 0	
		Begin
			-- get all events with mapping in view EVENT_VIEW.		
			Set @sSQLString="Insert into #EVENT_VIEW(EVENT_INPRO, EVENT_CPAXML) 
				select EVENT_INPRO, EVENT_CPAXML 
				from EVENT_VIEW E 
				where  EVENT_CPAXML is not null"
			exec @nErrorCode=sp_executesql @sSQLString
		End
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="Insert into #NAMETYPE_VIEW (NAMETYPE_INPRO, NAMETYPE_CPAXML)
			select NAMETYPE_INPRO, NAMETYPE_CPAXML from NAMETYPE_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="Insert into #NUMBERTYPE_VIEW (NUMBERTYPE_INPRO, NUMBERTYPE_CPAXML)
			select NUMBERTYPE_INPRO, NUMBERTYPE_CPAXML from NUMBERTYPE_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="Insert into #PROPERTYTYPE_VIEW (PROPERTYTYPE_INPRO, PROPERTYTYPE_CPAXML)
			select PROPERTYTYPE_INPRO, PROPERTYTYPE_CPAXML from PROPERTYTYPE_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="Insert into #RELATIONSHIP_VIEW (RELATIONSHIP_INPRO, RELATIONSHIP_CPAXML)
			select RELATIONSHIP_INPRO, RELATIONSHIP_CPAXML from RELATIONSHIP_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="Insert into #SUBTYPE_VIEW (SUBTYPE_INPRO, SUBTYPE_CPAXML)
			select SUBTYPE_INPRO, SUBTYPE_CPAXML from SUBTYPE_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
		If @nErrorCode = 0	
		Begin
			Set @sSQLString="Insert into #TEXTTYPE_VIEW (TEXTTYPE_INPRO, TEXTTYPE_CPAXML)
			select TEXTTYPE_INPRO, TEXTTYPE_CPAXML from TEXTTYPE_VIEW"
			exec @nErrorCode=sp_executesql @sSQLString
		End
	End




	---------------------- Transaction HEADER details ---------------------------------------------------
	If @nErrorCode = 0
	Begin
		-- Get timestamp
		Select @dCurrentDateTime = getdate()
	
		-- Get @sSenderRequestIdentifier as Timestamp in format CCYYMMDDHHMMSS,
		-- File name 
		-- and @sSenderProducedDateTime as Timestamp in format CCYY-MM-DDTHH:MM:SS.0Z  (.0Z is zero not letter O) 
		set @sSQLString = "
		Select  @sSenderRequestIdentifier = RTRIM( CONVERT(char(4), year(@dCurrentDateTime))) 
		+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dCurrentDateTime)))) + CONVERT(char(2), month(@dCurrentDateTime)))
		+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dCurrentDateTime)))) + CONVERT(char(2), day(@dCurrentDateTime)))
		+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dCurrentDateTime)))) + CONVERT(char(2), datepart(hh,@dCurrentDateTime)))
		+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dCurrentDateTime)))) + CONVERT(char(2), datepart(mi,@dCurrentDateTime)))
		+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dCurrentDateTime)))) + CONVERT(char(2), datepart(ss,@dCurrentDateTime))) ,
		
		@sSenderProducedDateTime = RTRIM( CONVERT(char(4), year(@dCurrentDateTime))) + '-' +
		+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dCurrentDateTime)))) + CONVERT(char(2), month(@dCurrentDateTime))) + '-' +
		+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dCurrentDateTime)))) + CONVERT(char(2), day(@dCurrentDateTime))) + 'T' +
		+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dCurrentDateTime)))) + CONVERT(char(2), datepart(hh,@dCurrentDateTime))) + ':' +
		+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dCurrentDateTime)))) + CONVERT(char(2), datepart(mi,@dCurrentDateTime))) + ':' +
		+ RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dCurrentDateTime)))) + CONVERT(char(2), datepart(ss,@dCurrentDateTime))) + '.0Z' ,
	
		@sFileName = REPLACE(SD.SENDERFILENAME, '.XML', '') + '_' + SC.COLCHARACTER  + '.XML' 
	
		from EDESENDERDETAILS SD
	        left join SITECONTROL SC on (SC.CONTROLID = 'EPL Suffix')
		where SD.BATCHNO = @nBatchNo
		"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@dCurrentDateTime		Datetime,
			  @nBatchNo			int,
			  @sSenderRequestIdentifier	nvarchar(14) OUTPUT,
			  @sSenderProducedDateTime	nvarchar(22) OUTPUT,
			  @sFileName			nvarchar(254) OUTPUT',
			  @dCurrentDateTime		= @dCurrentDateTime,
			  @nBatchNo			= @nBatchNo,
			  @sSenderRequestIdentifier	= @sSenderRequestIdentifier OUTPUT,
			  @sSenderProducedDateTime	= @sSenderProducedDateTime OUTPUT,
			  @sFileName			= @sFileName OUTPUT
	


		-- Create transaction header
		set @sSQLString = "
		select 1 as TAG, 0 as PARENT,
		null AS [TransactionHeader!1!], 
		null AS [SenderDetails!2!SenderRequestType!element],
		null AS [SenderDetails!2!SenderRequestIdentifier!element],
		null AS [SenderDetails!2!Sender!element],
		null AS [SenderDetails!2!SenderXSDVersion!element],
	
		null AS [SenderSoftware!3!SenderSoftwareName!element],
		null AS [SenderSoftware!3!SenderSoftwareVersion!element],
	
		null AS [SenderFilename!4!],
		null AS [SenderProducedDateTime!5!],
	
		null AS [ReceiverDetails!6!ReceiverRequestType!element],
		null AS [ReceiverDetails!6!ReceiverRequestIdentifier!element],
		null AS [ReceiverDetails!6!Receiver!element],
		null AS [ReceiverDetails!6!ReceiverXSDVersion!element],
	
		null AS [ReceiverSoftware!7!ReceiverSoftwareName!element],
		null AS [ReceiverSoftware!7!ReceiverSoftwareVersion!element],
	
		null AS [ReceiverFilename!8!],
		null AS [ReceiverProducedDate!9!]
	
		union all
	
	
		-- SenderDetails
		select 2, 1,
		null,
		'Data Input Response',			-- SenderRequestType (Hardcode)
		'" + @sSenderRequestIdentifier + "', 	-- SenderRequestIdentifier
		'" + @sSender + "', 			-- Sender
		'1.1',					-- SenderXSDVersion (Hardcode)
		null, null, null, null,	null,
		null, null, null, null,	null,
		null, null
	
		union all
	
		-- SenderSoftware
		select 3, 2,
		null, null, null, null, null,
		'CPA Inprotech',			-- SenderSoftwareName (Hardcode)
		SC.COLCHARACTER,			-- SenderSoftwareVersion
		null, null, null, null, null,
		null, null, null, null,	null
		FROM SITECONTROL SC WHERE CONTROLID = 'DB Release Version'
				
		union all
	
		-- SenderFilename
		select 4, 2,
		null, null, null, null, null,
		null, null,		
		'" + @sFileName + "', 
		null, null, null, null, null,
		null, null, null, null
	
		union all
	
		-- SenderProducedDateTime
		select 5, 2,
		null, null, null, null, null,
		null, null, null, 
		'"+ @sSenderProducedDateTime + "',	-- SenderProducedDateTime
		null, null, null, null, null,
		null, null, null
	
		union all
	
		-- ReceiverDetails
		select 6, 1,
		null, null, null, null, null,
		null, null, null, null,
		SD.SENDERREQUESTTYPE,			-- ReceiverRequestType
		SD.SENDERREQUESTIDENTIFIER,		-- ReceiverRequestIdentifier
		SD.SENDER,				-- Receiver
		SD.SENDERXSDVERSION,			-- ReceiverXSDVersion
		null, null, null, null
		from EDESENDERDETAILS SD
		where SD.BATCHNO = "+ cast(@nBatchNo as nvarchar) +"
	
		union all
	
		-- ReceiverSoftware
		select 7, 6,
		null, null, null, null, null,
		null, null, null, null, null,
		null, null, null, 
		SS.SENDERSOFTWARENAME, 			-- ReceiverSoftwareName
		SS.SENDERSOFTWAREVERSION, 		-- ReceiverSoftwareVersion
		null, null
		from EDESENDERSOFTWARE SS
		where SS.BATCHNO = "+ cast(@nBatchNo as nvarchar) +"
		
		union all
	
		-- ReceiverFilename
		select 8, 6,
		null, null, null, null, null,
		null, null, null, null, null,
		null, null, null, null, null,
		SD.SENDERFILENAME, 
		null
		from EDESENDERDETAILS SD
		where SD.BATCHNO = "+ cast(@nBatchNo as nvarchar) +" 
	
		union all
	
		-- ReceiverProducedDate
		select 9, 6,
		null, null, null, null, null,
		null, null, null, null, null,
		null, null, null, null, null,
		null, 
		replace( convert(nvarchar(10), SD.SENDERPRODUCEDDATE, 111), '/', '-')
		from EDESENDERDETAILS SD
		where SD.BATCHNO = "+ cast(@nBatchNo as nvarchar) +" 
		for xml explicit"

		exec(@sSQLString)
		set @nErrorCode=@@error
	End
	

	
	----------------------------------------------------------------------------------------------------------
	-- Determine the data source for each transaction in the batch.
	-- Data source are EDE tables if transaction status is REJECTEDCASE or REJECTEDNAME
	-- Data source are Inprotech live tables (CASES, NAME...) if transaction status is DRAFTCASE or LIVECASE or PROCESSEDNAME
	-- Also determine whether transactions are Name type to generate different XML structure
	-- Store these information in a temp table.
	----------------------------------------------------------------------------------------------------------
	If @nErrorCode = 0
	Begin
		Set @sSQLString="Insert into #TEMPTRANSACTION 
		(ROWID, BATCHNO, TRANSACTIONIDENTIFIER, TRANSACTIONCODE, TRANSACTIONTYPE, CASEID, NAMENO)
		Select distinct TB.ROWID, TB.BATCHNO, 
		TB.TRANSACTIONIDENTIFIER, 
		TCD.TRANSACTIONCODE, 
		case when TCD.TRANSACTIONCODE = 'Case Import' and CD.CASEID is null and CM.DRAFTCASEID is null then 'REJECTEDCASE'
		     when TCD.TRANSACTIONCODE = 'Case Import' and CD.CASEID is not null then 'LIVECASE'
		     when TCD.TRANSACTIONCODE = 'Case Import' and CD.CASEID is null and CM.DRAFTCASEID is not null then 'DRAFTCASE'
		     when TCD.TRANSACTIONCODE = 'Name Import' and (AB.NAMENO is null OR
					 (AB.NAMENO is not null and OI.ISSUEID is not null ) ) then 'REJECTEDNAME'
		     when TCD.TRANSACTIONCODE = 'Name Import' and AB.NAMENO is not null and OI.ISSUEID is null then 'PROCESSEDNAME'

		end TRANSACTIONTYPE,
		ISNULL(CD.CASEID, ISNULL(CM.LIVECASEID, CM.DRAFTCASEID)) CASEID,
		AB.NAMENO

		from EDETRANSACTIONBODY TB
		left join EDETRANSACTIONCONTENTDETAILS TCD on (TCD.BATCHNO = TB.BATCHNO and TCD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER)
		left join EDECASEDETAILS CD on (CD.BATCHNO = TB.BATCHNO and CD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER)
		left join EDECASEMATCH CM on (CM.BATCHNO = TB.BATCHNO and CM.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER)
		left join EDENAMEADDRESSDETAILS NAD on (NAD.BATCHNO = TB.BATCHNO and NAD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER)
		left join EDEADDRESSBOOK AB on (AB.BATCHNO = NAD.BATCHNO and AB.TRANSACTIONIDENTIFIER = NAD.TRANSACTIONIDENTIFIER)
		left join EDEOUTSTANDINGISSUES OI on (OI.BATCHNO = TB.BATCHNO and OI.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER)

		where TB.BATCHNO = @nBatchNo
		ORDER BY TB.ROWID"
	
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@nBatchNo		int',
			  @nBatchNo		= @nBatchNo
	End

	-------------------------------------------------------------------------------------------------------
	-- Extract Draft/Live case transactions data from live tables (i.e. CASES, NAME, CASEEVENT...)
	-------------------------------------------------------------------------------------------------------
	If (@nErrorCode = 0 and exists (Select 1 from #TEMPTRANSACTION where TRANSACTIONTYPE in ('LIVECASE', 'DRAFTCASE')) )
	Begin	

		If @bDebug = 1
			print 'create transaction body for LIVE/DRAFT CASE.' 


		-----------------------------------------------------------------------------------------------
		-- Prepare data for main SQL which generates the XML
		-----------------------------------------------------------------------------------------------

		set @nCPASchemaId = -3
		set @nInproSchemaId = -1

		-- Get Data Instructor code in Inprotech.
		Set @sSQLString = "select @sDataInstructorCode = dbo.fn_GetMappingCode(@nCPASchemaId, @nInproSchemaId, @sStructureTableName, @sInputCode, DEFAULT)"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@nCPASchemaId			int,
			  @nInproSchemaId			int,
			  @sStructureTableName 	nvarchar(50),
			  @sInputCode				nvarchar(50),
			  @sDataInstructorCode	nvarchar(50) output',
			  @nCPASchemaId			= @nCPASchemaId,
			  @nInproSchemaId			= @nInproSchemaId,
			  @sStructureTableName  = 'NAMETYPE',
			  @sInputCode				= 'DATA INSTRUCTOR',
			  @sDataInstructorCode	= @sDataInstructorCode output


		--Get site control values which determine what data can be extracted.
		If @nErrorCode = 0
		Begin		
			Set @sSQLString = "Select @sSiteCtrlClientTextType = COLCHARACTER 
					from SITECONTROL S 
					where CONTROLID = 'Client Text Types'"
			Exec @nErrorCode=sp_executesql @sSQLString,
				N'@sSiteCtrlClientTextType	nvarchar(254) output',
				  @sSiteCtrlClientTextType	= @sSiteCtrlClientTextType output
			
			If @nErrorCode = 0
			Begin	
				Set @sSQLString = "insert into #SiteCtrlClientTextType (Parameter)
				select Parameter from fn_Tokenise( @sSiteCtrlClientTextType, NULL)" 

				Exec @nErrorCode=sp_executesql @sSQLString,
					N'@sSiteCtrlClientTextType	nvarchar(254)',
					  @sSiteCtrlClientTextType	= @sSiteCtrlClientTextType 
			End

			If @nErrorCode = 0
			Begin		
				Set @sSQLString = "Select @sSiteCtrlNameTypes = COLCHARACTER 
						from SITECONTROL 
						where CONTROLID =  'Client Name Types Shown'"
				Exec @nErrorCode=sp_executesql @sSQLString,
					N'@sSiteCtrlNameTypes	nvarchar(254) output',
					  @sSiteCtrlNameTypes	= @sSiteCtrlNameTypes output
			End

			If @nErrorCode = 0
			Begin	
				Set @sSQLString = "insert into #SiteCtrlNameTypes (Parameter)
				select Parameter from fn_Tokenise( @sSiteCtrlNameTypes, NULL)" 
				Exec @nErrorCode=sp_executesql @sSQLString,
					N'@sSiteCtrlNameTypes	nvarchar(254)',
					  @sSiteCtrlNameTypes	= @sSiteCtrlNameTypes 
			End

		End


		-- Tokenised case name ADDRESS.STREET1 separated by carriage return character
		If @nErrorCode = 0
		Begin
			-- temp table to hold case name address code
			Create table #TEMPCASENAMEADDRESS (
						CASEID		int,
						NAMENO		int,
						NAMETYPE	nvarchar(3) collate database_default,
						SEQUENCE	int,
						ADDRESSCODE	int
						)
			CREATE INDEX X1TEMPCASENAMEADDRESS ON #TEMPCASENAMEADDRESS
			(
				CASEID
			)
			CREATE INDEX X2TEMPCASENAMEADDRESS ON #TEMPCASENAMEADDRESS
			(
				ADDRESSCODE
			)


			If @nErrorCode = 0
			Begin
				-- List of case name addresses
				-- Rules: Use CASENAME.ADDRESSCODE if it exists, otherwise use default Street address
				-- if name type is Owner or Inventor, otherwise assume is postal address for other name types.
				Set @sSQLString="
					Insert into #TEMPCASENAMEADDRESS ( CASEID, NAMENO, NAMETYPE, SEQUENCE, ADDRESSCODE)
					Select CN.CASEID, CN.NAMENO, CN.NAMETYPE, CN.SEQUENCE,
							Case 	when CN.ADDRESSCODE is not null then CN.ADDRESSCODE
								 	when (CN.NAMETYPE = 'O' or CN.NAMETYPE = 'J') then OWNER.STREETADDRESS
									else OTHER.POSTALADDRESS
								 end as ADDRESSCODE
						from #TEMPTRANSACTION TT
						join CASENAME CN on (CN.CASEID = TT.CASEID)
						left join NAME as OWNER on (OWNER.NAMENO = CN.NAMENO and (CN.NAMETYPE = 'O' or CN.NAMETYPE = 'J'))
						left join NAME as OTHER on (OTHER.NAMENO = CN.NAMENO and CN.NAMETYPE != 'O' and CN.NAMETYPE != 'J')
						where TT.TRANSACTIONTYPE in ('LIVECASE', 'DRAFTCASE')
				"
				exec @nErrorCode=sp_executesql @sSQLString
			End
			
			-- list of distinct addresscode to be tokenised
			If @nErrorCode = 0
			Begin
				-- Make sure table is empty first.
				Set @sSQLString="
					Delete " + @sTokenisedAddressTableName
				exec 	@nErrorCode=sp_executesql @sSQLString

				-- then load addresscodes for parsing
				If @nErrorCode = 0
				Begin
					Set @sSQLString="
						Insert into "+ @sTokenisedAddressTableName +"( ADDRESSCODE)
						Select distinct ADDRESSCODE
						from #TEMPCASENAMEADDRESS			"
					exec 	@nErrorCode=sp_executesql @sSQLString
				End
			End

			-- And tokenise case name ADDRESS.STREET1 into multiple lines
			If @nErrorCode = 0
			Begin
				Exec @nErrorCode=ede_TokeniseAddressLine @sTokenisedAddressTableName	
			End
		End

		-- Temp table to hold tokenised CASES.LOCALCLASSES and CASES.LOCALCLASSES, which are commas delimited,
		-- for affected cases to be reported.  
		-- Note: This must be a distinct global temp table as table name is passed to another 
		-- stored procedure to tokenise the classes.
		If @nErrorCode = 0
		Begin
			-- Generate a unique table name from the newid() 
			Set @sSQLString="Select @sCaseClassTableName = '##' + replace(newid(),'-','_')"
			exec @nErrorCode=sp_executesql @sSQLString,
				N'@sCaseClassTableName nvarchar(100) OUTPUT',
				@sCaseClassTableName = @sCaseClassTableName OUTPUT
		

			-- and create the table	
			If @nErrorCode = 0
			Begin
				Set @sSQLString="
				Create table " + @sCaseClassTableName +" (
							CASEID						int,
							CLASSTYPE					nvarchar(3) collate database_default,
							CLASS							nvarchar(250) collate database_default,
							SEQUENCENO					int
							)"
				Exec @nErrorCode=sp_executesql @sSQLString
			End

			-- load draft and live cases id into table for parsing case classes
			If @nErrorCode = 0
			Begin		
				Set @sSQLString = "Insert into "+ @sCaseClassTableName +" (CASEID) 
						Select distinct CASEID 
						from #TEMPTRANSACTION
						where TRANSACTIONTYPE in ('LIVECASE', 'DRAFTCASE')"
				Exec @nErrorCode=sp_executesql @sSQLString
			End		


			-- Now tokenise case classes
			If @nErrorCode = 0
			Begin
				Exec @nErrorCode=ede_TokeniseCaseClass @sCaseClassTableName	
			End
		End



		Set @sSQLString1 = ""
		Set @sSQLString2 = ""
		Set @sSQLString3 = ""
		Set @sSQLString4 = ""
		Set @sSQLString5 = ""
		Set @sSQLString5A = ""
		Set @sSQLString6 = ""
		Set @sSQLString7 = ""
		Set @sSQLString8 = ""
		Set @sSQLString9 = ""
		Set @sSQLString10 = ""
		Set @sSQLString11 = ""
		Set @sSQLString12 = ""
		Set @sSQLString13 = ""
		Set @sSQLStringLast = ""


		-----------------------------------------------------------------------------------------------
		-- Main SQL to generate the XML
		-----------------------------------------------------------------------------------------------
		Set @sSQLString1 = "
		Insert into  "+ @sTempEPLTableName +" (ROWID, XMLSTR)
		Select 
		    TT.ROWID, 
		    (
		    Select 	-- <TransactionBody>
			(Select TT.TRANSACTIONIDENTIFIER ) as 'TransactionIdentifier',
			(Select 
				top 1 TM.DESCRIPTION
				from TRANSACTIONMESSAGE TM
				join TRANSACTIONINFO TI on (TI.TRANSACTIONMESSAGENO = TM.TRANSACTIONMESSAGENO)
				where TI.BATCHNO = TB.BATCHNO
				and TI.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
				and TM.TRANSACTIONTYPE = 'C'
				order by TM.MESSAGEPRIORITY ASC
			) as 'TransactionReturnCode',
			(Select		-- <TransactionMessageDetails>
			    1 as '@sequentialNumber',	
			    TC.USERCODE as 'TransactionMessageCode', 
			    TC.DESCRIPTION as 'TransactionMessageText'
			    from EDETRANSACTIONBODY TB2
			    join TABLECODES TC on ( TC.TABLECODE = TB2.TRANSNARRATIVECODE AND TC.TABLETYPE = 402)
			    where TB2.BATCHNO =  TB.BATCHNO
			    and TB2.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			    and TB2.TRANSNARRATIVECODE  is not null
			    for XML PATH('TransactionMessageDetails'), TYPE 
			),
			(Select		-- <TransactionMessageDetails>
			    SI.ISSUECODE as 'TransactionMessageCode', 
			    SI.SHORTDESCRIPTION as 'TransactionMessageText'
			    from EDEOUTSTANDINGISSUES OI
			    join EDESTANDARDISSUE SI on (SI.ISSUEID = OI.ISSUEID)
			    where OI.BATCHNO =  TB.BATCHNO
			    and OI.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			    for XML PATH('TransactionMessageDetails'), TYPE
			)
		"

		-- SQA20266 Replace hardcode StopReasonCode
		Set @sSQLString2 = ",
		       ( 
		       Select    -- <TransactionContentDetails>
			  TCD.ALTERNATIVESENDER as 'AlternativeSender',		
			  'Case Import Response' as 'TransactionCode', 
			  TCD.TRANSACTIONCOMMENT AS 'TransactionComment',
			  (
			  Select 	-- <TransactionData>
			     null,
			    (	
			    select 	-- <CaseDetails>
			    "
			if isnull((select colboolean from sitecontrol where controlid ='Mapping Table Control'),0)	=1
			begin
			
				declare @nameno int 
				set @nameno =	(select SENDERNAMENO from EDESENDERDETAILS
								where BATCHNO = @nBatchNo)
				
				Set @sSQLString2 = @sSQLString2 +"dbo.fn_InternaltoExternal(C.CASEID, " + cast(@nameno as nvarchar (15)) + ", NULL) as 'SenderCaseIdentifier', "
			end
			else
				Set @sSQLString2 = @sSQLString2 +"C.CASEID as 'SenderCaseIdentifier', "
			
			Set @sSQLString2 = @sSQLString2 + "C.IRN 'SenderCaseReference', 
				ECD.SENDERCASEREFERENCE as 'ReceiverCaseReference', 
				case 	when TT.TRANSACTIONTYPE = 'LIVECASE' 
					then (Select CASETYPE_CPAXML from #CASETYPE_VIEW WHERE CASETYPE_INPRO = C.CASETYPE and CASETYPE_CPAXML is not null)
					else (Select CASETYPE_CPAXML from #CASETYPE_VIEW WHERE CASETYPE_INPRO = CT.ACTUALCASETYPE and CASETYPE_CPAXML is not null)
				end as 'CaseTypeCode', 
				PTV.PROPERTYTYPE_CPAXML as 'CasePropertyTypeCode', 
				(Select CASECATEGORY_CPAXML from #CASECATEGORY_VIEW where CASECATEGORY_INPRO = C.CASECATEGORY and CASECATEGORY_CPAXML is not null) as 'CaseCategoryCode',
				(Select SUBTYPE_CPAXML from #SUBTYPE_VIEW where SUBTYPE_INPRO = C.SUBTYPE and SUBTYPE_CPAXML is not null) as 'CaseSubTypeCode',
				BV.BASIS_CPAXML as 'CaseBasisCode', 
				isnull(COU.ALTERNATECODE, C.COUNTRYCODE) as 'CaseCountryCode', 

				case 	when ((C.ENTITYSIZE = 2602 and C.COUNTRYCODE = 'US') or (C.ENTITYSIZE = 2603 and C.COUNTRYCODE = 'US')) then 'Small'
					when C.ENTITYSIZE = 2601 then 'Large'
				end as 'EntitySize', 

				P.NOOFCLAIMS as 'NumberClaims', 
				C.NOINSERIES as 'NumberDesigns', 
				C.EXTENDEDRENEWALS as 'ExtendedNumberYears', 

				(Select S.EXTERNALDESC from STATUS S where S.STATUSCODE = C.STATUSCODE) as 'CaseStatus',
				(Select S.EXTERNALDESC from STATUS S join PROPERTY P on (P.RENEWALSTATUS = S.STATUSCODE and P.CASEID = C.CASEID)) as 'CaseRenewalStatus',

				(Select TC.DESCRIPTION from TABLECODES TC where TC.TABLETYPE = 68 AND TC.USERCODE = C.STOPPAYREASON) as 'StopReasonCode',
				C.FAMILY as 'Family',
				(Select F.FAMILYTITLE from CASEFAMILY F where F.FAMILY = C.FAMILY) as 'FamilyTitle'
		"

		--
		Set @sSQLString3 = ",	
				(Select		-- <DescriptionDetails>
				    TempDesc.DescriptionCode as 'DescriptionCode',
				    TempDesc.DescriptionText as 'DescriptionText'								
				    from					 
				    (	
				    Select 		-- <DescriptionDetails>
					    'Short Title' as 'DescriptionCode',
					    isnull(C.TITLE, '') as 'DescriptionText'								

				    UNION ALL

				    Select
					    distinct TTV.TEXTTYPE_CPAXML as 'DescriptionCode',
					    CT.SHORTTEXT as 'DescriptionText'
					    from #SiteCtrlClientTextType Temp
					    join CASETEXT CT ON (CT.TEXTTYPE = Temp.Parameter and CT.CASEID = C.CASEID AND CT.SHORTTEXT IS NOT NULL  ) 
					    join #TEXTTYPE_VIEW TTV ON (TTV.TEXTTYPE_INPRO = CT.TEXTTYPE AND TTV.TEXTTYPE_CPAXML IS NOT NULL)
				    ) TempDesc
			            for XML PATH('DescriptionDetails'), TYPE
				),
				(Select 	-- <IdentifierNumberDetails>
				    NTV.NUMBERTYPE_CPAXML as 'IdentifierNumberCode',  
				    ONS.OFFICIALNUMBER as 'IdentifierNumberText'
				    from OFFICIALNUMBERS ONS
				    join #NUMBERTYPE_VIEW NTV ON (NTV.NUMBERTYPE_INPRO = ONS.NUMBERTYPE AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
				    where ONS.CASEID = C.CASEID
				    and ONS.ISCURRENT = 1
				    for XML PATH('IdentifierNumberDetails'), TYPE
				)
		"
		Set @sSQLString4 = ",
				(Select	-- <EventDetails>
				    TEMPEVENT.EVENTCODE as 'EventCode',
				    TEMPEVENT.EVENTDATE as 'EventDate',
				    TEMPEVENT.EVENTDUEDATE as 'EventDueDate', 
				    TEMPEVENT.CYCLE as 'EventCycle', 
				    TEMPEVENT.EVENTTEXT as 'EventText'
				    from 
				    (Select   --Renewal events
					EV.EVENT_CPAXML as 'EVENTCODE', 
					replace( convert(nvarchar(10), CE.EVENTDATE, 111), '/', '-') as 'EVENTDATE', 
					replace( convert(nvarchar(10), CE.EVENTDUEDATE, 111), '/', '-') as 'EVENTDUEDATE', 
					CE.CYCLE as 'CYCLE', 
					CE.EVENTTEXT as 'EVENTTEXT'
					from CASEEVENT CE
					Join (	select MIN(O.CYCLE) as [CYCLE], O.CASEID
						from OPENACTION O
						join SITECONTROL SC on (SC.CONTROLID='Main Renewal Action')
						where O.ACTION=SC.COLCHARACTER
						and O.POLICEEVENTS=1
						group by O.CASEID) OA on (OA.CASEID = CE.CASEID and OA.CYCLE = CE.CYCLE)
					join EVENTS E on (E.EVENTNO = CE.EVENTNO)  
					join #EVENT_VIEW EV on (EV.EVENT_INPRO = CE.EVENTNO AND EV.EVENT_CPAXML is not null)
					where CE.CASEID = C.CASEID
					and CE.EVENTNO = -11
					and E.IMPORTANCELEVEL >= (select COLINTEGER 
								from SITECONTROL 
								where CONTROLID = 'Client Importance' ) 
				    UNION 
				    Select    -- other CYCLIC events 
					distinct EV.EVENT_CPAXML as 'EVENTCODE', 
					replace( convert(nvarchar(10), CE.EVENTDATE, 111), '/', '-') as 'EVENTDATE', 
					replace( convert(nvarchar(10), CE.EVENTDUEDATE, 111), '/', '-') as 'EVENTDUEDATE', 
					CE.CYCLE as 'CYCLE', 
					CE.EVENTTEXT as 'EVENTTEXT'
					from CASEEVENT CE
					-- events with multiple cycles
					join (select CASEID, EVENTNO
						from CASEEVENT 
						where CASEID = C.CASEID
						group by CASEID, EVENTNO
						having count(*) > 1    
						) as CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO)
					join EVENTS E on (E.EVENTNO = CE.EVENTNO)
					join(	select CASEID, ACTION, CRITERIANO, min(CYCLE) as CYCLE
						from OPENACTION
						where POLICEEVENTS=1
						group by CASEID, ACTION, CRITERIANO) OA 
								on (OA.CASEID=CE.CASEID
								and OA.ACTION= COALESCE (E.CONTROLLINGACTION, CE.CREATEDBYACTION, OA.ACTION))
					join EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO
							     and EC.EVENTNO=CE.EVENTNO)
					join ACTIONS A on (A.ACTION=OA.ACTION)
					join #EVENT_VIEW EV on (EV.EVENT_INPRO = CE.EVENTNO AND EV.EVENT_CPAXML is not null)
					where CE.EVENTNO != -11   -- exclude next renewal event
					and CE.OCCURREDFLAG<9
					and CE.CASEID=C.CASEID
					and CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) 
							    THEN OA.CYCLE
							    ELSE isnull((select min(CYCLE) 
									    from CASEEVENT CE1 
									    where CE1.CASEID=CE.CASEID 
									    and CE1.EVENTNO=CE.EVENTNO 
									    and CE1.OCCURREDFLAG=0),
									(Select max(CYCLE) 
									    from CASEEVENT CE2 
									    where CE2.CASEID=CE.CASEID 
									    and CE2.EVENTNO=CE.EVENTNO 
									    and CE2.OCCURREDFLAG<9) )
						     END
					and E.IMPORTANCELEVEL >=    (select COLINTEGER 
								    from SITECONTROL 
								    where CONTROLID = 'Client Importance' ) 
					"
		Set @sSQLString4A = "
				    UNION
				    Select	/* other NON-CYCLIC events */
					EV.EVENT_CPAXML as 'EVENTCODE', 
					replace( convert(nvarchar(10), CE.EVENTDATE, 111), '/', '-') as 'EVENTDATE', 
					replace( convert(nvarchar(10), CE.EVENTDUEDATE, 111), '/', '-') as 'EVENTDUEDATE', 
					CE.CYCLE as 'CYCLE', 
					CE.EVENTTEXT as 'EVENTTEXT'
					from CASEEVENT CE
					-- events with 1 cycle
					join (select CASEID, EVENTNO
						from CASEEVENT 
						where CASEID = C.CASEID
						group by CASEID, EVENTNO
						having count(*) = 1    
						) as CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO)
					join EVENTS E on (E.EVENTNO = CE.EVENTNO)  
					join #EVENT_VIEW EV on (EV.EVENT_INPRO = CE.EVENTNO AND EV.EVENT_CPAXML is not null)
					where CE.CASEID = C.CASEID
					and E.IMPORTANCELEVEL >= (select COLINTEGER 
								from SITECONTROL 
								where CONTROLID = 'Client Importance' ) 
				    ) TEMPEVENT
				    for XML PATH('EventDetails'), TYPE
				)
		"



		Set @sSQLString5 = ",
				(Select	-- <NameDetails>
				    NTV.NAMETYPE_CPAXML as 'NameTypeCode', 
				    CN.SEQUENCE as 'NameSequenceNumber',
				    CN.REFERENCENO as 'NameReference',
				    (Select   --<AddressBook>
					null,
					(Select --<FormattedNameAddress>
					    null, 
					    (Select -- <Name>
						N.NAMECODE as 'SenderNameIdentifier', 
						(Select top 1 TBL2.EXTERNALNAMECODE
						from
							(select SORTORDER, count(*) as ROWCOUNTNO, max(EXTERNALNAMECODE) EXTERNALNAMECODE
							from 
								(
								-- Division name
								SELECT TOP 1 'a' AS SORTORDER, NAL.ALIAS AS EXTERNALNAMECODE
								FROM SITECONTROL SC
								JOIN NAMEALIAS NAL on (NAL.ALIASTYPE=SC.COLCHARACTER)
								WHERE NAL.NAMENO = CN.NAMENO
								and upper(CN.NAMETYPE) IN (SELECT Parameter from #DivisionNameTypes)
								and NAL.COUNTRYCODE  is null
								and NAL.PROPERTYTYPE is null
								AND SC.CONTROLID = 'Division Name Alias'
								UNION
								Select 'b' SORTORDER, EN.EXTERNALNAMECODE
								from EXTERNALNAME EN
								join EXTERNALNAMEMAPPING ENM on (ENM.EXTERNALNAMEID = EN.EXTERNALNAMEID)
								where (ENM.PROPERTYTYPE = C.PROPERTYTYPE OR PROPERTYTYPE IS NULL)
								and (ENM.INSTRUCTORNAMENO is null 
									or ENM.INSTRUCTORNAMENO = (select CN.NAMENO 
													from CASENAME CN 
													where CN.NAMETYPE = 'I' 
													and CN.NAMETYPE NOT IN (SELECT Parameter from #DivisionNameTypes)
													and CN.CASEID = C.CASEID) )
								and ENM.INPRONAMENO = CN.NAMENO
								and EN.NAMETYPE = CN.NAMETYPE
								and EN.DATASOURCENAMENO = (Select SD.SENDERNAMENO
									    from EDESENDERDETAILS SD														
									    where SD.BATCHNO = TB.BATCHNO)
								UNION
								Select 'c' SORTORDER, N.SENDERNAMEIDENTIFIER as EXTERNALNAMECODE
								from EDECASENAMEDETAILS CND
								join EDENAME N on ( N.BATCHNO = CND.BATCHNO and N.TRANSACTIONIDENTIFIER = CND.TRANSACTIONIDENTIFIER and N.NAMETYPECODE = CND.NAMETYPECODE )
								where CND.BATCHNO = TB.BATCHNO 
								and CND.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
								and CND.NAMETYPECODE_T = CN.NAMETYPE
								and CND.NAMETYPECODE_T NOT IN (SELECT Parameter from #DivisionNameTypes)
								) TBL
							group by SORTORDER) TBL2
						where TBL2.ROWCOUNTNO=1 
						order by TBL2.SORTORDER
						) as 'ReceiverNameIdentifier',"


		Set @sSQLString5A = "
		                        	N.TITLE as 'FormattedName/NamePrefix',
						-- NAME.USEDASFLAG & 1 = 1 is Individual, else Organization.
						Case when ( (N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)=0)) then
							N.FIRSTNAME
						    when ( (N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)>0)) then
							left (N.FIRSTNAME, charindex(' ', N.FIRSTNAME))
						end as 'FormattedName/FirstName',

						Case when ((N.USEDASFLAG & 1 = 1) and (charindex(' ', ltrim(rtrim(N.FIRSTNAME)))>0) ) then
						    right (ltrim(rtrim(N.FIRSTNAME)), len(ltrim(rtrim(N.FIRSTNAME))) - charindex(' ', ltrim(rtrim(N.FIRSTNAME))))  
						end as 'FormattedName/MiddleName',

						Case when (N.USEDASFLAG & 1 = 1) then
						    N.NAME 
						end as 'FormattedName/LastName',

			                        Case IND.SEX 
						    when  'M' then 'Male' 
						    when  'F' then 'Female' 
						end as 'FormattedName/Gender',

						-- TODO N.REMARKS is not one of valid values hard coded in cpa-xml.xsd for IndividualIdentifier
			                        --N.REMARKS as 'FormattedName/IndividualIdentifier',

						Case when (N.USEDASFLAG & 1 = 1) 
						    -- individual salutation
						    then (select FORMALSALUTATION FROM INDIVIDUAL where NAMENO = N.NAMENO)  
						    -- Organisation main contact's salutation
						    else (select FORMALSALUTATION FROM INDIVIDUAL where NAMENO = N.MAINCONTACT)  
						end as 'FormattedName/Salutation',

						Case when not (N.USEDASFLAG & 1 = 1) then
			                        	N.NAME 
						end as 'FormattedName/OrganizationName'

		                        	from NAME N
						left join INDIVIDUAL IND on (IND.NAMENO = N.NAMENO)
						where N.NAMENO = CN.NAMENO 
			                        for XML PATH('Name'), TYPE
			                     )
		"


		Set @sSQLString6 = ",			
			                     (
			                     Select -- <Address>
			                        null,
			                        (	
			                        Select --<FormattedAddress>
			                           null,	
			                           (		
			                           Select  -- <AddressLines>
			                              DISTINCT TATN.SEQUENCENUMBER as 'AddressLine/@sequenceNumber', 
			                              TATN.ADDRESSLINE as 'AddressLine'
			                              from #TEMPCASENAMEADDRESS TCNA
													join " + @sTokenisedAddressTableName  + " TATN on (TATN.ADDRESSCODE = TCNA.ADDRESSCODE) 
			                              where TCNA.CASEID = CN.CASEID 
			                              and TCNA.NAMETYPE = CN.NAMETYPE
			                              and TCNA.NAMENO = CN.NAMENO
													and TCNA.SEQUENCE = CN.SEQUENCE
			                              ORDER BY TATN.SEQUENCENUMBER 
			                              for XML PATH(''), TYPE
			                           ),
			                           (
						    Select  -- <AddressCity><AddressState>	
							DISTINCT ADDR.CITY as 'AddressCity', 
							ADDR.STATE as 'AddressState', 
							ADDR.POSTCODE as 'AddressPostcode', 
							isnull(COU.ALTERNATECODE, COU.COUNTRYCODE) as 'AddressCountryCode'
							from #TEMPCASENAMEADDRESS TCNA
							join ADDRESS ADDR on (ADDR.ADDRESSCODE = TCNA.ADDRESSCODE)
							join COUNTRY COU on (COU.COUNTRYCODE = ADDR.COUNTRYCODE)
							where TCNA.CASEID = CN.CASEID 
							and TCNA.NAMETYPE = CN.NAMETYPE
							and TCNA.NAMENO = CN.NAMENO
							and TCNA.SEQUENCE = CN.SEQUENCE
							for XML PATH(''), TYPE
						    )
						    for XML PATH('FormattedAddress'), TYPE
			                        )
			                        for XML PATH('Address'), TYPE
			                     )
		"


		Set @sSQLString7 = "		,			
			                     (
			                     Select -- <AttentionOf>
						N.TITLE as 'FormattedAttentionOf/NamePrefix',  
						N.FIRSTNAME as 'FormattedAttentionOf/FirstName', 
						N.NAME as 'FormattedAttentionOf/LastName'
						from NAME N 
						where N.NAMENO = (
							Select isnull(CN2.CORRESPONDNAME, MAINCONTACT.MAINCONTACT) AS NAMENO
							from CASENAME CN2
							left join NAME MAINCONTACT on (MAINCONTACT.NAMENO = CN2.NAMENO)
							where CN2.CASEID = CN.CASEID 
							and CN2.NAMETYPE = CN.NAMETYPE
							and CN2.NAMENO = CN.NAMENO
							and CN2.SEQUENCE = CN.SEQUENCE 
							)
			                        for XML PATH('AttentionOf'), TYPE
			                     )
			                     for XML PATH('FormattedNameAddress'), TYPE
			                  )  -- <FormattedNameAddress>

		"


		Set @sSQLString8 = "	,
			                  (
			                  Select -- <ContactInformationDetails>
					    (Select SORTORDER as 'Phone/@sequenceNumber',
						    PHONE as 'Phone'
						    from
						    (Select 1 as SORTORDER, dbo.fn_FormatTelecom(1901, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'PHONE' 
						    from NAME N
						    join TELECOMMUNICATION TEL on (TEL.TELECODE = N.MAINPHONE)
						    where NAMENO = CN.NAMENO
						    UNION
						    Select ROW_NUMBER() OVER (order by N.NAMENO ) + 1 as SORTORDER, dbo.fn_FormatTelecom(1901, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'PHONE'
						    from NAME N
						    join NAMETELECOM NTEL on (NTEL.NAMENO = N.NAMENO and NTEL.TELECODE != N.MAINPHONE)
						    join TELECOMMUNICATION TEL on (TEL.TELECODE = NTEL.TELECODE)
						    where N.NAMENO = CN.NAMENO
						    and TEL.TELECOMTYPE = 1901
						    ) temp
						    order by SORTORDER
						    for XML PATH(''), TYPE
					    ),

					    (Select SORTORDER as 'Fax/@sequenceNumber',
						    FAX as 'Fax'
						    from
						    (Select 1 as SORTORDER, dbo.fn_FormatTelecom(1902, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'FAX'
						    from NAME N
						    join TELECOMMUNICATION TEL on (TEL.TELECODE = N.FAX)
						    where NAMENO = CN.NAMENO
						    UNION
						    Select ROW_NUMBER() OVER (order by N.NAMENO ) + 1 as SORTORDER, dbo.fn_FormatTelecom(1902, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'FAX'
						    from NAME N
						    join NAMETELECOM NTEL on (NTEL.NAMENO = N.NAMENO and NTEL.TELECODE != N.FAX)
						    join TELECOMMUNICATION TEL on (TEL.TELECODE = NTEL.TELECODE)
						    where N.NAMENO = CN.NAMENO
						    and TEL.TELECOMTYPE = 1902
						    ) temp
						    order by SORTORDER
						    for XML PATH(''), TYPE
					    ), 

					    (Select SORTORDER as 'Email/@sequenceNumber',
						    EMAIL as 'Email'
						    from
						    (Select 1 as SORTORDER, dbo.fn_FormatTelecom(1903, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'EMAIL' 
						    from NAME N
						    join TELECOMMUNICATION TEL on (TEL.TELECODE = N.MAINEMAIL)
						    where NAMENO = CN.NAMENO
						    UNION
						    Select ROW_NUMBER() OVER (order by N.NAMENO ) + 1 as SORTORDER, dbo.fn_FormatTelecom(1903, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'EMAIL'
						    from NAME N
						    join NAMETELECOM NTEL on (NTEL.NAMENO = N.NAMENO and NTEL.TELECODE != N.MAINEMAIL)
						    join TELECOMMUNICATION TEL on (TEL.TELECODE = NTEL.TELECODE)
						    where N.NAMENO = CN.NAMENO
						    and TEL.TELECOMTYPE = 1903
						    ) temp
						    order by SORTORDER
						    for XML PATH(''), TYPE
					    ) 
					    for XML PATH('ContactInformationDetails'), TYPE
			                  )		
		"


		Set @sSQLString9 = "	
			                  for XML PATH('AddressBook'), TYPE
					)	-- <AddressBook>
					from CASENAME CN
					join #SiteCtrlNameTypes VNT on (VNT.Parameter = CN.NAMETYPE)
					join #NAMETYPE_VIEW NTV on (NTV.NAMETYPE_INPRO = CN.NAMETYPE and NTV.NAMETYPE_CPAXML is not null)
					where CN.CASEID = C.CASEID
					for XML PATH('NameDetails'), TYPE
			            ) -- <NameDetails>
		"

		Set @sSQLString10 = " , 
			            ( 
			            Select     	-- <AssociatedCaseDetails>
			               RV.RELATIONSHIP_CPAXML as 'AssociatedCaseRelationshipCode', 
			               isnull(COU1.ALTERNATECODE, COU2.ALTERNATECODE) as 'AssociatedCaseCountryCode',
			               (
			               Select     	-- <AssociatedCaseIdentifierNumberDetails>
			                  TEMP.NUMBERTYPE as 'IdentifierNumberCode', 
			                  TEMP.NUMBERTEXT as 'IdentifierNumberText'
			                  from 
					    (
					    Select 
						    NTV.NUMBERTYPE_CPAXML as NUMBERTYPE, 
						    RC2.OFFICIALNUMBER as NUMBERTEXT
						    from RELATEDCASE RC2
						    join  #NUMBERTYPE_VIEW NTV on (NTV.NUMBERTYPE_INPRO = 'R' AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
						    where RC2.CASEID = RC.CASEID
						    and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
						    and RC2.OFFICIALNUMBER is not null
					    Union
					    Select NTV.NUMBERTYPE_CPAXML, OFN.OFFICIALNUMBER
						    from RELATEDCASE RC2
						    --join CASES CA on (CA.CASEID = RC.RELATEDCASEID)
						    join OFFICIALNUMBERS OFN on (OFN.CASEID = RC.RELATEDCASEID AND OFN.ISCURRENT = 1)
						    join #NUMBERTYPE_VIEW NTV on (NTV.NUMBERTYPE_INPRO = OFN.NUMBERTYPE AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
						    where RC2.CASEID = RC.CASEID
						    and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
						    and RC2.OFFICIALNUMBER is null
					    ) TEMP
			                  for XML PATH('AssociatedCaseIdentifierNumberDetails'), TYPE
			               )
		"

		Set @sSQLString11 = " , 
			               (
			               Select     	-- <AssociatedCaseEventDetails>
					    TEMP.EVENTCODE as 'EventCode', 
					    replace( convert(nvarchar(10), TEMP.EVENTDATE, 111), '/', '-') as 'EventDate'
					    from
					    (
					    Select EV.EVENT_CPAXML as EVENTCODE, RC2.PRIORITYDATE as EVENTDATE 
						    from RELATEDCASE RC2
						    join #EVENT_VIEW EV on (EV.EVENT_INPRO = -4 and EV.EVENT_CPAXML is not null)
						    where RC2.CASEID = RC.CASEID
						    and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
						    and RC2.OFFICIALNUMBER is not null
						    and RC2.RELATEDCASEID is null
					    Union
					    Select EV.EVENT_CPAXML, CE.EVENTDATE
						    from RELATEDCASE RC2
						    join CASEEVENT CE on (CE.CASEID = RC2.RELATEDCASEID and CE.EVENTNO = -4)
						    join #EVENT_VIEW EV on (EV.EVENT_INPRO = -4 and EV.EVENT_CPAXML is not null)
						    where RC2.CASEID = RC.CASEID
						    and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
						    and RC2.RELATEDCASEID is not null
					    ) TEMP
					    for XML PATH('AssociatedCaseEventDetails'), TYPE
					)
					from RELATEDCASE RC
					join #RELATIONSHIP_VIEW RV on (RV.RELATIONSHIP_INPRO = RC.RELATIONSHIP AND RV.RELATIONSHIP_CPAXML is not null)
					left join CASES CA on (CA.CASEID = RC.RELATEDCASEID)
					left join COUNTRY COU1 on (COU1.COUNTRYCODE = CA.COUNTRYCODE) 
					left join COUNTRY COU2 on (COU2.COUNTRYCODE = RC.COUNTRYCODE)
			               where RC.CASEID =  C.CASEID
			               for XML PATH('AssociatedCaseDetails'), TYPE
			            ), 

			     	    ( 
			            Select     	-- <DesignatedCountryDetails>
					isnull(COU.ALTERNATECODE, COU.COUNTRYCODE) as 'DesignatedCountryCode'
					from RELATEDCASE RC
					join COUNTRY COU on (COU.COUNTRYCODE = RC.COUNTRYCODE)
					where RC.RELATIONSHIP = 'DC1'
					and RC.CASEID =  C.CASEID
					for XML PATH('DesignatedCountryDetails'), TYPE
			            )
		"


		Set @sSQLString12 = ",

				    ( 
			            Select     	-- <GoodsServicesDetails> for International classes 'Nice' 
					'Nice' as 'ClassificationTypeCode',
					( 
					Select     	-- <ClassDescriptionDetails>  
					    null,
					    (
					    Select  -- <ClassDescription>
						IC.CLASS as 'ClassNumber'
						from  " + @sCaseClassTableName + " IC
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
						from  " + @sCaseClassTableName + " IC
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


		Set @sSQLString13 = "		
				    from CASES C
				    left join EDECASEDETAILS ECD on (ECD.BATCHNO =  TT.BATCHNO AND ECD.TRANSACTIONIDENTIFIER = TT.TRANSACTIONIDENTIFIER)
				    left join CASETYPE CT on (CT.CASETYPE = C.CASETYPE)
				    left join #PROPERTYTYPE_VIEW PTV on (PTV.PROPERTYTYPE_INPRO = C.PROPERTYTYPE AND PTV.PROPERTYTYPE_CPAXML IS NOT NULL)
				    left join COUNTRY COU on (COU.COUNTRYCODE = C.COUNTRYCODE)
				    left join PROPERTY P on (P.CASEID = C.CASEID)
				    left join #BASIS_VIEW BV on (BV.BASIS_INPRO = P.BASIS and P.BASIS IS NOT NULL AND BV.BASIS_CPAXML IS NOT NULL )
				    where C.CASEID = TT.CASEID
				    for XML PATH('CaseDetails'), TYPE
				)  -- <CaseDetails>
				for XML PATH('TransactionData'), TYPE
			    ) 	-- <TransactionData>
			    from EDETRANSACTIONCONTENTDETAILS TCD
			    where TCD.BATCHNO =  TB.BATCHNO
			    and TCD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			    for XML PATH('TransactionContentDetails'), TYPE
			)	-- <TransactionContentDetails>


		"

		Set @sSQLStringLast = "		
			from EDETRANSACTIONBODY TB   
			where TB.BATCHNO = TT.BATCHNO
			and TB.TRANSACTIONIDENTIFIER = TT.TRANSACTIONIDENTIFIER
			FOR XML PATH(''), ROOT('TransactionBody') 
		    ) as XMLSTR
		    from #TEMPTRANSACTION TT
		    where TT.TRANSACTIONTYPE  in ('LIVECASE', 'DRAFTCASE')
		"

/*
		If @bDebug = 1
		Begin		
			PRINT '--1--' + @sSQLString1
			PRINT '--2--' + @sSQLString2
			PRINT '--3--' + @sSQLString3
			PRINT '--4--' + @sSQLString4
			PRINT '--5--' + @sSQLString5
			PRINT '--5A--' + @sSQLString5A
			PRINT '--6--' + @sSQLString6
			PRINT '--7--' + @sSQLString7
			PRINT '--8--' + @sSQLString8
			PRINT '--9--' + @sSQLString9
			PRINT '--10--' + @sSQLString10
			PRINT '--11--' + @sSQLString11
			PRINT '--12--' + @sSQLString12
			PRINT '--13--' + @sSQLString13
			PRINT '--last--' + @sSQLStringLast
		End
*/

		If @nErrorCode = 0
		Begin
			exec(@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString4A+@sSQLString5+@sSQLString5A+@sSQLString6+@sSQLString7+@sSQLString8+@sSQLString9+@sSQLString10+@sSQLString11+@sSQLString12+@sSQLString13+@sSQLStringLast)
			set @nErrorCode=@@error
		End

   End  /* Draft or Live case transactions */




	-------------------------------------------------------------------------------------------------------
	-- Extract REJECTED case transactions data from EDE tables (i.e. sender original data)
	-------------------------------------------------------------------------------------------------------
	If (@nErrorCode = 0 and exists (Select 1 from #TEMPTRANSACTION where TRANSACTIONTYPE  = 'REJECTEDCASE'))
	Begin
		If @bDebug = 1
			print 'create transaction body for REJECTED CASE.' 

		Set @sSQLString1 = ""
		Set @sSQLString2 = ""
		Set @sSQLString3 = ""
		Set @sSQLString4 = ""
		Set @sSQLString5 = ""
		Set @sSQLString5A = ""
		Set @sSQLString6 = ""
		Set @sSQLString7 = ""

		Set @sSQLString1 = "
		Insert into   "+ @sTempEPLTableName +"   (ROWID, XMLSTR)
		Select 
		    TT.ROWID, 
		    (
		    Select 	-- <TransactionBody>
			(Select TT.TRANSACTIONIDENTIFIER ) as 'TransactionIdentifier',
			(Select 
				top 1 TM.DESCRIPTION
				from TRANSACTIONMESSAGE TM
				join TRANSACTIONINFO TI on (TI.TRANSACTIONMESSAGENO = TM.TRANSACTIONMESSAGENO)
				where TI.BATCHNO = TB.BATCHNO
				and TI.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
				and TM.TRANSACTIONTYPE = 'C'
				order by TM.MESSAGEPRIORITY ASC
			) as 'TransactionReturnCode',

			(Select		-- <TransactionMessageDetails>
			    1 as '@sequentialNumber',	
			    TC.USERCODE as 'TransactionMessageCode', 
			    TC.DESCRIPTION as 'TransactionMessageText'
			    from EDETRANSACTIONBODY TB2
			    join TABLECODES TC on ( TC.TABLECODE = TB2.TRANSNARRATIVECODE AND TC.TABLETYPE = 402)
			    where TB2.BATCHNO =  TB.BATCHNO
			    and TB2.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			    and TB2.TRANSNARRATIVECODE  is not null
			    for XML PATH('TransactionMessageDetails'), TYPE 
			),
			(Select		-- <TransactionMessageDetails>
			    SI.ISSUECODE as 'TransactionMessageCode', 
			    SI.SHORTDESCRIPTION as 'TransactionMessageText'
			    from EDEOUTSTANDINGISSUES OI
			    join EDESTANDARDISSUE SI on (SI.ISSUEID = OI.ISSUEID)
			    where OI.BATCHNO =  TB.BATCHNO
			    and OI.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			    for XML PATH('TransactionMessageDetails'), TYPE
			)
		"

		Set @sSQLString2 = ",

			   ( 
			   Select    -- <TransactionContentDetails>
			      TCD.ALTERNATIVESENDER as 'AlternativeSender',
			      'Case Import Response' as 'TransactionCode', 
			      TCD.TRANSACTIONCOMMENT AS 'TransactionComment',
			      (
			      Select 	-- <TransactionData>
			         null,
			        (	
			        select 	-- <CaseDetails>
			            CD.SENDERCASEIDENTIFIER as 'SenderCaseIdentifier', 
			            CD.RECEIVERCASEREFERENCE as 'SenderCaseReference', 
			            CD.SENDERCASEREFERENCE as 'ReceiverCaseReference', 
			            CD.CASETYPECODE as 'CaseTypeCode', 
			            CD.CASEPROPERTYTYPECODE as 'CasePropertyTypeCode', 
			            CD.CASECATEGORYCODE as 'CaseCategoryCode', 
			            CD.CASESUBTYPECODE as 'CaseSubTypeCode', 
			            CD.CASEBASISCODE as 'CaseBasisCode', 
			            COALESCE (COU.ALTERNATECODE, COU.COUNTRYCODE, CD.CASECOUNTRYCODE) as 'CaseCountryCode', 
			            CD.ENTITYSIZE as 'EntitySize', 
			            CD.NUMBERCLAIMS as 'NumberClaims', 
			            CD.NUMBERDESIGNS as 'NumberDesigns', 
			            CD.EXTENDEDNUMBERYEARS as 'ExtendedNumberYears', 
			            CD.STOPREASONCODE as 'StopReasonCode',
			            ( 
			            Select     	-- <DescriptionDetails>
			               DD.DESCRIPTIONCODE as 'DescriptionCode', 
			               DD.DESCRIPTIONTEXT as 'DescriptionText'
			               from EDEDESCRIPTIONDETAILS DD
			               where DD.BATCHNO =  TB.BATCHNO
			               and DD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
								and DD.DESCRIPTIONCODE is not null
								and DD.DESCRIPTIONTEXT is not null
			               for XML PATH('DescriptionDetails'), TYPE
			            ),
			     	      ( 
			            Select	-- <IdentifierNumberDetails>
			               IND.IDENTIFIERNUMBERCODE as 'IdentifierNumberCode', 
			               IND.IDENTIFIERNUMBERTEXT as 'IdentifierNumberText'
			               from EDEIDENTIFIERNUMBERDETAILS IND
			               where IND.BATCHNO =  TB.BATCHNO
			               and IND.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
				       and IND.ASSOCIATEDCASERELATIONSHIPCODE IS NULL
			               for XML PATH('IdentifierNumberDetails'), TYPE
			            ),
		"


		Set @sSQLString3 = "
			            ( 
			            Select	-- <EventDetails>
					ED.EVENTCODE as 'EventCode', 
					replace( convert(nvarchar(10), ED.EVENTDATE, 111), '/', '-') as 'EventDate',
					replace( convert(nvarchar(10), ED.EVENTDUEDATE, 111), '/', '-') as 'EventDueDate',
					ED.EVENTCYCLE as 'EventCycle', 
					ED.EVENTTEXT as 'EventText'
					from EDEEVENTDETAILS ED
					where ED.BATCHNO =  TB.BATCHNO
					and ED.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
					for XML PATH('EventDetails'), TYPE
			            ),
			            ( 
				    Select	-- <NameDetails>
					CND.NAMETYPECODE as 'NameTypeCode', 
					CND.NAMESEQUENCENUMBER as 'NameSequenceNumber', 
					CND.NAMEREFERENCE as 'NameReference',
					(
					Select   --<AddressBook>
					    null,
					    (
					    Select --<FormattedNameAddress>
						null, 
						(
						Select -- <Name>
						    N.RECEIVERNAMEIDENTIFIER as 'SenderNameIdentifier', 
						    N.SENDERNAMEIDENTIFIER as 'ReceiverNameIdentifier',
						    FN.NAMEPREFIX as 'FormattedName/NamePrefix',
						    FN.FIRSTNAME as 'FormattedName/FirstName',
						    FN.MIDDLENAME as 'FormattedName/MiddleName',
						    FN.LASTNAME as 'FormattedName/LastName',
						    FN.GENDER as 'FormattedName/Gender',
						    FN.INDIVIDUALIDENTIFIER as 'FormattedName/IndividualIdentifier',
						    FN.ORGANIZATIONNAME as 'FormattedName/OrganizationName'
						    from EDENAME N 
						    left join EDEFORMATTEDNAME FN on (FN.BATCHNO = N.BATCHNO and FN.TRANSACTIONIDENTIFIER = N.TRANSACTIONIDENTIFIER and FN.NAMETYPECODE = N.NAMETYPECODE)
						    where N.BATCHNO = CND.BATCHNO 
						    and N.TRANSACTIONIDENTIFIER = CND.TRANSACTIONIDENTIFIER
						    and N.NAMETYPECODE = CND.NAMETYPECODE
						    for XML PATH('Name'), TYPE
						),
		"

		Set @sSQLString4 = "			
			                     (
			                     Select -- <Address>
			                        null,
			                        (	
			                        Select --<FormattedAddress>
			                           null,	
			                           (		
			                           Select  -- <AddressLines>
			                              FA.SEQUENCENUMBER as 'AddressLine/@sequenceNumber', 
			                              FA.ADDRESSLINE as 'AddressLine'
			                              from EDEFORMATTEDADDRESS FA 
			                              where FA.BATCHNO = CND.BATCHNO 
			                              and FA.TRANSACTIONIDENTIFIER = CND.TRANSACTIONIDENTIFIER
			                              and FA.NAMETYPECODE = CND.NAMETYPECODE
			                              and FA.SEQUENCENUMBER is not null
			                              for XML PATH(''), TYPE
			                           ),
			                           (
			                           Select  -- <AddressCity><AddressState>	
			                              FA.ADDRESSCITY as 'AddressCity', 
			                              FA.ADDRESSSTATE as 'AddressState', 
			                              FA.ADDRESSPOSTCODE as 'AddressPostcode', 
			                              COALESCE (COU.ALTERNATECODE, COU.COUNTRYCODE, FA.ADDRESSCOUNTRYCODE) as 'AddressCountryCode'
			                              from EDEFORMATTEDADDRESS FA 
						      left join COUNTRY COU on (COU.COUNTRYCODE = FA.ADDRESSCOUNTRYCODE)
			                              where FA.BATCHNO = CND.BATCHNO 
			                              and FA.TRANSACTIONIDENTIFIER = CND.TRANSACTIONIDENTIFIER
			                              and FA.NAMETYPECODE = CND.NAMETYPECODE
			                              and FA.SEQUENCENUMBER is not null
			                              for XML PATH(''), TYPE
			                           )
			                           for XML PATH('FormattedAddress'), TYPE
			                        )
			                        for XML PATH('Address'), TYPE
			                     ),
			                     (
			                     Select -- <AttentionOf>
			                        FAO.NAMEPREFIX as 'FormattedAttentionOf/NamePrefix', 
			                        FAO.FIRSTNAME as 'FormattedAttentionOf/FirstName',
			                        FAO.LASTNAME as 'FormattedAttentionOf/LastName'
			                        from EDEFORMATTEDATTNOF FAO 
			                        where FAO.BATCHNO = CND.BATCHNO 
			                        and FAO.TRANSACTIONIDENTIFIER = CND.TRANSACTIONIDENTIFIER
			                        and FAO.NAMETYPECODE = CND.NAMETYPECODE
			                        for XML PATH('AttentionOf'), TYPE
			                     )		
			                     for XML PATH('FormattedNameAddress'), TYPE
			                  ),
			                  (
			                  Select -- <ContactInformationDetails>
			                     CID.PHONE as 'Phone',
			                     CID.FAX as 'Fax',
			                     CID.EMAIL as 'Email'
			                     from EDECONTACTINFORMATIONDETAILS CID
			                     where CID.BATCHNO = CND.BATCHNO 
			                     and CID.TRANSACTIONIDENTIFIER = CND.TRANSACTIONIDENTIFIER
			                     and CID.NAMETYPECODE = CND.NAMETYPECODE
			                     for XML PATH('ContactInformationDetails'), TYPE
			                  )		
			                  for XML PATH('AddressBook'), TYPE
			               )	
			               from EDECASENAMEDETAILS CND 
			               where CND.BATCHNO = TB.BATCHNO 
			               and CND.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			               for XML PATH('NameDetails'), TYPE
			            ),
		"


		Set @sSQLString5 = "
			            ( 
			            Select     	-- <AssociatedCaseDetails>
			               ACD.ASSOCIATEDCASERELATIONSHIPCODE as 'AssociatedCaseRelationshipCode', 
			               COALESCE (COU.ALTERNATECODE, COU.COUNTRYCODE, ACD.ASSOCIATEDCASECOUNTRYCODE) as 'AssociatedCaseCountryCode',
			               (
			               Select     	-- <AssociatedCaseIdentifierNumberDetails>
			                  IND.IDENTIFIERNUMBERCODE as 'IdentifierNumberCode', 
			                  IND.IDENTIFIERNUMBERTEXT as 'IdentifierNumberText'
			                  from EDEIDENTIFIERNUMBERDETAILS IND
			                  where IND.BATCHNO =  ACD.BATCHNO
			                  and IND.TRANSACTIONIDENTIFIER = ACD.TRANSACTIONIDENTIFIER
			                  and IND.ASSOCIATEDCASERELATIONSHIPCODE = ACD.ASSOCIATEDCASERELATIONSHIPCODE
			                  for XML PATH('AssociatedCaseIdentifierNumberDetails'), TYPE
			               ),
			               (
			               Select     	-- <AssociatedCaseEventDetails>
			                  ED.EVENTCODE as 'EventCode', 
					  replace( convert(nvarchar(10), ED.EVENTDATE, 111), '/', '-') as 'EventDate'
			                  from EDEEVENTDETAILS ED
			                  where ED.BATCHNO =  ACD.BATCHNO
			                  and ED.TRANSACTIONIDENTIFIER = ACD.TRANSACTIONIDENTIFIER
			                  and ED.ASSOCIATEDCASERELATIONSHIPCODE = ACD.ASSOCIATEDCASERELATIONSHIPCODE
			                  for XML PATH('AssociatedCaseEventDetails'), TYPE
			               )
			
			               from EDEASSOCIATEDCASEDETAILS ACD
				       left join COUNTRY COU on (COU.COUNTRYCODE = ACD.ASSOCIATEDCASECOUNTRYCODE)
			               where ACD.BATCHNO =  TB.BATCHNO
			               and ACD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			               for XML PATH('AssociatedCaseDetails'), TYPE
			            ),
			     	      ( 
			            Select     	-- <DesignatedCountryDetails>
			               COALESCE (COU.ALTERNATECODE, COU.COUNTRYCODE, DCD.DESIGNATEDCOUNTRYCODE) as 'DesignatedCountryCode'
			               from  EDEDESIGNATEDCOUNTRYDETAILS DCD
				       left join COUNTRY COU on (COU.COUNTRYCODE = DCD.DESIGNATEDCOUNTRYCODE)
			               where DCD.BATCHNO =  TB.BATCHNO
			               and DCD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			               for XML PATH('DesignatedCountryDetails'), TYPE
			            ),
						"


		Set @sSQLString6 = "
				    ( 
			            Select     	-- <GoodsServicesDetails> for International 'Nice' 
					GSD.CLASSIFICATIONTYPECODE as 'ClassificationTypeCode',
					( 
					Select     	-- <ClassDescriptionDetails>  
					    null,
					    (
					    Select																	
				                  CD.CLASSNUMBER as 'ClassNumber'
				                  from  EDECLASSDESCRIPTION CD
				                  where CD.BATCHNO =  GSD.BATCHNO
				                  and CD.TRANSACTIONIDENTIFIER = GSD.TRANSACTIONIDENTIFIER
				                  and CD.CLASSIFICATIONTYPECODE = GSD.CLASSIFICATIONTYPECODE				   
				                  for XML PATH('ClassDescription'), TYPE
					    )
					    for XML PATH('ClassDescriptionDetails'), TYPE
					)  
					from  EDEGOODSSERVICESDETAILS GSD
					where GSD.BATCHNO =  TB.BATCHNO
					and GSD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
					and GSD.CLASSIFICATIONTYPECODE = 'Nice'
					group by GSD.CLASSIFICATIONTYPECODE, GSD.BATCHNO, GSD.TRANSACTIONIDENTIFIER
					for XML PATH('GoodsServicesDetails'), TYPE
			            ),
				    ( 
			            Select     	-- <GoodsServicesDetails> for local 'Domestic' 
					GSD.CLASSIFICATIONTYPECODE as 'ClassificationTypeCode',
					( 
					Select     	-- <ClassDescriptionDetails> 
					    NULL,
					    (
					    Select 	-- <ClassDescription>
						CD.CLASSNUMBER as 'ClassNumber'
						from  EDECLASSDESCRIPTION CD
						where CD.BATCHNO =  GSD.BATCHNO
						and CD.TRANSACTIONIDENTIFIER = GSD.TRANSACTIONIDENTIFIER
						and CD.CLASSIFICATIONTYPECODE = GSD.CLASSIFICATIONTYPECODE					   
						for XML PATH('ClassDescription'), TYPE
					    )
					    for XML PATH('ClassDescriptionDetails'), TYPE
					)  
					from  EDEGOODSSERVICESDETAILS GSD
					where GSD.BATCHNO =  TB.BATCHNO
					and GSD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
					and GSD.CLASSIFICATIONTYPECODE = 'Domestic'
					group by GSD.CLASSIFICATIONTYPECODE, GSD.BATCHNO, GSD.TRANSACTIONIDENTIFIER
					for XML PATH('GoodsServicesDetails'), TYPE
			            )  

		"


		Set @sSQLString7 = "			
			            from EDECASEDETAILS CD
				    left join COUNTRY COU on (COU.COUNTRYCODE = CD.CASECOUNTRYCODE)
			            where CD.BATCHNO = TB.BATCHNO
			            and CD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			            for XML PATH('CaseDetails'), TYPE
			         )
			         for XML PATH('TransactionData'), TYPE
			      )
					from EDETRANSACTIONCONTENTDETAILS TCD
			      where TCD.BATCHNO =  TB.BATCHNO
			      and TCD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			      for XML PATH('TransactionContentDetails'), TYPE
			   )
				from EDETRANSACTIONBODY TB   
				where TB.BATCHNO = TT.BATCHNO
				and TB.TRANSACTIONIDENTIFIER = TT.TRANSACTIONIDENTIFIER
				for XML PATH(''), ROOT('TransactionBody') 
				) as XMLSTR
			from #TEMPTRANSACTION TT
			where TT.TRANSACTIONTYPE  = 'REJECTEDCASE'

		"
/*		
		PRINT '--1--' + @sSQLString1
		PRINT '--2--' + @sSQLString2
		PRINT '--3--' + @sSQLString3
		PRINT '--4--' + @sSQLString4
		PRINT '--5--' + @sSQLString5
		PRINT '--6--' + @sSQLString6
		PRINT '--7--' + @sSQLString7
*/

		exec(@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString5+@sSQLString6+@sSQLString7)
		set @nErrorCode=@@error

	End	-- Rejected CASE transaction




	-------------------------------------------------------------------------------------------------------
	-- Extract PROCESSED NAME transactions data from Inprotech tables 
	-------------------------------------------------------------------------------------------------------
	If (@nErrorCode = 0 and exists (Select * from #TEMPTRANSACTION where TRANSACTIONTYPE  = 'PROCESSEDNAME'))
	Begin	
		If @bDebug = 1
			print ('create transaction body for PROCESSES NAME.')

		-- Tokenised name ADDRESS.STREET1 which is separated by carriage return character
		If @nErrorCode = 0
		Begin
			-- temp table to hold name address code
			Create table #TEMPNAMEADDRESS (
						BATCHNO						int,
						TRANSACTIONIDENTIFIER	nvarchar(50) collate database_default,
						NAMETYPE						nvarchar(3) collate database_default,
						NAMENO						int,
						ADDRESSCODE					int
						)

			If @nErrorCode = 0
			Begin
				-- Load name address based on name type
				-- Rules: if name type is Owner or Inventor use default Street address, otherwise assume is postal address for other name types.
				Set @sSQLString="
					Insert into #TEMPNAMEADDRESS ( BATCHNO, TRANSACTIONIDENTIFIER, NAMETYPE, NAMENO, ADDRESSCODE)
						Select TR.BATCHNO, TR.TRANSACTIONIDENTIFIER, NAD.NAMETYPECODE_T, N.NAMENO,
						Case 	when (NAD.NAMETYPECODE_T = 'O' or NAD.NAMETYPECODE_T = 'J') then N.STREETADDRESS
								else N.POSTALADDRESS
						end as ADDRESSCODE
						from #TEMPTRANSACTION TR
						join NAME N on (N.NAMENO = TR.NAMENO)
						join EDENAMEADDRESSDETAILS NAD on (NAD.BATCHNO = TR.BATCHNO and NAD.TRANSACTIONIDENTIFIER = TR.TRANSACTIONIDENTIFIER)
						where TR.TRANSACTIONTYPE = 'PROCESSEDNAME' 
					"
				exec @nErrorCode=sp_executesql @sSQLString
			End
			
			-- list of distinct addresscode to be tokenised
			If @nErrorCode = 0
			Begin
				Set @sSQLString="
					delete " + @sTokenisedAddressTableName
				exec 	@nErrorCode=sp_executesql @sSQLString

				If @nErrorCode = 0
				Begin
					Set @sSQLString="
						Insert into "+ @sTokenisedAddressTableName +"( ADDRESSCODE)
						Select distinct ADDRESSCODE
						from #TEMPNAMEADDRESS			"
					exec 	@nErrorCode=sp_executesql @sSQLString
				End
			End

			-- And tokenise name ADDRESS.STREET1 into multiple lines
			If @nErrorCode = 0
			Begin
				Exec @nErrorCode=ede_TokeniseAddressLine @sTokenisedAddressTableName	
			End
		End


		Set @sSQLString1 = ""
		Set @sSQLString2 = ""
		Set @sSQLString3 = ""
		Set @sSQLString4 = ""


		Set @sSQLString1 = "
		Insert into   "+ @sTempEPLTableName +"   (ROWID, XMLSTR)
		select 
		    TT.ROWID, 
		    (Select 		--<TransactionBody>
			(Select TT.TRANSACTIONIDENTIFIER) as 'TransactionIdentifier',
			(Select 
				top 1 TM.DESCRIPTION
				from TRANSACTIONMESSAGE TM
				join TRANSACTIONINFO TI on (TI.TRANSACTIONMESSAGENO = TM.TRANSACTIONMESSAGENO)
				where TI.BATCHNO = TB.BATCHNO
				and TI.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
				and TM.TRANSACTIONTYPE = 'N'
			    order by TM.MESSAGEPRIORITY ASC
			) as 'TransactionReturnCode',
			(Select		-- <TransactionMessageDetails>
			    1 as '@sequentialNumber',	
			    TC.USERCODE as 'TransactionMessageCode', 
			    TC.DESCRIPTION as 'TransactionMessageText'
			    from EDETRANSACTIONBODY TB2
			    join TABLECODES TC on ( TC.TABLECODE = TB2.TRANSNARRATIVECODE AND TC.TABLETYPE = 402)
			    where TB2.BATCHNO =  TB.BATCHNO
			    and TB2.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			    and TB2.TRANSNARRATIVECODE  is not null
			    for XML PATH('TransactionMessageDetails'), TYPE 
			),
			(Select		-- <TransactionMessageDetails>
			    SI.ISSUECODE as 'TransactionMessageCode', 
			    SI.SHORTDESCRIPTION as 'TransactionMessageText'
			    from EDEOUTSTANDINGISSUES OI
			    join EDESTANDARDISSUE SI on (SI.ISSUEID = OI.ISSUEID)
			    where OI.BATCHNO =  TB.BATCHNO
			    and OI.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			    for XML PATH('TransactionMessageDetails'), TYPE
			)

		"

		--
		Set @sSQLString2 = ",
			( 
			Select    -- <TransactionContentDetails>
			    'Name Import Response' as 'TransactionCode', 
			    (
			    Select 	-- <TransactionData>
				null,
				(	
				select 	-- <NameAddressDetails>
				    NAD.NAMETYPECODE as 'NameTypeCode',
				    (
				    Select   --<AddressBook>
					null,
					(
					Select --<FormattedNameAddress>
					    null, 
					    (
					    Select -- <Name>
						N.NAMECODE as 'SenderNameIdentifier', 
						EDEN.SENDERNAMEIDENTIFIER as 'ReceiverNameIdentifier',
						N.TITLE as 'FormattedName/NamePrefix',

						-- NAME.USEDASFLAG & 1 = 1 is Individual, else Organization.
						Case when ( (N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)=0)) then
							N.FIRSTNAME
						    when ( (N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)>0)) then
							left (N.FIRSTNAME, charindex(' ', N.FIRSTNAME))
						end as 'FormattedName/FirstName',

						Case when ((N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)>0)) then
							right (ltrim(rtrim(N.FIRSTNAME)), len(ltrim(rtrim(N.FIRSTNAME))) - charindex(' ', ltrim(rtrim(N.FIRSTNAME))))  
						end as 'FormattedName/MiddleName',

						Case when (N.USEDASFLAG & 1 = 1) then
							N.NAME 
						end as 'FormattedName/LastName',

						Case IND.SEX 
							when  'M' then 'Male' 
							when  'F' then 'Female' 
						end as 'FormattedName/Gender',

						-- TODO N.REMARKS is not one of valid values hard coded in cpa-xml.xsd for IndividualIdentifier
						--N.REMARKS as 'FormattedName/IndividualIdentifier',

						Case when (N.USEDASFLAG & 1 = 1) 
						    -- individual salutation
						    then (select FORMALSALUTATION FROM INDIVIDUAL where NAMENO = N.NAMENO)  
						    -- Organisation main contact's salutation
						    else (select FORMALSALUTATION FROM INDIVIDUAL where NAMENO = N.MAINCONTACT)  
						end as 'FormattedName/Salutation',

						Case when not (N.USEDASFLAG & 1 = 1) then
							N.NAME 
						end as 'FormattedName/OrganizationName'

						from NAME N
						left join INDIVIDUAL IND on (IND.NAMENO = N.NAMENO)
						where N.NAMENO = TT.NAMENO 
						for XML PATH('Name'), TYPE
						)
		"


		Set @sSQLString3 = "	,			
					    (
					    Select -- <Address>
						null,
						(	
						Select --<FormattedAddress>
						    null,	
						    (		
						    Select  -- <AddressLines>
							TATN.SEQUENCENUMBER as 'AddressLine/@sequenceNumber', 
							TATN.ADDRESSLINE as 'AddressLine'
							from #TEMPNAMEADDRESS TNA
							join " + @sTokenisedAddressTableName  + " TATN on (TATN.ADDRESSCODE = TNA.ADDRESSCODE) 
							where TNA.BATCHNO = NAD.BATCHNO 
							and TNA.TRANSACTIONIDENTIFIER = NAD.TRANSACTIONIDENTIFIER
							ORDER BY TATN.SEQUENCENUMBER 
							for XML PATH(''), TYPE
						    ),
						    (
						    Select  -- <AddressCity><AddressState>	
							ADDR.CITY as 'AddressCity', 
							ADDR.STATE as 'AddressState', 
							ADDR.POSTCODE as 'AddressPostcode', 
							isnull(COU.ALTERNATECODE, COU.COUNTRYCODE) as 'AddressCountryCode'
							from #TEMPNAMEADDRESS TNA
							join ADDRESS ADDR on (ADDR.ADDRESSCODE = TNA.ADDRESSCODE)
							join COUNTRY COU on (COU.COUNTRYCODE = ADDR.COUNTRYCODE)
							where TNA.BATCHNO = NAD.BATCHNO 
							and TNA.TRANSACTIONIDENTIFIER = NAD.TRANSACTIONIDENTIFIER
							for XML PATH(''), TYPE
						    )
						    for XML PATH('FormattedAddress'), TYPE
						)
						for XML PATH('Address'), TYPE
					    )
			"


		Set @sSQLString4 = "	
					    for XML PATH('FormattedNameAddress'), TYPE
					)		
					for XML PATH('AddressBook'), TYPE
				    )	
				    from EDENAMEADDRESSDETAILS NAD 
				    join EDENAME EDEN on (EDEN.BATCHNO = NAD.BATCHNO and EDEN.TRANSACTIONIDENTIFIER = NAD.TRANSACTIONIDENTIFIER)
				    where NAD.BATCHNO = TB.BATCHNO 
				    and NAD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
				    for XML PATH('NameAddressDetails'), TYPE
				)
				for XML PATH ('TransactionData'), TYPE
			    )
			    for XML PATH ('TransactionContentDetails'), TYPE
			)
			from EDETRANSACTIONBODY TB
			where TB.BATCHNO = TT.BATCHNO
			and TB.TRANSACTIONIDENTIFIER = TT.TRANSACTIONIDENTIFIER
			for XML PATH(''), ROOT('TransactionBody')  
		    ) as XMLSTR
		    from #TEMPTRANSACTION TT
		    where TRANSACTIONTYPE  = 'PROCESSEDNAME'
		"

		If @nErrorCode = 0
		Begin
			exec(@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4)
			set @nErrorCode=@@error
		End

	end   /* Processed Name Transactions */




	-------------------------------------------------------------------------------------------------------
	-- Extract REJECTED NAME transactions data from EDE tables (i.e. sender original data)
	-------------------------------------------------------------------------------------------------------
	If (@nErrorCode = 0 and exists (Select * from #TEMPTRANSACTION where TRANSACTIONTYPE  = 'REJECTEDNAME'))
	Begin	
		If @bDebug = 1
			print ('create transaction body for REJECTED NAME.')

		Set @sSQLString1 = ""
		Set @sSQLString2 = ""
		Set @sSQLString3 = ""


		Set @sSQLString1 = "
		Insert into   "+ @sTempEPLTableName +"   (ROWID, XMLSTR)
		select 
		    TT.ROWID, 
		    (Select 		--<TransactionBody>
			(Select TT.TRANSACTIONIDENTIFIER) as 'TransactionIdentifier',
			(Select 
				top 1 TM.DESCRIPTION
				from TRANSACTIONMESSAGE TM
				join TRANSACTIONINFO TI on (TI.TRANSACTIONMESSAGENO = TM.TRANSACTIONMESSAGENO)
				where TI.BATCHNO = TB.BATCHNO
				and TI.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
				and TM.TRANSACTIONTYPE = 'N'
				order by TM.MESSAGEPRIORITY ASC
			) as 'TransactionReturnCode',
			(Select		-- <TransactionMessageDetails>
			    1 as '@sequentialNumber',	
			    TC.USERCODE as 'TransactionMessageCode', 
			    TC.DESCRIPTION as 'TransactionMessageText'
			    from EDETRANSACTIONBODY TB2
			    join TABLECODES TC on ( TC.TABLECODE = TB2.TRANSNARRATIVECODE AND TC.TABLETYPE = 402)
			    where TB2.BATCHNO =  TB.BATCHNO
			    and TB2.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			    and TB2.TRANSNARRATIVECODE  is not null
			    for XML PATH('TransactionMessageDetails'), TYPE 
			),
			(Select		-- <TransactionMessageDetails>
			    SI.ISSUECODE as 'TransactionMessageCode', 
			    SI.SHORTDESCRIPTION as 'TransactionMessageText'
			    from EDEOUTSTANDINGISSUES OI
			    join EDESTANDARDISSUE SI on (SI.ISSUEID = OI.ISSUEID)
			    where OI.BATCHNO =  TB.BATCHNO
			    and OI.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
			    for XML PATH('TransactionMessageDetails'), TYPE
			)
		"
		--
		Set @sSQLString2 = ",
			   ( 
			   Select    -- <TransactionContentDetails>
			      'Name Import Response' as 'TransactionCode', 
			      (
			      Select 	-- <TransactionData>
			         null,
			        (	
			        select 	-- <NameAddressDetails>
							NAD.NAMETYPECODE as 'NameTypeCode',
			            (
			            Select   --<AddressBook>
		                  null,
				            (
				            Select --<FormattedNameAddress>
		                     null, 
		                     (
		                     Select -- <Name>
		                        N.RECEIVERNAMEIDENTIFIER as 'SenderNameIdentifier', 
		                        N.SENDERNAMEIDENTIFIER as 'ReceiverNameIdentifier',
		                        FN.NAMEPREFIX as 'FormattedName/NamePrefix',
		                        FN.FIRSTNAME as 'FormattedName/FirstName',
		                        FN.MIDDLENAME as 'FormattedName/MiddleName',
		                        FN.LASTNAME as 'FormattedName/LastName',
		                        FN.GENDER as 'FormattedName/Gender',
		                        FN.INDIVIDUALIDENTIFIER as 'FormattedName/IndividualIdentifier',
		                        FN.ORGANIZATIONNAME as 'FormattedName/OrganizationName'
		                        from EDENAME N 
		                        left join EDEFORMATTEDNAME FN on (FN.BATCHNO = N.BATCHNO and FN.TRANSACTIONIDENTIFIER = N.TRANSACTIONIDENTIFIER and FN.NAMETYPECODE = N.NAMETYPECODE)
		                        where N.BATCHNO = NAD.BATCHNO 
		                        and N.TRANSACTIONIDENTIFIER = NAD.TRANSACTIONIDENTIFIER
		                        and N.NAMETYPECODE = NAD.NAMETYPECODE
		                        for XML PATH('Name'), TYPE
									),
									(
		                     Select -- <Address>
		                        null,
		                        (	
		                        Select --<FormattedAddress>
		                           null,	
		                           (		
		                           Select  -- <AddressLines>
		                              FA.SEQUENCENUMBER as 'AddressLine/@sequenceNumber', 
		                              FA.ADDRESSLINE as 'AddressLine'
		                              from EDEFORMATTEDADDRESS FA 
		                              where FA.BATCHNO = NAD.BATCHNO 
		                              and FA.TRANSACTIONIDENTIFIER = NAD.TRANSACTIONIDENTIFIER
		                              and FA.NAMETYPECODE = NAD.NAMETYPECODE
		                              and FA.SEQUENCENUMBER is not null
		                              for XML PATH(''), TYPE
		                           ),
		"
		Set @sSQLString3 = "
		                           (
		                           Select  -- <AddressCity><AddressState>	
		                              FA.ADDRESSCITY as 'AddressCity', 
		                              FA.ADDRESSSTATE as 'AddressState', 
		                              FA.ADDRESSPOSTCODE as 'AddressPostcode', 
					      COALESCE (COU.ALTERNATECODE, COU.COUNTRYCODE, FA.ADDRESSCOUNTRYCODE) as 'AddressCountryCode'
		                              from EDEFORMATTEDADDRESS FA 
					      left join COUNTRY COU on (COU.COUNTRYCODE = FA.ADDRESSCOUNTRYCODE)
		                              where FA.BATCHNO = NAD.BATCHNO 
		                              and FA.TRANSACTIONIDENTIFIER = NAD.TRANSACTIONIDENTIFIER
		                              and FA.NAMETYPECODE = NAD.NAMETYPECODE
		                              and FA.SEQUENCENUMBER is not null
		                              for XML PATH(''), TYPE
		                           )
		                           for XML PATH('FormattedAddress'), TYPE
		                        )
		                        for XML PATH('Address'), TYPE
		                     )
		                     for XML PATH('FormattedNameAddress'), TYPE
		                  )		
		                  for XML PATH('AddressBook'), TYPE
		               )	
		               from EDENAMEADDRESSDETAILS NAD 
		               where NAD.BATCHNO = TB.BATCHNO 
		               and NAD.TRANSACTIONIDENTIFIER = TB.TRANSACTIONIDENTIFIER
		               for XML PATH('NameAddressDetails'), TYPE
		            )
			    for XML PATH ('TransactionData'), TYPE
			)
			for XML PATH ('TransactionContentDetails'), TYPE
		    )
		    from EDETRANSACTIONBODY TB
		    where TB.BATCHNO = TT.BATCHNO
		    and TB.TRANSACTIONIDENTIFIER = TT.TRANSACTIONIDENTIFIER
		    for XML PATH(''), ROOT('TransactionBody')  
		) as XMLSTR
		from #TEMPTRANSACTION TT
		where TRANSACTIONTYPE  = 'REJECTEDNAME'
		"

		exec(@sSQLString1+@sSQLString2+@sSQLString3)
		set @nErrorCode=@@error

	end   /* Rejected Name Transactions */




	--Return XML BODY for all transactions types.  
	--Must order by ROWID to ensure transactions in XML are in the original order of the batch.
	If @nErrorCode = 0	
	Begin	
		-- separate transaction header and details
		Select char(13)+char(10)

		Set @sSQLString="
		Select CAST(XMLSTR as nvarchar(max)) + char(13)+char(10)
			from  "+ @sTempEPLTableName +"   
			order by ROWID
			"
		exec @nErrorCode=sp_executesql @sSQLString
	End
	

	-- Save the filename into ACTIVYTYREQUEST table to enable centura to save the file with the same name
	If @nErrorCode = 0 
	Begin
		-- Reset the locking level before updating database
		set transaction isolation level read committed
		
		BEGIN TRANSACTION	
		
		Set @sSQLString="
			Update ACTIVITYREQUEST
			set FILENAME = @sFileName
			where ACTIVITYID 	= @nActivityId
			and  SQLUSER 		= @sSQLUser
			"
		exec @nErrorCode=sp_executesql @sSQLString,
			N'	@sFileName		nvarchar(254),
				@nActivityId	int,
				@sSQLUser		nvarchar(40)',
				@sFileName		= @sFileName,
				@nActivityId	= @nActivityId,
				@sSQLUser		= @sSQLUser

		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End

/* NOTE: Moved to front end as xml string may not pass centura xml validation.
	-- update batch status if sucessful
	If @nErrorCode = 0 
	Begin
		Set @sSQLString="
			Update EDETRANSACTIONHEADER
			set BATCHSTATUS = 1282,
			DATEOUTPUTPRODUCED= GETDATE()  
			where BATCHNO = @nBatchNo
			"
		exec @nErrorCode=sp_executesql @sSQLString,
			N'	@nBatchNo int',
				@nBatchNo = @nBatchNo
	End
*/	

	If @bDebug = 1
		If @nErrorCode = 0
		Begin
			Print('XML SUCCESSFULLY GENERATED.')
			--rollback transaction
		End
		Else
			Print('XML GENERATION FAILED.')


	-- Drop global temporary table used
	if exists(select * from tempdb.dbo.sysobjects where name = @sCaseClassTableName)
	Begin
		Set @sSQLString = "drop table "+@sCaseClassTableName
		exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = @sTokenisedAddressTableName)
	Begin
		Set @sSQLString = "drop table "+@sTokenisedAddressTableName
		exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = @sTempEPLTableName)
	Begin
		Set @sSQLString = "drop table "+@sTempEPLTableName
		exec sp_executesql @sSQLString
	End

	if exists(select * from tempdb.dbo.sysobjects where name = '#BASIS_VIEW')
	Begin
	    Set @sSQLString = "drop table #BASIS_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#CASECATEGORY_VIEW')
	Begin
	    Set @sSQLString = "drop table #CASECATEGORY_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#CASETYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #CASETYPE_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#EVENT_VIEW')
	Begin
	    Set @sSQLString = "drop table #EVENT_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#NAMETYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #NAMETYPE_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#NUMBERTYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #NUMBERTYPE_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#PROPERTYTYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #PROPERTYTYPE_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#RELATIONSHIP_VIEW')
	Begin
	    Set @sSQLString = "drop table #RELATIONSHIP_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#SUBTYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #SUBTYPE_VIEW"
	    exec sp_executesql @sSQLString
	End
	if exists(select * from tempdb.dbo.sysobjects where name = '#TEXTTYPE_VIEW')
	Begin
	    Set @sSQLString = "drop table #TEXTTYPE_VIEW"
	    exec sp_executesql @sSQLString
	End



	RETURN @nErrorCode



GO


GRANT EXECUTE	 on  [dbo].[ede_GenerateEPL] 	TO PUBLIC

GO