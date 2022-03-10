-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_UpdateAccount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[acw_UpdateAccount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop Stored Procedure  dbo.acw_UpdateAccount.'
	drop procedure dbo.acw_UpdateAccount
End
print '**** Creating Stored Procedure dbo.acw_UpdateAccount...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_UpdateAccount
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura		bit		= 0,
	@pnEntityKey			int,
	@pnNameKey			int,
	@pnDRAdjustment			decimal(12,2)	= null,
	@pnCRAdjustment			decimal(12,2)	= null
)
-- PROCEDURE :	acw_UpdateAccount
-- VERSION :	2
-- DESCRIPTION:	Adjust the Name's Account
-- CALLED BY :	Inprotech Web

-- MODIFICTIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------------	-------	----------------------------------------------- 
-- 01 Oct 2011	AT	RFC9012		1	Procedure created.
-- 26 Oct 2011	AT	RFC10168	2	Fixed syntax errors.

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString		nvarchar(max)
Declare @nErrorCode		int

Set @nErrorCode = 0

If not exists (select * from ACCOUNT WHERE ENTITYNO = @pnEntityKey AND NAMENO = @pnNameKey)
Begin
	Set @sSQLString = 'insert into ACCOUNT (ENTITYNO, NAMENO, BALANCE, CRBALANCE)
			VALUES (@pnEntityKey, @pnNameKey, isnull(@pnDRAdjustment,0), isnull(@pnCRAdjustment,0))'
End
Else
Begin
	Set @sSQLString = 'update ACCOUNT'
	
	if (@pnDRAdjustment is not null)
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'set BALANCE = isnull(BALANCE,0) + @pnDRAdjustment'
	End
	Else if (@pnCRAdjustment is not null)
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'set CRBALANCE = isnull(CRBALANCE,0) + @pnCRAdjustment'
	End
	
	Set @sSQLString = @sSQLString + char(10) + 'where ENTITYNO = @pnEntityKey' +
					char(10) + 'and NAMENO = @pnNameKey'
End

if (@pnDRAdjustment is not null or @pnCRAdjustment is not null)
Begin

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnEntityKey	int,
				@pnNameKey	int,
				@pnDRAdjustment	decimal(12,2),
				@pnCRAdjustment decimal(12,2)',
				@pnEntityKey = @pnEntityKey,
				@pnNameKey = @pnNameKey,
				@pnDRAdjustment = @pnDRAdjustment,
				@pnCRAdjustment = @pnCRAdjustment
End

RETURN @nErrorCode
GO

Grant execute on dbo.acw_UpdateAccount  to public
GO