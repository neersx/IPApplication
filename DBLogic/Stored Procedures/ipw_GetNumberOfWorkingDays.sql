-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetNumberOfWorkingDays									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetNumberOfWorkingDays]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetNumberOfWorkingDays.'
	Drop procedure [dbo].[ipw_GetNumberOfWorkingDays]
End
Print '**** Creating Stored Procedure dbo.ipw_GetNumberOfWorkingDays...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_GetNumberOfWorkingDays
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@psCountryCode 			nvarchar(3)	= null,
	@pnNumberOfWorkDays		tinyint		output
)
as
-- PROCEDURE:	ipw_GetNumberOfWorkingDays
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns, via the @pnNumberOfWorkDays output parameter, 
--		the number of working days in the @psCountryKey country, if specified,
--		or in the country that the HOMECOUNTRY site control points to.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 23 May 2006	IB	RFC3678	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variable
Set @nErrorCode 	= 0

If @nErrorCode=0
Begin
	Set @sSQLString = "Select @pnNumberOfWorkDays =
			(C.WORKDAYFLAG&1)/1 + (C.WORKDAYFLAG&2)/2 + (C.WORKDAYFLAG&4)/4 +
			(C.WORKDAYFLAG&8)/8 + (C.WORKDAYFLAG&16)/16 + (C.WORKDAYFLAG&32)/32 +
			(C.WORKDAYFLAG&64)/64
		from COUNTRY C
		left join SITECONTROL H on (H.CONTROLID='HOMECOUNTRY')
		where C.COUNTRYCODE = isnull(@psCountryCode, H.COLCHARACTER)"
	
	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCountryCode		nvarchar(3),
				  @pnNumberOfWorkDays		tinyint			output',
				  @psCountryCode		= @psCountryCode,
				  @pnNumberOfWorkDays 		= @pnNumberOfWorkDays	output
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetNumberOfWorkingDays to public
GO

