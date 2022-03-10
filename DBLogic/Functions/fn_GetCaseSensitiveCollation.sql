-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCaseSensitiveCollation
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCaseSensitiveCollation') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetCaseSensitiveCollation.'
	drop function dbo.fn_GetCaseSensitiveCollation
	print '**** Creating function dbo.fn_GetCaseSensitiveCollation...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetCaseSensitiveCollation()

Returns nvarchar(100)

-- FUNCTION :	fn_GetCaseSensitiveCollation
-- VERSION :	2
-- DESCRIPTION:	This function returns the case and accent sensitive collation 
--		based on the current database collation.

-- Date		Who	Number		Version	Description
-- ===========	===	===========	=======	==========================================
-- 24 Sep 2015	AT 	R51616		1	Function created.
-- 20 Jan 2016	MF	R57243		2	Convert to NVARCHAR did not specify length and was truncating
--						to 30 characters.  Also the collation was being extracted for
--						the server instead of the database.

as
Begin

	Declare @sReturnCollation nvarchar(100)
	
	Select @sReturnCollation = CONVERT(nvarchar(100), DATABASEPROPERTYEX(db_name(),'collation'))
	Set @sReturnCollation = Replace(@sReturnCollation, '_CI', '_CS')
	Set @sReturnCollation = Replace(@sReturnCollation, '_AI', '_AS')
	
	Return @sReturnCollation
End
go

grant execute on dbo.fn_GetCaseSensitiveCollation to public
GO
