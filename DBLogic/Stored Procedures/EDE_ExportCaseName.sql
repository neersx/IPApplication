-----------------------------------------------------------------------------------------------------------------------------
-- Creation of EDE_ExportCaseName
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[EDE_ExportCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.EDE_ExportCaseName.'
	Drop procedure [dbo].[EDE_ExportCaseName]
end
Print '**** Creating Stored Procedure dbo.EDE_ExportCaseName...'
Print ''
GO



SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/*
Usage:
	exec EDE_ExportCaseName @psFilePath = '<UNC EXPORT FILE PATH>'
	For example: exec EDE_ExportCaseName @psFilePath = '<\\aus-d-0011\Share\TEMP'

*/

CREATE  PROCEDURE [dbo].[EDE_ExportCaseName] 
		@pnExportType		smallint		= null,			-- null=export cases & names in the same file; 1=case only; 2=name only

		@psFilePath			nvarchar(200)	=null,			-- export file path.  Must be a shared UNC name as \\Server\share\path\.  e.g. \\aus-sqlvd01\temp\ it is required 

		@psCaseTable		nvarchar(128)	= null,			-- Table contains caseid to be exported.  Structure CASEID.  If null or table is empty, all cases will be exported.

		@pbCurrentCycleOnly	bit				= 0,			-- 1=Includes only the current cycle for cyclic events, else all cycles.

		@pbSuppressName		bit				= 0,			-- 1=Includes only name identifier information and suppress name and address details.

		@pbShowAllTelecom	bit				= 0,			-- 0=Shows the MAIN Phone/Fax/Email only.  1=Show ALL Phone/Fax/Email
		
		@psLoginId			nvarchar(60)	= null,			-- LoginId and password for use in the BCP command if not using Trusted connection.
		@psPassword			nvarchar(60)	= null,
		@pnCaseId	 		int				= null,			-- Contains comma separated case keys.		
		@pnBackgroundProcessId int			=null,			-- background process id 
		@pnExportRequestType		smallint		= 0
AS
-- PROCEDURE :	EDE_ExportCaseName
-- VERSION :	15
-- DESCRIPTION:	Extract specified cases and names into XML file in CPA-XML format
-- COPYRIGHT: 	CPA Software Solutions (Australia) Pty Limited
--
-- Usage:
-- exec EDE_ExportCaseName @psFilePath = '\\servername\share folder name'

--
-- MODIFICATIONS :
-- Date			Who		SQA#	Version	Change
-- ------------	-------	-----	-------	---------------------------------------------- 
-- 20/03/2013	DL		21277	1		Procedure created
-- 24/06/2013	SW		DR69	2		Added new input parameters @psCaseKeys for supporting comma seperated case key input,
--										@pbReturnXml for executing CPA-XML and modified sender details sql to return HOMENAMENO name code
--										if _H ALIAS type is not set in NAMEALIAS table.
-- 24/06/2013	SW		DR69	3		Modified the sender alias validation message.
-- 25/06/2013	AK		DR68	4		Added parameter and logic to run this sp in back ground
-- 25/06/2013	SW		DR69    5		Changed the implementation for usage of tokenization of comma seperated casekeys, instead of using an additional temp table	 
-- 26/06/2013	AK		DR68	6		modified to insert result set into table CPAXMLEXPORTRESULT
-- 08/07/2013   DV		DR68	7		Replaced parameters @psCaseKeys with parameter @pnCaseId for single Case.
-- 11/09/2014   AK		R38912	8		remove unwanted logic to display TransactionIdentifier and rename IdentifierIsCurrent and SenderInternalNameIdentifier.
-- 30/09/2014   AK		R38131	9		Moved the logic to top as data from global temp table @psCaseTable is getting lost.
-- 22/12/2014	SW		R42539	10		Used as alias when exporting cpa-xml from Case Details to make it consistent with bulk cpa-xml export from Case Search
-- 06/07/2014	DV		R42549	11		Add an extra parameter to specify the purpose of CPAXML
-- 11/01/2019	DL		DR-46493 12		Add Family and FamilyTitle to CaseDetails.
-- 10/09/2019	DL		DR-49262 13		Include goods/services text in CPA XML export
-- 24/12/2019	KT		DR-55247 14		Exclude Inherited names if @pnExportRequestType set to 1
-- 29/05/2020	vql		DR-58943 15		Ability to enter up to 3 characters for Number type code via client server

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF 


-- Temp table to hold cases for export
CREATE TABLE #TEMPCASES(
	ROWID		int identity(1,1),
	CASEID		int,
	STATUS		nvarchar(30) collate database_default,
	PROPERTYTYPE	nvarchar(1) collate database_default,
	COUNTRYCODE	nvarchar(3) collate database_default,
	ANNUITYTERM	int,
	ROWID2		int
	)
CREATE INDEX X1TEMPCASES ON #TEMPCASES
(
	CASEID
)
 
CREATE INDEX X2TEMPCASES ON #TEMPCASES
(
	ROWID
)

CREATE INDEX X3TEMPCASES ON #TEMPCASES
(
	PROPERTYTYPE, COUNTRYCODE
)
    

-- Temp table to hold names for export
CREATE TABLE #TEMPNAMES(
	ROWID		int identity(1,1),
	NAMENO		int
	)



-- Temp tables to copy data mappings from views.
-- The report query will use these tables instead of the views to enhance performance 
-- as the views are regenerated each time they are accessed. 
CREATE TABLE #BASIS_VIEW(BASIS_INPRO NVARCHAR(2) collate database_default, BASIS_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #CASECATEGORY_VIEW(CASECATEGORY_INPRO NVARCHAR(2) collate database_default, CASECATEGORY_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #CASETYPE_VIEW(CASETYPE_INPRO NCHAR(1) collate database_default, CASETYPE_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #EVENT_VIEW(EVENT_INPRO INT, EVENT_CPAXML NVARCHAR(50) collate database_default)
CREATE INDEX X1EVENT_VIEW ON #EVENT_VIEW(EVENT_INPRO)
CREATE INDEX X2EVENT_VIEW ON #EVENT_VIEW(EVENT_CPAXML)
CREATE TABLE #NAMETYPE_VIEW(NAMETYPE_INPRO NVARCHAR(3) collate database_default, NAMETYPE_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #NUMBERTYPE_VIEW(NUMBERTYPE_INPRO NVARCHAR(3) collate database_default, NUMBERTYPE_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #PROPERTYTYPE_VIEW(PROPERTYTYPE_INPRO NCHAR(1) collate database_default, PROPERTYTYPE_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #RELATIONSHIP_VIEW(RELATIONSHIP_INPRO NVARCHAR(3) collate database_default, RELATIONSHIP_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #SUBTYPE_VIEW(SUBTYPE_INPRO NVARCHAR(2) collate database_default, SUBTYPE_CPAXML NVARCHAR(50) collate database_default)
CREATE TABLE #TEXTTYPE_VIEW(TEXTTYPE_INPRO NVARCHAR(2) collate database_default, TEXTTYPE_CPAXML NVARCHAR(50) collate database_default)

CREATE TABLE #SiteCtrlClientTextType(Parameter NVARCHAR(255) collate database_default)
CREATE TABLE #SiteCtrlNameTypes(Parameter NVARCHAR(255) collate database_default)

-- SQA17676  precalculate the event cycle for each case event
CREATE TABLE #CASEEVENTCYCLE(CASEID INT, EVENTNO INT, CYCLE INT)
CREATE INDEX X1CASEEVENTCYCLE ON #CASEEVENTCYCLE
(
	CASEID, EVENTNO, CYCLE
)

Declare	
	@dCurrentDateTime 				datetime,
	@sSenderRequestIdentifier		nvarchar(14),
	@sSenderProducedDateTime		nvarchar(22),
	@sSender						nvarchar(30),
	@sReceiver						nvarchar(30),
  	@nCPASchemaId					int,
	@nInproSchemaId					int,
	@sStructureTableName  			nvarchar(50),
	@sInputCode						nvarchar(50),
	@sDataInstructorCode			nvarchar(50),
	@sNumberTypeFileNumber			nvarchar(50),
	@sEventNoChangeOfResponsibility nvarchar(50),
	@sOldDataInstructorCode 		nvarchar(3),

	@sSiteCtrlClientTextType 		nvarchar(254),
	@sSiteCtrlNameTypes 			nvarchar(254),

	@sTempTableCaseClass			nvarchar(100),
	@sCaseAndNameXML			nvarchar(100),
	@sTokenisedAddressTableName 	nvarchar(100),

	@sSQLString 					nvarchar(4000),
	@sSQLString1 					nvarchar(4000),
	@sSQLString2 					nvarchar(4000),
	@sSQLString3 					nvarchar(4000),
	@sSQLString4 					nvarchar(4000),
	@sSQLString4A 					nvarchar(4000),
	@sSQLString5 					nvarchar(4000),
	@sSQLString5A 					nvarchar(4000),
	@sSQLString6 					nvarchar(4000),
	@sSQLString7 					nvarchar(4000),
	@sSQLString8 					nvarchar(4000),
	@sSQLString9 					nvarchar(4000),
	@sSQLString10 					nvarchar(4000),
	@sSQLString11					nvarchar(4000),
	@sSQLString12 					nvarchar(4000),
	@sSQLString12A 					nvarchar(4000),
	@sSQLString13 					nvarchar(4000),
	@sSQLStringLast					nvarchar(4000),
	@bDebug							bit,
	@sAlertXML						nvarchar(250),
	@nErrorCode 					int,

	@sSQLStringFilter				nvarchar (1000),
	@nLastFromRowId					int,
	@nNumberOfCases					int,
	@nNumberOfNames					int,
	@nClientImportance				int,
	@sSQLTemp						nvarchar (1000),
	@sExcludeInheritedName			nvarchar(1000),
	@sSQLStringNameLong				nvarchar(max),
	@sSQLStringNameShort			nvarchar(max),
	@sXMLResult						nvarchar(max),
	@sFileName						varchar(254),
	@sErrorMessage					nvarchar(254),
	@sSenderRequestType				nvarchar(100)
					

Set @nErrorCode = 0
set @bDebug = 0						-- Set to 1 to debug.

If @pnExportType not in (1,2) 
	set @pnExportType = NULL
If @pnExportRequestType not in (0,1) 
	set @pnExportRequestType = 0

Set @sSenderRequestType = 'Data Export' 
If @pnExportRequestType = 1
	set @sSenderRequestType = 'Case Import'

-- Use the lowest level of locks on the database
set transaction isolation level read uncommitted

-- Validate output path
if @psFilePath is not null 
Begin
	Set @sSQLString = 'dir ' + @psFilePath
	Exec @nErrorCode = master..xp_cmdshell @sSQLString, no_output

	If (@nErrorCode <> 15153 and @nErrorCode <> 15121 and @nErrorCode <> 0) 
	Begin	
		RAISERROR('Invalid output path or user does not have access to the folder.  The output path should be a shared folder in UNC format as \\Server\share\path\.  e.g \\sqlsvr1\temp\xmlreport\ ', 16, 1)
	End
End

--Ensure the Sender exists
If @nErrorCode = 0	
Begin	
    -- Get Sender against HOME NAME CODE 
    Set @sSQLString="
    Select @sSender = ISNULL(NA.ALIAS,N.NAMECODE) 
    from SITECONTROL SC
    left join NAMEALIAS NA	on (NA.NAMENO=SC.COLINTEGER
			and NA.ALIASTYPE='_H'
			and NA.COUNTRYCODE  is null
			and NA.PROPERTYTYPE is null)
	left join NAME N on (SC.COLINTEGER = N.NAMENO)
    where SC.CONTROLID = 'HOMENAMENO'"

    exec @nErrorCode=sp_executesql @sSQLString,
		    N'@sSender		nvarchar(30)	OUTPUT',
		      @sSender		= @sSender	OUTPUT

    If @nErrorCode = 0 and @sSender is null
    Begin
		Set @sAlertXML = dbo.fn_GetAlertXML("ed11", "There is no valid sender alias or name code against the HOME NAME. Please set up alias of type _H or the Name code against the HOME NAME.", null, null, null, null, null)
		RAISERROR(@sAlertXML, 16, 1)
		Set @nErrorCode = @@ERROR
    End
End


If @nErrorCode = 0	
Begin	
	Select @nClientImportance = COLINTEGER
	from SITECONTROL 
	where CONTROLID = 'Client Importance'
	set @nErrorCode = @@ERROR
End

----------------------------------------------------------------------------------------------------------
-- Determine which cases to include the export file
----------------------------------------------------------------------------------------------------------
If @nErrorCode = 0 
Begin	
	Set @nNumberOfCases = 0
	
	If @psCaseTable is not null 
	Begin
		Set @sSQLString="select @nNumberOfCases = count(*) from " + 	@psCaseTable
		exec @nErrorCode=sp_executesql @sSQLString, 
						N'@nNumberOfCases	int output',
						@nNumberOfCases = @nNumberOfCases output
	End	

	If @psCaseTable is not null and @nNumberOfCases > 0
	Begin
		-- Export only the specified cases
		Set @sSQLString="
		Insert into #TEMPCASES (CASEID, PROPERTYTYPE, COUNTRYCODE)
		Select  distinct C.CASEID, C.PROPERTYTYPE, C.COUNTRYCODE
		from  " + @psCaseTable + " T 
		join CASES C on (C.CASEID = T.CASEID)"		
	End
	Else If @pnCaseId is not null
	Begin
		-- Export only the specified cases using fn_Tokenise
		Set @sSQLString="
		Insert into #TEMPCASES (CASEID, PROPERTYTYPE, COUNTRYCODE)
		Select  distinct C.CASEID, C.PROPERTYTYPE, C.COUNTRYCODE
		FROM CASES C where C.CASEID = " + Convert(nvarchar(11),@pnCaseId) 		
	End  

	Else
	Begin
		-- Export all cases
		Set @sSQLString="
		Insert into #TEMPCASES (CASEID, PROPERTYTYPE, COUNTRYCODE)
		Select  distinct C.CASEID, C.PROPERTYTYPE, C.COUNTRYCODE
		from  CASES C"		
	End	

	exec @nErrorCode=sp_executesql @sSQLString
	Set @nNumberOfCases = 	@@ROWCOUNT

	set @nNumberOfNames = 0
	
	-- Get distinct case names from the selected cases.
	If @nErrorCode = 0 and ( @pnExportType is null or @pnExportType = 2)
	Begin
		
		Set @sSQLString="
		Insert into #TEMPNAMES (NAMENO)
		Select  distinct CN.NAMENO
		from  #TEMPCASES TC
		JOIN CASENAME CN ON CN.CASEID = TC.CASEID"

		IF @pnExportRequestType = 1
		BEGIN
			Set @sSQLString= @sSQLString + " AND isnull(CN.INHERITED, 0) <> 1"
		END

		exec @nErrorCode=sp_executesql @sSQLString

		set @nNumberOfNames = 	@@ROWCOUNT
	End

	-- Increament ROWIDE in the tempcases table as it is used as <TransactionIdentifier>
	If @nErrorCode = 0 and (@pnExportType is null or  @pnExportType=1)
	Begin
		Update #TEMPCASES
			set ROWID2 = ROWID + @nNumberOfNames
			
		set @nErrorCode = @@error
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

-- Create a temp table to hold XML transaction body data for cases so that each case can be separated by a line break.
If @nErrorCode = 0	
Begin
    -- Generate a unique table name from the newid() 
    Set @sSQLString="Select @sCaseAndNameXML = '##' + replace(newid(),'-','_')"
    exec @nErrorCode=sp_executesql @sSQLString,
	    N'@sCaseAndNameXML nvarchar(100) OUTPUT',
	    @sCaseAndNameXML = @sCaseAndNameXML OUTPUT

    Set @sSQLString="
		    CREATE TABLE "+ @sCaseAndNameXML +" (
			    ROWID	int identity(1,1),
			    XMLSTR	nvarchar(max)
			    )"
    exec @nErrorCode=sp_executesql @sSQLString
End

-- Calculate the current cycle for each case event 
-- only do this if the export type is Case & Name or Case only
If @nErrorCode=0 and (@pnExportType is null or @pnExportType = 1)
Begin
	Set @sSQLString="
	Insert into  #CASEEVENTCYCLE (CASEID, EVENTNO, CYCLE) 
	select -- single cycle event
	CE.CASEID, CE.EVENTNO, CE.CYCLE
	from #TEMPCASES TC 
	Join CASEEVENT CE on CE.CASEID = TC.CASEID
	Join #EVENT_VIEW EV on EV.EVENT_INPRO = CE.EVENTNO
	join (	select CE2.CASEID, CE2.EVENTNO
		from #TEMPCASES TC2
		Join CASEEVENT CE2 on CE2.CASEID = TC2.CASEID
		Join #EVENT_VIEW EV on EV.EVENT_INPRO = CE2.EVENTNO
		group by CE2.CASEID, CE2.EVENTNO
		having COUNT(*) = 1) CE3 on (CE3.CASEID = CE.CASEID AND  CE3.EVENTNO = CE.EVENTNO)
	union 
	select -- events with multiple cycles
	distinct CE.CASEID, CE.EVENTNO, CE.CYCLE
	from #TEMPCASES TC 
	Join CASEEVENT CE on CE.CASEID = TC.CASEID
	Join #EVENT_VIEW EV on EV.EVENT_INPRO = CE.EVENTNO
	join (select CE2.CASEID, CE2.EVENTNO
		from #TEMPCASES TC2
		Join CASEEVENT CE2 on CE2.CASEID = TC2.CASEID
		Join #EVENT_VIEW EV on EV.EVENT_INPRO = CE2.EVENTNO
		group by CE2.CASEID, CE2.EVENTNO
		having COUNT(*) > 1) CE3 on (CE3.CASEID = CE.CASEID AND  CE3.EVENTNO = CE.EVENTNO)
	join(	select O.CASEID, O.ACTION, O.CRITERIANO, min(O.CYCLE) as CYCLE
		from OPENACTION O
		Join #TEMPCASES TC2 on TC2.CASEID = O.CASEID
		where POLICEEVENTS=1
		group by O.CASEID, O.ACTION, O.CRITERIANO) OA 
				on (OA.CASEID=CE.CASEID
				and OA.ACTION=isnull(CE.CREATEDBYACTION, OA.ACTION))
	join EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO
			     and EC.EVENTNO=CE.EVENTNO)
	join ACTIONS A on (A.ACTION=OA.ACTION)
	where CE.OCCURREDFLAG<9
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
			END -- end case"

	Exec @nErrorCode=sp_executesql @sSQLString	
End


-------------------------------------------------------------------------------------------------------
-- Export file HEADER
-------------------------------------------------------------------------------------------------------
If @nErrorCode = 0
Begin
    -- Get timestamp
    Select @dCurrentDateTime = getdate()

    -- Get @sSenderRequestIdentifier as Timestamp in format CCYYMMDDHHMMSS.   (e.g. file name)
    -- and @sSenderProducedDateTime as Timestamp in format CCYY-MM-DDTHH:MM:SS.0Z  (.0Z is zero not letter O) 
    Set  @sSenderRequestIdentifier = RTRIM( CONVERT(char(4), year(@dCurrentDateTime))) 
    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dCurrentDateTime)))) + CONVERT(char(2), month(@dCurrentDateTime)))
    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dCurrentDateTime)))) + CONVERT(char(2), day(@dCurrentDateTime)))
    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dCurrentDateTime)))) + CONVERT(char(2), datepart(hh,@dCurrentDateTime)))
    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dCurrentDateTime)))) + CONVERT(char(2), datepart(mi,@dCurrentDateTime)))
    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dCurrentDateTime)))) + CONVERT(char(2), datepart(ss,@dCurrentDateTime))) 
	
    Set @sSenderProducedDateTime = RTRIM( CONVERT(char(4), year(@dCurrentDateTime))) + '-' +
    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), month(@dCurrentDateTime)))) + CONVERT(char(2), month(@dCurrentDateTime))) + '-' +
    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), day(@dCurrentDateTime)))) + CONVERT(char(2), day(@dCurrentDateTime))) + 'T' +
    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(hh, @dCurrentDateTime)))) + CONVERT(char(2), datepart(hh,@dCurrentDateTime))) + ':' +
    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(mi, @dCurrentDateTime)))) + CONVERT(char(2), datepart(mi,@dCurrentDateTime))) + ':' +
    + RTRIM( REPLICATE ('0', 2-LEN( CONVERT(char(2), datepart(ss, @dCurrentDateTime)))) + CONVERT(char(2), datepart(ss,@dCurrentDateTime))) + '.0Z' 

	If @psFilePath is not null
	Begin
		-- Output file will be called ‘Data Export ~ CCYYMMDDHHMMSS’or ‘Data Import ~ CCYYMMDDHHMMSS’, where CCYYMMDDHHMMSS is a date& time stamp.
		If right(@psFilePath, 1) = '\'
			set @psFilePath = @psFilePath + @sSenderRequestType + ' ~ ' + @sSenderRequestIdentifier + '.XML'
		else		
			set @psFilePath = @psFilePath + '\' + @sSenderRequestType + ' ~ ' + @sSenderRequestIdentifier + '.XML'
	End
	-- RFC9683 exclude time component for export type.
	set @sSenderProducedDateTime = left(@sSenderProducedDateTime, 10)
		

	-- NOTE:	The BCP command will be used for exporting data in XML to file.  BCP can only export the first result set to file.  
	--			Therefore export data will be added to a temp table in nvarchar(max) column.  We then select data from this table for export via BCP.
	--			This way there will be only one result set. 

	-- Add XML declaration and header element <Transaction>
	Set @sSQLString = "
		Insert into "+ @sCaseAndNameXML +" (XMLSTR) values ('<?xml version=""1.0""?>') "
	Set @sSQLString = @sSQLString  + "
		Insert into "+ @sCaseAndNameXML +" (XMLSTR) values (" + char(13)+char(10)+ "'<Transaction>') "
    exec(@sSQLString)
    set @nErrorCode=@@error


	If @nErrorCode = 0
	Begin		
		-- Create <TransactionHeader>
		Set @sSQLString = "
			Insert into "+ @sCaseAndNameXML +" ( XMLSTR)
			Select cast(
				(Select 
					(Select  -- Transaction header
					'" + @sSenderRequestType + "' as 'SenderRequestType',
					'"+ @sSenderRequestIdentifier +"' as 'SenderRequestIdentifier',
					'"+ @sSender +"' as 'Sender',
					'1.4' as 'SenderXSDVersion',
					(Select 
						'CPA Inprotech' as 'SenderSoftwareName',
						SC.COLCHARACTER as 'SenderSoftwareVersion'
						from SITECONTROL SC WHERE CONTROLID = 'DB Release Version' 
						for XML PATH('SenderSoftware'), TYPE
					),
					'" + @sSenderRequestType + " ~ ' +  '" + @sSenderRequestIdentifier + ".XML'  as 'SenderFilename', 
					
					'"+ @sSenderProducedDateTime +"' as 'SenderProducedDate' 
					for XML PATH('SenderDetails'), TYPE
					)
				for XML PATH('TransactionHeader'), TYPE)
				as nvarchar(max) )
			"
		If @bDebug = 1
			print 'transaction header SQL = ' + @sSQLString

		exec(@sSQLString)
		set @nErrorCode=@@error
	End		
End


-------------------------------------------------------------------------------------------------------
-- Prepare SQL for export file BODY
-------------------------------------------------------------------------------------------------------
If @nErrorCode = 0
Begin	

	If @bDebug = 1
		print 'create body.' 


	-----------------------------------------------------------------------------------------------
	-- Prepare data for main SQL which generates the XML
	-----------------------------------------------------------------------------------------------

	set @nCPASchemaId = -3
	set @nInproSchemaId = -1

	-- Get Inprotech Data Instructor code from CPAINPRO STANDARD MAPPING.
	Set @sSQLString = "Select @sDataInstructorCode = EV.CODE 
		from ENCODEDVALUE EV
		join MAPSTRUCTURE MS on MS.STRUCTUREID = EV.STRUCTUREID
		where MS.TABLENAME = 'NAMETYPE'
		and EV.SCHEMEID = @nInproSchemaId 
		and EV.DESCRIPTION = 'DATA INSTRUCTOR'"
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nInproSchemaId			int,
		  @sDataInstructorCode	nvarchar(50) output',
		  @nInproSchemaId			= @nInproSchemaId,
		  @sDataInstructorCode	= @sDataInstructorCode output


	-- Get the Old Data Instructor
	If @nErrorCode = 0
	Begin		
		Set @sSQLString = "Select @sOldDataInstructorCode = OLDNAMETYPE 
				from NAMETYPE  
				where UPPER(NAMETYPE) = UPPER(@sDataInstructorCode)"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@sDataInstructorCode	nvarchar(3),
			  @sOldDataInstructorCode nvarchar(3) output',
			  @sDataInstructorCode = @sDataInstructorCode,
			  @sOldDataInstructorCode	= @sOldDataInstructorCode output
	End



	-- Get Inprotech Official Number code for 'FILE NUMBER' from CPAINPRO STANDARD MAPPING.  
	If @nErrorCode = 0
	Begin	
		Set @sSQLString = "Select @sNumberTypeFileNumber = NUMBERTYPE_INPRO
			from #NUMBERTYPE_VIEW 
			where NUMBERTYPE_CPAXML = 'File Number'"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@sNumberTypeFileNumber	nvarchar(50) output',
			  @sNumberTypeFileNumber	= @sNumberTypeFileNumber output
	End


	-- Get Inprotech EVENTNO for EVENT 'CHANGE OF RESPONSIBILITY' from CPAINPRO STANDARD MAPPING.
	If @nErrorCode = 0
	Begin	
		Set @sSQLString = "Select @sEventNoChangeOfResponsibility = EV.EVENT_INPRO
			from #EVENT_VIEW EV
			where EV.EVENT_CPAXML = 'Change of Responsibility'"
		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@sEventNoChangeOfResponsibility	nvarchar(50) output',
			  @sEventNoChangeOfResponsibility	= @sEventNoChangeOfResponsibility output
	End


	--Get site control which determine what data can be extracted.
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


	-- create temp tables for parsing casename addresses
	If @nErrorCode = 0
	Begin
		-- temp table to hold case name address code
		Create table #TEMPCASENAMEADDRESS (
					CASEID		int,
					NAMENO		int,
					NAMETYPE	nvarchar(3) collate database_default,
					SEQUENCE	int,
					ADDRESSCODE	int, 
					POSTALADDRESSCODE	int
					)
		CREATE INDEX X1TEMPCASENAMEADDRESS ON #TEMPCASENAMEADDRESS
		(
			CASEID
		)
		CREATE INDEX X2TEMPCASENAMEADDRESS ON #TEMPCASENAMEADDRESS
		(
			ADDRESSCODE
		)
	
		CREATE INDEX X3TEMPCASENAMEADDRESS ON #TEMPCASENAMEADDRESS
		(
			POSTALADDRESSCODE
		)

		-- Create a temp table to hold the names ADDRESS.STREET1
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

		-- Create a temp table for holding the case classes.
		-- Get a unique table name
		Set @sSQLString="Select @sTempTableCaseClass = '##' + replace(newid(),'-','_')"
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@sTempTableCaseClass nvarchar(100) OUTPUT',
			@sTempTableCaseClass = @sTempTableCaseClass OUTPUT

		-- and create the table	
		If @nErrorCode = 0
		Begin
			Set @sSQLString="
			Create table " + @sTempTableCaseClass +" (
						CASEID		int,
						CLASSTYPE	nvarchar(3) collate database_default,
						CLASS		nvarchar(250) collate database_default,
						SEQUENCENO	int
						)"
			Exec @nErrorCode=sp_executesql @sSQLString

			If @nErrorCode = 0
			Begin
				Set @sSQLString="
				CREATE INDEX X1TempTableCaseClass ON " + @sTempTableCaseClass + " 
				(
					CASEID
				) "
				Exec @nErrorCode=sp_executesql @sSQLString
			End
		End
	End



	-- Tokenised case name ADDRESS.STREET1 separated by carriage return character
	-- Don't parse addesses if export type is cases only (@pnExportType = 1) and Suppress name details option is on (@pbSuppressName = 1)  
	If @nErrorCode = 0 and NOT ( isnull(@pnExportType, 0) = 1 and @pbSuppressName = 1)
	Begin
		-- List of case name addresses
		-- Rules: Use CASENAME.ADDRESSCODE if it exists, otherwise use default Street address
		-- if name type is Owner or Inventor, otherwise assume is postal address for other name types.
		Set @sSQLString="
			Insert into #TEMPCASENAMEADDRESS ( CASEID, NAMENO, NAMETYPE, SEQUENCE, ADDRESSCODE, POSTALADDRESSCODE)
			Select CN.CASEID, CN.NAMENO, CN.NAMETYPE, CN.SEQUENCE,
				Case 	when (CN.ADDRESSCODE is not null) then CN.ADDRESSCODE
					when (CN.NAMETYPE in ('O','J')  ) then N.STREETADDRESS
										else N.POSTALADDRESS
				end as ADDRESSCODE,
				ISNULL(N.POSTALADDRESS, N.STREETADDRESS)
			from #TEMPCASES TC
			join CASENAME CN on (CN.CASEID = TC.CASEID)"
		IF @pnExportRequestType = 1
		BEGIN
			Set @sSQLString=@sSQLString + " and isnull(CN.INHERITED, 0) <> 1  
				join NAME N      on (N.NAMENO = CN.NAMENO)"
		END
		ELSE
		BEGIN
			Set @sSQLString=@sSQLString + " 
				join NAME N      on (N.NAMENO = CN.NAMENO)"
		END
			
		if @bDebug = 1
			print @sSQLString
		exec @nErrorCode=sp_executesql @sSQLString
			


		-- Load distinct address codes for parsing
		If @nErrorCode = 0
		Begin
			Set @sSQLString="
				Insert into "+ @sTokenisedAddressTableName +"( ADDRESSCODE)
				Select distinct ADDRESSCODE
				from #TEMPCASENAMEADDRESS			"
			exec 	@nErrorCode=sp_executesql @sSQLString
		End

		-- Load POSTAL address for the Names export
		If @nErrorCode = 0
		Begin
			Set @sSQLString="
				Insert into "+ @sTokenisedAddressTableName +"( ADDRESSCODE)
				Select distinct T.POSTALADDRESSCODE
				from #TEMPCASENAMEADDRESS T			
				where not exists
					(select ADDRESSCODE 
					from "+ @sTokenisedAddressTableName +" T2
					where T2.ADDRESSCODE = T.POSTALADDRESSCODE)"
					
			exec 	@nErrorCode=sp_executesql @sSQLString
		End


		-- And tokenise case name ADDRESS.STREET1 into multiple lines
		If @nErrorCode = 0
		Begin
			Exec @nErrorCode=ede_TokeniseAddressLine @sTokenisedAddressTableName	
		End
	End




	-- Case classes are stored in CASES.LOCALCLASSES with commas delimited.
	-- We need to tokenise case classes into individual field for display
	-- only do this if the export includes cases
	If @nErrorCode = 0 and ( @pnExportType is null or @pnExportType = 1)
	Begin
		-- load draft and live cases id into table for parsing case classes
		Set @sSQLString = "Insert into "+ @sTempTableCaseClass +" (CASEID) 
				Select distinct CASEID 
				from #TEMPCASES"
		Exec @nErrorCode=sp_executesql @sSQLString

		If @nErrorCode = 0
		Begin
			Exec @nErrorCode=ede_TokeniseCaseClass @sTempTableCaseClass	
		End
	End

	-----------------------------------------------------------------------------------------------
	-- SQL to generate CPA-XML for case names from the selected cases 
	-----------------------------------------------------------------------------------------------

	If @pnExportType is null or @pnExportType = 2
	Begin	
		Set @sSQLString1 = ""
		Set @sSQLString2 = ""
		Set @sSQLString3 = ""
		Set @sSQLString4 = ""
		Set @sSQLString5 = ""
		Set @sSQLString6 = ""
		Set @sSQLString7 = ""


		Set @sSQLString1 = "
			Insert into "+ @sCaseAndNameXML +" ( XMLSTR)
			Select 
			(
			Select 	-- <TransactionBody>
				CN.ROWID  as 'TransactionIdentifier',
				(
				Select 	 -- <TransactionContentDetails>
					'Name Export' as 'TransactionCode'"

		Set @sSQLString2 = ",
					(
					Select 	-- <TransactionData>
						null,
						(	
						select 	-- <NameAddressDetails>
							(Select CURRENCY from IPNAME IPN where IPN.NAMENO = CN.NAMENO) as 'NameCurrencyCode',
							(
							Select   --<AddressBook>
							null,
							(
								Select --<FormattedNameAddress>
								null, 
								(
								Select -- <Name>
									N.NAMECODE as 'SenderNameIdentifier', 
									N.NAMENO as 'SenderNameInternalIdentifier', "


		Set @sSQLString3 = "
            						N.TITLE as 'FormattedName/NamePrefix',

									-- NAME.USEDASFLAG & 1 = 1 is Individual, else Organization.
									Case when ( (N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)=0)) then
										N.FIRSTNAME
									when ( (N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)>0)) then
										left (N.FIRSTNAME, charindex(' ', N.FIRSTNAME))
									end as 'FormattedName/FirstName',
									-- sqa20161 fix error if FIRSTNAME contains trailing spaces
									Case when ((N.USEDASFLAG & 1 = 1) and (charindex(' ', LTRIM(RTRIM(N.FIRSTNAME)))>0)) then
										right (LTRIM(RTRIM(N.FIRSTNAME)), len(LTRIM(RTRIM(N.FIRSTNAME))) - charindex(' ', LTRIM(RTRIM(N.FIRSTNAME))))  
									end as 'FormattedName/MiddleName',

									Case when (N.USEDASFLAG & 1 = 1) then
                								dbo.fn_SplitText(N.NAME, ' ', 1, 1)
									end as 'FormattedName/LastName',

									Case when (N.USEDASFLAG & 1 = 1) then
									dbo.fn_SplitText(N.NAME, ' ', 2, 2) 
									end as 'FormattedName/SecondLastName',  

									Case when (N.USEDASFLAG & 1 = 1) then
									dbo.fn_SplitText(N.NAME, ' ', 3, 1) 
									end as 'FormattedName/NameSuffix', 			

									Case IND.SEX 
									when  'M' then 'Male' 
									when  'F' then 'Female' 
									end as 'FormattedName/Gender',

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


		Set @sSQLString4 = "		,			
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
									  join " + @sTokenisedAddressTableName  + " TATN on (TATN.ADDRESSCODE = TCNA.POSTALADDRESSCODE) 
									  where TCNA.NAMENO = CN.NAMENO
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
									  join ADDRESS ADDR on (ADDR.ADDRESSCODE = TCNA.POSTALADDRESSCODE)
									  join COUNTRY COU on (COU.COUNTRYCODE = ADDR.COUNTRYCODE)
									  where TCNA.NAMENO = CN.NAMENO
									  for XML PATH(''), TYPE
									   )
									   for XML PATH('FormattedAddress'), TYPE
									)
									for XML PATH('Address'), TYPE
								)
		"

		-- For name export can only extract the NAME.MAINCONTACT for AttentionOf.
		Set @sSQLString5 = "		,			
								(
								Select -- <AttentionOf>
									N.TITLE as 'FormattedAttentionOf/NamePrefix',  
									N.FIRSTNAME as 'FormattedAttentionOf/FirstName', 
									N.NAME as 'FormattedAttentionOf/LastName'
									from NAME N 
									where N.NAMENO = (
										Select  MAINCONTACT.MAINCONTACT AS NAMENO
										from NAME MAINCONTACT 
										where MAINCONTACT.NAMENO = CN.NAMENO
										)
									for XML PATH('AttentionOf'), TYPE
								)		
								for XML PATH('FormattedNameAddress'), TYPE
								)  -- <FormattedNameAddress>
						"

		-- Show all Phone/Fax/Email?
		If @pbShowAllTelecom = 1
			Set @sSQLTemp = ''
		Else
			-- extract only the MAIN Phone/Fax/Email
			Set @sSQLTemp = ' and 1 = 0 '   -- forcing a false condition so that only the main phone/fax/mail will be reported

		Set @sSQLString6 = "	,	
							(
							Select -- <ContactInformationDetails>
							(Select 
								SORTORDER as 'Phone/@sequenceNumber',
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
								where N.NAMENO = CN.NAMENO " + @sSQLTemp + " 
								and TEL.TELECOMTYPE = 1901
								) temp
								order by SORTORDER
								for XML PATH(''), TYPE
							),										
		                                            	
							(Select 
								SORTORDER as 'Fax/@sequenceNumber',
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
								where N.NAMENO = CN.NAMENO " + @sSQLTemp + " 
								and TEL.TELECOMTYPE = 1902
								) temp
								order by SORTORDER
								for XML PATH(''), TYPE
							), 
		                                            	
							(Select 
								SORTORDER as 'Email/@sequenceNumber',
								EMAIL as 'Email'
								from
								(Select 1 as SORTORDER, dbo.fn_FormatTelecom(1903, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'EMAIL'
								from NAME N
								join TELECOMMUNICATION TEL on (TEL.TELECODE = N.MAINEMAIL)
								where NAMENO = CN.NAMENO
								UNION
								Select ROW_NUMBER() OVER (order by N.NAMENO ) + 1 as SORTORDER,  dbo.fn_FormatTelecom(1903, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'EMAIL'
								from NAME N
								join NAMETELECOM NTEL on (NTEL.NAMENO = N.NAMENO and NTEL.TELECODE != N.MAINEMAIL)
								join TELECOMMUNICATION TEL on (TEL.TELECODE = NTEL.TELECODE)
								where N.NAMENO = CN.NAMENO " + @sSQLTemp + " 
								and TEL.TELECOMTYPE = 1903
								) temp
								order by SORTORDER
								for XML PATH(''), TYPE
							) 
							for XML PATH('ContactInformationDetails'), TYPE
							)		
		"



		Set @sSQLString7 = "	
							for XML PATH('AddressBook'), TYPE
						)	-- <AddressBook>
						for XML PATH('NameAddressDetails'), TYPE
						) -- <NameAddressDetails>
					for XML PATH('TransactionData'), TYPE
					) 	-- end <TransactionData>
					for XML PATH('TransactionContentDetails'), TYPE
					)	-- end <TransactionContentDetails>
				for XML PATH(''), ROOT('TransactionBody') 
				) as XMLSTR     -- end <TransactionBody>

				from #TEMPNAMES CN
		"


		If @bDebug = 1
		Begin		
			PRINT 'Name SQL:'
			PRINT /*--1--*/ + @sSQLString1
			PRINT /*--2--*/ + @sSQLString2
			PRINT /*--3--*/ + @sSQLString3
			PRINT /*--4--*/ + @sSQLString4
			PRINT /*--5--*/ + @sSQLString5
			PRINT /*--6--*/ + @sSQLString6
			PRINT /*--7--*/ + @sSQLString7
		End


		-- sqa17676  extracting 1000 rows at a time seems to improve performance
		set @nLastFromRowId = 0
		While @nErrorCode = 0 
		and @nLastFromRowId <= @nNumberOfNames
		Begin
			set @sSQLStringFilter = " WHERE CN.ROWID >= " + CAST(@nLastFromRowId as nvarchar(10)) + 
									" and CN.ROWID < " + CAST(@nLastFromRowId + 1000 as nvarchar(10) )

			If @bDebug = 1
				print /*--filter--*/ @sSQLStringFilter

			exec(@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString5+@sSQLString6+@sSQLString7+@sSQLStringFilter)
			set @nErrorCode=@@error
				
			set @nLastFromRowId = @nLastFromRowId + 1000

			If @bDebug = 1
				PRINT 'inserted next 1000 rows into XML BODY'
		End
	End		/* export names -- If @pnExportType is null or @pnExportType = 2 */
	





	-----------------------------------------------------------------------------------------------
	-- SQL to generate cases & casenames in CPA-XML format
	-----------------------------------------------------------------------------------------------

	If @pnExportType is null or @pnExportType = 1
	Begin	
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
		Set @sSQLString12A = ""
		Set @sSQLString13 = ""
		Set @sSQLStringLast = ""

		Set @sSQLString1 = "
			Insert into "+ @sCaseAndNameXML +" ( XMLSTR)
			Select 
			(
			Select 	-- <TransactionBody>
				TC.ROWID2  as 'TransactionIdentifier',
				(
				Select 	 -- <TransactionContentDetails>
					'" + case when @pnExportRequestType = 0 then 'Case Export' else 'Case Import' end + 
					"' as 'TransactionCode'"

		--
		Set @sSQLString2 = ",
				(
				Select 	-- <TransactionData>
					null,
					(	
					select 	-- <CaseDetails>
						C.CASEID as 'SenderCaseIdentifier', 
						C.IRN as 'SenderCaseReference', 
						CTV.CASETYPE_CPAXML  as 'CaseTypeCode', 
						PTV.PROPERTYTYPE_CPAXML as 'CasePropertyTypeCode', 
						(Select CASECATEGORY_CPAXML from #CASECATEGORY_VIEW where CASECATEGORY_INPRO = C.CASECATEGORY and CASECATEGORY_CPAXML is not null) as 'CaseCategoryCode',
						(Select SUBTYPE_CPAXML from #SUBTYPE_VIEW where SUBTYPE_INPRO = C.SUBTYPE and SUBTYPE_CPAXML is not null) as 'CaseSubTypeCode',
						BV.BASIS_CPAXML as 'CaseBasisCode', 
						isnull(COU.ALTERNATECODE, C.COUNTRYCODE) as 'CaseCountryCode', 
						(Select S.EXTERNALDESC from STATUS S where S.STATUSCODE = C.STATUSCODE) as 'CaseStatus',
						(Select S.EXTERNALDESC from STATUS S join PROPERTY P on (P.RENEWALSTATUS = S.STATUSCODE and P.CASEID = C.CASEID)) as 'CaseRenewalStatus',
						TC.STATUS as 'CaseStatusFlag',
						C.FAMILY as 'Family',
						(Select F.FAMILYTITLE from CASEFAMILY F where F.FAMILY = C.FAMILY) as 'FamilyTitle'
			"

		Set @sSQLString3 = "		
					,(
					Select		-- <DescriptionDetails>
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
						from #SiteCtrlClientTextType AS Temp
						join CASETEXT CT ON (CT.TEXTTYPE = Temp.Parameter and CT.CASEID = C.CASEID AND CT.SHORTTEXT IS NOT NULL  ) 
						join #TEXTTYPE_VIEW TTV ON (TTV.TEXTTYPE_INPRO = CT.TEXTTYPE AND TTV.TEXTTYPE_CPAXML IS NOT NULL)
						) TempDesc
						for XML PATH('DescriptionDetails'), TYPE
					),
					( 
					Select 		-- <IdentifierNumberDetails>
						-- exclude number type 'FILE NUMBER' if case is transferred
						NUMBERTYPE_CPAXML as 'IdentifierNumberCode',  
						OFFICIALNUMBER as 'IdentifierNumberText',
						DATEINFORCE as 'IdentifierNumberDateInForce',
						ISCURRENT as 'IdentifierNumberIsCurrent'
						
						from
						(Select 
							NTV.NUMBERTYPE_CPAXML AS NUMBERTYPE_CPAXML, 
							ONS.OFFICIALNUMBER  AS OFFICIALNUMBER,
							ONS.NUMBERTYPE AS NUMBERTYPE, 
							replace( convert(nvarchar(10), Isnull(ONS.DATEENTERED, CE.EVENTDATE), 111), '/', '-') as 'DATEINFORCE',
							ONS.ISCURRENT AS ISCURRENT
							from  OFFICIALNUMBERS ONS
							join #NUMBERTYPE_VIEW NTV ON (NTV.NUMBERTYPE_INPRO = ONS.NUMBERTYPE AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
							join NUMBERTYPES N  ON ( N.NUMBERTYPE = ONS.NUMBERTYPE )
							left join CASEEVENT CE   ON (	CE.CASEID = ONS.CASEID
															and CE.EVENTNO = N.RELATEDEVENTNO )
							where ONS.CASEID = C.CASEID
							and Isnull(CE.CYCLE, 1) = (select Isnull(Max(CE2.CYCLE), 1)
														from   CASEEVENT CE2
														where  CE2.CASEID = CE.CASEID
														and	   CE2.EVENTNO = CE.EVENTNO)

						) temp
						for XML PATH('IdentifierNumberDetails'), TYPE
					)
		"


		Set @sSQLString4 = ",
					( 
					Select	-- <EventDetails>
						EV.EVENT_CPAXML as 'EventCode', 
						replace( convert(nvarchar(10), CE.EVENTDATE, 111), '/', '-') as 'EventDate', 

						-- For Transferred case, event due date is the OLD DATA INSTRUCTOR COMMENCE DATE WHERE EXPIRY DATE IS NULL
						case when (COALESCE(TC.STATUS, '') = 'Transferred' and E.EVENTNO = '"+ @sEventNoChangeOfResponsibility + "') then
						(select replace( convert(nvarchar(10), MAX(TCN.COMMENCEDATE), 111), '/', '-') 
							from CASENAME TCN 
							where TCN.CASEID = TC.CASEID 
							and TCN.NAMETYPE = '" + @sOldDataInstructorCode + "' )
						else
						replace( convert(nvarchar(10), CE.EVENTDUEDATE, 111), '/', '-') 
						end as 'EventDueDate', 
						CE.EVENTTEXT as 'EventText',
						CE.CYCLE as 'EventCycle',
						Case when CE.EVENTNO = -11 THEN TC.ANNUITYTERM  end as 'AnnuityTerm'
						
						from CASEEVENT CE 
						"

		-- Show current event cycle only
		If @pbCurrentCycleOnly = 1
			Set @sSQLString4 = @sSQLString4 + "
						Join #CASEEVENTCYCLE CE2 on (CE2.CASEID = CE.CASEID and CE2.EVENTNO = CE.EVENTNO and CE2.CYCLE = CE.CYCLE)
						"

		-- Only extract events with importance level >=  sitecontrol 'Client Importance'
		Set @sSQLString4 = @sSQLString4 + "
						join EVENTS E on (E.EVENTNO = CE.EVENTNO)  
						join #EVENT_VIEW EV on (EV.EVENT_INPRO = CE.EVENTNO AND EV.EVENT_CPAXML is not null)
						where CE.CASEID = C.CASEID 
						and E.IMPORTANCELEVEL >= " + cast(@nClientImportance as nvarchar(10))  + " 
						for XML PATH('EventDetails'), TYPE
					)

		"


		------------------------------------------------------------------------------------------------
		-- Start CaseName detail <NameDetails> for cases only export ( @pnExportType = 1 )or casenames export (@pnExportType = null)
		------------------------------------------------------------------------------------------------

		-- Suppress name details like address, telecom, contact.  Only show nameno and namecode.
		If @pbSuppressName = 1  
		Begin
			Set @sSQLString5 = ",
			( 
     			Select	-- <NameDetails>
				NTV.NAMETYPE_CPAXML as 'NameTypeCode', 
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
						N.NAMENO as 'SenderNameInternalIdentifier'
	                	from NAME N
						left join INDIVIDUAL IND on (IND.NAMENO = N.NAMENO)
						where N.NAMENO = CN.NAMENO 
						for XML PATH('Name'), TYPE
					)
					for XML PATH('FormattedNameAddress'), TYPE
				)  
				for XML PATH('AddressBook'), TYPE
				)	-- <AddressBook>
							
				from CASENAME CN 
				join #SiteCtrlNameTypes as VNT on (VNT.Parameter = CN.NAMETYPE)
				join #NAMETYPE_VIEW NTV on (NTV.NAMETYPE_INPRO = CN.NAMETYPE and NTV.NAMETYPE_CPAXML is not null)
				where CN.CASEID = C.CASEID "
			IF @pnExportRequestType = 1
			BEGIN
			Set @sSQLString5 = @sSQLString5 + "  AND isnull(CN.INHERITED, 0) <> 1
							for XML PATH('NameDetails'), TYPE
						) -- <NameDetails>		
					"
			END
			ELSE
			BEGIN
				Set @sSQLString5 = @sSQLString5 + "
							for XML PATH('NameDetails'), TYPE
						) -- <NameDetails>		
					"
			END
		End		
		Else Begin  /* Show full name details */
		
			Set @sSQLString5 = ",
						( 
     						Select	-- <NameDetails>
							NTV.NAMETYPE_CPAXML as 'NameTypeCode', 
							CN.SEQUENCE as 'NameSequenceNumber',
							CN.REFERENCENO as 'NameReference',
							-- SQA15741
							--(Select CURRENCY from IPNAME IPN where IPN.NAMENO = CN.NAMENO and CN.NAMETYPE in ('I', 'D') ) as 'NameCurrencyCode',
							case when (CN.NAMETYPE = 'I' or CN.NAMETYPE = 'D') then
							(Select CURRENCY from IPNAME IPN where IPN.NAMENO = CN.NAMENO)
							end as 'NameCurrencyCode',
							(
							Select   --<AddressBook>
							null,
							(
								Select --<FormattedNameAddress>
								null, 
								(
								Select -- <Name>
									N.NAMECODE as 'SenderNameIdentifier', 
									N.NAMENO as 'SenderNameInternalIdentifier', "



			Set @sSQLString5A = "
                					N.TITLE as 'FormattedName/NamePrefix',

									-- NAME.USEDASFLAG & 1 = 1 is Individual, else Organization.
									Case when ( (N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)=0)) then
										N.FIRSTNAME
									when ( (N.USEDASFLAG & 1 = 1) and (charindex(' ', N.FIRSTNAME)>0)) then
										left (N.FIRSTNAME, charindex(' ', N.FIRSTNAME))
									end as 'FormattedName/FirstName',
									-- sqa20161 fix error if FIRSTNAME contains trailing spaces
									Case when ((N.USEDASFLAG & 1 = 1) and (charindex(' ', LTRIM(RTRIM(N.FIRSTNAME)))>0)) then
										right (LTRIM(RTRIM(N.FIRSTNAME)), len(LTRIM(RTRIM(N.FIRSTNAME))) - charindex(' ', LTRIM(RTRIM(N.FIRSTNAME))))  
									end as 'FormattedName/MiddleName',

									Case when (N.USEDASFLAG & 1 = 1) then
                    							dbo.fn_SplitText(N.NAME, ' ', 1, 1)
									end as 'FormattedName/LastName',

									Case when (N.USEDASFLAG & 1 = 1) then
									dbo.fn_SplitText(N.NAME, ' ', 2, 2) 
									end as 'FormattedName/SecondLastName',  

									Case when (N.USEDASFLAG & 1 = 1) then
									dbo.fn_SplitText(N.NAME, ' ', 3, 1) 
									end as 'FormattedName/NameSuffix', 			

									Case IND.SEX 
									when  'M' then 'Male' 
									when  'F' then 'Female' 
									end as 'FormattedName/Gender',

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


			Set @sSQLString6 = "		,			
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

			-- SQA18988 - Attention of name being incorrectly populated
			-- Change MAINCONTACT.NAMENO to MAINCONTACT.MAINCONTACT to populate the name main contact.
			IF @pnExportRequestType = 1
			BEGIN
				Set @sSQLString7 = "		,			
									(
									Select -- <AttentionOf>
										N.TITLE as 'FormattedAttentionOf/NamePrefix',  
										N.FIRSTNAME as 'FormattedAttentionOf/FirstName', 
										N.NAME as 'FormattedAttentionOf/LastName'
										from NAME N 
										where N.NAMENO = (
											Select isnull(CORRESPOND.NAMENO, MAINCONTACT.MAINCONTACT) AS NAMENO
											from CASENAME CN2
											left join NAME CORRESPOND on (CORRESPOND.NAMENO = CN2.CORRESPONDNAME)
											left join NAME MAINCONTACT on (MAINCONTACT.NAMENO = CN2.NAMENO)
											where CN2.CASEID = CN.CASEID  AND isnull(CN2.INHERITED, 0) <> 1
											and CN2.NAMETYPE = CN.NAMETYPE
											and CN2.NAMENO = CN.NAMENO
											and CN2.SEQUENCE = CN.SEQUENCE 
											)
										for XML PATH('AttentionOf'), TYPE
									)		
									for XML PATH('FormattedNameAddress'), TYPE
									)  -- <FormattedNameAddress>
				"
			END
			ELSE
			BEGIN
				Set @sSQLString7 = "		,			
									(
									Select -- <AttentionOf>
										N.TITLE as 'FormattedAttentionOf/NamePrefix',  
										N.FIRSTNAME as 'FormattedAttentionOf/FirstName', 
										N.NAME as 'FormattedAttentionOf/LastName'
										from NAME N 
										where N.NAMENO = (
											Select isnull(CORRESPOND.NAMENO, MAINCONTACT.MAINCONTACT) AS NAMENO
											from CASENAME CN2
											left join NAME CORRESPOND on (CORRESPOND.NAMENO = CN2.CORRESPONDNAME)
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
			END
			-- Show all Phone/Fax/Email?
			If @pbShowAllTelecom = 1
				Set @sSQLTemp = ''
			Else
				-- extract only the MAIN Phone/Fax/Email
				Set @sSQLTemp = ' and 1 = 0 '   -- forcing a false condition so that only the main phone/fax/mail will be reported

			Set @sSQLString8 = "	,	
								(
								Select -- <ContactInformationDetails>
								(Select 
									SORTORDER as 'Phone/@sequenceNumber',
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
									where N.NAMENO = CN.NAMENO " + @sSQLTemp + " 
									and TEL.TELECOMTYPE = 1901
									) temp
									order by SORTORDER
									for XML PATH(''), TYPE
								),										
			                                            	
								(Select 
									SORTORDER as 'Fax/@sequenceNumber',
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
									where N.NAMENO = CN.NAMENO " + @sSQLTemp + " 
									and TEL.TELECOMTYPE = 1902
									) temp
									order by SORTORDER
									for XML PATH(''), TYPE
								), 
			                                            	
								(Select 
									SORTORDER as 'Email/@sequenceNumber',
									EMAIL as 'Email'
									from
									(Select 1 as SORTORDER, dbo.fn_FormatTelecom(1903, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'EMAIL'
									from NAME N
									join TELECOMMUNICATION TEL on (TEL.TELECODE = N.MAINEMAIL)
									where NAMENO = CN.NAMENO
									UNION
									Select ROW_NUMBER() OVER (order by N.NAMENO ) + 1 as SORTORDER,  dbo.fn_FormatTelecom(1903, TEL.ISD, TEL.AREACODE, TEL.TELECOMNUMBER, TEL.EXTENSION) as 'EMAIL'
									from NAME N
									join NAMETELECOM NTEL on (NTEL.NAMENO = N.NAMENO and NTEL.TELECODE != N.MAINEMAIL)
									join TELECOMMUNICATION TEL on (TEL.TELECODE = NTEL.TELECODE)
									where N.NAMENO = CN.NAMENO " + @sSQLTemp + " 
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
							join #SiteCtrlNameTypes as VNT on (VNT.Parameter = CN.NAMETYPE)
							join #NAMETYPE_VIEW NTV on (NTV.NAMETYPE_INPRO = CN.NAMETYPE and NTV.NAMETYPE_CPAXML is not null)
							where CN.CASEID = C.CASEID "

			IF @pnExportRequestType = 1
			BEGIN
				Set @sSQLString9 = @sSQLString9 + "  AND isnull(CN.INHERITED, 0) <> 1
								for XML PATH('NameDetails'), TYPE
								) -- <NameDetails>
				"
			END
			ELSE
			BEGIN
				Set @sSQLString9 = @sSQLString9 + "
								for XML PATH('NameDetails'), TYPE
								) -- <NameDetails>
				"
			END
		End  
		------------------------------------------------------------------------------------------------
		-- finish casename details <NameDetails>
		------------------------------------------------------------------------------------------------


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
							Select NTV.NUMBERTYPE_CPAXML as NUMBERTYPE,  
								OFN.OFFICIALNUMBER as NUMBERTEXT
								from RELATEDCASE RC2
								join OFFICIALNUMBERS OFN on (OFN.CASEID = RC.RELATEDCASEID AND OFN.ISCURRENT = 1)
								join #NUMBERTYPE_VIEW NTV on (NTV.NUMBERTYPE_INPRO = OFN.NUMBERTYPE AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
								where RC2.CASEID = RC.CASEID
								and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
								and RC2.OFFICIALNUMBER is null
								and OFN.NUMBERTYPE IN ('A', 'R')
							Union
							Select 
								NTV.NUMBERTYPE_CPAXML as NUMBERTYPE, 
								RC2.OFFICIALNUMBER as NUMBERTEXT
								from RELATEDCASE RC2 
								join  #NUMBERTYPE_VIEW NTV on (NTV.NUMBERTYPE_INPRO = 'A' AND NTV.NUMBERTYPE_CPAXML IS NOT NULL)
								where RC2.CASEID = RC.CASEID
								and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
								and RC2.OFFICIALNUMBER is not null										
							) TEMP
							for XML PATH('AssociatedCaseIdentifierNumberDetails'), TYPE
						)
		"
		-- RFC9683 
		-- When exporting related case information for a case 
		-- the priority date field should be derived from the FROMEVENTNO field on the relationship.
		-- Otherwise use the application date from the event -4. 	
		Set @sSQLString11 = " , 
						(
						Select     	-- <AssociatedCaseEventDetails>
							TEMP.EVENTCODE as 'EventCode', 
							replace( convert(nvarchar(10), TEMP.EVENTDATE, 111), '/', '-') as 'EventDate'
							from
							(
							Select EV.EVENT_CPAXML as EVENTCODE, RC2.PRIORITYDATE as EVENTDATE 
								from RELATEDCASE RC2
								--join #EVENT_VIEW EV on (EV.EVENT_INPRO = -4 and EV.EVENT_CPAXML is not null)
								join CASERELATION CR ON (CR.RELATIONSHIP = RC2.RELATIONSHIP)
								join #EVENT_VIEW EV on (EV.EVENT_INPRO = CR.FROMEVENTNO and EV.EVENT_CPAXML is not null)
								where RC2.CASEID = RC.CASEID
								and RC2.RELATIONSHIPNO = RC.RELATIONSHIPNO
								and RC2.OFFICIALNUMBER is not null
								and RC2.RELATEDCASEID is null
							Union
							Select EV.EVENT_CPAXML as EVENTCODE, CE.EVENTDATE as EVENTDATE
								from RELATEDCASE RC2 
								--join CASEEVENT CE on (CE.CASEID = RC2.RELATEDCASEID and CE.EVENTNO = -4)
								--join #EVENT_VIEW EV on (EV.EVENT_INPRO = -4 and EV.EVENT_CPAXML is not null)
								join CASERELATION CR ON (CR.RELATIONSHIP = RC2.RELATIONSHIP)
								join CASEEVENT CE on (CE.CASEID = RC2.RELATEDCASEID and CE.EVENTNO = CR.FROMEVENTNO)
								join #EVENT_VIEW EV on (EV.EVENT_INPRO = CR.FROMEVENTNO and EV.EVENT_CPAXML is not null)
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
						) 	-- <AssociatedCaseDetails>
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
							IC.CLASS as 'ClassNumber',
							TCT.LANGUAGE  as 'GoodsServicesDescription/@LanguageCode',
							ISNULL(TCT.SHORTTEXT, TCT.TEXT) as 'GoodsServicesDescription'
							from  " + @sTempTableCaseClass + " IC
							left join ( SELECT RANK() OVER (PARTITION BY CT.CASEID, CT.CLASS ORDER BY ISNULL(CT.LANGUAGE, 1) ) as SEQUENCE,   -- DR-49262 Include GST text
										CT.SHORTTEXT, CT.TEXT, CT.CASEID, CT.CLASS, TC.USERCODE AS LANGUAGE
										from CASETEXT CT
										Join SITECONTROL SC ON SC.CONTROLID = 'LANGUAGE'
										left Join TABLECODES TC ON TC.TABLECODE = CT.LANGUAGE AND TC.TABLETYPE = 47
										where CT.TEXTNO = (	select MAX(CT2.TEXTNO) 
															FROM CASETEXT CT2
															WHERE CT2.CASEID = CT.CASEID
															AND CT2.CLASS = CT.CLASS
															AND CT2.TEXTTYPE = 'G'
															AND ((CT2.LANGUAGE = CT.LANGUAGE) 
																OR (CT2.LANGUAGE IS NULL AND CT.LANGUAGE IS NULL)) )
										AND CT.CASEID = C.CASEID
										AND CT.TEXTTYPE = 'G'
										AND (CT.LANGUAGE IS NULL OR CT.LANGUAGE = ISNULL(SC.COLINTEGER, 4704))
										) TCT ON TCT.CASEID = IC.CASEID
											 AND TCT.CLASS = IC.CLASS
											 AND TCT.SEQUENCE = 1
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
						)
						"
		Set @sSQLString12A = ",
	     				( 
						Select     	-- <GoodsServicesDetails> for Local classes 'Domestic' 
						'Domestic' as 'ClassificationTypeCode',
						( 
						Select     	-- <ClassDescriptionDetails>  
							null,
							(
							Select	-- <ClassDescription>
							IC.CLASS as 'ClassNumber',
							TCT.LANGUAGE as 'GoodsServicesDescription/@LanguageCode',
							ISNULL(TCT.SHORTTEXT, TCT.TEXT) as 'GoodsServicesDescription'
							from  " + @sTempTableCaseClass + " IC
							left join ( SELECT RANK() OVER (PARTITION BY CT.CASEID, CT.CLASS ORDER BY ISNULL(CT.LANGUAGE, 1) ) as SEQUENCE,  -- DR-49262 Include GST text
										CT.SHORTTEXT, CT.TEXT, CT.CASEID, CT.CLASS, TC.USERCODE AS LANGUAGE
										from CASETEXT CT
										Join SITECONTROL SC ON SC.CONTROLID = 'LANGUAGE'
										left Join TABLECODES TC ON TC.TABLECODE = CT.LANGUAGE AND TC.TABLETYPE = 47
										where CT.TEXTNO = (	select MAX(CT2.TEXTNO) 
															FROM CASETEXT CT2
															WHERE CT2.CASEID = CT.CASEID
															AND CT2.CLASS = CT.CLASS
															AND CT2.TEXTTYPE = 'G'
															AND ((CT2.LANGUAGE = CT.LANGUAGE) 
																OR (CT2.LANGUAGE IS NULL AND CT.LANGUAGE IS NULL)))
										AND CT.CASEID = C.CASEID
										AND CT.TEXTTYPE = 'G'
										AND (CT.LANGUAGE IS NULL OR CT.LANGUAGE = ISNULL(SC.COLINTEGER, 4704))
										) TCT ON TCT.CASEID = IC.CASEID
											 AND TCT.CLASS = IC.CLASS
											 AND TCT.SEQUENCE = 1
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


		Set @sSQLStringLast = "		
						from CASES C
						left join #CASETYPE_VIEW CTV on (CTV.CASETYPE_INPRO = C.CASETYPE and CTV.CASETYPE_CPAXML is not null)
						left join #PROPERTYTYPE_VIEW PTV on (PTV.PROPERTYTYPE_INPRO = C.PROPERTYTYPE AND PTV.PROPERTYTYPE_CPAXML is not null)
						left join COUNTRY COU on (COU.COUNTRYCODE = C.COUNTRYCODE)
						left join PROPERTY P on (P.CASEID = C.CASEID)
						left join #BASIS_VIEW BV on (BV.BASIS_INPRO = P.BASIS and P.BASIS is not null AND BV.BASIS_CPAXML is not null )
						where C.CASEID = TC.CASEID
						for XML PATH('CaseDetails'), TYPE
					)  -- end <CaseDetails>
					for XML PATH('TransactionData'), TYPE
					) 	-- end <TransactionData>
					for XML PATH('TransactionContentDetails'), TYPE
					)	-- end <TransactionContentDetails>
				for XML PATH(''), ROOT('TransactionBody') 
				) as XMLSTR     -- end <TransactionBody>

				from #TEMPCASES TC
			"



		If @bDebug = 1
		Begin		
			PRINT /*--1--*/ + @sSQLString1
			PRINT /*--2--*/ + @sSQLString2
			PRINT /*--3--*/ + @sSQLString3
			PRINT /*--4--*/ + @sSQLString4
			PRINT /*--4A--*/ + @sSQLString4A
			PRINT /*--5--*/ + @sSQLString5
			PRINT /*--5A--*/ + @sSQLString5A
			PRINT /*--6--*/ + @sSQLString6
			PRINT /*--7--*/ + @sSQLString7
			PRINT /*--8--*/ + @sSQLString8
			PRINT /*--9--*/ + @sSQLString9
			PRINT /*--10--*/ + @sSQLString10
			PRINT /*--11--*/ + @sSQLString11
			PRINT /*--12--*/ + @sSQLString12
			PRINT /*--12A--*/ + @sSQLString12A
			PRINT /*--13--*/ + @sSQLString13
			PRINT /*--last--*/ + @sSQLStringLast
		End


		-- sqa17676  extracting 1000 rows at a time seems to improve performance
		set @nLastFromRowId = 0
		While @nErrorCode = 0 
		and @nLastFromRowId <= @nNumberOfCases
		Begin
			set @sSQLStringFilter = " WHERE TC.ROWID >= " + CAST(@nLastFromRowId as nvarchar(10)) + 
									" and TC.ROWID < " + CAST(@nLastFromRowId + 1000 as nvarchar(10) )

			If @bDebug = 1
				print /*--filter--*/ @sSQLStringFilter

			exec(@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString5+@sSQLString5A+@sSQLString6+@sSQLString7+@sSQLString8+@sSQLString9+@sSQLString10+@sSQLString11+@sSQLString12+@sSQLString12A+@sSQLString13+@sSQLStringLast+@sSQLStringFilter)
			set @nErrorCode=@@error
				
			set @nLastFromRowId = @nLastFromRowId + 1000

			If @bDebug = 1
				PRINT 'inserted next 1000 rows into XML BODY'
		End
	End		/* export cases & casenames */
	
End  /* transactions body*/


If @nErrorCode = 0	
Begin	
	-- Add close header element </Transaction>
	Set @sSQLString =  "
		Insert into "+ @sCaseAndNameXML +" (XMLSTR) values (" + char(13)+char(10)+ "'</Transaction>') "
	exec @nErrorCode=sp_executesql @sSQLString
End

--Export XML to file
If @nErrorCode = 0 and @psFilePath is not null
	Begin	
		If @psLoginId is not null and @psPassword is not null
			-- Using specific login (e.g. login is SQLServer authenticated rather then trusted - Windows authenticated)
			Set @sSQLString = 'bcp "SELECT XMLSTR FROM ' + DB_NAME() + '..' + @sCaseAndNameXML + ' order by ROWID " queryout "' + @psFilePath + '" -c -t -S' + @@Servername + ' -U' + @psLoginId + ' -P' + @psPassword 
		Else
			-- Using trusted connection (login is windows authentication)
			set @sSQLString = 'bcp "SELECT XMLSTR FROM ' + DB_NAME() + '..' + @sCaseAndNameXML + ' order by ROWID " queryout "' + @psFilePath + '" -c -t -T'

		If @bDebug = 1
			print @sSQLString
		
		exec @nErrorCode=master..xp_cmdshell @sSQLString
	End 
Else 
Begin
	If @nErrorCode = 0 and @pnBackgroundProcessId is not null and @pnCaseId is null
		Begin
			Set @sSQLString = 'INSERT INTO CPAXMLEXPORTRESULT(PROCESSID,CPAXMLDATA) 
							   SELECT '+Convert(varchar,@pnBackgroundProcessId)+', XMLSTR FROM ' + DB_NAME() + '..' + @sCaseAndNameXML + ' order by ROWID'			   
			Exec @nErrorCode=sp_executesql @sSQLString
			print @sSQLString
		END						
	Else
		Begin
			--Execute xml result set
			If @nErrorCode = 0 and @pnBackgroundProcessId is null and @pnCaseId is not null
			Begin	
				Set @sXMLResult =  'SELECT XMLSTR AS CPAXMLDATA FROM ' + DB_NAME() + '..' + @sCaseAndNameXML + ' order by ROWID '
				Exec @nErrorCode=sp_executesql @sXMLResult
			End
		End
End

-- Drop global temporary table used
if exists(select * from tempdb.dbo.sysobjects where name = @sTempTableCaseClass)
Begin
    Set @sSQLString = "drop table "+@sTempTableCaseClass
    exec sp_executesql @sSQLString
End
if exists(select * from tempdb.dbo.sysobjects where name = @sCaseAndNameXML)
Begin
    Set @sSQLString = "drop table "+@sCaseAndNameXML
    exec sp_executesql @sSQLString
End
if exists(select * from tempdb.dbo.sysobjects where name = @sTokenisedAddressTableName)
Begin
    Set @sSQLString = "drop table "+@sTokenisedAddressTableName
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


---------------------------------------
-- Update BACKGROUNDPROCESS table 
---------------------------------------	
If @pnBackgroundProcessId is not null 
Begin	
	if exists(select * from tempdb.dbo.sysobjects where name = @psCaseTable)
	Begin
		Set @sSQLString = "drop table "+@psCaseTable
		exec sp_executesql @sSQLString
	End
	If @nErrorCode = 0
	Begin		
		set @sFileName=''
		Set @sSQLString = "Update BACKGROUNDPROCESS
				Set STATUS = 2,
				    STATUSDATE = getdate(),
					STATUSINFO=@sFileName
				Where PROCESSID = @pnBackgroundProcessId"

		exec sp_executesql @sSQLString,
			N'@pnBackgroundProcessId	int,
			@sFileName			varchar(254)',
			@pnBackgroundProcessId  = @pnBackgroundProcessId,
			@sFileName=@sFileName
		
	End
	Else
	Begin
		Set @sSQLString="Select @sErrorMessage = description
			from master..sysmessages
			where error=@nErrorCode
			and msglangid=(SELECT msglangid FROM master..syslanguages WHERE name = @@LANGUAGE)"

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@sErrorMessage	nvarchar(254) output,
			  @nErrorCode	int',
			  @sErrorMessage	= @sErrorMessage output,
			  @nErrorCode	= @nErrorCode

		---------------------------------------
		-- Update BACKGROUNDPROCESS table 
		---------------------------------------	
		Set @sSQLString = "Update BACKGROUNDPROCESS
					Set STATUS = 3,
					    STATUSDATE = getdate(),
					    STATUSINFO = @sErrorMessage
					Where PROCESSID = @pnBackgroundProcessId"

		exec sp_executesql @sSQLString,
			N'@pnBackgroundProcessId	int,
			  @sErrorMessage	nvarchar(254)',
			  @pnBackgroundProcessId = @pnBackgroundProcessId,
			  @sErrorMessage	= @sErrorMessage
	End		
End
RETURN @nErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


grant execute on dbo.EDE_ExportCaseName to public
go

