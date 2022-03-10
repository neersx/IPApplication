
if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Abandoned Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Control'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Abandoned Event')  
   where C.INTERNALNAME = 'Control'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Abandoned Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Abandoned Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Accounts Alias')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Accounts Alias')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Accounts Alias')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Accounts Alias')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ACCOutputFileDir')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ACCOutputFileDir')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ACCOutputFileDir')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ACCOutputFileDir')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ACCOutputFilePrefix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ACCOutputFilePrefix')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ACCOutputFilePrefix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ACCOutputFilePrefix')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Activity Time Must Be Unique')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Activity Time Must Be Unique')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Additional Internal Staff')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Additional Internal Staff')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Additional Internal Staff')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Additional Internal Staff')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Additional Internal Staff')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Additional Internal Staff')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Addr Change Reminder Template')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Addr Change Reminder Template')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Address Administrator')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Address Administrator')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Address Password')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Address Password')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Address Password')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Address Password')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Address Password')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Address Password')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Address Style EN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Address Style EN')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Address Style EN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Address Style EN')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Address Style EN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Address Style EN')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Address Style ZH-CHS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Address Style ZH-CHS')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Address Style ZH-CHS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Address Style ZH-CHS')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Address Style ZH-CHS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Address Style ZH-CHS')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adhoc Reminders by Default')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adhoc Reminders by Default')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adhoc Reminders by Default')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adhoc Reminders by Default')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adhoc Reminders by Default')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adhoc Reminders by Default')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adjust Next G Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Control'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adjust Next G Event')  
   where C.INTERNALNAME = 'Control'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adjust Next G Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adjust Next G Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adjust T as today')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adjust T as today')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adjust T as today')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Control'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adjust T as today')  
   where C.INTERNALNAME = 'Control'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adjustment ~E Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Control'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adjustment ~E Event')  
   where C.INTERNALNAME = 'Control'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adjustment ~E Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adjustment ~E Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adjustment F Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adjustment F Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adjustment F Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Control'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adjustment F Event')  
   where C.INTERNALNAME = 'Control'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adjustment K Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Control'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adjustment K Event')  
   where C.INTERNALNAME = 'Control'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Adjustment K Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Adjustment K Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Agent Category')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Agent Category')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Agent Category')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Agent Category')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Agent Category')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Agent Category')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Agent Renewal Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Agent Renewal Fee')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Agent Renewal Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Agent Renewal Fee')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Alert Must Check Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Alert Must Check Status')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Alert Must Check Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Alert Must Check Status')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Alert Must Check Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Alert Must Check Status')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Alert Spawning Blocked')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Ad Hoc Date'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Alert Spawning Blocked')  
   where C.INTERNALNAME = 'Ad Hoc Date'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Alert Spawning Blocked')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Alert Spawning Blocked')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Alerts Show All')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Alerts Show All')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Alerts Show All')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Alerts Show All')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Alerts Show All')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Alerts Show All')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Allow All Text Types For Cases')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Allow All Text Types For Cases')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Allow All Text Types For Cases')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Allow All Text Types For Cases')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Allow All Text Types For Cases')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Allow All Text Types For Cases')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Always Open Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Always Open Action')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Always Open Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Always Open Action')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Always Show Event Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Always Show Event Date')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Always Show Event Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Always Show Event Date')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Always Show Event Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Always Show Event Date')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Any Open Action for Due Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Any Open Action for Due Date')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Any Open Action for Due Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Any Open Action for Due Date')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Any Open Action for Due Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Any Open Action for Due Date')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Allow Additional WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Allow Additional WIP')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Allow Additional WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Allow Additional WIP')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Default Supplier Tax Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Default Supplier Tax Code')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Default Supplier Tax Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Default Supplier Tax Code')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Enforce Disb to WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Enforce Disb to WIP')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Enforce Disb to WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Enforce Disb to WIP')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP E.F.T. Payment File Dir')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP E.F.T. Payment File Dir')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP E.F.T. Payment File Dir')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP E.F.T. Payment File Dir')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Enforce Disb To WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Enforce Disb To WIP')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Enforce Disb To WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Enforce Disb To WIP')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Generate Disbursement Slip')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Generate Disbursement Slip')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Generate Disbursement Slip')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Generate Disbursement Slip')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Handle Partial Disbursement')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Handle Partial Disbursement')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Handle Partial Disbursement')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Handle Partial Disbursement')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Protocol Number')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Protocol Number')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Protocol Number')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Protocol Number')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Purchase Date Not Defaulted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Purchase Date Not Defaulted')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AP Purchase Date Not Defaulted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AP Purchase Date Not Defaulted')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Apportion Adjustment')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Apportion Adjustment')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AR for Prepayments')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AR for Prepayments')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AR for Prepayments')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AR for Prepayments')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AR separate DRCR journal SeqNo')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AR separate DRCR journal SeqNo')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AR separate DRCR journal SeqNo')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AR separate DRCR journal SeqNo')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AR Without Journals')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AR Without Journals')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'AR Without Journals')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'AR Without Journals')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Attach HTTP Response To Case')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Attach HTTP Response To Case')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Attach HTTP Response To Case')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Attach HTTP Response To Case')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Auto Import Duplicate File')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Import Server'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Auto Import Duplicate File')  
   where C.INTERNALNAME = 'Import Server'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Auto Import Duplicate File')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Auto Import Duplicate File')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Auto Import Reprocess Rejected')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Import Server'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Auto Import Reprocess Rejected')  
   where C.INTERNALNAME = 'Import Server'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Auto Import Reprocess Rejected')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Auto Import Reprocess Rejected')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Automatic Event Text Format')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Automatic Event Text Format')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Automatic Event Text Format')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Automatic Event Text Format')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Automatic Event Text Format')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Automatic Event Text Format')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Automatic WIP Entity')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Automatic WIP Entity')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Automatic WIP Entity')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Automatic WIP Entity')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Application Path')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Application Path')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Application Path')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Application Path')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B ePAVE DEF URN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B ePAVE DEF URN')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B ePAVE DEF URN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B ePAVE DEF URN')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B ePAVE efiling URN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B ePAVE efiling URN')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B ePAVE efiling URN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B ePAVE efiling URN')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B EPOLine Command Export')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B EPOLine Command Export')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B EPOLine Command Export')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B EPOLine Command Export')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B EPOLine Command Import')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B EPOLine Command Import')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B EPOLine Command Import')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B EPOLine Command Import')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B EPOLine DEF URN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B EPOLine DEF URN')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B EPOLine DEF URN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B EPOLine DEF URN')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Group Password Required')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Group Password Required')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Group Password Required')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Group Password Required')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Password Attempts')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Password Attempts')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Password Attempts')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Password Attempts')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Password Required For Sign')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Password Required For Sign')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Password Required For Sign')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Password Required For Sign')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Police Immediately')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Police Immediately')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Police Immediately')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Police Immediately')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Profile Collect')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Profile Collect')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Profile Collect')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Profile Collect')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Profile Pack')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Profile Pack')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Profile Pack')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Profile Pack')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Profile Send')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Profile Send')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Profile Send')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Profile Send')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Publish URN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Publish URN')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Publish URN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Publish URN')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Show Warning For Trusted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Show Warning For Trusted')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Show Warning For Trusted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Show Warning For Trusted')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Strip App Num Cntry Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Strip App Num Cntry Code')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Strip App Num Cntry Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Strip App Num Cntry Code')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Temp URN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Temp URN')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'B2B Temp URN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'B2B Temp URN')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Background Process Login ID')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Background Process Login ID')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Background Process Login ID')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Background Process Login ID')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Background Process Login ID')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Background Process Login ID')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bank Rate In Use')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bank Rate In Use')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bank Rate In Use')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bank Rate In Use')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bank Rate In Use')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bank Rate In Use')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bank Rate In Use for Service Charges')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bank Rate In Use for Service Charges')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bank Rate In Use for Service Charges')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bank Rate In Use for Service Charges')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill All WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill All WIP')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Check Before Drafting')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Check Before Drafting')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Check Before Finalise')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Check Before Finalise')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Date Change')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Date Change')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Date Future Restriction')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Date Future Restriction')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Date Future Restriction')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Date Future Restriction')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Date Only From Today')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Date Only From Today')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Date Only From Today')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Date Only From Today')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Details Rpt')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Details Rpt')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Foreign Equiv')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Foreign Equiv')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill in Advance WIP Generated')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Charge Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill in Advance WIP Generated')  
   where C.INTERNALNAME = 'Charge Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill in Advance WIP Generated')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees & Charges'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill in Advance WIP Generated')  
   where C.INTERNALNAME = 'Fees & Charges'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill in Advance WIP Generated')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill in Advance WIP Generated')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Line Tax')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Line Tax')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Lines Grouped by Tax Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Lines Grouped by Tax Code')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill PDF Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill PDF Directory')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill PDF Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Attachments'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill PDF Directory')  
   where C.INTERNALNAME = 'Attachments'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Ref Doc Item 1')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Ref Doc Item 1')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Ref Doc Item 2')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Ref Doc Item 2')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Ref Doc Item 3')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Ref Doc Item 3')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Ref Doc Item 4')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Ref Doc Item 4')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Ref Doc Item 5')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Ref Doc Item 5')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Ref Doc Item 6')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Ref Doc Item 6')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Ref-Multi 0')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Ref-Multi 0')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Ref-Multi 1')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Ref-Multi 1')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Ref-Multi 9')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Ref-Multi 9')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Ref-Single')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Ref-Single')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Renewal Debtor')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Renewal Debtor')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Restrict Apply Credits')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Restrict Apply Credits')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Save as PDF')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Save as PDF')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Save as PDF')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Attachments'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Save as PDF')  
   where C.INTERNALNAME = 'Attachments'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Spell Check Automatic')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Spell Check Automatic')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Suppress PDF Copies')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Suppress PDF Copies')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Write Up Exch Reason')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Write Up Exch Reason')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill Write Up For Exch Rate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill Write Up For Exch Rate')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bill XML Profile')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bill XML Profile')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BillDatesForwardOnly')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BillDatesForwardOnly')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Billing Cap Threshold Percent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Billing Cap Threshold Percent')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Billing Credit Tolerance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Billing Credit Tolerance')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Billing Report Date Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Billing Report Date Type')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Billing Restrict Manual Payout')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Billing Restrict Manual Payout')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BillReversalDisabled')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BillReversalDisabled')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Browser Path')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Browser Path')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Budget Percentage Used Warning')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Budget Percentage Used Warning')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bulk Update Text Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bulk Update Text Type')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bulk Update Text Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bulk Update Text Type')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Bulk Update Text Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Bulk Update Text Type')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenAbandonEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenAbandonEvent')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenAbandonEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenAbandonEvent')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenAbandonEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenAbandonEvent')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenAbandonEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenAbandonEvent')  
   where C.INTERNALNAME = 'Renewals'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenDefaultLetter')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenDefaultLetter')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenDefaultLetter')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenDefaultLetter')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenDefaultLetter')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenDefaultLetter')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenDefaultLetter')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Bulk Renewals'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenDefaultLetter')  
   where C.INTERNALNAME = 'Bulk Renewals'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenDueEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenDueEvent')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenDueEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenDueEvent')  
   where C.INTERNALNAME = 'Renewals'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenDueEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenDueEvent')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenDueEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenDueEvent')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenRenewEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenRenewEvent')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenRenewEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenRenewEvent')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenRenewEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenRenewEvent')  
   where C.INTERNALNAME = 'Renewals'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'BulkRenRenewEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'BulkRenRenewEvent')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Comparison Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Comparison Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Comparison Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Comparison Event')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Comparison Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Comparison Event')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Default Description')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Default Description')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Default Description')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Default Description')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Default Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Default Status')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Default Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Default Status')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Event Default Sorting')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Event Default Sorting')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Event Default Sorting')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Event Default Sorting')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Event Default Sorting')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Event Default Sorting')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Export Office Suffix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Export Office Suffix')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Export Office Suffix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Export Office Suffix')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Export Office Suffix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Export Office Suffix')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Fees Calc Limit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Fees Calc Limit')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Fees Queries Purge Days')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Fees Queries Purge Days')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Fees Queries Purge Days')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Fees Queries Purge Days')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Fees Queries Purge Days')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Fees Queries Purge Days')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Fees Report Limit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Fees Report Limit')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Header Description')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Header Description')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Instr. Address Restricted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Instr. Address Restricted')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Instr. Address Restricted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Instr. Address Restricted')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Instr. Address Restricted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Instr. Address Restricted')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Policed Polling Time')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Policed Polling Time')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Policed Polling Time')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Policed Polling Time')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Policed Polling Time')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Policed Polling Time')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Reference Procedure')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Reference Procedure')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Reference Procedure')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Reference Procedure')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Reference Procedure')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Reference Procedure')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Screen Default Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Control'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Screen Default Program')  
   where C.INTERNALNAME = 'Control'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Screen Default Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Screen Default Program')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Screen Default Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Screen Default Program')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Summary Details')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Summary Details')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Summary Details')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Summary Details')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Summary Details')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Summary Details')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Takeover Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Takeover Program')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Type Internal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Type Internal')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Type Internal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Type Internal')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case Type Internal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case Type Internal')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Case View Summary Image Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Case View Summary Image Type')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CASE_DETAILS_HREF')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CASE_DETAILS_HREF')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CASE_EVENTENTRY_HREF')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CASE_EVENTENTRY_HREF')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CASEDETAILFLAG')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CASEDETAILFLAG')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CASEDETAILFLAG')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CASEDETAILFLAG')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CASEDETAILFLAG')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CASEDETAILFLAG')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CASEONLY_TIME')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CASEONLY_TIME')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CASEONLY_TIME')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CASEONLY_TIME')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CASEONLY_TIME')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CASEONLY_TIME')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Cash Accounting')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Cash Accounting')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Cash Accounting')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Cash Accounting')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CC Case Emails')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CC Case Emails')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CC Case Emails')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CC Case Emails')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CC Case Emails')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CC Case Emails')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CEF Exclude Old Events')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CEF Exclude Old Events')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Charge Date set to Bill Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Charge Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Charge Date set to Bill Date')  
   where C.INTERNALNAME = 'Charge Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Charge Date set to Bill Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Charge Date set to Bill Date')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Charge Variable Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Charge Variable Fee')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Check Concurrency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Check Concurrency')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Check Concurrency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Check Concurrency')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Check Concurrency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Check Concurrency')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Checklist Mandatory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Checklist Mandatory')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Checklist Mandatory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Checklist Mandatory')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Checklist Mandatory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Checklist Mandatory')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ChequeNo Length')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ChequeNo Length')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ChequeNo Length')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ChequeNo Length')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Activity Categories')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Activity Categories')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Case Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Case Types')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Case Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Case Types')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Due Dates: Overdue Days')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Due Dates: Overdue Days')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Due Dates: Overdue Days')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Due Dates: Overdue Days')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Event Text')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Event Text')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Exclude Dead Case Stats')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Exclude Dead Case Stats')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Importance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Importance')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Importance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Importance')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Instruction Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Instruction Types')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client May View Debt')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client May View Debt')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Name Alias Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Name Alias Types')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Name Alias Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Name Alias Types')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Name Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Name Types')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Name Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Name Types')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Name Types Shown')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Name Types Shown')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Name Types Shown')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Name Types Shown')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Number Types Shown')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Number Types Shown')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Request Case Summary')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Request Case Summary')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Request Email Address')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Request Email Address')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Request Email Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Request Email Body')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Request Email Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Request Email Subject')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Text Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Text Types')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Client Text Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Client Text Types')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Clients Unaware of CPA')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Clients Unaware of CPA')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Clients Unaware of CPA')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Clients Unaware of CPA')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CMDEFAULTEMPLOYEE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Contact Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CMDEFAULTEMPLOYEE')  
   where C.INTERNALNAME = 'Contact Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CMDEFAULTEMPLOYEE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Marketing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CMDEFAULTEMPLOYEE')  
   where C.INTERNALNAME = 'Marketing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CMS Unique Client Alias Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CMS Unique Client Alias Type')  
   where C.INTERNALNAME = 'Integration'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CMS Unique Matter Number Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CMS Unique Matter Number Type')  
   where C.INTERNALNAME = 'Integration'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CMS Unique Matter Number Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration Toolkit'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CMS Unique Matter Number Type')  
   where C.INTERNALNAME = 'Integration Toolkit'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CMS Unique Name Alias Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration Toolkit'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CMS Unique Name Alias Type')  
   where C.INTERNALNAME = 'Integration Toolkit'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CMS Unique Name Alias Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CMS Unique Name Alias Type')  
   where C.INTERNALNAME = 'Integration'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Confirmation Passwd')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Confirmation Passwd')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Confirmation Passwd')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Confirmation Passwd')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Confirmation Passwd')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Confirmation Passwd')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Conflict Search Default Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Conflict Searching'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Conflict Search Default Program')  
   where C.INTERNALNAME = 'Conflict Searching'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Conflict Search Relationships')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Conflict Search Relationships')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Conflict Search Relationships')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Conflict Search Relationships')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Conflict Search Relationships')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Conflict Search Relationships')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Consider Secs in Units Calc')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Consider Secs in Units Calc')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Consider Secs in Units Calc')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Time Recording'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Consider Secs in Units Calc')  
   where C.INTERNALNAME = 'Time Recording'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Consolidate by Name Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Consolidate by Name Type')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Cont. entry units adjmt')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Cont. entry units adjmt')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Copy Config Policing')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Copy Config'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Copy Config Policing')  
   where C.INTERNALNAME = 'Copy Config'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Copy To List')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Copy To List')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Copy To Name Address')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Copy To Name Address')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Correspond Instructions Apps')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Correspond Instructions Apps')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Correspond Instructions Apps')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Correspond Instructions Apps')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Correspond Instructions Apps')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Correspond Instructions Apps')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Correspond Instructions Apps')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Correspond Instructions Apps')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CountryProfile')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CountryProfile')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Assoc Design')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Assoc Design')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA BCP Code Page')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA BCP Code Page')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Clear Batch')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Clear Batch')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Clients Reference Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Clients Reference Type')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Consider All CPA Cases')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Consider All CPA Cases')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Acceptance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Acceptance')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Affidavit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Affidavit')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Assoc Des')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Assoc Des')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Expiry')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Expiry')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Filing')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Filing')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Intent Use')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Intent Use')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Nominal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Nominal')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Parent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Parent')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-PCT Filing')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-PCT Filing')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Priority')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Priority')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Publication')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Publication')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Quin Tax')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Quin Tax')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Registratn')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Registratn')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Renewal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Renewal')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Start')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Start')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Stop')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Stop')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Date-Stop')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Date-Stop')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Division Code Alias Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Division Code Alias Type')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Division Code Truncation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Division Code Truncation')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA EDT Email Address')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA EDT Email Address')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA EDT Email Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA EDT Email Body')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA EDT Email Copies')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA EDT Email Copies')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA EDT Email Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA EDT Email Subject')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Extract Proc')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Extract Proc')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA File Number Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA File Number Type')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Files Default Path')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Files Default Path')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Inprostart Case Attachment')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Inprostart Case Attachment')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Inprostart Email Method')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Inprostart Email Method')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Inprostart in use')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Inprostart in use')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Integration in use')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Integration in use')  
   where C.INTERNALNAME = 'Integration'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Integration in use')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration Toolkit'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Integration in use')  
   where C.INTERNALNAME = 'Integration Toolkit'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Intercept Flag')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Intercept Flag')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Load By Office')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Load By Office')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Logging')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Logging')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Mismatch-Acceptance No')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Mismatch-Acceptance No')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Mismatch-Application No')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Mismatch-Application No')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Mismatch-Publication No')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Mismatch-Publication No')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Mismatch-Registration No')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Mismatch-Registration No')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Modify Case')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Modify Case')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Multi Debtor File')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Multi Debtor File')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Name Logging')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Name Logging')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Number-Acceptance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Number-Acceptance')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Number-Application')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Number-Application')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Number-PCTFiling')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Number-PCTFiling')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Number-Publication')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Number-Publication')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Number-Registration')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Number-Registration')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Parent Exclude')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Parent Exclude')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA PCT FILING')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA PCT FILING')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Received Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Received Event')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Reject Requires Reason')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Reject Requires Reason')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Rejected Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Rejected Event')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Reportable Instr')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Reportable Instr')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Sent Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Sent Event')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Stop When Reason=A')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Stop When Reason=A')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Stop When Reason=A')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Stop When Reason=A')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Stop When Reason=C')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Stop When Reason=C')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Stop When Reason=C')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Stop When Reason=C')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Stop When Reason=U')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Stop When Reason=U')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Stop When Reason=U')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Stop When Reason=U')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Use Attorney as Client')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Use Attorney as Client')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Use CaseId as Case Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Use CaseId as Case Code')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA Use NameAddress CPA Client')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA Use NameAddress CPA Client')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA User Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA User Code')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA User Name Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA User Name Type')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA-CEF Case Lapse')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA-CEF Case Lapse')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA-CEF Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA-CEF Event')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA-CEF Expiry')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA-CEF Expiry')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA-CEF Next Renewal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA-CEF Next Renewal')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA-CEF Renewal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA-CEF Renewal')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CPA-Use ClientCaseCode')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CPA-Use ClientCaseCode')  
   where C.INTERNALNAME = 'Renewals Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Credit Bill Letter Generation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Credit Bill Letter Generation')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Credit Limit Warning Percentage')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Time Recording'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Credit Limit Warning Percentage')  
   where C.INTERNALNAME = 'Time Recording'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Critical Dates - External')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Critical Dates - External')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Critical Dates - External')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Critical Dates - External')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Critical Dates - Internal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Critical Dates - Internal')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Critical Dates - Internal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Critical Dates - Internal')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRITICAL LEVEL')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRITICAL LEVEL')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRITICAL LEVEL')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRITICAL LEVEL')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Critical Reminder')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Critical Reminder')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Critical Reminder')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Critical Reminder')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Activity Accept Response')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Marketing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Activity Accept Response')  
   where C.INTERNALNAME = 'Marketing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Activity Accept Response')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Activity Accept Response')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Convert Client Name Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Convert Client Name Types')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Convert Client Name Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Marketing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Convert Client Name Types')  
   where C.INTERNALNAME = 'Marketing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Default Lead Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Marketing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Default Lead Status')  
   where C.INTERNALNAME = 'Marketing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Default Lead Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Default Lead Status')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Default Mkting Act Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Default Mkting Act Status')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Default Mkting Act Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Marketing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Default Mkting Act Status')  
   where C.INTERNALNAME = 'Marketing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Default Network Filter')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Marketing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Default Network Filter')  
   where C.INTERNALNAME = 'Marketing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Default Network Filter')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Default Network Filter')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Default Opportunity Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Default Opportunity Status')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Default Opportunity Status')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Marketing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Default Opportunity Status')  
   where C.INTERNALNAME = 'Marketing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Name Screen Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Name Screen Program')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Opp Status Closed Won')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Opp Status Closed Won')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Opp Status Closed Won')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Marketing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Opp Status Closed Won')  
   where C.INTERNALNAME = 'Marketing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Opportunity Name Group')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Marketing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Opportunity Name Group')  
   where C.INTERNALNAME = 'Marketing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Opportunity Name Group')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Opportunity Name Group')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Screen Control Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Screen Control Program')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CRM Screen Control Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Marketing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CRM Screen Control Program')  
   where C.INTERNALNAME = 'Marketing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'CURRENCY')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'CURRENCY')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Currency Default from Agent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Currency Default from Agent')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Currency Default from Agent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Currency Default from Agent')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Currency Whole Units')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Currency Whole Units')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Database Culture')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Database Culture')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Database Culture')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Database Culture')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Database Email Login')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Database Email Login')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Database Email Profile')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Database Email Profile')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Database Email Profile')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Database Email Profile')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Database Email Shared Folder')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Database Email Shared Folder')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Database Email Shared Folder')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Database Email Shared Folder')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Database Email Via Certificate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Database Email Via Certificate')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Database Email Via Certificate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Database Email Via Certificate')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Date Style')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Date Style')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Date Style')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Date Style')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Date To Excel In Date Format')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Date To Excel In Date Format')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Date To Excel In Date Format')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Date To Excel In Date Format')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Date To Excel In Date Format')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Date To Excel In Date Format')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DB Release Version')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DB Release Version')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DB Release Version')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DB Release Version')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Debit Item Payout Tolerance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Debit Item Payout Tolerance')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Debit Item Payout Tolerance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Debit Item Payout Tolerance')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Debit Item Payout Tolerance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Debit Item Payout Tolerance')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Debtor Statement')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Debtor Statement')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Debtor Statement')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Debtor Statement')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DebtorType based on Instructor')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DebtorType based on Instructor')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DebtorType based on Instructor')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DebtorType based on Instructor')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Ad hoc Date Importance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Ad hoc Date Importance')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Ad hoc Date Importance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Ad hoc Date Importance')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Ad hoc Date Importance')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Ad hoc Date Importance')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Delimiter')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Delimiter')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Delimiter')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Reporting'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Delimiter')  
   where C.INTERNALNAME = 'Reporting'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Delimiter')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Delimiter')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Delimiter')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Delimiter')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Document Profile Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Document Profile Type')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Document Profile Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Document Profile Type')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Security')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Security')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Security')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Security')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Default Security')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Default Security')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DEFAULTDEBITCOPIES')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DEFAULTDEBITCOPIES')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Discount Automatic Adjustment')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Discount Automatic Adjustment')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Discount Narrative')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Discount Narrative')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Discount Renewal WIP Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Discount Renewal WIP Code')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Discount Renewal WIP Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Discount Renewal WIP Code')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Discount WIP Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Discount WIP Code')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Discount WIP Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Discount WIP Code')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DiscountNotInBilling')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DiscountNotInBilling')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DiscountNotInBilling')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Charge Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DiscountNotInBilling')  
   where C.INTERNALNAME = 'Charge Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DiscountNotInBilling')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees & Charges'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DiscountNotInBilling')  
   where C.INTERNALNAME = 'Fees & Charges'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Discounts')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Discounts')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Discounts')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Discounts')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Display Ceased Names')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Display Ceased Names')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Display Ceased Names')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Display Ceased Names')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Display Ceased Names')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Display Ceased Names')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Division Name Alias')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Division Name Alias')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Division Name Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Division Name Types')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Case Search Doc Item')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Case Search Doc Item')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Case Search Doc Item')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Case Search Doc Item')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Case Search Doc Item')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Case Search Doc Item')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Name Search Doc Item')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Name Search Doc Item')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Name Search Doc Item')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Name Search Doc Item')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Name Search Doc Item')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Name Search Doc Item')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Name Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Name Types')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Name Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Name Types')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Name Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Name Types')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Third Party Component URL')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Third Party Component URL')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Third Party Component URL')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Third Party Component URL')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DMS Third Party Component URL')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DMS Third Party Component URL')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DN Change Administrator')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DN Change Administrator')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DN Change Reminder Template')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DN Change Reminder Template')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DN Copy Text 0')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DN Copy Text 0')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DN Copy Text 1')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DN Copy Text 1')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DN Copy Text 2')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DN Copy Text 2')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DN Cust Copy Text')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DN Cust Copy Text')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DN Firm Copies')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DN Firm Copies')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DN Orig Copy Text')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DN Orig Copy Text')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocGen Default Sort Order')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocGen Default Sort Order')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocGen Default Sort Order')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocGen Default Sort Order')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocGen Default Word Doc Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocGen Default Word Doc Type')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocGen Row Display Limit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocGen Row Display Limit')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocGen Row Display Limit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocGen Row Display Limit')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocItem empty params as nulls')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocItem empty params as nulls')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocItem set null into bookmark')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocItem set null into bookmark')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocItems Command Timeout')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocItems Command Timeout')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocItems Command Timeout')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocItems Command Timeout')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Docket Wizard Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Docket Wizard Action')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Docket Wizard Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Docket Wizard Action')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Docket Wizard Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Docket Wizard Action')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Accelerator')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Accelerator')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Accelerator')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Accelerator')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt ActiveX Fn')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt ActiveX Fn')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt ActiveX Fn')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt ActiveX Fn')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt ActiveX ID')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt ActiveX ID')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt ActiveX ID')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt ActiveX ID')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt ContactDocs')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt ContactDocs')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt ContactDocs')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt ContactDocs')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Directory')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Directory')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Path')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Path')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Path')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Path')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Profile ActiveX Fn')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Profile ActiveX Fn')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Profile ActiveX Fn')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Profile ActiveX Fn')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Profile ActiveX Fn')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Profile ActiveX Fn')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Profile ActiveX ID')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Profile ActiveX ID')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Profile ActiveX ID')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Profile ActiveX ID')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Profile ActiveX ID')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Profile ActiveX ID')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Searching')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Searching')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Searching')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Searching')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Web Link')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Web Link')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Web Link')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Web Link')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Web Link')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Web Link')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Web Link Name')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Web Link Name')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Web Link Name')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Web Link Name')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DocMgmt Web Link Name')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DocMgmt Web Link Name')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Document Attachments Disabled')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Document Attachments Disabled')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Document Attachments Disabled')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Document Attachments Disabled')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Document Attachments Disabled')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Document Attachments Disabled')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Double Discount Restriction')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Double Discount Restriction')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'DRAFTPREFIX')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'DRAFTPREFIX')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Dream Account Prefix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Dream Account Prefix')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Dream Account Prefix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Expense Import'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Dream Account Prefix')  
   where C.INTERNALNAME = 'Expense Import'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Dream Account Prefix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Dream Account Prefix')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Due Date Event Threshhold')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'What''s Due'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Due Date Event Threshhold')  
   where C.INTERNALNAME = 'What''s Due'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Due Date Event Threshhold')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Staff Reminders'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Due Date Event Threshhold')  
   where C.INTERNALNAME = 'Staff Reminders'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Due Date Event Threshhold')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Due Dates'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Due Date Event Threshhold')  
   where C.INTERNALNAME = 'Due Dates'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Due Date Range')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Due Date Range')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Due Date Range')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Due Date Range')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Due Date Report Template')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Due Date Report Template')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Due Date Report Template')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Due Date Report Template')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Due Date Report Template')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Due Date Report Template')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Duplicate Individual Check')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Duplicate Individual Check')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Duplicate Individual Check')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Duplicate Individual Check')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Duplicate Individual Check')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Duplicate Individual Check')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Duplicate Organisation Check')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Duplicate Organisation Check')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Duplicate Organisation Check')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Duplicate Organisation Check')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Duplicate Organisation Check')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Duplicate Organisation Check')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Earliest Priority')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Earliest Priority')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Earliest Priority')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Earliest Priority')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Earliest Priority')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Earliest Priority')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'E-Bill Client Alias Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'E-Bill Client Alias Type')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'E-Bill Law Firm Alias Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'E-Bill Law Firm Alias Type')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'EDE Action Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'EDE Action Code')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'EDE Action Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration Toolkit'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'EDE Action Code')  
   where C.INTERNALNAME = 'Integration Toolkit'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'EDE Ad-hoc Reports')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'EDE Ad-hoc Reports')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'EDE Attention as Main Contact')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'EDE Attention as Main Contact')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'EDE Attention as Main Contact')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'EDE Attention as Main Contact')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'EDE Name Group')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'EDE Name Group')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'EDE Transaction Processing')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'EDE Transaction Processing')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'EDE Transaction Processing')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'EDE Transaction Processing')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Case Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Case Body')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Case Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Case Body')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Case Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Case Body')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Case Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Case Subject')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Case Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Case Subject')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Case Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Case Subject')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Debtor Statement BCC')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Debtor Statement BCC')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Debtor Statement BCC')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Debtor Statement BCC')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Debtor Statement Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Debtor Statement Body')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Debtor Statement Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Debtor Statement Body')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Debtor Statement CC')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Debtor Statement CC')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Debtor Statement CC')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Debtor Statement CC')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Debtor Statement Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Debtor Statement Subject')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Debtor Statement Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Debtor Statement Subject')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Debtor Statement To')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Debtor Statement To')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Debtor Statement To')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Debtor Statement To')  
   where C.INTERNALNAME = 'WIP'
end
go
if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Fee Query Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Fee Query Body')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Fee Query Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Fee Query Body')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Fee Query Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Fee Query Body')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Name Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Name Body')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Name Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Name Body')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Name Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Name Body')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Name Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Name Subject')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Name Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Name Subject')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Name Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Name Subject')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Body')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Body')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Body')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Body')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Date Style')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Date Style')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Format')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Format')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Format')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Format')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Heading')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Heading')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Heading')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Heading')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Heading')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Heading')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Subject')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Email Reminder Subject')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Email Reminder Subject')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Enable Rich Text Formatting')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Enable Rich Text Formatting')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Enable Rich Text Formatting')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Enable Rich Text Formatting')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Enforce Password Policy')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Security'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Enforce Password Policy')  
   where C.INTERNALNAME = 'Security'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Enter Open Item No.')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Enter Open Item No.')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Entity Defaults from Case Office')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Entity Defaults from Case Office')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Entity Defaults from Case Office')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Entity Defaults from Case Office')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Entity Defaults from Case Office')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Entity Defaults from Case Office')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Entity Restriction By Currency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees & Charges'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Entity Restriction By Currency')  
   where C.INTERNALNAME = 'Fees & Charges'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Entity Restriction By Currency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Charge Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Entity Restriction By Currency')  
   where C.INTERNALNAME = 'Charge Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Entity Restriction By Currency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Entity Restriction By Currency')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'EPL Suffix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'EPL Suffix')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Event Display Order')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Event Display Order')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Event Display Order')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Event Display Order')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Event Display Order')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Event Display Order')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Event Link to Workflow Allowed')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Event Link to Workflow Allowed')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Event Link to Workflow Allowed')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Event Link to Workflow Allowed')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Event Link to Workflow Allowed')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Event Link to Workflow Allowed')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Events Display All')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Events Display All')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Events Display All')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Events Display All')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Events Display All')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Events Display All')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Events Displayed')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Events Displayed')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Events Displayed')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Events Displayed')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Events Displayed')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Events Displayed')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Exchange Loss Reason')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Exchange Loss Reason')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Exchange Loss Reason')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Exchange Loss Reason')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Exchange Schedule Mandatory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Exchange Schedule Mandatory')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Exchange Schedule Mandatory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Exchange Schedule Mandatory')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Exchange Schedule Mandatory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Exchange Schedule Mandatory')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Exclude Case Status From Copy')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Exclude Case Status From Copy')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Exclude Case Status From Copy')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Exclude Case Status From Copy')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Exclude Case Status From Copy')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Exclude Case Status From Copy')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Expense Imp Calc WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Expense Imp Calc WIP')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Expense Imp Calc WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Expense Import'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Expense Imp Calc WIP')  
   where C.INTERNALNAME = 'Expense Import'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ExpImp Default Staff')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Expense Import'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ExpImp Default Staff')  
   where C.INTERNALNAME = 'Expense Import'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ExpImp Default Staff')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ExpImp Default Staff')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ExpImp Staff Name')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ExpImp Staff Name')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ExpImp Staff Name')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Expense Import'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ExpImp Staff Name')  
   where C.INTERNALNAME = 'Expense Import'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Export Limit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Export Limit')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'EXTACCOUNTSFLAG')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'EXTACCOUNTSFLAG')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'External DocGen in Use')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'External DocGen in Use')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FeeListNameType')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FeeListNameType')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FeeListNameType')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FeeListNameType')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Fees List Format A')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Fees List Format A')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Fees List Format A')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Fees List Format A')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Fees List Format B')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Fees List Format B')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Fees List Format B')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Fees List Format B')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Fees List shows zero rated')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Fees List shows zero rated')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Fees List shows zero rated')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Fees List shows zero rated')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FeesList Autocreate & Finalise')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FeesList Autocreate & Finalise')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FeesList Autocreate & Finalise')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FeesList Autocreate & Finalise')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FI Export Methods In Use')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FI Export Methods In Use')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FI Export Methods In Use')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FI Export Methods In Use')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FI Include Entity in CMS Export')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FI Include Entity in CMS Export')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FI WIP Payment Preference')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FI WIP Payment Preference')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FI WIP Payment Preference')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FI WIP Payment Preference')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FILE Default Language for Goods and Services')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'FILE'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FILE Default Language for Goods and Services')  
   where C.INTERNALNAME = 'FILE'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FILE Integration Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'FILE'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FILE Integration Event')  
   where C.INTERNALNAME = 'FILE'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'File Location When Moved')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'File Tracking'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'File Location When Moved')  
   where C.INTERNALNAME = 'File Tracking'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'File Location When Moved')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'File Location When Moved')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FILE TM Image Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'FILE'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FILE TM Image Type')  
   where C.INTERNALNAME = 'FILE'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Files In')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Files In')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Files In')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Files In')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Files In')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Files In')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Filing Language')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'FILE'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Filing Language')  
   where C.INTERNALNAME = 'FILE'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Financial Interface with GL')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Financial Interface with GL')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Financial Interface with GL')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Financial Interface with GL')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'First Use Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'First Use Event')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'First Use Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'First Use Event')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'First Use Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'First Use Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'FIStopsBillReversal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'FIStopsBillReversal')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Generate Complete Bill Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Generate Complete Bill Only')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Generate Complete Bill Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Charge Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Generate Complete Bill Only')  
   where C.INTERNALNAME = 'Charge Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Generate Complete Bill Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees & Charges'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Generate Complete Bill Only')  
   where C.INTERNALNAME = 'Fees & Charges'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Generate IR')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Generate IR')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Generate IR')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Generate IR')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Generate IR')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Generate IR')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'GENERATENAMECODE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'GENERATENAMECODE')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'GENERATENAMECODE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'GENERATENAMECODE')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'GENERATENAMECODE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'GENERATENAMECODE')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'GL Journal Creation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'GL Journal Creation')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'GL Journal Creation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'GL Journal Creation')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'GL Preserve Journal Fields')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'GL Preserve Journal Fields')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'GL Preserve Journal Fields')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'General Ledger'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'GL Preserve Journal Fields')  
   where C.INTERNALNAME = 'General Ledger'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Goods and Services Item Text Separator')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Goods and Services Item Text Separator')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Help for external users')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Help for external users')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Help for internal users')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Help for internal users')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Hist Exch For Open Period')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Hist Exch For Open Period')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Hist Exch For Open Period')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Hist Exch For Open Period')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Historical Exch Rate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Historical Exch Rate')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Historical Exch Rate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Charge Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Historical Exch Rate')  
   where C.INTERNALNAME = 'Charge Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'HOLDEXCLUDEDAYS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'HOLDEXCLUDEDAYS')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'HOLDEXCLUDEDAYS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'HOLDEXCLUDEDAYS')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'HOLDEXCLUDEDAYS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'HOLDEXCLUDEDAYS')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Home Country Display on Bill')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Home Country Display on Bill')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Home Country Display on Bill')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Home Country Display on Bill')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Home Parent No')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Home Parent No')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Home Parent No')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Home Parent No')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Home Parent No')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Home Parent No')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'HOMECOUNTRY')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'HOMECOUNTRY')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'HOMECOUNTRY')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'HOMECOUNTRY')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'HOMECOUNTRY')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'HOMECOUNTRY')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'HOMENAMENO')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'HOMENAMENO')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'HOMENAMENO')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'HOMENAMENO')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'HOMENAMENO')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'HOMENAMENO')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'HOMENAMENO')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'HOMENAMENO')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Ignore Case First Linked To')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Ignore Case First Linked To')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Ignore Case First Linked To')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Ignore Case First Linked To')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Ignore Case First Linked To')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Ignore Case First Linked To')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'iLOG table has Identity')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'iLOG table has Identity')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Image Type for Case Header')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Image Type for Case Header')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Image Type for Case Header')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Image Type for Case Header')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Inflation Index Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Inflation Index Code')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'InproDoc Local Templates')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'InproDoc Local Templates')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'InproDoc Local Templates')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'InproDoc Local Templates')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'InproDoc Local Templates')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'InproDoc Local Templates')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'InproDoc Network Templates')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'InproDoc Network Templates')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'InproDoc Network Templates')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'InproDoc Network Templates')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'InproDoc Network Templates')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'InproDoc Network Templates')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Inprotech Web Apps Version')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Inprotech Web Apps Version')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Inprotech Web Apps Version')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Inprotech Web Apps Version')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Input Amend EDE Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Input Amend EDE Action')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Instructions')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Instructions')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Instructions')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Instructions')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Instructions')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Instructions')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Instructions Tab to NonClients')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Instructions Tab to NonClients')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Instructions Tab to NonClients')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Instructions Tab to NonClients')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Instructions Tab to NonClients')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Instructions Tab to NonClients')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Instructor Sequence')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Instructor Sequence')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Instructor Sequence')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Instructor Sequence')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Instructor Sequence')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Instructor Sequence')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Integration Admin Row Count')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Integration Admin Row Count')  
   where C.INTERNALNAME = 'Integration'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Integration Admin Row Count')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration Toolkit'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Integration Admin Row Count')  
   where C.INTERNALNAME = 'Integration Toolkit'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Inter-Entity Billing')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Inter-Entity Billing')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Interim Case Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Interim Case Action')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Interim Case Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Interim Case Action')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Interim Case Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Interim Case Action')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPDOutputFileDir')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPDOutputFileDir')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPDOutputFileDir')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPDOutputFileDir')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPDOutputFilePrefix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPDOutputFilePrefix')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPDOutputFilePrefix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPDOutputFilePrefix')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPDOutputFilePrefix')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees & Charges'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPDOutputFilePrefix')  
   where C.INTERNALNAME = 'Fees & Charges'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPO ClientRef Number Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPO ClientRef Number Type')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPO ClientRef Number Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPO ClientRef Number Type')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOFFICE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOFFICE')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOFFICE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOFFICE')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeAUD')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeAUD')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeAUD')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeAUD')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeAUP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeAUP')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeAUP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeAUP')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeAUT')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeAUT')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeAUT')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeAUT')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeCustomerID')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeCustomerID')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeCustomerID')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeCustomerID')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeDefenceRel')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeDefenceRel')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeDefenceRel')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeDefenceRel')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeDivDateEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeDivDateEvent')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeDivDateEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeDivDateEvent')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeDivDateEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeDivDateEvent')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeDivDateEvent')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeDivDateEvent')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeDivRel')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeDivRel')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficeDivRel')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficeDivRel')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficePriorityRel')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficePriorityRel')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IPOfficePriorityRel')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IPOfficePriorityRel')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IR Check Digit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IR Check Digit')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IR Check Digit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IR Check Digit')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IR Check Digit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IR Check Digit')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IRNLENGTH')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IRNLENGTH')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IRNLENGTH')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IRNLENGTH')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'IRNLENGTH')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'IRNLENGTH')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Journal Printing on Creation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'General Ledger'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Journal Printing on Creation')  
   where C.INTERNALNAME = 'General Ledger'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Journal Printing on Creation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Journal Printing on Creation')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Keep Consolidated Name')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Keep Consolidated Name')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Keep Consolidated Name')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Keep Consolidated Name')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Keep Consolidated Name')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Keep Consolidated Name')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'KEEPREQUESTS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'KEEPREQUESTS')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'KEEPREQUESTS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'KEEPREQUESTS')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'KEEPREQUESTS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'KEEPREQUESTS')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'KEEPSPECIHISTORY')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'KEEPSPECIHISTORY')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'KEEPSPECIHISTORY')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'KEEPSPECIHISTORY')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'KEEPSPECIHISTORY')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'KEEPSPECIHISTORY')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Kind Codes For US Granted Patents')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Kind Codes For US Granted Patents')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'LANGUAGE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'LANGUAGE')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'LANGUAGE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'LANGUAGE')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Lapse Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Lapse Event')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Lapse Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Lapse Event')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Lapse Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Lapse Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Last Expense Import')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Expense Import'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Last Expense Import')  
   where C.INTERNALNAME = 'Expense Import'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'LASTIRN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'LASTIRN')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'LASTIRN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'LASTIRN')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'LASTIRN')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'LASTIRN')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'LASTNAMECODE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'LASTNAMECODE')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'LASTNAMECODE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'LASTNAMECODE')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'LASTNAMECODE')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'LASTNAMECODE')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Launchpad Use New Version')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Launchpad Use New Version')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Law Update Policing Start Time')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Law Update Service'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Law Update Policing Start Time')  
   where C.INTERNALNAME = 'Law Update Service'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Law Update Save Event -11')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Law Update Service'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Law Update Save Event -11')  
   where C.INTERNALNAME = 'Law Update Service'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Law Update Valid Tables')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Law Update Service'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Law Update Valid Tables')  
   where C.INTERNALNAME = 'Law Update Service'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Letters Tab Hidden When Empty')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Letters Tab Hidden When Empty')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Letters Tab Hidden When Empty')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Letters Tab Hidden When Empty')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Letters Tab Hidden When Empty')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Letters Tab Hidden When Empty')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'LETTERSAFTERDAYS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'LETTERSAFTERDAYS')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'LETTERSAFTERDAYS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'LETTERSAFTERDAYS')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Licence Admin Email')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Security'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Licence Admin Email')  
   where C.INTERNALNAME = 'Security'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Licence Admin Email')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Licence Admin Email')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Link from Current Official Number')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Link from Current Official Number')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Link from Current Official Number')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Link from Current Official Number')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Link From Prior Art Official Number')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Link From Prior Art Official Number')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Link From Prior Art Official Number')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Link From Prior Art Official Number')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Link From Related Official Number')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Link From Related Official Number')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Link From Related Official Number')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Link From Related Official Number')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Log Time as GMT')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Log Time as GMT')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Log Time Offset')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Log Time Offset')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Log Username only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Log Username only')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Logging Database')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Logging Database')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Lost File Location')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Lost File Location')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Lost File Location')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'File Location'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Lost File Location')  
   where C.INTERNALNAME = 'File Location'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Main Contact used as Attention')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Main Contact used as Attention')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Main Contact used as Attention')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Main Contact used as Attention')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Main Contact used as Attention')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Main Contact used as Attention')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Main Renewal Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Main Renewal Action')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Main Renewal Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Main Renewal Action')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Main Renewal Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Main Renewal Action')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Main Renewal Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Main Renewal Action')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Maintain File Request History')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'File Tracking'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Maintain File Request History')  
   where C.INTERNALNAME = 'File Tracking'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Maintain File Request History')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Maintain File Request History')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Margin as Separate WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Margin as Separate WIP')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Margin Narrative')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Margin Narrative')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Margin Profiles')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Margin Profiles')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Margin Profiles')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Margin Profiles')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Margin Profiles')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Margin Profiles')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Margin Renewal WIP Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Margin Renewal WIP Code')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Margin WIP Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Margin WIP Code')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Max Invalid Logins')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Max Invalid Logins')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Maximum Concurrent Policing')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Maximum Concurrent Policing')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'MAXLOCATIONS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'File Location'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'MAXLOCATIONS')  
   where C.INTERNALNAME = 'File Location'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'MAXLOCATIONS')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'MAXLOCATIONS')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'MAXSTREETLINES')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'MAXSTREETLINES')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'MAXSTREETLINES')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'MAXSTREETLINES')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'MAXSTREETLINES')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'MAXSTREETLINES')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Minimum WIP Reason')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Minimum WIP Reason')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Alias')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Alias')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Alias')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Alias')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Alias')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Alias')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Code has Check Digit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Code has Check Digit')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Code has Check Digit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Code has Check Digit')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Code has Check Digit')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Code has Check Digit')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Consolidate Financials')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Consolidate Financials')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Consolidate Financials')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Consolidate Financials')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Consolidate Financials')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Consolidate Financials')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Consolidation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Consolidation')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Consolidation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Consolidation')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Consolidation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Consolidation')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Document URL')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Document URL')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Image')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Image')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Image')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Image')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Image')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Image')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Language')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Language')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Language')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Language')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Screen Default Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Screen Default Program')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name search with both keys')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name search with both keys')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name search with both keys')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name search with both keys')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name search with both keys')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name search with both keys')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Style Default')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Style Default')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Style Default')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Style Default')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Style Default')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Style Default')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Variant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Variant')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Variant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Variant')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Name Variant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Name Variant')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'NAMECODELENGTH')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'NAMECODELENGTH')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'NAMECODELENGTH')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'NAMECODELENGTH')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'NAMECODELENGTH')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'NAMECODELENGTH')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Narrative Read Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Narrative Read Only')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Narrative Translate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Narrative Translate')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'NationalityUsePostal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'NationalityUsePostal')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'NationalityUsePostal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'NationalityUsePostal')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'NationalityUsePostal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'NationalityUsePostal')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Numeric Stem Not Defaulted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Numeric Stem Not Defaulted')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Numeric Stem Not Defaulted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Numeric Stem Not Defaulted')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Numeric Stem Not Defaulted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Numeric Stem Not Defaulted')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Office For Replication')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Office For Replication')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Office Restricted Names')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Office Restricted Names')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Office Restricted Names')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Security'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Office Restricted Names')  
   where C.INTERNALNAME = 'Security'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'OfficeGetFromUser')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Security'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'OfficeGetFromUser')  
   where C.INTERNALNAME = 'Security'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'OfficeGetFromUser')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'OfficeGetFromUser')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'OfficePrefixDefault')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'OfficePrefixDefault')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'OfficePrefixDefault')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'OfficePrefixDefault')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Password Expiry Duration')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Security'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Password Expiry Duration')  
   where C.INTERNALNAME = 'Security'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Password Used History')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Security'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Password Used History')  
   where C.INTERNALNAME = 'Security'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Patent Term Adjustments')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'To Do'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Patent Term Adjustments')  
   where C.INTERNALNAME = 'To Do'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Patent Term Adjustments')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Patent Term Adjustments')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Patent Term Adjustments')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Patent Term Adjustments')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Patent Term Adjustments')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Patent Term Adjustments')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF Field Manual Set')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF Field Manual Set')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF Field Manual Set')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF Field Manual Set')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF Field Manual Set')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF Field Manual Set')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF Form Filling')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF Form Filling')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF Form Filling')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF Form Filling')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF Form Filling')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF Form Filling')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF Forms Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF Forms Directory')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF Forms Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF Forms Directory')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF Forms Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF Forms Directory')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF invoice modifiable')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF invoice modifiable')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PDF uses Win2PDF driver')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PDF uses Win2PDF driver')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PenaltyInterestRate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PenaltyInterestRate')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Police Continuously')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Police Continuously')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Police Continuously')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Police Continuously')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Police First Action Immediate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Police First Action Immediate')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Police First Action Immediate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Police First Action Immediate')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Police Immediate in Background')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Police Immediate in Background')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Police Immediate in Background')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Police Immediate in Background')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Police Immediate in Background')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Police Immediate in Background')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Police Immediately')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Police Immediately')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Police Immediately')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Police Immediately')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Police Immediately')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Police Immediately')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Concurrency Control')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Concurrency Control')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Concurrency Control')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Concurrency Control')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Continuously Polling Time')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Continuously Polling Time')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Continuously Polling Time')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Continuously Polling Time')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Continuously Polling Time')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Continuously Polling Time')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Continuously Polling Time')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Continuously Polling Time')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Email Profile')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Email Profile')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Email Profile')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Email Profile')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Loop Count')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Loop Count')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Loop Count')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Loop Count')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Message Interval')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Message Interval')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing On Hold Reset')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing On Hold Reset')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing On Hold Reset')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing On Hold Reset')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Recalculates Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Recalculates Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Recalculates Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Recalculates Event')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Recalculates Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Recalculates Event')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Recalculates Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Recalculates Event')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Reminders On Hold')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Reminders On Hold')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Reminders On Hold')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Reminders On Hold')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Removes Reminders')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Removes Reminders')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Removes Reminders')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Removes Reminders')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Removes Reminders')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Removes Reminders')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Retry After Minutes')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Retry After Minutes')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Retry After Minutes')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Retry After Minutes')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Retry After Minutes')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Retry After Minutes')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Retry After Minutes')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Retry After Minutes')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Rows To Get')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Rows To Get')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Rows To Get')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Rows To Get')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Suppress Reminders')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Suppress Reminders')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Suppress Reminders')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Suppress Reminders')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Update After Seconds')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Update After Seconds')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Uses Row Security')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Uses Row Security')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Policing Uses Row Security')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Policing Uses Row Security')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prepayment Warn Bill')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prepayment Warn Bill')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prepayment Warn Over')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prepayment Warn Over')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prepayments Default Pay For')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prepayments Default Pay For')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prepayments Default Pay For')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prepayments Default Pay For')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Preserve Consolidate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Preserve Consolidate')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prime Cases Detail Entry Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prime Cases Detail Entry Only')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prime Cases Detail Entry Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prime Cases Detail Entry Only')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prime Cases Detail Entry Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prime Cases Detail Entry Only')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Print Draft Only by Default')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Print Draft Only by Default')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Print Draft Only by Default')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Print Draft Only by Default')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prior Art Received')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prior Art Received')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prior Art Received')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prior Art Received')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prior Art Received')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prior Art Received')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prior Art Report Issued')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prior Art Report Issued')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prior Art Report Issued')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prior Art Report Issued')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prior Art Report Issued')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prior Art Report Issued')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prior Art To Case Family')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prior Art To Case Family')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Prior Art To Case Family')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Prior Art'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Prior Art To Case Family')  
   where C.INTERNALNAME = 'Prior Art'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Process Checklist')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Process Checklist')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Process Checklist')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Process Checklist')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Process Checklist')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Process Checklist')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ProduceACCFile')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ProduceACCFile')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ProduceACCFile')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ProduceACCFile')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ProduceIPDFile')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ProduceIPDFile')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'ProduceIPDFile')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'ProduceIPDFile')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Product Recorded on WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Product Recorded on WIP')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Product Support Email')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Product Support Email')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Profit Centre edit locked WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Profit Centre edit locked WIP')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Profit Centre edit locked WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Profit Centre edit locked WIP')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PROMPTCOUNTRY')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PROMPTCOUNTRY')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PROMPTCOUNTRY')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PROMPTCOUNTRY')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'PROMPTCOUNTRY')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'PROMPTCOUNTRY')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Property Type Campaign')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Property Type Campaign')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Property Type Design')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Property Type Design')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Property Type Design')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Property Type Design')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Property Type Design')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Property Type Design')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Property Type Marketing Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Property Type Marketing Event')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Property Type Opportunity')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'CRM'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Property Type Opportunity')  
   where C.INTERNALNAME = 'CRM'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Publish Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Publish Action')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Quick File Request Priority')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Quick File Request Priority')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Quick File Request Priority')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Quick File Request Priority')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Quick File Request Priority')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Quick File Request Priority')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Quotation Gain/Loss')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Quotation Gain/Loss')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Quotation Reference')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Quotation Reference')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Quotations')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Quotations')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Quotations')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Quotations')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Rate mandatory on time items')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Rates Maintenance'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Rate mandatory on time items')  
   where C.INTERNALNAME = 'Rates Maintenance'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Confirm')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Reciprocity'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Confirm')  
   where C.INTERNALNAME = 'Reciprocity'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Confirm')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Confirm')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Confirm')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Confirm')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Confirm')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Confirm')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Counts')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Counts')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Counts')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Counts')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Counts')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Counts')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Counts')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Reciprocity'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Counts')  
   where C.INTERNALNAME = 'Reciprocity'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Disb')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Reciprocity'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Disb')  
   where C.INTERNALNAME = 'Reciprocity'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Disb')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Disb')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Disb')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Disb')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Disb')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Disb')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Event')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Event')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Reciprocity'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Event')  
   where C.INTERNALNAME = 'Reciprocity'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Months')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Reciprocity'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Months')  
   where C.INTERNALNAME = 'Reciprocity'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Months')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Months')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Months')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Months')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reciprocity Months')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reciprocity Months')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Related Case Quick Search Suppressed')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Related Case Quick Search Suppressed')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Related Cases Sort Order')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Related Cases Sort Order')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Related Cases Sort Order')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Related Cases Sort Order')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Related Cases Sort Order')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Related Cases Sort Order')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Relationship - Document Case')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Relationship - Document Case')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Relationship - Document Case')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Relationship - Document Case')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Relationship - Document Case')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Relationship - Document Case')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Case Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Case Program')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Case Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Case Program')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Case Program')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Case Program')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Delete Button')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Staff Reminders'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Delete Button')  
   where C.INTERNALNAME = 'Staff Reminders'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Delete Button')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'To Do'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Delete Button')  
   where C.INTERNALNAME = 'To Do'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Event Text Editable')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Event Text Editable')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Event Text Editable')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Event Text Editable')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Event Text Editable')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Event Text Editable')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Reply Email')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Reply Email')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Reply Email')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Reply Email')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reminder Reply Email')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reminder Reply Email')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renew Ext Pre Grant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renew Ext Pre Grant')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renew Ext Pre Grant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renew Ext Pre Grant')  
   where C.INTERNALNAME = 'Renewals'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renew Ext Pre Grant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renew Ext Pre Grant')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renew Ext Pre Grant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renew Ext Pre Grant')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renew Fee Pre Grant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renew Fee Pre Grant')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renew Fee Pre Grant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renew Fee Pre Grant')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renew Fee Pre Grant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renew Fee Pre Grant')  
   where C.INTERNALNAME = 'Renewals'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renew Fee Pre Grant')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renew Fee Pre Grant')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Display Action Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Display Action Code')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Display Action Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Display Action Code')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Display Action Code')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Display Action Code')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Ext Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Ext Fee')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Ext Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Ext Fee')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Ext Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Ext Fee')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Ext Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Ext Fee')  
   where C.INTERNALNAME = 'Renewals'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Fee')  
   where C.INTERNALNAME = 'Renewals'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Fee')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Fee')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Fee')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Fee')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal imminent days')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal imminent days')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal imminent days')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal imminent days')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Name Type Optional')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees & Charges'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Name Type Optional')  
   where C.INTERNALNAME = 'Fees & Charges'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Name Type Optional')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Charge Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Name Type Optional')  
   where C.INTERNALNAME = 'Charge Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Name Type Optional')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Name Type Optional')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Search on Any Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Search on Any Action')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Search on Any Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Renewals'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Search on Any Action')  
   where C.INTERNALNAME = 'Renewals'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Search on Any Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Search on Any Action')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Renewal Search on Any Action')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Renewal Search on Any Action')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Report by Post Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Report by Post Date')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Report by Post Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Report by Post Date')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Report Server URL')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Report Server URL')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Report Service Entry Folder')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Report Service Entry Folder')  
   where C.INTERNALNAME = 'Billing'
end
go

If exists (SELECT * FROM SITECONTROLCOMPONENTS 
            WHERE SITECONTROLID IN ( SELECT ID FROM SITECONTROL WHERE CONTROLID IN ('Reporting Name Types', 'Reporting Number Type')) 
            AND COMPONENTID = (SELECT COMPONENTID  FROM COMPONENTS WHERE COMPONENTNAME ='x-obsolete'))
BEGIN
    DELETE SITECONTROLCOMPONENTS
    WHERE 
    SITECONTROLID IN (SELECT ID FROM SITECONTROL WHERE CONTROLID IN ('Reporting Name Types', 'Reporting Number Type')) 
    AND COMPONENTID = (SELECT COMPONENTID  FROM COMPONENTS WHERE COMPONENTNAME ='x-obsolete')
END
GO

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reporting Name Types')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reporting Name Types')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reporting Number Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reporting Number Type')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reporting Service Params')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reporting Service Params')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reporting Service Params')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reporting Service Params')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Restrict On WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Restrict On WIP')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Restrict On WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Restrict On WIP')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Resubmit Batch Background')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Resubmit Batch Background')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Resubmit Batch Background')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Resubmit Batch Background')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Revenue Sharer')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Revenue Tracking'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Revenue Sharer')  
   where C.INTERNALNAME = 'Revenue Tracking'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Revenue Sharer')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Revenue Sharer')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Reverse Reconciled')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Reverse Reconciled')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'RFID System')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'File Tracking'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'RFID System')  
   where C.INTERNALNAME = 'File Tracking'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'RFID System')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'RFID System')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Rollover Log Files Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Rollover Log Files Directory')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Rollover Log Files Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Rollover Log Files Directory')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Rollover Runs Day Difference')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Rollover Runs Day Difference')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Rollover Runs Day Difference')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Rollover Runs Day Difference')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Round Up')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Round Up')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Row Security Uses Case Office')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Row Security Uses Case Office')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Row Security Uses Case Office')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Row Security Uses Case Office')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Row Security Uses Case Office')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Row Security Uses Case Office')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SEARCHSOUNDEXFLAG')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SEARCHSOUNDEXFLAG')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SEARCHSOUNDEXFLAG')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SEARCHSOUNDEXFLAG')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SEARCHSOUNDEXFLAG')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SEARCHSOUNDEXFLAG')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Sell Rate Only for New WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Sell Rate Only for New WIP')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Send DocGen Email via DB Mail')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Send DocGen Email via DB Mail')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Send DocGen Email via DB Mail')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Send DocGen Email via DB Mail')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Session Reports')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Session Reports')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Billing Currency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Billing Currency')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Billing Currency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Billing Currency')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Billing Currency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Billing Currency')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Criteria Number')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Control'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Criteria Number')  
   where C.INTERNALNAME = 'Control'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Criteria Number')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Criteria Number')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show extra addresses')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show extra addresses')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show extra addresses')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show extra addresses')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show extra addresses')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show extra addresses')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show extra telecom')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show extra telecom')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show extra telecom')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show extra telecom')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Past Reminders')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Past Reminders')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Past Reminders')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Past Reminders')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Past Reminders')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Past Reminders')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Screen Tips')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Screen Tips')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Screen Tips')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Screen Tips')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Show Screen Tips')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Show Screen Tips')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SHOWNAMECODEFLAG')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SHOWNAMECODEFLAG')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SHOWNAMECODEFLAG')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SHOWNAMECODEFLAG')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SHOWNAMECODEFLAG')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SHOWNAMECODEFLAG')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SiteBank')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SiteBank')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SiteBank')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SiteBank')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SiteBankAccount')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SiteBankAccount')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SiteBankAccount')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SiteBankAccount')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Smart Policing')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Smart Policing')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Smart Policing')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Smart Policing')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Smart Policing Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Policing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Smart Policing Only')  
   where C.INTERNALNAME = 'Policing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Smart Policing Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Smart Policing Only')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Spelling Dictionary')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Spelling Dictionary')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Spelling Dictionary')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Spelling Dictionary')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Spelling Dictionary')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Spelling Dictionary')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SQL Templates via MDAC Wrapper')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SQL Templates via MDAC Wrapper')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SQL Templates via MDAC Wrapper')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SQL Templates via MDAC Wrapper')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SQL Templates via MDAC Wrapper')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'E-filing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SQL Templates via MDAC Wrapper')  
   where C.INTERNALNAME = 'E-filing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'SQL Templates via MDAC Wrapper')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'SQL Templates via MDAC Wrapper')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Staff Manual Entry For WIP')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Staff Manual Entry For WIP')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Staff Responsible')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Staff Responsible')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Staff Responsible')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Staff Responsible')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Staff Responsible')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Staff Responsible')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Standard Daily Hours')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Standard Daily Hours')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statement-Multi 0')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statement-Multi 0')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statement-Multi 1')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statement-Multi 1')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statement-Multi 9')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statement-Multi 9')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statements Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statements Directory')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statements Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statements Directory')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statements Email Telecom Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statements Email Telecom Type')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statements Email Telecom Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statements Email Telecom Type')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statements Printer')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statements Printer')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statements Printer')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statements Printer')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statements Sender Email')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statements Sender Email')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statements Sender Email')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statements Sender Email')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Statement-Single')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Statement-Single')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Stop Processing Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Stop Processing Event')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Stop Processing Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Stop Processing Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Substitute In Payment Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Substitute In Payment Date')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Substitute In Payment Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Substitute In Payment Date')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Substitute In Payment Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Substitute In Payment Date')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Substitute In Renewal Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Substitute In Renewal Date')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Substitute In Renewal Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Substitute In Renewal Date')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Substitute In Renewal Date')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Substitute In Renewal Date')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Supervisor Approval Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Supervisor Approval Event')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Supervisor Approval Event')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Supervisor Approval Event')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Supervisor Approval Overdue')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Supervisor Approval Overdue')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Supervisor Approval Overdue')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Supervisor Approval Overdue')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Supplier Alias')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Supplier Alias')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Supplier Alias')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Supplier Alias')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Supplier shows full details')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Payable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Supplier shows full details')  
   where C.INTERNALNAME = 'Accounts Payable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Supplier shows full details')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Supplier shows full details')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Suppress Bill To Prompt')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Suppress Bill To Prompt')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tax Code by Owners')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tax Code by Owners')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tax Code by Owners')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tax Code by Owners')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tax Code by Owners')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tax Code by Owners')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tax Code for EU billing')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tax Code for EU billing')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tax for HOMECOUNTRY Multi-Tier')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tax for HOMECOUNTRY Multi-Tier')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tax Prepayments')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tax Prepayments')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tax Prepayments')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tax Prepayments')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tax Prepayments')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tax Prepayments')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tax Source Country Derived from Entity')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tax Source Country Derived from Entity')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'TAXLITERAL')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'TAXLITERAL')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'TAXREQUIRED')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'TAXREQUIRED')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Telecom Details Hidden')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Telecom Details Hidden')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Telecom Details Hidden')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Telecom Details Hidden')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Telecom Details Hidden')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Telecom Details Hidden')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Telecom Type - Home Page')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Telecom Type - Home Page')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Telecom Type - Home Page')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Telecom Type - Home Page')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Telecom Type - Home Page')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Telecom Type - Home Page')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Temporary IR')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Temporary IR')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Temporary IR')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Temporary IR')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Temporary IR')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Temporary IR')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Time empty for new entries')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Time empty for new entries')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Time Post Batch Size')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Time Post Batch Size')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Timesheet show Case Narrative')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Timesheet show Case Narrative')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Timesheet show Custom Content')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Timesheet show Custom Content')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Timesheet Single Timer Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'x-obsolete'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Timesheet Single Timer Only')  
   where C.INTERNALNAME = 'x-obsolete'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tip for Letters')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tip for Letters')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tip for Letters')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tip for Letters')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Tip for Letters')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Tip for Letters')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'TR External Change')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'TR External Change')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'TR External Change')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'TR External Change')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'TR Internal Change')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'TR Internal Change')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'TR Internal Change')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
    from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'TR Internal Change')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'TR IP Office Verification')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'TR IP Office Verification')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'TR IP Office Verification')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'TR IP Office Verification')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Track Recent Cases')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Track Recent Cases')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Track Recent Cases')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Track Recent Cases')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Track Recent Cases')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Track Recent Cases')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Trading Terms')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Trading Terms')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Trading Terms')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Trading Terms')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Trading Terms')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Trading Terms')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Transaction Reason')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Transaction Reason')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Transaction Reason')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Transaction Reason')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Transaction Reason')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Transaction Reason')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Transaction Reason')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'EDE Module'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Transaction Reason')  
   where C.INTERNALNAME = 'EDE Module'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'TransactionGeneration Log Dir')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'TransactionGeneration Log Dir')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'TransactionGeneration Log Dir')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'General Ledger'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'TransactionGeneration Log Dir')  
   where C.INTERNALNAME = 'General Ledger'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Transfer Discount With Associated Item')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Transfer Discount With Associated Item')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Unalloc BillCurrency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Accounts Receivable'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Unalloc BillCurrency')  
   where C.INTERNALNAME = 'Accounts Receivable'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Unalloc BillCurrency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Unalloc BillCurrency')  
   where C.INTERNALNAME = 'Financial Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Units Per Hour')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Units Per Hour')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Use Original Transaction Date By Default')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Use Original Transaction Date By Default')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'USPTO Private PAIR Enabled')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'USPTO Private PAIR Enabled')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Valid Pattern for Email Addresses')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Valid Pattern for Email Addresses')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'VAT uses bill exchange rate')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'VAT uses bill exchange rate')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'VerifyFeeListFunds')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees List'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'VerifyFeeListFunds')  
   where C.INTERNALNAME = 'Fees List'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'VerifyFeeListFunds')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'VerifyFeeListFunds')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Web Max Ad Hoc Dates')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Web Max Ad Hoc Dates')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Web Max Ad Hoc Dates')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Web Max Ad Hoc Dates')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Web Max Ad Hoc Dates')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Web Max Ad Hoc Dates')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Welcome Message - External')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Client Access'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Welcome Message - External')  
   where C.INTERNALNAME = 'Client Access'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Welcome Message - External')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Welcome Message - External')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Welcome Message - Internal')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Welcome Message - Internal')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Welcome Message - Global')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Welcome Message - Global')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Associate Use Agent Item')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Associate Use Agent Item')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Associate Use Agent Item')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Associate Use Agent Item')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP default to service charge')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP default to service charge')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Dissection Restricted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Dissection Restricted')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Link to Partner')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Link to Partner')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Link to Renewal Staff')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Link to Renewal Staff')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP NameType Default')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP NameType Default')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP NameType Group')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP NameType Group')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP NameType Group')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP NameType Group')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Narrative Adjustment')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Narrative Adjustment')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Narrative Adjustment')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Narrative Adjustment')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Only')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Charge Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Only')  
   where C.INTERNALNAME = 'Charge Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Only')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Fees & Charges'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Only')  
   where C.INTERNALNAME = 'Fees & Charges'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Profit Centre Source')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Profit Centre Source')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Profit Centre Source')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Profit Centre Source')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Recording by Charge')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Recording by Charge')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Recording by Charge')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Recording by Charge')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Split Multi Debtor')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Split Multi Debtor')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Split Multi Debtor')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Split Multi Debtor')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Summary Currency Options')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Summary Currency Options')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Summary Display Amounts As')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Summary Display Amounts As')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Transaction Log Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Transaction Log Directory')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Transaction Log Directory')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Transaction Log Directory')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Verification No Enforced')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'WIP'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Verification No Enforced')  
   where C.INTERNALNAME = 'WIP'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Write Down Restricted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Write Down Restricted')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIP Write Down Restricted')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Timesheet'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIP Write Down Restricted')  
   where C.INTERNALNAME = 'Timesheet'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WIPFixedCurrency')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WIPFixedCurrency')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Wizard Show Menus')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Wizard Show Menus')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Wizard Show Menus')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Wizard Show Menus')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Wizard Show Menus')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Wizard Show Menus')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Wizard Show Tabs')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Wizard Show Tabs')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Wizard Show Tabs')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Wizard Show Tabs')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Wizard Show Tabs')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Wizard Show Tabs')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Wizard Show Toolbar')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Case'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Wizard Show Toolbar')  
   where C.INTERNALNAME = 'Case'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Wizard Show Toolbar')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Name'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Wizard Show Toolbar')  
   where C.INTERNALNAME = 'Name'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Wizard Show Toolbar')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Wizard Show Toolbar')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WorkBench Administrator Email')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Inprotech'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WorkBench Administrator Email')  
   where C.INTERNALNAME = 'Inprotech'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'WorkBench Contact Name Type')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'WorkBench Contact Name Type')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'Workbench Max Image Size')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'Workbench Max Image Size')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'XML Bill Ref-Automatic')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Billing'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'XML Bill Ref-Automatic')  
   where C.INTERNALNAME = 'Billing'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'XML Document Generation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'XML Document Generation')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'XML Document Generation')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'IP Matter Management'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'XML Document Generation')  
   where C.INTERNALNAME = 'IP Matter Management'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'XML Text Output ANSI')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Integration Toolkit'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'XML Text Output ANSI')  
   where C.INTERNALNAME = 'Integration Toolkit'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'XML Text Output ANSI')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Document Generation'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'XML Text Output ANSI')  
   where C.INTERNALNAME = 'Document Generation'
end
go

if not exists (select 1 from SITECONTROLCOMPONENTS SC 
                 join SITECONTROL S on (S.ID = SC.SITECONTROLID and S.CONTROLID = 'XML Text Output ANSI')
                 join COMPONENTS C on (C.COMPONENTID = SC.COMPONENTID and C.INTERNALNAME = 'Financial Interface'))
begin
   insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
   select S.ID, C.COMPONENTID   
   from COMPONENTS C   
   join SITECONTROL S on (S.CONTROLID = 'XML Text Output ANSI')  
   where C.INTERNALNAME = 'Financial Interface'
end
go

