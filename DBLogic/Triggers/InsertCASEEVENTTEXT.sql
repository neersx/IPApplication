if exists (select * from sysobjects where type='TR' and name = 'InsertCASEEVENTTEXT')
begin
	PRINT 'Refreshing trigger InsertCASEEVENTTEXT...'
	DROP TRIGGER InsertCASEEVENTTEXT
end
go
	
CREATE TRIGGER InsertCASEEVENTTEXT ON CASEEVENTTEXT AFTER INSERT NOT FOR REPLICATION AS
BEGIN
-- TRIGGER:	InsertCASEEVENTTEXT
-- VERSION:	6
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	------------------------------------------------------------- 
-- 17 Mar 2015	MS	45377	1	Trigger created to monitor insert against CaseEventText table
-- 26 Sep 2016	MF	64418	2	When a row is inserted into the CASEEVENTTEXT table we need to determine if the EVENT in question 
--					indicates that the EVENTTEXT is to be shared with other CASEEVENT rows.
-- 14 Oct 2016	MF	64866	3	Need to cater for the possibility that more than one EventText for the same EventTextType can be 
--					associated with a CASEEVENT row. This can happen as a result of changes to the NOTEGROUP against
--					the Event. Additional code to remove no longer require CaseEventText will be added.
-- 12 Jul 2017	MF	71920	4	The sharing of Event Notes that have an Event Note Type need to check if the Event Note Type is allowed to be shared (SHARINGALLOWED=1).
-- 03 Jan 2018	MF	73174	5	Performance improvement.
-- 02 Jun 2018	MF	74270	6	Further performance improvement to resolve issue where more than 1000 CASEEVENT rows for a single CASEID exists. Replaced CTE with
--					temporary table resulting in much more consistent performance.
-- 20 Sep 2019	KT	DR-52379	7	Allowed null LOGDATETIMESTAMP from EVENTTEXT for create case event text

	Create table #TEMPEVENTTEXT (
			CASEID			int	 not null,
			EVENTTEXTTYPEID		int	 null,
			EVENTTEXTID		int	 not null,
			LASTENTERED		datetime null,
			TEXTCOUNT		int	 not null)

	insert into #TEMPEVENTTEXT(CASEID, EVENTTEXTTYPEID, EVENTTEXTID, LASTENTERED, TEXTCOUNT)
	select CT.CASEID, ET.EVENTTEXTTYPEID, ET.EVENTTEXTID, ET.LOGDATETIMESTAMP, count(*) as TEXTCOUNT
	from inserted i
	join CASEEVENTTEXT CT on (CT.CASEID=i.CASEID)
	join EVENTTEXT ET     on (ET.EVENTTEXTID=CT.EVENTTEXTID)
	group by CT.CASEID, ET.EVENTTEXTTYPEID, ET.EVENTTEXTID, ET.LOGDATETIMESTAMP

	--------------------------------------------------------------------
	-- Clean up code to remove CASEEVENTTEXT rows where it is found 
	-- that a CASEEVENT is pointing to more than one EVENTTEXT that has 
	-- the same EVENTTEXTTYPEID
	--------------------------------------------------------------------			
	DELETE CTE
	from CASEEVENTTEXT CTE
	join #TEMPEVENTTEXT ET on (ET.CASEID     =CTE.CASEID
			       and ET.EVENTTEXTID=CTE.EVENTTEXTID)
	where exists
	(select 1
	 from CASEEVENTTEXT CTE1
	 join #TEMPEVENTTEXT ET1 on (ET1.CASEID     =CTE1.CASEID
				 and ET1.EVENTTEXTID=CTE1.EVENTTEXTID)
	 where CTE1.CASEID =CTE.CASEID
	 and   CTE1.EVENTNO=CTE.EVENTNO
	 and   CTE1.CYCLE  =CTE.CYCLE
	 and   CTE1.EVENTTEXTID<>CTE.EVENTTEXTID
	 and (  ET1.EVENTTEXTTYPEID=ET.EVENTTEXTTYPEID OR (ET1.EVENTTEXTTYPEID is null and ET.EVENTTEXTTYPEID is null))
	 and (  ET1.TEXTCOUNT      >ET.TEXTCOUNT       OR (ET1.TEXTCOUNT=ET.TEXTCOUNT  and ET1.LASTENTERED>ET.LASTENTERED))
	 )
	
	If exists(select 1 
	          from inserted i
	          --------------------------------------
	          -- Check if ANY Events with EventText 
	          -- are to be shared with other Events.
	          --------------------------------------
	          join CASEEVENTTEXT CET      on (CET.CASEID    =i.CASEID)
		  join EVENTTEXT ET           on (ET.EVENTTEXTID=CET.EVENTTEXTID)
	          join EVENTS E               on (E.EVENTNO     =CET.EVENTNO)
		  left join EVENTTEXTTYPE ETT on (ETT.EVENTTEXTTYPEID=ET.EVENTTEXTTYPEID)
	          where (E.NOTEGROUP is not null OR E.NOTESSHAREDACROSSCYCLES=1)
		  and   (ETT.SHARINGALLOWED =1   OR ET.EVENTTEXTTYPEID is null)
		  )
	Begin        
		------------------------------------------------------------------------------
		-- For each CASEEVENTTEXT row for the inserted Case, check if the Event is 
		-- configured so that EVENTTEXT associated with this CASEEVENT row is to now
		-- be linked to other CASEEVENTs.
		-- We are checking ALL events because the EVENT rule may have changed since 
		-- the text was last added. 
		------------------------------------------------------------------------------
		With	CTE_Cases (CASEID)
				as (	select distinct CASEID
					from inserted)
		insert into CASEEVENTTEXT(EVENTTEXTID, CASEID, EVENTNO, CYCLE)
		Select distinct CET.EVENTTEXTID, CE.CASEID, CE.EVENTNO, CE.CYCLE
		from CTE_Cases C
		join CASEEVENTTEXT CET on (CET.CASEID=C.CASEID)
		join EVENTTEXT ET      on (ET.EVENTTEXTID=CET.EVENTTEXTID)
		join EVENTS E1         on (E1.EVENTNO=CET.EVENTNO)
		-------------------------------------------------
		-- Notes may be shared across Cycles of the same
		-- Event, even with no Event Text Type.
		-------------------------------------------------
		left join EVENTTEXTTYPE ETT on (ETT.EVENTTEXTTYPEID=ET.EVENTTEXTTYPEID)
		-------------------------------------------------
		-- Find other events that have the same NOTEGROUP
		-------------------------------------------------
		left join EVENTS E2 on (E2.NOTEGROUP=E1.NOTEGROUP
				    and E2.EVENTNO <>E1.EVENTNO)
		-------------------------------------------------
		-- Find CASEEVENT rows that the EVENTTEXT is to
		-- be shared with.
		-------------------------------------------------
		join CASEEVENT CE   on (CE.CASEID =C.CASEID
				    and CE.EVENTNO=CASE WHEN(E2.EVENTNO is not null)       THEN E2.EVENTNO
							WHEN(E1.NOTESSHAREDACROSSCYCLES=1) THEN E1.EVENTNO
						   END
				    and CE.CYCLE = CASE WHEN(E1.NOTESSHAREDACROSSCYCLES=1 and E2.NOTESSHAREDACROSSCYCLES=1) THEN CE.CYCLE -- Text for both events are shared across cycles
							WHEN(E1.NOTESSHAREDACROSSCYCLES=1 and CE.EVENTNO =CET.EVENTNO)      THEN CE.CYCLE -- Text for same event is share across cycles
							WHEN(E2.NOTESSHAREDACROSSCYCLES=1 and CE.EVENTNO<>CET.EVENTNO)      THEN CE.CYCLE -- Text for diffent event is share across all cycles
							WHEN(E2.NUMCYCLESALLOWED=1        and CET.CYCLE  =1)                THEN 1	  -- Text can only exists for cycle 1
							WHEN(E2.NUMCYCLESALLOWED>=CET.CYCLE)                                THEN CET.CYCLE-- Use the current cycle to fetch text
						   END)
		-------------------------------------------------
		-- Ensure the CaseEvent has not already been
		-- linked to the EventText
		-------------------------------------------------
		left join CASEEVENTTEXT CT1
				      on (CT1.EVENTTEXTID=CET.EVENTTEXTID
				      and CT1.CASEID     =CE.CASEID
				      and CT1.EVENTNO    =CE.EVENTNO
				      and CT1.CYCLE      =CE.CYCLE)
		where (ETT.SHARINGALLOWED =1  OR ET.EVENTTEXTTYPEID is null)	-- Either EventTextType is flagged to be shared or there is no EventTextType.
		and CT1.EVENTTEXTID is null
	End
	
	if exists(	select 1 from inserted i
			join EVENTTEXT ET on (ET.EVENTTEXTID = i.EVENTTEXTID)
			join CASEEVENT CE on (CE.CASEID = i.CASEID and CE.EVENTNO = i.EVENTNO and CE.CYCLE = i.CYCLE)
			where ET.EVENTTEXTTYPEID is null
			and CHECKSUM( isnull(CE.EVENTLONGTEXT,CE.EVENTTEXT) ) <> CHECKSUM(ET.EVENTTEXT))
	begin  	
		--------------------------------------------
		-- Only push the EventText data into the
		-- CASEEVENT row if Event Note grouping is
		-- not in use. 
		-- This was done for performance reasons.
		-- Note that only client/server looks at the
		-- text in CASEEVENT.
		--------------------------------------------
		Update CE
		set EVENTLONGTEXT = ET.EVENTTEXT,
		    EVENTTEXT = null,
		    LONGFLAG = 1
		from inserted i
		join EVENTTEXT ET on (ET.EVENTTEXTID = i.EVENTTEXTID)
		join CASEEVENT CE on (CE.CASEID = i.CASEID and CE.EVENTNO = i.EVENTNO and CE.CYCLE = i.CYCLE)
		where ET.EVENTTEXTTYPEID is null
		and CHECKSUM( isnull(CE.EVENTLONGTEXT,CE.EVENTTEXT) ) <> CHECKSUM(ET.EVENTTEXT)		
	end
END
go
