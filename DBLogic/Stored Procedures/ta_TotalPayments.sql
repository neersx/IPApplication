-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ta_TotalPayments
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ta_TotalPayments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ta_TotalPayments.'
	drop procedure dbo.ta_TotalPayments
end
print '**** Creating procedure dbo.ta_TotalPayments...'
print ''
go

create procedure dbo.ta_TotalPayments
	@pnPeriod		INT, 
	@psCurrency		varchar(3) = NULL,
	@pnEntityNo		INT = NULL, 
	@pnDebtorNo		INT = NULL,
	@prnTotalPayments	decimal(11,2) = 0 OUTPUT
as
-- PROCEDURE :	ta_TotalPayments
-- VERSION :	1
-- DESCRIPTION:	A procedure to calculate the total payments made during a posting period, in the currency of the item.
-- CALLED BY :	ta_OpenItemStatement
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  	SQA#	Version	    Change
-- ------------ ----	---- 	--------    ------------------------------------------- 
-- 11/03/2008	JS	10105	1	    Created based on aro_TotalPayments.

select @prnTotalPayments = 
	convert( decimal(11,2),
	  sum( case	when	H.CURRENCY IS NULL
				then	H.LOCALVALUE
				else	H.FOREIGNTRANVALUE
			end ) )
from TRUSTHISTORY H, TRUSTITEM I
where
	-- Trust Payment or Reversal
	( H.TRANSTYPE = 904 or
	  H.TRANSTYPE = 905   ) and
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
	H.TACCTENTITYNO = I.TACCTENTITYNO and
	H.TACCTNAMENO = I.TACCTNAMENO and
	I.STATUS = 1 and
	-- Check filter criteria
	( @pnEntityNo IS NULL or
	  I.TACCTENTITYNO = @pnEntityNo ) and
	( @pnDebtorNo IS NULL or
	  I.TACCTNAMENO = @pnDebtorNo ) 
return 0
GO

grant exec on dbo.ta_TotalPayments  TO public
GO
