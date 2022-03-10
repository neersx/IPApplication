-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_ListCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_ListCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_ListCases.'
	Drop procedure [dbo].[prw_ListCases]
End
Print '**** Creating Stored Procedure dbo.prw_ListCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_ListCases
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psFamilyCode		nvarchar(9) 	= null,
	@pnCaseListKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	prw_ListCases
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Cases of a Family or a Case List

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 11 Apr 2011	JC	RFC6563	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	Set @sSQLString = "Select
	C.CASEID		as CaseKey,
	C.IRN			as CaseReference,
	C.CURRENTOFFICIALNO	as CurrentOfficialNumber,
	"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)
		+ " as CountryName
	from CASES C
	left join COUNTRY CT	on (CT.COUNTRYCODE = C.COUNTRYCODE)"
	
	if @psFamilyCode is not null
	Begin
		Set @sSQLString = @sSQLString + " where C.FAMILY = @psFamilyCode"
	End
	Else If @pnCaseListKey is not null
	Begin
		Set @sSQLString = @sSQLString + " join CASELISTMEMBER CL on (CL.CASEID = C.CASEID and CL.CASELISTNO = @pnCaseListKey)"
	End
	
	Set @sSQLString = @sSQLString + " order by C.IRN"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura	bit,
			@psFamilyCode		nvarchar(9),
			@pnCaseListKey		int',
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@psFamilyCode		= @psFamilyCode,
			@pnCaseListKey		= @pnCaseListKey

End

Return @nErrorCode
GO

Grant execute on dbo.prw_ListCases to public
GO