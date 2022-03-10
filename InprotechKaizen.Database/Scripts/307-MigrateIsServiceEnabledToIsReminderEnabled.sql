
/** DR-68356 RENAME PROPERTY ISSERVICEENABLED TO  IsReminderEnabled **/ 
IF EXISTS( SELECT 1 FROM EXTERNALSETTINGS 
	WHERE PROVIDERNAME = 'ExchangeSetting' 
	AND SETTINGS LIKE '%ISSERVICEENABLED%')
BEGIN
	UPDATE EXTERNALSETTINGS SET 
		SETTINGS = REPLACE(SETTINGS, 'ISSERVICEENABLED', 'IsReminderEnabled')
		WHERE PROVIDERNAME = 'ExchangeSetting' 
		AND SETTINGS LIKE '%ISSERVICEENABLED%' 
END
GO