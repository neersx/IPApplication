-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_UserDefinedFields
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_UserDefinedFields') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_UserDefinedFields'
	Drop function [dbo].[fn_UserDefinedFields]
End
Print '**** Creating Function dbo.fn_UserDefinedFields...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_UserDefinedFields
(
	@pnEntityNo		int,
	@pnTransNo		int,
	@pnDesignation		int,
	@pnSeqNo		int,
	@psDescription		nVarchar(254),
	@pbExcludeForeign	bit
) 
RETURNS nvarchar(254)
AS
-- Function :	fn_UserDefinedFields
-- VERSION :	3
-- DESCRIPTION:	Return the contents of the user defined fields 
-- for a specific gljournalline as a comma separated string.
-- CALLED BY :	fi_PostToGL stored procedure

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 04-Nov-2003  CR	8197	1	Function created
-- 09-Sept-2005	CR	11735	2	Extended filtering by passing an additional where clause.
-- 14 Apr 2011	MF	10475	3	Change nvarchar(4000) to nvarchar(max)

Begin
	Declare @sSQLString		nvarchar(max)
	Declare @sUserDefinedFields 	nvarchar(max)
	Declare @sResult 		nvarchar(254)
	Declare @sFieldContents 	nvarchar(254)
	Declare @nErrorCode		int

	Set @sFieldContents = NULL
	Set @sUserDefinedFields = @psDescription

	if @pbExcludeForeign = 1
	Begin
		Select @sUserDefinedFields=ISNULL(NULLIF(@sUserDefinedFields + ',', ','),'')  +EXT.CONTENTS
		from  GLJOURNALLINEEXT EXT
		where EXT.ENTITYNO  = @pnEntityNo
		and EXT.TRANSNO     = @pnTransNo
		and EXT.DESIGNATION = @pnDesignation
		and EXT.SEQNO       = @pnSeqNo
		and EXT.FIELDNO NOT IN (SELECT DISTINCT FRC.FIELDNO
					FROM GLFIELDRULECONTENT FRC
					where FRC.CONTENTID in (15, 22, 26, 28, 37, 44, 14, 21, 25, 27, 36, 43))

	End
	Else
	Begin
		Select @sUserDefinedFields=ISNULL(NULLIF(@sUserDefinedFields + ',', ','),'')  +EXT.CONTENTS
		from  GLJOURNALLINEEXT EXT
		where EXT.ENTITYNO  = @pnEntityNo
		and EXT.TRANSNO     = @pnTransNo
		and EXT.DESIGNATION = @pnDesignation
		and EXT.SEQNO       = @pnSeqNo
	End

	Set @sResult = cast( @sUserDefinedFields as nvarchar(254) )

	Return @sResult
End
GO

grant execute on dbo.fn_UserDefinedFields to public
go
