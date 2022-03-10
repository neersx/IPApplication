
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteIndividual									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteIndividual]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteIndividual.'
	Drop procedure [dbo].[naw_DeleteIndividual]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteIndividual...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteIndividual
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@psOldGenderCode		nchar(1)	= null,
	@psOldFormalSalutation		nvarchar(50)	= null,
	@psOldInformalSalutation	nvarchar(50)	= null,
	@pbIsGenderCodeInUse		bit	 	= 0,
	@pbIsFormalSalutationInUse	bit	 	= 0,
	@pbIsInformalSalutationInUse	bit	 	= 0
)
as
-- PROCEDURE:	naw_DeleteIndividual
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Individual if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 31 Mar 2006	IB	RFC3506	1	Procedure created
-- 12 Apr 2006	IB	RFC3506	2	Fixed construction of the @sDeleteString variable.
-- 18 Apr 2006	IB	RFC3506 3	Saved the file as Unicode and then as ANSI  
--					to get rid of invalid characters.
-- 09 May 2008	Dw	SQA16326 4	Extended salutation columns

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
	Set @sDeleteString = "Delete from INDIVIDUAL
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		NAMENO = @pnNameKey"

	Set @sAnd = " and "

	If @pbIsGenderCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"SEX = @psOldGenderCode"
	End

	If @pbIsFormalSalutationInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"FORMALSALUTATION = @psOldFormalSalutation"
	End

	If @pbIsInformalSalutationInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CASUALSALUTATION = @psOldInformalSalutation"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
			@pnNameKey			int,
			@psOldGenderCode		nchar(1),
			@psOldFormalSalutation		nvarchar(50),
			@psOldInformalSalutation	nvarchar(50)',
			@pnNameKey	 		= @pnNameKey,
			@psOldGenderCode	 	= @psOldGenderCode,
			@psOldFormalSalutation	 	= @psOldFormalSalutation,
			@psOldInformalSalutation	= @psOldInformalSalutation

End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteIndividual to public
GO

