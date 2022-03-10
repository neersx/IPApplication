  IF EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 236 AND URL = '/apps/configuration/dmsintegration/#')
    Begin
	    print '***** DR-56898 Fix URL to DMS Integration configuration item.'
	    UPDATE CONFIGURATIONITEM
	    SET URL = '/apps/#/configuration/dmsintegration'
	    WHERE TASKID = 236
	    print '***** DR-56898 URL added to DMS Integration configuration item.'
	    print ''
    End
    Else
    Begin
	    print '***** DR-56898 URL already fixed for DMS Integration configuration item.'
	    print ''
    End
    go