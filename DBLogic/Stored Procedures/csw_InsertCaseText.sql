-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertCaseText									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertCaseText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertCaseText.'
	Drop procedure [dbo].[csw_InsertCaseText]
End
Print '**** Creating Stored Procedure dbo.csw_InsertCaseText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertCaseText
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,		-- Mandatory.
	@psTextTypeCode		nvarchar(2),	-- Mandatory.
	@pnTextSubSequence	smallint	= null  output,	
	@psClass		nvarchar(11)	= null,
	@pnLanguageKey		int		= null,
	@pdtLastModified	datetime	= null,
	@ptText			ntext		= null,
	@pdtFirstUse	        datetime	= null,
	@pdtFirstUseInCommerce	datetime	= null,
	@pdtLogDateTimeStamp	datetime	= null output,
	@psRowKey		nvarchar(50)	= null output	
)
as
-- PROCEDURE:	csw_InsertCaseText
-- VERSION:	9
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert CaseText.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 07 Nov 2005		RFC3201	1	Procedure created
-- 10 Nov 2005	TM	RFC3201	2	Correct spelling error.
-- 10 Nov 2005	TM	RFC3201	3	Place sequence generating logic just before the insert statement.
-- 12 Dec 2005	TM	RFC3201	4	Correct TextNo generation logic.
-- 10 Sep 2009	PA	RFC8043	5	Insert FIRSTUSE and FIRSTUSEINCOMMERCE dates in CLASSFIRSTUSE table
-- 28 Oct 2010	ASH	RFC9788 6   Maintain Title in foreign languages.
-- 17 Feb 2012  MS  R11154  7   Remove parameters for InUse
-- 24 Sep 2012  ASH R12777  8   Correct synatx error when @sLookupCulture is not null
-- 15 Apr 2013	DV	R13270	9	Increase the length of nvarchar to 11 when casting or declaring integer


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @bLongFlag		bit
Declare @pnTotal                smallint
Declare @sLookupCulture		nvarchar(10)
Declare @pnTid                  int

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("
Set @bLongFlag = 1
set @pnTotal = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @pdtLastModified = getdate()        -- Set LastModified to the current application date/time.

If (datalength(@ptText) <= 508)
or datalength(@ptText) is null
Begin
	Set @bLongFlag = 0
End

-- Generate subsequence
If @nErrorCode = 0
Begin        
	Set @sSQLString = "
	Select 	@pnTextSubSequence = MAX(TEXTNO) + 1
	from  	CASETEXT 
	where 	CASEID = @pnCaseKey
	and   	TEXTTYPE = @psTextTypeCode"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnTextSubSequence	smallint		OUTPUT,
				  @pnCaseKey		int,
				  @psTextTypeCode	nvarchar(2)',
				  @pnTextSubSequence	= @pnTextSubSequence	OUTPUT,
				  @pnCaseKey		= @pnCaseKey,
				  @psTextTypeCode	= @psTextTypeCode
	
End

If @nErrorCode = 0
Begin
        Set @pnTextSubSequence = ISNULL(@pnTextSubSequence,0)
        
	Set @sInsertString = "Insert into CASETEXT
				("

	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+" CASEID,TEXTTYPE,TEXTNO,CLASS,LANGUAGE,MODIFIEDDATE "

	Set @sValuesString = @sValuesString+CHAR(10)+" @pnCaseKey,@psTextTypeCode,@pnTextSubSequence," +
	        CHAR(10)+ "@psClass,@pnLanguageKey, @pdtLastModified "

	If @bLongFlag = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TEXT,LONGFLAG"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@ptText,1"
		Set @sComma = ","
        End
        Else 
        Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SHORTTEXT,LONGFLAG"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@ptText,0"                
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString
	
	-- Insert CaseText
	exec @nErrorCode=sp_executesql @sSQLString,
                N'@pnCaseKey		int,
		@psTextTypeCode		nvarchar(2),
		@pnTextSubSequence	smallint,
		@psClass		nvarchar(11),
		@pnLanguageKey		int,
		@pdtLastModified	datetime,
		@ptText			ntext',
		@pnCaseKey	 	= @pnCaseKey,
		@psTextTypeCode	 	= @psTextTypeCode,
		@pnTextSubSequence	= @pnTextSubSequence,
		@psClass	 	= @psClass,
		@pnLanguageKey	 	= @pnLanguageKey,
		@pdtLastModified	= @pdtLastModified,
		@ptText	 		= @ptText
		
        If @nErrorCode = 0
        Begin
                Set @sSQLString = "Select	@pdtLogDateTimeStamp = LOGDATETIMESTAMP,
		        @psRowKey = CAST(CASEID as nvarchar(11))+'^'+ TEXTTYPE+'^'+ CAST(TEXTNO as nvarchar(11))
	                from	CASETEXT
	                where	CASEID		= @pnCaseKey
	                and     TEXTTYPE        = @psTextTypeCode
	                and	TEXTNO		= @pnTextSubSequence"
	                
	        exec @nErrorCode=sp_executesql @sSQLString,
                        N'@pdtLogDateTimeStamp  datetime        OUTPUT,
                        @psRowKey               nvarchar(50)    OUTPUT,
                        @pnTextSubSequence      smallint,
                        @pnCaseKey		int,
		        @psTextTypeCode		nvarchar(2)',
		        @pdtLogDateTimeStamp    = @pdtLogDateTimeStamp  OUTPUT,
		        @psRowKey               = @psRowKey             OUTPUT,
		        @pnTextSubSequence	= @pnTextSubSequence,
		        @pnCaseKey	 	= @pnCaseKey,
		        @psTextTypeCode	 	= @psTextTypeCode
        
        End
	
End

If @nErrorCode = 0
Begin
        Set @sSQLString = "
	Select 	@pnTotal = COUNT(*)
	from  	CLASSFIRSTUSE 
	where 	CASEID = @pnCaseKey
	and   	CLASS = @psClass"

	exec @nErrorCode=sp_executesql @sSQLString,
	        N'@pnTotal	        smallint	OUTPUT,
		  @pnCaseKey		int,
		  @psClass	        nvarchar(11)',
		  @pnTotal	        = @pnTotal	OUTPUT,
		  @pnCaseKey		= @pnCaseKey,
		  @psClass	        = @psClass
End

If @nErrorCode = 0 and @pnTotal = 0 and @psTextTypeCode = 'G' and @psClass is not null
Begin	
	-- Insert ClassFirstUse
	Set @sSQLString = "Insert into CLASSFIRSTUSE (CASEID, CLASS, FIRSTUSE, FIRSTUSEINCOMMERCE)
	                   values (@pnCaseKey, @psClass, @pdtFirstUse, @pdtFirstUseInCommerce)"
	
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnCaseKey	                int,
		  @psClass		        nvarchar(11),
		  @pdtFirstUse	                datetime,
		  @pdtFirstUseInCommerce	datetime',
		  @pnCaseKey	 	        = @pnCaseKey,
		  @psClass	 	        = @psClass,
		  @pdtFirstUse	                = @pdtFirstUse,
		  @pdtFirstUseInCommerce	= @pdtFirstUseInCommerce

End

If @nErrorCode = 0 and @sLookupCulture is not null
Begin
        
        Set @sSQLString = "
	Select 	@pnTid = CASE WHEN @bLongFlag = 0 
	                        THEN SHORTTEXT_TID 
	                        ELSE TEXT_TID 
	                 END
	from CASETEXT 
        where CASEID = @pnCaseKey
	and TEXTTYPE = @psTextTypeCode
        and TEXTNO=@pnTextSubSequence"               

        exec @nErrorCode=sp_executesql @sSQLString,
                N'@pnTid	        int		OUTPUT,
		  @bLongFlag            bit,
		  @pnCaseKey		int,
		  @psTextTypeCode	nvarchar(2),
		  @pnTextSubSequence	smallint',
		  @pnTid	        = @pnTid	OUTPUT,
		  @pnCaseKey		= @pnCaseKey,
		  @psTextTypeCode	= @psTextTypeCode,
		  @bLongFlag		= @bLongFlag,
          @pnTextSubSequence = @pnTextSubSequence
End

If @nErrorCode = 0 and @sLookupCulture is not null and @ptText is not null and @bLongFlag =0
Begin
	-- Insert into translation tables.
	exec @nErrorCode = ipn_InsertTranslatedText	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@sLookupCulture,
							@psTableName= N'CASETEXT',
							@psTIDColumnName='SHORTTEXT_TID',
							@psText=@ptText,
							@pnTID=@pnTid output							
End

If @nErrorCode = 0 and @sLookupCulture is not null and @ptText is not null and @bLongFlag =1
Begin
	-- Insert into translation tables.
	exec @nErrorCode = ipn_InsertTranslatedText	@pnUserIdentityId=@pnUserIdentityId,
							@psCulture=@sLookupCulture,
							@psTableName= N'CASETEXT',
							@psTIDColumnName='TEXT_TID',
							@psText=@ptText,
							@pnTID=@pnTid output
End

-- Publish the generated TextSubSequence
If @nErrorCode = 0
Begin
	Select @pnTextSubSequence as TextSubSequence
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertCaseText to public
GO