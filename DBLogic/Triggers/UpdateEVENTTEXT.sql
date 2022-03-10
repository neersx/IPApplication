if exists (select * from sysobjects where type='TR' and name = 'UpdateEVENTTEXT')
begin
	PRINT 'Refreshing trigger UpdateEVENTTEXT...'
	DROP TRIGGER UpdateEVENTTEXT
end
go
	
CREATE TRIGGER UpdateEVENTTEXT ON EVENTTEXT FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	UpdateEVENTTEXT
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2015	MS	45377	1	Trigger created to monitor changes against EVENTTEXT table

If NOT UPDATE(LOGDATETIMESTAMP)
BEGIN
	IF UPDATE(EVENTTEXT) 
	BEGIN
		Update CE
		set	EVENTLONGTEXT	= i.EVENTTEXT,
			EVENTTEXT = null,
			LONGFLAG = 1
		From inserted i
		join CASEEVENTTEXT CET on (i.EVENTTEXTID = CET.EVENTTEXTID)
		join CASEEVENT CE on (CE.CASEID = CET.CASEID and CE.EVENTNO = CET.EVENTNO and CE.CYCLE = CET.CYCLE)
		where i.EVENTTEXTTYPEID is null
		and CHECKSUM( isnull(CE.EVENTLONGTEXT,CE.EVENTTEXT) ) <> CHECKSUM(i.EVENTTEXT)
	END
END
go