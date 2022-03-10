-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ListBillFormatProfiles
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListBillFormatProfiles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListBillFormatProfiles.'
	Drop procedure [dbo].[biw_ListBillFormatProfiles]
	Print '**** Creating Stored Procedure dbo.biw_ListBillFormatProfiles...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ListBillFormatProfiles
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	biw_ListBillFormatProfiles
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of available bill format profiles.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 22 Jan 2010	LP	R8203	1	Procedure created.
-- 21 Dec 2015	MF	R56315	2	Return the list of Bill Forma Profiles in description order. 


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(1000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "
			select
			cast(FORMATID as int)	as 'FormatProfileKey',
			FORMATDESC		as 'FormatProfileDescription',
			CONSOLIDATIONFLAG	as 'IsConsolidated',
			SINGLEDISCOUNT		as 'IsSingleDiscount',
			PRESENTATIONID		as 'PresentationKey',
			WEBSERVICE		as 'WebService',
			LOGDATETIMESTAMP	as 'LogDateTimeStamp'			
			from FORMATPROFILE
			order by 2"

	exec @nErrorCode = sp_executesql @sSQLString

End
Return @nErrorCode
GO

Grant execute on dbo.biw_ListBillFormatProfiles to public
GO
