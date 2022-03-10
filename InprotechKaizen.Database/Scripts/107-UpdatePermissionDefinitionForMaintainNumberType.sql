/**********************************************************************************************************/
/*** RFC60735 Update Maintain Number Types task security - Permissions							***/
/**********************************************************************************************************/
	If exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 241
				and LEVELTABLE is null
				and LEVELKEY is null
				and GRANTPERMISSION = 26)
        	BEGIN
         	 PRINT '**** RFC60735 Update permissions for default ROLE PERMISSIONS.OBJECTKEY = 241'
				UPDATE PERMISSIONS SET GRANTPERMISSION = 32, DENYPERMISSION = 0
				WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 241
				and LEVELTABLE is null
				and LEVELKEY is null
        	 PRINT '**** RFC60735 Data successfully updated to PERMISSIONS table.'
			 PRINT ''
			 
         	 PRINT '**** RFC60735 Grant permission for all roles having partial GRANT permissions PERMISSIONS.OBJECTKEY = 241'
				UPDATE PERMISSIONS SET GRANTPERMISSION = 32, DENYPERMISSION = 0
				WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 241
				and LEVELTABLE = 'ROLE'
				and LEVELKEY is not null
				and GRANTPERMISSION > 0
        	 PRINT '**** RFC60735 Data successfully updated to PERMISSIONS table.'
			 PRINT ''
         	
			 PRINT '**** RFC60735 Deny permission for all roles with full DENY permissions PERMISSIONS.OBJECTKEY = 241'
				UPDATE PERMISSIONS SET GRANTPERMISSION = 0, DENYPERMISSION = 32
				WHERE OBJECTTABLE = 'TASK'
				and OBJECTINTEGERKEY = 241
				and LEVELTABLE = 'ROLE'
				and LEVELKEY is not null
				and GRANTPERMISSION = 0
        	 PRINT '**** RFC60735 Data successfully updated to PERMISSIONS table.'
			 PRINT ''
         	END
    	ELSE
         	BEGIN
         	 PRINT '**** RFC60735 Permissions already updated for PERMISSIONS.OBJECTKEY = 241'
		 PRINT ''
         	END
    	go