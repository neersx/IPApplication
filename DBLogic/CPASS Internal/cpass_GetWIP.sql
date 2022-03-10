use cpalive
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cpass_GetWIP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[cpass_GetWIP]
GO


CREATE     PROCEDURE dbo.cpass_GetWIP
(
	--@psEntity			nvarchar(20)	= null,  -- the Entity to be reported on
	@psFamily			nvarchar(20)	= null  -- the Family of Cases to be reported on
)
AS
-- PROCEDURE :	cpass_GetWIP
-- DESCRIPTION:	Gets the WIP entries for the Detailed Project Status Report
-- NOTES:	
-- VERSION:	1
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 10 Jun 2006	JD		1	Procedure created


Set nocount on
Set concat_null_yields_null off

-- Declare a temporary table to hold the result returned from 
-- the cs_GetBudgetDetails table

Declare	@ErrorCode	int
declare @ClientName 	nvarchar(254)

set @ErrorCode = 0

If @ErrorCode=0
Begin
	SELECT	WORKINPROGRESS.TRANSDATE,
		WORKINPROGRESS.LOCALVALUE,
		WORKINPROGRESS.BALANCE
	FROM	CASES
	join	WORKINPROGRESS on ( CASES.CASEID = WORKINPROGRESS.CASEID ) 
		
	WHERE	CASES.FAMILY = @psFamily
	AND 	WORKINPROGRESS.STATUS IN (1, 2)

	Set @ErrorCode=@@Error
End

Return @ErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

--EXEC [dbo].[cpass_GetWIP] 'AAT01'
--go

grant execute on [dbo].[cpass_GetWIP] to public
go