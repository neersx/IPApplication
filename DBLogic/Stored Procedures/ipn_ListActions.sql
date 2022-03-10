-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListActions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListActions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipn_ListActions.'
	drop procedure [dbo].[ipn_ListActions]
	print '**** Creating Stored Procedure dbo.ipn_ListActions...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

create procedure dbo.ipn_ListActions
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(11) = null,
	@psCaseKey			varchar(11) 
)
-- VERSION:	5
-- DESCRIPTION:	List Actions
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 18 Jul 2002	SF		procedure created
-- 15 Nov 2002	SF	4	Update Version Number
-- 1 Mar 2007	PY	5	SQA14425 2 Reserved word [action]
-- 25 Nov 2011	ASH	R100640	6 Change the size of Case Key and Related Case key to 11.


as
begin	
	set nocount on
	
	select O.ACTION+Cast(O.CYCLE As varchar(10)) as 'ActionRowKey',	
		VA.ACTIONNAME+' ('+Cast(O.CYCLE As varchar(10))+')'		as 'ActionDescription',
		O.ACTION 		as 'ActionKey',
		O.CYCLE			as 'Cycle',
		O.CRITERIANO		as 'CriteriaKey'
	from	CASES 			as [Action]
	join	OPENACTION O 		on (O.CASEID = [Action].CASEID)
	join	VALIDACTION VA		on (O.ACTION = VA.ACTION 
					and VA.CASETYPE = [Action].CASETYPE
					and VA.PROPERTYTYPE = [Action].PROPERTYTYPE
					and VA.COUNTRYCODE = ( 	select 	min (VA1.COUNTRYCODE)
								from	VALIDACTION VA1
								where	VA1.COUNTRYCODE in ('ZZZ', [Action].COUNTRYCODE)
								and	VA1.PROPERTYTYPE = [Action].PROPERTYTYPE
								and	VA1.CASETYPE = [Action].CASETYPE)
					)

	and [Action].CASEID = cast(@psCaseKey as int)
	order by VA.DISPLAYSEQUENCE


	return @@error
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.ipn_ListActions to public
go
