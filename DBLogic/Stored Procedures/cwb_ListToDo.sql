-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cwb_ListToDo
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cwb_ListToDo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cwb_ListToDo.'
	Drop procedure [dbo].[cwb_ListToDo]
	Print '**** Creating Stored Procedure dbo.cwb_ListToDo...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cwb_ListToDo
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnRowCount		int		= null output,	-- just an example
	@pbCalledFromCentura	bit		= 0	
)
as
-- PROCEDURE:	cwb_ListToDo
-- VERSION:	30
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns details of the Reminders that have been generated for the 
--		Names that have been associated with the logged on user.
--		This stored procedure is only valid where the user is flagged as
--		an external user.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 22 Aug 2003  MF		1	Procedure created
-- 27 Aug 2003	MF		2	Do not pass a NameStyle to the FormatName function so the
--					names returned are in the default format.
-- 28 Aug 2003	MF		3	Assume that all users are external
-- 17 Sep 2003  TM		4	RFC334 To Do Web Part. Format ToName as for an envelope.
--					Extract YourReference similar to cwb_WhatsNew.  
-- 07-Oct-2003	MF	RFC519	5	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 30-Oct-2003	TM	RFC334	6	Change the result set returned by cwb_ListToDo to use CurrentOfficialNumber
--					instead of CurrentOfficialNo so that it matches the dataset defined.
-- 09-Dec-2003	JEK	RFC700	7	Implement EmailAddress, CountryAdjective, PropertyTypeDescription and GoverningEventDescription.
-- 04-Mar-2004	TM	RFC1032	8	Pass NULL as the @pnCaseKey to the fn_FilterUserCases.
-- 10-Mar-2004	TM	RFC868	9	Modify the logic extracting the 'EmailAddress' column to use new Name.MainEmail column.
-- 25-May-2004	TM	RFC907	10	Return EmployeeKey and ReminderDateCreated columns.
-- 15-Sep-2004	TM	RFC886	11	Implement translation.
-- 29 Sep 2004	MF	RFC1846	12	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 22 Nov 2004	TM	RFC1322	13	Add new EventProfileKey column.
-- 24 Jan 2005	TM	RFC1514	14	Report on all reminders, i.e. remove the 'where' clause.
-- 22 Feb 2005	TM	RFC1319	15	Add new IsRead and ReminderCheckSum columns.
-- 15 May 2005	JEK	RFC2508	16	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 30 May 2005	TM	RFC1933	17	Modify to return all EmployeeReminder rows where the EmployeeNo is either in 
--					dbo.fn_FilterUserNames() or is the NameNo for the @pnUserIdentityId. Return two 
--					new columns AdHocNameKey and AdHocDateCreated.
-- 18 Dec 2006	JEK	RFC2982	18	Implement new Instruction Definition rules.
-- 06 Feb 2007	LP	RFC4910	19	Return new RowKey column.
-- 08 Aug 2007	AT	RFC4910	20	Return the Reminder Reply Email site control if no email found against name.
-- 09 Jan 2008	SF	RFC7463	21 	Rowkey must be unique
-- 11 Dec 2008	MF	17136	22	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 16 Jun 2009  LP      RFC8155 23      Return Reminders with a Name Reference.
-- 17 Sep 2010	MF	RFC9777	24	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 11 Feb 2010	SF	RFC9284	25	Return LogDateTimeStamp as LastModified rather than checksum
-- 20 Apr 2011	MF	RFC10333 26	Join EMPLOYEEREMINDER to ALERT using new ALERTNAMENO column which caters for Reminders that
--					have been sent to names that are different to the originating Alert.
-- 13 Sep 2011	ASH	R11175	27	Maintain translation of Reminder Text in Foreign language.
-- 28 Sep 2012	LP	R100763	28	Return CanUpdate and CanDelete flags (always TRUE)
-- 15 Apr 2013	DV	R13270	29	Increase the length of nvarchar to 11 when casting or declaring integer
-- 10 Nov 2015	KR	R53910	30	Adjust formatted names logic (DR-15543)     



SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 			int

Declare @sSQLString1			nvarchar(4000)
Declare @sSQLString2			nvarchar(4000)
Declare @sReminderChecksumColumns	nvarchar(4000)

Declare @sLookupCulture			nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@ErrorCode      = 0
Set 	@pnRowCount	= 0

-- Get the comma separated list of all comparable colums
-- of the EmployeeRemider table
If @ErrorCode=0
Begin
	exec @ErrorCode = dbo.ip_GetComparableColumns
			@psColumns 	= @sReminderChecksumColumns output, 
			@psTableName 	= 'EMPLOYEEREMINDER',
			@psAlias 	= 'ER'
End

-- Get the reminders held in the EMPLOYEEREMINDER table as long as:
-- a) the CASEEVENT associated with the Reminder is still due
-- b) the CASEEVENT is attached to a live OpenAction
-- c) the Status of the Case allows for Reminders to be shown
	
If @ErrorCode=0
Begin
	Set @sSQLString1=
	"Select	distinct"+char(10)+
		"ER.EMPLOYEENO as EmployeeKey,"+char(10)+
		"ER.MESSAGESEQ as ReminderDateCreated,"+char(10)+
		"dbo.fn_FormatNameUsingNameNo(N.NAMENO,COALESCE(N.NAMESTYLE,NN.NAMESTYLE,7101)) as ToName,"+char(10)+
		"N.NAMENO as ToNameKey,"+char(10)+
		"C.CASEID as CaseKey,"+char(10)+
		"C.CURRENTOFFICIALNO as CurrentOfficialNumber,"+char(10)+
		"FC.CLIENTREFERENCENO as 'YourReference',"+char(10)+
		"C.IRN as 'OurReference',"+char(10)+
		+dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+
			" as Title,"+char(10)+
		+ dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','SHORTMESSAGE',null,'ER',@sLookupCulture,@pbCalledFromCentura)+
					" as Message,"+char(10)+
		"CE.EVENTDUEDATE as DueDate,"+char(10)+
		"ER.REMINDERDATE as ReminderDate,"+char(10)+
		+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'CC',@sLookupCulture,@pbCalledFromCentura)+
			" as CountryAdjective,"+char(10)+
		+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+
			" as PropertyTypeDescription,"+char(10)+
		"isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'GEC',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
		         dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")"+char(10)+
				"as GoverningEventDescription,"+char(10)+
		"isnull(dbo.fn_FormatTelecom(M.TELECOMTYPE,M.ISD,M.AREACODE,M.TELECOMNUMBER,M.EXTENSION), SCEMAIL.COLCHARACTER)"+char(10)+ 
				"as EmailAddress,"+char(10)+
		"case when D.CASEID IS NOT NULL then 1 else 0 end AS HasInstructions,"+char(10)+
		"CAST(ER.READFLAG as bit)"+char(10)+
				"as IsRead,"+char(10)+
		"ER.LOGDATETIMESTAMP as LastModified,"+char(10)+
		"null as AdHocNameKey,"+char(10)+
		"null as AdHocDateCreated,"+char(10)+
		"cast(1 as bit) as CanUpdate,"+char(10)+
		"cast(1 as bit) as CanDelete,"+char(10)+
		"cast(ER.EMPLOYEENO as varchar(11))+'^'+convert(varchar(23),ER.MESSAGESEQ ,126)+'^'+cast(CHECKSUM("+@sReminderChecksumColumns+") as varchar(10)) as RowKey"+char(10)+
	"from NAME N"+char(10)+ 
	"join EMPLOYEEREMINDER ER on (ER.EMPLOYEENO=N.NAMENO)"+char(10)+
	-- Reminders are only valid if the CaseEvent is still due
	"join CASEEVENT CE on (CE.CASEID=ER.CASEID"+char(10)+
			  "and CE.EVENTNO=ER.EVENTNO"+char(10)+
			  "and CE.CYCLE=ER.CYCLENO"+char(10)+
			  "and CE.OCCURREDFLAG=0)"+char(10)+
	"join EVENTS EP	on (EP.EVENTNO=CE.EVENTNO)"+char(10)+			
	"join CASES C on (C.CASEID=ER.CASEID)"+char(10)+
	"join dbo.fn_FilterUserCases("+cast(@pnUserIdentityId as varchar(11))+", 1, null) FC"+char(10)+ 
			  "on (FC.CASEID=C.CASEID)"+char(10)+
	"join VALIDPROPERTY VP on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
			      "and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)"+char(10)+
			      "from VALIDPROPERTY VP1"+char(10)+
			      "where VP1.PROPERTYTYPE=VP.PROPERTYTYPE"+char(10)+
			      "and   VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join dbo.fn_FilterUserNames("+cast(@pnUserIdentityId as varchar(11))+", 1) FN"+char(10)+
			"on (FN.NAMENO=ER.EMPLOYEENO)"+char(10)+
	"left join USERIDENTITY UI on (UI.NAMENO=ER.EMPLOYEENO"+char(10)+
				  "and UI.IDENTITYID = "+cast(@pnUserIdentityId as varchar(11))+")"+char(10)+	
	"left join COUNTRY NN on (NN.COUNTRYCODE=N.NATIONALITY)"+char(10)+
	-- Governing Event
	"left join EVENTS E on (E.EVENTNO=CE.GOVERNINGEVENTNO)"+char(10)+
	"left join OPENACTION OA on (OA.CASEID=CE.CASEID"+char(10)+
	"			 and OA.ACTION=E.CONTROLLINGACTION"+char(10)+
	"			 and OA.CYCLE =(select max(OA1.CYCLE)"+char(10)+
	"					from OPENACTION OA1"+char(10)+
	"					where OA1.CASEID=OA.CASEID"+char(10)+
	"					and OA1.ACTION=OA.ACTION))"+char(10)+
	"left join CASEEVENT GCE on (GCE.CASEID=CE.CASEID"+char(10)+
				"and GCE.EVENTNO=E.EVENTNO"+char(10)+
				"and GCE.CYCLE=CE.CYCLE)"+char(10)+
	"left join EVENTCONTROL GEC on (GEC.EVENTNO=GCE.EVENTNO"+char(10)+
				"and GEC.CRITERIANO=isnull(OA.CRITERIANO,GCE.CREATEDBYCRITERIA))"+char(10)+
	"left join COUNTRY CC on (CC.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
	"left join CASENAME CN on (CN.CASEID=C.CASEID"+char(10)+
			      "and CN.NAMETYPE='EMP'"+char(10)+
			      "and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"+char(10)+
	"left join NAME NCN on (NCN.NAMENO=CN.NAMENO)"+char(10)+
	"left join TELECOMMUNICATION M on (M.TELECODE=NCN.MAINEMAIL)"+char(10)+
	"left join (select distinct C.CASEID, D.DUEEVENTNO AS EVENTNO"+char(10)+
	"	   From CASES C"+char(10)+
	"	   cross join INSTRUCTIONDEFINITION D"+char(10)+
	"	   left join CASEEVENT P	on (P.CASEID=C.CASEID"+char(10)+
	"					and P.EVENTNO=D.PREREQUISITEEVENTNO)"+char(10)+
		   -- Available for due events
	"	   where D.AVAILABILITYFLAGS&4=4"+char(10)+
	"	   and	 D.DUEEVENTNO IS NOT NULL"+char(10)+
		   -- Either the instruction has no prerequisite event
		   -- or the prerequisite event exists
	"	   and 	(D.PREREQUISITEEVENTNO IS NULL OR"+char(10)+
	"	         P.EVENTNO IS NOT NULL"+char(10)+
	"		)"+char(10)+
	"	   ) D			on (D.CASEID=CE.CASEID"+char(10)+
	"				and D.EVENTNO=CE.EVENTNO)"+char(10)+
	", SITECONTROL AS SCEMAIL"+CHAR(10)+
	"where (FN.NAMENO is not null or UI.NAMENO is not null)"+char(10)+
	"and SCEMAIL.CONTROLID='Reminder Reply Email'"

	Set @sSQLString2= 
	"UNION ALL"+char(10)+
	"Select	ER.EMPLOYEENO as EmployeeKey,"+char(10)+
		"ER.MESSAGESEQ as ReminderDateCreated,"+char(10)+
		"dbo.fn_FormatNameUsingNameNo(N.NAMENO,COALESCE(N.NAMESTYLE,NN.NAMESTYLE,7101)) as ToName,"+char(10)+
		"N.NAMENO as ToNameKey,"+char(10)+
		"C.CASEID as CaseKey,"+char(10)+
		"C.CURRENTOFFICIALNO as CurrentOfficialNumber,"+char(10)+
		"FC.CLIENTREFERENCENO as 'YourReference',"+char(10)+
		"C.IRN as 'OurReference',"+char(10)+
		+dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+
			" as Title,"+char(10)+
		+ dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','SHORTMESSAGE',null,'ER',@sLookupCulture,@pbCalledFromCentura)+
					" as Message,"+char(10)+
		"A.DUEDATE as DueDate,"+char(10)+
		"ER.REMINDERDATE as ReminderDate,"+char(10)+
		+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'CC',@sLookupCulture,@pbCalledFromCentura)+
			" as CountryAdjective,"+char(10)+
		+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+
			" as PropertyTypeDescription,"+char(10)+
		"null as GoverningEventDescription,"+char(10)+
		"isnull(dbo.fn_FormatTelecom(M.TELECOMTYPE,M.ISD,M.AREACODE,M.TELECOMNUMBER,M.EXTENSION), SCEMAIL.COLCHARACTER)"+char(10)+ 
				"as EmailAddress,"+char(10)+
		"0 as HasInstructions,"+char(10)+
		"CAST(ER.READFLAG as bit)"+char(10)+
				"as IsRead,"+char(10)+
		"ER.LOGDATETIMESTAMP as LastModified,"+char(10)+
		"A.EMPLOYEENO as AdHocNameKey,"+char(10)+
		"A.ALERTSEQ as AdHocDateCreated,"+char(10)+
		"cast(1 as bit) as CanUpdate,"+char(10)+
		"cast(1 as bit) as CanDelete,"+char(10)+
		"cast(ER.EMPLOYEENO as varchar(11))+'^'+convert(varchar(23),ER.MESSAGESEQ ,126)+'^'+cast(CHECKSUM("+@sReminderChecksumColumns+") as varchar(10)) as RowKey"+char(10)+
	"from NAME N"+char(10)+	
	"join EMPLOYEEREMINDER ER on (ER.EMPLOYEENO=N.NAMENO)"+char(10)+
	"join ALERT A on (A.EMPLOYEENO=ER.ALERTNAMENO"+char(10)+
		     "and A.SEQUENCENO=ER.SEQUENCENO"+char(10)+
		     "and ER.EVENTNO IS NULL)"+char(10)+
	"left join dbo.fn_FilterUserNames("+cast(@pnUserIdentityId as varchar(11))+", 1) FN"+char(10)+
		    "on (FN.NAMENO=N.NAMENO)"+char(10)+
	"left join USERIDENTITY UI on (UI.NAMENO=ER.EMPLOYEENO"+char(10)+
				  "and UI.IDENTITYID = "+cast(@pnUserIdentityId as varchar(11))+")"+char(10)+	
	"left join dbo.fn_FilterUserCases("+cast(@pnUserIdentityId as varchar(11))+",1,null) FC"+char(10)+
		    "on (FC.CASEID=ER.CASEID)"+char(10)+
	"left join CASES C on (C.CASEID=FC.CASEID)"+char(10)+	
	"left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				    "and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)"+char(10)+
				    "from VALIDPROPERTY VP1"+char(10)+
				    "where VP1.PROPERTYTYPE=VP.PROPERTYTYPE"+char(10)+
				    "and   VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join COUNTRY NN on (NN.COUNTRYCODE=N.NATIONALITY)"+char(10)+
	"left join COUNTRY CC on (CC.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
	"left join CASENAME CN on (CN.CASEID=C.CASEID"+char(10)+
			      "and CN.NAMETYPE='EMP'"+char(10)+
			      "and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"+char(10)+
	"left join NAME NCN on (NCN.NAMENO=CN.NAMENO)"+char(10)+
	"left join TELECOMMUNICATION M on (M.TELECODE=NCN.MAINEMAIL)"+char(10)+	
	", SITECONTROL AS SCEMAIL"+CHAR(10)+
	"where (FN.NAMENO is not null or UI.NAMENO is not null)"+char(10)+
	"and SCEMAIL.CONTROLID='Reminder Reply Email'"+char(10)+
	"order by ER.REMINDERDATE,CE.EVENTDUEDATE,C.IRN"

	exec (@sSQLString1 + @sSQLString2)

	Select  @ErrorCode=@@Error,
		@pnRowCount=@@Rowcount
End


Return @ErrorCode
GO

Grant execute on dbo.cwb_ListToDo to public
GO
