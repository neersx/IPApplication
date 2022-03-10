if exists (select * from sysobjects where type='TR' and name = 'td_CaseNameEvents')
begin
	PRINT 'Refreshing trigger td_CaseNameEvents...'
	DROP TRIGGER td_CaseNameEvents
end
go

CREATE TRIGGER td_CaseNameEvents
ON CASENAME
FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER:	td_CaseNameEvents  
-- VERSION:	7
-- DESCRIPTION:	When a CASENAME row is deleted then check if any CASEEVENT rows for 
--		the same case need to be updated to no longer point to that NameNo.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15-Sep-2009	MF	S17983	1	Procedure created
-- 26-Nov-2010	MF	R10012	2	When a Name is removed from a Case then remove the associated
--					EMPLOYEEREMINDER rows if there is already another Name for the
--					same NameType against the Case that now has the same EMPLOYEEREMINDER.
-- 01-Feb-2012	MF	R11868	3	Do not rely on the CREATEDBYCRITERIA on CASEEVENT to determine if there is a rule that indicates
--					the responsible NameType.
-- 26 Jun 2012	MF	R12201	4	This is similar to RFC10012. Alerts that are directed to a recipient based on rules stored against the Alert can
--					be removed when the Name of the recipient is removed from the Case. The generated EMPLOYEEREMINDER may also
--					be removed.
-- 05 Mar 2014	MF	R31635	5	Allow the ALERT to be delete even if another CaseName for the same NameType does not exist.
-- 06 Mar 2014	MF	R31635	6	Rework. If the master ALERT with the rules matches the Name of the CaseName being deleted then do not delete the ALERT.
-- 22 Nov 2017	MF	R72408	7	Taking a less conservative approach and removing EMPLOYEEREMINDER rows if the Name is no longer a recipient of the Reminder,
--					even if they are still attached to the Case with some other NameType. I am deliberately ignoring multiple NameTypes heldd in 
--					REMINDERS.EXTENDEDNAMETYPE as this would caused significant performance implications within the trigger.

	Update CE
	Set EMPLOYEENO=CN.NAMENO,
	    DUEDATERESPNAMETYPE=CASE WHEN(CN.NAMENO is null) THEN EC.DUEDATERESPNAMETYPE ELSE NULL END
	from deleted d
	join OPENACTION OA   on (OA.CASEID=d.CASEID
			     and OA.POLICEEVENTS=1)
	join EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO
			     and EC.DUEDATERESPNAMETYPE=d.NAMETYPE)
	join CASEEVENT CE    on (CE.CASEID =d.CASEID
			     and CE.EVENTNO=EC.EVENTNO
			     and CE.EMPLOYEENO=d.NAMENO)
	left join CASENAME CN on(CN.CASEID=d.CASEID
			     and CN.NAMETYPE=d.NAMETYPE
			     and CN.SEQUENCE=(select min(CN1.SEQUENCE)
					      from CASENAME CN1
					      where CN1.CASEID=CN.CASEID
					      and CN1.NAMETYPE=CN.NAMETYPE
					      and CN1.EXPIRYDATE is null))
	where CE.OCCURREDFLAG=0
	and  (CE.EMPLOYEENO<>CN.NAMENO or CN.NAMENO is null)


	-------------------------------------------------------
	-- Delete EMPLOYEEREMINDER for recipient whose CaseName
	-- has just been removed and the reminder has already
	-- been copied to another Name.
	------------------------------------------------------
	Delete R
	from deleted d
	join OPENACTION OA	on (OA.CASEID=d.CASEID
				and OA.POLICEEVENTS=1)
	join REMINDERS M	on (M.CRITERIANO=OA.CRITERIANO
				and M.RELATIONSHIP is null
				and((M.EMPLOYEEFLAG=1  and d.NAMETYPE='EMP') OR
				    (M.SIGNATORYFLAG=1 and d.NAMETYPE='SIG') OR
				    (M.NAMETYPE=d.NAMETYPE)))
	join EMPLOYEEREMINDER R on (R.EMPLOYEENO=d.NAMENO
				and R.CASEID    =d.CASEID
				and R.EVENTNO   =M.EVENTNO)
	----------------------------------------------
	-- Delete will only occur if EMPLOYEEREMINDER
	-- exists for the new NameNo with the same
	-- NameType of the CASENAME row just deleted.
	----------------------------------------------
	where exists
	(select 1 
	 from CASENAME CN1
	 join EMPLOYEEREMINDER ER
			on (ER.EMPLOYEENO=CN1.NAMENO
			and ER.CASEID    =CN1.CASEID
			and ER.SHORTMESSAGE=R.SHORTMESSAGE)
	 where CN1.CASEID=d.CASEID
	 and CN1.NAMETYPE=d.NAMETYPE
	 and CN1.NAMENO <>d.NAMENO)
	----------------------------------------------
	-- Do not delete the EMPLOYEEREMINDER if name
	-- being deleted still exists in CASENAME with
	-- a NameType that would still receive a 
	-- reminder for the EventNo whose reminder is
	-- a candidate for deletion.
	----------------------------------------------
	 and not exists
	 (select 1
	  from CASENAME CN
	  join OPENACTION OA1 on ( OA1.CASEID      =d.CASEID
			      and  OA1.POLICEEVENTS=1)
	  join REMINDERS M1   on ( M1.CRITERIANO=OA1.CRITERIANO
			      and  M1.EVENTNO   =R.EVENTNO
			      and  M1.RELATIONSHIP is null
			      and((M1.EMPLOYEEFLAG =1 and CN.NAMETYPE='EMP') OR
				  (M1.SIGNATORYFLAG=1 and CN.NAMETYPE='SIG') OR
				  (M1.NAMETYPE     =CN.NAMETYPE)))
	  where CN.CASEID=d.CASEID
	  and   CN.NAMENO=d.NAMENO
	  and  (CN.NAMETYPE<>d.NAMETYPE OR CN.SEQUENCE<>d.SEQUENCE))

	-------------------------------------------------------
	-- Delete EMPLOYEEREMINDER for recipient whose CaseName
	-- has just been removed and the reminder was created
	-- by an ALERT that determined the recipient from a 
	-- rule
	------------------------------------------------------
	Delete R
	from deleted d
	join ALERT A		on (A.CASEID=d.CASEID
				and(A.EMPLOYEEFLAG=1  and d.NAMETYPE='EMP') OR
				   (A.SIGNATORYFLAG=1 and d.NAMETYPE='SIG') OR
				   (A.NAMETYPE=d.NAMETYPE))
	join ALERT A1		on (A1.EMPLOYEENO=d.NAMENO
				and A1.ALERTSEQ  =A.ALERTSEQ
				and A1.CASEID    =d.CASEID
				and A1.SEQUENCENO=A.SEQUENCENO)
	join EMPLOYEEREMINDER R on (R.EMPLOYEENO=d.NAMENO
				and R.CASEID    =d.CASEID
				and R.SOURCE    =1
				and R.SHORTMESSAGE=A.ALERTMESSAGE)
	left join CASENAME CN	on (CN.CASEID   =d.CASEID
				and CN.NAMENO   =d.NAMENO)
	----------------------------------------------
	-- Delete will only occur if EMPLOYEEREMINDER
	-- exists for the new NameNo with the same
	-- NameType of the CASENAME row just deleted
	-- and the CASENAME being deleted does not
	-- also exist as another NameType for the Case
	----------------------------------------------
	where CN.CASEID is null
	and exists
	(select 1 
	 from CASENAME CN1
	 join EMPLOYEEREMINDER ER
			on (ER.EMPLOYEENO=CN1.NAMENO
			and ER.CASEID    =CN1.CASEID
			and ER.SHORTMESSAGE=R.SHORTMESSAGE)
	 where CN1.CASEID=d.CASEID
	 and CN1.NAMETYPE=d.NAMETYPE
	 and CN1.NAMENO <>d.NAMENO)

	-------------------------------------------------------
	-- Delete ALERT for recipient whose CaseName
	-- has just been removed and the ALERT was created
	-- as a result of another ALERT that defined a rule
	-- to determine the recipient of generated reminders.
	------------------------------------------------------	
	Delete A1
	from deleted d
	join ALERT A		on (A.CASEID=d.CASEID
				and(A.EMPLOYEEFLAG=1  and d.NAMETYPE='EMP') OR
				   (A.SIGNATORYFLAG=1 and d.NAMETYPE='SIG') OR
				   (A.NAMETYPE=d.NAMETYPE))
	join ALERT A1		on (A1.EMPLOYEENO   =d.NAMENO
				and A1.ALERTSEQ     =A.ALERTSEQ
				and A1.CASEID       =d.CASEID
				and A1.SEQUENCENO   =A.SEQUENCENO
				and A1.EMPLOYEEFLAG =0
				and A1.SIGNATORYFLAG=0
				and A1.NAMETYPE     is null)
	left join CASENAME CN	on (CN.CASEID   =d.CASEID
				and CN.NAMENO   =d.NAMENO)
	----------------------------------------------
	-- Delete will only occur if the NAMENO being 
	-- deleted does not also exist as another 
	-- NameType for the Case
	----------------------------------------------
	where CN.CASEID is null
	
go