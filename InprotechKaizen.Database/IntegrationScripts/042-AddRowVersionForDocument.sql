	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Documents' AND COLUMN_NAME = 'RowVersion')
	BEGIN   
		ALTER TABLE Documents ADD [RowVersion] rowversion not null
	END
	go
	