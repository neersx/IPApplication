-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListRowAccessProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListRowAccessProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListRowAccessProfile.'
	Drop procedure [dbo].[ipw_ListRowAccessProfile]
	Print '**** Creating Stored Procedure dbo.ipw_ListRowAccessProfile...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [dbo].[ipw_ListRowAccessProfile]
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListRowAccessProfile
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return a list of available Row Access Profiles.

-- MODIFICATIONS :
-- Date		Who	Change	 Version Description
-- -----------	-------	-------- ------- ----------------------------------------------- 
-- 23 Oct 2009	LP	RFC6712	 1	 Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	SELECT 
	dbo.fn_StripNonAlphaNumerics(ACCESSNAME) as RowAccessKey,
	ACCESSNAME as RowAccessName,
	ACCESSDESC as RowAccessDescription
	from ROWACCESS
	
	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListRowAccessProfile to public
GO
