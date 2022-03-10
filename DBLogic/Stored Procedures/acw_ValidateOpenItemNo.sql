-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [acw_ValidateOpenItemNo] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[acw_ValidateOpenItemNo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[acw_ValidateOpenItemNo].'
	drop procedure dbo.[acw_ValidateOpenItemNo]
end
print '**** Creating procedure dbo.[acw_ValidateOpenItemNo]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[acw_ValidateOpenItemNo]
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psOpenItemNo		nvarchar(12)
				
as
-- PROCEDURE :	acw_ValidateOpenItemNo
-- VERSION :	1
-- DESCRIPTION:	A procedure that checks if an OpenItemNo exists in the database.
--
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC	 Version Description
-- -----------	-------	------	 ------- ----------------------------------------------- 
--- 30-Mar-2011  DV     RFC10041  1	 Procedure created

set nocount on

Declare		@nErrorCode	int
Declare		@sSQLString	nvarchar(4000)

Set @nErrorCode = 0

If (@nErrorCode = 0) 
Begin
	Set @sSQLString = "Select OPENITEMNO from OPENITEM where OPENITEMNO = @psOpenItemNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@psOpenItemNo nvarchar(12)',
				@psOpenItemNo = @psOpenItemNo
End

return @nErrorCode
go

grant execute on dbo.[acw_ValidateOpenItemNo]  to public
go