-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ta_TransferredFromDesc
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ta_TransferredFromDesc]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ta_TransferredFromDesc.'
	drop procedure dbo.ta_TransferredFromDesc
end
print '**** Creating procedure dbo.ta_TransferredFromDesc...'
print ''
go

create procedure dbo.ta_TransferredFromDesc
	@pnRefEntityNo		int,
	@pnRefTransNo		int,
	@prsDescription		varchar(255) = NULL OUTPUT
as
-- PROCEDURE :	ta_TransferredFromDesc
-- VERSION :	1
-- DESCRIPTION:	A procedure to return an output string containing a description of the credit Items from which a transfer was performed.
-- CALLED BY :	ta_OpenItemStatement
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  	SQA#	Version  	Change
-- ------------ ----	---- 	-------- 	------------------------------------------- 
-- 11/03/2008	JS	10105	1		Created based on aro_TransferredFromDesc.

DECLARE	@sItemNo varchar(12)

DECLARE historycursor CURSOR FOR

	SELECT DISTINCT ITEMNO FROM TRUSTHISTORY 	-- For a specific business transaction
	WHERE	REFENTITYNO = @pnRefEntityNo 
	AND 	REFTRANSNO = @pnRefTransNo 		-- i.e. increases to credit items
	AND	MOVEMENTCLASS = 4
	ORDER BY ITEMNO

OPEN historycursor 

fetch historycursor into @sItemNo

WHILE (@@fetch_status = 0)
BEGIN
	IF @prsDescription IS NULL
		SELECT @prsDescription = @sItemNo
	ELSE
		SELECT @prsDescription = @prsDescription + ', ' + @sItemNo

	fetch next from historycursor into @sItemNo

END

deallocate historycursor 

IF @prsDescription IS NOT NULL
	SELECT @prsDescription = convert(varchar(254), 'Applied from ' + @prsDescription )
go

grant execute on dbo.ta_TransferredFromDesc to public
go
