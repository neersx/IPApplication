if exists (select * from sysobjects where type='TR' and name = 'DeleteOPENACTION_Instruct')
begin
	PRINT 'Refreshing trigger DeleteOPENACTION_Instruct...'
	DROP TRIGGER DeleteOPENACTION_Instruct
end
go
	
CREATE TRIGGER DeleteOPENACTION_Instruct ON OPENACTION
FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER:	DeleteOPENACTION_Instruct    
-- VERSION:	3
-- DESCRIPTION:	Maintain the contents of CASEINSTRUCTALLOWED as a result of OPENACTION changes

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 5-Mar-2007	MF	RFC2982 1	Procedure created
-- 17 Mar 2010	MF	RFC9031	2	Action is optional in the Instruction Definition and so this needs to be considered when
--					checking for an OpenAction row.
-- 03 Jun 2010	MF	RFC9415	3	Change procedure so that CASEINSTRUCTALLOWED is only inserted by the
--					existence of the appropriate due date and if there is a prerequisite
--					event then that must exist as an occurred event for the same cycle.


Declare @nDeletedRows		int
--------------------------------------------------------------------
-- If an Open Action is deleted it may result in some due Events no
-- longer being considered as "due".  Any CASEINSTRUCTALLOWED
-- rows associated with the "due" Event should then be removed.

-- This is a heavy handed approach as we don't know which cycle,  
-- and also the Event may also belong to other Open Actions.
-- The following step will reinsert the CASEINSTRUCTALLOWED row if 
-- it should not have been deleted.
--------------------------------------------------------------------
Delete CI
from CASEINSTRUCTALLOWED CI
join deleted d		on (d.CASEID=CI.CASEID)
join EVENTCONTROL EC	on (EC.CRITERIANO=d.CRITERIANO
			and EC.EVENTNO   =CI.EVENTNO)
where d.POLICEEVENTS=1

set @nDeletedRows=@@rowcount


If @nDeletedRows>0
Begin
	--------------------------------------------------------------
	-- When a Case becomes eligible to be instructed via the web
	-- a row is to be inserted into the CASEINSTRUCTALLOWED table.
	-- This table will point to the CASEEVENT that indicates the
	-- eligibility.
	--------------------------------------------------------------
	Insert into CASEINSTRUCTALLOWED(CASEID, EVENTNO, CYCLE, DEFINITIONID)
	Select distinct INCE.CASEID, INCE.EVENTNO, INCE.CYCLE,IND.DEFINITIONID
	from deleted d
	CROSS JOIN INSTRUCTIONDEFINITION IND
	-- Locate the event that drives the applicability of the instruction
	JOIN EVENTS INE		on (INE.EVENTNO=IND.DUEEVENTNO)
	-- Locate the driving case event that must be a due date.
	join CASEEVENT INCE	on (INCE.CASEID      =d.CASEID
				and INCE.EVENTNO     =IND.DUEEVENTNO
				and INCE.OCCURREDFLAG=0)
	-- Find the best open action for the event and instruction
	Join (	select OA.CASEID, OA.ACTION, A.NUMCYCLESALLOWED, EC.EVENTNO, isnull(max(OA.CYCLE),null) as MAXCYCLE, isnull(min(OA.CYCLE),null) as MINCYCLE
		from EVENTCONTROL EC
		join OPENACTION OA	on (OA.CRITERIANO=EC.CRITERIANO
					and OA.POLICEEVENTS = 1)
		join ACTIONS A		on (A.ACTION=OA.ACTION)
		group by OA.CASEID, OA.ACTION, A.NUMCYCLESALLOWED, EC.EVENTNO) INOA 	
					on (INOA.CASEID=d.CASEID
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
	 join CASEEVENT CE1 	on (CE1.CASEID=d.CASEID
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