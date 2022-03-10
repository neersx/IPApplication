
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertIndividual									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertIndividual]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertIndividual.'
	Drop procedure [dbo].[naw_InsertIndividual]
End
Print '**** Creating Stored Procedure dbo.naw_InsertIndividual...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertIndividual
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory.
	@psGenderCode			nchar(1)	= null,
	@psFormalSalutation		nvarchar(50)	= null,
	@psInformalSalutation		nvarchar(50)	= null,
	@pbIsGenderCodeInUse		bit	 	= 0,
	@pbIsFormalSalutationInUse	bit	 	= 0,
	@pbIsInformalSalutationInUse	bit	 	= 0
)
as
-- PROCEDURE:	naw_InsertIndividual
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Individual.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 31 Mar 2006	IB	RFC3506	1	Procedure created
-- 18 Apr 2006	IB	RFC3506 2	Saved the file as Unicode and then as ANSI  
--					to get rid of invalid characters.
-- 09 May 2008	Dw	SQA16326 3	Extended salutation columns


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString	nvarchar(4000)
Declare @sComma		nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into INDIVIDUAL
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
			NAMENO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
			@pnNameKey
			"

	If @pbIsGenderCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SEX"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psGenderCode"
		Set @sComma = ","
	End

	If @pbIsFormalSalutationInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FORMALSALUTATION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psFormalSalutation"
		Set @sComma = ","
	End

	If @pbIsInformalSalutationInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CASUALSALUTATION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psInformalSalutation"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnNameKey		int,
				@psGenderCode		nchar(1),
				@psFormalSalutation	nvarchar(50),
				@psInformalSalutation	nvarchar(50)',
				@pnNameKey	 	= @pnNameKey,
				@psGenderCode	 	= @psGenderCode,
				@psFormalSalutation	= @psFormalSalutation,
				@psInformalSalutation	= @psInformalSalutation

End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertIndividual to public
GO