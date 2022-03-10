---------------------------------------------------------------------------------------------
-- Creation of dbo.ipn_ListAnalysisCode5
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListAnalysisCode5]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListAnalysisCode5.'
	drop procedure [dbo].[ipn_ListAnalysisCode5]
	Print '**** Creating Stored Procedure dbo.ipn_ListAnalysisCode5...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipn_ListAnalysisCode5
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
as
-- VERSION :	5
-- DESCRIPTION:	Returns Analysis Code 5
-- CALLED BY :	

-- 9/07/2002	Alan	procedure created
-- 16/07/2002	SF	updated analysis code
	
	-- set server options
	set NOCOUNT on
	select 	Cast(TABLECODE As Varchar(10)) 	as 'Key',
		DESCRIPTION 	as 'Description'	
	from 	TABLECODES
	where 	TABLETYPE = -6 
	order by DESCRIPTION

	return @@Error
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.ipn_ListAnalysisCode5 to public
go
