-----------------------------------------------------------------------------------------------------------------------------
-- Creation of aro_TotalPayments
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[aro_TotalPayments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.aro_TotalPayments.'
	drop procedure dbo.aro_TotalPayments
end
print '**** Creating procedure dbo.aro_TotalPayments...'
print ''
go

create procedure dbo.aro_TotalPayments
	@pnPeriod INT, @psCurrency varchar(3) = NULL,
	@pnEntityNo INT = NULL, @pnDebtorNo INT = NULL,
	@prnTotalPayments decimal(11,2) = 0 OUTPUT
as
-- PROCEDURE :	aro_TrasferredFromDesc
-- VERSION :	1
-- DESCRIPTION:	A procedure to calculate the total payments made during a posting period, in the currency of the item.
-- 		For local currency, set the @psCurrency to null CR 12/02/2001 modified the way in which the @psCurrency is compared 
-- 		to H.CURRENCY so that if it is NULL it is compared correctly changed from "H.CURRENCY = @psCurrency and" to 
-- 		"(H.CURRENCY =@psCurrency OR (@psCurrency is NULL and H.CURRENCY is NULL)) and"
-- 		Also added the if exists section above so that is may be updated with a bit more ease.
-- CALLED BY :	arb_OpenItemStatement
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited-- MODIFICTIONS :
-- MODIFICTIONS :
-- Date         Who  	SQA#	Version  Change
-- ------------ ----	---- 	-------- ------------------------------------------- 
-- 07/03/2003	AB		1	Add dbo to create procedure

select @prnTotalPayments = 
	convert( decimal(11,2),
	  sum( case	when	H.CURRENCY IS NULL
				then	H.LOCALVALUE
				else	H.FOREIGNTRANVALUE
			end ) )
from DEBTORHISTORY H, OPENITEM I
where
	-- Remittance or Reversal
	( H.TRANSTYPE = 520 or
	  H.TRANSTYPE = 521   ) and
	-- Exclude take up of credit balances
	H.MOVEMENTCLASS = 2 and
	-- Posted during the period
	H.POSTPERIOD = @pnPeriod and
	-- Exclude draft
	H.STATUS <> 0 and
	-- Only payments in specified currency
	((@psCurrency is NULL and H.CURRENCY is NULL) OR (H.CURRENCY = @psCurrency)) and
	-- Exclude anything against a reversed or draft item
	H.ITEMENTITYNO = I.ITEMENTITYNO and
	H.ITEMTRANSNO = I.ITEMTRANSNO and
	H.ACCTENTITYNO = I.ACCTENTITYNO and
	H.ACCTDEBTORNO = I.ACCTDEBTORNO and
	I.STATUS = 1 and
	-- Check filter criteria
	( @pnEntityNo IS NULL or
	  I.ACCTENTITYNO = @pnEntityNo ) and
	( @pnDebtorNo IS NULL or
	  I.ACCTDEBTORNO = @pnDebtorNo ) 
return 0
GO

grant exec on dbo.aro_TotalPayments  TO public
GO
