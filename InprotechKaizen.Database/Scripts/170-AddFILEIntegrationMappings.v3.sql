
/***************************************************************************/
/***************** FILE Data Mapping Scenario - Name Type ********************/
/***************************************************************************/
if not exists (select * 
				from MAPSCENARIO MS
				where MS.STRUCTUREID = 2 and MS.SYSTEMID = -6 and MS.SCHEMEID = -3)
begin
	insert MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	values (-6, 2, -3, 0)
end
go

/***************************************************************************/
/*********** FILE Data Mapping Scenario - Case Relationship ****************/
/***************************************************************************/
if not exists (select * 
				from MAPSCENARIO MS
				where MS.STRUCTUREID = 3 and MS.SYSTEMID = -6 and MS.SCHEMEID = -3)
begin
	insert MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	values (-6, 3, -3, 0)
end
go

/***************************************************************************/
/************        FILE Map Local Filing by default              *********/
/***************************************************************************/
if exists (select CODEID 
from ENCODEDVALUE where STRUCTUREID = 1 and SCHEMEID = -1 and CODE = 'A') 
and not exists (select * from MAPPING where STRUCTUREID = 1 and DATASOURCEID = -6 and INPUTCODE = 'LOCAL FILING')
begin

	insert MAPPING (STRUCTUREID, DATASOURCEID, INPUTCODE, OUTPUTCODEID)
	select 1, -6, 'LOCAL FILING', CODEID 
	from ENCODEDVALUE where STRUCTUREID = 1 and SCHEMEID = -1 and CODE = 'A'
end
GO

/***************************************************************************/
/************        FILE Map PCT by default              *********/
/***************************************************************************/
if not exists (select * from MAPPING where DATASOURCEID = -6 and STRUCTUREID = 4 and INPUTCODE = 'PCT')
begin
	insert MAPPING (STRUCTUREID, DATASOURCEID, INPUTCODE, OUTPUTVALUE)
	values ( 4, -6, 'PCT', 'PCT')
end
go

IF not exists (select * from MAPPING where STRUCTUREID = 5 and DATASOURCEID = -6 and INPUTDESCRIPTION = 'ACKNOWLEDGED')
begin
	insert MAPPING (STRUCTUREID, DATASOURCEID, INPUTDESCRIPTION, ISNOTAPPLICABLE)
	values (5, -6, 'ACKNOWLEDGED', 1)
end

IF not exists (select * from MAPPING where STRUCTUREID = 5 and DATASOURCEID = -6 and INPUTDESCRIPTION = 'COMPLETED')
begin
	insert MAPPING (STRUCTUREID, DATASOURCEID, INPUTDESCRIPTION, ISNOTAPPLICABLE)
	values (5, -6, 'COMPLETED', 1)
end

if not exists (select * from MAPPING where STRUCTUREID = 5 and DATASOURCEID = -6 and INPUTDESCRIPTION = 'FILING RECEIPT RECEIVED')
begin
	insert MAPPING (STRUCTUREID, DATASOURCEID, INPUTDESCRIPTION, ISNOTAPPLICABLE)
	values (5, -6, 'FILING RECEIPT RECEIVED', 1)
end

if not exists (select * from MAPPING where STRUCTUREID = 5 and DATASOURCEID = -6 and INPUTDESCRIPTION = 'SENT TO AGENT')
begin
	insert MAPPING (STRUCTUREID, DATASOURCEID, INPUTDESCRIPTION, ISNOTAPPLICABLE)
	values (5, -6, 'SENT TO AGENT', 1)
end

IF not exists (select * from MAPPING where STRUCTUREID = 5 and DATASOURCEID = -6 and INPUTDESCRIPTION = 'RECEIVED BY AGENT')
begin
	insert MAPPING (STRUCTUREID, DATASOURCEID, INPUTDESCRIPTION, ISNOTAPPLICABLE)
	values (5, -6, 'RECEIVED BY AGENT', 1)
end

if not exists (select * from MAPPING where STRUCTUREID = 5 and DATASOURCEID = -6 and INPUTDESCRIPTION = 'SENT TO PTO')
begin
	insert MAPPING (STRUCTUREID, DATASOURCEID, INPUTDESCRIPTION, ISNOTAPPLICABLE)
	values (5, -6, 'SENT TO PTO', 1)
END

go