-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseListCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseListCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseListCases.'
	Drop procedure [dbo].[csw_ListCaseListCases]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseListCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseListCases
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseListKey		int			-- Mandatory
)
as
-- PROCEDURE:	csw_ListCaseListCases
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List Cases linked to a particular Case List

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 MAR 2011	KR		RFC6563	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  CL.CASELISTNO 	as CaseListKey,
			CL.CASEID		as CaseKey,
			C.IRN			as CaseReference,
			C.CURRENTOFFICIALNO as CurrentOfficialNumber,
			CO.COUNTRY			as CountryName,
			cast(isnull(CL.PRIMECASE,0) as bit)	as IsPrimeCase,
			CL.LOGDATETIMESTAMP as LastModifiedDate
	from CASELISTMEMBER CL
	Join CASES C on (C.CASEID = CL.CASEID)
	Join COUNTRY CO on (C.COUNTRYCODE = CO.COUNTRYCODE)
	Where CASELISTNO = @pnCaseListKey
	order by 1"


	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCaseListKey		int',
			@pnCaseListKey		= @pnCaseListKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseListCases to public
GO
