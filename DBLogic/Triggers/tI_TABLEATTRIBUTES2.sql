	/******************************************************************************************************************/
	/*** SQA8116 Add triggers for OFFICE and TABLEATTRIBUTES							***/
	/*** SQA18907 DROP THE TRIGGER AS IT IS NO LONGER REQUIRED.                                                     ***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'tI_TABLEATTRIBUTES2')
	   begin
	    PRINT 'Refreshing trigger tI_TABLEATTRIBUTES2...'
	    DROP TRIGGER tI_TABLEATTRIBUTES2
	   end
	  go
