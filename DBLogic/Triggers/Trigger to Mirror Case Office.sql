	/******************************************************************************************************************/
	/*** SQA 9282 Trigger to Mirror Case Office									***/
	/*** SQA18907 DROP THE TRIGGERS AS THEY ARE NO LONGER REQUIRED.                                                 ***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'tI_TABLEATTRIBUTESOFFICE')
	   begin
	    PRINT 'Refreshing trigger tI_TABLEATTRIBUTESOFFICE...'
	    DROP TRIGGER tI_TABLEATTRIBUTESOFFICE
	   end
	  go

	if exists (select * from sysobjects where type='TR' and name = 'tU_TABLEATTRIBUTESOFFICE')
	   begin
	    PRINT 'Refreshing trigger tU_TABLEATTRIBUTESOFFICE...'
	    DROP TRIGGER tU_TABLEATTRIBUTESOFFICE
	   end
	  go