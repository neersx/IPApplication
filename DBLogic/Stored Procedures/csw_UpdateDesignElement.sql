-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateDesignElement									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateDesignElement]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateDesignElement.'
	Drop procedure [dbo].[csw_UpdateDesignElement]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateDesignElement...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateDesignElement
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,	-- Mandatory
	@pnSequence		int,	-- Mandatory
	@psFirmElementID	nvarchar(20)		 = null,
	@psDescription	nvarchar(254)		 = null,
	@psClientElementReference	nvarchar(20)		 = null,
	@pbToRenew	bit		 = null,
	@pnTypeface	int		 = null,
	@psOfficialElementID	nvarchar(20)		 = null,
	@psRegistrationNumber	nvarchar(36)		 = null,
	@psOldFirmElementID	nvarchar(20)		 = null,
	@psOldDescription	nvarchar(254)		 = null,
	@psOldClientElementReference	nvarchar(20)		 = null,
	@pbOldToRenew	bit		 = null,
	@pnOldTypeface	int		 = null,
	@psOldOfficialElementID	nvarchar(20)		 = null,
	@psOldRegistrationNumber	nvarchar(36)		 = null,
	@pbIsFirmElementIDInUse		bit	 = 0,
	@pbIsDescriptionInUse		bit	 = 0,
	@pbIsClientElementReferenceInUse		bit	 = 0,
	@pbIsToRenewInUse		bit	 = 0,
	@pbIsTypefaceInUse		bit	 = 0,
	@pbIsOfficialElementIDInUse		bit	 = 0,
	@pbIsRegistrationNumberInUse		bit	 = 0
)
as
-- PROCEDURE:	csw_UpdateDesignElement
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update DesignElement if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 13 Jul 2006	LP	RFC4143	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update DESIGNELEMENT
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		CASEID = @pnCaseKey and
		SEQUENCE = @pnSequence
"

	If @pbIsFirmElementIDInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FIRMELEMENTID = @psFirmElementID"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FIRMELEMENTID = @psOldFirmElementID"
		Set @sComma = ","
	End

	If @pbIsDescriptionInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ELEMENTDESC = @psDescription"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ELEMENTDESC = @psOldDescription"
		Set @sComma = ","
	End

	If @pbIsClientElementReferenceInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CLIENTELEMENTID = @psClientElementReference"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CLIENTELEMENTID = @psOldClientElementReference"
		Set @sComma = ","
	End

	If @pbIsToRenewInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"RENEWFLAG = @pbToRenew"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"RENEWFLAG = @pbOldToRenew"
		Set @sComma = ","
	End

	If @pbIsTypefaceInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TYPEFACE = @pnTypeface"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TYPEFACE = @pnOldTypeface"
		Set @sComma = ","
	End

	If @pbIsOfficialElementIDInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"OFFICIALELEMENTID = @psOfficialElementID"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"OFFICIALELEMENTID = @psOldOfficialElementID"
		Set @sComma = ","
	End

	If @pbIsRegistrationNumberInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REGISTRATIONNO = @psRegistrationNumber"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"REGISTRATIONNO = @psOldRegistrationNumber"
		Set @sComma = ","
	End

	Set @sSQLString = @sUpdateString + @sWhereString

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
			@psRegistrationNumber		nvarchar(36),
			@psOldFirmElementID		nvarchar(20),
			@psOldDescription		nvarchar(254),
			@psOldClientElementReference		nvarchar(20),
			@pbOldToRenew		bit,
			@pnOldTypeface		int,
			@psOldOfficialElementID		nvarchar(20),
			@psOldRegistrationNumber		nvarchar(36)',
			@pnCaseKey	 = @pnCaseKey,
			@pnSequence	 = @pnSequence,
			@psFirmElementID	 = @psFirmElementID,
			@psDescription	 = @psDescription,
			@psClientElementReference	 = @psClientElementReference,
			@pbToRenew	 = @pbToRenew,
			@pnTypeface	 = @pnTypeface,
			@psOfficialElementID	 = @psOfficialElementID,
			@psRegistrationNumber	 = @psRegistrationNumber,
			@psOldFirmElementID	 = @psOldFirmElementID,
			@psOldDescription	 = @psOldDescription,
			@psOldClientElementReference	 = @psOldClientElementReference,
			@pbOldToRenew	 = @pbOldToRenew,
			@pnOldTypeface	 = @pnOldTypeface,
			@psOldOfficialElementID	 = @psOldOfficialElementID,
			@psOldRegistrationNumber	 = @psOldRegistrationNumber


End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateDesignElement to public
GO