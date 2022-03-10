-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceSendEmails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceSendEmails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceSendEmails.'
	drop procedure dbo.ip_PoliceSendEmails
end
print '**** Creating procedure dbo.ip_PoliceSendEmails...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceSendEmails  
			@pnDebugFlag		tinyint,
			@pbUpdateFlag		bit	= 0
as
-- PROCEDURE :	ip_PoliceSendEmails 
-- VERSION :	40
-- DESCRIPTION:	A procedure to send emails electronically where required.
-- CALLED BY :	ipu_Policing

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13/07/2001	MF			Procedure created
-- 18/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 20/08/2002	MF	7944		The extended stored procedure xp_sendemail cannot handle NVARCHAR parameters
--					when run in a SQLServer 7 environment
-- 05/11/2002	MF	8158		Alerts that are to be sent by email are not getting the Due Date and Reminder 
--					Date because there is no Event being referenced by the Alert.
-- 06 Nov 2002	MF	8171		Incorporate hyperlink into reminder messages
-- 01 Apr 2003	MF	RFC112		Changes to the generated hyperlinks available for emailed reminders.
-- 28 Jul 2003	MF		10	Standardise version number
-- 10 Nov 2003	MF	9399	11	Allow a user defined SELECT statement to extract header information to be 
--					delivered as part of the email message.
-- 27 Nov 2003	MF	9498	12	Format the embedded dates based on the site control 'Date Style'
-- 28 Nov 2003 	MF	9498 	13	Further correction and allow the default date style to be DD/MM/YYYY
-- 06 Aug 2004	AB	8035	14	Add collate database_default to temp table definitions
-- 02 Jun 2005	RCT	11441	15	Alerts that are to be sent by email are not returning the Alert Message
--					because there is no Event being referenced by the Alert, causing the replace
--					statement for hyperlinks in reminder messages to return a null value. 
-- 06 Jun 2006	MF	12723	16	Allow EMAILHEADER to be null
-- 04 Sep 2006	MF	13167	17	For SQLServer 2005 and above use sp_send_dbmail instead of xp_sendmail if
--					the Sitecontrol "Database Email Profile" has been set.
-- 10 Oct 2006	MF	13167	18	Revisit.  Allow the new "DATABASE EMAIL PROFILE" profile to be independant
--					of the other site controls.
-- 31 May 2007	MF	14812	19	No change required but all procedures being updated.
-- 12 Nov 2007	MF	15340	20	Subject area of generated email is sometimes being left empty. 
-- 30 Jul 2008	MF	16730	21	Reminders delivered via Email should send one email with all recipients 
--					listed who are to receive that reminder.
-- 11 Dec 2008	MF	17136	22	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 09 Nov 2009	MF	18211	23	Provide a new Site Control to allow variations in the formatting of generated email reminders.
-- 18 Nov 2009	MF	18211	24	SQA extended to reformat the Email Subject to concatenate IRN to end of Subject.
-- 07 Jan 2010	MF	18358	25	Incorrect email delivery occurring when the same Event for different cycles on the same Case is
--					generating email reminders.
-- 15 Jun 2010	MF	18812	26	Ensure carriage returns and line feeds are removed from Subject in sp_send_dbmail
-- 28 Jan 2011	MF	R10193	27	EventText being truncated. Convert to nvarchar(max).
-- 12 Sep 2011	MF	19919	28	Use the ALERTDATE as the next reminder date for an ALERT triggered reminder.
-- 12 Jul 2012	DL	R12513	29	Reminder does not send to all recipients as set up in the reminder rule
-- 05 Feb 2013	ASH	R12907	30	Allow reminder email to consider LongMessage if it's not null
-- 26 Feb 2013	MF	R13230	31	The fixed wording embedded in to the generated email needs to be extracted from the database to allow
--					firms to replace with their own language if required.
-- 28 May 2013	MF	R13540	32	Removed reference to xp_SendMail which is unsupported from SQLServer 2012.
-- 28 May 2013	MF	R13535	33	Increase field sizes to allow long messages to be emailed.
-- 05 Jun 2013  AT	R12907	34	Revert all changes from RFC12907 due to introduced bug with multiple reminders.
-- 23 Jan 2014	MF	R13693	35	If Policing is not being run with the UPDATE option on then reminders to be sent by email
--					must not have a reminder date in the future.
-- 06 Jan 2015	MF	R42807	36	The change delivered in RFC13693 has been reversed out.  This was stopping email delivered reminders
--					when Policing was being run on a Friday for the following weekend. Policing is not typically run with 
--					the Update flag turned on for future runs because it may cause the status of the case to change prematurely.
-- 17 Feb 2015	MF	R44776	37	Provide a Policing specific Site Control to determine the date format for email generated reminders.
-- 24 Jun 2015	MF	R48974	38	Separate email profile should be provided for Policing Reminders.
-- 02 Sep 2016	MF	36786	39	Expand EMPLOYEEREMINDER.COMMENTS to nvarchar(max).
-- 14 Nov 2018  AV  75198/DR-45358	40   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on
set concat_null_yields_null off

Create table #TEMPEMAILREMINDERS (
	EMAILSEQNO		int	 identity (1,1),
	IRN			nvarchar(30)	collate database_default	NULL,
	COUNTRY			nvarchar(60)	collate database_default	NULL,
	TITLE			nvarchar(254)	collate database_default	NULL,
	EMAILADDRESS		varchar(max)	collate database_default	NULL,
	EMAILSUBJECT		varchar(255)	collate database_default	NULL,
	EMAILHEADER		varchar(max)	collate database_default	NULL,
	EVENTDESCRIPTION	nvarchar(100)	collate database_default	NULL,
	EVENTTEXT		nvarchar(max)	collate database_default	NULL,
	REMINDER		nvarchar(max)	collate database_default	NULL,
	COMMENTS		nvarchar(max)	collate database_default	NULL,
	DUEDATE			datetime	NULL,
	NEXTREMINDER		datetime	NULL,
	EVENTNO			int		NULL,
	CYCLE			smallint	NULL
)

DECLARE		@ErrorCode		int,
		@nRowCount		int,
		@nDuplicateRows		int,
		@nCurrentRow		int,
		@nDateFormat		tinyint,
		@nEmailFormat		tinyint,
		@sProfileName		varchar(254),
		@sIRN			nvarchar(30),
		@nEventNo		int,
		@nCycle			int,
		@sEmailAddress		varchar(max),
		@sEmailSubject		varchar(255),
		@sEmailBody		varchar(max),
		@sCaseHyperlink		varchar(512),
		@sEventHyperlink	varchar(512),
		@sSQLReminder		varchar(8000),
		@sSQLString		nvarchar(max),
		@sSQLString1		nvarchar(max),		
		@sDateDue		nvarchar(50),
		@sEvent			nvarchar(50),
		@sMessage		nvarchar(50),
		@sText			nvarchar(50),
		@sComments		nvarchar(50),
		@sReminder		nvarchar(50)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode=0

-- Get the default hyerlink address from SiteControl

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select  @sCaseHyperlink =S1.COLCHARACTER,
		@sEventHyperlink=S2.COLCHARACTER
	From SITECONTROL S1
	left join SITECONTROL S2 on (S2.CONTROLID='CASE_EVENTENTRY_HREF')
	Where S1.CONTROLID='CASE_DETAILS_HREF'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sCaseHyperlink	varchar(512)		Output,
				  @sEventHyperlink	varchar(512)		Output',
				  @sCaseHyperlink	=@sCaseHyperlink	Output,
				  @sEventHyperlink	=@sEventHyperlink	Output
End

-- Get the site control that indicates what format of the reminder to use
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select  @nEmailFormat=S1.COLINTEGER
	From SITECONTROL S1
	Where S1.CONTROLID='Email Reminder Format'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nEmailFormat		tinyint			Output',
				  @nEmailFormat		=@nEmailFormat		Output
End

-- Get the site control that indicates that SQLServer Email Profile to use.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select  @sProfileName=S1.COLCHARACTER
	From SITECONTROL S1
	Where S1.CONTROLID='Policing Email Profile'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sProfileName		varchar(254)		Output',
				  @sProfileName		=@sProfileName		Output

	If  @sProfileName is null
	and @ErrorCode=0
	Begin
		-----------------------------------------
		-- Fall back to the generic Email Profile
		-- if a specific Policing profile has
		-- not been provided.
		-----------------------------------------
		Set @sSQLString="
		Select  @sProfileName=S1.COLCHARACTER
		From SITECONTROL S1
		Where S1.CONTROLID='Database Email Profile'"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sProfileName		varchar(254)		Output',
					  @sProfileName		=@sProfileName		Output
	End
End

-- Get the default Date Style from SiteControl and then translate it to the Style used
-- by SQLServer.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @nDateFormat=S.COLINTEGER
	From SITECONTROL S
	Where S.CONTROLID='Email Reminder Date Style'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nDateFormat		tinyint		Output',
				  @nDateFormat		=@nDateFormat	Output

	Set @nDateFormat=CASE @nDateFormat
				WHEN(1)	THEN 106
				WHEN(2) THEN 107
				WHEN(3)	THEN 111
				WHEN(4)	THEN 101
					ELSE 103
			 END
End

-- Get the SELECT statement that will be used to extract the header information 
-- to be included in the Email Reminder.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sSQLReminder=convert(varchar(8000),SQL_QUERY)
	From SITECONTROL S
	join ITEM I on (I.ITEM_NAME=S.COLCHARACTER)
	Where S.CONTROLID='Email Reminder Heading'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sSQLReminder		varchar(8000)	Output',
				  @sSQLReminder=@sSQLReminder		Output
End

-- Note : Deliberately not using a CURSOR to loop through rows because it causes Recompile

If @ErrorCode = 0
Begin
	Set @sSQLString="
	insert into #TEMPEMAILREMINDERS (IRN, EVENTNO,CYCLE,EMAILADDRESS, EMAILSUBJECT, EVENTDESCRIPTION,EVENTTEXT,REMINDER,COMMENTS,DUEDATE,NEXTREMINDER,TITLE,COUNTRY)
	select DISTINCT
	C.IRN, 
	TR.EVENTNO,
	TR.CYCLENO,
	T.TELECOMNUMBER,
	CASE WHEN(@nEmailFormat=1)
		THEN
			substring(coalesce(TR.EMAILSUBJECT,TR.EVENTDESCRIPTION,ISNULL(TR.LONGMESSAGE,TR.SHORTMESSAGE),'') 
			+ CASE WHEN(C.IRN is NOT NULL) THEN ': '+rtrim(C.IRN) ELSE '' END,1,255)
		ELSE
			substring(isnull(rtrim(C.IRN),'') + CASE WHEN(C.IRN is NOT NULL) THEN ': ' ELSE '' END 
			+ coalesce(TR.EMAILSUBJECT,TR.EVENTDESCRIPTION,ISNULL(TR.LONGMESSAGE,TR.SHORTMESSAGE),''),1,255)
	END,
	TR.EVENTDESCRIPTION,
	isnull(convert(nvarchar(max),CE.EVENTLONGTEXT), CE.EVENTTEXT),
	-- Replace embedded variables with the hyperlink as required
	replace(replace(ISNULL(TR.LONGMESSAGE,TR.SHORTMESSAGE),'<<CASE_DETAILS_HREF>>',                   replace(@sCaseHyperlink, '<CaseKey>',convert(varchar(11),isnull(TR.CASEID, '')))),
					'<<CASE_EVENTENTRY_HREF>>',replace(replace(replace(@sEventHyperlink,'<CaseKey>',convert(varchar(11),isnull(TR.CASEID, ''))),'<EventKey>',convert(varchar(11),isnull(TR.EVENTNO, ''))),'<Cycle>',convert(varchar(6),isnull(TR.CYCLENO, '')))),
	convert(nvarchar(max),ER.COMMENTS),
	isnull(CE.EVENTDUEDATE, ER.DUEDATE),
	isnull(CE.DATEREMIND, A.ALERTDATE),
	C.TITLE,
	CT.COUNTRY
	from #TEMPEMPLOYEEREMINDER TR
	     join NAMETELECOM NT 	on (NT.NAMENO       =TR.NAMENO)
	     join TELECOMMUNICATION T	on (T.TELECODE      =NT.TELECODE
					and T.TELECOMTYPE   =1903)
	left join CASES C		on (C.CASEID=TR.CASEID)
	left join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
	left join CASEEVENT CE		on (CE.CASEID =TR.CASEID
					and CE.CYCLE  =TR.CYCLENO
					and CE.EVENTNO=TR.EVENTNO)
	left join ALERT A		on (A.EMPLOYEENO=TR.NAMENO
					and A.ALERTSEQ  =TR.ALERTSEQ)
	left join EMPLOYEEREMINDER ER	on ( ER.EMPLOYEENO=TR.NAMENO
					and (ER.CASEID    =TR.CASEID    or (TR.CASEID    is null and ER.CASEID    is null))
					and (ER.EVENTNO   =TR.EVENTNO   or (TR.EVENTNO   is null and ER.EVENTNO   is null))
					and (ER.CYCLENO   =TR.CYCLENO   or (TR.CYCLENO   is null and ER.CYCLENO   is null))
					and (ER.REFERENCE =TR.REFERENCE or (TR.REFERENCE is null and ER.REFERENCE is null))
					and  ER.SEQUENCENO=TR.SEQUENCENO)
			
	where 	TR.SENDELECTRONICALLY 	=1
	and	T.REMINDEREMAILS	=1
	and	T.TELECOMNUMBER is not null"
	
	-------------------------------------------------
	-- RFC42807 
	-- Following code commented out because it was
	-- blocking emailed reminders being sent.
	---- RFC13693
	---- If the Event Dates are not being updated
	---- then reminders to be generated by email must
	---- not have a future reminder date.
	-------------------------------------------------
	--If isnull(@pbUpdateFlag,0)=0
	--	Set @sSQLString=@sSQLString+CHAR(10)+"	and	TR.REMINDERDATE<=getdate()"
		
		
	Set @sSQLString=@sSQLString+CHAR(10)+"	order by 1,2,3,5,6,9,4"     -- RFC12513 add order by reminder COMMENTS so that duplicate reminders are skipped correctly

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sCaseHyperlink	varchar(512),
				  @sEventHyperlink	varchar(512),
				  @nDateFormat		tinyint,
				  @nEmailFormat		tinyint',
				  @sCaseHyperlink	=@sCaseHyperlink,
				  @sEventHyperlink	=@sEventHyperlink,
				  @nDateFormat		=@nDateFormat,
				  @nEmailFormat		=@nEmailFormat

End

-- Now extract the header information for the Email if one has been defined

If  @ErrorCode=0
and @sSQLReminder is not null
Begin
	Set @sSQLReminder=replace(@sSQLReminder,':gstrEntryPoint','T.IRN')

	exec("
	Update #TEMPEMAILREMINDERS
	Set EMAILHEADER=("+@sSQLReminder+")
	From #TEMPEMAILREMINDERS T")
	
	Set @ErrorCode=@@Error
End

-- Get the number of rows inserted

If @ErrorCode=0
Begin
	Set @sSQLString="
	select	@nRowCountOUT=count(*)
	from	#TEMPEMAILREMINDERS"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nRowCountOUT	int OUTPUT',
					  @nRowCountOUT=@nRowCount OUTPUT
End

If @nRowCount>0
and @ErrorCode=0
Begin
	---------------------------------------------------
	-- RFC 13230
	-- If emails are to be generated then extract the
	-- fixed wording to be used that has been defined
	-- by the firm. This allows for language variations
	-- for the following literals:
	--	Date Due
	--	Event
	--	Message
	--	Event Text
	--	Comments
	--	Next Reminder Date
	---------------------------------------------------
	
	Set @sDateDue=isnull((	Select TC.DESCRIPTION
				from TABLECODES TC
				where TC.TABLETYPE=-509
				and TC.TABLECODE=-42846993),'Date Due')
	
	Set @sEvent=isnull((	Select TC.DESCRIPTION
				from TABLECODES TC
				where TC.TABLETYPE=-509
				and TC.TABLECODE=-42846994),'Event')
	
	Set @sMessage=isnull((	Select TC.DESCRIPTION
				from TABLECODES TC
				where TC.TABLETYPE=-509
				and TC.TABLECODE=-42846995),'Message')
	
	Set @sText=isnull((	Select TC.DESCRIPTION
				from TABLECODES TC
				where TC.TABLETYPE=-509
				and TC.TABLECODE=-42846996),'Text')
	
	Set @sComments=isnull((	Select TC.DESCRIPTION
				from TABLECODES TC
				where TC.TABLETYPE=-509
				and TC.TABLECODE=-42846997),'Comments')
	
	Set @sReminder=isnull((	Select TC.DESCRIPTION
				from TABLECODES TC
				where TC.TABLETYPE=-509
				and TC.TABLECODE=-42846998),'Next Reminder Date')
End

set @nCurrentRow=1

while @nCurrentRow<=@nRowCount
and  @ErrorCode=0
begin
	If @nEmailFormat=1
	Begin
		Set @sSQLString1="
			@sEmailBody	=                                                     '"+@sDateDue+": ' + convert(nvarchar(12), DUEDATE,     @nDateFormat)+CHAR(10)
						+CASE WHEN(IRN is not null) THEN convert(nchar(31),IRN) + convert(nchar(31),COUNTRY) + ' ' + TITLE +CHAR(10) ELSE '' END
						+CASE WHEN(EVENTDESCRIPTION is not null) THEN '"+@sEvent+": '  +EVENTDESCRIPTION+CHAR(10)
						                                         ELSE '"+@sMessage+": '+REMINDER+CHAR(10) END
						+CASE WHEN(EVENTTEXT        is not null) THEN '"+@sText+": '+EVENTTEXT       +CHAR(10) ELSE '' END
						+CASE WHEN(EMAILHEADER is not null) THEN CHAR(10)+EMAILHEADER+CHAR(10) ELSE '' END"
	End
	Else Begin
		Set @sSQLString1="
			@sEmailBody	=        CASE WHEN(EMAILHEADER is not null) THEN EMAILHEADER+CHAR(10) ELSE '' END
						+CASE WHEN(EVENTDESCRIPTION is not null) THEN '"+@sEvent+":              '+EVENTDESCRIPTION+CHAR(10) ELSE '' END
						+CASE WHEN(EVENTTEXT        is not null) THEN '"+@sText+":         '+EVENTTEXT       +CHAR(10) ELSE '' END
						+                                             '"+@sMessage+":            '+REMINDER        +CHAR(10)
						+CASE WHEN(COMMENTS         is not null) THEN '"+@sComments+":           '+COMMENTS+CHAR(10) ELSE '' END
						+                                             '"+@sDateDue+":           ' + convert(nvarchar(12), DUEDATE,     @nDateFormat)+CHAR(10)
						+                                             '"+@sReminder+": ' + convert(nvarchar(12), NEXTREMINDER,@nDateFormat)+CHAR(10)"
	End
	
	Set @sSQLString="
	Select	@sEmailAddress	=EMAILADDRESS, 
		@sIRN		=IRN,
		@nEventNo	=EVENTNO,
		@nCycle		=CYCLE,
		@sEmailSubject	=EMAILSUBJECT,"+char(10)+
	@sSQLString1+"
	From #TEMPEMAILREMINDERS
	where EMAILSEQNO=@nCurrentRow"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sEmailAddress	nvarchar(max)	OUTPUT, 
				  @sIRN			nvarchar(30)	OUTPUT,
				  @nEventNo		int		OUTPUT,
				  @nCycle		int		OUTPUT,
				  @sEmailSubject	nvarchar(255)	OUTPUT,
				  @sEmailBody		nvarchar(max)	OUTPUT,
				  @nCurrentRow		int,
				  @nDateFormat		tinyint',
				  @sEmailAddress	=@sEmailAddress	OUTPUT, 
				  @sIRN			=@sIRN		OUTPUT,
				  @nEventNo		=@nEventNo	OUTPUT,
				  @nCycle		=@nCycle	OUTPUT,
				  @sEmailSubject	=@sEmailSubject	OUTPUT,
				  @sEmailBody		=@sEmailBody	OUTPUT,
				  @nCurrentRow		=@nCurrentRow,
				  @nDateFormat		=@nDateFormat
	
	If @ErrorCode=0
	Begin
		-- Get a concatenated list of EmailAddress(es) separated by a semi colon where the
		-- same message is being sent to multiple recipients for the same Case.
		
		Set @sSQLString="
		Select	@sEmailAddress=@sEmailAddress+';'+isnull(EMAILADDRESS,'')
		from #TEMPEMAILREMINDERS
		where IRN=@sIRN
		and (EVENTNO     =@nEventNo      OR (EVENTNO      is null and @nEventNo      is null))
		and (CYCLE       =@nCycle        OR (CYCLE        is null and @nCycle        is null))
		and (EMAILSUBJECT=@sEmailSubject OR (EMAILSUBJECT is null and @sEmailSubject is null))
		and " + @sSQLString1 + "
		and EMAILSEQNO>@nCurrentRow"
	
		exec @ErrorCode=sp_executesql @sSQLString,
				N'@sEmailAddress	nvarchar(max)	OUTPUT, 
				  @sIRN			nvarchar(30),
				  @nEventNo		int,
				  @nCycle		int,
				  @sEmailSubject	nvarchar(255),
				  @sEmailBody		nvarchar(max),
				  @nCurrentRow		int,
				  @nDateFormat		tinyint',
				  @sEmailAddress	=@sEmailAddress	OUTPUT, 
				  @sIRN			=@sIRN,
				  @nEventNo		=@nEventNo,
				  @nCycle		=@nCycle,
				  @sEmailSubject	=@sEmailSubject,
				  @sEmailBody		=@sEmailBody,
				  @nCurrentRow		=@nCurrentRow,
				  @nDateFormat		=@nDateFormat
		
		Set @nDuplicateRows=@@rowcount
	End
	
	If @ErrorCode=0
	Begin
		-- If the @sProfileName has been set then this indicates that the firm
		-- is running SQLServer 2005 or higher and has elected to use sp_send_dbmail
		if @sProfileName is not null
		begin
			-- Remove an carriage returns and line feeds 
			-- by replacing with a space. These cause a
			-- problem when using sp_send_dbmail.

			set @sEmailSubject = replace(replace(replace(@sEmailSubject,char(13),' '),char(10),' '),'  ',' ')
			
			exec msdb.dbo.sp_send_dbmail
				@profile_name = @sProfileName,
				@recipients   = @sEmailAddress, 
				@subject      = @sEmailSubject, 
				@body         = @sEmailBody	
		end

		Set @ErrorCode=@@error
	End

	Set @nCurrentRow=@nCurrentRow + @nDuplicateRows + 1
end	

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceSendEmails',0,1,@sTimeStamp ) with NOWAIT
End

drop table #TEMPEMAILREMINDERS

return @ErrorCode
go

grant execute on dbo.ip_PoliceSendEmails   to public
go

