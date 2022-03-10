if not exists (	select * 
				from RELEASEVERSIONS 
				where VERSIONNAME = 'Inprotech Apps 5.2')
begin

	insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
	values('Inprotech Apps 5.2', '20180302', 520000)

end
go

if not exists (select * from SITECONTROL where CONTROLID = 'FILE Default Language for Goods and Services')
begin

		declare @versionId int

		select @versionId = VERSIONID
		from RELEASEVERSIONS
		where VERSIONNAME = 'Inprotech Apps 5.2'

		insert SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, NOTES, INITIALVALUE, COMMENTS, VERSIONID)
		values (N'FILE Default Language for Goods and Services', 'I', null, 
				N'This value specifies the language that should be used for any Goods and Services text sent to FILE. If this is the same as the default language of the firm, then leave blank.',
				null,
				N'Specifies the language that should be used for Goods and Services text sent to FILE.',
				@versionId)
end
go

if not exists (select * 
				from SITECONTROLCOMPONENTS SC 
				join COMPONENTS C on SC.COMPONENTID = C.COMPONENTID
				join SITECONTROL S on SC.SITECONTROLID = S.ID
				where C.COMPONENTNAME = 'FILE'
				and S.CONTROLID = N'FILE Default Language for Goods and Services')
begin				

		insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
		select S.ID, C.COMPONENTID   
		from COMPONENTS C   
		join SITECONTROL S on (S.CONTROLID = N'FILE Default Language for Goods and Services')  
		where C.COMPONENTNAME = 'FILE'

end
go
		