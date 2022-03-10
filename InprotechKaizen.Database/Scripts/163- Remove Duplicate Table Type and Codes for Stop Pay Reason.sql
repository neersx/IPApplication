/*** RFC72178 Remove Table Code for Table Type = 65 (Stop Pay Reason) ***/	
If exists (SELECT 1 FROM TABLECODES WHERE TABLETYPE = 65) 
    BEGIN
    PRINT '****  Removing table codes for Table Type = 65 column.'            
	DELETE FROM TABLECODES WHERE TABLETYPE = 65
    PRINT '****  Removed table codes for Table Type = 65 column.'
    PRINT ''
    END
go

/*** RFC72178 Remove Duplicate Stop Pay Reason Table Type = 65 ***/
If exists (SELECT 1 FROM TABLETYPE WHERE TABLETYPE = 65) 
    BEGIN
    PRINT '****  Removing Table Type = 65 .'            
	DELETE FROM TABLETYPE WHERE TABLETYPE = 65
    PRINT '****  Removed Table Type = 65 .'
    PRINT ''
    END
go