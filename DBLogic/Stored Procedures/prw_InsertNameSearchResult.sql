-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_InsertNameSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_InsertNameSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_InsertNameSearchResult.'
	Drop procedure [dbo].[prw_InsertNameSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_InsertNameSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_InsertNameSearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int,
	@pnNameKey		int,
	@psNameTypeCode		nvarchar(3) 	= null,
	@pdtLastModifiedDate	datetime	= null	OUTPUT

)
as
-- PROCEDURE:	prw_InsertNameSearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert a Name Search Result

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 2 Mar 2011	JC		RFC6563	1		Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "Insert into NAMESEARCHRESULT
			(PRIORARTID,
			 NAMENO,
			 NAMETYPE)
		values (
			@pnPriorArtKey,
			@pnNameKey,
			@psNameTypeCode)

		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	NAMESEARCHRESULT
		where	PRIORARTID	= @pnPriorArtKey
		and	NAMENO		= @pnNameKey			
		"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey		int,
		@pnNameKey		int,
		@psNameTypeCode		nvarchar(3),
		@pdtLastModifiedDate	datetime output',
		@pnPriorArtKey		= @pnPriorArtKey,
		@pnNameKey		= @pnNameKey,
		@psNameTypeCode		= @psNameTypeCode,
		@pdtLastModifiedDate	= @pdtLastModifiedDate OUTPUT

	Select @pdtLastModifiedDate		as LastModifiedDate
End

Return @nErrorCode
GO

Grant execute on dbo.prw_InsertNameSearchResult to public
GO