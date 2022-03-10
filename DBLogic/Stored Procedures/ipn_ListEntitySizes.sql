-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListEntitySizes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListEntitySizes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipn_ListEntitySizes.'
	drop procedure [dbo].[ipn_ListEntitySizes]
	print '**** Creating Stored Procedure dbo.ipn_ListEntitySizes...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

create procedure dbo.ipn_ListEntitySizes
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	7
-- DESCRIPTION:	List Entity Sizes
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 18 Jul 2002	SF		procedure created
-- 15 Nov 2002	SF 	6	Update Version Number
-- 15 Apr 2013	DV	7	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
	set nocount on

	select 	Cast(TABLECODE As Varchar(11)) 		as 'Key',
		DESCRIPTION		as 'Description' 
	from 	TABLECODES 		as EntitySize
	where 	TABLETYPE = 26
	order by DESCRIPTION

	return @@error
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.ipn_ListEntitySizes to public
go
