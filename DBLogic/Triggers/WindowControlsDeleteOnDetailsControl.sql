/******************************************************************************************************************/
/*** 70004 Ability to use the c/s screen control rules in the web entry control									***/
/******************************************************************************************************************/     

if exists (select * from sysobjects where type='TR' and name = 'WindowControlsDeleteOnDetailsControl')
begin
	PRINT 'Refreshing trigger WindowControlsDeleteOnDetailsControl...'
	drop trigger WindowControlsDeleteOnDetailsControl
end
go

create trigger WindowControlsDeleteOnDetailsControl on DETAILCONTROL
for delete not for replication as

	delete W
	from WINDOWCONTROL W
	join deleted d on (d.ENTRYNUMBER = W.ENTRYNUMBER and d.CRITERIANO = W.CRITERIANO)

go
