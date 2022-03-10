-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_GetLicenseData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetLicenseData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	 Print '**** Drop Stored Procedure dbo.ip_GetLicenseData.'
	 Drop procedure [dbo].[ip_GetLicenseData]
End
Print '**** Creating Stored Procedure dbo.ip_GetLicenseData...'
Print ''
go

CREATE PROCEDURE dbo.ip_GetLicenseData
(
	-- Standard parameters
	@pnUserIdentityId		int,
	@psCulture			nvarchar(10) 	= null,

	@pbCalledFromCentura 		bit 		= 0,
	@pnModuleId			int		= null,

	-- Output parameters (for .net)
	@psFirmName 			nvarchar(210) 	= null output,
	@pnMaxCases 			int 		= null output,
	@pnPricingModel 		smallint 	= null output,
	@pnModuleUsers 			int 		= null output,
	@dtExpiryDate	 		datetime	= null output,
	@bExpiryAction			bit		= null output,
	@nExpiryWarningDays		int		= null output

)
With encryption
AS
-- PROCEDURE :	ip_GetLicenseData
-- VERSION :	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns all the information about the license
-- NOTES:	To get module specific data pass the ModuleId
--		To get firm-wide data do not pass the ModuleId
--
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21/04/2004	JB		1	Procedure created
-- 18/08/2004	VL		2	LICENSE table to nvarchar(254).
-- 31/08/2004	TM	RFC1516	3	Obtain the license information using fn_LicsensData. 
-- 16/09/2004	VL		4	do not return PRICINGMODEL when returning information
--					regardless of module as it module specific.
-- 29/06/2006	vql	11588	5	Create three extra column on temp table for expiry date information.

Set concat_null_yields_null off

Declare @nReturn 		int
Declare @sSQLString 		nvarchar(4000)
Declare @nErrorCode		int

Declare @bIsModulelisenced	bit

Set @nErrorCode			= 0
Set @nReturn 			= 0
Set @bIsModulelisenced 		= 0	-- Set to 1 if the passed @pnModuleId is licensed

-- Get the information for the passed parameters and set @bIsModulelisenced flag to 1
-- if the @pnModuleId is licensed:
If @nErrorCode = 0 
and @pnModuleId is not null
Begin
	Set @sSQLString = 
	'Select	@pnPricingModel 	= PRICINGMODEL,
		@pnMaxCases 		= MAXCASES,
		@pnModuleUsers		= MODULEUSERS,
		@psFirmName 		= FIRMNAME,
		@dtExpiryDate	 	= EXPIRYDATE,
		@bExpiryAction		= EXPIRYACTION,
		@nExpiryWarningDays	= EXPIRYWARNINGDAYS,
		@bIsModulelisenced 	= 1
	from dbo.fn_LicenseData() 
	where MODULEID = @pnModuleId'

	Exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnPricingModel 	smallint 		OUTPUT,
					@pnMaxCases		int			OUTPUT,
					@pnModuleUsers		int			OUTPUT,
					@psFirmName		nvarchar(210)		OUTPUT,
					@dtExpiryDate	 	datetime		OUTPUT,
					@bExpiryAction		bit			OUTPUT,
					@nExpiryWarningDays	int			OUTPUT,
					@bIsModulelisenced	bit			OUTPUT,
					@pnModuleId		int',
					@pnPricingModel 	= @pnPricingModel 	OUTPUT,
					@pnMaxCases		= @pnMaxCases		OUTPUT,
					@pnModuleUsers		= @pnModuleUsers	OUTPUT,
					@psFirmName		= @psFirmName		OUTPUT,
					@dtExpiryDate	 	= @dtExpiryDate		OUTPUT,
					@bExpiryAction		= @bExpiryAction	OUTPUT,
					@nExpiryWarningDays	= @nExpiryWarningDays	OUTPUT,
					@bIsModulelisenced	= @bIsModulelisenced	OUTPUT,
					@pnModuleId		= @pnModuleId
End

-- If the @pnModuleId is not provided or if the provided module is not licensed then
-- only get information that is independent on the ModuleId:
If @nErrorCode = 0 
and (@pnModuleId is null  
 or  @bIsModulelisenced = 0)
Begin
	-- We give them the information that is available regardless of ModuleId
	Set @sSQLString = 
	'Select	@pnMaxCases 	= MAXCASES,
		@psFirmName 	= FIRMNAME
	from dbo.fn_LicenseData()'
	
	Exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnMaxCases		int			OUTPUT,
					@psFirmName		nvarchar(210)		OUTPUT',
					@pnMaxCases		= @pnMaxCases		OUTPUT,
					@psFirmName		= @psFirmName		OUTPUT
End

If @nErrorCode = 0 
and @pbCalledFromCentura = 1
Begin
	Set @sSQLString = '
		Select 	@psFirmName as FIRMNAME, 
			@pnPricingModel as PRICINGMODEL,
			@pnMaxCases as MAXCASES,
			@pnModuleUsers as MODULEUSERS'

	Exec @nErrorCode = sp_executesql @sSQLString,
				      N'@psFirmName	nvarchar(210) OUTPUT,
					@pnPricingModel	smallint OUTPUT,
					@pnMaxCases	int OUTPUT,
					@pnModuleUsers	int OUTPUT',
					@psFirmName		=@psFirmName OUTPUT,
					@pnPricingModel 	=@pnPricingModel OUTPUT,
					@pnMaxCases		=@pnMaxCases OUTPUT,
					@pnModuleUsers		=@pnModuleUsers OUTPUT

End

Return @nReturn
GO

Grant execute on dbo.ip_GetLicenseData to public
GO