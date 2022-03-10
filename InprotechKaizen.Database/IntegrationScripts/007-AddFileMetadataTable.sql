    /*** RFC42101/DR-10429 Add table FileMetadata			***/	

    If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FileMetadata')
	BEGIN
		PRINT '**** RFC42101/DR-10429  Adding table FileMetadata.' 
		CREATE TABLE dbo.FileMetadata
                    (
 	                    Id  bigint  IDENTITY (1,1)  NOT FOR REPLICATION,
 	                    FileId  uniqueidentifier  NOT NULL ,
 	                    Filename  nvarchar(1024)  NOT NULL ,
 	                    FileSize  bigint  NOT NULL ,
 	                    FileGroup  nvarchar(1024)  NOT NULL ,
 	                    ContentHash  nvarchar(50)  NOT NULL ,
 	                    MimeType  nvarchar(255)  NULL ,
                        SavedOn datetime NOT NULL,
                        )
		PRINT '**** RFC42101/DR-10429 FileMetadata table has been added.'
		PRINT ''
	END
	ELSE
			PRINT '**** RFC42101/DR-10429 FileMetadata already exists'
    PRINT ''
	go 
	 

	/*** RFC42101/DR-10429 Adding primary key for table FileMetadata				***/

	if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'FileMetadata' and CONSTRAINT_NAME = 'XPKFileMetadata')
	begin
		PRINT 'Dropping primary key constraint FileMetadata.XPKFileMetadata...'
		ALTER TABLE FileMetadata DROP CONSTRAINT XPKFileMetadata
	end
	PRINT 'Adding primary key constraint FileMetadata.XPKFileMetadata...'	
        ALTER TABLE dbo.FileMetadata
	WITH NOCHECK ADD CONSTRAINT  XPKFileMetadata PRIMARY KEY   NONCLUSTERED (Id  ASC)
    go
        
    /*** RFC42101/DR-10429 Adding index for table FileMetadata	***/

    if exists (select * from sysindexes where name = 'XAK1FileMetadata')
    begin
	        PRINT 'Dropping index FileMetadata.XAK1FileMetadata ...'
	        DROP INDEX FileMetadata.XAK1FileMetadata
    end
    PRINT 'Adding index FileMetadata.XAK1FileMetadata ...'
    CREATE  UNIQUE NONCLUSTERED INDEX XAK1FileMetadata ON FileMetadata
    (
	    FileId  ASC
    )
    go
