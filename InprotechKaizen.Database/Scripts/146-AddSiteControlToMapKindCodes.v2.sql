if not exists (	select * 
				from RELEASEVERSIONS 
				where VERSIONNAME = 'Inprotech Apps 4.5')
begin

	insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
	values('Inprotech Apps 4.5', '20170715', 450000)

end
go

if not exists (select * from SITECONTROL where CONTROLID = 'Kind Codes For US Granted Patents')
begin

		declare @versionId int

		select @versionId = VERSIONID
		from RELEASEVERSIONS
		where VERSIONNAME = 'Inprotech Apps 4.5'

		insert SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, NOTES, INITIALVALUE, COMMENTS, VERSIONID)
		values ('Kind Codes For US Granted Patents', 'C', 'B1,B2', 
				'A Kind Code on a US Patent provides a quick way to see if a patent has been granted. The Inprotech prior art module will check the Kind Code and if it is B1 or B2, the date on that prior art will be considered to be the grant date, and the official number will be the grant number. Enter the kind codes that indicate US patents have been granted separated by a comma.',
				'B1,B2',
				'The Kind Code for US Patents indicates if the patent has been granted or not. If the code is B1 or B2, then the date on prior art will be considered to be the grant date, and the official number will be the grant number.',
				@versionId)
end
go

if not exists (select * 
				from SITECONTROLCOMPONENTS SC 
				join COMPONENTS C on SC.COMPONENTID = C.COMPONENTID
				join SITECONTROL S on SC.SITECONTROLID = S.ID
				where C.COMPONENTNAME = 'IP Matter Management'
				and S.CONTROLID = 'Kind Codes For US Granted Patents')
begin				

		insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
		select S.ID, C.COMPONENTID   
		from COMPONENTS C   
		join SITECONTROL S on (S.CONTROLID = 'Kind Codes For US Granted Patents')  
		where C.COMPONENTNAME = 'IP Matter Management'

end
go
