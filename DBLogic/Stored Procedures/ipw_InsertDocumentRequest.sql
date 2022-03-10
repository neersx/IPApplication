-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertDocumentRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertDocumentRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertDocumentRequest.'
	Drop procedure [dbo].[ipw_InsertDocumentRequest]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertDocumentRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertDocumentRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDocumentRequestKey		int		= null output,
	@psRequestDescription		nvarchar(100)	= null,
	@pnRecipient			int		= null,
	@psOtherEmailAddress		nvarchar(50)	= null,
	@pnDocumentDefinitionKey	int	= null,
	@pnFrequency			tinyint	 	= null,
	@psPeriodType			nchar(1) 	= null,
	@pnExportFormatKey		int		= null,
	@pdtNextGenerateDate		datetime 	= null,
	@pdtStopOn			datetime 	= null,
	@pdtLastGeneratedDate		datetime	= null,
	@pdtEventsStartingFrom	datetime	= null,
	@psBelongingToCode		nvarchar(2)	= null,
	@ptCaseFilterXML		ntext		= null,
	@pbIsSuppressedWhenEmpty	bit		= null,
	@pnDayOfMonth                   tinyint         = null
)
as
-- PROCEDURE:	ipw_InsertDocumentRequest
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert DocumentRequest.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 12 Mar 2007	PG	RFC3646	1	Procedure created
-- 26 Apr 2007	LP	RFC3646	2	Add @pdtEventsStartingFrom parameter

  -- 03 Dec 2007	vql		RFC5909	3		Change RoleKey and DocumentDefId from smallint to int.
 --14 Aug 2009  LP      RFC8348 4       Add @pnDayOfMonth parameter

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nFilterKey int
Declare @nDocumentEmailKey int

-- Initialise variables
Set @nErrorCode = 0
Set @nFilterKey =null
If @nErrorCode = 0
Begin

	--insert CaseFilterXML
	
	If @ptCaseFilterXML is not  null
	Begin
		Exec @nErrorCode = dbo.qr_MaintainFilter
					@pnFilterKey 		= @nFilterKey output,
					@pnUserIdentityId 	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@pnContextKey		= 8,
					@pnAdoptFromQueryKey	= null,
					@ptXMLFilterCriteria	= @ptCaseFilterXML,
					@ptOldXMLFilterCriteria = null
	End
	--Insert document request
	If @nErrorCode = 0
	Begin
		Set @sSQLString ="Insert into DOCUMENTREQUEST(
			DESCRIPTION,
			RECIPIENT,
			DOCUMENTDEFID,
			FREQUENCY,
			PERIODTYPE,
			OUTPUTFORMATID,
			NEXTGENERATE,
			STOPON,
			LASTGENERATED,
			BELONGINGTOCODE,
			CASEFILTERID,
			EVENTSTART,
			SUPPRESSWHENEMPTY,
			DAYOFMONTH
			)
			values (
			@psRequestDescription,
			@pnRecipient,
			@pnDocumentDefinitionKey,
			@pnFrequency,
			@psPeriodType,
			@pnExportFormatKey,
			@pdtNextGenerateDate,
			@pdtStopOn,
			@pdtLastGeneratedDate,
			@psBelongingToCode,
			@pnCaseFilterKey,
			@pdtEventsStartingFrom,
			@pbIsSuppressedWhenEmpty,
			@pnDayOfMonth
			)
			Set @pnDocumentRequestKey = SCOPE_IDENTITY()"
			
			exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnDocumentRequestKey		int output,
				@psRequestDescription		nvarchar(100),
				@pnRecipient			int,
				@pnDocumentDefinitionKey	int,
				@pnFrequency			tinyint,
				@psPeriodType			nchar(1),
				@pnExportFormatKey		int,
				@pdtNextGenerateDate		datetime,
				@pdtStopOn			datetime,
				@pdtLastGeneratedDate		datetime,
				@psBelongingToCode		nvarchar(2),
				@pnCaseFilterKey		int,
				@pdtEventsStartingFrom	datetime,
				@pbIsSuppressedWhenEmpty	bit,
				@pnDayOfMonth                   tinyint',
				@pnDocumentRequestKey	 	= @pnDocumentRequestKey output,
				@psRequestDescription	 	= @psRequestDescription,
				@pnRecipient	 		= @pnRecipient,
				@pnDocumentDefinitionKey	= @pnDocumentDefinitionKey,
				@pnFrequency	 		= @pnFrequency,
				@psPeriodType	 		= @psPeriodType,
				@pnExportFormatKey	 	= @pnExportFormatKey,
				@pdtNextGenerateDate	 	= @pdtNextGenerateDate,
				@pdtStopOn	 		= @pdtStopOn,
				@pdtLastGeneratedDate	 	= @pdtLastGeneratedDate,
				@psBelongingToCode	 	= @psBelongingToCode,
				@pnCaseFilterKey	 	= @nFilterKey,
				@pdtEventsStartingFrom	= @pdtEventsStartingFrom,
				@pbIsSuppressedWhenEmpty	= @pbIsSuppressedWhenEmpty,
				@pnDayOfMonth                   = @pnDayOfMonth	
	End
	-- Publish the generated key to update the data adapter
	Select @pnDocumentRequestKey as DocumentRequestKey

	--Insert email address
	If @nErrorCode = 0 and @psOtherEmailAddress is not null
	Begin
		Exec @nErrorCode = dbo.ipw_InsertDocumentRequestEmail
					@pnUserIdentityId		= @pnUserIdentityId,
					@psCulture			= @psCulture,
					@pbCalledFromCentura		= @pbCalledFromCentura,
					@pnDocumentRequestEmailKey 	= @nDocumentEmailKey output,
					@pnDocumentRequestKey		= @pnDocumentRequestKey,
					@pbIsMain			= 1,
					@psEmail			= @psOtherEmailAddress
	End

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertDocumentRequest to public
GO