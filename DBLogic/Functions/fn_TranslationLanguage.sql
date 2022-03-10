-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_TranslationLanguage
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_TranslationLanguage') and xtype='TF')
Begin
	Print '**** Drop Function dbo.fn_TranslationLanguage'
	Drop function [dbo].[fn_TranslationLanguage]
End
Print '**** Creating Function dbo.fn_TranslationLanguage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_TranslationLanguage
(
	@psCulture		nvarchar(10), -- The language in which the descrptions are required
	@pbCalledFromCentura	bit
) 
returns @tbTranslatedLanguage TABLE
   (
        LANGUAGEKEY		int		NULL,
        LANGUAGEDESCRIPTION	nvarchar(80)	collate database_default NULL,
	CULTURE			nvarchar(10)	collate database_default NULL,
	CULTUREDESCRIPTION	nvarchar(100)	collate database_default NULL,
	ISTRANSLATED		bit
   )
AS
-- Function :	fn_TranslationLanguage
-- VERSION :	2
-- DESCRIPTION:	Return the list of languages for which translations may be recorded.
--		This maps the .net Culture to the client/server Language.
--		For client/server, this list is limited to languages that match
--		the code page of the database.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Aug 2004	JEK	RFC1695	1	Function created
-- 22 Sep 2004	JEK	RFC1695	2	Implement db_name()

Begin

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Is a translation required?
If @sLookupCulture is not null
and (dbo.fn_GetTranslatedTIDColumn('CULTURE','DESCRIPTION') is not null
 or dbo.fn_GetTranslatedTIDColumn('TABLECODES','DESCRIPTION') is not null)
Begin
	If @pbCalledFromCentura = 1
	Begin
		insert 	into @tbTranslatedLanguage (LANGUAGEKEY, LANGUAGEDESCRIPTION, CULTURE, CULTUREDESCRIPTION,ISTRANSLATED)
		SELECT	T.TABLECODE, 
			dbo.fn_GetTranslationLimited(T.DESCRIPTION,null,T.DESCRIPTION_TID,@sLookupCulture),
			C.CULTURE, 
			dbo.fn_GetTranslationLimited(C.DESCRIPTION,null,C.DESCRIPTION_TID,@sLookupCulture),
			C.ISTRANSLATED
		from	TABLECODES T
		join	CULTURE C		ON (C.CULTURE=upper(T.USERCODE))
		where	T.TABLETYPE = 47
		-- Centura may only view languages valid for the code page of the database
		and exists
			(select 1 
			from 	CULTURECODEPAGE CP
			where 	(CP.CULTURE=C.CULTURE
			or 	CP.CULTURE=dbo.fn_GetParentCulture(C.CULTURE))
			and	CP.CODEPAGE	= cast(COLLATIONPROPERTY( 
							convert(nvarchar(50),DATABASEPROPERTYEX(db_name(), 'collation' )),
							 'codepage' ) 
						  as smallint)
			)
	End
	Else
	Begin
		insert 	into @tbTranslatedLanguage (LANGUAGEKEY, LANGUAGEDESCRIPTION, CULTURE, CULTUREDESCRIPTION, ISTRANSLATED)
		SELECT	T.TABLECODE, 
			dbo.fn_GetTranslation(T.DESCRIPTION,null,T.DESCRIPTION_TID,@sLookupCulture),
			C.CULTURE, 
			dbo.fn_GetTranslation(C.DESCRIPTION,null,C.DESCRIPTION_TID,@sLookupCulture),
			C.ISTRANSLATED
		from	CULTURE C
		left join TABLECODES T	ON (T.TABLECODE=dbo.fn_GetLanguage(C.CULTURE))
	
	End
End
-- No translation is required
Else
Begin
	If @pbCalledFromCentura = 1
	Begin
		insert 	into @tbTranslatedLanguage (LANGUAGEKEY, LANGUAGEDESCRIPTION, CULTURE, CULTUREDESCRIPTION,ISTRANSLATED)
		SELECT	T.TABLECODE, T.DESCRIPTION, C.CULTURE, C.DESCRIPTION, C.ISTRANSLATED
		from	TABLECODES T
		join	CULTURE C		ON (C.CULTURE=upper(T.USERCODE))
		where	T.TABLETYPE = 47
		-- Centura may only view languages valid for the code page of the database
		and exists
			(select 1 
			from 	CULTURECODEPAGE CP
			where 	(CP.CULTURE=C.CULTURE
			or 	CP.CULTURE=dbo.fn_GetParentCulture(C.CULTURE))
			and	CP.CODEPAGE	= cast(COLLATIONPROPERTY( 
							convert(nvarchar(50),DATABASEPROPERTYEX(db_name(), 'collation' )),
							 'codepage' ) 
						  as smallint)
			)
	End
	Else
	Begin
		insert 	into @tbTranslatedLanguage (LANGUAGEKEY, LANGUAGEDESCRIPTION, CULTURE, CULTUREDESCRIPTION, ISTRANSLATED)
		SELECT	T.TABLECODE, T.DESCRIPTION, C.CULTURE, C.DESCRIPTION, C.ISTRANSLATED
		from	CULTURE C
		left join TABLECODES T	ON (T.TABLECODE=dbo.fn_GetLanguage(C.CULTURE))
	
	End
End


return
End
GO

grant REFERENCES, SELECT on dbo.fn_TranslationLanguage to public
go
