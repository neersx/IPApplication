IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 232 AND GENERICPARAM='EPO')
BEGIN
	INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, GENERICPARAM, URL) VALUES(
	232,
	N'Configure EPO Integration Settings',
	N'Configure required settings for EPO integration and data download.', 'EPO', '/apps/#/pto-settings/epo')
END
GO