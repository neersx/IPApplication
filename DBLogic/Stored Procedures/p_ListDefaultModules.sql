---------------------------------------------------------------------------------------------
-- Creation of dbo.p_ListDefaultModules
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[p_ListDefaultModules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.p_ListDefaultModules.'
	drop procedure [dbo].[p_ListDefaultModules]
	Print '**** Creating Stored Procedure dbo.p_ListDefaultModules...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create proc dbo.p_ListDefaultModules
(
	@pnTabID int = 0,
	@psCulture nvarchar(10)
)
-- VERSION:	4
-- DESCRIPTION:	List Default Modules
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF	4	Update Version Number
as

	exec p_ListModules 99, null, 1


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.p_ListDefaultModules to public
go
