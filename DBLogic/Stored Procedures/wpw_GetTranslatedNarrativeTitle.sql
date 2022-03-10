-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wpw_GetTranslatedNarrativeTitle
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wpw_GetTranslatedNarrativeTitle]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wpw_GetTranslatedNarrativeTitle.'
	Drop procedure [dbo].[wpw_GetTranslatedNarrativeTitle]
End
Print '**** Creating Stored Procedure dbo.wpw_GetTranslatedNarrativeTitle...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wpw_GetTranslatedNarrativeTitle
(
	@psTranslatedNarrativeTitle nvarchar(max) = null output,
	@pnNarrativeKey			int,
	@psCulture				nvarchar(10) = null
)
as
-- PROCEDURE:	wpw_GetTranslatedNarrativeTitle
-- VERSION:		1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Translation wrapper procedure to get the translated NarrativeTitle for a Narrative.

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	-----------	-------	----------------------------------------------- 
-- 15-Jul-2013	AT		SDR9995		1		Procedure created.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode int
declare @sSQLString nvarchar(1000)
declare @sLookupCulture nvarchar(10)

Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

Set @sSQLString = 'SELECT @psTranslatedNarrativeTitle = ' + dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETITLE',NULL,'N',@sLookupCulture,NULL) + char(10) +
'FROM NARRATIVE N WHERE N.NARRATIVENO = @pnNarrativeKey'

exec @nErrorCode = sp_executesql @sSQLString,
				 N'@psTranslatedNarrativeTitle nvarchar(max) output,
					@pnNarrativeKey int',
					@psTranslatedNarrativeTitle = @psTranslatedNarrativeTitle output,
					@pnNarrativeKey = @pnNarrativeKey

Return @nErrorCode
GO

Grant execute on dbo.wpw_GetTranslatedNarrativeTitle to public
GO
