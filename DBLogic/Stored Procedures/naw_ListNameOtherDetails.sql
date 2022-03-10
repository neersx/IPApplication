-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameOtherDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameOtherDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameOtherDetails.'
	Drop procedure [dbo].[naw_ListNameOtherDetails]
	Print '**** Creating Stored Procedure dbo.naw_ListNameOtherDetails...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListNameOtherDetails
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,	
	@pnNameKey		int,		-- Mandatory, the name the results are required for.
	@psLocalCurrencyCode	nvarchar(3)	= null,
	@pdtBaseDate		datetime	= null,
	@pnAge0			smallint	= null,
	@pnAge1			smallint	= null,
	@pnAge2			smallint	= null,
	@pnMoneyInAccount	decimal(11,2)	OUTPUT
)
AS 
-- PROCEDURE:	naw_ListNameOtherDetails
-- VERSION:	3
-- SCOPE:	Inprotech Web
-- DESCRIPTION:	Returns summary WIP for this name
-- MODIFICATIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 13 Dec 2011  vql	RFC10456	1	Procedure created.
-- 25 Jan 2012  vql	RFC10456	2	Remaining issue RFC10456 : Implement Financial Summary Web Part.
-- 24 Aug 2017	MF	71721		3	Ethical Walls rules applied for logged on user.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)
Declare @bIsWIPAvailable	bit
Declare @dtToday		datetime
Declare @bBillRenewalDebtor	bit
Declare @nMoneyInAccount	int
Declare @dtDateOfLastBill	datetime
Declare @dtDateOfLastTimeEntry	datetime
Declare @dtDateOfLastPayment	datetime

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()

-- Check Bill Rewnal Debotr site control
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select @bBillRenewalDebtor = COLBOOLEAN
	from SITECONTROL
	where CONTROLID like 'Bill Renewal Debtor'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bBillRenewalDebtor			bit	OUTPUT',
					  @bBillRenewalDebtor=@bBillRenewalDebtor	OUTPUT
End

-- Check whether the WIP Items information is available.
-- The result set should only be published if the Work In Progress Items information security topic (120) is available.
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select @bIsWIPAvailable = IsAvailable
	from	dbo.fn_GetTopicSecurity(null, 120, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @bIsWIPAvailable	bit			OUTPUT,
					  @dtToday		datetime',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @bIsWIPAvailable	= @bIsWIPAvailable 	OUTPUT,
					  @dtToday		= @dtToday
End

-- Get the Total Amount of monies.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	Set @sSQLString = "
	Select @nMoneyInAccount=sum(BALANCE)
	from ACCOUNT
	where NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nMoneyInAccount	int OUTPUT,
					  @pnNameKey		int',
					  @nMoneyInAccount=@pnMoneyInAccount OUTPUT,
					  @pnNameKey=@pnNameKey
End

-- Get the date of last Bill.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	Set @sSQLString = "
	Select @dtDateOfLastBill=max(ITEMDATE)
	from OPENITEM
	where ITEMTYPE = 510
	and STATUS = 1
	and ACCTDEBTORNO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@dtDateOfLastBill	datetime OUTPUT,
					  @pnNameKey		int',
					  @dtDateOfLastBill=@dtDateOfLastBill OUTPUT,
					  @pnNameKey=@pnNameKey
End

-- Get the date of last time entry.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	Set @sSQLString = "
	Select @dtDateOfLastTimeEntry=max(D.STARTTIME)
	from DIARY D
	left join CASENAME CN on (CN.CASEID = D.CASEID "

	If @bBillRenewalDebtor = 1
	Begin
		Set @sSQLString = @sSQLString+char(10)+"and CN.NAMETYPE = 'Z')"
	End
	Else
	Begin
		Set @sSQLString = @sSQLString+char(10)+"and CN.NAMETYPE = 'D')"
	End	
	
	Set @sSQLString = @sSQLString+char(10)+"
	left join dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") C on (C.CASEID=D.CASEID)
	where isnull(CN.NAMENO,D.NAMENO) = @pnNameKey
	and (D.CASEID is null OR C.CASEID is not null)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@dtDateOfLastTimeEntry	datetime OUTPUT,
					  @pnNameKey			int',
					  @dtDateOfLastTimeEntry=@dtDateOfLastTimeEntry OUTPUT,
					  @pnNameKey=@pnNameKey
End

-- Get the date of last payment entry.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	Set @sSQLString = "
	Select @dtDateOfLastPayment=max(TRANSDATE) 
	from DEBTORHISTORY
	where TRANSTYPE in (520, 530)
	and STATUS = 1
	and ACCTDEBTORNO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@dtDateOfLastPayment	datetime OUTPUT,
					  @pnNameKey		int',
					  @dtDateOfLastPayment=@dtDateOfLastPayment OUTPUT,
					  @pnNameKey=@pnNameKey
End

-- Local currency result set.
If (@nErrorCode = 0) and (@bIsWIPAvailable = 1)
Begin
	select	@pnNameKey		as NameKey,
		Isnull(@pnMoneyInAccount,0)	as MoneyInAccount, 
		@dtDateOfLastBill	as DateOfLastBill, 
		@dtDateOfLastTimeEntry	as DateOfLastTimeEntry, 
		@dtDateOfLastPayment	as DateOfLastPayment
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameOtherDetails to public
GO