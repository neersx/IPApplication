-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteDesignElement									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteDesignElement]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteDesignElement.'
	Drop procedure [dbo].[csw_DeleteDesignElement]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteDesignElement...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_DeleteDesignElement
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,	-- Mandatory
	@pnSequence		int,	-- Mandatory
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
-- PROCEDURE:	csw_DeleteDesignElement
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete DesignElement if the underlying values are as expected.

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
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from DESIGNELEMENT
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		CASEID = @pnCaseKey and 
		SEQUENCE = @pnSequence
"

	If @pbIsFirmElementIDInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"FIRMELEMENTID = @psOldFirmElementID"
	End

	If @pbIsDescriptionInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ELEMENTDESC = @psOldDescription"
	End

	If @pbIsClientElementReferenceInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CLIENTELEMENTID = @psOldClientElementReference"
	End

	If @pbIsToRenewInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"RENEWFLAG = @pbOldToRenew"
	End

	If @pbIsTypefaceInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"TYPEFACE = @pnOldTypeface"
	End

	If @pbIsOfficialElementIDInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"OFFICIALELEMENTID = @psOldOfficialElementID"
	End

	If @pbIsRegistrationNumberInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"REGISTRATIONNO = @psOldRegistrationNumber"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
			@pnCaseKey		int,
			@pnSequence		int,
			@psOldFirmElementID		nvarchar(20),
			@psOldDescription		nvarchar(254),
			@psOldClientElementReference		nvarchar(20),
			@pbOldToRenew		bit,
			@pnOldTypeface		int,
			@psOldOfficialElementID		nvarchar(20),
			@psOldRegistrationNumber		nvarchar(36)',
			@pnCaseKey	 = @pnCaseKey,
			@pnSequence	 = @pnSequence,
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

Grant execute on dbo.csw_DeleteDesignElement to public
GO
