	if exists (select * from sysobjects where type='TR' and name = 'tD_TabTopicControls')
	   begin
	    PRINT 'Refreshing trigger tD_TabTopicControls...'
	    DROP TRIGGER tD_TabTopicControls
	   end
	  go	

	CREATE TRIGGER  tD_TabTopicControls ON TABCONTROL FOR DELETE NOT FOR REPLICATION AS
	-- TRIGGER :	tD_TabTopicControls
	-- VERSION :	1
	-- DESCRIPTION:	This trigger deletes corresponding TOPICCONTROL table rows whenever  
	-- 		a TABCONTROL is deleted
	-- Date		Who	Number	Version	Change
	-- ------------	-------	------	-------	----------------------------------------------- 	
	-- 16 Feb 2008	JC	RFC6732	1	Trigger created 	
	
	Begin
		Delete TOPICCONTROL
		from TOPICCONTROL 
		join deleted R	on (R.TABCONTROLNO=TOPICCONTROL.TABCONTROLNO)		
	End
	go
