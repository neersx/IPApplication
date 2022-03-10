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

/*  include Batch Event Update component */

IF NOT EXISTS (select * from COMPONENTS where COMPONENTNAME = 'Batch Event Update')
BEGIN
    insert into COMPONENTS (COMPONENTNAME,INTERNALNAME) values ('Batch Event Update','Batch Event Update')
END
GO


