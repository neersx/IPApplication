---------------------------------------------------------------------------------------------
-- Creation of dbo.p_ListConfig
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListModulesByTabID]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListModulesByTabID.'
	drop procedure [dbo].[ua_ListModulesByTabID]
	Print '**** Creating Stored Procedure dbo.ua_ListModulesByTabID...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ua_ListModulesByTabID
    @pnUserIdentityId		int 		= null,
    @psCulture			nvarchar(10) 	= null,
    @pnTabID			int, -- Mandatory
    @pbCalledFromCentura	bit		= 0
    
AS
-- PROCEDURE :	ua_ListModulesByTabID
-- VERSION :	1
-- DESCRIPTION:	A procedure to return the modules for the requested tab

-- MODIFICATIONS :
-- Date  	Who 	RFC# 	Version Change
-- ------------ ------- ---- 	------- ----------------------------------------------- 
-- 02-May-2008  JCLG  	RFC6487	1	Procedure Created

set nocount on
set concat_null_yields_null off
DECLARE		@ErrorCode		int

Declare 	@sSQLString		nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement
Set @ErrorCode   = 0

-- Then, get the modules for the first tab
If  @ErrorCode=0
begin
	execute @ErrorCode = p_ListModules 
		@pnUserIdentityId	=@pnUserIdentityId, 
		@psCulture		=@psCulture, 
		@pnTabID		=@pnTabID,
		@pbCalledFromCentura	=@pbCalledFromCentura
end

-- Get the settings that match the CONFIGURATIONIDs returned by p_ListModules above:
If  @ErrorCode=0 
Begin
	execute @ErrorCode = p_ListModuleConfigSettings 
		@pnUserIdentityId	=@pnUserIdentityId, 
		@psCulture		=@psCulture, 
		@pnTabID		=@pnTabID
End

-- Get the PortalSettings held against the Module that the user is permitted to see for the Tab:
If  @ErrorCode=0 
Begin
	execute @ErrorCode = p_ListModuleSettings 
		@pnUserIdentityId	=@pnUserIdentityId, 
		@psCulture		=@psCulture, 
		@pnTabID		=@pnTabID
End


return @ErrorCode
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.ua_ListModulesByTabID to public
go
