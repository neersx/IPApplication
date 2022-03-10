-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteOrganisation									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteOrganisation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteOrganisation.'
	Drop procedure [dbo].[naw_DeleteOrganisation]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteOrganisation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteOrganisation
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@psOldRegistrationNo		nvarchar(30)	= null,
	@psOldIncorporated		nvarchar(254)	= null,
	@pnOldParentNameKey		int		= null,
	@pbIsRegistrationNoInUse	bit	 	= 0,
	@pbIsIncorporatedInUse		bit	 	= 0,
	@pbIsParentNameKeyInUse		bit	 	= 0
)
as
-- PROCEDURE:	naw_DeleteOrganisation
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Organisation if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 12 Apr 2006	AU	RFC3505	1	Procedure created
-- 11 May 2010	PA	RFC9097	2	Remove the deletion of VATNO as the TAXNO field is used for this in NAME table

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from ORGANISATION
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
				NAMENO = @pnNameKey and
				"

	If @pbIsRegistrationNoInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"REGISTRATIONNO = @psOldRegistrationNo"
		Set @sAnd = " and "
	End
	
	If @pbIsIncorporatedInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"INCORPORATED = @psOldIncorporated"
		Set @sAnd = " and "
	End

	If @pbIsParentNameKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PARENT = @pnOldParentNameKey"
		Set @sAnd = " and "
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			N'
			@pnNameKey		int,
			@psOldRegistrationNo	nvarchar(30),
			@psOldIncorporated	nvarchar(254),
			@pnOldParentNameKey	int',
			@pnNameKey	 	= @pnNameKey,
			@psOldRegistrationNo	= @psOldRegistrationNo,
			@psOldIncorporated	= @psOldIncorporated,
			@pnOldParentNameKey	= @pnOldParentNameKey


End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteOrganisation to public
GO