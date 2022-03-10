-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_FinancialYearToPeriodRange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_FinancialYearToPeriodRange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_FinancialYearToPeriodRange.'
	Drop procedure [dbo].[gl_FinancialYearToPeriodRange]
End
Print '**** Creating Stored Procedure dbo.gl_FinancialYearToPeriodRange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_FinancialYearToPeriodRange
(
	@pnFinancialYearFrom	int		      ,
	@pnFinancialYearTo	int		= null,
	@pnPeriodFrom		int		output,
	@pnPeriodTo		int		output
)
as
-- PROCEDURE:	gl_FinancialYearToPeriodRange
-- VERSION:	1
-- SCOPE:	InProma
-- DESCRIPTION:	Convert a financial year range to period range. Receives financial year
--		from and to and output the first and last period from the supplied
--		financial year range.
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 11-Feb-2004  SFOO	8848	1	Procedure created
Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare @nErrorCode 	int,
		@sSql	    	nvarchar(1000),
		@sErrorMessage	nvarchar(397)
	Set @nErrorCode = 0

	If @nErrorCode = 0
	Begin
		If (@pnFinancialYearTo is null)
		Begin
			-- Assume financial year from and to are the same
			Set @pnFinancialYearTo = @pnFinancialYearFrom
		End
	End

	If @nErrorCode = 0
	Begin
		If (@pnFinancialYearTo < @pnFinancialYearFrom)
		Begin
			Set @sErrorMessage = N'Financial year from cannot be later than financial year to.'
			RAISERROR(@sErrorMessage, 16, 1)
			Set @nErrorCode = @@Error			
		End
	End

	If @nErrorCode = 0
	Begin
		Set @sSql = N'Select @pnPeriodFrom=MIN(PERIODID), @pnPeriodTo=MAX(PERIODID)
			      from PERIOD
			      where CONVERT(int, LEFT(CONVERT(nvarchar(12), PERIODID), 4)) >= @pnFinancialYearFrom
		              and CONVERT(int, LEFT(CONVERT(nvarchar(12), PERIODID), 4)) <= @pnFinancialYearTo'
		Exec @nErrorCode=sp_executesql @sSql, 
					       N'@pnFinancialYearFrom int,
						 @pnFinancialYearTo   int,
						 @pnPeriodFrom	      int output,
						 @pnPeriodTo	      int output',
					       @pnFinancialYearFrom,
					       @pnFinancialYearTo,
					       @pnPeriodFrom output,
					       @pnPeriodTo output
	End

	Return @nErrorCode
End
GO

Grant execute on dbo.gl_FinancialYearToPeriodRange to public
GO

--To Run:
--Declare @nPeriodFrom int,
--	@nPeriodTo   int
--Exec dbo.gl_FinancialYearToPeriodRange @pnFinancialYearTo=2002, @pnPeriodFrom=@nPeriodFrom output, @pnPeriodTo=@nPeriodTo output
--print @nPeriodFrom
--print @nPeriodTo
