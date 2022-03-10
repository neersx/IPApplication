-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ExistsInSplitString
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ExistsInSplitString') and xtype='FN')
Begin
	print '**** Drop function dbo.fn_ExistsInSplitString.'
	drop function dbo.fn_ExistsInSplitString
End
print '**** Creating function dbo.fn_ExistsInSplitString...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_ExistsInSplitString
(
	@psString1	nvarchar(4000),
	@psString2	nvarchar(4000),
	@psSearchText   nvarchar(4000)
)
RETURNS bit
AS
-- FUNCTION: 	fn_ExistsInSplitString
-- VERSION:  	1
-- SCOPE:    	CPA.net, InPro.net
-- DESCRIPTION: This function searches @psString1 for the @psSearchText, if @psSearchText 
-- 		is not found it searches @psString2, if still nothing it will constract the 
-- 		third string from the end of @psString1 and the beginning of @psString2 and 
--		will search it again for  @psSearchText. It returns true if found, and 
--		false otherwise.
-- CALLED BY :	cs_ConstructCaseSelect  
-- COPYRIGHT :	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date  	Who 	Version 	Change
-- ------------ ------- ------- ----------------------------------------------- 
-- 30-Jul-2003  TM 	1 		Function created
-- 06-Jul-2005	CR	2		Changed DATALENGTH to LEN to cather for nvarchar.
Begin
	-- @bExists is set to 1 if @psSearchText exists in @psString1 and/or @psString2,
	-- otherwise it is set to 0   
	
	declare @bExists	bit	
	
	-- Search @psString1 for @psSearchText  
	
	Set @bExists = CASE WHEN CHARINDEX(@psSearchText, @psString1)>0 THEN 1
			    ELSE 0
			  END
	
	-- If @psSearchText was not found in @psString1 then search @psString2     
	
	If @bExists = 0
	Begin
		Set @bExists = CASE WHEN CHARINDEX(@psSearchText, @psString2)>0 THEN 1
			       	    ELSE 0
			       END
	End
	
	-- If still not found take the last LEN(@psSearchText)+1 characters of @psString1 and concatenate
	-- the first LEN(@psSearchText)+1 characters to it and then search the constructed string 
	-- for the @psSearchText     
	 
	If @bExists = 0
	Begin
		Set @bExists = CASE WHEN CHARINDEX(@psSearchText, SUBSTRING(@psString1, 4000-LEN(@psSearchText),LEN(@psSearchText)+1 ) + SUBSTRING(@psString2, 1,LEN(@psSearchText)+1 ))>0 THEN 1
			       	    ELSE 0
			       END	
	End 
		
	Return @bExists 
End	
GO

Grant execute on dbo.fn_ExistsInSplitString to public
GO
