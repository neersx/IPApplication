-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteDocumentRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteDocumentRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteDocumentRequest.'
	Drop procedure [dbo].[ipw_DeleteDocumentRequest]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteDocumentRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteDocumentRequest
(
	@pnUserIdentityId		int,		 -- Mandatory
	@psCulture			nvarchar(10) 	 = null,
	@pbCalledFromCentura		bit		 = 0,
	@pnDocumentRequestKey		int,		 -- Mandatory
	@psOldRequestDescription	nvarchar(100)	 = null,
	@pnOldRecipient			int		 = null,
	@pnOldDocumentDefinitionKey	int	 = null,
	@pnOldFrequency			tinyint		 = null,
	@psOldPeriodTypeKey		nchar(1)	 = null,
	@pnOldExportFormatKey		int		 = null,
	@pdtOldNextGenerateDate		datetime	 = null,
	@pdtOldStopOn			datetime	 = null,
	@pdtOldLastGeneratedDate	datetime	 = null,
	@psOldBelongingToCode		nvarchar(2)	 = null,
	@pnOldCaseFilterKey		int		 = null,
	@ptOldCaseFilterXML		ntext		 = null, 
	@pbOldIsSuppressedWhenEmpty	bit		 = null,
	@pnOldDayOfMonth                tinyint          = null
)
as
-- PROCEDURE:	ipw_DeleteDocumentRequest
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete DocumentRequest if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 12 Mar 2007	PG	RFC3646	1	Procedure created
-- 03 Dec 2007	vql	RFC5909	2	Change RoleKey and DocumentDefKey from smallint to int.
-- 26 Feb 2008	SF	RFC6228	3	Case Filter to be deleted last.
-- 07 Mar 2008	SF	RFC6387	4	Activity Request needs to be deleted first
-- 14 Aug 2009  LP      RFC8348 5       Add new @pnOldDayOfMonth parameter

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sDeleteString		nvarchar(4000)
Declare @nRowCount		int

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount	= 1 -- anything not zero
if @nErrorCode = 0
Begin
	-- Assumption has been that this is confirmed by the end user in the UI
	Set @sDeleteString = "
		Delete from ACTIVITYREQUEST 
		Where	REQUESTID = @pnDocumentRequestKey"
	
	exec @nErrorCode = sp_executesql @sDeleteString,
		N'@pnDocumentRequestKey			int',
		@pnDocumentRequestKey = @pnDocumentRequestKey
End

If @nErrorCode = 0
Begin

	Set @sDeleteString = "
		Delete from DOCUMENTREQUEST 
		Where 	REQUESTID 		= @pnDocumentRequestKey
		and 	RECIPIENT 		= @pnOldRecipient
	 	and 	DESCRIPTION 		= @psOldRequestDescription
		and 	DOCUMENTDEFID 		= @pnOldDocumentDefinitionKey
		and 	FREQUENCY 		= @pnOldFrequency
		and 	PERIODTYPE 		= @psOldPeriodTypeKey
		and 	OUTPUTFORMATID 		= @pnOldExportFormatKey
		and 	NEXTGENERATE 		= @pdtOldNextGenerateDate
		and 	STOPON 			= @pdtOldStopOn
		and 	LASTGENERATED 		= @pdtOldLastGeneratedDate
		and 	BELONGINGTOCODE 	= @psOldBelongingToCode
		and 	CASEFILTERID 		= @pnOldCaseFilterKey
		and 	SUPPRESSWHENEMPTY 	= @pbOldIsSuppressedWhenEmpty
		and     DAYOFMONTH              = @pnOldDayOfMonth"
		
	
		exec @nErrorCode=sp_executesql @sDeleteString,
				N'@pnDocumentRequestKey			int,
				@pnOldRecipient				int,
				@psOldRequestDescription		nvarchar(100),
				@pnOldDocumentDefinitionKey		int,
				@pnOldFrequency				tinyint,
				@psOldPeriodTypeKey			nchar(1),
				@pnOldExportFormatKey			int,
				@pdtOldNextGenerateDate			datetime,
				@pdtOldStopOn				datetime,
				@pdtOldLastGeneratedDate		datetime,
				@psOldBelongingToCode			nvarchar(2),
				@pnOldCaseFilterKey			int,
				@pbOldIsSuppressedWhenEmpty		bit,
				@pnOldDayOfMonth                        tinyint',
				@pnDocumentRequestKey	 		= @pnDocumentRequestKey,
				@psOldRequestDescription	 	= @psOldRequestDescription,
				@pnOldRecipient	 			= @pnOldRecipient,
				@pnOldDocumentDefinitionKey	 	= @pnOldDocumentDefinitionKey,
				@pnOldFrequency	 			= @pnOldFrequency,
				@psOldPeriodTypeKey	 		= @psOldPeriodTypeKey,
				@pnOldExportFormatKey	 		= @pnOldExportFormatKey,
				@pdtOldNextGenerateDate	 		= @pdtOldNextGenerateDate,
				@pdtOldStopOn	 			= @pdtOldStopOn,
				@pdtOldLastGeneratedDate	 	= @pdtOldLastGeneratedDate,
				@psOldBelongingToCode	 		= @psOldBelongingToCode,
				@pnOldCaseFilterKey	 		= @pnOldCaseFilterKey,
				@pbOldIsSuppressedWhenEmpty	 	= @pbOldIsSuppressedWhenEmpty,
				@pnOldDayOfMonth                        = @pnOldDayOfMonth

	Set @nRowCount = @@RowCount
	
	--Maintain CaseFilterXML
	If @nErrorCode =0 and @nRowCount <> 0
	and @pnOldCaseFilterKey is not null
	Begin
		Set @sDeleteString = "Delete from QUERYFILTER
					Where FILTERID = @pnOldCaseFilterKey
					and dbo.fn_IsNtextEqual(@ptOldCaseFilterXML,XMLFILTERCRITERIA) = 1"

		exec @nErrorCode=sp_executesql @sDeleteString,
				N'@pnOldCaseFilterKey			int,
				@ptOldCaseFilterXML			ntext',
				@pnOldCaseFilterKey	 		= @pnOldCaseFilterKey,
				@ptOldCaseFilterXML	 		= @ptOldCaseFilterXML
	End

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteDocumentRequest to public
GO