	if exists (select * from sysobjects where type='TR' and name = 'tD_RolePermissions')
	   begin
	    PRINT 'Refreshing trigger tD_RolePermissions...'
	    DROP TRIGGER tD_RolePermissions
	   end
	  go	

	CREATE TRIGGER  tD_RolePermissions ON ROLE FOR DELETE NOT FOR REPLICATION AS
	-- TRIGGER :	tD_RolePermissions
	-- VERSION :	1
	-- DESCRIPTION:	This trigger deletes corresponding PERMISSIONS table rows whenever  
	-- 		a Role is deleted
	-- Date		Who	Number	Version	Change
	-- ------------	-------	------	-------	----------------------------------------------- 	
	-- 10 Aug 2004	TM	RFC1500	1	Trigger created 	
	
	Begin
		Delete PERMISSIONS
		from PERMISSIONS 
		join deleted R	on (R.ROLEID=PERMISSIONS.LEVELKEY
				and PERMISSIONS.LEVELTABLE='ROLE')		
	End
	go
