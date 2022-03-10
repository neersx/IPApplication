-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetStoredProcedureVersion
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_GetStoredProcedureVersion') and xtype='FN')
Begin
	print '**** Drop function dbo.fn_GetStoredProcedureVersion.'
	drop function dbo.fn_GetStoredProcedureVersion
	print '**** Creating function dbo.fn_GetStoredProcedureVersion...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE FUNCTION dbo.fn_GetStoredProcedureVersion
(
	@psRoutineName		nvarchar(128)
)
RETURNS nvarchar(10)
AS
-- FUNCTION: 	fn_GetStoredProcedureVersion
-- VERSION: 	5
-- SCOPE: 	CPA Inprostart
-- DESCRIPTION: Returns a stored procedure Version Number
-- CALLED BY :	ip_StoredProcedureVersions
 
-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 28-Jul-2003  TM 		1 	Function created
-- 29-Aug-2003  TM		2	RFC278 Not all Stored Procedures are listed on about page.
--					Use ASCII(48) and ASCII(57) to test if a character is numeric 
--					instead of ISNUMERIC function as ASCII is more reliable approach. 
-- 07 Oct 2011	MF	R11373	3	Invisible characters are being returned with the Version. These will be removed.
-- 30 05 2013	vql		4	Check whole routine for version not only first 4000 char.
-- 12 Feb 2014	DV	R27636	5 Use Object definition for getting the whole routine as there was a performance impact by using sql_modules

Begin

	declare @sVersionNumber nvarchar(10) 
	declare @sSPCOLUMN  	nvarchar(max)
	declare @sSubstring 	varchar(50)
	declare @nIndex	    	int
	
	SELECT @sSPCOLUMN = OBJECT_DEFINITION(OBJECT_ID(@psRoutineName))
	
	-- Find starting position of '-- VERSION' string in the stored procedure text
	
	Set @nIndex = CHARINDEX('-- VERSION', UPPER(@sSPCOLUMN)) 
	
	-- If the '-- VERSION' string is found then stored procedure should have a Version Number so extract it 
		
	If @nIndex <> 0
	Begin	
		-- Narrow down the search by searching 50 characters string (@sSubstring) after '-- VERSION' 
		-- Also strip out any carriage returns, line feeds or tabs
		
		Set @sSubstring = replace(replace(replace(SUBSTRING(@sSPCOLUMN, @nIndex+10, 50),char(9),''),char(10),''),char(13),'')
		
		-- Search the @sSubstring for the first numeric value 
		 
		While @sVersionNumber is null
		and LEN(@sSubstring) > 0
		Begin
			-- If the first character in the @sSubstring is a numeric value then extract a substring
			-- that starts with that numeric value, e.g. '2.1.0  -- SCOPE:' will return '2.1.0'
			
			If ASCII(SUBSTRING(@sSubstring,1,1)) BETWEEN 48 AND 57
			Begin
				-- Use '--' to find the end of the extracted Version Number string	
		
				Set @sVersionNumber = SUBSTRING(@sSubstring, 1,CHARINDEX('--',@sSubstring)-1)
				
			End 

			-- If the first character in the @sSubstring is not numeric then cut it off and continue search  
			
			Else
			Begin
				Set @sSubstring = SUBSTRING(@sSubstring, 2, LEN(@sSubstring)-1)
			End
		End
	End

	-- If the '-- VERSION' string is not found then stored procedure does not have a Version number so set @sVersionNumber to ''

	Else
	Begin
		Set @sVersionNumber = '' 
	End
	 
	Return @sVersionNumber

End	
GO

Grant execute on dbo.fn_GetStoredProcedureVersion to public
GO





