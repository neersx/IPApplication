	if exists (select * from sysobjects where type='TR' and name = 'tD_ModulePermissions')
	   begin
	    PRINT 'Refreshing trigger tD_ModulePermissions...'
	    DROP TRIGGER tD_ModulePermissions
	   end
	  go	

	CREATE TRIGGER  tD_ModulePermissions ON MODULE FOR DELETE NOT FOR REPLICATION AS
	-- TRIGGER :	tD_ModulePermissions
	-- VERSION :	1
	-- DESCRIPTION:	This trigger deletes corresponding PERMISSIONS table rows whenever  
	-- 		a Module is deleted
	-- Date		Who	Number	Version	Change
	-- ------------	-------	------	-------	----------------------------------------------- 	
	-- 10 Aug 2004	TM	RFC1500	1	Trigger created 	
	
	Begin
		Delete PERMISSIONS
		from PERMISSIONS 
		join deleted M	on (M.MODULEID=PERMISSIONS.OBJECTINTEGERKEY
				and PERMISSIONS.OBJECTTABLE='MODULE')		
	End
	go
