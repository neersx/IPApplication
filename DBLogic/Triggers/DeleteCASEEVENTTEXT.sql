if exists (select * from sysobjects where type='TR' and name = 'DeleteCASEEVENTTEXT')
begin
	PRINT 'Refreshing trigger DeleteCASEEVENTTEXT...'
	DROP TRIGGER DeleteCASEEVENTTEXT
end
go
	
CREATE TRIGGER DeleteCASEEVENTTEXT ON CASEEVENTTEXT AFTER DELETE NOT FOR REPLICATION AS
BEGIN	
-- TRIGGER:	DeleteCASEEVENTTEXT
-- VERSION:	5
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	------------------------------------------------------------- 
-- 17 Mar 2015	MS	45377	1	Trigger created to be called after delete on CaseEventText table
-- 13 Oct 2016	MF	64866	2	Performance improvement resulting from testing on very large database.
-- 29 Jan 2019	MF	DR-46749 3	Deleting a shared note from an Event, should result in that note being
--					removed from all the events or cycles that it was being shared with.
-- 28 Feb 2019	MF	DR-47222 4	Revisit of DR-46749.  When the CASEEVENT parent of CASEEVENTTEXT is deleted, 
--					this will trigger the deletion of CASEEVENTTEXT.  In that situation we do not
--					want to delete all references to the same EVENTTEXT.
-- 22 Mar 2019	MF	DR-47719 5	A further revisit of DR-46749.  If the CASEEVENT parent of CASEEVENTTEXT is having
--					its OCCURREDFLAG set to 9 to indicate that it is a satisfied due date with a manually
--					saved due date (DATEDUESATED=1), then this removes the CASEEVENTTEXT, however we do
--					not want it to delete all references to the same EVENTTEXT.	
	if not exists(	select 1
			from deleted d
			join EVENTS E on (E.EVENTNO=d.EVENTNO)
			where E.NOTEGROUP is not null
			or NOTESSHAREDACROSSCYCLES=1)
	and trigger_nestlevel() = 1
	Begin
		--------------------------------------------
		-- Only clear the EventText data into the
		-- CASEEVENT row if Event Note grouping is
		-- not in use. 
		-- This was done for performance reasons.
		-- Note that only client/server looks at the
		-- text in CASEEVENT.
		--------------------------------------------
		Update CE
		set	EVENTLONGTEXT = null,
			EVENTTEXT = null,
			LONGFLAG = null
		from deleted d
		join EVENTTEXT ET on (ET.EVENTTEXTID = d.EVENTTEXTID)
		join CASEEVENT CE on (CE.CASEID = d.CASEID and CE.EVENTNO = d.EVENTNO and CE.CYCLE = d.CYCLE)
		where ET.EVENTTEXTTYPEID is null
		and ISNULL(CE.EVENTLONGTEXT, CE.EVENTTEXT) is not null 
	End
	
	------------------------------------
	-- Delete all references to the same 
	-- Event Text row just removed only
	-- if the CASEEVENT row still exists
	-- and does not have OCCURREDFLAG=9,
	-- as this indicates the CASEEVENTTEXT
	-- row was explicitly removed and not
	-- just deleted becase the parent
	-- CASEEVENT was deleted or satisfied.
	------------------------------------
	Delete CET
	from deleted d
	join CASEEVENT CE      on (CE.CASEID =d.CASEID
			       and CE.EVENTNO=d.EVENTNO
			       and CE.CYCLE  =d.CYCLE)	
	join CASEEVENTTEXT CET on (CET.EVENTTEXTID = d.EVENTTEXTID)
	where isnull(CE.OCCURREDFLAG,0)<>9
	
	------------------------------------
	-- Now remove the EVENTTEXT row that 
	-- is no longer being referenced.
	------------------------------------
	Delete ET
        from deleted d
	left join CASEEVENTTEXT CET on (CET.EVENTTEXTID=d.EVENTTEXTID)
        join EVENTTEXT ET on (ET.EVENTTEXTID = d.EVENTTEXTID)
	where CET.CASEID is null
END
go
