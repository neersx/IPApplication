-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_StandingInstructionsBestFit
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_StandingInstructionsBestFit') and xtype='IF')
begin
	print '**** Drop function dbo.fn_StandingInstructionsBestFit.'
	drop function dbo.fn_StandingInstructionsBestFit
	print '**** Creating function dbo.fn_StandingInstructionsBestFit...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create FUNCTION [dbo].[fn_StandingInstructionsBestFit]
       (@pnNameNo		int,		-- from Name with NameType as configured for the Instruction Type
	@pnNameNoX		int,		-- from Name with RestrictedBy as configured for the Instruction Type
	@pnCaseOfficeNameNo	int,		-- from Office for case
	@pnNameOfficeNameNo	int,		-- from Office for name (via NameType from Instruction type)
	@pnHomeNameNo		int,		-- from HomeNameNo (SiteControl)
	@pnCaseid		int,		-- from Case
	@psPropertyType		nvarchar(01),	-- from Case
	@psCountryCode		nvarchar(03),	-- from Case
	@psInstructionType	nvarchar(03),	-- 
	@pnInstructionCode	int = NULL)	-- optional: select only where having this instruction code

RETURNS	table AS RETURN
---------------------------------------------------------------------------------------------------
-- FUNCTION :	fn_FilterUserCases
-- VERSION :	1
-- DESCRIPTION:	Based on the provided parameters, this function applies Inprotech's best-fit
--		algorithm to find the applicable standing instruction for the case.
--		This function is only called from function StandingInstructionsForCase
--		to apply the best-fit algorithm. The reason for placing this code in this
--		separate function is to avoid SQL issues with mixing inner and outer 
--		references in the same query.
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

	WITH	cte AS
		(
		SELECT	CASEID          = @pnCaseid,
			INSTRUCTIONCODE =
				CAST( SUBSTRING( MAX (
					  CASE WHEN(ni.CASEID           IS NOT NULL) THEN '1' ELSE '0' END
					+ CASE WHEN(ni.NAMENO = @pnNameNo)           THEN '4'
					       WHEN(ni.NAMENO = @pnCaseOfficeNameNo) THEN '3'
					       WHEN(ni.NAMENO = @pnNameOfficeNameNo) THEN '2'
					       WHEN(ni.NAMENO = @pnHomeNameNo)       THEN '1'
					                                             ELSE '0' END
					+ CASE WHEN(ni.RESTRICTEDTONAME IS NOT NULL) THEN '1' ELSE '0' END
					+ CASE WHEN(ni.PROPERTYTYPE     IS NOT NULL) THEN '1' ELSE '0' END
					+ CASE WHEN(ni.COUNTRYCODE      IS NOT NULL) THEN '1' ELSE '0' END
					+ CONVERT(nchar(11),ni.INSTRUCTIONCODE)
					),6,11) as smallint)

		FROM	dbo.INSTRUCTIONS i

		INNER	JOIN	dbo.NAMEINSTRUCTIONS ni
			ON	ni.INSTRUCTIONCODE   = i.INSTRUCTIONCODE
			AND	(ni.NAMENO         IN (@pnNameNo, @pnCaseOfficeNameNo, @pnNameOfficeNameNo, @pnHomeNameNo) )
			AND	(ni.CASEID           = @pnCaseid       OR ni.CASEID           IS NULL) 
			AND	(ni.PROPERTYTYPE     = @psPropertyType OR ni.PROPERTYTYPE     IS NULL OR ni.CASEID IS NOT NULL)
			AND	(ni.COUNTRYCODE      = @psCountryCode  OR ni.COUNTRYCODE      IS NULL OR ni.CASEID IS NOT NULL)
			AND	(ni.RESTRICTEDTONAME = @pnNameNoX      OR ni.RESTRICTEDTONAME IS NULL)

		WHERE	i.INSTRUCTIONTYPE = @psInstructionType
		AND	i.INSTRUCTIONCODE = ISNULL(@pnInstructionCode,i.INSTRUCTIONCODE)
		)

		-- if a specific instruction was searched for then only return
		-- a row if that instruction code was found for the case
		SELECT	cte.CASEID, 
			i.INSTRUCTIONCODE, 
			INSTRUCTION = i.DESCRIPTION
		FROM	cte
		INNER	JOIN	dbo.INSTRUCTIONS i
			ON	i.INSTRUCTIONCODE = cte.INSTRUCTIONCODE
		WHERE	cte.InstructionCode IS NOT NULL
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_StandingInstructionsBestFit to public
go
