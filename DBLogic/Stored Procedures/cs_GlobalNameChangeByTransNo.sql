-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalNameChangeByTransNo
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_GlobalNameChangeByTransNo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_GlobalNameChangeByTransNo.'
	drop procedure dbo.cs_GlobalNameChangeByTransNo
end
print '**** Creating procedure dbo.cs_GlobalNameChangeByTransNo...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_GlobalNameChangeByTransNo
	@pnUserIdentityId		int		= null,
	@pnTransNo			int			-- Used to identify 1 or more CASENAMEREQUEST rows
AS
-- PROCEDURE :	cs_GlobalNameChangeByTransNo  
-- VERSION:	1
-- DESCRIPTION:	Loops through each CASENAMEREQUEST row with the transaction number passed
--		to the stored procedure and calls cs_GlobalNameChange for the specific request.
-- COPYRIGHT	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Jun 2008	MF	16430	1	Procedure created

set nocount on

-- VARIABLES

declare @ErrorCode		int
declare @TranCountStart		int
declare @nRequestNo		int
declare @sSQLString		nvarchar(4000)

set @ErrorCode=0

If @ErrorCode=0
Begin
	--------------------------------
	-- Get the first RequestNo from
	-- CASENAMEREQUEST with the 
	-- transaction number provided.
	--------------------------------
	Set @sSQLString="
	select @nRequestNo=min(REQUESTNO)
	from CASENAMEREQUEST
	where LOGTRANSACTIONNO=@pnTransNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nRequestNo		int	OUTPUT,
				  @pnTransNo		int',
				  @nRequestNo	=@nRequestNo	OUTPUT,
				  @pnTransNo	=@pnTransNo
End

-----------------------
-- Loop through each
-- CASENAMEREQUEST row.
-----------------------
While @nRequestNo is not null
and @ErrorCode=0
Begin
	-- Call Global Name Change for the 
	-- specific request

	exec cs_GlobalNameChange
			@pnUserIdentityId=@pnUserIdentityId,
			@pbSuppressOutput=1,
			@pnRequestNo     =@nRequestNo

	--------------------------------
	-- Get the next RequestNo from
	-- CASENAMEREQUEST with the 
	-- transaction number provided.
	--------------------------------
	Set @sSQLString="
	select @nRequestNo=min(REQUESTNO)
	from CASENAMEREQUEST
	where LOGTRANSACTIONNO=@pnTransNo
	and REQUESTNO>@nRequestNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nRequestNo		int	OUTPUT,
				  @pnTransNo		int',
				  @nRequestNo	=@nRequestNo	OUTPUT,
				  @pnTransNo	=@pnTransNo
End

RETURN @ErrorCode
go

grant execute on dbo.cs_GlobalNameChangeByTransNo  to public
go
