-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeriveCaseLocalClient
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeriveCaseLocalClient]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeriveCaseLocalClient.'
	Drop procedure [dbo].[csw_DeriveCaseLocalClient]
End
Print '**** Creating Stored Procedure dbo.csw_DeriveCaseLocalClient...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_DeriveCaseLocalClient
(
	@pbIsLocalClient	bit		= null output,	-- Indicates whether the case should be treated as local.
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		= null,		-- The Case that the information is required for. If not provided, the @pnInstructorKey must be provided.
	@pnInstructorKey	int		= null		-- The Instructor for which the information is required.
)
as
-- PROCEDURE:	csw_DeriveCaseLocalClient
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Determines whether the case is expected to be local based on the Instructor.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Dec 2005	AP	RFC3200	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If  @nErrorCode = 0
and @pnInstructorKey is not null
Begin
	Set @sSQLString = "
	Select @pbIsLocalClient = COALESCE(IP.LOCALCLIENTFLAG, 
					   CASE WHEN SC.COLCHARACTER = A.COUNTRYCODE
						THEN 1 
						ELSE 0 
					   END,					 
					   1)   -- Default to true
	from NAME N
	left join IPNAME IP		on (IP.NAMENO = N.NAMENO)
	left join ADDRESS A		on (A.ADDRESSCODE = N.POSTALADDRESS)
	left join SITECONTROL SC	on (SC.CONTROLID = 'HOMECOUNTRY')
	where N.NAMENO = @pnInstructorKey"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pbIsLocalClient	bit			OUTPUT,
					  @pnInstructorKey	int',
					  @pbIsLocalClient	= @pbIsLocalClient	OUTPUT,
					  @pnInstructorKey	= @pnInstructorKey
End
Else If  @nErrorCode = 0
     and @pnCaseKey is not null
Begin
	Set @sSQLString = "
	Select @pbIsLocalClient = COALESCE(IP.LOCALCLIENTFLAG, 
					   CASE WHEN SC.COLCHARACTER = A.COUNTRYCODE
						THEN 1 
						ELSE 0 
					   END,					 
					   1)   -- Default to true
	from CASENAME CN
	join NAME N			on (CN.NAMENO = N.NAMENO)
	left join IPNAME IP		on (IP.NAMENO = N.NAMENO)
	left join ADDRESS A		on (A.ADDRESSCODE = N.POSTALADDRESS)
	left join SITECONTROL SC	on (SC.CONTROLID = 'HOMECOUNTRY')
	where CN.CASEID = @pnCaseKey
	and   CN.NAMETYPE = N'I'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pbIsLocalClient	bit			OUTPUT,
					  @pnCaseKey		int',
					  @pbIsLocalClient	= @pbIsLocalClient	OUTPUT,
					  @pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeriveCaseLocalClient to public
GO
