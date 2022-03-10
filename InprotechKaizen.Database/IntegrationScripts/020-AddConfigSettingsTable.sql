 /*** DR-11393 Add table ConfigurationSettings			***/	

    If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ConfigurationSettings')
	BEGIN
		PRINT '**** DR-11393  Adding table ConfigurationSettings.' 
		CREATE TABLE dbo.ConfigurationSettings
                    (
 	                    Id  bigint  IDENTITY (1,1)  NOT FOR REPLICATION,
 	                    [Key]  nvarchar(450)  NOT NULL ,
 	                    [Value]  nvarchar(max)  NOT NULL ,
                        )
		PRINT '**** DR-11393 ConfigurationSettings table has been added.'
		PRINT ''
	    PRINT 'Adding primary key constraint ConfigurationSettings.XPKConfigurationSettings...'	
            ALTER TABLE dbo.ConfigurationSettings
	            WITH NOCHECK ADD CONSTRAINT  XPKConfigurationSettings PRIMARY KEY   NONCLUSTERED (Id  ASC)
	END
	ELSE
			PRINT '**** DR-11393 ConfigurationSettings already exists'
    PRINT ''
	go 
        
    /*** DR-11393 Adding index for table ConfigurationSettings	***/

    if not exists (select * from sysindexes where name = 'XAK1ConfigurationSettings')
    begin
        PRINT 'Adding index ConfigurationSettings.XAK1ConfigurationSettings ...'
        CREATE  UNIQUE NONCLUSTERED INDEX XAK1ConfigurationSettings ON dbo.ConfigurationSettings
        (
	        [Key]  ASC
        )
    end
    go