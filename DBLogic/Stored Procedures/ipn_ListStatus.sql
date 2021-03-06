---------------------------------------------------------------------------------------------
-- Creation of dbo.ipn_ListStatus
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListStatus.'
	drop procedure [dbo].[ipn_ListStatus]
	Print '**** Creating Stored Procedure dbo.ipn_ListStatus...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipn_ListStatus
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	4
-- DESCRIPTION:	List Status
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 Nov 2002	SF	3	Update Version Number
-- 28 JAN 2003	SF	4	display Internal/External status description appropriately
as
	-- set server options
	set NOCOUNT on
	select 	cast(STATUSCODE as varchar(10)) as 'StatusKey',
		case when UI.ISEXTERNALUSER = 1 then
			EXTERNALDESC
		     else
			INTERNALDESC 
		end				as 'StatusDescription'
	from	STATUS
	join 	USERIDENTITY UI on (UI.IDENTITYID = @pnUserIdentityId)
	order by INTERNALDESC
	return @@Error
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.ipn_ListStatus to public
go
