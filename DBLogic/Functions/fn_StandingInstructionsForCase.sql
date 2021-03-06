-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_StandingInstructionsForCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_StandingInstructionsForCase') and xtype='IF')
begin
	print '**** Drop function dbo.fn_StandingInstructionsForCase.'
	drop function dbo.fn_StandingInstructionsForCase
	print '**** Creating function dbo.fn_StandingInstructionsForCase...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create FUNCTION [dbo].[fn_StandingInstructionsForCase]
       (@pnCaseId		int,
	@psInstructionTypeCode	nvarchar(03),	-- either restrict to a single instruction type (fastest)
--	@psInstructionTypeCodes	nvarchar(255),	-- or allow one or more comma-separated values
	@pnInstructionCode	int		= NULL)

RETURNS	table AS RETURN
---------------------------------------------------------------------------------------------------
-- FUNCTION :	fn_FilterUserCases
-- VERSION :	1
-- DESCRIPTION:	This function determines the applicable standing instruction
--		for a given case for a given instruction type.
--		This function is written as an inline table-valued function and
--		can therefore be joined efficiently to (e.g.) the case table.
--
--		Parameter @pnInstructionCode is optional:
--		- if no value is provided then the function returns a row for each case
--		  with the applicable instruction code (whether case-level or inherited).
--		- if, however, no value is provided then rows are only returned for those
--		  cases where the instruction for the given type matches the specified code.
--
-- Dependencies:This function relies on function StandingInstructionsBestFit to apply the
--		best-fit algorithm. That code was moved out of this function to avoid
--		SQL issues with mixing inner and outer references in the same query.
--
-- Notes:	Performance might be improved slightly by adding the following index:
--		CREATE	NONCLUSTERED INDEX xakCaseNameExpiryDate
--		ON	dbo.CASENAME (EXPIRYDATE)
--			INCLUDE	(CASEID,NAMETYPE,SEQUENCE)

-- Example:	select TOP 1000 C.IRN, SI.*
--		from CASES C
--		cross apply dbo.fn_StandingInstructionsForCase(C.CASEID, 'R', Default) SI 
--
---------------------------------------------------------------------------------------------------
-----	Copyright:	IPsIT - 2014-2015
-----	History:	IPsIT - 2014-03-06 - Initial creation
-----			IPsIT - 2015-12-24 - Various improvements (performance, formatting)
-----			IPsIT - 2015-12-27 - Added support for instructions against Name Office
---------------------------------------------------------------------------------------------------

-- MODIFICATION
-- Date		Who	Version	RFC	Details
-- ----		---	-------	---	-------------------------------------
-- 07 Jan 2016	IPsIT	1	56939	High performing function provided by Sjoerd Koneijnenburg.

	SELECT	sibf.CASEID,
		typ.INSTRUCTIONTYPE	as INSTRUCTIONTYPECODE,
		sibf.INSTRUCTIONCODE,
		typ.INSTRTYPEDESC	as INSTRUCTIONTYPE,
		sibf.INSTRUCTION
			
	-- retrieve from cases
	FROM	dbo.CASES c

	-- link with specified instruction types
	INNER	JOIN	dbo.INSTRUCTIONTYPE typ
		ON	typ.INSTRUCTIONTYPE = @psInstructionTypeCode				-- for a specific InstructionType
--		ON	CHARINDEX(typ.INSTRUCTIONTYPE+',',@psInstructionTypeCodes+',') > 0	-- or for multiple types

	-- link with home name no
	INNER	JOIN	dbo.SITECONTROL sc
		ON	sc.CONTROLID = 'HOMENAMENO'

	-- link with name for standing instruction
	LEFT	JOIN	dbo.CASENAME cn
		ON	cn.CASEID   = c.CASEID
		AND	cn.NAMETYPE = typ.NAMETYPE
		AND	cn.SEQUENCE =
			(SELECT	MIN(SEQUENCE)
			 FROM	dbo.CASENAME
			 WHERE	CASEID     = cn.CASEID
			 AND	NAMETYPE   = cn.NAMETYPE
			 AND	EXPIRYDATE IS NULL)

	-- link with 'restricted by' name for standing instruction
	LEFT	JOIN	dbo.CASENAME cnX
		ON	cnX.CASEID   = c.CASEID
		AND	cnX.NAMETYPE = typ.RESTRICTEDBYTYPE
		AND	cnX.SEQUENCE =
			(SELECT	MIN(SEQUENCE)
			 FROM	dbo.CASENAME
			 WHERE	CASEID     = cnX.CASEID
			 AND	NAMETYPE   = cnX.NAMETYPE
			 AND	EXPIRYDATE IS NULL)

	-- link with case office
	LEFT	JOIN	dbo.OFFICE oCase
		ON	oCase.OFFICEID = c.OFFICEID

	-- link with name office
	LEFT	JOIN	dbo.TABLEATTRIBUTES ta
		INNER	JOIN	dbo.OFFICE oName
			ON	oName.OFFICEID = ta.TABLECODE
		ON	ta.PARENTTABLE = 'NAME'
		AND	ta.TABLETYPE   = 44
		AND	ta.GENERICKEY  = CAST(cn.NAMENO as nvarchar)

	-- use separate function to apply Inprotech's best-fit algorithm
	CROSS	APPLY	dbo.fn_StandingInstructionsBestFit
			(cn.NAMENO, cnX.NAMENO, oCase.ORGNAMENO, oName.ORGNAMENO, sc.COLINTEGER,
			 c.CASEID, c.PROPERTYTYPE, c.COUNTRYCODE, 
			 typ.INSTRUCTIONTYPE, @pnInstructionCode) sibf

	WHERE	c.CASEID = @pnCaseId
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_StandingInstructionsForCase to public
go
