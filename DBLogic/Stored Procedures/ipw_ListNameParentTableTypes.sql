-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListNameParentTableTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListNameParentTableTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListNameParentTableTypes.'
	Drop procedure [dbo].[ipw_ListNameParentTableTypes]
End
Print '**** Creating Stored Procedure dbo.ipw_ListNameParentTableTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE PROCEDURE [dbo].[ipw_ListNameParentTableTypes]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pbCalledFromCentura bit	= 0	
)
as
-- PROCEDURE:	ipw_ListNameParentTableTypes
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns all ParentTable where Parenttable in Individual, Organisation, Name or Employee
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Aug 2009	DV	RFC8016	1	Procedure created 
-- 04 Feb 2010	DL	18430	2	Grant stored procedure to public


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @tblParentTable table 
(	NAMEPARENTTABLETYPEKEY		nvarchar(50)	collate database_default not null,
	NAMEPARENTTABLENAME			nvarchar(50)	collate database_default not null			
) 

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin	
	insert into @tblParentTable(NAMEPARENTTABLETYPEKEY, NAMEPARENTTABLENAME)	
	values('EMPLOYEE','EMPLOYEE')
	Set @nErrorCode = @@Error
End
If @nErrorCode = 0
Begin
	insert into @tblParentTable(NAMEPARENTTABLETYPEKEY, NAMEPARENTTABLENAME)	
	values('INDIVIDUAL','INDIVIDUAL')
	Set @nErrorCode = @@Error
End
If @nErrorCode = 0
Begin
	insert into @tblParentTable(NAMEPARENTTABLETYPEKEY, NAMEPARENTTABLENAME)	
	values('NAME/LEAD','NAME/LEAD')
	Set @nErrorCode = @@Error
End
If @nErrorCode = 0
Begin
	insert into @tblParentTable(NAMEPARENTTABLETYPEKEY, NAMEPARENTTABLENAME)	
	values('ORGANISATION','ORGANISATION')
	Set @nErrorCode = @@Error
End
If @nErrorCode = 0
Begin
	Select * from @tblParentTable
End
Return @nErrorCode
GO

grant execute on dbo.ipw_ListNameParentTableTypes to public
GO
