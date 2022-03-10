-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetAssignmentChildCount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetAssignmentChildCount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetAssignmentChildCount.'
	Drop procedure [dbo].[csw_GetAssignmentChildCount]
End
Print '**** Creating Stored Procedure dbo.csw_GetAssignmentChildCount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetAssignmentChildCount
(
	@pnUserIdentityId	int,	-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null
)
as
-- PROCEDURE:	csw_GetAssignmentChildCount
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Counts all records for child tables of SearchResults

-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 23 Jun 2011	KR	RFC7904	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0


If @nErrorCode = 0
Begin

	Set @sSQLString = "	
	Select 'AssignedCases' as TableName, count(*) as Count
	FROM RELATEDCASE R
	Join CASERELATION CR on (CR.RELATIONSHIP = R.RELATIONSHIP)
	LEFT OUTER JOIN CASES C ON R.RELATEDCASEID = C.CASEID
	WHERE R.CASEID = @pnCaseKey AND R.RELATIONSHIP = 'ASG'
	union
	Select 'ApplyAssignment' as TableName, count(*) as Count
	FROM RELATEDCASE R
	Join CASERELATION CR on (CR.RELATIONSHIP = R.RELATIONSHIP)
	LEFT OUTER JOIN CASES C ON R.RELATEDCASEID = C.CASEID
	WHERE R.CASEID = @pnCaseKey AND R.RELATIONSHIP = 'ASG'"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pnCaseKey		int',
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnCaseKey		= @pnCaseKey

End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetAssignmentChildCount to public
GO
