-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DefaultPurchaseOrderNoFromInstructor
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DefaultPurchaseOrderNoFromInstructor]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DefaultPurchaseOrderNoFromInstructor.'
	Drop procedure [dbo].[csw_DefaultPurchaseOrderNoFromInstructor]
End
Print '**** Creating Stored Procedure dbo.csw_DefaultPurchaseOrderNoFromInstructor...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_DefaultPurchaseOrderNoFromInstructor
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey				int,		-- Mandatory
	@pnInstructorNameKey	int			-- Mandatory
)
as
-- PROCEDURE:	csw_DefaultPurchaseOrderNoFromInstructor
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Default Purchase Order Number from Instructor if it is recorded against the Name.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Mar 2008	SF		RFC6297	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		update CASES
			set CASES.PURCHASEORDERNO = IP.PURCHASEORDERNO
		from CASES 
		join NAME N on (N.NAMENO = @pnInstructorNameKey)
		join IPNAME IP on (N.NAMENO = IP.NAMENO)
		join CASENAME CN on (CN.CASEID = CASES.CASEID and CN.NAMENO = N.NAMENO and CN.NAMETYPE = 'I')
		where CASES.CASEID = @pnCaseKey"
	
	Exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnCaseKey				int,
						@pnInstructorNameKey		int',
						@pnCaseKey					= @pnCaseKey,
						@pnInstructorNameKey		= @pnInstructorNameKey
End


Return @nErrorCode
GO

Grant execute on dbo.csw_DefaultPurchaseOrderNoFromInstructor to public
GO
