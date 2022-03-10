        /**********************************************************************************************************/
    	/*** RFC71178 Delete Maintain Case Relationship Codes task security - FeatureTask			***/
	/**********************************************************************************************************/
	If exists (select * from FEATURETASK where FEATUREID = 51 AND TASKID = 242)
        	BEGIN
         	 PRINT '**** RFC71178 Delete data FEATURETASK.FEATUREID = 51 and FEATURETASK.TASKID = 242 '
		 DELETE FROM FEATURETASK where FEATUREID = 51 AND TASKID = 242
        	 PRINT '**** RFC71178 Data successfully deleted from FEATURETASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC71178 FEATURETASK.FEATUREID = 51 and FEATURETASK.TASKID = 242 does not exist'
         	PRINT ''
    	go
                
        /**********************************************************************************************************/
    	/*** RFC71178 Delete Maintain Case Relationship Codes task security - PERMISSIONS			***/
	/**********************************************************************************************************/
        If exists (select * from PERMISSIONS where OBJECTTABLE = 'TASK' and OBJECTINTEGERKEY = 242)
        	BEGIN
         	 PRINT '**** RFC71178 Delete data PERMISSIONS.OBJECTINTEGERKEY = 242'
		 DELETE FROM PERMISSIONS where OBJECTTABLE = 'TASK' and OBJECTINTEGERKEY = 242
        	 PRINT '**** RFC71178 Data successfully deleted from PERMISSIONS table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC71178 PERMISSIONS.OBJECTINTEGERKEY = 242 does not exist'
         	PRINT ''
    	go

        /**********************************************************************************************************/
    	/*** RFC71178 Delete Maintain Case Relationship Codes task security - Task				***/
	/**********************************************************************************************************/
	If exists (select * from TASK where TASKID = 242)
        	BEGIN
         	 PRINT '**** RFC71178 Delete data TASK.TASKID = 242'
		 DELETE FROM TASK where TASKID = 242
        	 PRINT '**** RFC71178 Data successfully deleted from TASK table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC71178 TASK.TASKID = 242 does not exist'
         	PRINT ''
    	go