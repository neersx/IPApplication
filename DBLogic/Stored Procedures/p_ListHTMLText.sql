---------------------------------------------------------------------------------------------
-- Creation of dbo.p_ListHTMLText
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[p_ListHTMLText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.p_ListHTMLText.'
	drop procedure [dbo].[p_ListHTMLText]
	Print '**** Creating Stored Procedure dbo.p_ListHTMLText...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.p_ListHTMLText
    @pnModuleId		int,
    @psCulture		nvarchar(10) = null
AS
-- PROCEDURE :	p_GetHtmlText
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

grant exec on dbo.p_ListHTMLText to public
go
