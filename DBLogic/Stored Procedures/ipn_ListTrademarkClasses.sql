-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListTrademarkClasses
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListTrademarkClasses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipn_ListTrademarkClasses.'
	drop procedure [dbo].[ipn_ListTrademarkClasses]
	print '**** Creating Stored Procedure dbo.ipn_ListTrademarkClasses...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

create procedure dbo.ipn_ListTrademarkClasses
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,
	@psCaseKey			varchar(11) 
)
-- VERSION:	7
-- DESCRIPTION:	List Trademark Classes
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 18 Jul 2002	SF		procedure created
-- 24 Jul 2002	SF		Select Classes available for the Case instead of from the case.
-- 15 Nov 2002	SF	4	Update Version Number
-- 21 Aug 2003  TM	5	RFC228 Case Subclasses. For Class and ClassKey columns TMClass.Class 
--				and TMClass.SubClass formatted as <Class>.<SubClass>. The separating  
--				"." only presents if the SubClass is not null. A list of all the classes
--				is filtered to include only those items where TMClass.PropertyType = 
--				Cases.PropertyType 
-- 03 Sep 2003	TM	6	RFC228 Case SubClasses - stored procedures. Add CL.PROPERTYTYPE = C.PROPERTYTYPE
--				condition to the where clause. 
-- 25 Nov 2011	ASH	7	Change the size of Case Key and Related Case key to 11.

as
begin	
	set nocount on

	declare @nErrorCode 	int
	declare @nCaseId 	int
	declare @sLocalClasses	nvarchar(255)
	declare @sCountryCode	nvarchar(3)

	set @nCaseId = cast(@psCaseKey as int)

	set @nErrorCode = @@Error

	If @nErrorCode=0
	begin
		select	case when CL.SUBCLASS is not null then CL.CLASS + '.' + CL.SUBCLASS else CL.CLASS end as 'ClassKey',
			case when CL.SUBCLASS is not null then CL.CLASS + '.' + CL.SUBCLASS else CL.CLASS end as 'Class',  
			CL.CLASSHEADING as 'ClassHeading'
		from	CASES C
		left join TMCLASS CL	on (CL.COUNTRYCODE = (	select min(CL1.COUNTRYCODE)
								from TMCLASS CL1
								where CL1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')
								and   CL1.PROPERTYTYPE = C.PROPERTYTYPE ) )
								
		where 	C.CASEID = @nCaseId
		and     CL.PROPERTYTYPE = C.PROPERTYTYPE
		order by CL.CLASS
	
		set @nErrorCode=@@Error
	end

	return @nErrorCode
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ipn_ListTrademarkClasses to public
go

