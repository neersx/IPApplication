set quoted_identifier off
set nocount on
set concat_null_yields_null off

-- Data Mapping Testing
-- Test data mapping logic.

-- This is done by creating a temporary table containing the test conditions and
-- then running the mapping procedure to update the table.

declare @sSQLString 	as nvarchar(4000)
If not exists(select * from tempdb.dbo.sysobjects where name = '##TEMPTEST' )
Begin
	create table ##TEMPTEST
		(INPUTCODE		nvarchar(50) collate database_default,
		INPUTDESCRIPTION	nvarchar(254) collate database_default,
		OUTPUTVALUE		nvarchar(50) collate database_default,
		EXPECTEDRESULT		nvarchar(50) collate database_default,
		TESTCONDITION		nvarchar(254) collate database_default
		)
End
Else
Begin
	delete ##TEMPTEST
End

declare @sScenarios		nvarchar(20)  -- comma separated list of scenarios required.
declare @nErrorCode		int
declare @nStructureID		smallint
declare @nDataSourceID		int
declare @nCommonSchemeID	smallint
declare @nInputSchemeID		smallint
declare @nDebugFlag		tinyint

Set @nErrorCode = 0
Set @sScenarios = null
Set @nCommonSchemeID = -1
Set @nDebugFlag = 1

delete ##TEMPTEST
DELETE MAPPING WHERE ENTRYID>0
DELETE ENCODEDVALUE WHERE CODE LIKE 'TEST%'
DELETE ENCODEDVALUE WHERE DESCRIPTION LIKE 'TEST%'

Set @nDataSourceID = -1

-- Test Scenario 1:  Mapping of raw code data
If @nErrorCode = 0
and (@sScenarios is null or
     patindex('%'+','+'1'+','+'%',',' + @sScenarios + ',')>0 )
Begin
	print 'Scenario 1 - Mapping of raw code data'
	Set @nStructureID = 1 -- Number Types

	-- Insert test conditions
	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('a',null,'1.1','1.1 Input code to output value')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,'A',null,null,null,'1.1',0)

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('b',null,'1.2','1.2 Input code to common encoding to output value')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,@nDataSourceID,'B',null,null,CODEID,NULL,0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = 'R'
	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,null,null,CODEID,null,'1.2',0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = 'R'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('12345678901234567890123456789012345678901234567890',null,'deleted row','1.3 Input code to not applicable')
	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,'12345678901234567890123456789012345678901234567890',null,null,null,null,1)


	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('c',null,'deleted row','1.4 Input code to common encoding to not applicable')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,@nDataSourceID,'C',null,null,CODEID,NULL,0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = 'P'
	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,null,null,CODEID,null,NULL,1
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = 'P'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('no match',null,'error message','1.5 Input code to common encoding to no match')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,@nDataSourceID,'no match',null,null,CODEID,NULL,0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = 'A'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('f',null,'error message','1.6 Input code to no match')

	exec @nErrorCode = dbo.dm_ApplyMapping
		@pnUserIdentityId	= 5,
		@pnMapStructureKey	= @nStructureID,
		@pnDataSourceKey	= @nDataSourceID,
		@pnFromSchemeKey	= null,
		@pnCommonSchemeKey	= @nCommonSchemeID,
		@psTableName		= '##TEMPTEST',
		@psCodeColumnName	= 'INPUTCODE',
		@psDescriptionColumnName = null,
		@psMappedColumn		= 'OUTPUTVALUE',
		@pnDebugFlag		= @nDebugFlag

End

SELECT * FROM ##TEMPTEST order by TESTCONDITION
Set @nErrorCode = 0
delete ##TEMPTEST
DELETE MAPPING WHERE ENTRYID>0
DELETE ENCODEDVALUE WHERE CODE LIKE 'TEST%'
DELETE ENCODEDVALUE WHERE DESCRIPTION LIKE 'TEST%'

-- Test Scenario 2:  Mapping of raw description data
If @nErrorCode = 0
and (@sScenarios is null or
     patindex('%'+','+'2'+','+'%',',' + @sScenarios + ',')>0 )
Begin
	print 'Scenario 2 - Mapping of raw description data'
	Set @nStructureID = 5 -- Events

	-- Insert test conditions
	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (NULL,'1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890AB',
	'2.1','2.1 Input description to output value')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,null,'1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890AB'
		,null,null,'2.1',0)

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'description','2.2','2.2 Input description to common encoding to output value')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,@nDataSourceID,null,'DESCRIPTION',null,CODEID,NULL,0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = '-11335'
	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,null,null,CODEID,null,'2.2',0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = '-11335'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'!@#$$%^&&*()''','deleted row','2.3 Input description to not applicable')
	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,null,'!@#$$%^&&*()''',null,null,null,1)


	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'1234','deleted row','2.4 Input description to common encoding to not applicable')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,@nDataSourceID,NULL,'1234',null,CODEID,NULL,0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = '-11331'
	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,null,null,CODEID,null,NULL,1
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = '-11331'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'no match','deleted row - ignore unmapped','2.5 Input description to common encoding to no match')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,@nDataSourceID,null,'NO MATCH',null,CODEID,NULL,0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = '-11330'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'no match again','deleted row - ignore unmapped','2.6 Input description to no match')

	exec @nErrorCode = dbo.dm_ApplyMapping
		@pnUserIdentityId	= 5,
		@pnMapStructureKey	= @nStructureID,
		@pnDataSourceKey	= @nDataSourceID,
		@pnFromSchemeKey	= null,
		@pnCommonSchemeKey	= @nCommonSchemeID,
		@psTableName		= '##TEMPTEST',
		@psCodeColumnName	= null,
		@psDescriptionColumnName = 'INPUTDESCRIPTION',
		@psMappedColumn		= 'OUTPUTVALUE',
		@pnDebugFlag		= @nDebugFlag

End

SELECT * FROM ##TEMPTEST order by TESTCONDITION
Set @nErrorCode = 0
delete ##TEMPTEST
DELETE MAPPING WHERE ENTRYID>0
DELETE ENCODEDVALUE WHERE CODE LIKE 'TEST%'
DELETE ENCODEDVALUE WHERE DESCRIPTION LIKE 'TEST%'

-- Test Scenario 3:  Mapping of encoded code data
If @nErrorCode = 0
and (@sScenarios is null or
     patindex('%'+','+'3'+','+'%',',' + @sScenarios + ',')>0 )
Begin
	print 'Scenario 3 - Mapping of encoded code data'
	Set @nStructureID = 4 -- Country
	Set @nInputSchemeID = -2 -- WIPO

	-- Insert test conditions
	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('TEST1',null,'3.1','3.1 Input encoded code to output value')

	INSERT INTO ENCODEDVALUE (SCHEMEID,STRUCTUREID,CODE)
	SELECT S.SCHEMEID, S.STRUCTUREID, 'TEST1'
	FROM ENCODINGSTRUCTURE S
	WHERE NOT EXISTS(
		SELECT * FROM ENCODEDVALUE V2
		WHERE V2.SCHEMEID=S.SCHEMEID
		AND V2.STRUCTUREID=S.STRUCTUREID
		AND V2.CODE='TEST1')
	and S.SCHEMEID=@nInputSchemeID
	AND S.STRUCTUREID=@nStructureID

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,NULL,null,CODEID,NULL,'3.1',0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nInputSchemeID
	AND CODE = 'TEST1'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('AE',null,'3.2','3.2 Input encoded code to common encoding to output value')

	-- WIPO to CPAINPRO mapping already on database.
	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,null,null,CODEID,null,'3.2',0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = 'AE'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('TEST2',null,'delete row','3.3 Input encoded code to not applicable')

	INSERT INTO ENCODEDVALUE (SCHEMEID,STRUCTUREID,CODE)
	SELECT S.SCHEMEID, S.STRUCTUREID, 'TEST2'
	FROM ENCODINGSTRUCTURE S
	WHERE NOT EXISTS(
		SELECT * FROM ENCODEDVALUE V2
		WHERE V2.SCHEMEID=S.SCHEMEID
		AND V2.STRUCTUREID=S.STRUCTUREID
		AND V2.CODE='TEST2')
	and S.SCHEMEID=@nInputSchemeID
	AND S.STRUCTUREID=@nStructureID

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,NULL,null,CODEID,NULL,null,1
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nInputSchemeID
	AND CODE = 'TEST2'


	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('am',null,'delete row','3.4 Input encoded code to common encoding to not applicable')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,null,null,CODEID,null,NULL,1
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND CODE = 'AM'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('AR',null,'error','3.5 Input encoded code to common encoding to no match')

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('br',null,'3.6','3.6 Input raw code to output value overrides input encoded code')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,'BR',null,null,null,'3.6',0)

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('AT',null,'delete row','3.7 Input raw code to not applicable overrides input encoded code')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,'AT',null,null,null,null,1)


End

-- Test Scenario 4:  Mapping of encoded description data
If @nErrorCode = 0
and (@sScenarios is null or
     patindex('%'+','+'4'+','+'%',',' + @sScenarios + ',')>0 )
Begin
	print 'Scenario 4 - Mapping of encoded description data'
	Set @nStructureID = 4 -- Country
	Set @nInputSchemeID = -2 -- WIPO

	-- Insert test conditions
	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'TESTDESC1','4.1','4.1 Input encoded description to output value')

	INSERT INTO ENCODEDVALUE (SCHEMEID,STRUCTUREID,DESCRIPTION)
	SELECT S.SCHEMEID, S.STRUCTUREID, 'TESTDESC1'
	FROM ENCODINGSTRUCTURE S
	WHERE NOT EXISTS(
		SELECT * FROM ENCODEDVALUE V2
		WHERE V2.SCHEMEID=S.SCHEMEID
		AND V2.STRUCTUREID=S.STRUCTUREID
		AND V2.DESCRIPTION='TESTDESC1')
	and S.SCHEMEID=@nInputSchemeID
	AND S.STRUCTUREID=@nStructureID

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,NULL,null,CODEID,NULL,'4.1',0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nInputSchemeID
	AND DESCRIPTION = 'TESTDESC1'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (NULL,'CANADA','4.2','4.2 Input encoded description to common encoding to output value')

	-- WIPO to CPAINPRO mapping already on database.
	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,null,null,CODEID,null,'4.2',0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND DESCRIPTION = 'CANADA'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'TESTDESC2','delete row','4.3 Input encoded description to not applicable')

	INSERT INTO ENCODEDVALUE (SCHEMEID,STRUCTUREID,DESCRIPTION)
	SELECT S.SCHEMEID, S.STRUCTUREID, 'TESTDESC2'
	FROM ENCODINGSTRUCTURE S
	WHERE NOT EXISTS(
		SELECT * FROM ENCODEDVALUE V2
		WHERE V2.SCHEMEID=S.SCHEMEID
		AND V2.STRUCTUREID=S.STRUCTUREID
		AND V2.DESCRIPTION='TESTDESC2')
	and S.SCHEMEID=@nInputSchemeID
	AND S.STRUCTUREID=@nStructureID

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,NULL,null,CODEID,NULL,null,1
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nInputSchemeID
	AND DESCRIPTION = 'TESTDESC2'


	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'C�TE D''IVOIRE','delete row','4.4 Input encoded description to common encoding to not applicable')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,null,null,CODEID,null,NULL,1
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nCommonSchemeID
	AND DESCRIPTION = 'C�TE D''IVOIRE'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'CENTRAL AFRICAN REPUBLIC','error','4.5 Input encoded description to common encoding to no match')

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'congo','4.6','4.6 Input raw description to output value overrides input encoded code')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,null,'CONGO',null,null,'4.6',0)

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'SWITZERLAND','delete row','4.7 Input raw description to not applicable overrides input encoded code')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,null,'SWITZERLAND',null,null,null,1)


End

-- Perform both code and description processing
If @nErrorCode = 0
and ((@sScenarios is null or
     patindex('%'+','+'3'+','+'%',',' + @sScenarios + ',')>0 )
or  (@sScenarios is null or
     patindex('%'+','+'4'+','+'%',',' + @sScenarios + ',')>0 ))
Begin

	exec @nErrorCode = dbo.dm_ApplyMapping
		@pnUserIdentityId	= 5,
		@pnMapStructureKey	= @nStructureID,
		@pnDataSourceKey	= @nDataSourceID,
		@pnFromSchemeKey	= NULL, -- Test defaulting to WIPO
		@pnCommonSchemeKey	= @nCommonSchemeID,
		@psTableName		= '##TEMPTEST',
		@psCodeColumnName	= 'INPUTCODE',
		@psDescriptionColumnName = 'INPUTDESCRIPTION',
		@psMappedColumn		= 'OUTPUTVALUE',
		@pnDebugFlag		= @nDebugFlag

End

SELECT * FROM ##TEMPTEST order by TESTCONDITION
Set @nErrorCode = 0
delete ##TEMPTEST
DELETE MAPPING WHERE ENTRYID>0
DELETE ENCODEDVALUE WHERE CODE LIKE 'TEST%'
DELETE ENCODEDVALUE WHERE DESCRIPTION LIKE 'TEST%'

-- Test Scenario 5:  Mapping of common encoded code data
If @nErrorCode = 0
and (@sScenarios is null or
     patindex('%'+','+'5'+','+'%',',' + @sScenarios + ',')>0 )
Begin
	print 'Scenario 5 - Mapping of common encoded code data'
	Set @nStructureID = 3 -- Case relation
	Set @nInputSchemeID = -1 -- CPAINPRO

	-- Insert test conditions
	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('BAS',null,'5.1','5.1 Input common encoded code to output value')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,NULL,null,CODEID,NULL,'5.1',0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nInputSchemeID
	AND CODE = 'BAS'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('ORC',null,'delete row','5.2 Input encoded code to not applicable')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,NULL,null,CODEID,NULL,null,1
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nInputSchemeID
	AND CODE = 'ORC'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('ORG',null,'5.3','5.3 Input raw code to output value overrides input encoded code')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,'ORG',null,null,null,'5.3',0)

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES ('PAR',null,'delete row','5.4 Input raw code to not applicable overrides input encoded code')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,'PAR',null,null,null,null,1)

	exec @nErrorCode = dbo.dm_ApplyMapping
		@pnUserIdentityId	= 5,
		@pnMapStructureKey	= @nStructureID,
		@pnDataSourceKey	= @nDataSourceID,
		@pnFromSchemeKey	= @nInputSchemeID,
		@pnCommonSchemeKey	= @nCommonSchemeID,
		@psTableName		= '##TEMPTEST',
		@psCodeColumnName	= 'INPUTCODE',
		@psDescriptionColumnName = null,
		@psMappedColumn		= 'OUTPUTVALUE',
		@pnDebugFlag		= @nDebugFlag
End

SELECT * FROM ##TEMPTEST order by TESTCONDITION
Set @nErrorCode = 0
delete ##TEMPTEST
DELETE MAPPING WHERE ENTRYID>0
DELETE ENCODEDVALUE WHERE CODE LIKE 'TEST%'
DELETE ENCODEDVALUE WHERE DESCRIPTION LIKE 'TEST%'

-- Test Scenario 6:  Mapping of common encoded description data
If @nErrorCode = 0
and (@sScenarios is null or
     patindex('%'+','+'6'+','+'%',',' + @sScenarios + ',')>0 )
Begin
	print 'Scenario 6 - Mapping of common encoded description data'
	Set @nStructureID = 5 -- Event
	Set @nInputSchemeID = -1 -- CPAINPRO

	-- Insert test conditions
	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'EXPIRY DEADLINE','6.1','6.1 Input common encoded description to output value')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,NULL,null,CODEID,NULL,'6.1',0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nInputSchemeID
	AND DESCRIPTION = 'EXPIRY DEADLINE'


	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'TRANSLATION OF PRIORITY DOCUMENTS LODGED','delete row','6.2 Input common encoded description to not applicable')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,NULL,null,CODEID,NULL,null,1
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nInputSchemeID
	AND DESCRIPTION = 'TRANSLATION OF PRIORITY DOCUMENTS LODGED'

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'CHANGE OF ADDRESS FILED','6.3','6.3 Input raw description to output value overrides input common encoded code')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,null,'CHANGE OF ADDRESS FILED',null,null,'6.3',0)

	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'NOTICE OF ALLOWANCE','delete row','6.4 Input raw description to not applicable overrides input common encoded code')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	VALUES (@nStructureID,@nDataSourceID,null,'NOTICE OF ALLOWANCE',null,null,null,1)

	exec @nErrorCode = dbo.dm_ApplyMapping
		@pnUserIdentityId	= 5,
		@pnMapStructureKey	= @nStructureID,
		@pnDataSourceKey	= @nDataSourceID,
		@pnFromSchemeKey	= @nInputSchemeID,
		@pnCommonSchemeKey	= @nCommonSchemeID,
		@psTableName		= '##TEMPTEST',
		@psCodeColumnName	= null,
		@psDescriptionColumnName = 'INPUTDESCRIPTION',
		@psMappedColumn		= 'OUTPUTVALUE',
		@pnDebugFlag		= @nDebugFlag
End

SELECT * FROM ##TEMPTEST order by TESTCONDITION
Set @nErrorCode = 0
delete ##TEMPTEST
DELETE MAPPING WHERE ENTRYID>0
DELETE ENCODEDVALUE WHERE CODE LIKE 'TEST%'
DELETE ENCODEDVALUE WHERE DESCRIPTION LIKE 'TEST%'

-- Test Scenario 7:  Map descriptions with no errors
If @nErrorCode = 0
and (@sScenarios is null or
     patindex('%'+','+'6'+','+'%',',' + @sScenarios + ',')>0 )
Begin
	print 'Scenario 7 - Map descriptions with no errors'
	Set @nStructureID = 2 -- Name Type

	-- Insert test conditions
	INSERT INTO ##TEMPTEST
	(INPUTCODE,INPUTDESCRIPTION,EXPECTEDRESULT,TESTCONDITION)
	VALUES (null,'Examiner','7.1','7.1 Input raw description to output value')

	INSERT INTO MAPPING
	(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)
	select STRUCTUREID,null,NULL,null,CODEID,NULL,'7.1',0
	from ENCODEDVALUE
	where STRUCTUREID = @nStructureID
	AND SCHEMEID=@nInputSchemeID
	AND DESCRIPTION = 'EXAMINER'

	exec @nErrorCode = dbo.dm_ApplyMapping
		@pnUserIdentityId	= 5,
		@pnMapStructureKey	= @nStructureID,
		@pnDataSourceKey	= @nDataSourceID,
		@pnFromSchemeKey	= @nInputSchemeID,
		@pnCommonSchemeKey	= @nCommonSchemeID,
		@psTableName		= '##TEMPTEST',
		@psCodeColumnName	= null,
		@psDescriptionColumnName = 'INPUTDESCRIPTION',
		@psMappedColumn		= 'OUTPUTVALUE',
		@pnDebugFlag		= @nDebugFlag
End

SELECT * FROM ##TEMPTEST order by TESTCONDITION
Set @nErrorCode = 0
delete ##TEMPTEST
DELETE MAPPING WHERE ENTRYID>0
DELETE ENCODEDVALUE WHERE CODE LIKE 'TEST%'
DELETE ENCODEDVALUE WHERE DESCRIPTION LIKE 'TEST%'





