-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetTranslatedTIDColumn
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetTranslatedTIDColumn') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetTranslatedTIDColumn'
	Drop function [dbo].[fn_GetTranslatedTIDColumn]
End
Print '**** Creating Function dbo.fn_GetTranslatedTIDColumn...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetTranslatedTIDColumn
(
	@psTableName	nvarchar(30),
	@psColumnName	nvarchar(30)	-- Provide either the short or long column names
) 
RETURNS nvarchar(50)
AS
-- Function :	fn_GetTranslatedTIDColumn
-- VERSION :	1
-- DESCRIPTION:	Return the name of the column containing the pointer to the translations.
--		Null indicates that translations should not be looked up for the column.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Aug 2004	JEK	RFC1695	1	Function created

Begin
declare @sResult nvarchar(30)

Select @sResult = TIDCOLUMN
From 	TRANSLATIONSOURCE
Where 	TABLENAME = @psTableName
and	(SHORTCOLUMN = @psColumnName or LONGCOLUMN = @psColumnName)
and	INUSE = 1
	
return @sResult
End
GO

grant execute on dbo.fn_GetTranslatedTIDColumn to public
go
