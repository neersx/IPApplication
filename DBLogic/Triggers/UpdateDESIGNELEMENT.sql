if exists (select * from sysobjects where type='TR' and name = 'UpdateDESIGNELEMENT')
begin
	PRINT 'Refreshing trigger UpdateDESIGNELEMENT...'
	DROP TRIGGER UpdateDESIGNELEMENT
end
go
	
Create trigger UpdateDESIGNELEMENT on DESIGNELEMENT for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateDESIGNELEMENT    
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Jan 2016	MF	41323 	1	Created

Begin
	If UPDATE ( REGISTRATIONNO )
	Begin
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
		-----------------------------------------------------------
		-- Lastly we need to remove OFFICIALNUMBERS if they are not
		-- referenced by another DESIGNELEMENT for the same Case.
		-----------------------------------------------------------
		Delete O
		from OFFICIALNUMBERS O
		join deleted d		   on (d.CASEID         =O.CASEID
					   and d.REGISTRATIONNO =O.OFFICIALNUMBER)
		left join DESIGNELEMENT DE on (DE.CASEID        =d.CASEID
					   and DE.REGISTRATIONNO=d.REGISTRATIONNO)
		where O.NUMBERTYPE='R'
		and   O.ISCURRENT =0
		and  DE.CASEID is null
	End
End
go
