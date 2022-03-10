-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertDesignElement									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertDesignElement]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertDesignElement.'
	Drop procedure [dbo].[csw_InsertDesignElement]
End
Print '**** Creating Stored Procedure dbo.csw_InsertDesignElement...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertDesignElement
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,		-- Mandatory.
	@pnSequence		int		= null		output,
	@psFirmElementID	nvarchar(20)		 = null,
	@psDescription	nvarchar(254)		 = null,
	@psClientElementReference	nvarchar(20)		 = null,
	@pbToRenew	bit		 = null,
	@pnTypeface	int		 = null,
	@psOfficialElementID	nvarchar(20)		 = null,
	@psRegistrationNumber	nvarchar(36)		 = null,
	@pbIsFirmElementIDInUse		bit	 = 0,
	@pbIsDescriptionInUse		bit	 = 0,
	@pbIsClientElementReferenceInUse		bit	 = 0,
	@pbIsToRenewInUse		bit	 = 0,
	@pbIsTypefaceInUse		bit	 = 0,
	@pbIsOfficialElementIDInUse		bit	 = 0,
	@pbIsRegistrationNumberInUse		bit	 = 0
)
as
-- PROCEDURE:	csw_InsertDesignElement
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert DesignElement.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 13 Jul 2006	LP	RFC4143	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
declare @sSQLString2		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("


If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into DESIGNELEMENT
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
						CASEID,SEQUENCE
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
						@pnCaseKey,@pnSequence
			"

	If @pbIsFirmElementIDInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FIRMELEMENTID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psFirmElementID"
		Set @sComma = ","
	End

	If @pbIsDescriptionInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ELEMENTDESC"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psDescription"
		Set @sComma = ","
	End

	If @pbIsClientElementReferenceInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CLIENTELEMENTID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psClientElementReference"
		Set @sComma = ","
	End

	If @pbIsToRenewInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"RENEWFLAG"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbToRenew"
		Set @sComma = ","
	End

	If @pbIsTypefaceInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TYPEFACE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnTypeface"
		Set @sComma = ","
	End

	If @pbIsOfficialElementIDInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"OFFICIALELEMENTID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psOfficialElementID"
		Set @sComma = ","
	End

	If @pbIsRegistrationNumberInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"REGISTRATIONNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psRegistrationNumber"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	-- Get the next sequence no
	If @nErrorCode = 0
	Begin
		Set @sSQLString2 = "
		Select @pnSequence = isnull(MAX(SEQUENCE)+1, 0)
		from DESIGNELEMENT
		where CASEID = @pnCaseKey"
	
		exec @nErrorCode=sp_executesql @sSQLString2,	
					      N'@pnSequence	int		output,
						@pnCaseKey	int',
						@pnSequence	= @pnSequence	output,
						@pnCaseKey	= @pnCaseKey
	End

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnCaseKey		int,
			@pnSequence		int,
			@psFirmElementID		nvarchar(20),
			@psDescription		nvarchar(254),
			@psClientElementReference		nvarchar(20),
			@pbToRenew		bit,
			@pnTypeface		int,
			@psOfficialElementID		nvarchar(20),
			@psRegistrationNumber		nvarchar(36)',
			@pnCaseKey	 = @pnCaseKey,
			@pnSequence	 = @pnSequence,
			@psFirmElementID	 = @psFirmElementID,
			@psDescription	 = @psDescription,
			@psClientElementReference	 = @psClientElementReference,
			@pbToRenew	 = @pbToRenew,
			@pnTypeface	 = @pnTypeface,
			@psOfficialElementID	 = @psOfficialElementID,
			@psRegistrationNumber	 = @psRegistrationNumber

End

-- Publish Sequence
If @nErrorCode = 0
Begin
	Select @pnSequence as 'Sequence'
End


Return @nErrorCode
GO

Grant execute on dbo.csw_InsertDesignElement to public
GO