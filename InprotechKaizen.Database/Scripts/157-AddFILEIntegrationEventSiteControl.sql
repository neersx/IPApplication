/** DR-42320 Updating column COMPONENT.INTERNALNAME	and removing default constraint**/

If exists (SELECT 1 FROM COMPONENTS WHERE INTERNALNAME = '')
BEGIN
	PRINT '**** DR-42320 Populating column COMPONENT.INTERNALNAME from COMPONENT.COMPONENTNAME'
	Update COMPONENTS set INTERNALNAME = COMPONENTNAME WHERE INTERNALNAME = ''
	Declare @ConstraintName nvarchar(200)
	Select @ConstraintName = d.Name
	from sys.tables t
		join sys.default_constraints d on (d.parent_object_id = t.object_id)
		join sys.columns c on (c.object_id = t.object_id
		and c.column_id = d.parent_column_id)
	where t.name = 'COMPONENTS'
		and c.name = 'INTERNALNAME'
	IF @ConstraintName IS NOT NULL
	BEGIN
		EXEC('ALTER TABLE COMPONENTS DROP CONSTRAINT ' + @ConstraintName)
		PRINT '**** DR-42320 Column COMPONENT.INTERNALNAME drop default constraint' 
	END
	PRINT '**** DR-42320 Column COMPONENT.INTERNALNAME populated' 

	EXEC ipu_UtilGenerateAuditTriggers 'COMPONENTS'
END
GO

if not exists (	select * 
				from RELEASEVERSIONS 
				where VERSIONNAME = 'Inprotech Apps 4.7')
begin

	insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
	values('Inprotech Apps 4.7', '20171013', 470000)

end
go


if not exists (select * from SITECONTROL where CONTROLID = 'FILE Integration Event')
begin

		declare @versionId int

		select @versionId = VERSIONID
		from RELEASEVERSIONS
		where VERSIONNAME = 'Inprotech Apps 4.7'

		insert SITECONTROL (CONTROLID, DATATYPE, COLINTEGER, NOTES, INITIALVALUE, COMMENTS, VERSIONID)
		values ('FILE Integration Event', 'I', null, 
				'The Event Number that will be populated in a case to indicate that the case has also been created in FILE.',
				null,
				'The system will retrieve status changes for cases with this Event.',
				@versionId)
end
go

if not exists (select *
				from COMPONENTS where COMPONENTNAME = 'FILE')
begin

	insert into COMPONENTS (COMPONENTNAME, INTERNALNAME) values ('FILE', 'FILE')

end
go

if not exists (select * 
				from SITECONTROLCOMPONENTS SC 
				join COMPONENTS C on SC.COMPONENTID = C.COMPONENTID
				join SITECONTROL S on SC.SITECONTROLID = S.ID
				where C.COMPONENTNAME = 'FILE'
				and S.CONTROLID = 'FILE Integration Event')
begin				

		insert into SITECONTROLCOMPONENTS (SITECONTROLID, COMPONENTID)  
		select S.ID, C.COMPONENTID   
		from COMPONENTS C   
		join SITECONTROL S on (S.CONTROLID = 'FILE Integration Event')  
		where C.COMPONENTNAME = 'FILE'

end
go
