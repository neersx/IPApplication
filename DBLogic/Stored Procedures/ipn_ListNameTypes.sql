-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListNameTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListNameTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipn_ListNameTypes.'
	drop procedure [dbo].[ipn_ListNameTypes]
	print '**** Creating Stored Procedure dbo.ipn_ListNameTypes...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

create procedure dbo.ipn_ListNameTypes
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	4
-- DESCRIPTION:	List Name Types
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 17 Jul 2002	SF		procedure created
-- 15 Nov 2002	SF	4	Update Version Number
as
begin
	set NOCOUNT on
	

	select 	NAMETYPE as 'NameTypeKey',
		DESCRIPTION as 'NameTypeDescription'
	from 	NAMETYPE as NameType
	order by NAMETYPE

	return @@Error

end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ipn_ListNameTypes to public
go
