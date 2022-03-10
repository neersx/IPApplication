-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListValidStatus
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListValidStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop Stored Procedure dbo.ipw_ListValidStatus.'
	drop procedure [dbo].[ipw_ListValidStatus]
	print '**** Creating Stored Procedure dbo.ipw_ListValidStatus...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListValidStatus
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsRenewal 		bit		= null
)
AS
-- PROCEDURE:	csw_ListCaseHeader
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns a list of Valid Statuses.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Dec 2005	TM	RFC3255	1	Procedure created
-- 16 Jan 2015	MS	R41437	2	Added ConfirmationRequired in select

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(1000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set 	@sLookupCulture  = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  V.STATUSCODE 	as StatusKey,
		CASE 	WHEN UI.ISEXTERNALUSER=1 
			THEN	"+dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+"
			ELSE	"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+"
		END		as StatusDescription,
		V.COUNTRYCODE 	as CountryKey,
		CASE 	WHEN COUNTRYCODE = 'ZZZ' 
			THEN cast(1 as bit)
			ELSE cast(0 as bit) 
		END 		as IsDefaultCountry,
		V.PROPERTYTYPE 	as PropertyTypeKey,
		V.CASETYPE 	as CaseTypeKey,
		S.CONFIRMATIONREQ as 'ConfirmationRequired'
	from	VALIDSTATUS V
	join	STATUS S on (V.STATUSCODE = S.STATUSCODE)
	join	USERIDENTITY UI on (UI.IDENTITYID = @pnUserIdentityId)"+
	CASE 	WHEN @pbIsRenewal is not null
		THEN char(10)+"where   S.RENEWALFLAG = @pbIsRenewal"
	END+char(10)+
	"order by StatusDescription"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @pbIsRenewal		bit',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @pbIsRenewal		= @pbIsRenewal
	
	Set @pnRowCount = @@Rowcount	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListValidStatus to public
GO
