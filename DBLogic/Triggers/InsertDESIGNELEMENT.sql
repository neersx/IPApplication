if exists (select * from sysobjects where type='TR' and name = 'InsertDESIGNELEMENT')
begin
	PRINT 'Refreshing trigger InsertDESIGNELEMENT...'
	DROP TRIGGER InsertDESIGNELEMENT
end
go

Create trigger InsertDESIGNELEMENT on DESIGNELEMENT for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertDESIGNELEMENT    
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Jan 2016	MF	41323 	1	Created

	Insert into OFFICIALNUMBERS (CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)
	Select distinct i.CASEID, i.REGISTRATIONNO, NT.NUMBERTYPE, 0
	from inserted i
	     join NUMBERTYPES NT    on (NT.NUMBERTYPE='R')
	left join OFFICIALNUMBERS O on (O.CASEID        =i.CASEID
				    and O.OFFICIALNUMBER=i.REGISTRATIONNO
				    and O.NUMBERTYPE    =NT.NUMBERTYPE)
	where i.REGISTRATIONNO is not null
	and   i.REGISTRATIONNO<>''
	and   O.CASEID is null

End
go
