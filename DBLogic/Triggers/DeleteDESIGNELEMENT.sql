if exists (select * from sysobjects where type='TR' and name = 'DeleteDESIGNELEMENT')
begin
	PRINT 'Refreshing trigger DeleteDESIGNELEMENT...'
	DROP TRIGGER DeleteDESIGNELEMENT
end
go
Create trigger DeleteDESIGNELEMENT on DESIGNELEMENT for DELETE NOT FOR REPLICATION as 
Begin
-- TRIGGER:	DeleteDESIGNELEMENT    
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Jan 2016	MF	41323 	1	Created

	----------------------------------------------------
	-- Remove OFFICIALNUMBERS if they are not referenced
	-- by another DESIGNELEMENT for the same Case.
	----------------------------------------------------
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
go
