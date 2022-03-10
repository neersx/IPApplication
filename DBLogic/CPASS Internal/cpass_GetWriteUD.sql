use cpalive
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cpass_GetWriteUD]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[cpass_GetWriteUD]
GO


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO



CREATE     PROCEDURE dbo.cpass_GetWriteUD
(
	--@psEntity			nvarchar(20)	= null,  -- the Entity to be reported on
	@psFamily			nvarchar(20)	= null  -- the Family of Cases to be reported on
)
AS
-- PROCEDURE :	cpass_GetWriteUD
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
	select 	REASON.DESCRIPTION,
		isnull(sum(-WORKHISTORY.LOCALTRANSVALUE),0)

	FROM	CASES
	join	WORKHISTORY on ( CASES.CASEID = WORKHISTORY.CASEID
				and   WORKHISTORY.STATUS <> 0
				and   WORKHISTORY.MOVEMENTCLASS in (3,9) ) 
	join	REASON on ( REASON.REASONCODE = WORKHISTORY.REASONCODE ) 
		
	WHERE	CASES.FAMILY = @psFamily
	group by 	
		CASES.FAMILY,
		REASON.DESCRIPTION

	Set @ErrorCode=@@Error
End

Return @ErrorCode


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

--exec [dbo].[cpass_GetWriteUD] 'AAT01'
--go


grant execute on [dbo].[cpass_GetWriteUD] to public
go