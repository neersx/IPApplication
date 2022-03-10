-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_OrderTabsDisplaySequence
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_OrderTabsDisplaySequence]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_OrderTabsDisplaySequence.'
	Drop procedure [dbo].[ipw_OrderTabsDisplaySequence]
End
Print '**** Creating Stored Procedure dbo.ipw_OrderTabsDisplaySequence...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[ipw_OrderTabsDisplaySequence]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pnWindowControlNo			int,		-- Mandatory
	@pbApplyToDecendants		        bit		= 0
)
as
-- PROCEDURE:	ipw_OrderTabsDisplaySequence
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
declare @WindowControlNo        int
declare @nCount                 int 
declare @nRow                   int 
Declare @nCriteriaNo	        int
Declare @bIsNameCriteria	bit
Declare @sWindowName	        nvarchar(50)
Declare @bIsExternal	        bit
		
-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0      
Begin   
	execute @nErrorCode = ipw_OrderTabsDisplaySequence_internal
	        @pnUserIdentityId       = @pnUserIdentityId,
	        @psCulture              = @psCulture,
	        @pnWindowControlNo      = @pnWindowControlNo
End

If @nErrorCode = 0 and @pbApplyToDecendants = 1
Begin
	Declare @tblTabControlWindowControls table (
		RowID INT IDENTITY(1, 1),
		WINDOWCONTROLNO int) 

	Set @bIsNameCriteria = 0
	Set @bIsExternal = 0

	Set @sSQLString = "
	Select	@nCriteriaNo = isnull(WC.CRITERIANO,WC.NAMECRITERIANO),
			@bIsNameCriteria = CASE WHEN (WC.CRITERIANO IS NOT NULL) THEN 0 ELSE 1 END,
			@bIsExternal = WC.ISEXTERNAL,
			@sWindowName = WC.WINDOWNAME
	from WINDOWCONTROL WC
	where WC.WINDOWCONTROLNO = @pnWindowControlNo"

	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@nCriteriaNo		int                     OUTPUT,
			  @bIsNameCriteria	bit                     OUTPUT,
			  @bIsExternal		bit                     OUTPUT,
			  @sWindowName		nvarchar(50)            OUTPUT,			 
			  @pnWindowControlNo	int',
			  @nCriteriaNo          = @nCriteriaNo          OUTPUT,
			  @bIsNameCriteria      = @bIsNameCriteria	OUTPUT,
			  @bIsExternal          = @bIsExternal          OUTPUT,
			  @sWindowName          = @sWindowName          OUTPUT,
			  @pnWindowControlNo    = @pnWindowControlNo

	If @nErrorCode = 0 and @nCriteriaNo is not null and @nCriteriaNo <> 0
	Begin 
		Insert into @tblTabControlWindowControls
		Select WC.WINDOWCONTROLNO
		From dbo.fn_GetChildCriteria (@nCriteriaNo,@bIsNameCriteria) C
		Join WINDOWCONTROL WC on (
		        ((@bIsNameCriteria = 0 and WC.CRITERIANO=C.CRITERIANO and WC.CRITERIANO != @nCriteriaNo) 
			  or
			(@bIsNameCriteria = 1 and WC.NAMECRITERIANO=C.CRITERIANO and WC.NAMECRITERIANO != @nCriteriaNo))
			and WC.ISEXTERNAL = @bIsExternal
		        and WC.WINDOWNAME = @sWindowName
		        and WC.ISINHERITED = 1)		
			 
	        Select @nCount = @@ROWCOUNT, @nErrorCode = @@Error	
	End
	
	If @nErrorCode = 0
	Begin
	        SET @nRow = 1
	        WHILE @nRow <= @nCount
                BEGIN
	                SELECT @WindowControlNo = WINDOWCONTROLNO 
	                FROM @tblTabControlWindowControls 
	                WHERE RowID = @nRow
	                	                
	                execute @nErrorCode = ipw_OrderTabsDisplaySequence_internal
	                        @pnUserIdentityId       = @pnUserIdentityId,
	                        @psCulture              = @psCulture,
	                        @pnWindowControlNo      = @WindowControlNo
	                        
	                Set @nRow = @nRow + 1
	        End
	End
End
 
Return @nErrorCode
GO

Grant execute on dbo.ipw_OrderTabsDisplaySequence to public
GO