if exists (select * from sysobjects where type='TR' and name = 'tD_ASSOCIATEDNAME')
begin
	PRINT 'Refreshing trigger tD_ASSOCIATEDNAME...'
	DROP TRIGGER tD_ASSOCIATEDNAME
end
  go	

CREATE TRIGGER  tD_ASSOCIATEDNAME ON ASSOCIATEDNAME FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER :	tD_ASSOCIATEDNAME
-- VERSION :	1
-- DESCRIPTION:	This trigger clears out the MAINCONTACT of a Name 
-- 		if there are no ASSOCIATEDNAME rows linking that
--		related name to the NAME row
--
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 	
-- 09 Jan 2014	MF	R27812	1	Trigger created 	

Begin
	Update N
	set MAINCONTACT=NULL
	from NAME N
	join deleted d	on (d.NAMENO=N.NAMENO
			and d.RELATEDNAME=N.MAINCONTACT)
	-- check that the associated name
	-- being deleted does not exist as
	-- another associated name.
	left join ASSOCIATEDNAME A
			on (A.NAMENO=N.NAMENO
			and A.RELATEDNAME=N.MAINCONTACT)
	where A.NAMENO is null
End
go
