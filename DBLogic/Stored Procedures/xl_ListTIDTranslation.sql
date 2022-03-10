-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xl_ListTIDTranslation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xl_ListTIDTranslation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xl_ListTIDTranslation.'
	Drop procedure [dbo].[xl_ListTIDTranslation]
End
Print '**** Creating Stored Procedure dbo.xl_ListTIDTranslation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.xl_ListTIDTranslation
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@pnTID			int,		-- Mandatory
	@psForCulture 		nvarchar(10)	= null, 	-- filters the results
	@pbCalledFromCentura	bit		-- Mandatory
)
as
-- PROCEDURE:	xl_ListTIDTranslation
-- VERSION:	2
-- DESCRIPTION:	Populates the TranslatedText result set

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 Sep 2004	TM	RFC1695	1	Procedure created
-- 06 Oct 2004	TM	RFC1695	2	Add the following to the join on the TABLECODES table: "and TC.TABLETYPE = 47".
--					Order result set by LanguageDescription.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Populating SourceText result set
If @nErrorCode = 0 
Begin
	Set @sSQLString = "
	Select  TT.TID			as 'TID',
		TT.CULTURE		as 'Culture',"+CHAR(10)+
		CASE WHEN @pbCalledFromCentura = 1 
		     THEN -- When called from Centura, this should be obtained from
			  -- the client/server Language (TableCodes):
			  "TC.DESCRIPTION	as 'LanguageDescription',"
		     ELSE "C.DESCRIPTION	as 'LanguageDescription'," 	
		END+CHAR(10)+
		-- the translation text should be returned as a long string:
		"ISNULL(CAST(TT.SHORTTEXT AS NTEXT), TT.LONGTEXT)	
					as 'Translation',
		TT.HASSOURCECHANGED	as 'HasSourceChanged'
	from TRANSLATEDTEXT TT"+CHAR(10)+
	CASE WHEN @pbCalledFromCentura = 1 
	     THEN -- When called from Centura, this should be obtained from
		  -- the client/server Language (TableCodes):
		  "join TABLECODES TC 	on (UPPER(TC.USERCODE) = TT.CULTURE"+CHAR(10)+
		  "			and TC.TABLETYPE = 47)"
		  -- Otherwise, obtain from Culture.Description:
	     ELSE "join CULTURE C		on (C.CULTURE = TT.CULTURE)" 	
	END+CHAR(10)+
	"where TT.TID = @pnTID
	and (TT.CULTURE = @psForCulture
	 or  @psForCulture is null)"+CHAR(10)+
	CASE WHEN @pbCalledFromCentura = 1 THEN
	-- Centura may only view languages valid for the code page of the database
	"and exists(	Select 1 
			from 	CULTURECODEPAGE CP
			where 	(CP.CULTURE=TT.CULTURE
			or 	CP.CULTURE=dbo.fn_GetParentCulture(TT.CULTURE))
			-- Compare the culture's collation code to the collation code
			-- of the current database:
			and	CP.CODEPAGE = 	CAST(
							COLLATIONPROPERTY( 
								CONVERT(nvarchar(50), 
									DATABASEPROPERTYEX(db_name(),'collation')),
						 		'codepage') 
						 as smallint))"
	END+CHAR(10)+
	"order by 'LanguageDescription'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTID	int,
					  @psForCulture	nvarchar(10)',
					  @pnTID	= @pnTID,
					  @psForCulture	= @psForCulture

	Set @pnRowCount = @@RowCount
End

Return @nErrorCode
GO

Grant execute on dbo.xl_ListTIDTranslation to public
GO
