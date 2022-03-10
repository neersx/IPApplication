-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_RemoveStandingInstruction
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_RemoveStandingInstruction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_RemoveStandingInstruction.'
	drop procedure dbo.cs_RemoveStandingInstruction
end
print '**** Creating procedure dbo.cs_RemoveStandingInstruction...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_RemoveStandingInstruction
	@pnRowCount			int 		= null	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psTempTable			nvarchar(32),		-- optional name of temporary table of CASEIDs to be reported on.
	@pnInstructionCode		smallint,		-- The Instruction Code to be used to determine deletion of Instructions
	@pbNotInstruction		bit		= 0	-- Flag to indicate that Instructions to be deleted is Not @pnInstructionCode
	
AS
-- PROCEDURE :	cs_RemoveStandingInstruction
-- DESCRIPTION:	Remove specific standing instructions that are held against Cases.
-- CALLED BY :	
-- COPYRIGHT :	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Feb 2005	MF			Procedure created

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF


DECLARE	@ErrorCode		int,
	@sSQLString		nvarchar(4000),
	@sFrom			nvarchar(1000),
	@sWhere			nvarchar(1000)

-- Variables required for the Official number validation


set @ErrorCode=0


Set @sFrom='From '+@psTempTable+' T'+char(10)+
	   'join NAMEINSTRUCTIONS NI on (NI.CASEID=T.CASEID)'

-- Initialise the WHERE clause to determine what Instructions are to be deleted

If @pbNotInstruction=0
	Set @sWhere="Where NI.INSTRUCTIONCODE=@pnInstructionCode"
else
	Set @sWhere="Where NI.INSTRUCTIONCODE<>@pnInstructionCode"

-- Now execute the constructed statement
If @ErrorCode=0
Begin
	Set @sSQLString='Delete NAMEINSTRUCTIONS'+char(10)+
			@sFrom+char(10)+
			@sWhere

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnInstructionCode	smallint',
					  @pnInstructionCode=@pnInstructionCode

	Set @pnRowCount=@@Error
End

RETURN @ErrorCode
go

grant execute on dbo.cs_RemoveStandingInstruction to public
go
