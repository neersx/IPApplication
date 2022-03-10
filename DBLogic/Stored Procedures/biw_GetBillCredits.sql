-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetBillCredits] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetBillCredits]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetBillCredits].'
	drop procedure dbo.[biw_GetBillCredits]
end
print '**** Creating procedure dbo.[biw_GetBillCredits]...'
print ''
go

set QUOTED_IDENTIFIER on
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetBillCredits]
		@pnUserIdentityId		int,		-- Mandatory
		@psCulture			nvarchar(10) 	= null,
		@pbCalledFromCentura	bit	= 0,
		@pnItemEntityNo		int = null,
		@pnItemTransNo		int = null,
		@psCaseKeyCSVList	nvarchar(max) = null,
		@psDebtorKeyList	nvarchar(max) = null,
		@psMergeXMLKeys		nvarchar(max)	= null
as
-- PROCEDURE :	biw_GetBillCredits
-- VERSION :	10
-- DESCRIPTION:	A procedure that returns all of the credit items from an open item.
--
-- COPYRIGHT:	Copyright 1993 - 2014 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 22/10/2009	AT	RFC3605		1	Procedure created
-- 12/07/2010	MS	RFC7269		2	Fixed issue related to empty case list
-- 29/04/2011	AT	RFC7956		3	Get credits for multiple items (draft bills only)
-- 13/03/2012	AT	RFC12054	4	Turn CONCAT_NULL_YIELDS_NULL off to compile case CSV list.
-- 08/05/2012	AT	RFC12230	5	Turn CONCAT_NULL_YIELDS_NULL back on for XML Processing.
-- 15/06/2012	AT	RFC12395	6	Added additional support for retrieving credits for merged bills.
-- 02/10/2012	AT	RFC12808	7	Fixed loading a bill with a large number of WIP items.
-- 21/12/2012	AT	RFC13062	8	Filter credits by Entity.
-- 11/09/2014   SS	RFC39363	9	Modified the size of psCaseKeyCSVList to take as max.
-- 04/06/2015	LP	R44648		10	Return IsLocked flag to prevent item from being applied if it is in use.

set nocount on
SET CONCAT_NULL_YIELDS_NULL on

Declare		@nErrorCode	int
Declare		@nRowCount	int

Declare @sSQLString nvarchar(max)
Declare @sBaseSelect nvarchar(1500)
Declare @sBaseFrom nvarchar(500)
Declare @nItemStatus int
Declare	@sXMLJoin nvarchar(500)
Declare @bForcedPayout bit

Declare	@XMLKeys	XML

Set @nErrorCode = 0

if (@psMergeXMLKeys is not null)
Begin		
	Set @XMLKeys = cast(@psMergeXMLKeys as XML)
	
	Set @sXMLJoin = char(10) + 'JOIN (
		select	K.value(N''ItemEntityNo[1]'',N''int'') as ItemEntityNo,
			K.value(N''ItemTransNo[1]'',N''int'') as ItemTransNo
		from @XMLKeys.nodes(N''/Keys/Key'') KEYS(K)) AS XM'
End

If (@nErrorCode = 0 and @pnItemTransNo is not null)
Begin
	Select @nItemStatus = [STATUS]
	From OPENITEM
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @pnItemTransNo
End
Else
Begin
	Set @nItemStatus = 0
End

If (@nErrorCode = 0 and (@pnItemTransNo is not null or @sXMLJoin is not null) and (@psCaseKeyCSVList is null or @psCaseKeyCSVList = ''))
Begin
	--Get the cases
	Set @sSQLString = 'Select @psCaseKeyCSVList = isnull(@psCaseKeyCSVList,'''') + Case when @psCaseKeyCSVList is not null then '','' else '''' end + cast(CASEID as nvarchar(12))'
	
	If @nItemStatus=0
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'FROM
			(select distinct WIP.CASEID From BILLEDITEM BI 
		Join WORKINPROGRESS WIP on (WIP.ENTITYNO = BI.WIPENTITYNO
				and WIP.TRANSNO = BI.WIPTRANSNO
				and WIP.WIPSEQNO = BI.WIPSEQNO)'
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'FROM
			(select distinct WIP.CASEID From WORKHISTORY WIP'
	End
				
	if @sXMLJoin is not null and @nItemStatus=0
	Begin
		-- JOIN to the XML Keys
		Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
		char(10) + 'on (XM.ItemEntityNo = BI.ITEMENTITYNO
				and XM.ItemTransNo = BI.ITEMTRANSNO)' +
		char(10) + 'Where WIP.CASEID IS NOT NULL'
	End
	Else if @nItemStatus = 0
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'Where  BI.ITEMENTITYNO = @pnItemEntityNo
		and BI.ITEMTRANSNO = @pnItemTransNo
		and WIP.CASEID IS NOT NULL'
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'Where  WIP.REFENTITYNO = @pnItemEntityNo
		and WIP.REFTRANSNO = @pnItemTransNo
		and WIP.CASEID IS NOT NULL'
	End
	
	Set @sSQLString = @sSQLString + ') AS CASEIDS'

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnItemTransNo	int,
			  @pnItemEntityNo	int,
			  @psCaseKeyCSVList nvarchar(max) OUTPUT,
			  @XMLKeys		xml',
			  @pnItemTransNo=@pnItemTransNo,
			  @pnItemEntityNo=@pnItemEntityNo,
			  @psCaseKeyCSVList = @psCaseKeyCSVList OUTPUT,
			  @XMLKeys = @XMLKeys
End
	  
If (@nErrorCode = 0 and (@pnItemTransNo is not null or @sXMLJoin is not null) and (@psDebtorKeyList is null or @psDebtorKeyList = ''))
Begin
	Set @sSQLString = 'Select @psDebtorKeyList = isnull(@psDebtorKeyList,'''') + Case when @psDebtorKeyList is not null then '','' else '''' end + cast(ACCTDEBTORNO as nvarchar(12))
			From OPENITEM'
			
	if @sXMLJoin is not null and @nItemStatus=0
	Begin
		-- JOIN to the XML Keys
		Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
		char(10) + 'on (XM.ItemEntityNo = OPENITEM.ITEMENTITYNO
				and XM.ItemTransNo = OPENITEM.ITEMTRANSNO)
			where OPENITEM.ACCTDEBTORNO IS NOT NULL'
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'Where  ITEMENTITYNO = @pnItemEntityNo
			and ITEMTRANSNO = @pnItemTransNo
			and ACCTDEBTORNO IS NOT NULL'
	End

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int,
				  @XMLKeys		xml,
				  @psDebtorKeyList nvarchar(1000) OUTPUT',
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo,
				  @XMLKeys=@XMLKeys,
				  @psDebtorKeyList = @psDebtorKeyList OUTPUT
End


	-- Build up the SQL Statement.
	-- First part of the UNION gets available Credits
	-- Second part of the UNION gets Credits already selected on the Open item
	Set @sBaseSelect = 'SELECT (1- isnull( (OPENITEM.ACCTDEBTORNO * 0), 1 ) ) * 1000 + (1- isnull( (OIC.CASEID * 0), 1 ) ) * 100 +  CASE WHEN OPENITEM.PAYPROPERTYTYPE IS NULL THEN 0 ELSE 1 END  * 10 +  CASE WHEN OPENITEM.PAYFORWIP IS NULL THEN 0 ELSE 1 END  * 1 AS ''BestFitScore'',
	OPENITEM.ITEMENTITYNO as ''ItemEntityNo'', OPENITEM.ITEMTRANSNO as ''ItemTransNo'',
	OPENITEM.ACCTENTITYNO as ''AcctEntityNo'', OPENITEM.ACCTDEBTORNO as ''AcctDebtorNo'',
	OPENITEM.OPENITEMNO as ''OpenItemNo'', ITEMDATE as ''ItemDate'',
	CASE WHEN OIC.CASEID IS NULL THEN OPENITEM.LOCALBALANCE ELSE OIC.LOCALBALANCE END as ''LocalBalance'',
	OPENITEM.CURRENCY as ''Currency'',  OPENITEM.EXCHRATE as ''ExchRate'',
	CASE WHEN OIC.CASEID IS NULL THEN OPENITEM.FOREIGNBALANCE ELSE OIC.FOREIGNBALANCE END as ''ForeignBalance'',
	isnull(OPENITEM.LONGREFTEXT, OPENITEM.REFERENCETEXT) as ''ReferenceText'', C.IRN as ''IRN'', C.CASEID as ''CaseKey'', ITEMTYPE as ''ItemType'', OPENITEM.PAYPROPERTYTYPE as ''PayPropertyTypeKey'', PT.PROPERTYNAME as ''PayPropertyName'',
	CASE WHEN OPENITEM.PAYFORWIP = ''R'' 
	THEN ''Renewal'' 
	ELSE CASE WHEN OPENITEM.PAYFORWIP = ''N'' THEN ''Non-renewal'' ELSE NULL END
	END as ''PayForWIP'',
	Cast(ISNULL(OPENITEM.LOCKIDENTITYID,0) as bit) as ''IsLocked'','

	Set @sBaseFrom = 'FROM OPENITEM
	LEFT JOIN OPENITEMCASE OIC ON
		(OPENITEM.ITEMENTITYNO = OIC.ITEMENTITYNO AND
		 OPENITEM.ITEMTRANSNO = OIC.ITEMTRANSNO AND
		 OPENITEM.ACCTENTITYNO = OIC.ACCTENTITYNO AND
		 OPENITEM.ACCTDEBTORNO = OIC.ACCTDEBTORNO)
	LEFT JOIN CASES C ON (OIC.CASEID = C.CASEID)
	LEFT JOIN PROPERTYTYPE PT ON
		(OPENITEM.PAYPROPERTYTYPE = PT.PROPERTYTYPE)'

	Set @sSQLString = @sBaseSelect + CHAR(10) + 
	'NULL as ''ForcedPayOut'', NULL as ''LocalSelected'', NULL as ''ForeignSelected''' + char(10) +

	+ @sBaseFrom + char(10) +

	'WHERE OPENITEM.ITEMENTITYNO = @pnItemEntityNo
	AND OPENITEM.STATUS = 1
	AND OPENITEM.ITEMTYPE IN (SELECT ITEM_TYPE_ID
	   FROM DEBTOR_ITEM_TYPE
	   WHERE TAKEUPONBILL = 1) AND OPENITEM.LOCALBALANCE < { fn CONVERT (0.00, SQL_DECIMAL) } 
	   AND (OIC.CASEID IS NULL'

If (@psCaseKeyCSVList is not null and @psCaseKeyCSVList != '')
Begin
	Set @sSQLString = @sSQLString + char(10) + 'OR (OIC.STATUS = 1 
		AND OIC.LOCALBALANCE < { fn CONVERT (0.00, SQL_DECIMAL) } 
		AND OIC.CASEID in (' + @psCaseKeyCSVList + '))'
End

Set @sSQLString = @sSQLString + ')'

If (@psDebtorKeyList is not null and @psDebtorKeyList != '')
Begin
	Set @sSQLString = @sSQLString +char(10)+ 'and OPENITEM.ACCTDEBTORNO IN (' + @psDebtorKeyList + ')'
End

if (@pnItemTransNo is not null or @sXMLJoin is not null)
Begin
	/*************** UNION SELECTED CREDITS **************/
	Set @sSQLString = @sSQLString+char(10)+'UNION ALL'+char(10)+

	@sBaseSelect + char(10) + 

	'BC.FORCEDPAYOUT as ''ForcedPayOut'', BC.LOCALSELECTED as ''LocalSelected'', BC.FOREIGNSELECTED as ''ForeignSelected'''+char(10)+

	@sBaseFrom+char(10)+

	'JOIN BILLEDCREDIT BC ON
	(BC.CRITEMENTITYNO = OPENITEM.ITEMENTITYNO AND
	 BC.CRITEMTRANSNO = OPENITEM.ITEMTRANSNO AND
	 BC.CRACCTENTITYNO = OPENITEM.ACCTENTITYNO AND
	 BC.CRACCTDEBTORNO = OPENITEM.ACCTDEBTORNO)'
	 
	if @sXMLJoin is not null
	Begin
		-- JOIN to the XML Keys
		Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
			char(10) + 'on (XM.ItemEntityNo = BC.DRITEMENTITYNO
					and XM.ItemTransNo = BC.DRITEMTRANSNO)' +
			char(10) + 'Where (BC.CRCASEID IS NULL'
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'WHERE BC.DRITEMENTITYNO = @pnItemEntityNo
		AND BC.DRITEMTRANSNO = @pnItemTransNo
		AND (BC.CRCASEID IS NULL'
	End

	If (@psCaseKeyCSVList is not null and @psCaseKeyCSVList != '')
	Begin
		Set @sSQLString = @sSQLString +char(10)+ 
		'or BC.CRCASEID in (' + @psCaseKeyCSVList + '))' +CHAR(10)+
		'AND (OIC.CASEID IS NULL OR OIC.CASEID = BC.CRCASEID'
	End

	Set @sSQLString = @sSQLString +char(10)+ ') ORDER BY 1 DESC, 16, 18, 19, 17 DESC, 7, 6'

End

if @nItemStatus = 1
Begin
	
	IF exists (select * from DEBTORHISTORY DH 
			WHERE DH.REFENTITYNO = @pnItemEntityNo
			and DH.REFTRANSNO = @pnItemTransNo
			and DH.FORCEDPAYOUT = 1)
	Begin
		Set @bForcedPayout = 1
	End
	Else
	Begin
		Set @bForcedPayout = 0
	End

	Set @sSQLString = null
	-- Get the billed credits from history.
	Select @sSQLString = @sBaseSelect + 
	'@bForcedPayout as ''ForcedPayOut'', DH.LOCALVALUE as ''LocalSelected'', DH.FOREIGNTRANVALUE as ''ForeignSelected'''
	+ CHAR(10) + @sBaseFrom + char(10) + 
	'join DEBTORHISTORY DH on OPENITEM.ITEMENTITYNO = DH.ITEMENTITYNO
				AND OPENITEM.ITEMTRANSNO = DH.ITEMTRANSNO
	Where DH.REFENTITYNO = @pnItemEntityNo
	and DH.REFTRANSNO = @pnItemTransNo
	and DH.ITEMTRANSNO != @pnItemTransNo'
	
	If (@psCaseKeyCSVList is not null and @psCaseKeyCSVList != '')
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'and OIC.CASEID in (' + @psCaseKeyCSVList + ')'
	End
End

	exec @nErrorCode = sp_executesql @sSQLString, 	
			N'@pnItemTransNo	int,
			  @pnItemEntityNo	int,
			  @XMLKeys		xml,
			  @bForcedPayout	bit',
			  @pnItemTransNo=@pnItemTransNo,
			  @pnItemEntityNo=@pnItemEntityNo,
			  @XMLKeys = @XMLKeys,
			  @bForcedPayout = @bForcedPayout

return @nErrorCode
go

grant execute on dbo.[biw_GetBillCredits]  to public
go