-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_GetAccountLevel
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_GetAccountLevel]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_GetAccountLevel.'
	drop procedure dbo.gl_GetAccountLevel
	print '**** Creating procedure dbo.gl_GetAccountLevel...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.gl_GetAccountLevel
as
  -- blank to create sp so the next ALTER statement will work with no warnings on self called execution.
go

ALTER PROCEDURE dbo.gl_GetAccountLevel
(
	@pnAccountId	int ,
	@pnLevel 	Int 
	)
AS
-- PROCEDURE :	dbo.gl_GetAccountLevel
-- VERSION :	1
-- DESCRIPTION:	Return level of the supplied account
-- SCOPE:	General Ledger
-- CALLED BY :	gl_GetParentAccountAndLevel and gl_GetAccountLevel (recursive)

-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 1 May 2003	MB	1	Procedure created

Begin
	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF
	declare @ErrorCode	int
	declare @iRet int
	declare @iTempParentAccountId	int
	
	Set	@ErrorCode=0
	
	SELECT @iTempParentAccountId =  P.PARENTACCOUNTID 
		from LEDGERACCOUNT P
		where  P.ACCOUNTID= @pnAccountId	
	Select @ErrorCode=@@Error
	
	
	Set @pnLevel = @pnLevel + 1
	if @iTempParentAccountId IS NOT NULL
		begin
			exec @pnLevel = gl_GetAccountLevel @iTempParentAccountId, @pnLevel
		end
	Return @pnLevel
End
go

grant execute on dbo.gl_GetAccountLevel to public
go
