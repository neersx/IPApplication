-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_appsFilterEligibleCasesForComparison
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_appsResolveCriticalEventMappings') and xtype in ('IF', 'TF'))
Begin
	Print '**** Drop Function dbo.fn_appsResolveCriticalEventMappings'
	Drop function [dbo].fn_appsResolveCriticalEventMappings
End
Print '**** Creating Function dbo.fn_appsResolveCriticalEventMappings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_appsResolveCriticalEventMappings
(
	@psMapDescriptions	nvarchar(max) = 'Application,Publication,Registration/Grant',
	@psSystemCode		nvarchar(50) = 'Innography'
) 
RETURNS Table 
AS
-- Function :	fn_appsResolveCriticalEventMappings
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return critical mapped events given the data source required.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Jul 2017	SF		DR-32729	1		Function created

return
	select Codes.Parameter as Code, cast(dbo.fn_appsResolveMapping(MS.STRUCTUREID, ES.SCHEMEID, Codes.Parameter, DS.DATASOURCECODE) as int) as MappedEventId
	from dbo.fn_Tokenise(@psMapDescriptions, ',') Codes 
	join DATASOURCE DS on DS.DATASOURCECODE =  @psSystemCode
	join MAPSTRUCTURE MS on  MS.STRUCTURENAME = 'Events'
	join ENCODINGSCHEME ES on ES.SCHEMECODE = 'CPAXML'

GO

grant references, select on dbo.fn_appsResolveCriticalEventMappings to public
go
