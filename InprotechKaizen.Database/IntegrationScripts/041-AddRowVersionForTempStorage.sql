	If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TempStorage' AND COLUMN_NAME = 'RowVersion')
	BEGIN   
		ALTER TABLE TempStorage ADD [RowVersion] rowversion not null
	END
	go