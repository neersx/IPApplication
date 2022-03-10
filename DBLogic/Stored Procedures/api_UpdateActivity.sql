-----------------------------------------------------------------------------------------------------------------------------
-- Creation of api_UpdateActivity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[api_UpdateActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.api_UpdateActivity.'
	Drop procedure [dbo].[api_UpdateActivity]
End
Print '**** Creating Stored Procedure dbo.api_UpdateActivity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc dbo.api_UpdateActivity
(	@pnActivityNo		int,
	@pnNameNo		int		= NULL,
	@pnCaseId		int		= NULL,
	@psFileName		nvarchar(254)	= NULL,
	@psSummary		nvarchar(100)	= NULL,
	@psActivityType		nvarchar(80)	= NULL,
	@psActivityCategory	nvarchar(80)	= NULL,
	@psAttachmentType	nvarchar(80)	= NULL,
	@psAttachmentName	nvarchar(254)	= NULL,
	@pnActivityTypeCode	int		= 58,
	@pnAttachmentTypeCode	int		= 101,
	@pnActivityCategoryCode int		= 59,
	@pbModifyNameNo		Bit		= 0,						
	@pbModifyCaseId		Bit		= 0	
)
as
-- PROCEDURE :	api_UpdateActivity
-- VERSION :	1
-- DESCRIPTION:	Insert data into ACTIVITY and ACTIVITYATTACHMENT tables
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 07/01/2008	LITS			Procedure created
-- 09/01/2008	MF	15817	1	CPASS standards applied

SET NOCOUNT ON

Declare @sSQLString		nvarchar(4000)
Declare @sSQLFrom		nvarchar(1000)
Declare @sSQLWhere		nvarchar(1000)
Declare @sComma			nchar(1)
Declare @nErrorCode 		int
Declare @nTranCountStart	int

Set @nErrorCode=0

--------------------------------------
-- Update the ACTIVITY row if required
--------------------------------------
If @nErrorCode=0
and (@psSummary is not null
 or  @psActivityCategory is not null
 or  @psActivityType     is not null
 or  @pbModifyNameNo=1
 or  @pbModifyCaseId=1)
Begin
	---------------------------------
	-- Construct the UPDATE statement
	---------------------------------
	set @sSQLString="
	Update ACTIVITY
	Set"
	
	Set @sSQLFrom="
	From ACTIVITY A"
	
	Set @sSQLWhere="
	Where A.ACTIVITYNO=@pnActivityNo"
	
	Set @sComma=''
	
	If @pbModifyNameNo=1
	Begin
		Set @sSQLString=@sSQLString+"
		NAMENO=@pnNameNo"
		
		Set @sComma=','
	End
	
	If @pbModifyCaseId=1
	Begin
		Set @sSQLString=@sSQLString+@sComma+"
		NAMENO=@pnCaseId"
		
		Set @sComma=','
	End
	
	If @psSummary is not null
	Begin
		Set @sSQLString=@sSQLString+@sComma+"
		SUMMARY=@psSummary"
		
		Set @sComma=','
	End
	
	If @psActivityCategory is not null
	Begin
		Set @sSQLString=@sSQLString+@sComma+"
		ACTIVITYCATEGORY=AC.TABLECODE"
		
		Set @sSQLFrom=@sSQLFrom+"
		Left Join TABLECODES AC on (AC.TABLETYPE=@pnActivityCategoryCode
		                        and AC.DESCRIPTION=@psActivityCategory)"
		
		Set @sComma=','
	End
	
	If @psActivityType is not null
	Begin
		Set @sSQLString=@sSQLString+@sComma+"
		ACTIVITYTYPE=AT.TABLECODE"
		
		Set @sSQLFrom=@sSQLFrom+"
		Left Join TABLECODES AT on (AT.TABLETYPE=@pnActivityTypeCode
		                        and AT.DESCRIPTION=@psActivityType)"
		
		Set @sComma=','
	End
	
	Set @sSQLString=@sSQLString+@sSQLFrom+@sSQLWhere
				
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnActivityNo			int,
					  @pnNameNo			int,
					  @pnCaseId			int,
					  @psSummary			nvarchar(100),
					  @pnActivityCategoryCode	int,
					  @psActivityCategory		nvarchar(80),
					  @pnActivityTypeCode		int,
					  @psActivityType		nvarchar(80)',
					  @pnActivityNo			=@pnActivityNo,
					  @pnNameNo			=@pnNameNo,
					  @pnCaseId			=@pnCaseId,
					  @psSummary			=@psSummary,
					  @pnActivityCategoryCode	=@pnActivityCategoryCode,
					  @psActivityCategory		=@psActivityCategory,
					  @pnActivityTypeCode		=@pnActivityTypeCode,
					  @psActivityType		=@psActivityType
End

------------------------------------------
-- Insert the ACTIVITYATTACHMENT row if a
-- FILENAME or ATTACHMENT name is provided
------------------------------------------
If @nErrorCode=0
and(@psAttachmentName is not null
 or @psFileName       is not null
 or @psAttachmentType is not null)
Begin
	---------------------------------
	-- Construct the UPDATE statement
	---------------------------------
	set @sSQLString="
	Update ACTIVITYATTACHMENT
	Set"
	
	Set @sSQLFrom="
	From ACTIVITYATTACHMENT A"
	
	Set @sSQLWhere="
	Where A.ACTIVITYNO=@pnActivityNo"
	
	Set @sComma=''
	
	If @psAttachmentName is not null
	Begin
		Set @sSQLString=@sSQLString+"
		ATTACHMENTNAME=@psAttachmentName"
		
		Set @sComma=','
	End
	
	If @psFileName is not null
	Begin
		Set @sSQLString=@sSQLString+@sComma+"
		FILENAME=@psFileName"
		
		Set @sComma=','
	End
	
	If @psAttachmentType is not null
	Begin
		Set @sSQLString=@sSQLString+@sComma+"
		ATTACHMENTTYPE=AT.TABLECODE"
		
		Set @sSQLFrom=@sSQLFrom+"
		Left Join TABLECODES AT on (AT.TABLETYPE=@pnAttachmentTypeCode
		                        and AT.DESCRIPTION=@psAttachmentType)"
		
		Set @sComma=','
	End
	
	Set @sSQLString=@sSQLString+@sSQLFrom+@sSQLWhere
		
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnActivityNo			int,
					  @pnAttachmentTypeCode		int,
					  @psAttachmentName		nvarchar(254),
					  @psFileName			nvarchar(254),
					  @psAttachmentType		nvarchar(80)',
					  @pnActivityNo			=@pnActivityNo,
					  @pnAttachmentTypeCode		=@pnAttachmentTypeCode,
					  @psAttachmentName		=@psAttachmentName,
					  @psFileName			=@psFileName,
					  @psAttachmentType		=@psAttachmentType
End

RETURN @nErrorCode
GO

Grant execute on dbo.api_UpdateActivity to public
GO
