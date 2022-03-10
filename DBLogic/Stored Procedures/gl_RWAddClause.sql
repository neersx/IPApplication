-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_RWAddClause
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_RWAddClause]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_RWAddClause.'
	Drop procedure [dbo].[gl_RWAddClause]
End
Print '**** Creating Stored Procedure dbo.gl_RWAddClause...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.gl_RWAddClause
(
	@psTableName		nvarchar(128)	= null, --name of the temporary table
	@psClauseType		nvarchar(15), -- clause type: SELECTCLAUSE,FROMCLAUSE,WHERECLAUSE,GROUPBYCLAUSE,ORDERBYCLAUSE
	@psClause		nvarchar(4000) 	= null -- text of the clause
)
as
-- PROCEDURE:	gl_RWAddClause
-- VERSION:	1
-- SCOPE:	 InPro.net
-- DESCRIPTION:	Adds Clause (@psClause) text to specified appropriate column (@psClauseType)

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Mar 2004	MB	8809	1	Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSql 		nvarchar (4000)
Declare @ptrval 	binary(16)


-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin


	set @sSql= "SELECT @ptrval = TEXTPTR( " + @psClauseType + ") FROM #OUTPUTTABLE"

	exec @nErrorCode = sp_executesql @sSql,
				N'@ptrval binary(16) output',
				  @ptrval	= @ptrval output
End
If @nErrorCode = 0
Begin
	set @sSql= "UPDATETEXT #OUTPUTTABLE." + @psClauseType + " @ptrval null null @psClause"
	exec @nErrorCode = sp_executesql @sSql,
				N'@ptrval  binary(16),
				 @psClause nvarchar(4000)',
				 @ptrval	= @ptrval,
				 @psClause	= @psClause

End

Return @nErrorCode
GO

Grant execute on dbo.gl_RWAddClause to public
GO
