if exists (select * from sysobjects where type='TR' and name = 'DeleteREPORTCITATIONS_ids')
begin
	PRINT 'Refreshing trigger DeleteREPORTCITATIONS_ids...'
	DROP TRIGGER DeleteREPORTCITATIONS_ids
end
go

Create trigger DeleteREPORTCITATIONS_ids on REPORTCITATIONS for DELETE NOT FOR REPLICATION as
Begin
-- TRIGGER:	DeleteREPORTCITATIONS_ids
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Mar 2011	MF	6563 	1	Created

	--------------------------------------------------
	-- PriorArt that was cited against a Search Report
	-- that is now no longer cited, will have its
	-- REPORTCITATION row removed, to break the link
	-- between the Source Document and the Prior Art.
	-- This delete should trigger the removal of the
	-- Cases determined from the Source Documnent that
	-- are linked to the Prior Art.
	-------------------------------------------------------

	-------------------------------------------------------
	-- Remove the Cases linked to PriorArt that were found
	-- from the FAMILYSEARCHRESULT
	-------------------------------------------------------
	Delete CSR
	from deleted d
	join FAMILYSEARCHRESULT F
				on (F.PRIORARTID=d.SEARCHREPORTID)
	join CASESEARCHRESULT CSR
				on (CSR.FAMILYPRIORARTID=F.FAMILYPRIORARTID
				and CSR.PRIORARTID=d.CITEDPRIORARTID)

	-------------------------------------------------------
	-- Remove the Cases linked to PriorArt that were found
	-- from the CASELISTSEARCHRESULT
	-------------------------------------------------------
	Delete CSR
	from deleted d
	join CASELISTSEARCHRESULT L
				on (L.PRIORARTID=d.SEARCHREPORTID)
	join CASESEARCHRESULT CSR
				on (CSR.CASELISTPRIORARTID=L.CASELISTPRIORARTID
				and CSR.PRIORARTID=d.CITEDPRIORARTID)


	-------------------------------------------------------
	-- Remove the Cases linked to PriorArt that were found
	-- from the NAMESEARCHRESULT
	-------------------------------------------------------
	Delete CSR
	from deleted d
	join NAMESEARCHRESULT N	on (N.PRIORARTID=d.SEARCHREPORTID)
	join CASESEARCHRESULT CSR
				on (CSR.NAMEPRIORARTID=N.NAMEPRIORARTID
				and CSR.PRIORARTID=d.CITEDPRIORARTID)


	-------------------------------------------------------
	-- Remove the Cases linked to PriorArt where the Cases
	-- where linked directly to Source Document.
	-------------------------------------------------------
	Delete CSR
	from deleted d
	join CASESEARCHRESULT PAR
				on (PAR.PRIORARTID=d.SEARCHREPORTID
				and PAR.FAMILYPRIORARTID   is null
				and PAR.CASELISTPRIORARTID is null
				and PAR.NAMEPRIORARTID     is null)
	join CASESEARCHRESULT CSR
				on (CSR.PRIORARTID=d.CITEDPRIORARTID
				and CSR.FAMILYPRIORARTID   is null
				and CSR.CASELISTPRIORARTID is null
				and CSR.NAMEPRIORARTID     is null)


End
go
