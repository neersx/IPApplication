if exists (select * from sysobjects where type='TR' and name = 'DeleteSEARCHRESULTS_ids')
begin
	PRINT 'Refreshing trigger DeleteSEARCHRESULTS_ids...'
	DROP TRIGGER DeleteSEARCHRESULTS_ids
end
go

Create trigger DeleteSEARCHRESULTS_ids on SEARCHRESULTS INSTEAD OF DELETE NOT FOR REPLICATION as
Begin
-- TRIGGER:	DeleteSEARCHRESULTS_ids
-- VERSION:	1
-- DESCRIPTION:	Trigger the deletion of child tables that reference the 
--		SEARCHRESULTS table. These are tables where declarative
--		referential integrity cannot be used due to complex
--		relationships.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Mar 2011	MF	10361 	1	Created

	----------------------------------------------------
	-- Deletion of rows from the SEARCHRESULTS table
	-- will cause a cascade delete of referencing 
	-- tables that could not be handled by the
	-- declarative referential integrity rules.
	----------------------------------------------------

	------------------------------------------------------
	-- Delete FAMILYSEARCHRESULT where match on PRIORARTID
	------------------------------------------------------
	delete SR
	from deleted d
	join FAMILYSEARCHRESULT SR on (SR.PRIORARTID=d.PRIORARTID)

	----------------------------------------------------
	-- Delete NAMESEARCHRESULT where match on PRIORARTID
	----------------------------------------------------
	delete SR
	from deleted d
	join NAMESEARCHRESULT SR on (SR.PRIORARTID=d.PRIORARTID)

	----------------------------------------------------
	-- Delete REPORTCITATIONS where match on PRIORARTID
	----------------------------------------------------
	delete R
	from deleted d
	join REPORTCITATIONS R on (R.CITEDPRIORARTID=d.PRIORARTID)

	----------------------------------------------------
	-- Delete CASESEARCHRESULT where match on PRIORARTID
	----------------------------------------------------
	delete SR
	from deleted d
	join CASESEARCHRESULT SR on (SR.PRIORARTID=d.PRIORARTID)

	----------------------------------------------------
	-- Delete SEARCHRESULTS now child rows are deleted
	----------------------------------------------------
	delete SR
	from deleted d
	join SEARCHRESULTS SR on (SR.PRIORARTID=d.PRIORARTID)
End
go
