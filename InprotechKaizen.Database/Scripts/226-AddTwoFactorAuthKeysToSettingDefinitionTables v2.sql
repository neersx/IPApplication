
If NOT exists (SELECT *
FROM SETTINGDEFINITION
WHERE SettingId = 26)

	INSERT INTO SETTINGDEFINITION(SettingId, SETTINGNAME, DATATYPE, COMMENT, ISINTERNAL, ISEXTERNAL)
	VALUES
	(26, 'Preferred Two Factor Mode','C', '', 1,1)


ELSE
	BEGIN
	PRINT '**** Preferred Two Factor Mode Already Exists'
END

If NOT exists (SELECT *
FROM SETTINGDEFINITION
WHERE SettingId = 27)

	INSERT INTO SETTINGDEFINITION(SettingId, SETTINGNAME, DATATYPE, COMMENT, ISINTERNAL, ISEXTERNAL)
	VALUES
	(27, 'Email Secret Key','C', '', 1,1)


ELSE
	BEGIN
	PRINT '**** Email Secret Key Already Exists'
END

If NOT exists (SELECT *
FROM SETTINGDEFINITION
WHERE SettingId = 28)

	INSERT INTO SETTINGDEFINITION(SettingId, SETTINGNAME, DATATYPE, COMMENT, ISINTERNAL, ISEXTERNAL)
	VALUES
	(28, 'App Secret Key','C', '', 1,1)


ELSE
	BEGIN
	PRINT '**** App Secret Key Already Exists'
END

UPDATE SITECONTROL Set COMMENTS = 'Specifies the default administrator email address for Inprotech. This email address will be used to send automated system emails from the web-based software. For example, an email is sent when an individual is locked out of the web-based software. When using Two Step Verification, the system generated code will also be sent from this email address.', NOTES='Specifies the default administrator email address for Inprotech. This email address will be used to send automated system emails from the web-based software. For example, an email is sent when an individual is locked out of the web-based software. When using Two Step Verification, the system generated code will also be sent from this email address.' Where CONTROLID='WorkBench Administrator Email'
UPDATE SITECONTROL Set COLCHARACTER='noreply@inprotech' Where CONTROLID='WorkBench Administrator Email' and ISNULL(COLCHARACTER,'') = ''

GO

