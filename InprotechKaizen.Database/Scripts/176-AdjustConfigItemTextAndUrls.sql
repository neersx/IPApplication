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


/*  include new components */

insert into COMPONENTS (COMPONENTNAME, INTERNALNAME)
select f.Parameter, f.Parameter
from dbo.fn_Tokenise('To Do,Web Links,Checklist,Data Validation,Screen Designer,Case Comparison,Workflow Designer,General Configuration,Third Party Applications',',') f
where not exists (
	select C1.COMPONENTNAME
	from COMPONENTS C1
	where C1.COMPONENTNAME = f.Parameter)

GO

/* update existing component */
IF(NOT EXISTS(SELECT 1 FROM COMPONENTS WHERE COMPONENTNAME = 'Integration'))
BEGIN
Update COMPONENTS 
set COMPONENTNAME = 'Integration', INTERNALNAME = 'Integration' 
where COMPONENTNAME='Integration Software'
END
GO

/* update all configuration items so they have a title */

update C
set C.TITLE = T.TASKNAME,
	C.DESCRIPTIon = T.DESCRIPTION
from CONFIGURATIONITEM C
join TASK T on C.TASKID = T.TASKID
where C.TASKID in (57, 75, 83, 115)

GO

/* update all configuration items */

update CONFIGURATIONITEM 
set TITLE = 'First To File Access' 
where TITLE like '%Access to First To File'

GO

update CONFIGURATIONITEM
set TITLE = REPLACE(TITLE, 'Workflows', 'Workflow Designer')
where TITLE like '%Rules - Workflows'

GO

IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 239 and GENERICPARAM = N'FILE' )
    BEGIN	
		INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL, GENERICPARAM) VALUES(
	    239,
	    N'Data Mapping for FILE',
	    N'Create, update or delete data mappings for FILE.', N'/apps/#/configuration/general/ede/datamapping/File', N'FILE')
        PRINT ''
    END
go

IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 239 and GENERICPARAM = N'Innography' )
    BEGIN	
		INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL, GENERICPARAM) VALUES(
	    239,
	    N'Data Mapping for Innography',
	    N'Create, update or delete data mappings for Innography.', N'/apps/#/configuration/general/ede/datamapping/Innography', N'Innography')
        PRINT ''
    END
go

update CONFIGURATIONITEM
set URL = '/apps/#/integration/ptoaccess/schedules'
where TITLE LIKE 'Schedule%' AND URL IS null

update CONFIGURATIONITEM
set TITLE = REPLACE(TITLE, 'Maintain ', '')
where TITLE like 'Maintain %'

update CONFIGURATIONITEMGROUP 
set TITLE = REPLACE(TITLE, 'Maintain ', '')
where TITLE like 'Maintain %'

update CONFIGURATIONITEM
set TITLE = REPLACE(TITLE, 'Configure ', '')
where TITLE like 'Configure %'

update CONFIGURATIONITEM 
set TITLE = 'USPTO Practitioner Sponsorship' 
where TITLE like '%USPTO Certificate'

update CONFIGURATIONITEM 
set TITLE = 'First To File Document Uploads' 
where TITLE = 'Manage First To File Document Uploads'

update CONFIGURATIONITEM 
set TITLE = 'Jurisdictions' 
where TITLE = 'View Jurisdictions'

update CONFIGURATIONITEM 
set GROUPID = null 
where TITLE = 'EPO Integration Settings'

update CONFIGURATIONITEM 
set URL = '/apps/#/configuration/rules/workflows'
where TITLE like '%Workflow Designer%' and URL is null

GO

IF NOT exists (select * FROM CONFIGURATIONITEMGROUP WHERE ID = 3)
Begin
    INSERT INTO CONFIGURATIONITEMGROUP (ID, TITLE, DESCRIPTION, URL)
	VALUES (3, 'Jurisdictions', 'Maintain Jurisdictions for the firm.', '/apps/#/configuration/general/jurisdictions')
END
GO

update CONFIGURATIONITEM 
set GROUPID  = 3 
where TITLE = 'Jurisdictions'
GO
