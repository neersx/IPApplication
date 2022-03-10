-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCaseOccurredDates
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCaseOccurredDates'))
begin
	print '**** Drop function dbo.fn_GetCaseOccurredDates.'
	drop function dbo.fn_GetCaseOccurredDates
end
print '**** Creating function dbo.fn_GetCaseOccurredDates...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function [dbo].[fn_GetCaseOccurredDates]( @pbShowAllEventDates	bit = 1)

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
	--CREATEDBYACTION		nvarchar(2)	collate database_default,
	--CREATEDBYCRITERIA		int,
	--GOVERNINGEVENTNO		int,
	--EMPLOYEENO			int,
	--DUEDATERESPNAMETYPE		nvarchar(3)	collate database_default,
	--EVENTTEXT			nvarchar(max)	collate database_default,
	--EVENTTEXT_TID			int,
	--FROMCASEID				int,
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
-- FUNCTION :	fn_GetCaseOccurredDates
-- VERSION  :	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This function returns CaseEvent details of Events that have occurred by 
--		applying the conditions that determine whether the CaseEvent should be 
--		returned for the Case.  These rules are as follows :
--		a) OccurredFlag between 1 and 8
--		b) EventDate has a value
--		c) Event belongs to an OpenAction
--		d) Event Description is deteremined from ControllingAction if one has been specified for the EventNo
--
-- EXAMPLE:	The function may be treated as a table as shown in the following example:
--		Note the parameter @bShowAllEventDates that can be passed to the function to control whether
--		events with a Controlling Action must have an open Controlling Action or not.
--
--			Declare @bShowAllEventDates	bit

--			Select @bShowAllEventDates=SC.COLBOOLEAN
--			from SITECONTROL SC
--			where SC.CONTROLID='Always Show Event Date'

--			select C.IRN, CE.*
--			from CASES C
--			join dbo.fn_GetCaseOccurredDates(@bShowAllEventDates) CE on (CE.CASEID=C.CASEID)
--			where C.CASEID=-487
--			order by 1, 2,3,4

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 May 2011	MF	R12307	1	Function created
-- 09 Apr 2013	MF	R13035	2	Also return the CATEGORYID of the Event.
-- 03 Mar 2015	MF	R43207	3	Change of data structure for EVENTTEXT. Return the last text updated if there are multiple rows.
-- 06 Oct 2016	MF	69085	4	Performance improvement for getting the latest EVENTTEXT associated with the CASEEVENT.
-- 14 Oct 2016	MF	64418	5	Return the new EVENTS columns NOTEGROUP and NOTESSHAREDACROSSCYCLES

Return	
	SELECT  DISTINCT
		CE.CASEID,
		CE.EVENTNO,
		CE.CYCLE,
		isnull(EC.EVENTDESCRIPTION,E.EVENTDESCRIPTION) as EVENTDESCRIPTION,
		CASE WHEN(EC.EVENTDESCRIPTION is not null) THEN EC.EVENTDESCRIPTION_TID ELSE E.EVENTDESCRIPTION_TID END as EVENTDESCRIPTION_TID,
		CE.EVENTDATE,
		CE.EVENTDUEDATE,
		CE.DATEREMIND,
		CE.DATEDUESAVED,
		CE.GOVERNINGEVENTNO,
		isnull(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL) as IMPORTANCELEVEL,
		CE.CREATEDBYACTION,
		CE.CREATEDBYCRITERIA,
		CE.EMPLOYEENO,
		CE.DUEDATERESPNAMETYPE,
		CET.EVENTTEXT,
		CET.EVENTTEXT_TID,
		CE.FROMCASEID,
		cast(CASE WHEN(A.ACTIONTYPEFLAG=1) THEN 1 ELSE 0 END as bit) as RENEWALFLAG,
		E.DEFINITION,
		E.DEFINITION_TID,
		E.CATEGORYID,
		E.NOTEGROUP,
		E.NOTESSHAREDACROSSCYCLES,
                CET.EVENTTEXTID,
                CET.EVENTTEXTTYPEID,
                CET.LOGDATETIMESTAMP
                
	FROM CASEEVENT CE
	JOIN EVENTS E		ON ( E.EVENTNO    = CE.EVENTNO )
	LEFT JOIN OPENACTION OA	ON (OA.CASEID=CE.CASEID
				AND OA.ACTION= E.CONTROLLINGACTION
				AND OA.CYCLE = (select max(OA1.CYCLE)
						from OPENACTION OA1
						where OA1.CASEID=OA.CASEID
						and OA1.ACTION=OA.ACTION))
	LEFT JOIN EVENTCONTROL EC	
				ON (EC.EVENTNO=CE.EVENTNO
				AND EC.CRITERIANO=isnull(OA.CRITERIANO,CE.CREATEDBYCRITERIA))
				
	LEFT JOIN (	select CET.CASEID, CET.EVENTNO, CET.CYCLE, MAX(convert(char(23),ET.LOGDATETIMESTAMP,121)+convert(char(11),ET.EVENTTEXTID)) as EVENTTEXTROW
			from CASEEVENTTEXT CET
			join EVENTTEXT ET on (ET.EVENTTEXTID=CET.EVENTTEXTID)
			group by CET.CASEID, CET.EVENTNO, CET.CYCLE
			) T	on (T.CASEID =CE.CASEID
				and T.EVENTNO=CE.EVENTNO
				and T.CYCLE  =CE.CYCLE)
				
	LEFT JOIN EVENTTEXT CET
			     ON (CET.EVENTTEXTID=cast(substring(T.EVENTTEXTROW,24,11) as INT))
				
	----------------------------------------------------
	-- At least one OpenAction that references the Event
	-- must exist although it does not have to be set
	-- to Police the events.
	-- This will be used to determine if the Event is
	-- for Renewals or not.
	----------------------------------------------------
	JOIN (SELECT OA.CASEID, EC.EVENTNO, MAX(A.ACTIONTYPEFLAG) AS ACTIONTYPEFLAG
	      FROM OPENACTION OA
	      JOIN EVENTCONTROL EC
				ON (EC.CRITERIANO=OA.CRITERIANO)
	      JOIN ACTIONS A	ON ( A.ACTION=OA.ACTION)
	      GROUP BY OA.CASEID, EC.EVENTNO) A
				ON ( A.CASEID=CE.CASEID
				AND  A.EVENTNO=CE.EVENTNO)
	     
	WHERE CE.OCCURREDFLAG between 1 and 8
	AND CE.EVENTDATE IS NOT NULL
	----------------------------------------------------------
	-- Events with a Controlling Action will only be displayed
	-- if an OpenAction is currently set to Police Events 
	-- unless the parameter to show all Events is set on.
	----------------------------------------------------------
	and (E.CONTROLLINGACTION is null OR OA.POLICEEVENTS=1 or @pbShowAllEventDates=1)
GO

grant REFERENCES, SELECT on dbo.fn_GetCaseOccurredDates to public
GO


