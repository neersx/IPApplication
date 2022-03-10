-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_GetTranslated
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_GetTranslated]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_GetTranslated.'
	drop procedure dbo.ipr_GetTranslated
	print '**** Creating procedure dbo.ipr_GetTranslated...'
	print ''
end
go

create proc dbo.ipr_GetTranslated
	@pnLanguage int, @psDataToTranslate varchar(254)
as

-- PROCEDURE 	: ipr_GetTranslated
-- VERSION 	: 2.1.0
-- DESCRIPTION	:	
-- MODIFICATIONS:
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17/03/2004	abell			Modify syntax in grant statement

DECLARE @Translated varchar(254)

SELECT @Translated = TRANSLATEDDATA
FROM TRANSLATEDATA
WHERE LANGUAGE = @pnLanguage
AND DATATOTRANSLATE = @psDataToTranslate

IF @Translated IS NULL
	SELECT @Translated = @psDataToTranslate

SELECT @Translated
go

GRANT EXECUTE on dbo.ipr_GetTranslated to public
go
