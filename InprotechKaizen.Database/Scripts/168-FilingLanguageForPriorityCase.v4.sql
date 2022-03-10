if not exists (	select * 
				from RELEASEVERSIONS 
				where VERSIONNAME = 'Inprotech Apps 5.0')
begin

	insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
	values('Inprotech Apps 5.0', '20171124', 500000)

end
go

if not exists (select * from SITECONTROL where CONTROLID = 'Filing Language')
begin

		declare @versionId int

		select @versionId = VERSIONID
		from RELEASEVERSIONS
		where VERSIONNAME = 'Inprotech Apps 5.0'

		insert SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, NOTES, INITIALVALUE, COMMENTS, VERSIONID)
		values ('Filing Language', 'C', 'FILING_LANGUAGE', 
				'The name of the Data Item that will be used to return the filing language of a case.',
				'FILING_LANGUAGE',
				'The name of the Data Item that will be used to return the filing language of a case, which is required when creating an instruction in FILE for a direct Patent. ',
				@versionId)
end
go

if not exists (select * 
				from SITECONTROLCOMPONENTS SC 
				join COMPONENTS C on SC.COMPONENTID = C.COMPONENTID
				join SITECONTROL S on SC.SITECONTROLID = S.ID
				where C.COMPONENTNAME = 'FILE'
				and S.CONTROLID = 'Filing Language')
begin				

		insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
		select S.ID, C.COMPONENTID   
		from COMPONENTS C   
		join SITECONTROL S on (S.CONTROLID = 'Filing Language')  
		where C.COMPONENTNAME = 'FILE'

end
go


If not exists(select 1 from ITEM where ITEM_NAME='FILING_LANGUAGE')
begin
	-------------------------------------------
	-- Insert a new docitem into the ITEM table
	-- for use in the data validation
	-------------------------------------------
	declare @nItemId	int
	
	update L
	set @nItemId=1+(select MAX(ITEM_ID) from ITEM),
	    INTERNALSEQUENCE=@nItemId
	From LASTINTERNALCODE L
	Where L.TABLENAME='ITEM'
	
	INSERT into ITEM(ITEM_ID, ITEM_NAME, SQL_QUERY, ITEM_DESCRIPTION, ITEM_TYPE, ENTRY_POINT_USAGE, SQL_DESCRIBE, SQL_INTO, CREATED_BY, DATE_CREATED, DATE_UPDATED)
	Values (@nItemId, 'FILING_LANGUAGE', 'Select ''English''', 'Returns the filing language of the given case', 0, 1, 1, ':s[0]', left(system_user, 18), GETDATE(), GETDATE() )
END
go
		