if exists (select * from sysobjects where type='TR' and name = 'UpdateEVENTS')
begin
	PRINT 'Refreshing trigger UpdateEVENTS...'
	DROP TRIGGER UpdateEVENTS
end
go
	
CREATE TRIGGER UpdateEVENTS ON EVENTS FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	UpdateEVENTS
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	------------------------------------------------------------- 
-- 16 Nov 2016	MF	69895	1	Trigger created to cater for changes to NOTEGROUP on EVENTS

If NOT UPDATE(LOGDATETIMESTAMP)
BEGIN	
	If UPDATE(NOTEGROUP)
	Begin
		----------------------------------------------
		-- When a NOTEGROUP is changed or cleared 
		-- from an Event, any EventText being pointed
		-- to from a CASEEVENT for this EVENTNO is to
		-- be deleted if other CASEEVENT rows are also
		-- pointing to the same text.
		-- This ensures that the EVENTNO being changed
		-- can no longer impact on text used by other
		-- members of the same Note Group.
		----------------------------------------------
		delete CET
		from inserted i
		join deleted d		on (d.EVENTNO=i.EVENTNO)
		join CASEEVENTTEXT CET	on (CET.EVENTNO=i.EVENTNO)
		where (i.NOTEGROUP<>d.NOTEGROUP OR d.NOTEGROUP is not null and i.NOTEGROUP is null)
		and exists
		(Select 1
		 from CASEEVENTTEXT CET1
		 where CET1.CASEID     =CET.CASEID
		 and   CET1.EVENTTEXTID=CET.EVENTTEXTID
		 and   CET1.EVENTNO   <>CET.EVENTNO)
	End
End
go
