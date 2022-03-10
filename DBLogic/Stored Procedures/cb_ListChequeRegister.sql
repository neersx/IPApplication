-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cb_ListChequeRegister
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cb_ListChequeRegister]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cb_ListChequeRegister.'
	Drop procedure [dbo].[cb_ListChequeRegister]
End
Print '**** Creating Stored Procedure dbo.cb_ListChequeRegister...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cb_ListChequeRegister
(
	@pnEntityNo		int,		--Mandatory
	@pdtDateFrom		datetime 	= null,
	@pdtDateTo		datetime 	= null,
	@pnPeriod		int 		= null,
	@psBankAcct		nvarchar(35) 	= null,
	@pnSupplier		int 		= null,
	@pnEnteredByStaff	int 		= null,
	@pnChequeNoFrom		bigint 		= null,
	@pnChequeNoTo		bigint 		= null,
	@pnLocalBankedFrom	decimal(11,4) 	= null,
	@pnLocalBankedTo	decimal(11,4) 	= null,
	@pnReportBy		tinyint,	--Mandatory
	@pnSortBy		tinyint,	--Mandatory
	@pnState		tinyint,	--Mandatory
	@pnReportOn		tinyint
)
as
-- PROCEDURE:	cb_ListChequeRegister
-- VERSION:	12
-- SCOPE:	InPro
-- DESCRIPTION:	List Cheque Register entries by specified criteria (for Cheque Register Report)
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26/07/04	AT	8846	1	Procedure created.
-- 18/08/04	AT	8846	2	Data types modified.
-- 23/08/04	AT	8846	3	Sorting modified. Output Bank Account with Account Desc.
-- 30/09/04	AT	8846	4	State checkbox handling modified.
-- 9/10/06	JP	11250	5	Casting ChequeNo as decimal(11,4)
-- 15/11/06	JP	13322	6	In @sSqlFrom changed JOIN ON NAME EN to LEFT JOIN ON MAME EN
-- 28/02/07	PY	SQA14425 7	Reserved word [state]
-- 11 Dec 2008	MF	17136	8	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 15 Apr 2013	DV	R13270	9	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629	10	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 18 May 2015	vql	R40817	11	Provide an option for displaying the Payee on the Cheque Register report (DR-8955).
-- 14 Nov 2018  AV  75198/DR-45358	12   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


declare @sSql 			nvarchar(4000)
declare @sSqlFrom 		nvarchar(1000)
declare @sSqlWhere		nvarchar(2000)
declare @sOr			nvarchar(5)

declare	@nErrorCode int
Set	@nErrorCode = 0

-- Set the base SQL table joins first.
Set @sSql = "
	Select 	BN.NAME,
		Case	when BA.IBAN is null then BA.ACCOUNTNO
			else BA.IBAN
		end + CHAR(32) + BA.DESCRIPTION as BADESCRIPTION,
		BA.CURRENCY,
		SC.COLCHARACTER,"
		If (@pnReportOn = 2)
		Begin
			set @sSql = @sSql + "CI.TRADER as SUPPLIER"
		End
		Else
		Begin
			set @sSql = @sSql + "CAST(SN.NAME + Case	when SN.NAMECODE is NULL then NULL
						else ' {' + SN.NAMECODE + '}' 
						end 
			as NVARCHAR(254)) as SUPPLIER"		
		End
set @sSql = @sSql +",
		C.CHEQUENO,
		CAST(EN.NAME + (Case	when EN.FIRSTNAME is not NULL
					then ', ' + EN.FIRSTNAME
					end)
		as NVARCHAR(254)) as ENTEREDBY,
		B.TRANSDATE,
		B.POSTDATE,
		(B.LOCALAMOUNT * -1),
		(B.BANKAMOUNT * -1),
		Case 	when (C.STATUS = 8201 and B.ISRECONCILED = 1) then 1
			when (C.STATUS = 8201 and B.ISRECONCILED != 1) then 2
			when (C.STATUS = 8203) then 3
			else 0
		end as [STATE]"

Set @sSqlFrom = "
	From CHEQUEREGISTER C
	JOIN BANKHISTORY B on (B.REFENTITYNO = C.REFENTITYNO
			and B.REFTRANSNO = C.REFTRANSNO)
	JOIN CASHITEM CI on (CI.TRANSENTITYNO = C.REFENTITYNO
			and CI.TRANSNO = C.REFTRANSNO)
	JOIN BANKACCOUNT BA on (BA.ACCOUNTOWNER = C.BANKENTITYNO
			and BA.BANKNAMENO = C.BANKNAMENO
			and BA.SEQUENCENO = C.BANKSEQUENCENO)
	JOIN TRANSACTIONHEADER T on (T.ENTITYNO = C.REFENTITYNO
			and T.TRANSNO = C.REFTRANSNO)
	JOIN NAME N on (N.NAMENO = C.REFENTITYNO)
	JOIN NAME BN on (BN.NAMENO = C.BANKNAMENO)
	JOIN NAME SN on (SN.NAMENO = CI.ACCTNAMENO)
	LEFT JOIN NAME EN on (EN.NAMENO = T.EMPLOYEENO)
	LEFT JOIN TABLECODES TC on (TC.TABLECODE = C.STATUS)
	JOIN SITECONTROL SC on (SC.CONTROLID = 'CURRENCY')"

--Set the basic Where
Set @sSqlWhere = "
	Where C.REFENTITYNO = @pnEntityNo"

--Set the additional filter criteria
--CHAR(39) returns single quote (')
If (@pdtDateFrom is not NULL)
Begin
	Set @sSqlWhere = @sSqlWhere + 
		Case @pnReportBy
		When 0 then '
		and CAST(CONVERT(NVARCHAR,B.TRANSDATE,112) as DATETIME) >= ' + CHAR(39) + convert(nvarchar,@pdtDateFrom,112) + CHAR(39)
		When 1 then '
		and CAST(CONVERT(NVARCHAR,B.POSTDATE,112) as DATETIME) >= ' + CHAR(39) + convert(nvarchar,@pdtDateFrom,112) + CHAR(39)
		Else Null End
End

If (@pdtDateTo is not NULL)
Begin
	Set @sSqlWhere = @sSqlWhere + 
		Case @pnReportBy
		When 0 then '
		and CAST(CONVERT(NVARCHAR,B.TRANSDATE,112) as DATETIME) <= ' + CHAR(39) + convert(nvarchar,@pdtDateTo,112)+ CHAR(39)
		When 1 then '
		and CAST(CONVERT(NVARCHAR,B.POSTDATE,112) as DATETIME) <= ' + CHAR(39) + convert(nvarchar,@pdtDateTo,112) + CHAR(39)
		Else Null End
End

If (@pnPeriod is not NULL)
Begin
	If @pnReportBy = 2
	Begin
		Set @sSqlWhere = @sSqlWhere + '
		and B.POSTPERIOD = @pnPeriod'
	End
End

--CHAR(39) returns single quote (')
If (@psBankAcct is not NULL)
Begin
	Set @sSqlWhere = @sSqlWhere + '
		and CAST(BA.ACCOUNTOWNER as NVARCHAR(11)) + ' + CHAR(39) + '^' + CHAR(39) +
		' + CAST(BA.BANKNAMENO as NVARCHAR(11)) + ' + CHAR(39) + '^' + CHAR(39) + 
		' + CAST(BA.SEQUENCENO as NVARCHAR(11)) = ' + CHAR(39) + @psBankAcct + CHAR(39)
End
	
If (@pnSupplier is not NULL)
Begin
	Set @sSqlWhere = @sSqlWhere + '
		and CI.ACCTNAMENO = ' + CAST(@pnSupplier as NVARCHAR(11))
End

If (@pnEnteredByStaff is not NULL)
Begin
	Set @sSqlWhere = @sSqlWhere + '
		and T.EMPLOYEENO = ' + CAST(@pnEnteredByStaff as NVARCHAR(11))
End

If (@pnChequeNoFrom is not NULL)
Begin
	Set @sSqlWhere = @sSqlWhere + '	
		and CAST(C.CHEQUENO as decimal(11,4)) >= @pnChequeNoFrom '			
		--and CAST(C.CHEQUENO as BIGINT) <= @pnChequeNoFrom'
		
End

If (@pnChequeNoTo is not NULL)
Begin
	Set @sSqlWhere = @sSqlWhere + '	
		and CAST(C.CHEQUENO as decimal(11,4)) <= @pnChequeNoTo '	
		--and CAST(C.CHEQUENO as BIGINT) <= @pnChequeNoTo'
		
End

If (@pnLocalBankedFrom is not NULL)
Begin
	Set @sSqlWhere = @sSqlWhere + '
		and B.LOCALAMOUNT <= ' + CAST(@pnLocalBankedFrom as NVARCHAR(20))
End

If (@pnLocalBankedTo is not NULL)
Begin
	Set @sSqlWhere = @sSqlWhere + '
		and B.LOCALAMOUNT >= ' + CAST(@pnLocalBankedTo as NVARCHAR(20))
End

--Set the Status Flag conditions

--Reconciled flag
If (@pnState & 1 != 0 or @pnState & 2 != 0 or @pnState & 4 != 0)
Begin
	Set @sOr = ''
	Set @sSqlWhere = @sSqlWhere + '
		and ('

--Presented flag
	If (@pnState & 1) != 0
	Begin
		Set @sSqlWhere = @sSqlWhere + '(C.STATUS = 8201 and B.ISRECONCILED = 1)'
		Set @sOr = ' or '
	End
	
--Unpresented flag
	If (@pnState & 2) != 0
	Begin
		Set @sSqlWhere = @sSqlWhere + @sOr + '(C.STATUS = 8201 and B.ISRECONCILED != 1)'
		Set @sOr = ' or '
	End

--Voided flag
	If (@pnState & 4) != 0
	Begin
		Set @sSqlWhere = @sSqlWhere + @sOr + '(C.STATUS = 8203)'
	End
End

Set @sSqlWhere = @sSqlWhere + ')'

Set @sSqlWhere = @sSqlWhere + '
		order by C.REFENTITYNO, BN.NAME, BADESCRIPTION'

Set @sSqlWhere = @sSqlWhere + 
	Case @pnSortBy
	When 0 then ', C.CHEQUENO'
	When 1 then ', B.TRANSDATE, C.CHEQUENO'
	When 2 then ', SN.NAME, C.CHEQUENO'
	End

Set @sSql = @sSql + @sSqlFrom + @sSqlWhere

Exec @nErrorCode=sp_executesql @sSql, 
		N'@pnEntityNo		int,
		@pdtDateFrom		datetime,
		@pdtDateTo		datetime,
		@pnPeriod		int,
		@psBankAcct		nvarchar(35),
		@pnSupplier		int,
		@pnEnteredByStaff	int,
		@pnChequeNoFrom		bigint,
		@pnChequeNoTo		bigint,
		@pnLocalBankedFrom	decimal(11,4),
		@pnLocalBankedTo	decimal(11,4)',
		@pnEntityNo=@pnEntityNo,
		@pdtDateFrom=@pdtDateFrom,
		@pdtDateTo=@pdtDateTo,
		@pnPeriod=@pnPeriod,
		@psBankAcct=@psBankAcct,
		@pnSupplier=@pnSupplier,
		@pnEnteredByStaff=@pnEnteredByStaff,
		@pnChequeNoFrom=@pnChequeNoFrom,
		@pnChequeNoTo=@pnChequeNoTo,
		@pnLocalBankedFrom=@pnLocalBankedFrom,
		@pnLocalBankedTo=@pnLocalBankedTo


Return @nErrorCode
GO

Grant execute on dbo.cb_ListChequeRegister to public
GO
