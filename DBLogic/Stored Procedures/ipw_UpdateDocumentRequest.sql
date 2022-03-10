-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateDocumentRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateDocumentRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateDocumentRequest.'
	Drop procedure [dbo].[ipw_UpdateDocumentRequest]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateDocumentRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateDocumentRequest
(
	@pnUserIdentityId		int,		 -- Mandatory
	@psCulture			nvarchar(10) 	 = null,
	@pbCalledFromCentura		bit		 = 0,
	@pnDocumentRequestKey		int,		 -- Mandatory
	@psRequestDescription		nvarchar(100) 	 = null,
	@pnRecipient			int		 = null,
	@psOtherEmailAddress		nvarchar(50)	 = null,
	@pnOtherEmailKey		int		 = null,
	@pnDocumentDefinitionKey	int	 = null,
	@pnFrequency			tinyint		 = null,
	@psPeriodType			nchar(1)	 = null,
	@pnExportFormatKey		int		 = null,
	@pdtNextGenerateDate		datetime	 = null,
	@pdtStopOn			datetime	 = null,
	@pdtLastGeneratedDate		datetime	 = null,
	@psBelongingToCode		nvarchar(2)	 = null,
	@pnCaseFilterKey		int		 = null,
	@ptCaseFilterXML		ntext		 = null,
	@pdtEventsStartingFrom		datetime	= null,
	@pbIsSuppressedWhenEmpty	bit		 = null,
	@pnDayOfMonth                   tinyint          = null,
	@psOldRequestDescription	nvarchar(100)	 = null,
	@pnOldRecipient			int		 = null,
	@psOldOtherEmailAddress		nvarchar(50)	 = null,
	@pnOldDocumentDefinitionKey	int	 = null,
	@pnOldFrequency			tinyint		 = null,
	@psOldPeriodType		nchar(1)	 = null,
	@pnOldExportFormatKey		int		 = null,
	@pdtOldNextGenerateDate		datetime	 = null,
	@pdtOldStopOn			datetime	 = null,
	@pdtOldLastGeneratedDate	datetime	 = null,
	@psOldBelongingToCode		nvarchar(2)	 = null,
	@pnOldCaseFilterKey		int		 = null,
	@ptOldCaseFilterXML		ntext		 = null,
	@pdtOldEventsStartingFrom	datetime	= null,
	@pbOldIsSuppressedWhenEmpty	bit		 = null,
	@pnOldDayOfMonth                tinyint          = null
)
as
-- PROCEDURE:	ipw_UpdateDocumentRequest
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update DocumentRequest if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- Date		Who	Change	    Version	  Description
-- -----------	-------	    ------	-------	-----------------------------------------------
-- 12 Mar 2007	PG	RFC3646   1	    Procedure created
-- 30 May 2007	PG	RFC5468	  2	    Delete case filter if @ptCaseFilterXML is empty
-- 03 Dec 2007	vql	RFC5909	  3	    Change RoleKey and DocumentDefId from smallint to int.



-- 14 Aug 2009  LP      RFC8348 4       Add new DayOfMonth parameter to update new DAYOFMONTH column
-- 15 Jan 2010	LP	RFC8519	5	Pass @pnDocumentRequestKey as @pnDocumentRequestKey when updating document request email.
-- 19 Jan 2010	DV	RFC100126 6		Remove @pnOldDocumentRequestKey as a parameter to the call of ipw_UpdateDocumentRequestEmail 
SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nDocumentEmailKey 	int
Declare @nRowCount		int


-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount 	= 1 --Anything not zero

If @nErrorCode = 0
Begin


	--Maintain CaseFilterXML
	If @ptCaseFilterXML is null and @ptOldCaseFilterXML is not null
	Begin
		Set @pnCaseFilterKey =null
	End
	Else If dbo.fn_IsNtextEqual(@ptOldCaseFilterXML,@ptCaseFilterXML) = 0
	Begin
		Exec @nErrorCode = dbo.qr_MaintainFilter
					@pnFilterKey = @pnCaseFilterKey output,
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture	=   @psCulture,
					@pnContextKey	= 8,
					@pnAdoptFromQueryKey	=null,
					@ptXMLFilterCriteria=@ptCaseFilterXML,
					@ptOldXMLFilterCriteria = @ptOldCaseFilterXML
		Set @nRowCount = @@RowCount
	End

	print @pnCaseFilterKey
	-- Maintain Other email address
	If @nErrorCode = 0 and @nRowCount <> 0
	Begin
		If @psOldOtherEmailAddress is null and @psOtherEmailAddress is not null
		Begin
			Exec @nErrorCode = dbo.ipw_InsertDocumentRequestEmail
						@pnUserIdentityId		= @pnUserIdentityId,
						@psCulture			= @psCulture,
						@pbCalledFromCentura		= @pbCalledFromCentura,
						@pnDocumentRequestEmailKey 	= @nDocumentEmailKey output,
						@pnDocumentRequestKey		= @pnDocumentRequestKey,
						@pbIsMain			= 1,
						@psEmail			= @psOtherEmailAddress
			Set @nRowCount = @@RowCount
		End
		Else If @psOldOtherEmailAddress is not null and @psOtherEmailAddress is null
		Begin
		  	Exec @nErrorCode = dbo.ipw_DeleteDocumentRequestEmail
						@pnUserIdentityId		= @pnUserIdentityId,
						@psCulture			= @psCulture,
						@pbCalledFromCentura		= @pbCalledFromCentura,
						@pnDocumentRequestEmailKey 	= @pnOtherEmailKey,
						@pnOldDocumentRequestKey	= @pnDocumentRequestKey,
						@pbOldIsMain			= 1,
						@psOldEmail			= @psOldOtherEmailAddress
			Set @nRowCount = @@RowCount
		End
		Else If @psOldOtherEmailAddress is not null and @psOtherEmailAddress is not null and @psOldOtherEmailAddress <>@psOtherEmailAddress
		Begin
		  	Exec @nErrorCode = dbo.ipw_UpdateDocumentRequestEmail
						@pnUserIdentityId		= @pnUserIdentityId,
						@psCulture			= @psCulture,
						@pbCalledFromCentura		= @pbCalledFromCentura,
						@pnDocumentRequestEmailKey 	= @pnOtherEmailKey,
						@pbIsMain			= 1,
						@psEmail			= @psOtherEmailAddress,
						@pnDocumentRequestKey		= @pnDocumentRequestKey,
						@pbOldIsMain			= 1,
						@psOldEmail			= @psOldOtherEmailAddress
			Set @nRowCount = @@RowCount
		End
	End

	If @nErrorCode = 0 and @nRowCount <> 0
	Begin
		Set @sSQLString = "
		
		Update DOCUMENTREQUEST 
		Set 	RECIPIENT 	= @pnRecipient,
			DESCRIPTION 	= @psRequestDescription,
			DOCUMENTDEFID 	= @pnDocumentDefinitionKey,
			FREQUENCY 		= @pnFrequency,
			PERIODTYPE 		= @psPeriodType,
			OUTPUTFORMATID 	= @pnExportFormatKey,
			NEXTGENERATE 	= @pdtNextGenerateDate,
			STOPON 			= @pdtStopOn,
			LASTGENERATED 	= @pdtLastGeneratedDate,
			BELONGINGTOCODE = @psBelongingToCode,
			CASEFILTERID 	= @pnCaseFilterKey,
			EVENTSTART		= @pdtEventsStartingFrom,
			SUPPRESSWHENEMPTY = @pbIsSuppressedWhenEmpty,
			DAYOFMONTH      = @pnDayOfMonth
		Where 
	
		REQUESTID 		= @pnDocumentRequestKey
		and RECIPIENT 		= @pnOldRecipient
		and DESCRIPTION 	= @psOldRequestDescription
		and DOCUMENTDEFID 	= @pnOldDocumentDefinitionKey
		and FREQUENCY 		= @pnOldFrequency
		and PERIODTYPE 		= @psOldPeriodType
		and OUTPUTFORMATID 	= @pnOldExportFormatKey
		and NEXTGENERATE 	= @pdtOldNextGenerateDate
		and STOPON 			= @pdtOldStopOn
		and LASTGENERATED 	= @pdtOldLastGeneratedDate
		and BELONGINGTOCODE = @psOldBelongingToCode
		and CASEFILTERID 	= @pnOldCaseFilterKey
		and EVENTSTART		= @pdtOldEventsStartingFrom
		and SUPPRESSWHENEMPTY 	= @pbOldIsSuppressedWhenEmpty
		and DAYOFMONTH          = @pnOldDayOfMonth"
	
		exec @nErrorCode=sp_executesql @sSQLString,
			    N'@pnDocumentRequestKey		int,
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
				@pnDayOfMonth                   tinyint,
				@psOldRequestDescription	nvarchar(100),
				@pnOldRecipient			int,
				@pnOldDocumentDefinitionKey	int,
				@pnOldFrequency			tinyint,
				@psOldPeriodType		nchar(1),
				@pnOldExportFormatKey		int,
				@pdtOldNextGenerateDate		datetime,
				@pdtOldStopOn			datetime,
				@pdtOldLastGeneratedDate	datetime,
				@psOldBelongingToCode		nvarchar(2),
				@pnOldCaseFilterKey		int,
				@pdtOldEventsStartingFrom	datetime,
				@pbOldIsSuppressedWhenEmpty	bit,
				@pnOldDayOfMonth                tinyint',
				@pnDocumentRequestKey	 	= @pnDocumentRequestKey,
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
				@pnCaseFilterKey	 	= @pnCaseFilterKey,
				@pdtEventsStartingFrom		= @pdtEventsStartingFrom,
				@pbIsSuppressedWhenEmpty	= @pbIsSuppressedWhenEmpty,
				@pnDayOfMonth                   = @pnDayOfMonth,
				@psOldRequestDescription	= @psOldRequestDescription,
				@pnOldRecipient	 		= @pnOldRecipient,
				@pnOldDocumentDefinitionKey	= @pnOldDocumentDefinitionKey,
				@pnOldFrequency	 		= @pnOldFrequency,
				@psOldPeriodType	 	= @psOldPeriodType,
				@pnOldExportFormatKey	 	= @pnOldExportFormatKey,
				@pdtOldNextGenerateDate	 	= @pdtOldNextGenerateDate,
				@pdtOldStopOn	 		= @pdtOldStopOn,
				@pdtOldLastGeneratedDate	= @pdtOldLastGeneratedDate,
				@psOldBelongingToCode	 	= @psOldBelongingToCode,
				@pnOldCaseFilterKey	 	= @pnOldCaseFilterKey,
				@pdtOldEventsStartingFrom	= @pdtOldEventsStartingFrom,
				@pbOldIsSuppressedWhenEmpty	= @pbOldIsSuppressedWhenEmpty,
				@pnOldDayOfMonth                = @pnOldDayOfMonth

	End
	--Delete QueryFilter if XML is empty
	If @nErrorCode = 0 and (@ptCaseFilterXML is null and @ptOldCaseFilterXML is not null)
	Begin	
		Set @sSQLString = "Delete from QUERYFILTER
					Where FILTERID = @pnOldCaseFilterKey
					and dbo.fn_IsNtextEqual(@ptOldCaseFilterXML,XMLFILTERCRITERIA) = 1"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnOldCaseFilterKey			int,
				@ptOldCaseFilterXML			ntext',
				@pnOldCaseFilterKey	 		= @pnOldCaseFilterKey,
				@ptOldCaseFilterXML	 		= @ptOldCaseFilterXML
	End


End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateDocumentRequest to public
GO