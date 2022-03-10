-----------------------------------------------------------------------------------------------------------------------------
-- Creation of api_InsertActivity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[api_InsertActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.api_InsertActivity.'
	Drop procedure [dbo].[api_InsertActivity]
End
Print '**** Creating Stored Procedure dbo.api_InsertActivity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc dbo.api_InsertActivity
(	@pnActivityNo		int		= NULL	OUTPUT,
	@pbDeleteOnFileMatch	bit		= 0,	-- Flag to indicate the deletion of preexisting Activity with attachment
	@pnNameNo		int		= NULL,
	@pnCaseId		int		= NULL,
	@psFileName		nvarchar(254)	= NULL,
	@psSummary		nvarchar(254),		-- Mandatory
	@psActivityType		nvarchar(80)	= NULL,
	@psActivityCategory	nvarchar(80)	= NULL,
	@psAttachmentType	nvarchar(80)	= NULL,
	@psAttachmentName	nvarchar(254)	= NULL,
	@pnActivityTypeCode	int		= 58,	-- Note this default may be invalid for some implementations
	@pnAttachmentTypeCode	int		= null,
	@pnActivityCategoryCode int		= 59,	-- Note this default may be invalid for some implementations
	@pnStaffMemberId	int		= NULL,
	@pdtActivityDate	datetime	= NULL,
	@psActivityNotes	nvarchar(max)	= NULL
)
as
-- PROCEDURE :	api_InsertActivity
-- VERSION :	2
-- DESCRIPTION:	Insert data into ACTIVITY and ACTIVITYATTACHMENT tables
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 07/01/2008	LITS			Procedure created
-- 09/01/2008	MF	15817	1	CPASS standards applied
-- 28 Apr 2014	MF	R32616	2	Extend API to include additional parameters

SET NOCOUNT ON

Declare @sSQLString		nvarchar(max)
Declare @nErrorCode 		int
Declare @nTranCountStart	int

Set @nErrorCode		= 0 
set @nTranCountStart	= 0
--------------------------------------------------
-- D A T A   V A L I D A T I O N
-- Validate the input parameters before attempting
-- to create the ACTIVITY row.
--------------------------------------------------

------------------------
-- Validate Staff Member
------------------------
If @nErrorCode = 0
and @pnStaffMemberId is not null
Begin
	If not exists (select 1 from EMPLOYEE where EMPLOYEENO=@pnStaffMemberId)
	Begin	
		RAISERROR('@pnStaffMemberId must identify a Name marked as staff and exists in the EMPLOYEE table', 14, 1)
		Set @nErrorCode = -1
	End	
End

------------------------
-- Validate Date is not
-- in the future.
------------------------
If  @nErrorCode = 0
and @pdtActivityDate is not null
Begin
	If @pdtActivityDate>getdate()
	Begin
		RAISERROR('@pdtActivityDate must not be after the current system date', 14, 1)
		Set @nErrorCode = -2
	End
End

--------------------------
-- Either CaseId or NameNo
-- has been supplied.
--------------------------
If  @nErrorCode = 0
and @pnCaseId is null
and @pnNameNo is null
Begin
	RAISERROR('At least one of @pnCaseId and/or @pnNameNo must be provided.', 14, 1)
	Set @nErrorCode = -3
End

------------------------
-- Validate CaseId if it 
-- has been supplied.
------------------------
If  @nErrorCode = 0
and @pnCaseId is not null
Begin
	If not exists (select 1 from CASES where CASEID=@pnCaseId)
	Begin	
		RAISERROR('@pnCaseId must identify a Case within the CASES table', 14, 1)
		Set @nErrorCode = -4
	End
End

------------------------
-- Validate NameNo if it 
-- has been supplied.
------------------------
If  @nErrorCode = 0
and @pnNameNo is not null
Begin
	If not exists (select 1 from NAME where NAMENO=@pnNameNo)
	Begin	
		RAISERROR('@pnNameNo must identify a Name within the NAME table', 14, 1)
		Set @nErrorCode = -5
	End
End

-------------------------
-- Validate ActivityType,
-- ActivityCategoryCode
-- and AttachmentType.
-------------------------
If @nErrorCode = 0
Begin
	If not exists(Select 1 from TABLECODES where TABLECODE=@pnActivityTypeCode and TABLETYPE=58)
	Begin
		RAISERROR('@pnActivityTypeCode must exist within the TABLECODES table', 14, 1)
		Set @nErrorCode = -6
	End
	
	If  @psActivityType is not null
	and @nErrorCode =0
	Begin
		if not exists(Select 1 from TABLECODES where TABLECODE=@pnActivityTypeCode and DESCRIPTION=@psActivityType and TABLETYPE=58)
		Begin
			RAISERROR('@psActivityType does not match the Description of the supplied @pnActivityTypeCode', 14, 1)
			Set @nErrorCode = -7
		End
	End
End	

If @nErrorCode = 0
Begin
	If not exists(Select 1 from TABLECODES where TABLECODE=@pnActivityCategoryCode and TABLETYPE=59)
	Begin
		RAISERROR('@pnActivityCategoryCode must exist within the TABLECODES table', 14, 1)
		Set @nErrorCode = -8
	End
	
	If  @psActivityCategory is not null
	and @nErrorCode =0
	Begin
		if not exists(Select 1 from TABLECODES where TABLECODE=@pnActivityCategoryCode and DESCRIPTION=@psActivityCategory and TABLETYPE=59)
		Begin
			RAISERROR('@psActivityCategory does not match the Description of the supplied @pnActivityCategoryCode', 14, 1)
			Set @nErrorCode = -9
		End
	End
End

If  @nErrorCode = 0
and @pnAttachmentTypeCode is not null
Begin
	If not exists(Select 1 from TABLECODES where TABLECODE=@pnAttachmentTypeCode and TABLETYPE=101)
	Begin
		RAISERROR('@pnAttachmentTypeCode must exist within the TABLECODES table', 14, 1)
		Set @nErrorCode = -10
	End
	
	If  @psAttachmentType is not null
	and @nErrorCode =0
	Begin
		if not exists(Select 1 from TABLECODES where TABLECODE=@pnAttachmentTypeCode and DESCRIPTION=@psAttachmentType and TABLETYPE=101)
		Begin
			RAISERROR('@psAttachmentType does not match the Description of the supplied @pnAttachmentTypeCode', 14, 1)
			Set @nErrorCode = -11
		End
	End
End

 
-------------------------------------------------------------------
-- Get the Activity Number to use from the LastInternalCode table
-- Keep the transaction as short as possible to avoid system blocks
-- on this widely used table. 
-------------------------------------------------------------------
If  @nErrorCode=0
Begin
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	select @sSQLString="
	Update LASTINTERNALCODE
	set INTERNALSEQUENCE=INTERNALSEQUENCE+1,
	    @pnActivityNo=isnull(INTERNALSEQUENCE,0) + 1
	from LASTINTERNALCODE 
	where TABLENAME='ACTIVITY'"

	Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@pnActivityNo		int OUTPUT',
					  @pnActivityNo=@pnActivityNo OUTPUT

	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-------------------------------------------------
-- Delete the Activity if an attachment for the
-- file, case and name combination already exists
-------------------------------------------------
if  @psFileName is not null 
and ltrim(rtrim(@psFileName))<>'' 
and charindex('http://',ltrim(rtrim(@psFileName)))=1
and @pbDeleteOnFileMatch=1
and @nErrorCode=0
Begin
	Set @sSQLString="
	delete ACTIVITY 
	from ACTIVITY A
	join ACTIVITYATTACHMENT AA on (AA.ACTIVITYNO=A.ACTIVITYNO)
	where LTRIM(RTRIM(AA.FILENAME)) =@psFileName 
	and (A.NAMENO=@pnNameNo or (A.NAMENO is null and @pnNameNo is null))
	and (A.CASEID=@pnCaseId or (A.CASEID is null and @pnCaseId is null))"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@psFileName		nvarchar(254),
				  @pnNameNo		int,
				  @pnCaseId		int',
				  @psFileName=@psFileName,
				  @pnNameNo  =@pnNameNo,
				  @pnCaseId  =@pnCaseId
End

--------------------------------------------
-- Insert the ACTIVITY row which is required
-- as a parent to ACTIVITYATTACHMENT
--------------------------------------------
If @nErrorCode=0
Begin
	set @sSQLString="
	insert into ACTIVITY (ACTIVITYNO,EMPLOYEENO, NAMENO,CASEID,INCOMPLETE, SUMMARY,ACTIVITYCATEGORY,ACTIVITYTYPE,ACTIVITYDATE, NOTES, LONGNOTES, LONGFLAG) 
	select	A.ACTIVITYNO,@pnStaffMemberId,@pnNameNo,@pnCaseId,'0',@psSummary,@pnActivityCategoryCode,@pnActivityTypeCode,isnull(@pdtActivityDate,getdate()),
		CASE WHEN(LEN(@psActivityNotes)>254) THEN NULL ELSE @psActivityNotes END,
		CASE WHEN(LEN(@psActivityNotes)<255) THEN NULL ELSE @psActivityNotes END,
		CASE WHEN(LEN(@psActivityNotes)>254) THEN 1    ELSE 0                END
	from (select @pnActivityNo as ACTIVITYNO) A"
				
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnActivityNo			int,
					  @pnStaffMemberId		int,
					  @pnNameNo			int,
					  @pnCaseId			int,
					  @psSummary			nvarchar(100),
					  @pnActivityCategoryCode	int,
					  @pnActivityTypeCode		int,
					  @pdtActivityDate		datetime,
					  @psActivityNotes		nvarchar(max)',
					  @pnActivityNo			=@pnActivityNo,
					  @pnStaffMemberId		=@pnStaffMemberId,
					  @pnNameNo			=@pnNameNo,
					  @pnCaseId			=@pnCaseId,
					  @psSummary			=@psSummary,
					  @pnActivityCategoryCode	=@pnActivityCategoryCode,
					  @pnActivityTypeCode		=@pnActivityTypeCode,
					  @pdtActivityDate		=@pdtActivityDate,
					  @psActivityNotes		=@psActivityNotes
End
------------------------------------------
-- Insert the ACTIVITYATTACHMENT row if a
-- FILENAME or ATTACHMENT name is provided
------------------------------------------
If @nErrorCode=0
and(@psAttachmentName is not null
 or @psFileName       is not null)
Begin
	set @sSQLString="
	insert into ACTIVITYATTACHMENT (ACTIVITYNO,SEQUENCENO,ATTACHMENTNAME,FILENAME,ATTACHMENTTYPE)
	select A.ACTIVITYNO,0,@psAttachmentName,@psFileName,AT.TABLECODE
	from ACTIVITY A
	left join TABLECODES AT	on (AT.TABLETYPE=@pnAttachmentTypeCode
				and AT.DESCRIPTION=@psAttachmentType)
	where A.ACTIVITYNO=@pnActivityNo"
				
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnActivityNo			int,
					  @pnAttachmentTypeCode		int,
					  @psFileName			nvarchar(254),
					  @psAttachmentName		nvarchar(254),
					  @psAttachmentType		nvarchar(80)',
					  @pnActivityNo			=@pnActivityNo,
					  @pnAttachmentTypeCode		=@pnAttachmentTypeCode,
					  @psFileName			=@psFileName,
					  @psAttachmentName		=@psAttachmentName,
					  @psAttachmentType		=@psAttachmentType
End

RETURN @nErrorCode
GO

Grant execute on dbo.api_InsertActivity to public
GO
