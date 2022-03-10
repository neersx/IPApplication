-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_IsNameOfficeRequired
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_IsNameOfficeRequired]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_IsNameOfficeRequired.'
	Drop procedure [dbo].[naw_IsNameOfficeRequired]
End
Print '**** Creating Stored Procedure dbo.naw_IsNameOfficeRequired...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_IsNameOfficeRequired
(
	@pbYes				bit		= null output,	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		 = 0
)
as
-- PROCEDURE:	naw_IsNameOfficeRequired
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Check to see if Office is required for Names via Row Access Security
--		Used to determine if user must have ability to enter Office during Name Creation

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Oct 2011	LP	R11327	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @pbYes = 0
	Set @sSQLString ="
	Select @pbYes = 1
	from ROWACCESSDETAIL R WITH (NOLOCK) 
	join IDENTITYROWACCESS I WITH (NOLOCK) on (R.ACCESSNAME = I.ACCESSNAME) 
	where R.RECORDTYPE = 'N'
	and R.OFFICE IS NOT NULL
	and I.IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pbYes 		bit	output,
				  @pnUserIdentityId	int', 
				  @pbYes		= @pbYes output,
			 	  @pnUserIdentityId	= @pnUserIdentityId

	
End


If @nErrorCode = 0
and @pbCalledFromCentura = 0
Begin
	-- publish to .net dataaccess
	Select isnull(@pbYes,0)
End

Return @nErrorCode
GO

Grant execute on dbo.naw_IsNameOfficeRequired to public
GO
