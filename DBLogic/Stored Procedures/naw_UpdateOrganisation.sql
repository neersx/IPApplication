-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateOrganisation									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateOrganisation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateOrganisation.'
	Drop procedure [dbo].[naw_UpdateOrganisation]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateOrganisation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateOrganisation
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@psRegistrationNo		nvarchar(30)	= null,
	@psIncorporated			nvarchar(254)	= null,
	@pnParentNameKey		int		= null,
	@psOldRegistrationNo		nvarchar(30)	= null,
	@psOldIncorporated		nvarchar(254)	= null,
	@pnOldParentNameKey		int		= null,
	@pbIsRegistrationNoInUse	bit	 	= 0,
	@pbIsIncorporatedInUse		bit	 	= 0,
	@pbIsParentNameKeyInUse		bit	 	= 0
)
as
-- PROCEDURE:	naw_UpdateOrganisation
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Organisation if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 10 Apr 2006	AU	RFC3505	1	Procedure created
-- 10 May 2010	PA	RFC9097	2	Remove the updation of VATNO for the oragnisation as the TAXNO filed is used in NAME table

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update ORGANISATION
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
				NAMENO = @pnNameKey and
				"

	If @pbIsRegistrationNoInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REGISTRATIONNO = @psRegistrationNo"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"REGISTRATIONNO = @psOldRegistrationNo"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsIncorporatedInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INCORPORATED = @psIncorporated"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"INCORPORATED = @psOldIncorporated"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsParentNameKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PARENT = @pnParentNameKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PARENT = @pnOldParentNameKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@psRegistrationNo	nvarchar(30),
			@psIncorporated		nvarchar(254),
			@pnParentNameKey	int,
			@psOldRegistrationNo	nvarchar(30),
			@psOldIncorporated	nvarchar(254),
			@pnOldParentNameKey	int',
			@pnNameKey	 	= @pnNameKey,
			@psRegistrationNo	= @psRegistrationNo,
			@psIncorporated	 	= @psIncorporated,
			@pnParentNameKey	= @pnParentNameKey,
			@psOldRegistrationNo	= @psOldRegistrationNo,
			@psOldIncorporated	= @psOldIncorporated,
			@pnOldParentNameKey	= @pnOldParentNameKey


End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateOrganisation to public
GO