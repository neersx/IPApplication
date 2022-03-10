-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_SetContextInfo
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_SetContextInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_SetContextInfo.'
	Drop procedure [dbo].[ip_SetContextInfo]
End
Print '**** Creating Stored Procedure dbo.ip_SetContextInfo...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create	procedure dbo.ip_SetContextInfo
	@pnUserIdentityId	int,
	@pnTransactionNo	int = null,
	@pnBatchNo		int = null,
	@pnOfficeId		int = null,
	@pnLogTimeOffset	int = null
AS
-- VERSION :		5
-- DESCRIPTION:		dbo.ip_SetContextInfo
-- SCOPE:		Inprotech
-- COPYRIGHT:		Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- --------	---	------	-------	-----------
-- 29/10/07	vql	15484	1	Procedure created
-- 14/11/07	vql	15593	2	Fixed syntax error added Go to end SP
-- 24 Jan 2008	mf	15865	3	Extend to store a time offset (minutes) that will be used in
--					log transactions and audit information.  The offset will be
--					belong to each site where a replicated system is being run
--					across multiple timezones.
-- 18/03/08	vql	15658	4	Make the @pnTransactionNo parameter non mandatory.
-- 19/03/08	vql	RFC5980	5	Default the Office Id and Offset if they are not passed in.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @bHexNumber			varbinary(128)
Declare @nErrorCode			int
Declare @sSQLString			nvarchar(4000)

Set @nErrorCode = 0

If @nErrorCode=0 and (@pnLogTimeOffset is null)
Begin
    -- Set the context_info after validation.
    Select @pnLogTimeOffset = COLINTEGER
    from SITECONTROL
    where CONTROLID = 'Log Time Offset'
    
    Set @nErrorCode = @@ERROR
End

If @nErrorCode=0 and (@pnOfficeId is null)
Begin
    Select @pnOfficeId = COLINTEGER
    from SITECONTROL
    where CONTROLID = 'Office For Replication'

    Set @nErrorCode = @@ERROR
End

-- Convert and set the hex number into the context_info area.
If @nErrorCode=0
Begin
	Set @bHexNumber=convert(varbinary(4), isnull(@pnUserIdentityId, ''))+
			convert(varbinary(4), isnull(@pnTransactionNo, ''))+
			convert(varbinary(4), isnull(@pnBatchNo, ''))+
			convert(varbinary(4), isnull(@pnOfficeId,''))+
			convert(varbinary(4), isnull(@pnLogTimeOffset,''))
	Set CONTEXT_INFO @bHexNumber
End
go

---	Grant appropriate rights
Grant exec on dbo.ip_SetContextInfo to Public
go