-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_InsertFamilySearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_InsertFamilySearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_InsertFamilySearchResult.'
	Drop procedure [dbo].[prw_InsertFamilySearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_InsertFamilySearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_InsertFamilySearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int,
	@psFamilyCode		nvarchar(20),
	@pdtLastModifiedDate	datetime	= null	OUTPUT
)
as
-- PROCEDURE:	prw_InsertFamilySearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert a Family Search Result

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 2 Mar 2011	JC	RFC6563	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "Insert into FAMILYSEARCHRESULT
			(PRIORARTID,
			 FAMILY)
		values (
			@pnPriorArtKey,
			@psFamilyCode)
			
		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	FAMILYSEARCHRESULT
		where	PRIORARTID	= @pnPriorArtKey
		and	FAMILY		= @psFamilyCode
		"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey		int,
		@psFamilyCode		nvarchar(30),
		@pdtLastModifiedDate	datetime output',
		@pnPriorArtKey		= @pnPriorArtKey,
		@psFamilyCode		= @psFamilyCode,
		@pdtLastModifiedDate	= @pdtLastModifiedDate output

	Select @pdtLastModifiedDate		as LastModifiedDate
		

End

Return @nErrorCode
GO

Grant execute on dbo.prw_InsertFamilySearchResult to public
GO