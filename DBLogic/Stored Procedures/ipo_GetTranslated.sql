-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipo_GetTranslated
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipo_GetTranslated]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipo_GetTranslated.'
	drop procedure dbo.ipo_GetTranslated
	print '**** Creating procedure dbo.ipo_GetTranslated...'
	print ''
end
go

create proc dbo.ipo_GetTranslated
	@pnLanguage int, 
	@psDataToTranslate varchar(254) ,
	@prsTranslatedData varchar(254) output

as

-- PROCEDURE 	: ipo_GetTranslated
-- VERSION 	: 2.1.0
-- DESCRIPTION	:	
-- CALLED BY 	:	

-- MODIFICATIONS:
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17/03/2004	ABELL			Clean up of grant statement

SELECT 	@prsTranslatedData = TRANSLATEDDATA
FROM 	TRANSLATEDATA
WHERE 	LANGUAGE = @pnLanguage
AND 	DATATOTRANSLATE = @psDataToTranslate

IF @prsTranslatedData IS NULL
	SELECT @prsTranslatedData = @psDataToTranslate
go

grant execute on dbo.ipo_GetTranslated to public
go
