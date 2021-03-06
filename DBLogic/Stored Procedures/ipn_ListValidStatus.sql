---------------------------------------------------------------------------------------------
-- Creation of dbo.ipn_ListValidStatus
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListValidStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListValidStatus.'
	drop procedure [dbo].[ipn_ListValidStatus]
	Print '**** Creating Stored Procedure dbo.ipn_ListValidStatus...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipn_ListValidStatus
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	7
-- DESCRIPTION:	List Valid Status
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF	5	Update Version Number
-- 28 JAN 2002	SF	6	Display Internal/External Status Description appropriately
-- 28 JUL 2003	TM      7	RFC253 - Exclude renewal statuses
as
	-- set server options
	set NOCOUNT on
	select 	cast(V.STATUSCODE as varchar(10))	as 'StatusKey',
		case when UI.ISEXTERNALUSER=1 
		then	EXTERNALDESC 
		else	INTERNALDESC 
		end					as 'StatusDescription',
		COUNTRYCODE 				as 'CountryKey',
		Case 	COUNTRYCODE 
		when 'ZZZ' then 1
		else 0 
		end 					as 'IsDefaultCountry',
		PROPERTYTYPE 				as 'PropertyTypeKey',
		CASETYPE 				as 'CaseTypeKey'
	from	VALIDSTATUS V
	join	STATUS S on (V.STATUSCODE = S.STATUSCODE)
	join	USERIDENTITY UI on (UI.IDENTITYID = @pnUserIdentityId)
	where   S.RENEWALFLAG = 0
	order by INTERNALDESC
	return @@Error
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.ipn_ListValidStatus to public
go

