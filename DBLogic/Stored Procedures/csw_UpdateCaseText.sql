-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateCaseText									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateCaseText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateCaseText.'
	Drop procedure [dbo].[csw_UpdateCaseText]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateCaseText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateCaseText
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,		-- Mandatory
	@psTextTypeCode		nvarchar(2),	-- Mandatory
	@pnTextSubSequence	        smallint        output,	-- Mandatory
	@psClass		nvarchar(11)	= null,
	@pnLanguageKey		int		= null,
	@pdtLastModified	datetime	= null,
	@ptText			ntext		= null,
	@pdtFirstUse	datetime	= null,
	@pdtFirstUseInCommerce	datetime	= null,
	@psOldTextTypeCode	nvarchar(2)	= null,
	@psOldClass		nvarchar(11)	= null,
	@pdtOldFirstUse	datetime	= null,
	@pdtOldFirstUseInCommerce	datetime	= null,
	@pdtLogDateTimeStamp            datetime        = null output,
	@psRowKey                       nvarchar(50)	= null output
)
as
-- PROCEDURE:	csw_UpdateCaseText
-- VERSION:	14
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update CaseText if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 07 Nov 2005		RFC3201	1	Procedure created
-- 07 Nov 2005	TM	RFC3201	2	Use 'Else' statement rather then terminating the procedure with 'Return'.	
-- 02 Dec 2005	TM	RFC3201	3	Adjust the standard parameters to include both old and current versions 
--					of TextTypeCode.
-- 11 Jan 2006	TM	RFC3201	4	Concurrency error is not produced after executing the csw_DeleteCaseText
--					when TextTypeCode<>OldTextTypeCode.
-- 06 Dec 2007	AT	RFC3208	5	Check KeepSpeciHistory site control and insert instead of update.
-- 27 Mar 2008	ash	RFC6207	6	Cannot update case text with carriage returns line feeds and/or tabs
-- 11 Dec 2008	MF	17136	7	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 10 Sep 2009	PA	RFC8043	8	Update FIRSTUSE and FIRSTUSEINCOMMERCE fields
-- 28 Oct 2010	ASH	R9788	9	Maintain Title in foreign languages.
-- 19 Sep 2011  DV  R100604 10  KEEPSPECIHISTORY sitecontrol should only be applicable for Goods/Services Case text
-- 23 Nov 2011	LP	R11592	11	Update of SHORTTEXT and TEXT columns should be allowed regardless of LookupCulture
-- 17 Feb 2012  MS	R11154	12  Remove InUse and OldData parameters
-- 20 Jul 2012	ASH	R12112	13	Pass @pdtFirstUse and @pdtFirstUseInCommerce parameters in csw_InsertCaseText.
-- 10 Mar 2014	SF	R31302	14	KEEPSPECIHISTORY sitecontrol should only be applicable for Goods/Services Case text

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)
Declare @bLongFlag 		bit
Declare @bOldLongFlag		bit
Declare @sShortOldText		nvarchar(254)
Declare @sShortText		nvarchar(254)
Declare @bKeepHistory		bit

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0 
and (datalength(@ptText) = 0
or datalength(@ptText) is null)
Begin
	exec @nErrorCode = dbo.csw_DeleteCaseText
			@pnRowCount		= @nRowCount	OUTPUT,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnCaseKey		= @pnCaseKey,
			@psTextTypeCode		= @psTextTypeCode,
			@pnTextSubSequence	= @pnTextSubSequence,
			@psClass		        = @psOldClass,
			@pdtLogDateTimeStamp            = @pdtLogDateTimeStamp	

			-- If no rows were updated by the above delete, set @@RowCount 
			-- back to 0 for the calling code to be able to produce concurrency error:
			If @nRowCount = 0
			Begin
				PRINT 'Reset @@RowCount back to 0'
			End
End
Else If @nErrorCode = 0 
and (@psTextTypeCode <> @psOldTextTypeCode)
Begin
	exec @nErrorCode = dbo.csw_DeleteCaseText
			@pnRowCount		= @nRowCount	OUTPUT,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnCaseKey		= @pnCaseKey,
			@psTextTypeCode		= @psOldTextTypeCode,
			@pnTextSubSequence	= @pnTextSubSequence,
			@psClass		        = @psOldClass,
			@pdtLogDateTimeStamp            = @pdtLogDateTimeStamp		

			-- If no rows were updated by the above delete, set @@rowCount 
			-- back to 0 for the calling code to be able to produce concurrency error:
			If @nRowCount = 0
			Begin
				PRINT 'Reset @@RowCount back to 0'
			End
			-- Only insert CaseText if there was no concurrency  
			-- error during the above delete
			Else If @nRowCount > 0
			and @nErrorCode = 0 			
			Begin
				exec @nErrorCode =  dbo.csw_InsertCaseText
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@pbCalledFromCentura	= 0,
					@pnCaseKey		= @pnCaseKey,		
					@psTextTypeCode		= @psTextTypeCode,
				@pnTextSubSequence	= @pnTextSubSequence output,	
					@psClass		= @psClass,
					@pnLanguageKey		= @pnLanguageKey,
					@pdtLastModified	= @pdtLastModified,
					@ptText			= @ptText,
					@pdtFirstUse	        = @pdtFirstUse,
			                          @pdtFirstUseInCommerce	= @pdtFirstUseInCommerce,
					@pdtLogDateTimeStamp	= @pdtLogDateTimeStamp output,
					@psRowKey		= @psRowKey output
			End
End
Else Begin

	-- Is the new CaseText long text?
	If (datalength(@ptText) <= 508)
	or datalength(@ptText) is null
	Begin
		Set @bLongFlag = 0
	End
	Else
	Begin
		Set @bLongFlag = 1
	End
	
	-- Set LastModified to the current application date/time.
	If @nErrorCode = 0
	Begin
		Set @pdtLastModified = getdate()
	End
	
	Set @bKeepHistory = 0
	-- Check the KEEPSPECIHISTORY site control to see if we should insert or update
	If @nErrorCode = 0 and @psTextTypeCode = 'G'
	Begin
		set @sSQLString = "Select @bKeepHistory = COLBOOLEAN
				from SITECONTROL WHERE CONTROLID = 'KEEPSPECIHISTORY'"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@bKeepHistory	bit OUTPUT',
				@bKeepHistory = @bKeepHistory OUTPUT
	End

	If (@nErrorCode = 0 AND ISNULL(@bKeepHistory,0) = 0)
	Begin
		Set @sUpdateString = "Update CASETEXT
				   set 
				   CLASS = @psClass,
				   LANGUAGE = @pnLanguageKey,
				   MODIFIEDDATE = @pdtLastModified"
	
		Set @sWhereString = @sWhereString+CHAR(10)+"
			CASEID = @pnCaseKey and
			TEXTTYPE = @psTextTypeCode and
			TEXTNO = @pnTextSubSequence and 
			(LOGDATETIMESTAMP = @pdtLogDateTimeStamp or (LOGDATETIMESTAMP is null and @pdtLogDateTimeStamp is null))"
			
		Set @sComma = ","		
		
			If @bLongFlag = 1
			Begin
				Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+
				" 	LONGFLAG  	= 1," + char(10) +
				"	SHORTTEXT 	= null," + char(10) +
				"	TEXT 	  	= @ptText"
			End
			Else Begin
				Set @sShortText = CAST(@ptText as nvarchar(254))
				Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+
				" 	LONGFLAG	= 0," + char(10) +
				"	SHORTTEXT	= @sShortText," + char(10) + 
				"	TEXT 		= null"
			End
					
		Set @sSQLString = @sUpdateString + @sWhereString
	
		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@pnCaseKey		int,
				@psTextTypeCode		nvarchar(2),
				@pnTextSubSequence	smallint,
				@psClass		nvarchar(11),
				@pnLanguageKey		int,
				@pdtLastModified	datetime,
				@ptText			ntext,
				@sShortText		nvarchar(254),
				@sShortOldText		nvarchar(254),
				@pdtLogDateTimeStamp    datetime',
				@pnCaseKey	 	= @pnCaseKey,
				@psTextTypeCode	 	= @psTextTypeCode,
				@pnTextSubSequence	= @pnTextSubSequence,
				@psClass	 	= @psClass,
				@pnLanguageKey	 	= @pnLanguageKey,
				@pdtLastModified	= @pdtLastModified,
				@ptText	 		= @ptText,
				@sShortText		= @sShortText,
				@sShortOldText		= @sShortOldText,
				@pdtLogDateTimeStamp    = @pdtLogDateTimeStamp
	
	End
	else if (@nErrorCode = 0) 
	Begin
		exec @nErrorCode = [csw_InsertCaseText] 
					@pnUserIdentityId = @pnUserIdentityId, 
					@psCulture = @psCulture,
					@pbCalledFromCentura = @pbCalledFromCentura,
					@pnCaseKey = @pnCaseKey,
					@psTextTypeCode = @psTextTypeCode,
					@pnTextSubSequence      = @pnTextSubSequence output,
					@psClass = @psClass,
					@pnLanguageKey = @pnLanguageKey,
					@pdtLastModified = @pdtLastModified,
					@ptText = @ptText,
					@pdtFirstUse	        = @pdtFirstUse,
	                                @pdtFirstUseInCommerce	= @pdtFirstUseInCommerce,
				        @pdtLogDateTimeStamp	= @pdtLogDateTimeStamp output,
	                                @psRowKey		= @psRowKey output
					
	End
End
If @nErrorCode = 0 and @psTextTypeCode = 'G'
Begin
	exec @nErrorCode = dbo.csw_UpdateClassFirstUse
					@pnUserIdentityId = @pnUserIdentityId, 
					@psCulture = @psCulture,
					@pbCalledFromCentura = @pbCalledFromCentura,
					@pnCaseKey = @pnCaseKey,
					@psClass = @psClass,
					@pdtFirstUse	= @pdtFirstUse,
					@pdtFirstUseInCommerce	= @pdtFirstUseInCommerce,
					@pdtOldFirstUse		=	@pdtOldFirstUse,
					@pdtOldFirstUseInCommerce	= @pdtOldFirstUseInCommerce,
					@pbIsClassInUse = 1,
					@pbIsFirstUseInUse = 1,
					@pbIsFirstUseInCommerceInUse = 1


End 

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateCaseText to public
GO