SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_DeleteReminder ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_DeleteReminder .'
	Drop procedure [dbo].[ip_DeleteReminder ]
End
Print '**** Creating Stored Procedure dbo.ip_DeleteReminder ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ip_DeleteReminder 
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEmployeeKey		int,
	@pdtReminderDateCreated	datetime,
	@pdtLogDateTimeStamp	datetime
)
-- PROCEDURE:	ip_DeleteReminder 
-- VERSION:	6
-- SCOPE:	CPA.net
-- DESCRIPTION:	Delete reminder (Ad Hoc or related to a case event).

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 05 Apr 2004  TM	RFC907	1	Procedure created. 
-- 27 Apr 2004	TM	RFC907	2	Correct the description as this stored procedure deletes reminders 
--					in general, whether they are Ad Hoc or related to a case event.
-- 21 Jan 2004	TM	RFC1319	3	Add a mandatory @pnReminderCheckSum parameter.
-- 22 Feb 2005	TM	RFC1319	4	Increase the size of the @sSQLString to nvarchar(4000)
-- 01 Mar 2005	TM	RFC2400	5	Set NOCOUNT OFF.
-- 11 Feb 2010	SF	RFC9284	6	Return LogDateTimeStamp rather than checksum
as

-- Row counts required by the data adapter
SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int
Declare @sSQLString  			nvarchar(4000)
Declare @sReminderChecksumColumns	nvarchar(4000)

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Delete 
	from EMPLOYEEREMINDER 
	where EMPLOYEENO = @pnEmployeeKey
	and   MESSAGESEQ = @pdtReminderDateCreated
	and    LOGDATETIMESTAMP = @pdtLogDateTimeStamp"

	exec sp_executesql @sSQLString,
				N'@pnEmployeeKey	  int,
				  @pdtReminderDateCreated datetime,
				  @pdtLogDateTimeStamp	  datetime',
				  @pnEmployeeKey	  = @pnEmployeeKey,
				  @pdtReminderDateCreated = @pdtReminderDateCreated,
				  @pdtLogDateTimeStamp	  = @pdtLogDateTimeStamp
End

Return @nErrorCode
GO

Grant execute on dbo.ip_DeleteReminder  to public
GO

