
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of apps_FindMatchingCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[apps_FindMatchingCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.apps_FindMatchingCases.'
	Drop procedure [dbo].[apps_FindMatchingCases]
End
Print '**** Creating Stored Procedure dbo.apps_FindMatchingCases...'
Print ''
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apps_FindMatchingCases]
(
	@pxEligibleCases XML
)
as
-- PROCEDURE:	apps_FindMatchingCases
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given an xml list of official numbers, return a filtered list of matching cases.

-- MODIFICATIONS :
-- Date			Who		Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 03/03/2015	SF		R37709	1		Procedure created.

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(max)

-- Initialise variables
set @nErrorCode = 0

-- Extract the XML
DECLARE @tbEligibleCases table
(
	CASEID INT,
	SOURCE int,
	APPLICATIONNUMBER NVARCHAR(50) COLLATE DATABASE_DEFAULT,
	APPLICATIONNUMBERCLEANED NVARCHAR(50) COLLATE DATABASE_DEFAULT,
	REGISTRATIONNUMBER NVARCHAR(50) COLLATE DATABASE_DEFAULT,
	REGISTRATIONNUMBERCLEANED NVARCHAR(50) COLLATE DATABASE_DEFAULT,
	PUBLICATIONUMBER NVARCHAR(50) COLLATE DATABASE_DEFAULT,
	PUBLICATIONUMBERCLEANED NVARCHAR(50) COLLATE DATABASE_DEFAULT,
	MATCHINGCASEID INT
)

INSERT INTO @tbEligibleCases (CASEID, SOURCE, APPLICATIONNUMBER, APPLICATIONNUMBERCLEANED, REGISTRATIONNUMBER, REGISTRATIONNUMBERCLEANED, PUBLICATIONUMBER, PUBLICATIONUMBERCLEANED)
select  N.value(N'@CaseId',N'int') as NotificationId,
		N.value(N'Source[1]',N'INT') as SourceSystemId,
		N.value(N'ApplicationNumber[1]',N'nvarchar(50)') as ApplicationNumber,
		N.value(N'ApplicationNumberCleaned[1]',N'nvarchar(50)') as ApplicationNumberCleaned,
		N.value(N'RegistrationNumber[1]',N'nvarchar(50)') as RegistrationNumber,
		N.value(N'RegistrationNumberCleaned[1]',N'nvarchar(50)') as RegistrationNumberCleaned,
		N.value(N'PublicationNumber[1]',N'nvarchar(50)') as PublicationNumber,
		N.value(N'PublicationNumberCleaned[1]',N'nvarchar(50)') as PublicationNumberCleaned
from @pxEligibleCases.nodes(N'/Cases/Case') C(N)

-- match to an integration case
UPDATE T
SET MATCHINGCASEID = C.Id
FROM @tbEligibleCases T
join Cases C on (C.Source = T.SOURCE
	and 
		((C.ApplicationNumber is not null) and 
		 (C.ApplicationNumber = T.APPLICATIONNUMBER) or C.ApplicationNumber = T.APPLICATIONNUMBERCLEANED)
	or  ((C.RegistrationNumber is not null) and 
		 (C.RegistrationNumber = T.REGISTRATIONNUMBER) or C.RegistrationNumber = T.REGISTRATIONNUMBERCLEANED)
	or  ((C.PublicationNumber is not null) and 
		 (C.PublicationNumber = T.PUBLICATIONUMBER) or C.PublicationNumber = T.PUBLICATIONUMBERCLEANED))

-- Return results
SELECT CN.CASEID as CaseKey, CN.MATCHINGCASEID as ExternalCaseKey
FROM @tbEligibleCases CN

Return @nErrorCode
GO

Grant execute on dbo.apps_FindMatchingCases to public
GO