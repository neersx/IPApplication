-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_ListOutstandingPurchases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ap_ListOutstandingPurchases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ap_ListOutstandingPurchases.'
	drop procedure dbo.ap_ListOutstandingPurchases
end
print '**** Creating procedure dbo.ap_ListOutstandingPurchases...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ap_ListOutstandingPurchases
(
	@pnRowCount		int output,
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@ptXMLFilterCriteria	ntext,			-- The filtering to be performed on the result set
	@pbCalledFromCentura	bit		= 0	-- Indicates that Centura called the stored procedure

)
AS
-- PROCEDURE :	ap_ListOutstandingPurchases
-- VERSION :	6
-- DESCRIPTION:	the procedure is used by the Outstanding Purchases report
-- SCOPE:	AP
-- CALLED BY :	Centura

-- MODIFICTIONS :
-- Date		Who	Version  Change		Description
-- ------------ ----	-------- ---------	---------------------------------- 
-- 11 Apr 2005	MB	1			Procedure created
-- 15 Mar 2006	AT	2	SQA12252	Include Creditor Restriction/Reason.
--				SQA12253	Include Creditor Restriction/Reason in where clause
-- 09 Dec 2008	MF	3	17136		Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 26 Aug 2009	CR	4	SQA8819		Modified ITEMDUEDATE logic so that both Credit Notes AND Unallocated Payments are included
-- 05 Jul 2013	vql	5	R13629		Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	6   Date conversion errors when creating cases and opening names in Chinese DB
			

Set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF
	
Declare @ErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sWhereString	nvarchar(4000)
Declare @sLocalCurrency nvarchar(254)
Declare @nSupplier 	int
Declare @dtItemDateFrom datetime
Declare @dtItemDateTo 	datetime
Declare @dtDueDateFrom 	datetime
Declare @dtDueDateTo 	datetime
Declare @nSupplierType 	int
Declare @sCurrency 	nvarchar(3)
Declare @nEntity 	int
Declare @idoc 		int 
Declare @nPaymentMethod	int	
Declare @nRestriction	int
Declare @sReason	nvarchar(2)
Declare @nItemType	int
	
Set @ErrorCode=0
Set @sWhereString = ''
Set @sLocalCurrency =''

exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria 	
Select	@nEntity		= EntityNo, 
	@dtDueDateFrom		= DueDateFrom, 
	@dtDueDateTo		= DueDateTo, 
	@dtItemDateFrom		= ItemDateFrom, 
	@dtItemDateTo		= ItemDateTo,
	@nSupplier		= Supplier,
	@nSupplierType		= SupplierType,
	@nPaymentMethod		= PaymentMethod,
	@sCurrency		= Currency,
	@nRestriction		= Restriction,
	@sReason		= Reason,
	@nItemType		= ItemType
from	OPENXML (@idoc, '/Filter',2)
	WITH (
			EntityNo		int		'cmbEntity/text()',
			DueDateFrom		datetime	'dfDueDateFrom/text()',
			DueDateTo		datetime	'dfDueDateTo/text()',
			ItemDateFrom		datetime	'dfItemDateFrom/text()',
			ItemDateTo		datetime	'dfItemDateTo/text()',
			Supplier		int		'dfSupplier/text()',
			SupplierType		int		'cmbSupplierType/text()',
			PaymentMethod		int		'cmbPaymentMethod/text()',
			Currency		nvarchar(3)	'dfCurrency/text()',
			Restriction		int		'cmbRestrictions/text()',
			Reason			nvarchar(2)	'cmbReason/text()',
			ItemType		int		'cmbItemType/text()')
Set @ErrorCode =@@Error
Exec sp_xml_removedocument @idoc
If @ErrorCode = 0
Begin	
	SELECT 
		@sLocalCurrency=COLCHARACTER 
	FROM 
		SITECONTROL 
	WHERE 
		CONTROLID ='CURRENCY'
	Set @ErrorCode =@@Error

	If @nSupplier is not  null
		Set @sWhereString = @sWhereString + ' AND CREDITORITEM.ACCTCREDITORNO = ' + CAST (@nSupplier as nvarchar)
	
-- to ensure Credit Notes and Unallocated Payments are include also need to cater for ITEMDUEDATE = NULL
-- ITEMDUEDATE will NOT be NULL for Purchases	
	If @dtDueDateFrom is not null
		Set @sWhereString = @sWhereString + ' AND (CAST(CONVERT(NVARCHAR,CREDITORITEM.ITEMDUEDATE,112) as DATETIME)
			 >= ' + CHAR(39) + convert(nvarchar,@dtDueDateFrom,112)+ CHAR(39) + 
				' OR ( CREDITORITEM.ITEMDUEDATE IS NULL) )'

	If @dtDueDateTo is not null
		Set @sWhereString = @sWhereString + ' AND (CAST(CONVERT(NVARCHAR,CREDITORITEM.ITEMDUEDATE,112) as DATETIME)
			 <= ' + CHAR(39) + convert(nvarchar,@dtDueDateTo,112)+ CHAR(39) + 
				' OR ( CREDITORITEM.ITEMDUEDATE IS NULL) )'

	If @dtItemDateFrom is not null
		Set @sWhereString = @sWhereString + ' AND CAST(CONVERT(NVARCHAR,CREDITORITEM.ITEMDATE,112) as DATETIME)
			 >= ' + CHAR(39) + convert(nvarchar,@dtItemDateFrom,112)+ CHAR(39)

	If @dtItemDateTo is not null
		Set @sWhereString = @sWhereString + ' AND CAST(CONVERT(NVARCHAR,CREDITORITEM.ITEMDATE,112) as DATETIME)
			 <= ' + CHAR(39) + convert(nvarchar,@dtItemDateTo,112)+ CHAR(39)
	
	If @nSupplierType  is not  null
		Set @sWhereString = @sWhereString + ' AND CREDITOR.SUPPLIERTYPE = ' + CAST (@nSupplierType as nvarchar)
	
	if @sCurrency  is NOT null AND @sCurrency <> ''
		Begin
		If @sLocalCurrency <>"" AND @sCurrency = @sLocalCurrency
			Set @sWhereString = @sWhereString + ' AND CREDITORITEM.CURRENCY  IS NULL '
		Else
			Set @sWhereString = @sWhereString + ' AND CREDITORITEM.CURRENCY = ''' + CAST (@sCurrency as nvarchar) + ''''
		End
		
	If @nPaymentMethod is not null
		Set @sWhereString = @sWhereString + ' AND CREDITOR.PAYMENTMETHOD = ' + CAST (@nPaymentMethod as nvarchar)

	If @nItemType is not null
		Set @sWhereString = @sWhereString + ' AND CREDITORITEM.ITEMTYPE = ' + CAST (@nItemType as nvarchar)
			
	If @nRestriction is not null and @sReason is null
		Set @sWhereString = @sWhereString + ' AND (CREDITOR.RESTRICTIONID = ' + CAST (@nRestriction as nvarchar) + '
							OR CREDITORITEM.RESTRICTIONID = ' + CAST (@nRestriction as nvarchar) + ')'
	
	If @sReason is not null and @nRestriction is null
		Set @sWhereString = @sWhereString + ' AND (CREDITOR.RESTNREASONCODE = ''' + CAST (@sReason as nvarchar) + '''
							OR CREDITORITEM.RESTNREASONCODE = ''' + CAST (@sReason as nvarchar) + ''')'

	If @nRestriction is not null and @sReason is not null
		Set @sWhereString = @sWhereString + ' AND ((CREDITOR.RESTRICTIONID = ' + CAST (@nRestriction as nvarchar) + '
								AND CREDITOR.RESTNREASONCODE = ''' + CAST (@sReason as nvarchar) + ''')
							OR (CREDITORITEM.RESTRICTIONID = ' + CAST (@nRestriction as nvarchar) + '
							AND CREDITORITEM.RESTNREASONCODE = ''' + CAST (@sReason as nvarchar) + '''))'
	
End	
If @ErrorCode = 0
Begin
	Set @sSQLString="
	Select 
		TABLECODES.DESCRIPTION , 
		CREDITOR.NAMENO,
		 convert( nvarchar(254), N.NAME+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END +N.FIRSTNAME+SPACE(1)+ CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END +N.NAMECODE+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END ), 
		-- dbo.fn_FormatName ( N.NAME, N.FIRSTNAME, N.TITLE,0),
		CREDITORITEM.DOCUMENTREF,
		IT.USERCODE,
		CREDITORITEM.ITEMDATE,
		CREDITORITEM.ITEMDUEDATE,
		CREDITORITEM.LOCALBALANCE,
		CREDITORITEM.FOREIGNBALANCE,
		DATEDIFF (day,  CREDITORITEM.ITEMDATE, GETDATE()),
		CREDITORITEM.CURRENCY,
		PAYMENTMETHODS.PAYMENTDESCRIPTION,
		CRRESTRICTION.CRRESTRICTIONDESC,
		REASON.DESCRIPTION,
		CREDITORITEM.RESTRICTIONID,
		CREDITOR.RESTRICTIONID,
		CRR.CRRESTRICTIONDESC,
		CRRSN.DESCRIPTION
	from CREDITORITEM JOIN  NAME N on CREDITORITEM.ACCTCREDITORNO =N.NAMENO 
			LEFT JOIN CREDITOR on N.NAMENO = CREDITOR.NAMENO 
			LEFT JOIN TABLECODES on CREDITOR.SUPPLIERTYPE = TABLECODES.TABLECODE 
			JOIN TABLECODES IT on CREDITORITEM.ITEMTYPE = IT.TABLECODE 
			LEFT JOIN PAYMENTMETHODS on CREDITOR.PAYMENTMETHOD = PAYMENTMETHODS.PAYMENTMETHOD
			LEFT JOIN REASON on CREDITORITEM.RESTNREASONCODE = REASON.REASONCODE
			LEFT JOIN CRRESTRICTION on CREDITORITEM.RESTRICTIONID = CRRESTRICTION.CRRESTRICTIONID
			LEFT JOIN REASON CRRSN on CREDITOR.RESTNREASONCODE = CRRSN.REASONCODE
			LEFT JOIN CRRESTRICTION CRR on CREDITOR.RESTRICTIONID = CRR.CRRESTRICTIONID
	where 
			CREDITORITEM.ITEMENTITYNO = " + CAST ( @nEntity As nvarchar) + " AND 
		( CREDITORITEM.LOCALBALANCE <>0 OR CREDITORITEM.FOREIGNBALANCE <> 0)	 " + @sWhereString + "
			
	order by
		TABLECODES.DESCRIPTION , 
		convert( nvarchar(254), N.NAME+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN ', ' END + N.FIRSTNAME+SPACE(1)+ CASE WHEN N.NAMECODE IS NOT NULL THEN '{' END +N.NAMECODE+ CASE WHEN N.NAMECODE IS NOT NULL THEN '}' END ), 
		CREDITORITEM.CURRENCY,
		CREDITORITEM.ITEMDUEDATE,
		CREDITORITEM.DOCUMENTREF " 
--	select @sSQLString
				
	Exec (@sSQLString)
	Set @ErrorCode =@@Error
	set @pnRowCount=@@Rowcount 
End
	
Return @ErrorCode	
go

Grant execute on dbo.ap_ListOutstandingPurchases to public
go
