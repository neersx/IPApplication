-----------------------------------------------------------------------------------------------------------------------------
-- Creation of aro_TransferredFromDesc
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[aro_TransferredFromDesc]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.aro_TransferredFromDesc.'
	drop procedure dbo.aro_TransferredFromDesc
end
print '**** Creating procedure dbo.aro_TransferredFromDesc...'
print ''
go

create procedure dbo.aro_TransferredFromDesc
	@pnRefEntityNo int,
	@pnRefTransNo int,
	@prsDescription varchar(255) = NULL OUTPUT,
	@pnMovementClass int = 4
as

-- PROCEDURE :	aro_TrasferredFromDesc
-- VERSION :	3
-- DESCRIPTION:	A procedure to return an output string containing a description of the credit Items from which a transfer was performed.
-- CALLED BY :	arb_OpenItemStatement
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited-- MODIFICTIONS :
-- MODIFICTIONS :
-- Date         Who  	SQA#	Version  	Change
-- ------------ ----	---- 	-------- 	------------------------------------------- 
--				1		Procedure Created
-- 02/04/2014	DL	S20835	2		Show Client Payment transactions on Debtor Statement (e.g. AP client refund and AR/AP offset)
-- 24 Nov 2015	DL	R55494	3		Debtors Item Movement report - Description not displayed for Inter Entity transactions 

DECLARE	@sOpenItemNo varchar(12)

DECLARE historycursor CURSOR FOR

	-- S20835 include movementclass 5
	SELECT DISTINCT OPENITEMNO 
	FROM DEBTORHISTORY 	--For a specific business transaction
	WHERE	ACCTENTITYNO = @pnRefEntityNo 
	AND 	REFTRANSNO = @pnRefTransNo 		-- i.e. increases to credit items
	AND	MOVEMENTCLASS in ( 4, 5)
	AND	MOVEMENTCLASS = @pnMovementClass
	AND	TRANSTYPE <> 600			-- Exclude inter-entity history row
	ORDER BY OPENITEMNO

OPEN historycursor 

fetch historycursor into @sOpenItemNo

WHILE (@@fetch_status = 0)
BEGIN
	IF @prsDescription IS NULL
		SELECT @prsDescription = @sOpenItemNo
	ELSE
		SELECT @prsDescription = @prsDescription + ', ' + @sOpenItemNo

	fetch next from historycursor into @sOpenItemNo

END

deallocate historycursor 

IF @prsDescription IS NOT NULL
--	SELECT @prsDescription = convert(varchar(254), 'Applied from ' + @prsDescription )
	SELECT @prsDescription = convert(varchar(254), 'Applied ' +  case when @pnMovementClass = 4 then 'To ' else 'From ' end  + @prsDescription )
go

grant execute on aro_TransferredFromDesc to public
go
