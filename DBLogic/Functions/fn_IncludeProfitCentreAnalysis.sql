-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IncludeProfitCentreAnalysis
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IncludeProfitCentreAnalysis') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_IncludeProfitCentreAnalysis'
	Drop function [dbo].[fn_IncludeProfitCentreAnalysis]
End
Print '**** Creating Function dbo.fn_IncludeProfitCentreAnalysis...'
Print ''
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_IncludeProfitCentreAnalysis
(
	@psProfitCentreCodes 	nvarchar(2000),
	@pnAnalysisTypeId 	int,
	@psAnalysisCodeIds 	nvarchar(1000),
	@psSQLSegment 		nvarchar(10),
	@psColumn     		nvarchar(50) = null
) 
RETURNS nvarchar(1500)
AS
-- Function :	fn_IncludeProfitCentreAnalysis
-- VERSION :	1.0.0
-- DESCRIPTION:	
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 12/08/03	Created
-- 27/10/03	Order by Analysis Type Description then Code Description.
-- 11/02/04	Increase size for profit centre code list and analysis id list
Begin	
	declare @TTC_PROFITCENTRERULE_TYPE nvarchar(7) -- Constant for table type
	set @TTC_PROFITCENTRERULE_TYPE = '83'

	declare @sResult nvarchar(1500)
	Set @sResult = ''

	if (@psProfitCentreCodes is NULL) OR 
	   (@pnAnalysisTypeId is NULL) OR
           (@psAnalysisCodeIds is NULL)
	begin
		if ( UPPER(@psSQLSegment) = 'SELECT' )
			Set @sResult = ' NULL, NULL, NULL, NULL, '
		return @sResult
	end
	
	if ( UPPER(@psSQLSegment) = 'SELECT' )

		Set @sResult = ' TC.TABLECODE, TC.DESCRIPTION, AC.CODEID, AC.DESCRIPTION, '

	else if ( UPPER(@psSQLSegment) = 'FROM' )

		Set @sResult = ' INNER JOIN PROFITCENTRERULE PCR ON (' +
					@psColumn + ' = PCR.PROFITCENTRECODE) ' +
				'INNER JOIN ANALYSISCODE AC ON (PCR.ANALYSISCODE = AC.CODEID AND ' +
					'AC.TYPEID = ' + CONVERT(nvarchar(12), @pnAnalysisTypeId) +
					' AND AC.CODEID IN (' + @psAnalysisCodeIds + ') ) ' +
				'INNER JOIN TABLECODES TC ON (AC.TYPEID = TC.TABLECODE AND ' +
								'TC.TABLETYPE = ' + 
								@TTC_PROFITCENTRERULE_TYPE + ')'

	else if ( UPPER(@psSQLSegment) = 'ORDER' )
		Set @sResult = ' TC.DESCRIPTION, AC.DESCRIPTION, '
	
	return @sResult
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_IncludeProfitCentreAnalysis to public
go
