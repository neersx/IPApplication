-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListStopPayReasons
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListStopPayReasons]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipn_ListStopPayReasons.'
	drop procedure [dbo].[ipn_ListStopPayReasons]
	print '**** Creating Stored Procedure dbo.ipn_ListStopPayReasons...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

create procedure dbo.ipn_ListStopPayReasons
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	8
-- DESCRIPTION:	List Stop Pay Reasons
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 18 Jul 2002	SF		procedure created
-- 13 Aug 2002	SF		Unlike most TableCodes tables, the TableCodes.UserCode is what is stored on Cases.  Consequently, the picklist needs to place the UserCode in both the Key and the Code.  Select all rows where TableType = 68
-- 15 Nov 2002 	SF	8	Update Version Number
as
begin
	set nocount on

	select 	USERCODE 		as 'Key',
		DESCRIPTION		as 'Description',
		USERCODE		as 'Code'
	from 	TABLECODES 		as StopPayReason
	where 	TABLETYPE = 68
	order by DESCRIPTION

	return @@error
end
GO

grant execute on dbo.ipn_ListStopPayReasons to public
go
