-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetAttachment
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_GetAttachment.'
	drop procedure [dbo].[cs_GetAttachment]
end
print '**** Creating Stored Procedure dbo.cs_GetAttachment...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.cs_GetAttachment
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psAttachmentKey		varchar(11)			-- Mandatory 
)
as
-- VERSION:	4
-- DESCRIPTION:	To stream content back to the browser.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who			Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 24 Jul 2002	SF				1	Procedure Created
-- 24 Jul 2002	SF				2	Return ContentType and AttachmentData
-- 15 Nov 2002	SF				3	Update Version Number
-- 15 Apr 2013	DV		R13270	4	Increase the length of nvarchar to 11 when casting or declaring integer

	select 	IMAGEDETAIL.CONTENTTYPE as 'ContentType', 
		IMG.IMAGEDATA 		as 'AttachmentData'
	from 	IMAGE IMG
	left join IMAGEDETAIL on IMAGEDETAIL.IMAGEID = IMG.IMAGEID
	where 	IMG.IMAGEID = Cast(@psAttachmentKey as int)


	return @@error
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_GetAttachment to public
go
