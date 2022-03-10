/** DR-19053 Workbenches component is misleading for site controls **/

IF NOT EXISTS (select 1 from SITECONTROL S INNER JOIN SITECONTROLCOMPONENTS SC on S.ID = SC.SITECONTROLID
											INNER JOIN COMPONENTS C on C.COMPONENTID = SC.COMPONENTID 
											where S.CONTROLID = 'Time Post Batch Size' and c.INTERNALNAME = 'Timesheet')
BEGIN
	insert into SITECONTROLCOMPONENTS(SITECONTROLID,COMPONENTID)
	values (
			(select ID from SITECONTROL where CONTROLID = 'Time Post Batch Size'),
			(select COMPONENTID from COMPONENTS where INTERNALNAME = 'Timesheet')
		)
END
GO

IF EXISTS (select 1 from COMPONENTS where INTERNALNAME = 'Workbenches')
BEGIN
    delete from SITECONTROLCOMPONENTS where COMPONENTID = (select COMPONENTID from COMPONENTS where INTERNALNAME = 'Workbenches')
	delete from COMPONENTS where INTERNALNAME = 'Workbenches'
END
GO