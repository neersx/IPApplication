-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteNameControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteNameControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteNameControlCriteria.'
	Drop procedure [dbo].[ipw_DeleteNameControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteNameControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_DeleteNameControlCriteria]
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameCriteriaNo		int,		-- Mandatory
	@psOldPurposeCode		nchar(1)	-- Mandatory
)
as
-- PROCEDURE:	ipw_DeleteNameControlCriteria
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Deletes records from NAMECRITERIA and NAMECRITERIAINHERITS to break the inheritance

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Jul 2008	MS	RFC7085	1	Procedure created


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

-- Delete records where the criteria acts as Parent
If @nErrorCode = 0 and exists (Select * from NAMECRITERIAINHERITS Where FROMNAMECRITERIANO = @pnNameCriteriaNo)
Begin
	Set @sSQLString = "
		Delete NAMECRITERIAINHERITS
		Where FROMNAMECRITERIANO = @pnNameCriteriaNo"

	Exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnNameCriteriaNo	int',
			@pnNameCriteriaNo	= @pnNameCriteriaNo
End

-- Delete records where the criteria acts as child
If @nErrorCode = 0 and exists (Select * from NAMECRITERIAINHERITS Where NAMECRITERIANO = @pnNameCriteriaNo)
Begin
	Set @sSQLString = "
		Delete NAMECRITERIAINHERITS
		Where NAMECRITERIANO = @pnNameCriteriaNo"

	Exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnNameCriteriaNo	int',
			@pnNameCriteriaNo	= @pnNameCriteriaNo
End

-- Delete Record from NAMECRITERIA table
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Delete	NAMECRITERIA
		Where	NAMECRITERIANO	= @pnNameCriteriaNo		
		and	PURPOSECODE	= @psOldPurposeCode"

	Exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnNameCriteriaNo	int,
			  @psOldPurposeCode	nchar(1)',
			  @pnNameCriteriaNo	= @pnNameCriteriaNo,
			  @psOldPurposeCode	= @psOldPurposeCode
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteNameControlCriteria to public
GO