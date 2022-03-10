/*** Update URL for Data Mapping ***/
IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 239 AND GENERICPARAM='EPO' AND URL='/apps/configuration/ede/datamapping/#/Epo')
BEGIN
	UPDATE CONFIGURATIONITEM SET URL = '/apps/#/configuration/general/ede/datamapping/Epo'
	WHERE TASKID = 239 AND GENERICPARAM='EPO'
END
GO

IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 239 AND GENERICPARAM='USPTO.PP' AND URL='/apps/configuration/ede/datamapping/#/UsptoPrivatePair')
BEGIN
	UPDATE CONFIGURATIONITEM SET URL = '/apps/#/configuration/general/ede/datamapping/UsptoPrivatePair'
	WHERE TASKID = 239 AND GENERICPARAM='USPTO.PP'
END
GO

IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 239 AND GENERICPARAM='USPTO.TSDR' AND URL='/apps/configuration/ede/datamapping/#/UsptoTsdr')
BEGIN
	UPDATE CONFIGURATIONITEM SET URL = '/apps/#/configuration/general/ede/datamapping/UsptoTsdr'
	WHERE TASKID = 239 AND GENERICPARAM='USPTO.TSDR'
END
GO

/*** Update URL for Locality ***/
IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 234 AND URL='/apps/configuration/names/locality/#/')
BEGIN
	UPDATE CONFIGURATIONITEM SET URL = '/apps/#/configuration/general/names/locality' 
	WHERE TASKID = 234
END
GO

/*** Update URL for Event Note Type ***/
IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 228 AND URL like '%apps/configuration/events/eventnotetype/#/')
BEGIN
UPDATE CONFIGURATIONITEM SET URL = '/apps/#/configuration/general/events/eventnotetypes'
WHERE TASKID = 228
END
GO

/*** Update URL for Name Alias Type ***/
IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 238 AND URL='/apps/configuration/names/aliastype/#/')
BEGIN
	UPDATE CONFIGURATIONITEM SET URL = '/apps/#/configuration/general/names/namealiastype' 
	WHERE TASKID = 238
END
GO

/*** Update URL for Name Relationhip ***/
IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 237 AND URL='/apps/configuration/names/namerelation/#/')
BEGIN
	UPDATE CONFIGURATIONITEM SET URL = '/apps/#/configuration/general/names/namerelations'
	WHERE TASKID = 237
END
GO