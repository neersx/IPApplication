If exists (SELECT * FROM MAPSCENARIO WHERE SYSTEMID = -3 AND SCHEMEID IS NULL)
Begin
	PRINT '**** RFC37315 Update USPTO/TSDR mapping to use CPA-XML encoding by default.'
	UPDATE MAPSCENARIO
	SET SCHEMEID = -3
	WHERE SYSTEMID = -3
	AND SCHEMEID IS NULL
	PRINT '**** RFC37315 USPTO/TSDR mapping updated.'
	PRINT ''
End
Else
Begin
	PRINT 'RFC37315 USPTO/TSDR already has an encoding scheme set.'
End

If exists (SELECT * FROM MAPSCENARIO WHERE SYSTEMID = -1 AND SCHEMEID IS NULL)
Begin
	PRINT 'RFC37315 Update USPTO/PrivatePAIR mapping to use CPA-XML encoding by default'
	UPDATE MAPSCENARIO
	SET SCHEMEID = -3
	WHERE SYSTEMID = -1
	AND SCHEMEID IS NULL
	PRINT '**** RFC37315 USPTO/PrivatePAIR mapping updated.'
End
Else
Begin
	PRINT 'RFC37315 USPTO/PrivatePAIR already has an encoding scheme set.'
End

If exists (SELECT * FROM MAPSCENARIO WHERE SYSTEMID = -2 AND STRUCTUREID = 5 AND SCHEMEID = -3 AND ISNULL(IGNOREUNMAPPED,0) = 0)
Begin
	PRINT 'RFC37315 Update EPO Event mapping to ignore unmapped values.'
	UPDATE MAPSCENARIO
	SET IGNOREUNMAPPED = 1 
	WHERE SYSTEMID = -2
	AND STRUCTUREID = 5
	AND SCHEMEID = -3
	PRINT 'RFC37315 EPO Event mapping updated.'
End
Else
Begin
	PRINT 'RFC37315 EPO Event mapping already ignoring unmapped values.'
End
go