if not exists (select * from SITECONTROL where CONTROLID = 'Background Process Login ID')
begin

       insert SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, COMMENTS)
       values ('Background Process Login ID', 'C', null, 'The Inprotech Web user Login ID to use for audit trail purposes when processing system initiated background processes.')
end
go