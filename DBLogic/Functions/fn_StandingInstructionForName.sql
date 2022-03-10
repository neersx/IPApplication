-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_StandingInstructionForName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_StandingInstructionForName') and xtype='FN')
begin
	print '**** Drop function dbo.fn_StandingInstructionForName.'
	drop function dbo.fn_StandingInstructionForName
	print '**** Creating function dbo.fn_StandingInstructionForName...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_StandingInstructionForName 
			(
			@pnNameNo		int,
			@psInstructionType	nvarchar(3),
			@pnHomeNameNo		int	= null
			)
Returns smallint

-- FUNCTION :	fn_StandingInstructionForName
-- VERSION :	3
-- DESCRIPTION:	This function accepts the NAMENO and Instruction Type and returns the specific
--		Standing Instruction.  If the Home NameNo is required then it will be looked
--		up if it has not be supplied as an input parameter.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 27 Jul 2010	MF	9613	1	Function created
-- 05 Dec 2011	LP	R11070	2	Default Instruction from ORGNAMENO of Name Office first before the HOMENAMENO
-- 11 Apr 2013	DV	R13270	3	Cast @pnNameNo to nvarchar(11)
as
Begin
	Declare @pnInstructionCode	smallint
	Declare @nOfficeNameNo		int
	
	SELECT	@pnInstructionCode=NI.INSTRUCTIONCODE
	FROM INSTRUCTIONS I
	join NAMEINSTRUCTIONS NI on (NI.NAMENO=@pnNameNo
				 and NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE)
	where I.INSTRUCTIONTYPE=@psInstructionType
	and NI.CASEID       is NULL
	and NI.PROPERTYTYPE is NULL
	and NI.COUNTRYCODE  is NULL

	-- Default Instruction from Name Office Entity
	If @pnInstructionCode is null
	Begin
		Select  @nOfficeNameNo = O.ORGNAMENO
		from TABLEATTRIBUTES T
		join OFFICE O on (O.OFFICEID = T.TABLECODE)
		and T.PARENTTABLE = 'NAME'
		and T.GENERICKEY = cast(@pnNameNo as nvarchar(11))
		and T.TABLETYPE = (SELECT TABLETYPE from TABLETYPE where DATABASETABLE = 'OFFICE')	
	
		If @nOfficeNameNo is not null
		Begin
			SELECT	@pnInstructionCode=NI.INSTRUCTIONCODE
			FROM INSTRUCTIONS I
			join NAMEINSTRUCTIONS NI on (NI.NAMENO=@nOfficeNameNo
						 and NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE)
			where I.INSTRUCTIONTYPE=@psInstructionType
			and NI.CASEID       is NULL
			and NI.PROPERTYTYPE is NULL
			and NI.COUNTRYCODE  is NULL
		End
	End
	
	-- Default Instruction from HomeName
	If @pnInstructionCode is null
	Begin
		If @pnHomeNameNo is null
		Begin
			Select @pnHomeNameNo=COLINTEGER
			From   SITECONTROL
			where  CONTROLID='HOMENAMENO'
		End

		-- If no InstructionCode has been found against
		-- the main Name then drop back and use the HomeName
		-- NOTE
		-- This is coded separately to improve performance.	
	
		SELECT	@pnInstructionCode=NI.INSTRUCTIONCODE
		FROM INSTRUCTIONS I
		join NAMEINSTRUCTIONS NI on (NI.NAMENO=@pnHomeNameNo
					 and NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE)
		where I.INSTRUCTIONTYPE=@psInstructionType
		and NI.CASEID       is NULL
		and NI.PROPERTYTYPE is NULL
		and NI.COUNTRYCODE  is NULL
	End

	Return @pnInstructionCode
End
go

grant execute on dbo.fn_StandingInstructionForName to public
go
