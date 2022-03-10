-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertImage
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertImage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_InsertImage.'
	drop procedure [dbo].[csw_InsertImage]
	print '**** Creating Stored Procedure dbo.csw_InsertImage...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create procedure dbo.csw_InsertImage
(		
	@psAttachmentKey		nvarchar(11) output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psAttachmentDescription	nvarchar(254) = null,
	@psFileLocation			nvarchar(254) = null,
	@psContentType			nvarchar(100) = null,
	@piImgData			varbinary(max) = null,
	@pnImageStatusKey		int
)
-- PROCEDURE: 	csw_InsertImage
-- VERSION:	3
-- DESCRIPTION:	Insert an image into the Image Table with a row in the ImageDetail table.
--		This 'image' can be of any type, ranging from actual images to documents. etc.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 31/10/2007	AT	1	Procedure Created
-- 15 Apr 2013	DV	2	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
-- 26 Aug 2019	vql	3	Change 'image' columns to a supported data type

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode 		int
declare @nImageId 		int
Declare @TransactionCountStart	int

set @nErrorCode = @@ERROR

If @nErrorCode = 0
Begin
   Select @TransactionCountStart = @@TranCount
   BEGIN TRANSACTION
End

If (@nErrorCode = 0)
Begin
	Update LASTINTERNALCODE 
	Set     INTERNALSEQUENCE = INTERNALSEQUENCE + 1, 
        @nImageId = INTERNALSEQUENCE + 1,
	@psAttachmentKey = cast(INTERNALSEQUENCE+1 as nvarchar(11))
	from    LASTINTERNALCODE                
	where   TABLENAME = 'IMAGE'

	set @nErrorCode = @@Error
End

if (@nErrorCode = 0)
Begin
	insert 	INTO IMAGE(IMAGEID, IMAGEDATA)
	values (@nImageId, @piImgData)

	set @nErrorCode = @@Error
End

if (@nErrorCode = 0)
Begin
	insert into IMAGEDETAIL(IMAGEID, IMAGEDESC, CONTENTTYPE, IMAGESTATUS)
	values (@nImageId, @psAttachmentDescription, @psContentType, @pnImageStatusKey)

	set @nErrorCode = @@Error
End

If @@TranCount > @TransactionCountStart
Begin
	if (@nErrorCode =0)
		COMMIT TRANSACTION
	else
		ROLLBACK TRANSACTION
End

Return @nErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.csw_InsertImage to public
GO