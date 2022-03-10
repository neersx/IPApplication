-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rmw_ListWorksheetReminder
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rmw_ListWorksheetReminder]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rmw_ListWorksheetReminder.'
	Drop procedure [dbo].[rmw_ListWorksheetReminder]
End
Print '**** Creating Stored Procedure dbo.rmw_ListWorksheetReminder...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.rmw_ListWorksheetReminder
(		
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLFilterCriteria	ntext		= null,	-- The filtering to be performed on the result set.	
	@pnType			int		= 0,	-- Type of Result
							-- 0 for Main Result Set
							-- 1 for Comments
							-- 2 for Designated Countries
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	rmw_ListWorksheetReminder
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns reminder details for the Report.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- -----------	------	-------	-------	----------------------------------------------- 
-- 08 Mar 2010	MS	RFC8576	1	Procedure created
-- 07 Apr 2010	MS	RFC8576	2	Fix Comments by applying Isnull on Reference and ShortMessage
-- 17 Sep 2010	MF	RFC9777	3	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 20 Apr 2011	MF	RFC10333 4	Join EMPLOYEEREMINDER to ALERT using new ALERTNAMENO column which caters for Reminders that
--					have been sent to names that are different to the originating Alert.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int	
Declare @sSQLString		nvarchar(max) 
Declare @sWhere			nvarchar(max) 
Declare @sSelect		nvarchar(max)
Declare @sFrom			nvarchar(max) 
Declare @sLookupCulture		nvarchar(10)

Declare	@iDocument 		int		-- handle to the XML document					
Declare @nEmployeeNo		int		-- the EMPLOYEENO held against the reminder. 
Declare	@dtDateCreated		datetime	-- the ALERTSEQ held against the reminder.				

set	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set     @nErrorCode = 0	


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
	Exec 	sp_xml_preparedocument  @iDocument OUTPUT, @ptXMLFilterCriteria
	Set 	@nErrorCode = @@Error
end

---	Extract individual tags from the XML parameter for B2BResponse
If	@nErrorCode = 0
Begin
	Set	@sSQLString = "
		select 	@nEmployeeNo = EmployeeNo,
			@dtDateCreated = DateCreated
		from	openxml (@iDocument,'EmployeeReminder',2)
		with   (EmployeeNo	integer 'EmployeeNo/text()',
			DateCreated 	datetime 'DateCreated/text()') "

	Exec	@nErrorCode = sp_executesql @sSQLString,
		N'@nEmployeeNo		int     		OUTPUT,
		  @dtDateCreated	datetime   		OUTPUT,		
		  @iDocument		int',
		  @nEmployeeNo		= @nEmployeeNo		OUTPUT,
		  @dtDateCreated	= @dtDateCreated  	OUTPUT,		 
		  @iDocument 		= @iDocument
	
	-- deallocate the XML document handle when finished.
	Exec sp_xml_removedocument @iDocument
End

-- Set Where
If  @nErrorCode = 0
Begin
	Set @sWhere =  "where 	ER.EMPLOYEENO = @nEmployeeNo and  ER.MESSAGESEQ = @dtDateCreated"
End

If  @nErrorCode = 0 and @pnType = 0
Begin
	-- Main result set
	Set @sSelect = "Select EMP.NAME + CASE WHEN EMP.FIRSTNAME IS NOT NULL THEN ', ' + EMP.FIRSTNAME END as Employee,
		OWNER.NAME + CASE WHEN OWNER.FIRSTNAME IS NOT NULL THEN ', ' + OWNER.FIRSTNAME END as CaseOwner,
		CASEEMP.NAME + CASE WHEN CASEEMP.FIRSTNAME IS NOT NULL THEN ', ' + CASEEMP.FIRSTNAME END as CaseEmployee,
		SIG.NAME + CASE WHEN SIG.FIRSTNAME IS NOT NULL THEN ', ' + SIG.FIRSTNAME END as Signatory,
		C.IRN as CaseReference, 	
		C.TITLE as CaseShortTitle, 	
		CT.CASETYPEDESC as CaseType, 	
		PT.PROPERTYNAME as PropertyType,
		CC.COUNTRY as Country,
		CASE WHEN ER.SOURCE = 1 THEN 'Ad-Hoc Reminders' ELSE 'Policing' END as Source, 
		ER.DUEDATE as DueDate, 	
		ER.REMINDERDATE as ReminderDate, 
		datediff( day, getdate(), isnull( CE.EVENTDUEDATE, getdate())) as DaysUntilDue,	
		ER.DATEUPDATED as DateUpdated, 	
		ER.READFLAG as ReadFlag, 	
		ISNULL(ER.LONGMESSAGE, ER.SHORTMESSAGE)  as ReminderMessage,
		ER.HOLDUNTILDATE as HoldUntilDate,		
		ER.COMMENTS as ReminderComments, 	
		ER.REFERENCE as Reference,		
		ER.SEQUENCENO as Sequence, 
		ER.EVENTNO as EventNo, 		
		ER.CYCLENO as EventCycle, 	
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+', '+
			dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EV',@sLookupCulture,@pbCalledFromCentura)+
			") as EventDescription,"+CHAR(10)+ 
		dbo.fn_SqlTranslatedColumn('EVENTCATEGORY','CATEGORYNAME',null,'ECT',@sLookupCulture,@pbCalledFromCentura)+" as EventCategory, 	
		CE.EVENTTEXT as EventText,	
		IM.IMPORTANCELEVEL as ImportanceLevel,"+CHAR(10)+ 	
		dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'IM',@sLookupCulture,@pbCalledFromCentura)+" as ImportanceLevelDesc, 	
		CL.FILELOCATION as FileLocationKey, 	
		TC.DESCRIPTION as FileLocation"

	Set @sFrom = "from EMPLOYEEREMINDER ER
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
						and CE.EVENTNO= ER.EVENTNO
						and CE.CYCLE  = ER.CYCLENO)
		left join EVENTS EV 		on (EV.EVENTNO= ER.EVENTNO)
		left join OPENACTION OA		on (OA.CASEID = CE.CASEID
						and OA.ACTION = EV.CONTROLLINGACTION
						and OA.CYCLE  =(select max(OA1.CYCLE)
								from OPENACTION OA1
								where OA1.CASEID=OA.CASEID
								and OA1.ACTION=OA.ACTION))
		left join EVENTCONTROL EC 	on (EC.CRITERIANO = isnull(OA.CRITERIANO,CE.CREATEDBYCRITERIA)
						and EC.EVENTNO    = CE.EVENTNO)
		left join CASENAME CN 		on (CN.CASEID   = ER.CASEID
						and CN.NAMETYPE = 'O'
						and CN.SEQUENCE = (select min(SEQUENCE)
								   from  CASENAME CN2
								   where CN2.CASEID = ER.CASEID
								   and CN2.NAMETYPE = CN.NAMETYPE))
		left join NAME OWNER 		on (OWNER.NAMENO = CN.NAMENO)
		left join CASENAME CN3 		on (CN3.CASEID   = ER.CASEID
						and CN3.NAMETYPE = 'EMP'
						and CN3.SEQUENCE = (select min(SEQUENCE)
								    from  CASENAME CN2
								    where CN2.CASEID = ER.CASEID
								    and CN2.NAMETYPE = CN3.NAMETYPE))
		left join NAME CASEEMP 		on (CASEEMP.NAMENO = CN3.NAMENO)
		left join CASENAME CN4 		on (CN4.CASEID   = ER.CASEID
						and CN4.NAMETYPE = 'SIG'
						and CN4.SEQUENCE = (select min(SEQUENCE)
								    from  CASENAME CN2
								    where CN2.CASEID = ER.CASEID
								    and CN2.NAMETYPE = CN4.NAMETYPE))
		left join NAME SIG 		on (SIG.NAMENO = CN4.NAMENO)
		left join EVENTCATEGORY ECT	on (ECT.CATEGORYID=EV.CATEGORYID)
		left join ALERT A		on (ER.ALERTNAMENO= A.EMPLOYEENO
						and ER.SEQUENCENO = A.SEQUENCENO
						and ER.EVENTNO IS NULL)
		left join IMPORTANCE IM 	on ( IM.IMPORTANCELEVEL = coalesce( EC.IMPORTANCELEVEL, EV.IMPORTANCELEVEL, A.IMPORTANCELEVEL ) )
		left join CASELOCATION CL 	on (CL.CASEID = ER.CASEID
						and CL.WHENMOVED = (select max( WHENMOVED )
							from CASELOCATION CL1
							where CL1.CASEID = ER.CASEID ))
		left join TABLECODES TC 	on (TC.TABLETYPE = 10 and TC.TABLECODE = CL.FILELOCATION)"	

	Set @sSQLString = @sSelect + char(10) + @sFrom + char(10) + @sWhere
End

If  @nErrorCode = 0 and @pnType = 1
Begin
	-- Comments
	Set @sSQLString = "Select N.NAME + CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' + N.FIRSTNAME END as CommentsOf,
			ER.COMMENTS as Comments	 	
		from	EMPLOYEEREMINDER ER
		join 	EMPLOYEEREMINDER ER2	
				on (ER2.EMPLOYEENO = @nEmployeeNo 
				and ER2.MESSAGESEQ = @dtDateCreated)
		join 	NAME N	on (N.NAMENO = ER.EMPLOYEENO)
		where	ER.COMMENTS IS NOT NULL
		and   ((ER.REFERENCE=ER2.REFERENCE and ER.CASEID is null and ER2.CASEID is null)
		 OR    (ER.REFERENCE  is null  and
			ER2.REFERENCE is null  and
			ER2.CASEID=ER.CASEID   and
			ER2.EVENTNO=ER.EVENTNO and
			ER2.CYCLENO=ER.CYCLENO ))
		order by 1"
End

If @nErrorCode=0 and @pnType = 2
Begin
	-- Designated Countries
	Set @sSelect = "Select 	C.COUNTRY as Country, 	
			CF.FLAGNAME as FlagName"

	Set @sFrom = "from EMPLOYEEREMINDER ER
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
							and CF.FLAGNUMBER=RC.CURRENTSTATUS)"

	Set @sSQLString = @sSelect + char(10) + @sFrom + char(10) + @sWhere + char(10) + "order by 1"		
	
End

If @nErrorCode=0
Begin
	Exec @nErrorCode = sp_executesql @sSQLString,
		N'@nEmployeeNo		int,
		  @dtDateCreated	datetime',
		  @nEmployeeNo		= @nEmployeeNo,
		  @dtDateCreated	= @dtDateCreated
End

Return @nErrorCode
GO

Grant execute on dbo.rmw_ListWorksheetReminder to public
GO
