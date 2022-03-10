-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_GetNameDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_GetNameDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_GetNameDetails.'
	drop procedure [dbo].[na_GetNameDetails]
	print '**** Creating Stored Procedure dbo.na_GetNameDetails...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  PROCEDURE dbo.na_GetNameDetails
-- PROCEDURE :	na_GetNameDetails
-- VERSION :	4
-- DESCRIPTON:	Populate the Alias table in the NameDetails typed dataset.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 18/06/2002	SF	Procedure created	

	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnNameNo			int

AS
	exec dbo.na_GetNameSummary @pnUserIdentityId, @psCulture, @pnNameNo
	exec dbo.na_ListAssociatedNames @pnUserIdentityId, @psCulture, @pnNameNo
	exec dbo.na_ListAddresses @pnUserIdentityId, @psCulture, @pnNameNo
	exec dbo.na_ListTelecommunications @pnUserIdentityId, @psCulture, @pnNameNo
	exec dbo.na_ListTexts @pnUserIdentityId, @psCulture, @pnNameNo
	exec dbo.na_ListAliasses @pnUserIdentityId, @psCulture, @pnNameNo
	exec dbo.na_ListAttributes @pnUserIdentityId, @psCulture, @pnNameNo
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_GetNameDetails to public
go
