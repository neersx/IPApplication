-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetLookupCulture
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetLookupCulture') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetLookupCulture'
	Drop function [dbo].[fn_GetLookupCulture]
End
Print '**** Creating Function dbo.fn_GetLookupCulture...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetLookupCulture
(
	@psRequestedCulture	nvarchar(10),
	@pnLanguageKey		int,
	@pbCalledFromCentura	bit
) 

RETURNS nvarchar(10)
AS
-- Function :	fn_GetLookupCulture
-- VERSION :	3
-- DESCRIPTION:	Return best culture to use when looking up a translation on the database.
--		Null indicates that no translation lookup should be performed.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Aug 2004	JEK	RFC1695	1	Function created
-- 22 Sep 2004	JEK	RFC1695	2	Implement db_name().
-- 02 Apr 2008	MF	SQA16185 3	Improve performance reading SITECONTROL by removing 
--					the use of UPPER in the key join.

Begin

declare @sLookupCulture nvarchar(10)
declare @sParentCulture	nvarchar(10)

-- Convert client/server language to culture
If @psRequestedCulture is null
and @pnLanguageKey is not null
Begin
	select @sLookupCulture=upper(USERCODE)
	FROM TABLECODES
	WHERE TABLECODE=@pnLanguageKey
End
Else
Begin
	set @sLookupCulture = upper(@psRequestedCulture)
End

-- Is it the database culture?
If @sLookupCulture is not null
Begin
	-- The primary data on the database is held in this culture,
	-- so there is no need to look up a translation
	select @sLookupCulture = null
	from SITECONTROL
	WHERE CONTROLID = 'Database Culture'
	and upper(COLCHARACTER)=@sLookupCulture
End

-- Get the parent culture
If @sLookupCulture is not null
Begin
	Set @sParentCulture = dbo.fn_GetParentCulture(@sLookupCulture)
End

-- If called from Centura, is it a valid Centura culture?
If @sLookupCulture is not null
and @pbCalledFromCentura = 1
Begin
	-- If it is not a valid client/server language, don't look for a translation
	If not exists(
		select 1 
		from	CULTURECODEPAGE CP
		where   CP.CODEPAGE	= cast(COLLATIONPROPERTY( 
						convert(nvarchar(50),DATABASEPROPERTYEX(db_name(), 'collation' )),
						'codepage' ) 
				 	 as smallint)	
		and (CP.CULTURE=@sLookupCulture
		or CP.CULTURE=@sParentCulture))
	Begin
		Set @sLookupCulture=null
	End

End

-- Are there any translations on the database for the culture?
If @sLookupCulture is not null
Begin
	If not exists(select 1 from TRANSLATEDTEXT WHERE CULTURE=@sLookupCulture)
	Begin
		-- If the culture is a language and region combination,
		-- extract the language on its own.
		If @sParentCulture is not null
		and exists(select 1 from TRANSLATEDTEXT WHERE CULTURE=@sParentCulture)
		Begin
			set @sLookupCulture = @sParentCulture
		End
		Else
		Begin
			set @sLookupCulture = null
		End
	End
End
	
return @sLookupCulture

End
GO

grant execute on dbo.fn_GetLookupCulture to public
go
