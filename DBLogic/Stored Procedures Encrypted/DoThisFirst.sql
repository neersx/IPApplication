-- The encrypted functions and procedures are installed before the database is upgraded.
-- This script contains any changes that need to made to the database before the
-- ecrypted procedures and functions can be applied.
-- Note: such scripting is to be 'officially' released via the upgrade script as usual.
-- A copy is held here of only the portions that are essential pre-requisites.


    	/**********************************************************************************************************/
    	/*** 10095 Add column LICENSEMODULE.MODULEFLAG								***/
	/**********************************************************************************************************/     
	If NOT exists (SELECT * FROM syscolumns WHERE id = object_id('LICENSEMODULE') and name = 'MODULEFLAG')
        	BEGIN
         	 PRINT '**** 10095 Adding column LICENSEMODULE.MODULEFLAG.'
		 ALTER TABLE LICENSEMODULE ADD MODULEFLAG SMALLINT NULL
        	 PRINT '**** 10095 LICENSEMODULE.MODULEFLAG column has been added.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** 10095 LICENSEMODULE.MODULEFLAG already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** 10095 Create table LICENSEDACCOUNT									***/
	/**********************************************************************************************************/ 
	IF NOT EXISTS (SELECT * FROM sysobjects where id = object_id('LICENSEDACCOUNT'))
		BEGIN
	  	 PRINT '**** 10095 Creating table LICENSEDACCOUNT'
		 CREATE TABLE dbo.LICENSEDACCOUNT (
		        MODULEID             int NOT NULL,
		        ACCOUNTID            int NOT NULL
		 )		 
		 grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.LICENSEDACCOUNT to public
  		 PRINT '**** 10095 LICENSEDACCOUNT table has been successfully created.'
  		 PRINT ''
		END
	ELSE
       		PRINT '**** 10095 LICENSEDACCOUNT table already exists'
       		PRINT ''
	go

	/**********************************************************************************************************/
	/*** RFC869 Create table VALIDOBJECT									***/
	/**********************************************************************************************************/ 
	IF NOT EXISTS (SELECT * FROM sysobjects where id = object_id('VALIDOBJECT'))
		BEGIN
	  	 PRINT '**** RFC869 Creating table VALIDOBJECT'
		 CREATE TABLE dbo.VALIDOBJECT (
		        OBJECTID             int NOT NULL,
		        TYPE                 int NOT NULL,
		        OBJECTDATA           nvarchar(254) NOT NULL
		 )
		 grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.VALIDOBJECT to public
  		 PRINT '**** RFC869 VALIDOBJECT table has been successfully created.'
  		 PRINT ''
		END
	ELSE
       		PRINT '**** RFC869 VALIDOBJECT table already exists'
       		PRINT ''
	go

	/**********************************************************************************************************/
	/*** RFC1085 Create table PERMISSIONS									***/
	/**********************************************************************************************************/ 
	IF not exists (SELECT * FROM syscolumns WHERE id = object_id('PERMISSIONS'))
		BEGIN
	  	 PRINT '**** RFC1085 Creating table PERMISSIONS'
		 CREATE TABLE dbo.[PERMISSIONS] (
		        PERMISSIONID         int IDENTITY(1,1),
		        OBJECTTABLE          nvarchar(30) NOT NULL,
		        OBJECTINTEGERKEY     int NULL,
		        OBJECTSTRINGKEY      nvarchar(30) NULL,
		        LEVELTABLE           nvarchar(30) NULL,
		        LEVELKEY             int NULL,
		        GRANTPERMISSION      tinyint NOT NULL,
		        DENYPERMISSION       tinyint NOT NULL
		 )
		grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.[PERMISSIONS] to public
		
  		PRINT '**** RFC1085 PERMISSIONS table has been successfully created.'
  		PRINT ''
		END
	ELSE
       		PRINT '**** RFC1085 PERMISSIONS table already exists'
       		PRINT ''
	go

    	/**********************************************************************************************************/
    	/*** 11588 Change column LICENSE.DATA to NVARCHAR(268)							***/
	/**********************************************************************************************************/     
	If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LICENSE' and COLUMN_NAME = 'DATA' AND CHARACTER_MAXIMUM_LENGTH = 268)
		BEGIN
		 PRINT '**** 11588 Change column LICENSE.DATA to NVARCHAR(268)'
		 ALTER TABLE LICENSE ALTER COLUMN DATA NVARCHAR(268) null
		 PRINT '**** 11588 Change has been successfully applied to LICENSE table.'
		END
	ELSE
		PRINT '**** 11588 LICENSE.SERVDISPERCENTAGE column already set to NVARCHAR(268).'
		print ''
	go
		
