-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCaseDueDates
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCaseDueDates'))
begin
	print '**** Drop function dbo.fn_GetCaseDueDates.'
	drop function dbo.fn_GetCaseDueDates
end
print '**** Creating function dbo.fn_GetCaseDueDates...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_GetCaseDueDates()

Returns TABLE
 --  (      
	--CASEID			int,
	--EVENTNO			int,
	--CYCLE				smallint,
	--EVENTDESCRIPTION		nvarchar(100)	collate database_default,
	--EVENTDESCRIPTION_TID		int,
	--EVENTDUEDATE			datetime,
	--DATEREMIND			datetime,
	--DATEDUESAVED			bit,
	--GOVERNINGEVENTNO		int,
	--IMPORTANCELEVEL		nvarchar(2)	collate database_default,
	--CLIENTIMPLEVEL		nvarchar(2)	collate database_default,
	--CREATEDBYACTION		nvarchar(2)	collate database_default,
	--CREATEDBYCRITERIA		int,
	--GOVERNINGEVENTNO		int,
	--EMPLOYEENO			int,
	--DUEDATERESPNAMETYPE		nvarchar(3)	collate database_default,
	--EVENTTEXT			nvarchar(max)	collate database_default,
	--EVENTTEXT_TID			int,
	--FROMCASEID			int,
	--RENEWALFLAG			bit,
	--DEFINITION			nvarchar(254)	collate database_default,
	--DEFINITION_TID		bit,
	--CATEGORYID			int,
	--NOTEGROUP			int,
	--NOTESSHAREDACROSSCYCLES	bit,
        --EVENTTEXTID			int,
        --EVENTTEXTTYPEID		int
        --LOGDATETIMESTAMP		datetime
 --  )

as
-- FUNCTION :	fn_GetCaseDueDates
-- VERSION  :	9
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This function returns CaseEvent details of due dates by applying the 
--		conditions that determine whether the CaseEvent should be considered
--		to be due for the Case.  These rules are as follows :
--		a) OccurredFlag=0
--		b) EventDueDate has a value
--		c) Event belongs to an OpenAction with PoliceEvents=1
--		d) OpenAction must be ControllingAction if one has been specified for the EventNo
--		e) OpenAction cycle must match cycle of CaseEvent if multiple cycles allowed for Action.
--
-- EXAMPLE:	The function may be treated as a table as shown in the following example:
--
--			select C.IRN, DD.*
--			from CASES C
--			join dbo.fn_GetCaseDueDates() DD on (DD.CASEID=C.CASEID)
--			where C.CASEID=-487
--			order by 1

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Mar 2012	MF	R12065	1	Function created
-- 18 Apr 2012	MF	R12194	2	Return a flag that indicates if the Event is a renewal event.
-- 16 May 2012	MF	R12307	3	Return the EVENT definition to keep in sync with fn_GetCaseOccurredDates
-- 06 Dec 2012	MF	R13009	4	Provide an option as to whether the specified CONTROLLINGACTION must be open or 
--					whether any open action that includes the Event will do.
-- 09 Apr 2013	MF	R13035	5	Also return the CATEGORYID of the Event.
-- 03 Mar 2015	MF	R43207	6	Change of data structure for EVENTTEXT. Return the last text updated if there are multiple rows.
-- 06 Oct 2016	MF	69085	7	Performance improvement for getting the latest EVENTTEXT associated with the CASEEVENT.
-- 14 Oct 2016	MF	64418	8	Return the new EVENTS columns NOTEGROUP and NOTESSHAREDACROSSCYCLES
-- 31 May 2019	MF	DR-49447 9	Return the CLIENTIMPLEVEL for client importance level

Return	
	SELECT  DISTINCT
		DD.CASEID,
		DD.EVENTNO,
		DD.CYCLE,
		EC.EVENTDESCRIPTION,
		EC.EVENTDESCRIPTION_TID,
		DD.EVENTDUEDATE,
		DD.DATEREMIND,
		DD.DATEDUESAVED,
		DD.GOVERNINGEVENTNO,
		coalesce(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL) as IMPORTANCELEVEL,
		coalesce(E.CLIENTIMPLEVEL, EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL) as CLIENTIMPLEVEL,
		DD.CREATEDBYACTION,
		DD.CREATEDBYCRITERIA,
		DD.EMPLOYEENO,
		DD.DUEDATERESPNAMETYPE,
		CET.EVENTTEXT,
		CET.EVENTTEXT_TID,
		DD.FROMCASEID,
		cast(CASE WHEN(A.ACTIONTYPEFLAG=1) THEN 1 ELSE 0 END as bit) as RENEWALFLAG,
		E.DEFINITION,
		E.DEFINITION_TID,
                E.CATEGORYID,
		E.NOTEGROUP,
		E.NOTESSHAREDACROSSCYCLES,
                CET.EVENTTEXTID,
                CET.EVENTTEXTTYPEID,
                CET.LOGDATETIMESTAMP
	FROM CASEEVENT DD
	JOIN OPENACTION OA   ON (OA.CASEID = DD.CASEID)
	JOIN EVENTCONTROL EC ON (EC.CRITERIANO = OA.CRITERIANO
			     AND EC.EVENTNO    = DD.EVENTNO )
	JOIN EVENTS E        ON ( E.EVENTNO    = DD.EVENTNO )
	JOIN ACTIONS A       ON ( A.ACTION     = OA.ACTION  )
	JOIN SITECONTROL S   ON ( S.CONTROLID  = 'Any Open Action for Due Date')
				
	LEFT JOIN (	select CET.CASEID, CET.EVENTNO, CET.CYCLE, MAX(convert(char(23),ET.LOGDATETIMESTAMP,121)+convert(char(11),ET.EVENTTEXTID)) as EVENTTEXTROW
			from CASEEVENTTEXT CET
			join EVENTTEXT ET on (ET.EVENTTEXTID=CET.EVENTTEXTID)
			group by CET.CASEID, CET.EVENTNO, CET.CYCLE
			) T	on (T.CASEID =DD.CASEID
				and T.EVENTNO=DD.EVENTNO
				and T.CYCLE  =DD.CYCLE)
				
	LEFT JOIN EVENTTEXT CET
			     ON (CET.EVENTTEXTID=cast(substring(T.EVENTTEXTROW,24,11) as INT))
			     
	WHERE isnull(DD.OCCURREDFLAG, 0) = 0
	AND DD.EVENTDUEDATE IS NOT NULL

	-- The preferred EventDescription is determined by using the Controlling Action
	-- associated with the Event.  This will be used if the OPENACTION row exists
	-- that matches the Controlling Action otherwise use the description determined
	-- from any OpenAction that references the Event.
	AND ( OA.ACTION = E.CONTROLLINGACTION
	 OR ( E.CONTROLLINGACTION IS NULL AND EC.CRITERIANO = DD.CREATEDBYCRITERIA )  )
	AND OA.CYCLE = CASE WHEN( A.NUMCYCLESALLOWED > 1 ) THEN DD.CYCLE ELSE 1 END

	-- At least one OpenAction that is is still being Policed
	-- must exist that references the Event for it to be considered
	-- as a due date.
	-- If a ControllingAction is specified then the OpenAction must
	-- exist for that OpenAction.
	-- The cycle of the OpenAction need to match the cycle of the
	-- CaseEvent if the Action allows multiple cycles.
	AND EXISTS 
	(  SELECT 1
	   FROM OPENACTION OA1
	   JOIN EVENTCONTROL EC1 ON (EC1.CRITERIANO = OA1.CRITERIANO
				 AND EC1.EVENTNO    = DD.EVENTNO )
	   JOIN ACTIONS A1       ON ( A1.ACTION     = OA1.ACTION )
	   WHERE  OA1.CASEID = DD.CASEID
	   AND OA1.ACTION = CASE WHEN(S.COLBOOLEAN=1) THEN OA1.ACTION ELSE ISNULL(E.CONTROLLINGACTION, OA1.ACTION) END
	   AND OA1.POLICEEVENTS = 1
	   AND OA1.CYCLE = CASE WHEN( A1.NUMCYCLESALLOWED > 1 ) THEN DD.CYCLE ELSE 1 END  )
	    

GO

grant REFERENCES, SELECT on dbo.fn_GetCaseDueDates to public
GO
