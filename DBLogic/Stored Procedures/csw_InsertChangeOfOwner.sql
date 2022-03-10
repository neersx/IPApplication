-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertChangeOfOwner
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertChangeOfOwner]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertChangeOfOwner.'
	Drop procedure [dbo].[csw_InsertChangeOfOwner]
End
Print '**** Creating Stored Procedure dbo.csw_InsertChangeOfOwner...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_InsertChangeOfOwner
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,
	@pnNameKey		int,
	@pnNameVariantKey	int		= null,
	@pnAddressKey		int		= null,
	@psNameTypeKey		nvarchar(3),
	@pdtLastModifiedDate	datetime

)
as
-- PROCEDURE:	csw_InsertChangeOfOwner
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Inserts an assignor(owner)/assignee(new owner) from an assignment recordal case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Aug 2011	KR	R7904	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare	@nSequenceNo	smallint

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "select  @nSequenceNo = isnull(max(SEQUENCE),0)
		from	CASENAME
		where	CASEID		= @pnCaseKey
		and	NAMETYPE	= @psNameTypeKey "
	
	exec @nErrorCode=sp_executesql @sSQLString,
	      	N'
		@pnCaseKey		int,
		@psNameTypeKey		nvarchar(3),
		@nSequenceNo		smallint OUTPUT',
		@pnCaseKey	= @pnCaseKey,
		@psNameTypeKey	= @psNameTypeKey,
		@nSequenceNo	= @nSequenceNo    OUTPUT		
		
End

If @nErrorCode = 0
Begin
	If @nSequenceNo > 0
		Set @nSequenceNo = @nSequenceNo + 1
End

If @nErrorCode = 0
Begin

	Set @sSQLString = "Insert into CASENAME
			   (
			   CASEID,
			   NAMETYPE,
			   NAMENO,
			   SEQUENCE,
			   ADDRESSCODE,
			   NAMEVARIANTNO)
			   Values
			   (@pnCaseKey,
			   @psNameTypeKey,
			   @pnNameKey,
			   @nSequenceNo,
			   @pnAddressKey,
			   @pnNameVariantKey )"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
			@pnCaseKey		int,
			@pnNameKey		int,
			@nSequenceNo		smallint,
			@psNameTypeKey		nvarchar(3),
			@pnAddressKey		int,
			@pnNameVariantKey	int',
			@pnCaseKey		= @pnCaseKey,
			@pnNameKey		= @pnNameKey,
			@nSequenceNo		= @nSequenceNo,
			@psNameTypeKey		= @psNameTypeKey,
			@pnAddressKey		= @pnAddressKey,
			@pnNameVariantKey	= @pnNameVariantKey 

End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertChangeOfOwner to public
GO