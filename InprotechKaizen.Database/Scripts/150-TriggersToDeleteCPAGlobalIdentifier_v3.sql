-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_app_CPANumberTypes
-----------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[fn_app_CPANumberTypes]') AND XTYPE IN (N'FN', N'IF', N'TF'))
BEGIN
	PRINT '**** Drop function dbo.fn_app_CPANumberTypes.'
	DROP FUNCTION [dbo].[fn_app_CPANumberTypes]
END
GO
PRINT '**** Creating function dbo.fn_app_CPANumberTypes...'
PRINT ''

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_app_CPANumberTypes]()
RETURNS @OfficialNumberTypes TABLE(
numberType VARCHAR(MAX))
AS
-- FUNCTION :	fn_app_CPANumberTypes
-- VERSION :	1
-- DESCRIPTION:	This function return number types for Application, Registration, Publication numbers.

-- MODIFICATIONS :
-- Date			Who		Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 11 MAY 2017	SS		1		Function created

BEGIN
	DECLARE @NumberTypesToConsider VARCHAR(MAX)

	SELECT @NumberTypesToConsider = COALESCE(NULLIF(@NumberTypesToConsider + ',', ','), '') + 
	CASE CONTROLID
		WHEN 'CPA Number-Application' THEN ISNULL(NULLIF(LTRIM(RTRIM(COLCHARACTER)),''), 'A') 
		WHEN 'CPA Number-Publication' THEN ISNULL(NULLIF(LTRIM(RTRIM(COLCHARACTER)),''), 'P') 
		WHEN 'CPA Number-Registration' THEN ISNULL(NULLIF(LTRIM(RTRIM(COLCHARACTER)),''), 'R') 
	END
	FROM SiteControl
	WHERE ControlId IN ('CPA Number-Application', 'CPA Number-Publication', 'CPA Number-Registration')

	INSERT INTO @OfficialNumberTypes(numberType) 
		SELECT DISTINCT(LTRIM(RTRIM(PARAMETER))) FROM fn_Tokenise( @NumberTypesToConsider, ',')
	RETURN
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT REFERENCES ON dbo.fn_app_CPANumberTypes TO PUBLIC
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Update Trigger for Cases
-----------------------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM sysobjects WHERE TYPE='TR'AND NAME='tU_CASES_CpaGlobalidentifier')
BEGIN
	PRINT 'Refreshing trigger tU_CASES_CpaGlobalidentifier...'
	DROP TRIGGER tU_CASES_CpaGlobalidentifier
END
ELSE
BEGIN
	PRINT 'Creating trigger tU_CASES_CpaGlobalidentifier...'
END
GO

CREATE TRIGGER [dbo].[tU_CASES_CpaGlobalidentifier] on [dbo].[CASES] AFTER UPDATE NOT FOR REPLICATION 

AS
-- TRIGGER :	tU_CASES_CpaGlobalidentifier
-- VERSION :	1
-- DESCRIPTION:	Deletes CPAGLOBALIDENTIFIER if case properties change 

-- MODIFICATIONS :
-- Date			Who		RFC		Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 May 2017	SS		70276	1		Trigger created.
BEGIN

	IF UPDATE(CASETYPE) OR UPDATE(PROPERTYTYPE) OR UPDATE(COUNTRYCODE)
	BEGIN

		DELETE C 
		FROM CPAGLOBALIDENTIFIER C
		INNER JOIN INSERTED I ON C.CASEID = I.CASEID
		INNER JOIN DELETED D ON I.CASEID = D.CASEID
		WHERE (I.CASETYPE <> D.CASETYPE OR I.PROPERTYTYPE <> D.PROPERTYTYPE OR I.COUNTRYCODE <> D.COUNTRYCODE)
	END
END
GO 
