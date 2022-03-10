-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_GetReminderDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xml_GetReminderDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xml_GetReminderDetails.'
	Drop procedure [dbo].[xml_GetReminderDetails]
End
Print '**** Creating Stored Procedure dbo.xml_GetReminderDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.xml_GetReminderDetails
(							
	@ptXML	ntext
)
as
-- PROCEDURE:	xml_GetReminderDetails
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns reminder details in the XML format.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	------	--------	-------	----------------------------------------------- 
-- 04 Apr 2007	IB	SQA14511	1	Procedure created
-- 10 Aug 2007	IB	SQA13175	2	Displayed comments for alerts (ad-hoc reminders).
-- 20 Jan 2009	MF	SQA17252	3	Return the designated countries associated with the reminder.
-- 02 Apr 2009	MF	SQA17561	4	Return the Country with the details of the reminder.
-- 17 Sep 2010	MF	RFC9777		5	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 20 Apr 2011	MF	RFC10333	6	Join EMPLOYEEREMINDER to ALERT using new ALERTNAMENO column which caters for Reminders that
--						have been sent to names that are different to the originating Alert.
-- 27 Aug 2013	DL	SQA21076	7	Duplicated reminder information in reminder details pop up.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int	
Declare	@iDocument 		int		-- handle to the XML document					
Declare @nEmployeeNo		int		-- the EMPLOYEENO held against the reminder. 
Declare	@dtDateCreated		datetime	-- the MESSAGESEQ held against the reminder.				
Declare @nCaseId		int		-- the CASEID held against the reminder. 			
Declare @nEventNo		int		-- the EVENTNO held against the reminder. 			
Declare @nCycleNo		smallint	-- the CYCLENO held against the reminder.
Declare @sSQLString1		nvarchar(4000) 

-- Store the required information in a table variable
Declare @tbReminderDetails table (
	Employee		nvarchar(400)	collate database_default NULL,
	CaseOwner		nvarchar(400)	collate database_default NULL,
	CaseEmployee		nvarchar(400)	collate database_default NULL,
	Signatory		nvarchar(400)	collate database_default NULL,
	Source			bit		NULL,
	DueDate			datetime	NULL,
	ReminderDate		datetime	NULL,
	ReadFlag		bit		NULL,
	ShortMessage		nvarchar(254)	collate database_default NULL,
	LongMessage		ntext		NULL,
	HoldUntilDate		datetime	NULL,	
	EventNo			int		NULL,
	CycleNo			smallint	NULL,
	Comments		nvarchar(254)	collate database_default NULL,
	Reference		nvarchar(20)	collate database_default NULL,
	DateUpdated		datetime	NULL,	
	[Sequence]		int		NULL,
	IRN			nvarchar(30)	collate database_default NULL,
	CaseShortTitle		nvarchar(254)	collate database_default NULL,
	CaseType		nvarchar(50)	collate database_default NULL,
	PropertyType		nvarchar(50)	collate database_default NULL,
	Country			nvarchar(60)	collate database_default NULL,
	EventDescription	nvarchar(100)	collate database_default NULL,
	EventText		nvarchar(254)	collate database_default NULL,
	ImportanceLevel		nvarchar(2)	collate database_default NULL,
	ImportanceLevelDesc	nvarchar(30)	collate database_default NULL,
	FileLocationKey		int		NULL,	
	FileLocation		nvarchar(80)	collate database_default NULL
			)

Declare @tbEmployeeComments table (
	Employee		nvarchar(400)	collate database_default NULL,
	Comments		nvarchar(254)	collate database_default NULL
			)
			
Declare @tbDesignatedCountry table (
	Country			nvarchar(60)	collate database_default NULL,
	CountryStatus		nvarchar(30)	collate database_default NULL
			)

-- Initialise variables
Set @nErrorCode 		= 0

--	Extract details from XML-string
--	Collect data from XML that was passed as XML parameter, using OPENXML functionality
If	@nErrorCode = 0
begin	
	Exec 	sp_xml_preparedocument  @iDocument OUTPUT, @ptXML
	Set 	@nErrorCode = @@Error
end

---	Extract individual tags from the XML parameter for B2BResponse
If	@nErrorCode = 0
Begin
	Set	@sSQLString1 = "
		select 	@nEmployeeNo = EMPLOYEENO,
			@dtDateCreated = MESSAGESEQ,
			@nCaseId = CASEID,
			@nEventNo = EVENTNO,
			@nCycleNo = CYCLENO
		from	openxml (@iDocument,'EmployeeReminder',2)
		with   (EMPLOYEENO	integer 'EmployeeNo/text()',
			MESSAGESEQ 	datetime 'MessageSeq/text()',
			CASEID 		integer 'CaseId/text()',
			EVENTNO 	integer 'EventNo/text()',
			CYCLENO 	smallint 'CycleNo/text()') "

	Exec	@nErrorCode = sp_executesql @sSQLString1,
		N'@nEmployeeNo		int     		OUTPUT,
		  @dtDateCreated	datetime   		OUTPUT,
		  @nCaseId		int     		OUTPUT,
		  @nEventNo		int     		OUTPUT,
		  @nCycleNo		smallint     		OUTPUT,
		  @iDocument		int',
		  @nEmployeeNo		= @nEmployeeNo		OUTPUT,
		  @dtDateCreated	= @dtDateCreated  	OUTPUT,
		  @nCaseId		= @nCaseId  	OUTPUT,
		  @nEventNo		= @nEventNo  	OUTPUT,
		  @nCycleNo		= @nCycleNo  	OUTPUT,
		  @iDocument 		= @iDocument
	
	-- deallocate the XML document handle when finished.
	Exec sp_xml_removedocument @iDocument
End

If  @nErrorCode = 0
Begin
	-- Main result set
	insert into @tbReminderDetails
	Select 	EMP.NAME + CASE WHEN EMP.FIRSTNAME IS NOT NULL THEN ', ' + EMP.FIRSTNAME END,
		OWNER.NAME + CASE WHEN OWNER.FIRSTNAME IS NOT NULL THEN ', ' + OWNER.FIRSTNAME END,
		CASEEMP.NAME + CASE WHEN CASEEMP.FIRSTNAME IS NOT NULL THEN ', ' + CASEEMP.FIRSTNAME END,
		SIG.NAME + CASE WHEN SIG.FIRSTNAME IS NOT NULL THEN ', ' + SIG.FIRSTNAME END,
		ER.SOURCE, 
		ER.DUEDATE, 	
		ER.REMINDERDATE, 	
		ER.READFLAG, 	
		ER.SHORTMESSAGE, 
		ER.LONGMESSAGE, 	
		ER.HOLDUNTILDATE, 	
		ER.EVENTNO, 		
		ER.CYCLENO, 	
		ER.COMMENTS, 	
		ER.REFERENCE, 	
		ER.DATEUPDATED, 	
		ER.SEQUENCENO, 	
		C.IRN, 	
		C.TITLE, 	
		CT.CASETYPEDESC, 	
		PT.PROPERTYNAME,
		CC.COUNTRY,
		EC.EVENTDESCRIPTION, 	
		CE.EVENTTEXT,	
		IM.IMPORTANCELEVEL, 	
		IM.IMPORTANCEDESC, 
		CL.FILELOCATION, 	
		TC.DESCRIPTION
	from EMPLOYEEREMINDER ER
     	join NAME EMP 			on (EMP.NAMENO = ER.EMPLOYEENO)
     	left join CASES C 		on (C.CASEID = ER.CASEID)
     	left join CASETYPE CT 		on (CT.CASETYPE = C.CASETYPE)
     	left join VALIDPROPERTY PT 	on (PT.PROPERTYTYPE = C.PROPERTYTYPE
					and PT.COUNTRYCODE = (select min(PT1.COUNTRYCODE)
						from VALIDPROPERTY PT1
						where PT1.PROPERTYTYPE=C.PROPERTYTYPE
						and   PT1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
	left join COUNTRY CC		on (CC.COUNTRYCODE=C.COUNTRYCODE)
	left join CASEEVENT CE 		on (CE.CASEID = ER.CASEID
					and CE.EVENTNO = ER.EVENTNO
					and CE.CYCLE  = ER.CYCLENO)
	left join EVENTS EV 		on (EV.EVENTNO = ER.EVENTNO)
	left join OPENACTION OA		on (OA.CASEID  = CE.CASEID
					and OA.ACTION  = EV.CONTROLLINGACTION
					and OA.CYCLE =(	select max(OA1.CYCLE)
							from OPENACTION OA1
							where OA1.CASEID=OA.CASEID
							and OA1.ACTION=OA.ACTION))
	left join EVENTCONTROL EC 	on (EC.CRITERIANO = isnull(OA.CRITERIANO,CE.CREATEDBYCRITERIA)
					and EC.EVENTNO = CE.EVENTNO)
	left join CASENAME CN 		on (CN.CASEID = ER.CASEID
					and CN.NAMETYPE = 'O'
					and CN.SEQUENCE = (select min(SEQUENCE)
						from  CASENAME CN2
						where CN2.CASEID = ER.CASEID
						and CN2.NAMETYPE = CN.NAMETYPE))
	left join NAME OWNER 		on (OWNER.NAMENO = CN.NAMENO)
	left join CASENAME CN3 		on (CN3.CASEID = ER.CASEID
					and CN3.NAMETYPE = 'EMP'
					and CN3.SEQUENCE = (select min(SEQUENCE)
						from  CASENAME CN2
						where CN2.CASEID = ER.CASEID
						and CN2.NAMETYPE = CN3.NAMETYPE))
	left join NAME CASEEMP 		on (CASEEMP.NAMENO = CN3.NAMENO)
	left join CASENAME CN4 		on (CN4.CASEID = ER.CASEID
					and CN4.NAMETYPE = 'SIG'
					and CN4.SEQUENCE = (select min(SEQUENCE)
						from  CASENAME CN2
						where CN2.CASEID = ER.CASEID
						and CN2.NAMETYPE = CN4.NAMETYPE))
	left join NAME SIG 		on (SIG.NAMENO = CN4.NAMENO)
	left join ALERT A		on (ER.ALERTNAMENO = A.EMPLOYEENO
					and ER.SEQUENCENO = A.SEQUENCENO
					and (ER.CASEID=A.CASEID OR ER.REFERENCE=A.REFERENCE OR ER.NAMENO=A.NAMENO)
					and ER.EVENTNO IS NULL)
	left join IMPORTANCE IM 	on ( IM.IMPORTANCELEVEL = coalesce( EC.IMPORTANCELEVEL, EV.IMPORTANCELEVEL, A.IMPORTANCELEVEL ) )
	left join CASELOCATION CL 	on (CL.CASEID = ER.CASEID
					and CL.WHENMOVED = (select max( WHENMOVED )
						from CASELOCATION CL1
						where CL1.CASEID = ER.CASEID ))
	left join TABLECODES TC 	on (TC.TABLETYPE = 10 and TC.TABLECODE = CL.FILELOCATION)
	
	where 				ER.EMPLOYEENO = @nEmployeeNo
					and   ER.MESSAGESEQ = @dtDateCreated

	Select * 
	from @tbReminderDetails AS ReminderDetails
	for XML AUTO, ELEMENTS

	Set @nErrorCode = @@Error

End

If  @nErrorCode = 0
Begin
	-- Comments
	If (@nCaseId is not null) AND (@nEventNo is not null) AND (@nCycleNo is not null)
	Begin
		insert into @tbEmployeeComments
		Select 	N.NAME + CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' + N.FIRSTNAME END,
			ER.COMMENTS	
		from	EMPLOYEEREMINDER ER
		join 	NAME N on 		(N.NAMENO = ER.EMPLOYEENO)
		join	CASEEVENT CE on 	(CE.CASEID = ER.CASEID
						AND CE.EVENTNO = ER.EVENTNO
						AND CE.CYCLE = ER.CYCLENO)
		where	ER.CASEID = @nCaseId
		and	ER.EVENTNO = @nEventNo
		and	ER.CYCLENO = @nCycleNo
		and	ER.COMMENTS IS NOT NULL
		order by 1
	End
	Else If (@nCaseId is not null) AND (@nEventNo is null)
	Begin
		insert into @tbEmployeeComments
		Select 	N.NAME + CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' + N.FIRSTNAME END,
			ER.COMMENTS	
		from	EMPLOYEEREMINDER ER
		join 	EMPLOYEEREMINDER ER2 on	(ER2.EMPLOYEENO = @nEmployeeNo
						 and ER2.MESSAGESEQ = @dtDateCreated)
		join 	NAME N on 		(N.NAMENO = ER.EMPLOYEENO)
		where	ER.CASEID = @nCaseId
		and	ER.SHORTMESSAGE = ER2.SHORTMESSAGE
		and	ER.COMMENTS IS NOT NULL
		order by 1
	End
	Else
	Begin
		insert into @tbEmployeeComments
		Select 	N.NAME + CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' + N.FIRSTNAME END,
			ER.COMMENTS	
		from	EMPLOYEEREMINDER ER
		join 	EMPLOYEEREMINDER ER2 on	(ER2.EMPLOYEENO = @nEmployeeNo
						 and ER2.MESSAGESEQ = @dtDateCreated)
		join 	NAME N on 		(N.NAMENO = ER.EMPLOYEENO)
		where	ER.COMMENTS IS NOT NULL
		and   ((ER.REFERENCE=ER2.REFERENCE and ER.CASEID is null and ER2.CASEID is null)
		 OR    (ER.REFERENCE  is null  and
			ER2.REFERENCE is null  and
			ER2.CASEID =ER.CASEID  and
			ER2.EVENTNO=ER.EVENTNO and
			ER2.CYCLENO=ER.CYCLENO ))
		order by 1
	End

	Select * 
	from @tbEmployeeComments AS EmployeeComments
	for XML AUTO, ELEMENTS

	Set @nErrorCode = @@Error

End

If @nErrorCode=0
Begin
	insert into @tbDesignatedCountry
	Select 	C.COUNTRY, 	
		CF.FLAGNAME
	from EMPLOYEEREMINDER ER
	join CASES CS			on (CS.CASEID=ER.CASEID)
	join CASEEVENT CE		on (CE.CASEID=ER.CASEID
					and CE.EVENTNO=ER.EVENTNO
					and CE.CYCLE=ER.CYCLENO)
	join EVENTCONTROL EC		on (EC.CRITERIANO=CE.CREATEDBYCRITERIA
					and EC.EVENTNO=CE.EVENTNO)
	join DUEDATECALC DD		on (DD.CRITERIANO=CE.CREATEDBYCRITERIA
					and DD.EVENTNO=CE.EVENTNO
					and DD.FROMEVENT is null)
	join RELATEDCASE RC		on (RC.CASEID=CE.CASEID
					and RC.RELATIONSHIP='DC1'
					and RC.COUNTRYCODE =DD.COUNTRYCODE
					and RC.COUNTRYFLAGS<EC.CHECKCOUNTRYFLAG)
	join COUNTRY C			on (C.COUNTRYCODE=DD.COUNTRYCODE)
	left join COUNTRYFLAGS CF	on (CF.COUNTRYCODE=CS.COUNTRYCODE
					and CF.FLAGNUMBER=RC.CURRENTSTATUS)
	where ER.EMPLOYEENO = @nEmployeeNo
	and   ER.MESSAGESEQ = @dtDateCreated
	order by 1

	Select * 
	from @tbDesignatedCountry AS DesignatedCountries
	for XML AUTO, ELEMENTS

	Set @nErrorCode = @@Error
End

Return @nErrorCode
GO

Grant execute on dbo.xml_GetReminderDetails to public
GO
