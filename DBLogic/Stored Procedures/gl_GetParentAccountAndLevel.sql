-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_GetParentAccountAndLevel
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_GetParentAccountAndLevel]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_GetParentAccountAndLevel.'
	drop procedure dbo.gl_GetParentAccountAndLevel
	print '**** Creating procedure dbo.gl_GetParentAccountAndLevel...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.gl_GetParentAccountAndLevel
(
	@pnAccountId		int ,
	@pbCalledFromCentura	tinyint = 0,
	@pnParentAccountId	int output,
	@pnLevel		int output
)
AS
-- PROCEDURE :	gl_GetParentAccountAndLevel
-- VERSION :	1
-- DESCRIPTION:	Returns the ledger account level and parent account id.
-- SCOPE:	General Ledger
-- CALLED BY :	DataAccess directly as well as Centura

-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 21 Feb 2003	MB	1	Procedure created
Begin
	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF

	declare @ErrorCode	int
	declare @iRet	int
	declare @sSQLString	nvarchar(4000)

	set @ErrorCode=0

	SELECT @pnParentAccountId =  P.PARENTACCOUNTID 
	from LEDGERACCOUNT P 
	where  P.ACCOUNTID= @pnAccountId	

	if @pnParentAccountId IS NOT NULL
		begin
			Set @iRet = 1
			exec @pnLevel = gl_GetAccountLevel @pnAccountId, 0
		end
	else
		Begin
			Set @pnParentAccountId = @pnAccountId
			Set @iRet = 0
			Set @pnLevel = 1
		End
	if @pbCalledFromCentura = 1
	select @pnParentAccountId, @pnLevel
	RETURN @iRet
End
go

grant execute on dbo.gl_GetParentAccountAndLevel to public
go
