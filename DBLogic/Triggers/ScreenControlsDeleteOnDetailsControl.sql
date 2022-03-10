/******************************************************************************************************************/
/*** 70004 Ability to use the c/s screen control rules in the web entry control									***/
/******************************************************************************************************************/     

if exists (select * from sysobjects where type='TR' and name = 'ScreenControlsDeleteOnDetailsControl')
begin
	PRINT 'Refreshing trigger ScreenControlsDeleteOnDetailsControl...'
	drop trigger ScreenControlsDeleteOnDetailsControl
end
go

create trigger ScreenControlsDeleteOnDetailsControl on DETAILCONTROL
for delete not for replication as

	delete S
	from SCREENCONTROL S
	join deleted d on (d.ENTRYNUMBER = S.ENTRYNUMBER and d.CRITERIANO = S.CRITERIANO)

go
