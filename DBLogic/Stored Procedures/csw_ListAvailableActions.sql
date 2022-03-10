-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListAvailableActions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListAvailableActions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListAvailableActions.'
	Drop procedure [dbo].[csw_ListAvailableActions]
End
Print '**** Creating Stored Procedure dbo.csw_ListAvailableActions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListAvailableActions
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,
	@pnImportanceLevel		int		= null	-- the Action importance level, if null then default for user will be found.
)
as
-- PROCEDURE:	csw_ListAvailableActions
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates CaseActionData dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Oct 2008	SF	R3392	1	Procedure created
-- 22 Oct 2008	SF	R3392	2	Cater for fallback logic - default country
-- 23 Jul 2010	DV	R9532	3	Order the Actions on the basis of Action Name
-- 08 Nov 2011	MF	R11397	4	Only show Actions whose IMPORTANCELEVEL is greater than or equal to that of the user.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

---------------------------------------
-- Now get the importance level used
-- to determine which Actions should be
-- displayed.
---------------------------------------
If  @nErrorCode=0
and @pnImportanceLevel is null
Begin
        Set @sSQLString = "
		select @pnImportanceLevel = isnull(convert(int,PA.ATTRIBUTEVALUE),isnull(S.COLINTEGER,0))
		from USERIDENTITY U
		left join SITECONTROL S		on (S.CONTROLID=CASE WHEN(U.ISEXTERNALUSER=1) THEN 'Client Importance' ELSE 'Events Displayed' END )
		left join PROFILEATTRIBUTES PA	on (PA.PROFILEID = U.PROFILEID 
						and PA.ATTRIBUTEID = 1)
		where U.IDENTITYID = @pnUserIdentityId"

        exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnImportanceLevel	int	OUTPUT,
				  @pnUserIdentityId	int',
				  @pnImportanceLevel	= @pnImportanceLevel	OUTPUT,
				  @pnUserIdentityId	= @pnUserIdentityId
End

If @nErrorCode = 0
Begin

	Set @sSQLString = "
	Select distinct
		VA.ACTION		as ActionKey,
		"+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'VA',@sLookupCulture,@pbCalledFromCentura)+
		"		as ActionName
	from VALIDACTION VA
	join ACTIONS A	on (A.ACTION = VA.ACTION
			and A.IMPORTANCELEVEL>=@pnImportanceLevel)
	join CASES C	on (C.CASETYPE = VA.CASETYPE 
			and C.PROPERTYTYPE = VA.PROPERTYTYPE
			and C.COUNTRYCODE = VA.COUNTRYCODE)
	left join OPENACTION OA	on (OA.CASEID = C.CASEID
				and OA.ACTION = VA.ACTION)
	where C.CASEID = @pnCaseKey
	and OA.ACTION is null
	union
	Select distinct
		VA.ACTION		as ActionKey,
		"+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'VA',@sLookupCulture,@pbCalledFromCentura)+
		"		as ActionName
	from VALIDACTION VA
	join ACTIONS A	on (A.ACTION = VA.ACTION
			and A.IMPORTANCELEVEL>=@pnImportanceLevel)
	join CASES C	on (C.CASETYPE = VA.CASETYPE 
			and C.PROPERTYTYPE = VA.PROPERTYTYPE)
	left join OPENACTION OA on (OA.CASEID = C.CASEID
				and OA.ACTION = VA.ACTION)
	where VA.COUNTRYCODE = 'ZZZ'
	and C.CASEID = @pnCaseKey
	and OA.ACTION is null
	and not exists (	Select	distinct VA.ACTION
				from	VALIDACTION VA
				join	CASES C on (C.CASETYPE = VA.CASETYPE 
						and C.PROPERTYTYPE = VA.PROPERTYTYPE
						and C.COUNTRYCODE = VA.COUNTRYCODE)
				left join OPENACTION OA on (OA.CASEID = C.CASEID
							and OA.ACTION = VA.ACTION)
				where C.CASEID = @pnCaseKey
				and OA.ACTION is null)
	order by 2
	"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey		int,
				  @pnImportanceLevel	int',
				  @pnCaseKey		= @pnCaseKey,
				  @pnImportanceLevel	= @pnImportanceLevel

End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListAvailableActions to public
GO
