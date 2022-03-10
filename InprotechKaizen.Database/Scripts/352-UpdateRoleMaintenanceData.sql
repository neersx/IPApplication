	/**********************************************************************************************************/
	/*** DR-75534 Provide new Execute permission option for 'Maintain Roles' task security					***/
	/**********************************************************************************************************/
		IF NOT EXISTS(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'
				AND OBJECTINTEGERKEY = 17
				AND GRANTPERMISSION = 58
				AND LEVELKEY is null
				AND OBJECTTABLE = N'TASK')
			BEGIN
				PRINT '**** DR-75534 Update GRANTPERMISSION in PERMISSIONS table'

					UPDATE PERMISSIONS set GRANTPERMISSION = 58 
					WHERE OBJECTTABLE = 'TASK'
					AND OBJECTINTEGERKEY = 17
					AND LEVELKEY is null
					AND OBJECTTABLE = N'TASK'

				PRINT '**** DR-75534 Data successfully updated to PERMISSIONS table.'
			PRINT ''
			END
		ELSE
			BEGIN
				PRINT '**** DR-75534 GRANTPERMISSION is already exists for OBJECTINTEGERKEY = 17'
			PRINT ''
			END
		GO
			   
	/**********************************************************************************************************/
	/*** DR-75534 Provide EXECUTE permission for 'Maintain Roles' task security             				***/
	/**********************************************************************************************************/
		if exists(select * from permissions
					WHERE OBJECTTABLE = 'TASK' AND OBJECTINTEGERKEY = 17 AND LEVELKEY IN
					(SELECT LEVELKEY from PERMISSIONS P
						WHERE P.OBJECTTABLE = 'MODULE' AND P.OBJECTINTEGERKEY = -15 AND P.GRANTPERMISSION = 1))
		BEGIN
			PRINT '**** DR-75534 Update EXECUTE permission for Maintain Roles TASK'
			
			UPDATE PERMISSIONS
			SET GRANTPERMISSION = GRANTPERMISSION | 32
			WHERE OBJECTTABLE = 'TASK' AND OBJECTINTEGERKEY = 17 AND LEVELKEY IN (SELECT LEVELKEY from PERMISSIONS P
																				  WHERE P.OBJECTTABLE = 'MODULE' AND P.OBJECTINTEGERKEY = -15 AND P.GRANTPERMISSION = 1)

			PRINT '**** DR-75534 Data successfully updated to PERMISSIONS table.'
			PRINT ''
		END
		GO

		if exists(select * from permissions 
					where OBJECTTABLE = 'MODULE' AND OBJECTINTEGERKEY = -15 and GRANTPERMISSION = 1
					 and LEVELKEY not in (select P.LEVELKEY  from permissions P
											WHERE P.OBJECTTABLE = 'TASK' AND P.OBJECTINTEGERKEY = 17 and P.LEVELKEY is not null))
		begin
			insert PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION)
			select 'TASK', 17, 'ROLE', P.LEVELKEY, 32, 0
			from PERMISSIONS P
			where P.OBJECTTABLE = 'MODULE' AND P.OBJECTINTEGERKEY = -15
						and P.LEVELKEY not in (select LEVELKEY from permissions
												WHERE OBJECTTABLE = 'TASK' AND OBJECTINTEGERKEY = 17
												and LEVELKEY is not null)
		end
		GO