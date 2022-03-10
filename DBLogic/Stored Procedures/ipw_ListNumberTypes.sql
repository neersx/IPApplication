-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListNumberTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListNumberTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListNumberTypes.'
	Drop procedure [dbo].[ipw_ListNumberTypes]
	Print '**** Creating Stored Procedure dbo.ipw_ListNumberTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListNumberTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsExternalUser	bit		= null
)
AS
-- PROCEDURE:	ipw_ListNumberTypes
-- VERSION:	6
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Number Types that the currently logged on user
--		identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 08 Oct 2003  TM		1	Procedure created
-- 19-Feb-2004	TM	RFC976	2	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 09 Sep 2004	JEK	RFC886	3	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 15 May 2005  JEK	RFC2508	4	Pass @sLookupCulture to fn_FilterUserXxx.
-- 04 Dec 2006  PG	RFC3646	5	Pass @pbIsExternalUser to fn_FilterUserXxx.
-- 26 Aug 2009  PS  RFC8092 6   Add new parameter CaseKey, default value will be null. Add EventDate column in the result set. 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
If @nErrorCode = 0
Begin
	If @pbIsExternalUser is null
	Begin		
		Set @sSQLString='
		Select @pbIsExternalUser=ISEXTERNALUSER
		from USERIDENTITY
		where IDENTITYID=@pnUserIdentityId'
	
		Exec  @nErrorCode=sp_executesql @sSQLString,
					N'@pbIsExternalUser	bit	OUTPUT,
					  @pnUserIdentityId	int',
					  @pbIsExternalUser	=@pbIsExternalUser	OUTPUT,
					  @pnUserIdentityId	=@pnUserIdentityId
	End
End

If @nErrorCode = 0

Begin
	Set @sSQLString = "
	Select 	NUMBERTYPE 	as 'NumberTypeKey',
		DESCRIPTION	as 'NumberTypeDescription',
		EVENTDATE  as 'EventDate'
	from	dbo.fn_FilterUserNumberTypes(@pnUserIdentityId,@sLookupCulture, @pbIsExternalUser,@pbCalledFromCentura)  NT
	LEFT JOIN CASEEVENT CE on (NT.RELATEDEVENTNO = CE.EVENTNO and CE.CASEID = @pnCaseKey and CE.CYCLE =1)
	order by DESCRIPTION"
		
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @sLookupCulture	nvarchar(10),
					  @pbIsExternalUser     bit,
					  @pbCalledFromCentura	bit,
					  @pnCaseKey int',
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbIsExternalUser	= @pbIsExternalUser,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @pnCaseKey = @pnCaseKey
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListNumberTypes to public
GO
