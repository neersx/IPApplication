if exists (select * from sysobjects where type='TR' and name = 'InsertCASEEVENT_Instruct')
begin
	PRINT 'Refreshing trigger InsertCASEEVENT_Instruct...'
	DROP TRIGGER InsertCASEEVENT_Instruct
end
go
	
CREATE TRIGGER InsertCASEEVENT_Instruct ON CASEEVENT
FOR INSERT NOT FOR REPLICATION AS
-- TRIGGER:	InsertCASEEVENT_Instruct    
-- VERSION:	4
-- DESCRIPTION:	Maintain the contents of CASEINSTRUCTALLOWED as a result of CASEEVENT changes

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30-Jan-2007	MF	RFC2982 1	Procedure created
-- 17 Mar 2010	MF	RFC9031	2	Action is optional in the Instruction Definition and so this needs to be considered when
--					checking for an OpenAction row.
-- 16 Mar 2010	MF	RFC9031	3	Revisit.  Need to test that IND.ACTION is null.
-- 01 Jun 2010	MF	RFC9415	4	Change procedure so that CASEINSTRUCTALLOWED is only inserted by the
--					existence of the appropriate due date and if there is a prerequisite
--					event then that must exist as an occurred event for the same cycle.

Declare @nDeletedRows		int
-----------------------------------------------------------------------
-- If an Event that is flagged as an Instruction Response
-- has occurred then remove any associated CASEINSTRUCTALLOWED.
-- Also delete any CASEINSTRUCTALLOWED that matches the
-- triggered EventNo if the cycle is diferent.
-- This is a heavy handed approach as we don't know which cycle
-- will satify the instruction however the following step will reinsert
-- the CASEINSTRUCTALLOWED row if it should not have been deleted.
-----------------------------------------------------------------------
Delete CASEINSTRUCTALLOWED
from CASEINSTRUCTALLOWED CI
join inserted i			on (i.CASEID=CI.CASEID)
left join INSTRUCTIONRESPONSE R	on (R.FIREEVENTNO=i.EVENTNO)
where (R.DEFINITIONID=CI.DEFINITIONID and i.OCCURREDFLAG=1)
OR (i.EVENTNO=CI.EVENTNO and i.CYCLE<>CI.CYCLE)

set @nDeletedRows=@@rowcount

If @nDeletedRows>0
or exists(select 1
	  from inserted i
	  join INSTRUCTIONDEFINITION D	on (D.DUEEVENTNO=i.EVENTNO
					or  D.PREREQUISITEEVENTNO=i.EVENTNO))
Begin
	--------------------------------------------------------------
	-- When a Case becomes eligible to be instructed via the web
	-- a row is to be inserted into the CASEINSTRUCTALLOWED table.
	-- This table will point to the CASEEVENT that indicates the
	-- eligibility.
	--------------------------------------------------------------
	Insert into CASEINSTRUCTALLOWED(CASEID, EVENTNO, CYCLE, DEFINITIONID)
	Select distinct INCE.CASEID, INCE.EVENTNO, INCE.CYCLE,IND.DEFINITIONID
	from inserted i
	JOIN INSTRUCTIONDEFINITION IND	on (i.EVENTNO in (IND.PREREQUISITEEVENTNO,IND.DUEEVENTNO))
	-- Locate the event that drives the applicability of the instruction
	JOIN EVENTS INE		on (INE.EVENTNO=IND.DUEEVENTNO)
	-- Locate the driving case event that must be a due date.
	join CASEEVENT INCE	on (INCE.CASEID      =i.CASEID
				and INCE.EVENTNO     =IND.DUEEVENTNO
				and INCE.OCCURREDFLAG=0)
	-- Find the best open action for the event and instruction
	Join (	select OA.CASEID, OA.ACTION, A.NUMCYCLESALLOWED, EC.EVENTNO, isnull(max(OA.CYCLE),null) as MAXCYCLE, isnull(min(OA.CYCLE),null) as MINCYCLE
		from EVENTCONTROL EC
		join OPENACTION OA	on (OA.CRITERIANO=EC.CRITERIANO
					and OA.POLICEEVENTS = 1)
		join ACTIONS A		on (A.ACTION=OA.ACTION)
		group by OA.CASEID, OA.ACTION, A.NUMCYCLESALLOWED, EC.EVENTNO) INOA 	
					on (INOA.CASEID=i.CASEID
					and(INOA.ACTION=IND.ACTION OR IND.ACTION is NULL)
					and INOA.EVENTNO=IND.DUEEVENTNO
					and INCE.CYCLE=
						case
						 -- For non-cyclic events, action is irrelevant
						 when INE.NUMCYCLESALLOWED=1 then INCE.CYCLE
						 -- If instruction is controlled by an action, event must match the cycle
						 when IND.ACTION is not null and INOA.NUMCYCLESALLOWED=1 then INCE.CYCLE 
						 when IND.ACTION is not null and IND.USEMAXCYCLE=1       then INOA.MAXCYCLE 
						 when IND.ACTION is not null and IND.USEMAXCYCLE=0       then INOA.MINCYCLE
						 -- If instruction has no action, use the max cycle for the OpenAction
						 else (	select max(OA2.CYCLE)
							from OPENACTION OA2
							where OA2.CASEID=INOA.CASEID
							and OA2.ACTION=INOA.ACTION
							and OA2.POLICEEVENTS=1)
						end)
	-- Ensure the row does not already exist
	left join CASEINSTRUCTALLOWED CI on (CI.CASEID=INCE.CASEID
					 and CI.EVENTNO=INCE.EVENTNO
					 and CI.CYCLE=INCE.CYCLE
					 and CI.DEFINITIONID=IND.DEFINITIONID)
	-- Check if prerequisite event exists
	left join CASEEVENT CE		on (CE.CASEID =INCE.CASEID
					and CE.EVENTNO=IND.PREREQUISITEEVENTNO
					and CE.CYCLE  =INCE.CYCLE
					and CE.OCCURREDFLAG=1)
	where CI.CASEID IS NULL
	-- If driven by prerequisite event it must exist
	and (IND.PREREQUISITEEVENTNO=CE.EVENTNO OR IND.PREREQUISITEEVENTNO is null)
	-- without any responses
	and not exists
	(select 1
	 from INSTRUCTIONRESPONSE R
	 join EVENTS E		on (E.EVENTNO=R.FIREEVENTNO)
	 join CASEEVENT CE1 	on (CE1.CASEID=i.CASEID
				and CE1.EVENTNO=R.FIREEVENTNO
				and CE1.CYCLE=
					case
					 when E.NUMCYCLESALLOWED=1 then 1
					 else INCE.CYCLE
					end)
	 where R.DEFINITIONID=IND.DEFINITIONID
	 and CE1.OCCURREDFLAG=1)
End
go
