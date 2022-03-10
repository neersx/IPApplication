-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserInstructionTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserInstructionTypes') and xtype='IF')
begin
	print '**** Drop function dbo.fn_FilterUserInstructionTypes.'
	drop function dbo.fn_FilterUserInstructionTypes
	print '**** Creating function dbo.fn_FilterUserInstructionTypes...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserInstructionTypes
			(@pnUserIdentityId		int,		-- the specific user the AliasTypes are required for
			 @pbIsExternalUser		bit,		-- External user flag which should already be known
			 @psLookupCulture		nvarchar(10), 	-- the culture the output is required in
			 @pbCalledFromCentura  		bit = 0)	-- if true, the function should provide access to all data		
RETURNS TABLE
AS
-- FUNCTION :	fn_FilterUserInstructionTypes
-- VERSION :	2
-- DESCRIPTION:	This function is used to return a list of Instruction Types that the currently logged on
--		external user identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 06 Mar 2006	TM	RFC3215	1	Function created
-- 15 Jan 2009	AT	17136 	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

RETURN
	-- NOTE : This code will be replaced if a new method of getting AliasTypes is determined
	Select 	I.INSTRUCTIONTYPE	as INSTRUCTIONTYPE,
		I.NAMETYPE		as NAMETYPE,
		dbo.fn_GetTranslationLimited(I.INSTRTYPEDESC,null,I.INSTRTYPEDESC_TID,@psLookupCulture)
					as INSTRTYPEDESC,
		I.RESTRICTEDBYTYPE	as RESTRICTEDBYTYPE
	from INSTRUCTIONTYPE I
	join SITECONTROL S on (S.CONTROLID='Client Instruction Types')
	where patindex('%'+I.INSTRUCTIONTYPE+'%',S.COLCHARACTER)>0
GO

grant REFERENCES, SELECT on dbo.fn_FilterUserInstructionTypes to public
GO
