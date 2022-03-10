-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetTranslationLimited
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_GetTranslationLimited') and xtype='FN')
Begin
	print '**** Drop function dbo.fn_GetTranslationLimited.'
	drop function dbo.fn_GetTranslationLimited
	print '**** Creating function dbo.fn_GetTranslationLimited...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_GetTranslationLimited
(
	@psShortSourceData	nvarchar(max),
	@ptLongSourceData	ntext,
	@pnTID			int,
	@psRequiredCulture	nvarchar(10)	
)
RETURNS nvarchar(254)
   
-- FUNCTION :	fn_GetTranslationLimited
-- VERSION :	2
-- DESCRIPTION:	This function returns the translation for the source data,
--		limited to 254 characters for use by client/server.
--		If none is found, the source data is returned.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 26 Aug 2004	JEK	RFC1695	1	Function created
-- 14 Apr 2011	MF	10475	2	Change nvarchar(4000) to nvarchar(max)
AS
Begin

Return cast(dbo.fn_GetTranslation(@psShortSourceData, @ptLongSourceData, @pnTID, @psRequiredCulture) as nvarchar(254))

End
GO

Grant execute on dbo.fn_GetTranslationLimited to public
GO
