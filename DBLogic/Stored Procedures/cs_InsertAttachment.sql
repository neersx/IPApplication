-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertAttachment
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_InsertAttachment.'
	drop procedure [dbo].[cs_InsertAttachment]
	print '**** Creating Stored Procedure dbo.cs_InsertAttachment...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

create procedure dbo.cs_InsertAttachment
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(11) = null,
	@psAttachmentKey		varchar(11) output,
	@psAttachmentName		varchar(254) = null,
	@psContentType			varchar(50) = null,	
	@piImgData			varbinary(max) = null
)
-- PROCEDURE: 	cs_InsertAttachment
-- VERSION:	9
-- DESCRIPTION:	Insert a blob into the Image Table and establish necessary relationship with a case
--		This blob can be of any type, ranging from actual images to documents.. etc.


-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 22/02/2002	SF 		Procedure Created
-- 23 Oct 2002	JB	4	Row Security
-- 23 Oct 2002	JB	5	Bug - need to set the ErrorCode after RAISERROR
-- 25 Oct 2002	JB	6	Now using cs_GetSecurityForCase for Row Security
-- 10 Mar 2003	JEK	7	RFC82 Localise stored procedure errors.
-- 15 Apr 2013	DV	8	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
-- 26 Aug 2019	vql	9	Change 'image' columns to a supported data type

AS

declare @nErrorCode 		int
declare @nImageId 		int
declare @nCaseId 		int
declare @nAttachmentType 	int
declare @bHasUpdateRights	bit
declare @sAlertXML 		nvarchar(400)
set @nCaseId = CAST(@psCaseKey as int)
set @nErrorCode = @@ERROR

-- -------------------
-- Row level security
If @nErrorCode = 0
Begin
	Exec @nErrorCode = cs_GetSecurityForCase
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pnCaseKey = @nCaseId,
		@pbCanUpdate = @bHasUpdateRights output

	If @nErrorCode = 0 and @bHasUpdateRights = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS3', 'User has insufficient security to update this case.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	Update LASTINTERNALCODE 
	Set     INTERNALSEQUENCE = INTERNALSEQUENCE + 1, 
        @nImageId = INTERNALSEQUENCE + 1,
	@psAttachmentKey = cast(INTERNALSEQUENCE+1 as varchar(11))
	from    LASTINTERNALCODE                
	where   TABLENAME = 'IMAGE'

	set @nErrorCode = @@Error
end

if @nErrorCode = 0
begin
	insert 	INTO IMAGE(IMAGEID, IMAGEDATA)
	values (@nImageId, @piImgData)

	set @nErrorCode = @@Error
end

if @nErrorCode = 0
begin
	insert into IMAGEDETAIL(IMAGEID, IMAGEDESC, CONTENTTYPE)
	values (@nImageId, @psAttachmentName, @psContentType)

	set @nErrorCode = @@Error
end

if @nErrorCode = 0
begin
     	set @nAttachmentType = 	
		case patindex('image%', lower(@psContentType))
		  when 0 then 1206 /* Attachment */
		else 
		  1205	/* Generic Case image Type */
		end
	set @nErrorCode = @@error
end
	
if @nErrorCode = 0
begin
	insert into CASEIMAGE (CASEID, IMAGEID, IMAGETYPE, IMAGESEQUENCE)
	values (@nCaseId, @nImageId, @nAttachmentType, 0)
	
	set @nErrorCode = @@Error
end

return @nErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_InsertAttachment to public
go
