-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_SubmitDocumentRequest
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_SubmitDocumentRequest  ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_SubmitDocumentRequest  .'
	Drop procedure [dbo].[ipw_SubmitDocumentRequest  ]
End
Print '**** Creating Stored Procedure dbo.ipw_SubmitDocumentRequest  ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_SubmitDocumentRequest  
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnDocumentRequestKey	int		--Mandatory
)
as
-- PROCEDURE:	ipw_SubmitDocumentRequest  
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Submits the request as new ad hoc request with Frequency=Once and NextGenerate = StopOn= today
--		Adds the new request to the production queue immediately

-- MODIFICATIONS :
-- Date		Who	Change	    Version	Description
-- -----------	-------	------	    -------	----------------------------------------------- 
-- 03 Apr 2007	PG	RFC3646	    1		Procedure created
-- 24 May 2007	PG	RFC3646	    2		Insert a separate QueryFilter for new request
-- 14 Jul 2008	vql	SQA16490    3		SCOPE_IDENT( ) to retrieve an identity value cannot be used with tables that have an INSTEAD OF trigger present.
-- 06 Jan 2011  PA      RFC9972     4           Added a check if FREQUENCY is null then DOCUMENTREQUEST will not be created.
-- 12 Jan 20111 PA      RFC9972     5           Added a condition to show the generated Once-off request in Document Generator

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @dtNextGenerate	datetime
Declare @sSQLString 		nvarchar(4000)
Declare @nDocumentRequestKey 	int
Declare @nOldFilterKey		int
Declare @nContextKey		int
Declare @nFilterKey		int

-- Initialise variables
Set @nErrorCode = 0
Set @nContextKey = 8 -- Query Context for Document Request Case Filter

If @nErrorCode = 0
Begin

	--Get current date
	exec @nErrorCode = dbo.ip_GetCurrentDate
			@pdtCurrentDate		= @dtNextGenerate	OUTPUT,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psDateType		= 'A', 	-- 'A'- Application Date; 'U'  User Date
			@pbIncludeTime		= 0

	-- Insert new query filter
	If @nErrorCode = 0
	Begin
		Set @nOldFilterKey = (Select CASEFILTERID From DOCUMENTREQUEST Where REQUESTID=@pnDocumentRequestKey)
		Set @nErrorCode = @@Error 
	End

	If @nErrorCode = 0 and @nOldFilterKey is not null
	Begin 
		Set @sSQLString = " 
		Insert	QUERYFILTER
			(PROCEDURENAME, XMLFILTERCRITERIA)
		Select	QC.PROCEDURENAME, QF.XMLFILTERCRITERIA
		From	QUERYCONTEXT QC join QUERYFILTER QF on (QF.FILTERID=@nOldFilterKey)
		Where	QC.CONTEXTID = @nContextKey
	
		Set @nFilterKey = IDENT_CURRENT('QUERYFILTER')"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nFilterKey		int		OUTPUT,
						  @nOldFilterKey	int,
						  @nContextKey		int',
						  @nFilterKey		= @nFilterKey 	OUTPUT,
						  @nOldFilterKey	= @nOldFilterKey,
						  @nContextKey		= @nContextKey
	
	End
        IF Exists (Select * From DOCUMENTREQUEST Where REQUESTID=@pnDocumentRequestKey and FREQUENCY is not NULL)
        BEGIN
	        --Insert document request
	        If @nErrorCode =0
	        Begin
		        Set @sSQLString = 'Insert into DOCUMENTREQUEST 
					        (RECIPIENT,
					        DESCRIPTION,
					        DOCUMENTDEFID,
					        FREQUENCY,
					        PERIODTYPE,
					        OUTPUTFORMATID,
					        NEXTGENERATE,
					        STOPON,
					        BELONGINGTOCODE,
					        CASEFILTERID,
					        EVENTSTART,
					        SUPPRESSWHENEMPTY)
			        Select 		RECIPIENT,
					        DESCRIPTION,
					        DOCUMENTDEFID,
					        null,
					        null,
					        OUTPUTFORMATID,
					        @dtNextGenerate,
					        null,
					        BELONGINGTOCODE,
					        @nFilterKey,
					        EVENTSTART,
					        SUPPRESSWHENEMPTY
			        From DOCUMENTREQUEST 
			        Where REQUESTID=@pnDocumentRequestKey

			        Set @nDocumentRequestKey = SCOPE_IDENTITY()'
        	
        	
		        exec @nErrorCode=sp_executesql @sSQLString,
				              N'@pnDocumentRequestKey	int,
					        @nDocumentRequestKey    int output,
					        @dtNextGenerate		datetime,
					        @nFilterKey		int',
					        @pnDocumentRequestKey 	= @pnDocumentRequestKey,
					        @nDocumentRequestKey	= @nDocumentRequestKey output,
					        @dtNextGenerate		= @dtNextGenerate,
					        @nFilterKey		= @nFilterKey
	        End

	        --Insert document request email
	        If @nErrorCode = 0 
	        Begin
		        Set @sSQLString = 'Insert into DOCUMENTREQUESTEMAIL
					        (REQUESTID,
					        ISMAIN,
					        EMAIL)
				           Select @nDocumentRequestKey, ISMAIN,EMAIL
				           From DOCUMENTREQUESTEMAIL
				           Where REQUESTID=@pnDocumentRequestKey'
        	
        	
		        exec @nErrorCode=sp_executesql @sSQLString,
				              N'@pnDocumentRequestKey	int,
					        @nDocumentRequestKey	int',
					        @pnDocumentRequestKey 	= @pnDocumentRequestKey,
					        @nDocumentRequestKey	= @nDocumentRequestKey
        	
	        End
        	
	        --Insert Document Event group
	        If @nErrorCode = 0
	        Begin
		        Set @sSQLString = 'Insert into DOCUMENTEVENTGROUP
					        (REQUESTID,
					        EVENTGROUP)
				           Select @nDocumentRequestKey, EVENTGROUP
				           From DOCUMENTEVENTGROUP
				           Where REQUESTID=@pnDocumentRequestKey'
        	
		        exec @nErrorCode=sp_executesql @sSQLString,
				              N'@pnDocumentRequestKey	int,
					        @nDocumentRequestKey	int',
					        @pnDocumentRequestKey 	= @pnDocumentRequestKey,
					        @nDocumentRequestKey	= @nDocumentRequestKey
        	
	        End
	        --Insert Acting As
	        If @nErrorCode = 0
	        Begin
		        Set @sSQLString = 'Insert into DOCUMENTREQUESTACTINGAS
					        (REQUESTID,
					        NAMETYPE)
				           Select @nDocumentRequestKey, NAMETYPE
				           From DOCUMENTREQUESTACTINGAS
				           Where REQUESTID=@pnDocumentRequestKey'
        	
        	
		        exec @nErrorCode=sp_executesql @sSQLString,
				              N'@pnDocumentRequestKey	int,
					        @nDocumentRequestKey	int',
					        @pnDocumentRequestKey 	= @pnDocumentRequestKey,
					        @nDocumentRequestKey	= @nDocumentRequestKey
        	
	        End
        End
        Else
        Begin
                set @nDocumentRequestKey = @pnDocumentRequestKey
        End
	--Add to production queue
	If @nErrorCode = 0
	Begin
		Exec @nErrorCode = dbo.cs_GenerateActivityRequest
					@pnUserIdentityId		= @pnUserIdentityId,
					@pnDocumentRequestKey		= @nDocumentRequestKey
	End

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_SubmitDocumentRequest   to public
GO
