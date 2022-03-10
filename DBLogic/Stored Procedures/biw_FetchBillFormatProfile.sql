-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_FetchBillFormatProfileData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_FetchBillFormatProfileData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_FetchBillFormatProfileData.'
	Drop procedure [dbo].[biw_FetchBillFormatProfileData]
End
Print '**** Creating Stored Procedure dbo.biw_FetchBillFormatProfileData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_FetchBillFormatProfileData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnFormatProfileKey		int,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	biw_FetchBillFormatProfileData
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the details of a specific bill format profile

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Jul 2010	LP		RFC9289	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(2000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
			select
			cast(FORMATID as int)	as 'FormatProfileKey',
			FORMATDESC		as 'FormatProfileDescription',
			CONSOLIDATIONFLAG as 'IsConsolidated',
			SINGLEDISCOUNT	as 'IsSingleDiscount',
			PRESENTATIONID	as 'PresentationKey',
			WEBSERVICE		as 'WebService',
			LOGDATETIMESTAMP as 'LogDateTimeStamp'	
			from FORMATPROFILE
			where FORMATID = @pnFormatProfileKey"
			
	exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnFormatProfileKey int',
						@pnFormatProfileKey = @pnFormatProfileKey
End

Return @nErrorCode
GO

Grant execute on dbo.biw_FetchBillFormatProfileData to public
GO
