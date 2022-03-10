/**************************************************************************/
/*** RFC47615 Convert Encoded Raw Values to Simple Raw Mapped Values	***/
/**************************************************************************/

IF EXISTS (SELECT * FROM MAPPING WHERE DATASOURCEID IS NOT NULL AND OUTPUTCODEID IS NOT NULL AND OUTPUTVALUE IS NULL AND STRUCTUREID = 5)
Begin
	print '**** RFC47615 Convert Raw Mapped Encoded Values to simple Mapped Values.'
	UPDATE M
	SET OUTPUTVALUE = EV.CODE,
	OUTPUTCODEID = NULL
	FROM MAPPING M
	JOIN ENCODEDVALUE EV ON EV.CODEID = M.OUTPUTCODEID
	WHERE M.DATASOURCEID IS NOT NULL
	AND M.OUTPUTVALUE IS NULL
	AND M.STRUCTUREID = 5
	print '**** RFC47615 Raw Mapped Encoded Values converted to simple Mapped Values.'
	print ''
End
Else
Begin
        print '**** RFC47615 Raw Mapped Encoded Values already up to date.'
	print ''
End
go