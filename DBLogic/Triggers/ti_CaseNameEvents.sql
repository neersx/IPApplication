if exists (select * from sysobjects where type='TR' and name = 'ti_CaseNameEvents')
begin
	PRINT 'Refreshing trigger ti_CaseNameEvents...'
	DROP TRIGGER ti_CaseNameEvents
end
go

CREATE TRIGGER ti_CaseNameEvents
ON CASENAME
FOR INSERT NOT FOR REPLICATION AS
-- TRIGGER:	ti_CaseNameEvents  
-- VERSION:	15
-- DESCRIPTION:	When a CASENAME row is inserted check if any CASEEVENT rows for 
--		the same case can be updated to point to that NameNo.
--		Also check if there are EmployeeReminders that may need to be moved.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15-Sep-2009	MF	SQA17983 1	Procedure created
-- 29-Mar-2010	MF	SQA18463 2	Insertion of a CASENAME may mean that previously sent EMPLOYEEREMINDERS should
--					now also be sent to the new CASENAME. On deleteion of a CASENAME the 
--					EMPLOYEREMINDERS will not be deleted as the deletion of the CASENAME may occur
--					before insertion of a replacement CASENAME and we require the previous
--					EMPLOYEEREMINDERS row to copy from.
-- 30-Jul-2010	MF	SQA18955 3	Duplicate key error occuring on insert into EMPLOYEEREMINDER where an identical 
--					reminder existed for 2 different employees with exactly the same time stamp.
-- 10-Aug-2010	MF	SQA18955 4	Revisit. Still more circumstances where duplicates can occur.
-- 12-Aug-2010	MF	SQA18955 5	Revisit. Failed testing on global name change.
-- 26-Nov-2010	MF	RFC10012 6	When a Name is inserted against a Case this will cause EMPLOYEEREMINDERs to be 
--					inserted for the new name.  Remove any existing EMPLOYEEREMINDER rows for the Case
--					that no longer exist against the Case where the Reminder rule only delivers reminders
--					to names that are explicitly held against the Case.
-- 09-May-2011	MF	R10591 7	There were some situations where the EMPLOYEEREMINDER that was just copied to another
--					name were not being removed from the name it was originally against.
-- 29-Sep-2011	MF	R11357	8	Do not remove a reminder from a Name where the Reminder rule directs the Reminder explicitly
--					to that Name even if the Name is not associated with the Case.
-- 01-Feb-2012	MF	R11868	9	Do not rely on the CREATEDBYCRITERIA on CASEEVENT to determine if there is a rule that indicates
--					the responsible NameType.
-- 26 Jun 2012	MF	R12201	10	Alerts that are directed to a recipient based on rules stored against the Alert can
--					be created when a CaseName with a matching NameType is inserted again the Case. 
-- 17 Jul 2017	MF	71944	11	Cater for reminders whose message is longer than 254 characters.
-- 22 Nov 2017	MF	R72408	12	Taking a less conservative approach and removing EMPLOYEEREMINDER rows if the Name is no longer a recipient of the Reminder,
--					even if they are still attached to the Case with some other NameType. I am deliberately ignoring multiple NameTypes heldd in 
--					REMINDERS.EXTENDEDNAMETYPE as this would caused significant performance implications within the trigger.
-- 17 Jul 2018	MF	74573	13	Duplicate key error on ALERT table where the Case has multiple ALERT rows for different employeeno with identical ALERTSEQ.
-- 30 Aug 2018	MF	74894	14	Duplicate key error on EMPLOYEEREMINDER table where the Case has multiple ALERT rows for different employeeno with identical ALERTSEQ.
-- 31 Jan 2019	MF	DR-46796 15	Revisit RFC 74573 to correct join ALERT table

	declare @tbEmployeeReminder	table (
			EMPLOYEENO	int		not null,
			MESSAGESEQ	datetime	not null,
			CASEID		int		not null,
			EVENTNO		int		null,
			CYCLENO		int		null,
			DUEDATE		datetime	null,
			REMINDERDATE	datetime	null,
			REMINDERMESSAGE	nvarchar(max)	collate database_default not null,
			ALERTNAMENO	int		null,
			SEQUENCENO	int		null,
			SOURCE		tinyint		null  )

	Declare @nRowCount		int
	Declare @nAlertCount		int
	Declare @nErrorCode		int

	Update CE
	Set EMPLOYEENO=CN.NAMENO,
	    DUEDATERESPNAMETYPE=NULL
	from inserted i
	join OPENACTION OA   on (OA.CASEID=i.CASEID
			     and OA.POLICEEVENTS=1)
	join EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO
			     and EC.DUEDATERESPNAMETYPE=i.NAMETYPE)
	join CASEEVENT CE    on (CE.CASEID=i.CASEID
			     and CE.EVENTNO=EC.EVENTNO
			     and CE.EMPLOYEENO is null)
	join CASENAME CN     on (CN.CASEID=i.CASEID
			     and CN.NAMETYPE=i.NAMETYPE
			     and CN.SEQUENCE=(select min(CN1.SEQUENCE)
					      from CASENAME CN1
					      where CN1.CASEID=CN.CASEID
					      and CN1.NAMETYPE=CN.NAMETYPE
					      and CN1.EXPIRYDATE is null))
	where CE.OCCURREDFLAG=0
	
	set @nErrorCode=@@Error
	------------------------------------------------------
	-- Insert EMPLOYEEREMINDER for recipient that matches
	-- the inserted Name where a reminder rule exists
	-- for the NameType and an EMPLOYEEREMINDER for a
	-- different Name already exists.
	------------------------------------------------------
	If @nErrorCode=0
	Begin
		Insert into @tbEmployeeReminder(EMPLOYEENO,MESSAGESEQ,CASEID,EVENTNO,CYCLENO,DUEDATE,REMINDERDATE,REMINDERMESSAGE,SOURCE)
		select distinct i.NAMENO,R.MESSAGESEQ,R.CASEID,R.EVENTNO,R.CYCLENO,R.DUEDATE,R.REMINDERDATE,R.REMINDERMESSAGE,0
		from inserted i
		join OPENACTION OA	on (OA.CASEID=i.CASEID
					and OA.POLICEEVENTS=1)
		join REMINDERS M	on (M.CRITERIANO=OA.CRITERIANO
					and M.RELATIONSHIP is null
					and((M.EMPLOYEEFLAG=1  and i.NAMETYPE='EMP') OR
					    (M.SIGNATORYFLAG=1 and i.NAMETYPE='SIG') OR
					    (M.NAMETYPE=i.NAMETYPE)))
		join (	Select CASEID, EVENTNO, CYCLENO, min(REMINDERDATE) as REMINDERDATE, 
				min(CASE WHEN(SHORTMESSAGE is null) THEN cast(LONGMESSAGE as nvarchar(max)) ELSE SHORTMESSAGE END) 
						as REMINDERMESSAGE, 
				min(DUEDATE)	as DUEDATE, 
				min(MESSAGESEQ) as MESSAGESEQ
			from EMPLOYEEREMINDER
			where SOURCE=0
			and isnull(LONGMESSAGE, SHORTMESSAGE) is not null
			group by CASEID, EVENTNO, CYCLENO) R
				on (R.CASEID=OA.CASEID
				and R.EVENTNO=M.EVENTNO)

		Select @nRowCount =@@Rowcount,
		       @nErrorCode=@@ERROR
	End
	------------------------------------------------------
	-- Insert EMPLOYEEREMINDER for recipient that matches
	-- the inserted Name where a reminder rule exists
	-- for the NameType and an EMPLOYEEREMINDER for a
	-- different Name already exists.
	-- Allow for possibility of an Alert for a Case being
	-- against multiple employees.
	------------------------------------------------------
	If @nErrorCode=0
	Begin
		with CTE_ALERT (ALERTSEQ, CASEID, EMPLOYEENO)
		as (	select ALERTSEQ, CASEID, min(EMPLOYEENO)
			from ALERT
			group by ALERTSEQ, CASEID
			)
		Insert into @tbEmployeeReminder(EMPLOYEENO,MESSAGESEQ,CASEID,EVENTNO,CYCLENO,DUEDATE,REMINDERDATE,REMINDERMESSAGE,SOURCE, ALERTNAMENO, SEQUENCENO)
		select distinct i.NAMENO,A.ALERTSEQ,i.CASEID,A.EVENTNO,A.CYCLE,A.DUEDATE,A.ALERTDATE,A.ALERTMESSAGE,1, i.NAMENO, A.SEQUENCENO
		from inserted i
		join ALERT A		on  (A.CASEID=i.CASEID
					and((A.EMPLOYEEFLAG=1  and i.NAMETYPE='EMP') OR
					    (A.SIGNATORYFLAG=1 and i.NAMETYPE='SIG') OR
					    (A.NAMETYPE=i.NAMETYPE)))
		join CTE_ALERT CTE	on (CTE.ALERTSEQ  =A.ALERTSEQ
					and CTE.EMPLOYEENO=A.EMPLOYEENO
					and CTE.CASEID    =A.CASEID)
		----------------------------------
		-- Don't insert a row if the newly
		-- insert name already has a
		-- matching Alert against it.
		----------------------------------
		left join ALERT A1	on (A1.EMPLOYEENO=i.NAMENO
					and A1.ALERTSEQ  =A.ALERTSEQ
					and A1.CASEID    =i.CASEID
					and A1.SEQUENCENO=A.SEQUENCENO)
		----------------------------------
		-- Don't insert a row if the newly
		-- inserted name already has an 
		-- Employee Reminder for the Case,
		-- Event and CycleNo.
		----------------------------------
		left join EMPLOYEEREMINDER R
					on (R.EMPLOYEENO <>i.NAMENO
					and R.CASEID      =i.CASEID
					and A.ALERTMESSAGE LIKE isnull(R.LONGMESSAGE, R.SHORTMESSAGE)
					and R.ALERTNAMENO =i.NAMENO
					and R.SEQUENCENO  =A.SEQUENCENO)
		where R.CASEID is null
		and  A1.EMPLOYEENO is null
		
		Select @nAlertCount=@@ROWCOUNT,
		       @nErrorCode =@@ERROR
	End
	
	If @nAlertCount>0
	and @nErrorCode=0
	Begin
		----------------------------------------------
		-- Now create an ALERT for the new CASENAME
		-- where the NAMETYPE matches an existing
		-- ALERT that has defined a rule for determing
		-- the recipient of reminders.
		-- And there is an ALERTDATE.
		----------------------------------------------
		Insert into ALERT (	
				EMPLOYEENO, ALERTSEQ, CASEID, ALERTMESSAGE, REFERENCE, ALERTDATE, DUEDATE, 
				DATEOCCURRED, OCCURREDFLAG, DELETEDATE, STOPREMINDERSDATE, MONTHLYFREQUENCY,
				MONTHSLEAD, DAILYFREQUENCY, DAYSLEAD, SEQUENCENO, SENDELECTRONICALLY, EMAILSUBJECT, NAMENO, EMPLOYEEFLAG, SIGNATORYFLAG,
				CRITICALFLAG, NAMETYPE, RELATIONSHIP, TRIGGEREVENTNO, EVENTNO, CYCLE, IMPORTANCELEVEL)
		select DISTINCT i.NAMENO, A.ALERTSEQ, A.CASEID, A.ALERTMESSAGE, A.REFERENCE, A.ALERTDATE, A.DUEDATE, A.DATEOCCURRED, A.OCCURREDFLAG, 
				A.DELETEDATE, A.STOPREMINDERSDATE, A.MONTHLYFREQUENCY, A.MONTHSLEAD, A.DAILYFREQUENCY, A.DAYSLEAD, A.SEQUENCENO, 
				A.SENDELECTRONICALLY, A.EMAILSUBJECT, NULL, A.EMPLOYEEFLAG, A.SIGNATORYFLAG, A.CRITICALFLAG, A.NAMETYPE, A.RELATIONSHIP, A.TRIGGEREVENTNO, A.EVENTNO, A.CYCLE, A.IMPORTANCELEVEL
		from inserted i
		     join ALERT A	on ( A.CASEID=i.CASEID
					and((A.EMPLOYEEFLAG =1 and i.NAMETYPE='EMP')
					 or (A.SIGNATORYFLAG=1 and i.NAMETYPE='SIG')
					 or (A.NAMETYPE     =i.NAMETYPE)))
		left join ALERT A1	on (A1.EMPLOYEENO=i.NAMENO
					and A1.ALERTSEQ  =A.ALERTSEQ)			 
		where  A.LETTERNO   is null
		and    A.ALERTDATE  is not null		-- Only bring across ALERT rows that are still active
		and   A1.EMPLOYEENO is null
			----------------------------------------
			-- Safeguard against the possibility of 
			-- more than one ALERT for the same Case
			-- with identical ALERTSEQ
			----------------------------------------
		and   A.EMPLOYEENO=(select min(A2.EMPLOYEENO)
				    from ALERT A2
				    where A2.CASEID=A.CASEID
				    and   A2.ALERTSEQ=A.ALERTSEQ
				    and   isnull(A2.EMPLOYEEFLAG,0) =isnull(A.EMPLOYEEFLAG,0)
				    and   isnull(A2.SIGNATORYFLAG,0)=isnull(A.SIGNATORYFLAG,0)
				    and   isnull(A2.NAMENO,'')      =isnull(A.NAMENO,''))
		
		Set @nErrorCode=@@ERROR
	End

	Set @nRowCount=@nRowCount+@nAlertCount
	
	If @nRowCount>0
	and @nErrorCode=0
	begin
		Insert into EMPLOYEEREMINDER(EMPLOYEENO,MESSAGESEQ,CASEID,EVENTNO,CYCLENO,DUEDATE,REMINDERDATE,READFLAG,SOURCE,HOLDUNTILDATE,DATEUPDATED,SHORTMESSAGE,LONGMESSAGE,COMMENTS,SEQUENCENO,ALERTNAMENO)
		select T.EMPLOYEENO,T.MESSAGESEQ,T.CASEID,T.EVENTNO,T.CYCLENO,T.DUEDATE,T.REMINDERDATE,0,T.SOURCE,null,getdate(),
			CASE WHEN(LEN(T.REMINDERMESSAGE)<255) THEN T.REMINDERMESSAGE END,
			CASE WHEN(LEN(T.REMINDERMESSAGE)>254) THEN T.REMINDERMESSAGE END,
			null,
			0,
			T.ALERTNAMENO
		from @tbEmployeeReminder T
		-- Don't insert a row if the newly
		-- inserted name already has an 
		-- Employee Reminder for the Case,
		-- Event and CycleNo.
		left join EMPLOYEEREMINDER R
					on (R.CASEID    =T.CASEID
					and R.EMPLOYEENO=T.EMPLOYEENO
					and R.REFERENCE is null
					and R.EVENTNO=T.EVENTNO
					and R.CYCLENO=T.CYCLENO)
		where R.CASEID is null
		and T.SOURCE=0
		UNION
		select  T.EMPLOYEENO,T.MESSAGESEQ,T.CASEID,T.EVENTNO,T.CYCLENO,T.DUEDATE,T.REMINDERDATE,0,T.SOURCE,null,getdate(),
			CASE WHEN(LEN(T.REMINDERMESSAGE)<255) THEN T.REMINDERMESSAGE END,
			CASE WHEN(LEN(T.REMINDERMESSAGE)>254) THEN T.REMINDERMESSAGE END,
			null,
			T.SEQUENCENO,
			T.ALERTNAMENO
		from @tbEmployeeReminder T
		-----------------------------------
		-- Don't insert a row if the newly
		-- inserted name already has an 
		-- Employee Reminder generated from
		-- the ALERT
		-----------------------------------
		left join EMPLOYEEREMINDER R
					on (R.CASEID    =T.CASEID
					and R.EMPLOYEENO=T.EMPLOYEENO
					and R.REFERENCE is null
					and R.ALERTNAMENO=T.ALERTNAMENO
					and R.SEQUENCENO =T.SEQUENCENO)
		where R.CASEID is null
		and T.SOURCE=1
		
		Set @nErrorCode=@@ERROR

		-------------------------------------------------------
		-- Delete EMPLOYEEREMINDER for recipient whose CaseName
		-- has been removed and the reminder has already
		-- been copied to another Name.
		------------------------------------------------------
		If @nErrorCode=0
		Begin
			Delete ER
			from @tbEmployeeReminder T
			join EMPLOYEEREMINDER ER
						on (ER.EMPLOYEENO <>T.EMPLOYEENO
						and ER.CASEID      =T.CASEID
						and ER.EVENTNO     =T.EVENTNO
						and ER.CYCLENO     =T.CYCLENO
						and T.REMINDERMESSAGE LIKE isnull(ER.LONGMESSAGE, ER.SHORTMESSAGE))
			left join SITECONTROL SC
						on (SC.CONTROLID ='Critical Reminder'
						and SC.COLINTEGER=ER.EMPLOYEENO)

			where T.SOURCE=0
			----------------------------------------------------
			-- Do not delete the reminder if :
			-- a) Reminder has explicitly directed the reminder 
			--    to the name in question;
			-- b) The Name is marked to receive Critical 
			--    Reminders and the reminder is flagged as such;
			-- c) The Reminder is directed to go to a Name
			--    relationship.
			----------------------------------------------------
			and not exists
			(select 1
			 from OPENACTION OA
			 join REMINDERS R on (R.CRITERIANO    =OA.CRITERIANO
					  and R.EVENTNO       =ER.EVENTNO
					  and(R.REMINDEMPLOYEE=ER.EMPLOYEENO
					   OR R.RELATIONSHIP is not null
					   OR(R.CRITICALFLAG=1 and SC.CONTROLID is not null)))
			 where OA.CASEID=ER.CASEID
			 and OA.POLICEEVENTS=1)

			----------------------------------------------
			-- Do not delete the EMPLOYEEREMINDER if name
			-- receiving reminder still exists against the
			-- Case, with a NameType that should receive
			-- the reminder for the Event.
			----------------------------------------------
			 and not exists
			 (select 1
			  from CASENAME CN
			  join OPENACTION OA  on ( OA.CASEID      =ER.CASEID
					      and  OA.POLICEEVENTS=1)
			  join REMINDERS M1   on ( M1.CRITERIANO=OA.CRITERIANO
					      and  M1.EVENTNO   =ER.EVENTNO
					      and  M1.RELATIONSHIP is null
					      and((M1.EMPLOYEEFLAG =1 and CN.NAMETYPE='EMP') OR
						  (M1.SIGNATORYFLAG=1 and CN.NAMETYPE='SIG') OR
						  (M1.NAMETYPE     =CN.NAMETYPE)))
			  where CN.CASEID=ER.CASEID
			  and   CN.NAMENO=ER.EMPLOYEENO)
			 
			 Set @nErrorCode=@@ERROR
		End

		-------------------------------------------------------
		-- Delete EMPLOYEEREMINDER for recipient whose CaseName
		-- has been removed and the reminder has already
		-- been copied to another Name.
		------------------------------------------------------
		If @nErrorCode=0
		Begin
			Delete ER
			from @tbEmployeeReminder T
			join EMPLOYEEREMINDER ER
						on (ER.EMPLOYEENO <>T.EMPLOYEENO
						and ER.CASEID      =T.CASEID
						and ER.ALERTNAMENO =T.ALERTNAMENO
						and ER.SEQUENCENO  =T.SEQUENCENO)
			-- Only delete the reminder if the name
			-- it is against does not exist against
			-- the Case in any way.
			left join CASENAME CN	on (CN.CASEID     =ER.CASEID
						and CN.NAMENO     =ER.EMPLOYEENO)
			where CN.CASEID is null
			and T.SOURCE=1
			
			Set @nErrorCode=@@ERROR
		End
	End
go