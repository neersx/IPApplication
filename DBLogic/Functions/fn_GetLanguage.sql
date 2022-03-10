-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetLanguage
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_GetLanguage') and xtype='FN')
Begin
	print '**** Drop function dbo.fn_GetLanguage.'
	drop function dbo.fn_GetLanguage
	print '**** Creating function dbo.fn_GetLanguage...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_GetLanguage
(
	@psCulture	nvarchar(10)	
)
RETURNS int
   
-- FUNCTION :	fn_GetLanguage
-- VERSION :	2
-- DESCRIPTION:	This function returns the InPro language code for the supplied culture.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 24-Oct-2003	TM	RFC544	1	Function created
-- 09-Sep-2004	JEK	RFC1695	2	Implement fn_GetParentCulture().
AS
Begin

	-- The InPro language code for the supplied culture
	Declare @nLanguageCode	int

	-- Case insensitive search for the @psCulture  
	Set @psCulture		= upper(@psCulture)    	

	-- The following will return the TableCode that matches the Culture exactly
	select @nLanguageCode=TABLECODE
	from TABLECODES 
	where TABLETYPE=47
	and upper(USERCODE)=@psCulture

	-- If the language has not been found then try and match on the 
	-- neutral culture which are the characters up to the hyphen
	If @nLanguageCode is null
	Begin
		select @nLanguageCode=TABLECODE
		from TABLECODES 
		where TABLETYPE=47
		and upper(USERCODE)= dbo.fn_GetParentCulture(@psCulture)
	End
		
	Return @nLanguageCode
End
GO

Grant execute on dbo.fn_GetLanguage to public
GO
