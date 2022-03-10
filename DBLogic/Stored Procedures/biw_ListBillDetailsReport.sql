---------------------------------------------------------------------------------------------
-- Creation of dbo.biw_ListBillDetailsReport
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListBillDetailsReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListBillDetailsReport.'
	drop procedure [dbo].[biw_ListBillDetailsReport]
	Print '**** Creating Stored Procedure dbo.biw_ListBillDetailsReport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ListBillDetailsReport
(	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@pnEntityKey                    int             = null, -- The key for Entity Name 
	@pnItemType                     int             = null, -- Open Item type
	@pnStaffKey			int		= null, -- The key of the staff member who raised the bill.
	@pdtFromDate			datetime	= null,	-- The start of the date range for the report.
	@pdtToDate			datetime	= null,	-- The end of the date range for the report.
	@psItemNo                       nvarchar(12)    = null, -- Open Item Number
	@pbCalledFromCentura	        bit		= 0
)
AS
-- PROCEDURE:	biw_ListBillDetailsReport
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates the Bill Details Report dataset.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 19 Oct 2011  TM	R100259	1	Procedure created
-- 13 May 2014	MF	R34358	2	Improve performance by removing NOT EXISTS in sub query 
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).
-- 24 Aug 2017	MF	71713	4	Ethical Walls rules applied for logged on user.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(max)

Set	@nErrorCode      	= 0

-- Populate the Time result set
If  @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  O.OPENITEMNO,
		O.ITEMTYPE,
		C.IRN,
		dbo.fn_FormatNameUsingNameNo(DEBTOR.NAMENO, DEBTOR.NAMESTYLE) AS DEBTORNAME,
		dbo.fn_FormatNameUsingNameNo(STAFF.NAMENO, STAFF.NAMESTYLE) AS STAFFNAME,
	        STAFF.NAMENO, 
	        WT.WIPCODE, 
	        WT.DESCRIPTION as WIPTEMPLATE, 
	        WC.CATEGORYCODE, 
	        WC.DESCRIPTION as WIPCATEGORY, 
	        WHORIG.TRANSDATE, 
	        WHORIG.TRANSNO,
	        WHORIG.TOTALTIME, 
	        WHORIG.CHARGEOUTRATE, 
	        WHORIG.FOREIGNCURRENCY,
	        CASE WHEN WH.MOVEMENTCLASS=2 THEN WH.LOCALTRANSVALUE * -1 ELSE 0 END as LOCALTRANSVALUE,
	        WH2.LOCALTRANSVALUE as LOCALDISCOUNTVALUE, 
	        R.DESCRIPTION,
	        SIGNOFFNAME=dbo.fn_FormatNameUsingNameNo(RAISEDBY.NAMENO, RAISEDBY.NAMESTYLE),
	        O.ITEMDATE, 
	        O.CURRENCY, 
	        O.BILLPERCENTAGE, 
	        O.STATUS,
	        O.ITEMPRETAXVALUE, 
	        O.LOCALTAXAMT,
	        O.LOCALVALUE,
	        O.FOREIGNTAXAMT,
	        O.FOREIGNVALUE,
	        O.REFERENCETEXT,  
	        O.REGARDING, 
	        O.SCOPE, 
	        TS.STATUS_DESCRIPTION,
	        NS.FORMATTEDNAME, 
	        NS.FORMATTEDADDRESS, 
	        NS.FORMATTEDATTENTION,
	        O.LONGREGARDING, 
	        O.LONGREFTEXT,
                STAFF.NAMECODE
	From OPENITEM O
	join WORKHISTORY WH	on (WH.REFENTITYNO= O.ITEMENTITYNO
				and WH.REFTRANSNO = O.ITEMTRANSNO)
	left join WORKHISTORY WH1
				on (WH1.ENTITYNO	= WH.ENTITYNO
				and WH1.TRANSNO 	= WH.TRANSNO
				and WH1.WIPSEQNO	= WH.WIPSEQNO
				and WH1.REFENTITYNO	= WH.REFENTITYNO
				and WH1.REFTRANSNO 	= WH.REFTRANSNO
				and WH1.MOVEMENTCLASS	=2)
	join WORKHISTORY WHORIG	on (WHORIG.ENTITYNO	= WH.ENTITYNO
				and WHORIG.TRANSNO	= WH.TRANSNO
				and WHORIG.WIPSEQNO	= WH.WIPSEQNO
				and WHORIG.ITEMIMPACT	= 1 )
	join WIPTEMPLATE WT	on (WT.WIPCODE		= WH.WIPCODE)
	join WIPTYPE W		on (W.WIPTYPEID		= WT.WIPTYPEID)
	join WIPCATEGORY WC	on (WC.CATEGORYCODE	= W.CATEGORYCODE)
	left join WORKHISTORY WH2
				on (WH2.ENTITYNO	= WH.ENTITYNO
				and WH2.TRANSNO		= WH.TRANSNO
				and WH2.WIPSEQNO	= WH.WIPSEQNO
				and WH2.REFENTITYNO	= WH.REFENTITYNO
				and WH2.REFTRANSNO	= WH.REFTRANSNO
				and WH2.TRANSTYPE 	<>600
				and WH2.MOVEMENTCLASS in (3,9))
	left join REASON R	on (R.REASONCODE	= WH2.REASONCODE)
	left join dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") C on (C.CASEID = WH.CASEID)
	left join dbo.fn_NamesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") DEBTOR on (DEBTOR.NAMENO = WH.ACCTCLIENTNO)
	left join NAME STAFF	on (STAFF.NAMENO	= WHORIG.EMPLOYEENO)
	left join NAME RAISEDBY on (RAISEDBY.NAMENO	= O.EMPLOYEENO)
	join TRANSACTION_STATUS TS on (TS.STATUS_ID = O.STATUS)
	left join NAMEADDRESSSNAP NS on (NS.NAMESNAPNO	= O.NAMESNAPNO)
	where (WH.MOVEMENTCLASS=2 OR (WH.MOVEMENTCLASS=3 and WH1.ENTITYNO is null))	
	 and   O.STATUS <> 0
	 and  (O.ITEMENTITYNO = @pnEntityKey or @pnEntityKey IS NULL)
	 and  (O.ITEMTYPE = @pnItemType or @pnItemType IS NULL)
	 and  (O.ITEMDATE >= @pdtFromDate or @pdtFromDate IS NULL)
	 and  (O.ITEMDATE <= @pdtToDate or @pdtToDate IS NULL)
	 and  (O.EMPLOYEENO = @pnStaffKey or @pnStaffKey IS NULL)
	 and  (O.OPENITEMNO = @psItemNo or @psItemNo IS NULL)
	 and  (C.CASEID is NOT NULL OR WH.CASEID IS NULL)
	 and  (DEBTOR.NAMENO is NOT NULL OR WH.ACCTCLIENTNO IS NULL)
	 ORDER BY O.OPENITEMNO, WC.CATEGORYSORT, WC.CATEGORYCODE, C.IRN, WHORIG.TRANSDATE, STAFFNAME, STAFF.NAMENO"


	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnEntityKey          int,
			  @pnItemType           int,
			  @pnStaffKey		int,
			  @psItemNo             nvarchar(12),
			  @pdtFromDate		datetime,
			  @pdtToDate		datetime',
			  @pnEntityKey          = @pnEntityKey,
			  @pnItemType           = @pnItemType,
			  @pnStaffKey		= @pnStaffKey,
			  @psItemNo             = @psItemNo,
			  @pdtFromDate		= @pdtFromDate,
			  @pdtToDate		= @pdtToDate 
End


Return @nErrorCode
GO

Grant exec on dbo.biw_ListBillDetailsReport to public
GO
