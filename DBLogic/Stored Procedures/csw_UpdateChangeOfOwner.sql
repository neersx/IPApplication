-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateChangeOfOwner
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateChangeOfOwner]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateChangeOfOwner.'
	Drop procedure [dbo].[csw_UpdateChangeOfOwner]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateChangeOfOwner...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_UpdateChangeOfOwner
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,
	@pnNameKey		int,
	@pnSequenceNo		smallint,
	@pnNameVariantKey	int		= null,
	@pnAddressKey		int		= null,
	@pbIsAssignor		bit,
	@pdtLastModifiedDate	datetime	= null OUTPUT

)
as
-- PROCEDURE:	csw_UpdateChangeOfOwner
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Updates an assignor(owner)/assignee(new owner) from an assignment recordal case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Aug 2011	KR	R7904	1	Procedure created
-- 04 Nov 2011	KR	R11308	2	Make @pdtLastModifiedDate as output parameter
-- 09 Nov 2011	KR	R11308	3	Add NameKey to the where clause

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

	Set @sSQLString = "Update CASENAME
			   Set ADDRESSCODE = @pnAddressKey
			   Where CASEID = @pnCaseKey
			   and	 NAMENO = @pnNameKey
			   and	 NAMETYPE = @sNameTypeKey
			   and	 SEQUENCE = @pnSequenceNo			   
			   and	 LOGDATETIMESTAMP = @pdtLastModifiedDate
			   
			Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
			From	CASENAME
			Where	CASEID = @pnCaseKey
			and	NAMENO = @pnNameKey
			and	NAMETYPE = @sNameTypeKey
			and	SEQUENCE = @pnSequenceNo"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
			@pnCaseKey		int,
			@pnNameKey		int,
			@pnSequenceNo		smallint,
			@sNameTypeKey		nvarchar(3),
			@pnAddressKey		int,
			@pnNameVariantKey	int,
			@pdtLastModifiedDate	datetime output',
			@pnCaseKey		= @pnCaseKey,
			@pnNameKey		= @pnNameKey,
			@pnSequenceNo		= @pnSequenceNo,
			@sNameTypeKey		= @sNameTypeKey,
			@pnAddressKey		= @pnAddressKey,
			@pnNameVariantKey	= @pnNameVariantKey,
			@pdtLastModifiedDate	= @pdtLastModifiedDate OUTPUT

End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateChangeOfOwner to public
GO