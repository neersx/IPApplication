declare @settingValue nvarchar(50) = 'Mr+30TVuZCWjX9qbqTZl+w=='
If NOT exists (select 1 from CONFIGURATIONSETTINGS where SETTINGKEY = 'Inprotech.GoogleAnalytics.TrackingId')
	BEGIN		
		PRINT '**** Insert Google Analytics Tracking Id'
		INSERT INTO CONFIGURATIONSETTINGS (SETTINGKEY,SETTINGVALUE) VALUES ('Inprotech.GoogleAnalytics.TrackingId', @settingValue)
 	END
ELSE
	BEGIN
		PRINT '**** Checking Google Analytics Tracking Id'
		UPDATE CONFIGURATIONSETTINGS SET SETTINGVALUE = @settingValue WHERE SETTINGKEY = 'Inprotech.GoogleAnalytics.TrackingId' AND SETTINGVALUE != @settingValue
	END
GO