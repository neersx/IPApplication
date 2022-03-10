	if exists (select * from sysobjects where type='TR' and name = 'tD_NAMETYPE')
	   begin
	    PRINT 'Refreshing trigger tD_NAMETYPE...'
	    DROP TRIGGER tD_NAMETYPE
	   end
	  go	

	CREATE TRIGGER  tD_NAMETYPE ON NAMETYPE FOR DELETE NOT FOR REPLICATION AS
	-- TRIGGER :	tD_NAMETYPE
	-- VERSION :	1
	-- DESCRIPTION:	This trigger deletes corresponding TOPICCONTROL and ELEMENTCONTROL table rows whenever  
	-- 		a NAMETYPE is deleted
	-- Date		Who	Number	Version	Change
	-- ------------	-------	------	-------	----------------------------------------------- 	
	-- 18 Mar 2009	JC	RFC7756	1	Trigger created 	
	
	Begin
		Delete TOPICCONTROL
		from TOPICCONTROL 
		join deleted R on (R.NAMETYPE = TOPICCONTROL.FILTERVALUE)
		where FILTERNAME = 'NameTypeCode'

		Delete ELEMENTCONTROL
		from ELEMENTCONTROL 
		join deleted R on (R.NAMETYPE = ELEMENTCONTROL.FILTERVALUE)
		where FILTERNAME = 'NameTypeCode'

	End
	go
