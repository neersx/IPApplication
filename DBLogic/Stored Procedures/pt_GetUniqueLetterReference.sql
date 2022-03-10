-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_GetUniqueLetterReference
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_GetUniqueLetterReference]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_GetUniqueLetterReference.'
	drop procedure dbo.pt_GetUniqueLetterReference
	print '**** Creating procedure dbo.pt_GetUniqueLetterReference...'
	print ''
end
go

create procedure dbo.pt_GetUniqueLetterReference
@psEntryPoint varchar(254)
as

-- PROCEDURE :	pt_GetUniqueLetterReference
-- VERSION :	2.2.0
-- DESCRIPTION:	Get all of the Actions from the OpenAction table for the CaseEvents Cases being policed.

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 05/02/2002	MF	SQA7362	Procedure created
-- 06/02/2002	ZA		Input required (Entry Point) even though it is not used

set nocount on

declare @nRefNo		int,
	@ErrorCode	int,
	@TranCountStart int

Select @ErrorCode=0

Select @TranCountStart = @@TranCount
BEGIN TRANSACTION

If @ErrorCode=0
Begin
	update	LASTINTERNALCODE
	set	INTERNALSEQUENCE=INTERNALSEQUENCE+1,
		@nRefNo=INTERNALSEQUENCE+1
	where	TABLENAME='LETTER REFERENCE'
	
	Select @ErrorCode=0
End

if  @nRefNo is null
and @ErrorCode=0
begin
	Select @nRefNo=1
	insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE) values ('LETTER REFERENCE', @nRefNo)

	Select @ErrorCode=0
End

-- Commit or Rollback the transaction

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

select @nRefNo

Return(@ErrorCode)
go

grant execute on dbo.pt_GetUniqueLetterReference to public
go
