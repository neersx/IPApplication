-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_appsResolveEventMapping
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_appsResolveEventMapping') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_appsResolveEventMapping'
	Drop function [dbo].[fn_appsResolveEventMapping]
End
Print '**** Creating Function dbo.fn_appsResolveEventMapping...'
Print ''
GO


-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_appsResolveMapping
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_appsResolveMapping') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_appsResolveMapping'
	Drop function [dbo].[fn_appsResolveMapping]
End
Print '**** Creating Function dbo.fn_appsResolveMapping...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE FUNCTION [dbo].[fn_appsResolveMapping]
(
	@pnStructureId		int,
	@pnFallbackScheme	int,
	@psMapDescription	nvarchar(50),
	@psSystemCode		nvarchar(50)
) 
RETURNS nvarchar(50)
AS
-- Function :	fn_appsResolveMapping
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the mapped data from the requested data structure

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 10 Aug 2017	SF		DR-33425	1		Function created

begin
    declare @sResult NVARCHAR(50)
    declare @nDataSourceId INT

	select @nDataSourceId = DS.DATASOURCEID
	from DATASOURCE DS 
	where DS.DATASOURCECODE = @psSystemCode

    select top 1 @sResult = MAPPED.CODE
    from   (select null as CODE,
                   1    as [PRIORITY]
            from   MAPPING [RAW_CODE_IGNORED]
            where  [RAW_CODE_IGNORED].INPUTCODE = @psMapDescription
                   and [RAW_CODE_IGNORED].STRUCTUREID = @pnStructureId
                   and [RAW_CODE_IGNORED].DATASOURCEID = @nDataSourceId
                   and [RAW_CODE_IGNORED].ISNOTAPPLICABLE = 1
            union
			select null as CODE,
                   2    as [PRIORITY]
            from   MAPPING [RAW_DESCRIPTION_IGNORED]
            where  [RAW_DESCRIPTION_IGNORED].INPUTDESCRIPTION = @psMapDescription
                   and [RAW_DESCRIPTION_IGNORED].STRUCTUREID = @pnStructureId
                   and [RAW_DESCRIPTION_IGNORED].DATASOURCEID = @nDataSourceId
                   and [RAW_DESCRIPTION_IGNORED].ISNOTAPPLICABLE = 1
            union
            select coalesce([COMMON].CODE, [RAW_CODE].OUTPUTVALUE) as CODE,
                   3                                          as [PRIORITY]
            from   MAPPING [RAW_CODE]
                   -- Common Encoding scheme							
                   left join ENCODEDVALUE [COMMON]
                          on ( [COMMON].CODEID = [RAW_CODE].OUTPUTCODEID and [COMMON].SCHEMEID = -1 )
            where  [RAW_CODE].INPUTCODE = @psMapDescription
                   and [RAW_CODE].STRUCTUREID = @pnStructureId
                   and [RAW_CODE].DATASOURCEID = @nDataSourceId
            union
            select coalesce([COMMON].CODE, [RAW_DESCRIPTION].OUTPUTVALUE) as CODE,
                   4                                          as [PRIORITY]
            from   MAPPING [RAW_DESCRIPTION]
                   -- Common Encoding scheme							
                   left join ENCODEDVALUE [COMMON]
                          on ( [COMMON].CODEID = [RAW_DESCRIPTION].OUTPUTCODEID and [COMMON].SCHEMEID = -1 )
            where  [RAW_DESCRIPTION].INPUTDESCRIPTION = @psMapDescription
                   and [RAW_DESCRIPTION].STRUCTUREID = @pnStructureId
                   and [RAW_DESCRIPTION].DATASOURCEID = @nDataSourceId
            union
            select coalesce([COMMON].CODE, [FALLBACK_DIRECT].OUTPUTVALUE) as CODE,
                   5                                                    as [PRIORITY]
            from   MAPPING [FALLBACK]
                   -- FALLBACK Encoding scheme	
                   left join ENCODEDVALUE [FALLBACKINPUT]
                          on ( [FALLBACKINPUT].CODE = @psMapDescription
                               and [FALLBACKINPUT].SCHEMEID = @pnFallbackScheme)
                   left join MAPPING [FALLBACK_COMMON]
                          on ( [FALLBACK_COMMON].STRUCTUREID = @pnStructureId
                               and [FALLBACK_COMMON].INPUTCODEID = [FALLBACKINPUT].CODEID
                               and [FALLBACK_COMMON].OUTPUTCODEID is not null )
                   -- Common Encoding scheme							
                   left join ENCODEDVALUE [COMMON]
                          on ( [COMMON].CODEID = [FALLBACK_COMMON].OUTPUTCODEID
                               and [COMMON].SCHEMEID = -1 )
                   left join MAPPING [FALLBACK_DIRECT]
                          on ( [FALLBACK_DIRECT].STRUCTUREID = @pnStructureId
                               and [FALLBACK_DIRECT].INPUTCODEID = [FALLBACKINPUT].CODEID
                               and [FALLBACK_DIRECT].OUTPUTVALUE is not null )
            where  [FALLBACK].STRUCTUREID = @pnStructureId
                   and [FALLBACK].INPUTCODEID = [FALLBACKINPUT].CODEID
                   and [FALLBACK].ISNOTAPPLICABLE <> 1) as MAPPED
    order  by MAPPED.[PRIORITY]

    return @sResult
end 

GO

grant execute on dbo.fn_appsResolveMapping to public
go
