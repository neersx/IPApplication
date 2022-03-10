if exists (select * from sysobjects where type='TR' and name = 'tu_CaseNameEvents')
begin
	PRINT 'Refreshing trigger tu_CaseNameEvents...'
	DROP TRIGGER tu_CaseNameEvents
end
go

CREATE TRIGGER tu_CaseNameEvents
ON CASENAME
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	tu_CaseNameEvents  
-- VERSION:	12
-- DESCRIPTION:	On change of NAMENO on CASENAME, any CASEEVENT rows for due dates that
--		point to the NameNo being changed for the Case will be updated.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15-Sep-2009	MF	17983	1	Procedure created
-- 29-Mar-2010	MF	18463	2	Update of a CASENAME where NAMENO is changed should cause EMPLOYEEREMINDERS
--					to be moved to the new NameNo where the specific Reminder was associated
--					with the NameType being updated.
-- 05-Aug-2010	MF	18955	3	Duplicate key error occuring on insert into EMPLOYEEREMINDER where an identical 
--					reminder existed for 2 different employees with exactly the same time stamp.
-- 10-Aug-2010	MF	18955	4	Revisit. Still more circumstances where duplicates can occur.
-- 12-Aug-2010	MF	18955	5	Revisit. Failed testing on global name change.
-- 13-Sep-2011	MF	19990	6	There were some situations where the EMPLOYEEREMINDER that was just copied to another
--					name were not being removed from the name it was originally against.
-- 29-Sep-2011	MF	R11357	7	Do not remove a reminder from a Name where the Reminder rule directs the Reminder explicitly
--					to that Name even if the Name is not associated with the Case.
-- 01-Feb-2012	MF	R11868	8	Do not rely on the CREATEDBYCRITERIA on CASEEVENT to determine if there is a rule that indicates
--					the responsible NameType.
-- 26 Jun 2012	MF	R12201	9	A change of NAMENO for a CASENAME row should now consider ALERTS that have been generated as a
--					result of the NameType held against an ALERT rule.
-- 03 Apr 2017	MF	71089	10	A duplicate key error was occurring in the ALERT table. This was because 2 different ALERTS existed for the same
--					CASEID but different EMPLOYEENOs. They were flagged to generate an Alert to either the Employee, Signatory or 
--					some other NAMETYPE.  The result was the duplicate.  Changed the code to take the lowest EMPLOYEENO only as the
--					basis of the ALERT being generated to the new NAMENO.
-- 17 Jul 2017	MF	71944	11	Cater for reminders whose message is longer than 254 characters.
-- 22 Nov 2017	MF	R72408	12	Taking a less conservative approach and removing EMPLOYEEREMINDER rows if the Name is no longer a recipient of the Reminder,
--					even if they are still attached to the Case with some other NameType. I am deliberately ignoring multiple NameTypes heldd in 
--					REMINDERS.EXTENDEDNAMETYPE as this would caused significant performance implications within the trigger.

If NOT UPDATE(LOGDATETIMESTAMP)
and  ( UPDATE(NAMENO) or UPDATE(SEQUENCE) )
Begin

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
			SOURCE		tinyint		null )

	Declare @nRowCount		int
	Declare @nAlertCount		int

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
			     and CE.OCCURREDFLAG=0)
	join CASENAME CN     on (CN.CASEID=i.CASEID
			     and CN.NAMETYPE=i.NAMETYPE
			     and CN.SEQUENCE=(select min(CN1.SEQUENCE)
					      from CASENAME CN1
					      where CN1.CASEID=CN.CASEID
					      and CN1.NAMETYPE=CN.NAMETYPE
					      and CN1.EXPIRYDATE is null))
	where (CE.EMPLOYEENO<>CN.NAMENO or CE.EMPLOYEENO is null)
	------------------------------------------------------
	-- Insert EMPLOYEEREMINDER for recipient that matches
	-- the inserted Name where a reminder rule exists
	-- for the NameType and an EMPLOYEEREMINDER for a
	-- different Name already exists.
	------------------------------------------------------
	Insert into @tbEmployeeReminder(EMPLOYEENO,MESSAGESEQ,CASEID,EVENTNO,CYCLENO,DUEDATE,REMINDERDATE,REMINDERMESSAGE,SOURCE,SEQUENCENO)
	select distinct i.NAMENO,R.MESSAGESEQ,R.CASEID,R.EVENTNO,R.CYCLENO,R.DUEDATE,R.REMINDERDATE,R.REMINDERMESSAGE,0,0
	from inserted i
	join deleted d		on (d.CASEID=i.CASEID
				and d.NAMETYPE=i.NAMETYPE
				and d.SEQUENCE=i.SEQUENCE
				and d.NAMENO <>i.NAMENO)
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
			min(DUEDATE)      as DUEDATE, 
			min(MESSAGESEQ)   as MESSAGESEQ
		from EMPLOYEEREMINDER
		where isnull(LONGMESSAGE, SHORTMESSAGE) is not null
		group by CASEID, EVENTNO, CYCLENO) R
			on (R.CASEID=OA.CASEID
			and R.EVENTNO=M.EVENTNO)
	-- Don't insert a row if the newly
	-- inserted name already has an 
	-- Employee Reminder for the Case,
	-- Event and CycleNo.
	left join EMPLOYEEREMINDER R2
				on (R2.CASEID=R.CASEID
				and R2.EMPLOYEENO=i.NAMENO
				and R2.REFERENCE is null
				and R2.EVENTNO=R.EVENTNO
				and R2.CYCLENO=R.CYCLENO)
	where R2.CASEID is null

	Set @nRowCount=@@Rowcount
	
	------------------------------------------------------
	-- Insert EMPLOYEEREMINDER for recipient that matches
	-- the inserted Name where a reminder rule exists
	-- for the NameType and an EMPLOYEEREMINDER for a
	-- different Name already exists.
	------------------------------------------------------
	Insert into @tbEmployeeReminder(EMPLOYEENO,MESSAGESEQ,CASEID,EVENTNO,CYCLENO,DUEDATE,REMINDERDATE,REMINDERMESSAGE,SOURCE, ALERTNAMENO, SEQUENCENO)
	select distinct i.NAMENO,ER.MESSAGESEQ,i.CASEID,A1.EVENTNO,A1.CYCLE,ER.DUEDATE,ER.REMINDERDATE,
			CASE WHEN(ER.SHORTMESSAGE is null) THEN cast(ER.LONGMESSAGE as nvarchar(max)) ELSE ER.SHORTMESSAGE END,
			1, i.NAMENO, A1.SEQUENCENO
	from inserted i
	join deleted d		on (d.CASEID=i.CASEID
				and d.NAMETYPE=i.NAMETYPE
				and d.SEQUENCE=i.SEQUENCE
				and d.NAMENO <>i.NAMENO)
	join ALERT A		on (A.CASEID=i.CASEID
				and(A.EMPLOYEEFLAG=1  and i.NAMETYPE='EMP') OR
				   (A.SIGNATORYFLAG=1 and i.NAMETYPE='SIG') OR
				   (A.NAMETYPE=i.NAMETYPE))
	join ALERT A1		on (A1.EMPLOYEENO=d.NAMENO
				and A1.ALERTSEQ  =A.ALERTSEQ
				and A1.CASEID    =d.CASEID
				and A1.SEQUENCENO=A.SEQUENCENO)
	join EMPLOYEEREMINDER ER
				on (ER.EMPLOYEENO  =d.NAMENO
				and ER.CASEID      =i.CASEID
				and A1.ALERTMESSAGE LIKE isnull(ER.LONGMESSAGE, ER.SHORTMESSAGE)
				and ER.ALERTNAMENO =A1.EMPLOYEENO
				and ER.SEQUENCENO  =A1.SEQUENCENO)
	----------------------------------
	-- Don't insert a row if the newly
	-- inserted name already has an 
	-- Employee Reminder that matches
	-- the ALERT.
	----------------------------------
	left join EMPLOYEEREMINDER R
				on (R.EMPLOYEENO  =i.NAMENO
				and R.CASEID      =i.CASEID
				and A1.ALERTMESSAGE LIKE isnull(R.LONGMESSAGE,R.SHORTMESSAGE)
				and R.ALERTNAMENO =A1.EMPLOYEENO
				and R.SEQUENCENO  =A1.SEQUENCENO)
	where R.CASEID is null
	
	Set @nAlertCount=@@ROWCOUNT


	If @nAlertCount>0
	Begin
		----------------------------------------------
		-- Now create an ALERT for the new CASENAME
		-- where the NAMETYPE matches an existing
		-- ALERT that has defined a rule for determing
		-- the recipient of reminders.
		----------------------------------------------
		Insert into ALERT (	
				EMPLOYEENO, ALERTSEQ, CASEID, ALERTMESSAGE, REFERENCE, ALERTDATE, DUEDATE, 
				DATEOCCURRED, OCCURREDFLAG, DELETEDATE, STOPREMINDERSDATE, MONTHLYFREQUENCY,
				MONTHSLEAD, DAILYFREQUENCY, DAYSLEAD, SEQUENCENO, SENDELECTRONICALLY, EMAILSUBJECT, NAMENO, EMPLOYEEFLAG, SIGNATORYFLAG,
				CRITICALFLAG, NAMETYPE, RELATIONSHIP, TRIGGEREVENTNO, EVENTNO, CYCLE, IMPORTANCELEVEL)
		select DISTINCT i.NAMENO, A.ALERTSEQ, A.CASEID, A.ALERTMESSAGE, A.REFERENCE, A.ALERTDATE, A.DUEDATE, A.DATEOCCURRED, A.OCCURREDFLAG, 
				A.DELETEDATE, A.STOPREMINDERSDATE, A.MONTHLYFREQUENCY, A.MONTHSLEAD, A.DAILYFREQUENCY, A.DAYSLEAD, A.SEQUENCENO, 
				A.SENDELECTRONICALLY, A.EMAILSUBJECT, NULL, 0, 0, 0, NULL, A.RELATIONSHIP, A.TRIGGEREVENTNO, A.EVENTNO, A.CYCLE, A.IMPORTANCELEVEL
		from inserted i
		     join ALERT A	on ( A.CASEID=i.CASEID
					----------------------------------------------------
					-- It is possible that more than one ALERT exists
					-- for the same ALERTSEQ value and CASEID which will
					-- generate the new ALERT to be inserted.  Just take
					-- the first EMPLOYEENO.
					----------------------------------------------------
					and  A.EMPLOYEENO = (	select min(A2.EMPLOYEENO)
								from ALERT A2
								where A2.CASEID=A.CASEID
								and   A2.ALERTSEQ=A.ALERTSEQ
								and((A.EMPLOYEEFLAG =1 and i.NAMETYPE='EMP')
								 or (A.SIGNATORYFLAG=1 and i.NAMETYPE='SIG')
								 or (A.NAMETYPE     =i.NAMETYPE))))
		left join ALERT A1	on (A1.EMPLOYEENO=i.NAMENO
					and A1.ALERTSEQ  =A.ALERTSEQ)			 
		where  A.LETTERNO     is null
		and    A.DATEOCCURRED is null	-- we don't need to create ALERTs that have already occurred
		and    isnull(A.OCCURREDFLAG,0)=0
		and   A1.EMPLOYEENO   is null
	End

	Set @nRowCount=@nRowCount+@nAlertCount

	If @nRowCount>0
	begin
		Insert into EMPLOYEEREMINDER(EMPLOYEENO,MESSAGESEQ,CASEID,EVENTNO,CYCLENO,DUEDATE,REMINDERDATE,READFLAG,SOURCE,HOLDUNTILDATE,DATEUPDATED,SHORTMESSAGE,LONGMESSAGE,COMMENTS,SEQUENCENO,ALERTNAMENO)
		select T.EMPLOYEENO,T.MESSAGESEQ,T.CASEID,T.EVENTNO,T.CYCLENO,T.DUEDATE,T.REMINDERDATE,T.SOURCE,0,null,getdate(),
			CASE WHEN(LEN(T.REMINDERMESSAGE)<255) THEN T.REMINDERMESSAGE END,
			CASE WHEN(LEN(T.REMINDERMESSAGE)>254) THEN T.REMINDERMESSAGE END,
			null,
			T.SEQUENCENO,T.ALERTNAMENO
		from @tbEmployeeReminder T
		-----------------------------------
		-- Don't insert a row if the newly
		-- inserted name already has an 
		-- Employee Reminder for the Case,
		-- Event and CycleNo.
		-----------------------------------
		left join EMPLOYEEREMINDER R
					on (R.CASEID    =T.CASEID
					and R.EMPLOYEENO=T.EMPLOYEENO
					and R.REFERENCE is null
					and R.EVENTNO=T.EVENTNO
					and R.CYCLENO=T.CYCLENO)
		where R.CASEID is null
		and T.SOURCE=0
		UNION
		select  T.EMPLOYEENO,T.MESSAGESEQ,T.CASEID,T.EVENTNO,T.CYCLENO,T.DUEDATE,T.REMINDERDATE,T.SOURCE,0,null,getdate(),
			CASE WHEN(LEN(T.REMINDERMESSAGE)<255) THEN T.REMINDERMESSAGE END,
			CASE WHEN(LEN(T.REMINDERMESSAGE)>254) THEN T.REMINDERMESSAGE END,
				null,T.SEQUENCENO,T.ALERTNAMENO
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

		-------------------------------------------------------
		-- Delete EMPLOYEEREMINDER for recipient whose CaseName
		-- has been removed and the reminder has already
		-- been copied to another Name.
		------------------------------------------------------
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
		where  T.SOURCE=0
		----------------------------------------------------
		-- Do not delete the reminder if :
		-- a) Reminderhas explicitly directed the reminder 
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

		-------------------------------------------------------
		-- Delete EMPLOYEEREMINDER for recipient whose CaseName
		-- has been removed and the reminder has already
		-- been copied to another Name.
		------------------------------------------------------
		Delete ER
		from @tbEmployeeReminder T
		join EMPLOYEEREMINDER ER
					on (ER.EMPLOYEENO <>T.EMPLOYEENO
					and ER.CASEID      =T.CASEID
					and T.REMINDERMESSAGE LIKE isnull(ER.LONGMESSAGE,ER.SHORTMESSAGE)
					and ER.ALERTNAMENO is not null
					and ER.SEQUENCENO  =T.SEQUENCENO)
		-- Only delete the reminder if the name
		-- it is against does not exist against
		-- the Case in any way.
		left join CASENAME CN	on (CN.CASEID     =ER.CASEID
					and CN.NAMENO     =ER.EMPLOYEENO)
		where CN.CASEID is null
		and T.SOURCE=1
	End
	
	If @nAlertCount>0
	Begin
		----------------------------------------------
		-- Now delete the ALERT for the old CASENAME
		-- where the NAMETYPE matches an existing
		-- ALERT that has defined a rule for determing
		-- the recipient of reminders.
		----------------------------------------------
		Delete A1
		from deleted d
		     join ALERT A	on ( A.CASEID=d.CASEID
					and((A.EMPLOYEEFLAG =1 and d.NAMETYPE='EMP')
					 or (A.SIGNATORYFLAG=1 and d.NAMETYPE='SIG')
					 or (A.NAMETYPE     =d.NAMETYPE)))
		     join ALERT A1	on (A1.EMPLOYEENO=d.NAMENO
					and A1.ALERTSEQ  =A.ALERTSEQ
					and A1.ALERTMESSAGE=A.ALERTMESSAGE
					and A1.EMPLOYEENO <>A.EMPLOYEENO)
	End
End
go