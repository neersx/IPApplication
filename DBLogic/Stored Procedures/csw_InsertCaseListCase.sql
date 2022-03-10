-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertCaseListCase 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertCaseListCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertCaseListCase.'
	Drop procedure [dbo].[csw_InsertCaseListCase]
End
Print '**** Creating Stored Procedure dbo.csw_InsertCaseListCase...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

-- Allow comparison of null values
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_InsertCaseListCase
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnListKey		int,			-- Mandatory
	@pnCaseKey		int,			-- Mandatory
	@pdtLastModifiedDate	datetime	= null OUTPUT
)
as
-- PROCEDURE:	csw_InsertCaseListCase
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Inserts the case list members.  Used by the Web version.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 MAR 2011	KR		RFC6563	1		Procedure created

SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @nCaseListNo int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
		Set @sSQLString = "Insert into CASELISTMEMBER
		(
		CASELISTNO,
		CASEID,
		PRIMECASE
		)
		Values
		(
		@pnListKey,
		@pnCaseKey,
		0
		)
		
		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	CASELISTMEMBER
		where	CASELISTNO	= @pnListKey
		and		CASEID		= @pnCaseKey"
		
		exec @nErrorCode = sp_executesql @sSQLString,
		 				N'@pnListKey		int,
		 				@pnCaseKey			int,
		 				@pdtLastModifiedDate	datetime output',
						@pnListKey			= @pnListKey,
						@pnCaseKey			= @pnCaseKey,
						@pdtLastModifiedDate = 		@pdtLastModifiedDate output
						
		Select @pdtLastModifiedDate		as LastModifiedDate
			

End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertCaseListCase to public
GO
