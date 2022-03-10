	if exists (select * from sysobjects where type='TR' and name = 'tD_TaskPermissions')
	   begin
	    PRINT 'Refreshing trigger tD_TaskPermissions...'
	    DROP TRIGGER tD_TaskPermissions
	   end
	  go	

	CREATE TRIGGER  tD_TaskPermissions ON TASK FOR DELETE NOT FOR REPLICATION AS
	-- TRIGGER :	tD_TaskPermissions
	-- VERSION :	1
	-- DESCRIPTION:	This trigger deletes corresponding PERMISSIONS table rows whenever  
	-- 		a Task is deleted
	-- Date		Who	Number	Version	Change
	-- ------------	-------	------	-------	----------------------------------------------- 	
	-- 10 Aug 2004	TM	RFC1500	1	Trigger created 	
	
	Begin
		Delete PERMISSIONS
		from PERMISSIONS 
		join deleted T	on (T.TASKID=PERMISSIONS.OBJECTINTEGERKEY
				and PERMISSIONS.OBJECTTABLE='TASK')		
	End
	go
