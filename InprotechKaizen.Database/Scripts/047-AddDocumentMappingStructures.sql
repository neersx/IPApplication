IF NOT EXISTS (SELECT * FROM MAPSTRUCTURE WHERE STRUCTUREID = 14 AND STRUCTURENAME = 'Documents')
Begin
	print '**** RFC47616 Adding Documents Map Structure.'
	INSERT INTO MAPSTRUCTURE (STRUCTUREID, STRUCTURENAME, TABLENAME, KEYCOLUMNAME, CODECOLUMNNAME, DESCCOLUMNNAME, SEARCHCONTEXTID)
	VALUES (14, 'Documents', 'EVENTS', 'EVENTNO', 'EVENTNO', 'EVENTDESCRIPTION', 20)
	print '**** RFC47616 Documents Map Structure added.'
	print ''
End
Else
Begin
	print '**** RFC47616 Documents Map Structure already exists.'
	print ''
End
go

IF NOT EXISTS (SELECT * FROM MAPSCENARIO WHERE SYSTEMID = -3 AND STRUCTUREID = 14)
Begin
	print '**** RFC47616 Adding USPTO/TSDR Map Scenario.'
	INSERT INTO MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	VALUES (-3, 14, -3, 1)
	print '**** RFC47616 USPTO/TSDR Map Scenario added.'
	print ''
End
Else
Begin
	print '**** RFC47616 USPTO/TSDR Map Scenario already exists.'
	print ''
End
go

IF NOT EXISTS (SELECT * FROM MAPSCENARIO WHERE SYSTEMID = -2 AND STRUCTUREID = 14)
Begin
	print '**** RFC47616 Adding European Patent Office Map Scenario.'
	INSERT INTO MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	VALUES (-2, 14, -3, 1)
	print '**** RFC47616 European Patent Office Map Scenario added.'
	print ''
End
Else
Begin
	print '**** RFC47616 European Patent Office Map Scenario already exists.'
	print ''
End
go

IF NOT EXISTS (SELECT * FROM MAPSCENARIO WHERE SYSTEMID = -1 AND STRUCTUREID = 14)
Begin
	print '**** RFC47616 Adding USPTO/PAIR Map Scenario.'
	INSERT INTO MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	VALUES (-1, 14, -3, 1)
	print '**** RFC47616 USPTO/PAIR Map Scenario added.'
	print ''
End
Else
Begin
	print '**** RFC47616 USPTO/PAIR Map Scenario already exists.'
	print ''
End
go

IF NOT EXISTS (SELECT * FROM ENCODINGSTRUCTURE WHERE SCHEMEID = -3 AND STRUCTUREID = 14)
Begin
	print '**** RFC47616 Adding Document Encoding Structure.'
	INSERT INTO ENCODINGSTRUCTURE (SCHEMEID, STRUCTUREID, NAME, DESCRIPTION)
	VALUES (-3, 14, 'CPA XML Data Exchange Document Code', 'Common Document Code for CPA XML Data Exchange scheme')
	print '**** RFC47616 Document Encoding Structure added.'
	print ''
End
Else
Begin
	print '**** RFC47616 Document Encoding Structure already exists.'
	print ''
End
go