-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ValidateSelectedCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ValidateSelectedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ValidateSelectedCase.'
	Drop procedure [dbo].[csw_ValidateSelectedCase]
End
Print '**** Creating Stored Procedure dbo.csw_ValidateSelectedCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

Create PROCEDURE [dbo].[csw_ValidateSelectedCase]
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pnCaseKey			int,			
	@psOfficialNumber		nvarchar(36)	= null,	 
	@pnInstructorNameKey		int		= null
)
as
-- PROCEDURE:	csw_ValidateSelectedCase
-- VERSION:	1
-- DESCRIPTION:	Validates 1 or 0 based on Official Number or Instructor NameKey matching the case provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Mar 2012	SF	R11318	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @nMatchCount	int
Declare @nItemsToMatch	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0
Set @nMatchCount	= 0
Set @nItemsToMatch 	= 0

If @nErrorCode = 0
and not (@psOfficialNumber is null or @psOfficialNumber = '')
Begin		
	Set @nItemsToMatch = @nItemsToMatch + 1

	Set @sSQLString = "
		Select @nMatchCount = @nMatchCount + count(*)
		from CASES 
		where CASEID = @pnCaseKey
		and CURRENTOFFICIALNO = @psOfficialNumber
	"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@nMatchCount		int output,
				@pnCaseKey		int,
				@psOfficialNumber	nvarchar(36)',
				@nMatchCount		= @nMatchCount output,
				@psOfficialNumber	= @psOfficialNumber,
				@pnCaseKey		= @pnCaseKey
End

If @nErrorCode = 0
and @pnInstructorNameKey is not null
Begin
	Set @nItemsToMatch = @nItemsToMatch + 1
	
	Set @sSQLString = "
		Select 	@nMatchCount = @nMatchCount + count(*)
		from 	CASENAME 
		where 	CASEID = @pnCaseKey
		and 	NAMENO = @pnInstructorNameKey
		and 	NAMETYPE = 'I'
	"
		
	exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@nMatchCount		int output,
				@pnCaseKey		int,
				@pnInstructorNameKey	int',
				@nMatchCount		= @nMatchCount output,
				@pnInstructorNameKey	= @pnInstructorNameKey,
				@pnCaseKey		= @pnCaseKey
End

If @nErrorCode = 0
Begin
	Select	CASE 
			WHEN 
				@nMatchCount = @nItemsToMatch 
			THEN cast(1 as bit) 
			ELSE cast(0 as bit) 
		END
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ValidateSelectedCase to public
GO