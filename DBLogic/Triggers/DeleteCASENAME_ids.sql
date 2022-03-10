if exists (select * from sysobjects where type='TR' and name = 'DeleteCASENAME_ids')
begin
	PRINT 'Refreshing trigger DeleteCASENAME_ids...'
	DROP TRIGGER DeleteCASENAME_ids
end
go

Create trigger DeleteCASENAME_ids on CASENAME for DELETE NOT FOR REPLICATION as
Begin
-- TRIGGER:	DeleteCASENAME_ids
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Mar 2011	MF	6563 	1	Created

	--------------------------------------------------------
	-- Removal of a CASE from a CASENAME should subsequently
	-- remove the CASESEARCHRESULT rows for that Case that 
	-- were inserted as result of its NAMENO association.
	-------------------------------------------------------
	Delete CSR
	from deleted d
	join NAMESEARCHRESULT N	on (N.NAMENO=d.NAMENO
				and d.NAMETYPE=isnull(N.NAMETYPE, d.NAMETYPE))
	join CASESEARCHRESULT CSR
				on (CSR.NAMEPRIORARTID=N.NAMEPRIORARTID
				and CSR.CASEID=d.CASEID)

End -- End trigger
go
