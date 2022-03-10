--biw_GetBillReferences
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetBillReferences] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetBillReferences]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetBillReferences].'
	drop procedure dbo.[biw_GetBillReferences]
end
print '**** Creating procedure dbo.[biw_GetBillReferences]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetBillReferences]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnItemEntityNo		int,
				@pnItemTransNo		int
				
as
-- PROCEDURE :	biw_GetBillReferences
-- VERSION :	2
-- DESCRIPTION:	A procedure that returns all of the details regarding an OpenItem's text references
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC	Version Description
-- -----------	-------	------	------- ----------------------------------------------- 
-- 14-Oct-2009	AT	RFC3605	1	Procedure created.
-- 03-May-2010	AT	RFC9092	2	Use translations.

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@sLookupCulture	nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

If @ErrorCode = 0
Begin
	Set @sSQLString = "

		select TOP 1
		" + dbo.fn_SqlTranslatedColumn('OPENITEM','REFERENCETEXT','LONGREFTEXT','OI',@sLookupCulture,@pbCalledFromCentura) + " as 'ReferenceText',
		" + dbo.fn_SqlTranslatedColumn('OPENITEM','SCOPE',null,'OI',@sLookupCulture,@pbCalledFromCentura) + " as 'BillScope',
		" + dbo.fn_SqlTranslatedColumn('OPENITEM','REGARDING','LONGREGARDING','OI',@sLookupCulture,@pbCalledFromCentura) + " as 'Regarding',
		LTRIM(RTRIM(OI.STATEMENTREF)) as 'StatementText'
		FROM OPENITEM OI
		where OI.ITEMENTITYNO = @pnItemEntityNo
		and OI.ITEMTRANSNO = @pnItemTransNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnItemTransNo	int,
				  @pnItemEntityNo	int',
				  @pnItemTransNo=@pnItemTransNo,
				  @pnItemEntityNo=@pnItemEntityNo
End

return @ErrorCode
go

grant execute on dbo.[biw_GetBillReferences]  to public
go
