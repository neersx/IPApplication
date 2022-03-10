if exists (select * from sysobjects where type='TR' and name = 'DeleteCASELISTMEMBER_ids')
begin
	PRINT 'Refreshing trigger DeleteCASELISTMEMBER_ids...'
	DROP TRIGGER DeleteCASELISTMEMBER_ids
end
go

Create trigger DeleteCASELISTMEMBER_ids on CASELISTMEMBER for DELETE NOT FOR REPLICATION as
Begin
-- TRIGGER:	DeleteCASELISTMEMBER_ids    
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Mar 2011	MF	6563 	1	Created

	-------------------------------------------------------
	-- Removal of a CASE from a CASELIST by deletion of the
	-- CASELISTMEMBER row should subsequently remove the
	-- CASESEARCHRESULT rows for that Case that were
	-- inserted as result of its membership of the CASELIST.
	-------------------------------------------------------
	Delete CSR
	from deleted d
	join CASELISTSEARCHRESULT L
				on (L.CASELISTNO=d.CASELISTNO)
	join CASESEARCHRESULT CSR
				on (CSR.CASELISTPRIORARTID=L.CASELISTPRIORARTID
				and CSR.CASEID=d.CASEID)

End -- End trigger
go
