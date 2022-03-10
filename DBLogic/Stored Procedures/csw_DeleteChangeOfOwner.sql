-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteChangeOfOwner
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteChangeOfOwner]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteChangeOfOwner.'
	Drop procedure [dbo].[csw_DeleteChangeOfOwner]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteChangeOfOwner...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_DeleteChangeOfOwner
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,
	@pnNameKey		int,
	@pnSequenceNo		int		= null,
	@pnNameVariantKey	int		= null,		
	@pbIsAssignor		bit,
	@pdtLastModifiedDate	datetime	= null

)
as
-- PROCEDURE:	csw_DeleteChangeOfOwner
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Deletes an assignor(owner)/assignee(new owner) from an assignment recordal case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Aug 2011	KR	R7904	1	Procedure created
-- 29 Sep 2011	KR	R7904	2	null check is added to LOGDATETIMESTAMP

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sNameTypeKey	nvarchar(3)

-- Initialise variables
Set @nErrorCode = 0
If @nErrorCode = 0
Begin
	If @pbIsAssignor = 1
		Set @sNameTypeKey = 'O'
	Else
		Set @sNameTypeKey = 'ON'
End

If @nErrorCode = 0
Begin

	Set @sSQLString = "DELETE CASENAME
		where	CASEID	= @pnCaseKey
		and	NAMENO	= @pnNameKey
		and	NAMETYPE = @sNameTypeKey
		and	SEQUENCE = @pnSequenceNo
		and	(LOGDATETIMESTAMP is null or LOGDATETIMESTAMP = @pdtLastModifiedDate)"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnCaseKey		int,
		@pnNameKey		int,
		@pnSequenceNo		int,
		@sNameTypeKey		nvarchar(3),
		@pdtLastModifiedDate	datetime',
		@pnCaseKey		= @pnCaseKey,
		@pnNameKey		= @pnNameKey,
		@pnSequenceNo		= @pnSequenceNo,
		@sNameTypeKey		= @sNameTypeKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteChangeOfOwner to public
GO