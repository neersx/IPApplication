-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_DeleteAttachment
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_DeleteAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_DeleteAttachment.'
	drop procedure [dbo].[cs_DeleteAttachment]
end
print '**** Creating Stored Procedure dbo.cs_DeleteAttachment...'
print ''
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_DeleteAttachment
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(11) = null, 
	@psAttachmentKey		nvarchar(11) = null,
	@psAttachmentTypeKey		nvarchar(10) = null,
	@pnSequence			int = null,
	@psAttachmentName		nvarchar(254) = null
)
as
-- PROCEDURE :	cs_DeleteAttachment
-- VERSION :	4
-- DESCRIPTION:	remove a row 
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17/07/2002	SF				1	stub created
-- 08/08/2002	SF				2	procedure created
-- 25 Nov 2011	ASH				3	Change the size of Case Key and Related Case key to 11.
-- 15 Apr 2013	DV		R13270	4	Increase the length of nvarchar to 11 when casting or declaring integer

begin
	declare @nErrorCode int
	declare @nCaseId int
	declare @nImageId int

	set @nCaseId = cast(@psCaseKey as int)
	set @nImageId = cast(@psAttachmentKey as int)

	set @nErrorCode = @@error

	if @nErrorCode = 0
	begin
		delete
		from	CASEIMAGE
		where	CASEID = @nCaseId
		and	IMAGEID = @nImageId

		set @nErrorCode = @@error	
	end

	if @nErrorCode = 0
	and not exists(select * 
			from 	CASEIMAGE 
			where 	IMAGEID = @nImageId)
	begin
		delete
		from 	[IMAGE]
		where	IMAGEID = @nImageId
		
		set @nErrorCode = @@error
	end

	return @nErrorCode
end
GO

grant execute on dbo.cs_DeleteAttachment to public
go
