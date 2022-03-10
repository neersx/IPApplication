IF NOT EXISTS(SELECT * FROM dbo.MAPPING WHERE INPUTCODE = 'PCT' AND DATASOURCEID = -1)
BEGIN
	PRINT '**** R48995 Adding data mapping for USPTOPrivatepair - country PCT.'
	INSERT dbo.MAPPING(STRUCTUREID, DATASOURCEID, INPUTCODE, OUTPUTVALUE)
	SELECT 4, -1, 'PCT', 'PCT'
	PRINT '**** R48995 Added data mapping for USPTOPrivatepair - country PCT .'
END
ELSE
BEGIN
PRINT '**** R48995 Raw data mapping for USPTOPrivatepair - country PCT  exists already'
	PRINT ''
END