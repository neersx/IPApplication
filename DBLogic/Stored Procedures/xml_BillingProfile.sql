-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_BillingProfile
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_BillingProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_BillingProfile.'
	drop procedure dbo.xml_BillingProfile
	print '**** Creating procedure dbo.xml_BillingProfile...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.xml_BillingProfile
	@pnItemEntityNo		int,
	@pnItemTransNo		int,
	@psOpenItemNo		varchar(100),
	@psLoginId		varchar(100)
AS

-- PROCEDURE :	xml_BillingProfile
-- VERSION :	4
-- DESCRIPTION:	Collects search criteria for the Invoice
-- CALLED BY :	SQLT_BillingProfile SQLTemplate 

-- MODIFICATIONS:
-- Date		Who	Number	Version	
-- ====         ===	======	=======
-- 17/09/2002	AvdA		Procedure created
-- 21/10/2002	AvdA		Simplify implementation
-- 21/10/2002	AvdA		Add extra NameType sample
-- 22/10/2002	AvdA 	2.3.0	Comment extra NameType sample
-- 18 Apr 2017	MF	4	Customisation provided by client to include the Bill Copy.

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode	int
declare	@sSQLString	nvarchar(4000)


begin
	--Collect the ENTITY
	set @sSQLString="SELECT 1 as TAG, 0 as parent,
			ENTITY.NAMECODE as  [Entity!1!NameCode],
			ENTITY.NAME as  [Entity!1!Name]
			FROM    OPENITEM 
			JOIN NAME ENTITY ON ENTITY.NAMENO = ACCTENTITYNO
			WHERE ITEMENTITYNO = " + cast(@pnItemEntityNo as varchar)+ "
			AND ITEMTRANSNO = " + cast(@pnItemTransNo as varchar)+ "
			AND OPENITEMNO = '" + @psOpenItemNo + "'
			FOR XML EXPLICIT"
	Exec(@sSQLString)
	set @ErrorCode=@@error

end
if  @ErrorCode=0
begin	
	--Collect the DEBTOR
	set @sSQLString="SELECT 1 as TAG, 0 as parent,
			DEBTOR.NAMECODE as  [Debtor!1!NameCode],
			DEBTOR.NAME as  [Debtor!1!Name]
			FROM    OPENITEM
			JOIN NAME DEBTOR ON DEBTOR.NAMENO = ACCTDEBTORNO
			WHERE ITEMENTITYNO = " + cast(@pnItemEntityNo as varchar)+ "
			AND ITEMTRANSNO = " + cast(@pnItemTransNo as varchar)+ "
			AND OPENITEMNO = '" + @psOpenItemNo + "'
			FOR XML EXPLICIT"
	Exec(@sSQLString)
	set @ErrorCode=@@error
end
if @ErrorCode=0 
begin 
	--Collect the Bill Copy, when different to the account debtor 
	set @sSQLString="SELECT DISTINCT 1 as TAG, 0 as parent, 
			BILLCOPY.NAMECODE as [BillCopy!1!NameCode], 
			BILLCOPY.NAME as [BillCopy!1!Name] 
			FROM OPENITEM OI 
			JOIN WORKHISTORY WH ON (WH.REFENTITYNO = OI.ITEMENTITYNO AND WH.REFTRANSNO = OI.ITEMTRANSNO) 
			JOIN CASENAME CN ON WH.CASEID = CN.CASEID AND CN.NAMETYPE IN ( 'CD' ) 
			JOIN NAME BILLCOPY ON BILLCOPY.NAMENO = CN.NAMENO 
			WHERE OI.ACCTDEBTORNO <> BILLCOPY.NAMENO 
			AND ITEMENTITYNO = " + cast(@pnItemEntityNo as varchar)+ " 
			AND ITEMTRANSNO = " + cast(@pnItemTransNo as varchar)+ " 
			AND OPENITEMNO = '" + @psOpenItemNo + "' 
			FOR XML EXPLICIT" 
	Exec(@sSQLString) 
	set @ErrorCode=@@error 
end
if  @ErrorCode=0
begin
	--Collect the CASE
	set @sSQLString="SELECT DISTINCT 1 as TAG, 0 as parent,
			NULL AS	[Cases!1!!element],
			NULL AS	[CaseReference!2!!element]
			UNION
			SELECT DISTINCT 2 as TAG, 1 as parent,
			NULL,
			C.IRN
			FROM		OPENITEM OI
			LEFT JOIN	WORKHISTORY WH ON (WH.REFENTITYNO = OI.ITEMENTITYNO
					AND WH.REFTRANSNO = OI.ITEMTRANSNO)
			LEFT JOIN	CASES C ON (C.CASEID = WH.CASEID)
			WHERE ITEMENTITYNO = " + cast(@pnItemEntityNo as varchar)+ "
			AND ITEMTRANSNO = " + cast(@pnItemTransNo as varchar)+ "
			AND OPENITEMNO = '" + @psOpenItemNo + "'
			AND C.CASEID IS NOT NULL 		--Ensure there is no tag if Debtor only bill 
			FOR XML EXPLICIT"
	Exec(@sSQLString)
	set @ErrorCode=@@error
end
if  @ErrorCode=0
begin
	--Collect the Bill Info
	set @sSQLString="SELECT 1 as TAG, 0 as parent,
			rtrim(DEBTOR_ITEM_TYPE.DESCRIPTION) 	AS [BillInformation!1!ItemType],
			OPENITEMNO 	AS [BillInformation!1!OpenItemNo],
			STAFF.FIRSTNAME+SPACE(1)+STAFF.NAME	AS [BillInformation!1!RaisedBy],
			PC.DESCRIPTION	AS [BillInformation!1!ProfitCentre],
			'" + @psLoginId + "' 	AS [BillInformation!1!Login],
			ITEMDATE	AS [BillInformation!1!ItemDate],
			LOCALVALUE	AS [BillInformation!1!LocalAmount],
			ASSOCOPENITEMNO	AS [BillInformation!1!RelatedItem]
			FROM    OPENITEM
			JOIN DEBTOR_ITEM_TYPE ON ITEM_TYPE_ID = ITEMTYPE
			LEFT JOIN NAME STAFF ON STAFF.NAMENO = EMPLOYEENO
			LEFT JOIN PROFITCENTRE PC ON PC.PROFITCENTRECODE = EMPPROFITCENTRE
			WHERE ITEMENTITYNO = " + cast(@pnItemEntityNo as varchar)+ "
			AND ITEMTRANSNO = " + cast(@pnItemTransNo as varchar)+ "
			AND OPENITEMNO = '" + @psOpenItemNo + "'
			FOR XML EXPLICIT"
	Exec(@sSQLString)
	set @ErrorCode=@@error
end


RETURN @ErrorCode
go

grant execute on dbo.xml_BillingProfile  to public
go
