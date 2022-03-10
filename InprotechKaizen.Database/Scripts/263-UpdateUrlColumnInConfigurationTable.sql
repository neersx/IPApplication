  /**********************************************************************************************************/
  /*** DR-57763 Configuration item for 'Case Search Columns' and 'External Case Search Columns'     			    ***/
  /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 160 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=2'
				WHERE TASKID = 160
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 160.'
			 PRINT ''
		 END
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 173 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=1'
				WHERE TASKID = 173
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 173.'
			 PRINT ''
		 END
     GO 
	/**********************************************************************************************************/
    /*** Configuration item for 'Name Search Columns' and 'External Name Search Columns'     			    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 161 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=10'
				WHERE TASKID = 161
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 161.'
			 PRINT ''
		 END
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 174 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=15'
				WHERE TASKID = 174
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 174.'
			 PRINT ''
	    END
     GO	
    /**********************************************************************************************************/
    /*** Configuration item for 'Case Fee Search Columns' and 'External Case Fee Search Columns'		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 165 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=330'
				WHERE TASKID = 165
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 165.'
			 PRINT ''
		 END
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 177 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=331'
				WHERE TASKID = 177
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 177.'
			 PRINT ''
		 END
	GO	 
	/**********************************************************************************************************/
    /*** Configuration item for 'Case Instruction Search Columns' and 'External Case Instruction Search Columns'		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 166 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=340'
				WHERE TASKID = 166
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 166.'
			 PRINT ''
		 END
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 176 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=341'
				WHERE TASKID = 176
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 176.'
			 PRINT ''
		 END
	GO 	 
	/**********************************************************************************************************/
    /*** Configuration item for 'Client Request Search Columns' and 'External Client Request Search Columns'		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 170 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=198'
				WHERE TASKID = 170
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 170.'
			 PRINT ''
		 END
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 175 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=199'
				WHERE TASKID = 175
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 175.'
			 PRINT ''
		 END
    GO    
    /**********************************************************************************************************/
    /*** Configuration item for 'Reciprocity Case Search'                                       		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 171 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=19'
				WHERE TASKID = 171
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 171.'
			 PRINT ''
		 END
	GO
    /**********************************************************************************************************/
    /*** Configuration item for 'Ad Hoc Date Search'                                            		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 196 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=164'
				WHERE TASKID = 196
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 196.'
			 PRINT ''
		 END
    GO  
    /**********************************************************************************************************/
    /*** Configuration item for 'Staff Reminders Search'                                            		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 198 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=165'
				WHERE TASKID = 198
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 198.'
			 PRINT ''
		 END
	GO
	/**********************************************************************************************************/
    /*** Configuration item for 'To Do Search Columns'                                            		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 197 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=162'
				WHERE TASKID = 197
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 197.'
			 PRINT ''
		 END
     GO
	/**********************************************************************************************************/
    /*** Configuration item for 'What's Due Calendar Search'                                      		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 195 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=160'
				WHERE TASKID = 195
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 195.'
			 PRINT ''
		 END
     GO
    /**********************************************************************************************************/
    /*** Configuration item for 'Work History Search'                                            		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 172 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=205'
				WHERE TASKID = 172
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 172.'
			 PRINT ''
		 END
     GO
    /**********************************************************************************************************/
    /*** Configuration item for 'WIP Overview Search'                                            		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 169 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=200'
				WHERE TASKID = 169
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 169.'
			 PRINT ''
		 END
     GO
    /**********************************************************************************************************/
    /*** Configuration item for 'Lead Search'                                                    		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 167 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=500'
				WHERE TASKID = 167
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 167.'
			 PRINT ''
		 END
	 GO
    /**********************************************************************************************************/
    /*** Configuration item for 'Opportunity Search'                                               		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 162 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=550'
				WHERE TASKID = 162
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 162.'
			 PRINT ''
		 END
     GO
	/**********************************************************************************************************/
    /*** Configuration item for 'Campaign Search'                                               		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 163 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=560'
				WHERE TASKID = 163
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 163.'
			 PRINT ''
		 END
    GO
	/**********************************************************************************************************/
    /*** Configuration item for 'Marketing Event Search'                                               		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 164 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=570'
				WHERE TASKID = 164
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 164.'
			 PRINT ''
		 END
    GO
	/**********************************************************************************************************/
    /*** Configuration item for 'Activity Search Columns'                                          		    ***/
    /**********************************************************************************************************/
    IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 168 AND URL IS NULL)
    	BEGIN
			UPDATE CONFIGURATIONITEM
				SET URL = '/apps/#/search/columns?queryContextKey=190'
				WHERE TASKID = 168
			 PRINT '**** DR-57763 Url successfully updates in CONFIGURATIONITEM table for TASKID = 168.'
			 PRINT ''
		 END
    GO

