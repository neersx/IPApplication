-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteCaseText									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteCaseText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteCaseText.'
	Drop procedure [dbo].[csw_DeleteCaseText]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteCaseText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_DeleteCaseText
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,	-- Mandatory
	@psTextTypeCode		nvarchar(2),	-- Mandatory
	@pnTextSubSequence	smallint,	-- Mandatory
	@psClass		        nvarchar(11)	= null,
	@pdtLogDateTimeStamp            datetime        = null	
)
as
-- PROCEDURE:	csw_DeleteCaseText
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete CaseText if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 07 Nov 2005		RFC3201	1	Procedure created
-- 11 Jan 1006	TM	RFC3201	2	Add new optional @pnRowCount output parameter.
-- 10 Sep 2009  PA	RFC8043	3	To delete the FIRSTUSE and FIRSTUSEINCOMMERCE fields.
-- 28 Oct 2010	ASH	RFC9788 	4       Maintain Title in foreign languages.
-- 17 Feb 2012  MS      R11154  		5       Remove Inuse and OldData parameters
-- 18 May 2012  ASH	R11999  	6	Change the logic to determine the value of @bLongFlag
-- 20 Jul 2012  ASH	R12112  	7	Delete from CLASSFIRSTUSE if there is no Case text in Class.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)
Declare @bLongFlag		bit
Declare @sShortOldText		nvarchar(254)
Declare @sLookupCulture		nvarchar(10)
Declare @nTitleTID		int
Declare @nDescriptionTID	int

-- Initialise variables
Set @nErrorCode = 0
	Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from CASETEXT
			where 
		        CASEID = @pnCaseKey and
		        TEXTTYPE = @psTextTypeCode and
		        TEXTNO = @pnTextSubSequence and
		        (LOGDATETIMESTAMP = @pdtLogDateTimeStamp or (LOGDATETIMESTAMP is null and @pdtLogDateTimeStamp is null))"

	exec @nErrorCode=sp_executesql @sDeleteString,
		      N'@pnCaseKey		int,
			@psTextTypeCode		nvarchar(2),
			@pnTextSubSequence	smallint,
			@pdtLogDateTimeStamp	datetime',
			@pnCaseKey	 	= @pnCaseKey,
			@psTextTypeCode	 	= @psTextTypeCode,
			@pnTextSubSequence	= @pnTextSubSequence,
			@pdtLogDateTimeStamp    = @pdtLogDateTimeStamp

	Set @pnRowCount = @@RowCount

	-- If no rows were updated by the above delete statemant,
	-- set @@RowCount back to 0 for the calling code to be able
	-- to produce concurrency error:
	If @pnRowCount = 0
	Begin
		PRINT 'Reset @@RowCount back to 0'
	End
End
If @nErrorCode = 0 and @psTextTypeCode = 'G' and not exists( Select 1 from CASETEXT WHERE CLASS = @psClass and CASEID = @pnCaseKey)
Begin
	Set @sDeleteString = "Delete from CLASSFIRSTUSE
			where 
		        CASEID = @pnCaseKey and
		        CLASS = @psClass"	
	
	exec @nErrorCode=sp_executesql @sDeleteString,
		N'@pnCaseKey		        int,
		@psClass 		        nvarchar(11)',
		@pnCaseKey	 	        = @pnCaseKey,
		@psClass			= @psClass

End

-- Culture is different to DB culture
If @nErrorCode = 0 and @sLookupCulture is not null
Begin
	-- Get the TIDs if the exist
	Set @sSQLString = "
		Select	@nTitleTID = (Case When @bLongFlag=0 Then SHORTTEXT_TID Else TEXT_TID End )
		From CASETEXT
		Where CASEID = @pnCaseKey and
		TEXTTYPE = @psTextTypeCode and
		TEXTNO = @pnTextSubSequence"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
                                          @psTextTypeCode	nvarchar(2),
				          @pnTextSubSequence	smallint,
                                          @bLongFlag            bit,
					  @nTitleTID		int output',
					  @pnCaseKey = @pnCaseKey,
                                          @psTextTypeCode = @psTextTypeCode,
                                          @pnTextSubSequence = @pnTextSubSequence,
                                          @bLongFlag         = @bLongFlag,
					  @nTitleTID = @nTitleTID	output

        If @nErrorCode = 0
	Begin
		Set @sSQLString = " 
			Delete TRANSLATEDTEXT 
			Where	TID = @nTitleTID and CULTURE =@psCulture "

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTitleTID		int,
                                          @psCulture		nvarchar(10)',
					  @psCulture		= @psCulture,
					  @nTitleTID 		= @nTitleTID
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteCaseText to public
GO