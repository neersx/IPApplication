	if exists (select * from sysobjects where type='TR' and name = 'tD_DataTopicPermissions')
	   begin
	    PRINT 'Refreshing trigger tD_DataTopicPermissions...'
	    DROP TRIGGER tD_DataTopicPermissions
	   end
	  go	

	CREATE TRIGGER  tD_DataTopicPermissions ON DATATOPIC FOR DELETE NOT FOR REPLICATION AS
	-- TRIGGER :	tD_DataTopicPermissions
	-- VERSION :	1
	-- DESCRIPTION:	This trigger deletes corresponding PERMISSIONS table rows whenever  
	-- 		a DataTopic is deleted
	-- Date		Who	Number	Version	Change
	-- ------------	-------	------	-------	----------------------------------------------- 	
	-- 10 Aug 2004	TM	RFC1500	1	Trigger created 	
	
	Begin
		Delete PERMISSIONS
		from PERMISSIONS 
		join deleted DT	on (DT.TOPICID=PERMISSIONS.OBJECTINTEGERKEY
				and PERMISSIONS.OBJECTTABLE='DATATOPIC')		
	End
	go
