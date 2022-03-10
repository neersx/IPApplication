use cpalive
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cpass_GetDebtors]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[cpass_GetDebtors]
GO


CREATE     PROCEDURE dbo.cpass_GetDebtors
(
	@psFamily			nvarchar(20)	= null  -- the Family of Cases to be reported on
)
AS
-- PROCEDURE :	cpass_GetDebtors
-- DESCRIPTION:	Gets the debtors for the Detailed Project Status Report
-- NOTES:	
-- VERSION:	1
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 10 Jun 2006	JD		1	Procedure created


Set nocount on
Set concat_null_yields_null off

Declare	@ErrorCode	int
declare @ClientName 	nvarchar(254)

set @ErrorCode = 0

If @ErrorCode=0
Begin
	
	SELECT 	OI.ITEMDATE,  
		OI.LOCALVALUE, 
		OI.LOCALBALANCE
	from	( 
		SELECT 	 distinct N.NAMENO
		FROM  	CASES C
		join	CASENAME CN on ( CN.CASEID=C.CASEID )
		join	NAME N on ( N.NAMENO = CN.NAMENO )
		WHERE 	C.FAMILY     = @psFamily 
		AND   	C.PROPERTYTYPE <> 'I'
		AND   	CN.NAMETYPE  = 'I'
		AND	CN.SEQUENCE = ( 	SELECT 	MIN(CN2.SEQUENCE) 
					FROM 	CASENAME CN2 
					WHERE 	CN2.NAMETYPE  = 'I' 
					AND	CN2.CASEID=C.CASEID ) ) as N
	join	OPENITEM   OI on ( OI.ACCTDEBTORNO = N.NAMENO )
	where	STATUS <> 0 
	AND 	CLOSEPOSTPERIOD = 999999

	Set @ErrorCode=@@Error
End

Return @ErrorCode


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

--EXEC [dbo].[cpass_GetDebtors] 'AAT01'
--go



grant execute on [dbo].[cpass_GetDebtors] to public
go