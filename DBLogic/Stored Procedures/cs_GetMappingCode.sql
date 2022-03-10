-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetMappingCode
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_GetMappingCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_GetMappingCode.'
	drop procedure dbo.cs_GetMappingCode
end
print '**** Creating procedure dbo.cs_GetMappingCode...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE PROCEDURE dbo.cs_GetMappingCode 
		@psMappedCode		nvarchar(50) output,
		@pbFoundMappingFlag	bit output,
		@psMapStructureTableName nvarchar(50),
		@psInputCode		nvarchar(50),
		@pnInputSchemeId	int = 0,
		@pnOutputSchemeId	int
AS
-- PROCEDURE :	cs_GetMappingCode
-- VERSION :	1
-- DESCRIPTION:	Find a mapping code in @pnOutputSchemeId scheme for a specified value
--		Note: Only maps CPAINPRO to CPAXML
-- 		Example: Map Inprotech Instructor (I) to CPAXML value
-- 		cs_GetMappingCode @psMappedCode output, @pbFoundMappingFlag output, 'NAMETYPE', 'I', -1, -3
--
-- COPYRIGHT: 	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- 
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 29/05/2006	DL	12388	1	Procedure created
-- 06/12/2006	DL	13114	2	Change output value to return the original CPAXML value.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode 		int,
	@nInputCodeId 		int,			
	@sMappedCode		nvarchar(50),
	@nCPAXMLSchemeId	int,
	@nCPAINPROSchemeId	int,
	@sSQLString 		nvarchar(4000)



Set @nErrorCode = 0


-- Get CPAXML SCHEME ID
If @nErrorCode = 0
Begin  
	Select @nCPAXMLSchemeId = SCHEMEID from ENCODINGSCHEME where SCHEMECODE = 'CPAXML'
	Set @nErrorCode = @@error
End

-- Get CPAINPRO SCHEME ID
If @nErrorCode = 0
Begin  
	Select @nCPAINPROSchemeId = SCHEMEID from ENCODINGSCHEME where SCHEMECODE = 'CPAINPRO'
	Set @nErrorCode = @@error
End


-- Find mapping from CPAINPRO to CPAXML
If @nErrorCode = 0 and @pnInputSchemeId = @nCPAINPROSchemeId and @pnOutputSchemeId = @nCPAXMLSchemeId
Begin
    Set @sSQLString = "
	Select @sMappedCode = isnull(EV.OUTBOUNDVALUE, EV1.OUTBOUNDVALUE) 
	from MAPSTRUCTURE MS
	join MAPPING M on (M.STRUCTUREID = MS.STRUCTUREID
			   and M.DATASOURCEID is null
			   and M.ISNOTAPPLICABLE = 0 )
	left join ENCODEDVALUE EV on (EV.STRUCTUREID = MS.STRUCTUREID
				and EV.SCHEMEID = @pnOutputSchemeId
				and EV.CODEID = M.INPUTCODEID) 
	join MAPPING M1 on (M1.OUTPUTCODEID = M.INPUTCODEID 
				and M1.STRUCTUREID = MS.STRUCTUREID
				AND M1.DATASOURCEID is null
				AND M1.ISNOTAPPLICABLE = 0
				)
	left join ENCODEDVALUE EV1 on (EV1.STRUCTUREID = MS.STRUCTUREID
				and EV1.SCHEMEID = @pnOutputSchemeId
				and EV1.CODEID = M1.INPUTCODEID) 

	where MS.TABLENAME = @psMapStructureTableName
	and M.OUTPUTVALUE = @psInputCode
    "
    Exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnOutputSchemeId		int,
		  @psMapStructureTableName	nvarchar(50),
		  @psInputCode			nvarchar(50),
		  @sMappedCode			nvarchar(50) OUTPUT',
		  @pnOutputSchemeId		= @pnOutputSchemeId,
		  @psMapStructureTableName	= @psMapStructureTableName,
		  @psInputCode			= @psInputCode,
		  @sMappedCode			= @sMappedCode OUTPUT


End  /* MAPPING CPAINPRO TO CPAXML SCHEME */



-- If found mapping code then returns flag to indicate mapping found
-- otherwise returns the input code.
If @sMappedCode is not null
    Select @psMappedCode = @sMappedCode, @pbFoundMappingFlag = 1
else
    Select @psMappedCode = @psInputCode, @pbFoundMappingFlag = 0


RETURN @nErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_GetMappingCode to public
go
