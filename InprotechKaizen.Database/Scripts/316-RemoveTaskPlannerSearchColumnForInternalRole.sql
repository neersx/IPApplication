 	/************************************************************************************************************/
	/*** DR-71144 'Maintain Task Planner Search Columns' security task should be turned off in Internal Role ***/
    /***********************************************************************************************************/

		If EXISTS(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 284
			and LEVELTABLE = 'ROLE'
			and LEVELKEY = -21
			and GRANTPERMISSION = 26
			and OBJECTTABLE = 'TASK')
			BEGIN
				PRINT '**** DR-71144 Delete TASK data PERMISSIONS.OBJECTKEY = 284'
					DELETE FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 284
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -21
				and GRANTPERMISSION = 26
				and OBJECTTABLE = 'TASK'
				PRINT '**** DR-71144 Data successfully deleted to PERMISSIONS table.'
				PRINT ''
			END
		ELSE
			BEGIN
				PRINT '**** DR-71144 TASK data PERMISSIONS.OBJECTKEY = 284 does not exists'
				PRINT ''
			END
		GO

 	/************************************************************************************************************/
	/*** DR-71144 'Maintain Task Planner Search Columns' security task should be turned off in Admin Role ***/
    /***********************************************************************************************************/
		If EXISTS(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
			and OBJECTINTEGERKEY = 284
			and LEVELTABLE = 'ROLE'
			and LEVELKEY = -1
			and GRANTPERMISSION = 26
			and OBJECTTABLE = 'TASK')
			BEGIN
				PRINT '**** DR-71144 Delete TASK data PERMISSIONS.OBJECTKEY = 284'
					DELETE FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 284
				and LEVELTABLE = 'ROLE'
				and LEVELKEY = -1
				and GRANTPERMISSION = 26
				and OBJECTTABLE = 'TASK'
				PRINT '**** DR-71144 Data successfully deleted to PERMISSIONS table.'
				PRINT ''
			END
		ELSE
			BEGIN
				PRINT '**** DR-71144 TASK data PERMISSIONS.OBJECTKEY = 284 does not exists'
				PRINT ''
			END
		GO
