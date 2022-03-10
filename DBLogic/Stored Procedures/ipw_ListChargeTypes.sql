-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListChargeTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListChargeTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListChargeTypes.'
	Drop procedure [dbo].[ipw_ListChargeTypes]
End
Print '**** Creating Stored Procedure dbo.ipw_ListChargeTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_ListChargeTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,
	@pbIsExternalUser	bit		= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListChargeTypes
-- VERSION:	5
-- DESCRIPTION:	Returns a list of Charge Types.
-- COPYRIGHT:Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2006  JEK	RFC3218	1	Procedure created
-- 14 Dec 2006	JEK	RFC3218	2	Implement fn_FilterUserChargeTypes.
-- 20 Nov 2008	MF	RFC7316	3	Allow CaseId to be optionally passed as parameter.  If a value is passed
--					then restrict the ChargeTypes displayed to only those that a valid for
--					the characteristics of the Case.
-- 07 Jul 2016	MF	63861	4	A null LOCALCLIENTFLAG should default to 0.
-- 29 May 2017	MF	71325	5	When determining the Renewal Charge Type, we need to determine if the Case is granted or not.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)
Declare @sDerivedTable	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @sRenewalFees	nvarchar(254)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set 	@sLookupCulture  = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Determine if the user is internal or external
If @nErrorCode=0
and @pbIsExternalUser is null
Begin		
	Set @sSQLString="
	Select	@pbIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@pbIsExternalUser		bit	OUTPUT,
				  @pnUserIdentityId		int',
				  @pbIsExternalUser=@pbIsExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId
End

If @nErrorCode = 0
Begin
	---------------------------------------------------
	-- If the Case is not marked as Registered then
	-- get the possible Renewl Fee charge types from
	-- the sitecontrol "Renew Fee Pre Grant" if exists
	-- otherwise use sitecontrol "Renew Fee".
	---------------------------------------------------
	Set @sSQLString = "
	Select 	@sRenewalFees=CASE WHEN(ST.REGISTEREDFLAG=1) 
					THEN S1.COLCHARACTER
					ELSE coalesce(S2.COLCHARACTER, S1.COLCHARACTER)
			      END
	from	CASES CS
	left join STATUS ST	 on (ST.STATUSCODE=CS.STATUSCODE)
	left join SITECONTROL S1 on (S1.CONTROLID ='Renewal Fee')
	left join SITECONTROL S2 on (S2.CONTROLID ='Renew Fee Pre Grant')
	Where CS.CASEID=@pnCaseKey"
 
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@sRenewalFees		nvarchar(254)	OUTPUT,
			  @pnCaseKey		int',					
			  @sRenewalFees		= @sRenewalFees	OUTPUT,
			  @pnCaseKey		= @pnCaseKey

End

If @pnCaseKey is not null
Begin
	Set @sDerivedTable="
	join (	select distinct CH.CHARGETYPENO
		from CASES C
		join CASETYPE CT	on ( CT.CASETYPE=C.CASETYPE)
		join CRITERIA CR	on ( CR.PURPOSECODE='F'
					and  CR.RULEINUSE=1
					and (CR.CASETYPE in (CT.CASETYPE,CT.ACTUALCASETYPE) OR CR.CASETYPE is null)
					and (CR.PROPERTYTYPE   =C.PROPERTYTYPE    OR CR.PROPERTYTYPE    is NULL)
					and (CR.COUNTRYCODE    =C.COUNTRYCODE     OR CR.COUNTRYCODE     is NULL)
					and (CR.CASECATEGORY   =C.CASECATEGORY    OR CR.CASECATEGORY    is NULL)
					and (CR.SUBTYPE        =C.SUBTYPE         OR CR.SUBTYPE         is NULL)
					and (CR.TYPEOFMARK     =C.TYPEOFMARK      OR CR.TYPEOFMARK      is NULL)
					and (CR.TABLECODE      =C.ENTITYSIZE      OR CR.TABLECODE       is NULL)
					and (CR.LOCALCLIENTFLAG=isnull(C.LOCALCLIENTFLAG,0) 
										  OR CR.LOCALCLIENTFLAG is NULL))
		join CHARGERATES CG	on ( CG.RATENO=CR.RATENO
					and (CG.CASETYPE in (CT.CASETYPE,CT.ACTUALCASETYPE) OR CG.CASETYPE is null)
					and (CG.PROPERTYTYPE   =C.PROPERTYTYPE    OR CG.PROPERTYTYPE   is NULL)
					and (CG.COUNTRYCODE    =C.COUNTRYCODE     OR CG.COUNTRYCODE    is NULL)
					and (CG.CASECATEGORY   =C.CASECATEGORY    OR CG.CASECATEGORY   is NULL)
					and (CG.SUBTYPE        =C.SUBTYPE         OR CG.SUBTYPE        is NULL))
		join CHARGETYPE CH	on ( CH.CHARGETYPENO=CG.CHARGETYPENO)
		where C.CASEID=@pnCaseKey) CT on (CT.CHARGETYPENO=C.CHARGETYPENO)"
End


If  @nErrorCode = 0
and @pbIsExternalUser = 0
Begin
	Set @sSQLString = "
	Select 	C.CHARGETYPENO	as ChargeTypeKey,
		"+dbo.fn_SqlTranslatedColumn('CHARGETYPE','CHARGEDESC',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as ChargeTypeDescription,
		case when D.ChargeKey is null
			then cast(0 as bit)
			else cast(1 as bit)
			end	as 'IsDefault'
	from 	CHARGETYPE C"
	
	If @pnCaseKey is not null
		Set @sSQLString=@sSQLString+@sDerivedTable
		
	Set @sSQLString=@sSQLString+"
	-- Find the minimum charge type key from the comma separated list
	left join (select min(T.NumericParameter) as ChargeKey
		   from dbo.fn_Tokenise(N'"+@sRenewalFees+"',',') T
		   ) D on (D.ChargeKey=C.CHARGETYPENO)
	order by ChargeTypeDescription"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey		int',
				  @pnCaseKey		= @pnCaseKey

	Set @pnRowCount = @@Rowcount	
End
Else If  @nErrorCode = 0
     and @pbIsExternalUser = 1
Begin	
	Set @sSQLString = "
	Select 	C.CHARGETYPENO	as ChargeTypeKey,
		C.CHARGEDESC	as ChargeTypeDescription,
		case when D.ChargeKey is null
			then cast(0 as bit)
			else cast(1 as bit)
			end	as 'IsDefault'
	from 	dbo.fn_FilterUserChargeTypes(@pnUserIdentityId,1,@sLookupCulture,@pbCalledFromCentura) C"
	
	If @pnCaseKey is not null
		Set @sSQLString=@sSQLString+@sDerivedTable
		
	Set @sSQLString=@sSQLString+"
	-- Find the minimum charge type key from the comma separated list
	left join (select min(T.NumericParameter) as ChargeKey
		   from dbo.fn_Tokenise(N'"+@sRenewalFees+"',',') T
		   ) D on (D.ChargeKey=C.CHARGETYPENO)
	order by ChargeTypeDescription"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @pnCaseKey		int,
				  @sLookupCulture	nvarchar(10),
				  @pbCalledFromCentura	bit',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @pnCaseKey		= @pnCaseKey,
				  @sLookupCulture	= @sLookupCulture,
				  @pbCalledFromCentura	= @pbCalledFromCentura

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListChargeTypes to public
GO
