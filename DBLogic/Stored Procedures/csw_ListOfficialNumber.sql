-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListOfficialNumber
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListOfficialNumber ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListOfficialNumber .'
	Drop procedure [dbo].[csw_ListOfficialNumber ]
	Print '**** Creating Stored Procedure dbo.csw_ListOfficialNumber ...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListOfficialNumber
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,		-- if @pnCaseKey is null return an empty result set
	@pbIsExternalUser 	bit,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	csw_ListOfficialNumber
-- VERSION:	9
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates OfficialNumber result set.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	-----------------------------------------------
-- 15 Oct 2004  TM	RFC1156	1	Procedure created
-- 08 Dec 2004	TM	RFC1156	2	Add a new RowKey column.
-- 15 May 2005  JEK	RFC2508	3	Pass @sLookupCulture to fn_FilterUserXxx.
-- 02 Feb 2010	AT	RFC8858	4	Order results by number type display priority
-- 04 Mar 2010	MS	RFC7594	5	Add checksum on RowKey for encoding
-- 24 Oct 2011	ASH	R11460  6	Cast integer columns as nvarchar(11) data type.
-- 17 Jul 2014	MF	R37428	7	Get Date In Force from EventNo associated with NumberType if there is not a date
--					explicitly recoreded against the Official Number
-- 24 May 2016	SF	R60691 	8	Add Doc Item in the result set
-- 17 Mar 2020  LP  DR-55250 9  Return OFFICIALNUMBERID identity column as RowKey

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0


-- Populating OfficialNumber result set
If @nErrorCode = 0
and @pnCaseKey is not null
Begin
	Set @sSQLString = "
	Select 	O.CASEID		as CaseKey,
		FNT.DESCRIPTION 	as NumberTypeDescription,
		O.OFFICIALNUMBER	as OfficialNumber,
		O.ISCURRENT		as IsCurrent,
		isnull(O.DATEENTERED,CE.EVENTDATE) as DateInForce,
		O.OFFICIALNUMBERID as RowKey,
		NT.DOCITEMID as DocItemKey
	from OFFICIALNUMBERS O
	join dbo.fn_FilterUserNumberTypes(@pnUserIdentityId, @sLookupCulture, @pbIsExternalUser, @pbCalledFromCentura) FNT
				on (FNT.NUMBERTYPE = O.NUMBERTYPE)
	join NUMBERTYPES NT on (NT.NUMBERTYPE = O.NUMBERTYPE)
	left join CASEEVENT CE  on (CE.CASEID=O.CASEID
				and CE.EVENTNO=FNT.RELATEDEVENTNO
				and CE.CYCLE=(	select isnull(max(CE2.CYCLE),1)
						from CASEEVENT CE2
						where CE2.CASEID = CE.CASEID
						and CE2.EVENTNO = CE.EVENTNO) )
	where O.CASEID = @pnCaseKey
	order by FNT.DISPLAYPRIORITY, NumberTypeDescription, DateInForce DESC, IsCurrent DESC, OfficialNumber"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId 	int,
					  @sLookupCulture	nvarchar(10),
					  @pbIsExternalUser	bit,
					  @pbCalledFromCentura	bit,
					  @pnCaseKey		int',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbIsExternalUser	= @pbIsExternalUser,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @pnCaseKey		= @pnCaseKey
	Set @pnRowCount = @@Rowcount
End
Else
-- Return an empty result set if the @pnCaseKey is null
If @nErrorCode = 0
and @pnCaseKey is null
Begin
	Select 	null	as CaseKey,
		null	as NumberTypeDescription,
		null	as OfficialNumber,
		null	as IsCurrent,
		null	as DateInForce,
		null	as RowKey,
		null	as DocItemKey
	where 1=0

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListOfficialNumber  to public
GO
