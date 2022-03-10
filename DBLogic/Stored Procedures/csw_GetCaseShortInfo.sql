-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetCaseShortInfo
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetCaseShortInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetCaseShortInfo.'
	Drop procedure [dbo].[csw_GetCaseShortInfo]
End
Print '**** Creating Stored Procedure dbo.csw_GetCaseShortInfo...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetCaseShortInfo
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_GetCaseShortInfo
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns case reference.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 NOV 2011	SF	R10553	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

-- Case result set
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  
	C.CASEID	as CaseKey,
	C.IRN 		as CaseReference,
	cast(isnull(CS.CRMONLY,0) as bit) as IsCRM,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0)+" as PropertyTypeDescription"+char(10)+
	"from CASES C WITH (NOLOCK)
	join CASETYPE CS on (CS.CASETYPE=C.CASETYPE)
	join COUNTRY CT on (CT.COUNTRYCODE=C.COUNTRYCODE)
	left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=C.PROPERTYTYPE
				and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
				from VALIDPROPERTY VP1
				where	VP1.PROPERTYTYPE=C.PROPERTYTYPE 
				and	VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
	left join PROPERTY P on (P.CASEID = C.CASEID)
	where C.CASEID = @pnCaseKey"

print @sSQLString
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey	int',
			          @pnCaseKey	= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetCaseShortInfo to public
GO
