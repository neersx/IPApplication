---------------------------------------------------------------------------------------------
-- Creation of dbo.p_ListModuleHTMLText
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[p_ListModuleHTMLText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.p_ListModuleHTMLText.'
	drop procedure [dbo].[p_ListModuleHTMLText]
	Print '**** Creating Stored Procedure dbo.p_ListModuleHTMLText...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.p_ListModuleHTMLText
    @pnModuleId	int,
    @psCulture	nvarchar(10) = null
AS
-- PROCEDURE :	p_ListModuleHTMLText
-- VERSION :	4
-- DESCRIPTION:	Returns the identity of a previously authenticated user
-- Date			MODIFICATION HISTORY
-- ====         =========+==========
--
set nocount on

select 
	HTMLTEXT
from
    HTMLTEXT
where
    PORTALMODULEID = @pnModuleId
    
return @@error
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.p_ListModuleHTMLText to public
go
