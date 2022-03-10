if not exists (	select * 
				from RELEASEVERSIONS 
				where VERSIONNAME = 'Inprotech Apps 5.2')
begin

	insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
	values('Inprotech Apps 5.2', '20180302', 520000)

end
go

if not exists (select * from SITECONTROL where CONTROLID = 'FILE TM Image Type')
begin

		declare @versionId int

		select @versionId = VERSIONID
		from RELEASEVERSIONS
		where VERSIONNAME = 'Inprotech Apps 5.2'

		insert SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, NOTES, INITIALVALUE, COMMENTS, VERSIONID)
		values (N'FILE TM Image Type', 'C', '1201', 
				N'An image will be included in a Trade Mark instruction being sent to FILE if it is the same Image Type as one listed in this Site Control. One or more Image Types can be specified, separated by commas, in order of preference. If the case includes several images of the preferred Image Type, the one with the lowest order number will be included. The Trade Mark Image Type will be the default value.',
				'1201',
				N'Specifies the Image Types that must exist on a Trade Mark for an image to be included in an instruction to FILE.',
				@versionId)
end
go

if not exists (select * 
				from SITECONTROLCOMPONENTS SC 
				join COMPONENTS C on SC.COMPONENTID = C.COMPONENTID
				join SITECONTROL S on SC.SITECONTROLID = S.ID
				where C.COMPONENTNAME = 'FILE'
				and S.CONTROLID = N'FILE TM Image Type')
begin				

		insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
		select S.ID, C.COMPONENTID   
		from COMPONENTS C   
		join SITECONTROL S on (S.CONTROLID = N'FILE TM Image Type')  
		where C.COMPONENTNAME = 'FILE'

end
go
		