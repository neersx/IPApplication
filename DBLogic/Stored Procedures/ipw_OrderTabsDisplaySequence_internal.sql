-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_OrderTabsDisplaySequence_internal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_OrderTabsDisplaySequence_internal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_OrderTabsDisplaySequence_internal.'
	Drop procedure [dbo].[ipw_OrderTabsDisplaySequence_internal]
End
Print '**** Creating Stored Procedure dbo.ipw_OrderTabsDisplaySequence_internal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_OrderTabsDisplaySequence_internal]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pnWindowControlNo			int		-- Mandatory
)
as
-- PROCEDURE:	ipw_OrderTabsDisplaySequence_internal
-- VERSION:	1
-- DESCRIPTION:	Order the display sequence of all the tabs inside the document control

-- MODIFICATIONS :
-- Date		Who	Change	        Version	Description
-- -----------	-------	------	        -------	----------------------------------------------- 
-- 17 Jun 2011	MS	RFC10722	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	        int
declare @sSQLString 	        nvarchar(4000)
declare @iRow                   int 
declare @count                  int
declare @TabControlNo           int 
	
Declare @tblTabControl table (
                RowID INT IDENTITY(1, 1),
		TABCONTROLNO int,
		DISPLAYSEQUENCE int);
		
-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0      
Begin
        INSERT into @tblTabControl SELECT TABCONTROLNO, DISPLAYSEQUENCE from TABCONTROL 
        where WINDOWCONTROLNO = @pnWindowControlNo order by DISPLAYSEQUENCE
        
        SET @count = @@ROWCOUNT	
        
	SET @iRow = 0	
	WHILE @iRow < @count and @nErrorCode = 0
	BEGIN
                SELECT @TabControlNo = TABCONTROLNO
		FROM @tblTabControl 
		WHERE RowID = @iRow + 1
		
		If (Select DISPLAYSEQUENCE from TABCONTROL where  TABCONTROLNO = @TabControlNo) <> @iRow
                Begin			
		        Set @sSQLString = "Update TABCONTROL
		        SET DISPLAYSEQUENCE = @iRow
		        where TABCONTROLNO = @TabControlNo"		
		
		        Exec  @nErrorCode=sp_executesql @sSQLString,
			        N'@iRow		        int,
			        @TabControlNo	        int',
			        @iRow                  = @iRow,
			        @TabControlNo         = @TabControlNo
                End     

		SET @iRow = @iRow + 1		
	END
End
 
Return @nErrorCode
GO

Grant execute on dbo.ipw_OrderTabsDisplaySequence_internal to public
GO