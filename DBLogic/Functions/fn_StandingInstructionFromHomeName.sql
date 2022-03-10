-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_StandingInstructionFromHomeName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_StandingInstructionFromHomeName') and xtype='FN')
begin
	print '**** Drop function dbo.fn_StandingInstructionFromHomeName.'
	drop function dbo.fn_StandingInstructionFromHomeName
	print '**** Creating function dbo.fn_StandingInstructionFromHomeName...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_StandingInstructionFromHomeName 
			(
			@psPropertyType		nchar(1),	-- optional
			@psCountryCode		nvarchar(3),	-- optional
			@psInstructionType	nvarchar(3)	-- mandatory
			)
Returns int

-- FUNCTION :	fn_StandingInstructionFromHomeName
-- VERSION :	3
-- DESCRIPTION:	This function returns details of the Standing Instruction held against
--		the Home Name that would be the 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 12 Dec 2006	MF	13721		Function created
-- 15 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 01 Jul 2010	MF	18758	3	Increase the column size of Instruction Type to allow for expanded list.

as
Begin
	Declare @pnInternalSequence	smallint

	If @psInstructionType is not null
	Begin

		-- Get the InstructionSequence for the NAMEINSTRUCTION of the Home Name
		-- that best matches the characteristics passed 
		SELECT	@pnInternalSequence=
			cast(
			substring(max (
			CASE WHEN(NI.PROPERTYTYPE is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.COUNTRYCODE  is not null) THEN '1' ELSE '0' END +
			convert(nchar(11),NI.INTERNALSEQUENCE)),3,11) as int)
		FROM INSTRUCTIONS I
		join SITECONTROL S		on (S.CONTROLID='HOMENAMENO')
		join NAMEINSTRUCTIONS NI	on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
						and  NI.NAMENO=S.COLINTEGER
						and (NI.PROPERTYTYPE=@psPropertyType OR NI.PROPERTYTYPE is NULL)
						and (NI.COUNTRYCODE =@psCountryCode  OR NI.COUNTRYCODE  is NULL) )
		where I.INSTRUCTIONTYPE=@psInstructionType
	End

	Return @pnInternalSequence
End
go

grant execute on dbo.fn_StandingInstructionFromHomeName to public
go
