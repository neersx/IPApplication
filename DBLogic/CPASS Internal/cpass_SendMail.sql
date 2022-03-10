use cpalive
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

drop procedure cpass_SendMail
go

CREATE     PROCEDURE dbo.cpass_SendMail
(
	@profile_name			nvarchar(254),
	@psRecipients			nvarchar(254),
	@psSubject				nvarchar(254),
	@psAttachments			nvarchar(254)	= null 
)
AS
-- PROCEDURE :	cpass_SendMail
-- DESCRIPTION:	Sends mail to recipients
-- NOTES:	
-- VERSION:	1
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 10 Jul 2006	JD		1	Procedure created

declare	@ErrorCode int

set @psAttachments = rtrim(@psAttachments)

exec msdb.dbo.sp_send_dbmail
    @profile_name = @profile_name,
	@recipients = @psRecipients, 
	@subject    = @psSubject, 
	@file_attachments = @psAttachments

Return @@Error

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on [dbo].[cpass_SendMail] to public
go