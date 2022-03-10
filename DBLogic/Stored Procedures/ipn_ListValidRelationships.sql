-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListValidRelationships
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListValidRelationships]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipn_ListValidRelationships.'
	drop procedure [dbo].[ipn_ListValidRelationships]
	print '**** Creating Stored Procedure dbo.ipn_ListValidRelationships...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

CREATE PROCEDURE dbo.ipn_ListValidRelationships
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psCaseKey			varchar(11) 		= null	-- the Case whose Valid Relationships are to be displayed

-- PROCEDURE :	ipn_ListValidRelationships
-- VERSION :	7
-- DESCRIPTION:	List Valid Relationships for Case Update Support
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 18/07/2002	Siew Fai			Procedure created
-- 25 Nov 2011	ASH	R100640	7 Change the size of Case Key and Related Case key to 11.
as

set nocount on
declare @sSQLString	nvarchar(4000)
declare @ErrorCode	int
set @ErrorCode=0
	
if @psCaseKey is not null
begin
	Set @sSQLString="
	select 	VR.RELATIONSHIP		as 'RelationshipTypeKey',
		CR.RELATIONSHIPDESC	as 'RelationshipTypeDescription',
		VR.COUNTRYCODE		as 'CountryKey',
		VR.PROPERTYTYPE		as 'PropertyTypeKey'
	from 	CASES C
	join  	VALIDRELATIONSHIPS VR	on (VR.PROPERTYTYPE=C.PROPERTYTYPE
					and VR.COUNTRYCODE=(	select min(VR1.COUNTRYCODE)
								from VALIDRELATIONSHIPS VR1
								where VR1.PROPERTYTYPE=VR.PROPERTYTYPE
								and   VR1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	join CASERELATION CR 		on (CR.RELATIONSHIP = VR.RELATIONSHIP
					and CR.SHOWFLAG = 1)
	where C.CASEID= cast(@psCaseKey as int)
	order by CR.RELATIONSHIPDESC"
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psCaseKey	varchar(11)',
					  @psCaseKey
end
else begin
	set @sSQLString="
	select 	VR.RELATIONSHIP		as 'RelationshipTypeKey',
		CR.RELATIONSHIPDESC	as 'RelationshipTypeDescription',
		VR.COUNTRYCODE		as 'CountryKey',
		VR.PROPERTYTYPE		as 'PropertyTypeKey'
	from 	VALIDRELATIONSHIPS 	as VR
	join 	CASERELATION CR 	on (CR.RELATIONSHIP = VR.RELATIONSHIP
					and CR.SHOWFLAG = 1)
	order by CR.RELATIONSHIPDESC"

	exec @ErrorCode=sp_executesql @sSQLString
end

Return @ErrorCode
go

grant execute on dbo.ipn_ListValidRelationships  to public
go
