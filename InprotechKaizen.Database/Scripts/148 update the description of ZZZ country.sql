/**********************************************************************************************************/
	/*** RFC70156 update the description of ZZZ country				***/
/**********************************************************************************************************/     
If exists(SELECT * FROM COUNTRY WHERE COUNTRYCODE='ZZZ')
        BEGIN
			PRINT '**** RFC70156 updating data COUNTRY.COUNTRYCODE = ZZZ'
			UPDATE COUNTRY SET COUNTRY='DEFAULT JURISDICTION' WHERE COUNTRYCODE='ZZZ'
			PRINT '**** RFC70156 Data successfully updated to COUNTRY table.'
		PRINT ''
        END
    ELSE 
         	PRINT '**** RFC70156 COUNTRY.COUNTRYCODE = ZZZ not exists.'
		PRINT ''
    go