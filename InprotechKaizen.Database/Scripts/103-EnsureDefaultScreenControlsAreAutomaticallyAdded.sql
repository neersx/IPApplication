
if exists (select * from sysobjects where type='TR' and name = 'InsertDefaultScreenControls_Criteria')
begin
	PRINT 'Refreshing trigger InsertDefaultScreenControls_Criteria...'
	drop trigger InsertDefaultScreenControls_Criteria
end
go

create trigger InsertDefaultScreenControls_Criteria on CRITERIA
after insert not for replication as

	---------------------------------------------------------------------------------------------
	--	Add default 'Case Entry Event' step in entry criterion                                 --
	---------------------------------------------------------------------------------------------

	insert SCREENCONTROL (CRITERIANO, SCREENNAME, SCREENID, SCREENTITLE)
	select C.CRITERIANO, 'frmCaseDetail', 0, 'Case Entry Event'
	from inserted C
	where C.PURPOSECODE = 'E'
	and APP_NAME() <> 'Control Maintenance'

	---------------------------------------------------------------------------------------------
	--	Add default 'Letters' step in entry criterion if missing                               --
	---------------------------------------------------------------------------------------------

	insert SCREENCONTROL (CRITERIANO, SCREENNAME, SCREENID, SCREENTITLE)
	select C.CRITERIANO, 'frmLetters', 1, 'Letters'
	from inserted C
	where C.PURPOSECODE = 'E'
	and APP_NAME() <> 'Control Maintenance'

go