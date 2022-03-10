-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ListCaseHierarchy
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_ListCaseHierarchy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_ListCaseHierarchy.'
	drop procedure dbo.cs_ListCaseHierarchy
end
print '**** Creating procedure dbo.cs_ListCaseHierarchy...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_ListCaseHierarchy
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnCaseKey			int			-- the Case whose hierarchy is to be displayed.
)
as
-- PROCEDURE :	cs_ListCaseHierarchy
-- DESCRIPTION:	Lists the CHILDCASE Cases and their direct PARENTCASE Case
-- SCOPE:	CPA.net, InPro.net
-- CALLED BY :	DataAccess directly

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Jun 2002	MF		1	Procedure created
-- 18 Jul 2002	MF		2	Update to only include Relationships that are flagged
--					as pointing to a parent case.
-- 28 Oct 2002	SF		3	Changed Parameter @pnCaseId to @pnCaseKey (for standard conformance)
-- 12 Nov 2002  MF		4	Only show the child Case if it does not have another Parent that also
--					exists at the same level
-- 11 Feb 2002	SF		5	Add new columns - SubTypeKey, SubTypeDescription, ApplicationBasisKey and ApplicationBasisDescription.
--					For detail information, please refer to RFC05
-- 05 Aug 2004	AB	8035	6	Add collate database_default to temp table definitions
-- 07 Sep 2018	AV	74738	7	Set isolation level to read uncommited.

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

create table #CaseTree(	SEQ		smallint	identity,
			DEPTH		tinyint,
			PARENTCASE	int,
			CHILDCASE	int,
			RELATIONSHIP	nvarchar(3) collate database_default)

declare @ErrorCode	int
declare @sSQLString	nvarchar(4000)

set @ErrorCode=0

-- NOTE : We are working on the assumption that the RelatedCase relationship describes
--        the relationship from the CHILD case pointing to the PARENT case.  This will 
--        be further confirmed after we allow specific Relationships to be flagged as being
--        pointers to the Parent.

if @ErrorCode = 0
begin
	Set @sSQLString="
	insert into #CaseTree(DEPTH, PARENTCASE, CHILDCASE, RELATIONSHIP)
	select 1, R1.RELATEDCASEID, R1.CASEID, R1.RELATIONSHIP
	from RELATEDCASE R1
	join CASERELATION CR	on (CR.RELATIONSHIP=R1.RELATIONSHIP
				and CR.POINTERTOPARENT=1)
	where R1.RELATEDCASEID="+convert(nvarchar,@pnCaseKey)+"
	-- exclude Child cases who have a Parent that is also a Child case
	and not exists
	(select * from RELATEDCASE R2
	 join CASERELATION CR2 on (CR2.RELATIONSHIP=R2.RELATIONSHIP
				 and CR2.POINTERTOPARENT=1)
	 where R2.CASEID=R1.CASEID
	 and   R2.RELATEDCASEID in (	select R3.CASEID
					from RELATEDCASE R3
					join CASERELATION CR3	on (CR3.RELATIONSHIP=R3.RELATIONSHIP
								and CR3.POINTERTOPARENT=1)
					where R3.RELATEDCASEID=R1.RELATEDCASEID))"

	exec (@sSQLString)

	select	@pnRowCount=@@Rowcount,
		@ErrorCode =@@Error
End

WHILE	@pnRowCount>0
and	@ErrorCode=0
begin
	set @sSQLString="
	insert into #CaseTree(DEPTH, PARENTCASE, CHILDCASE, RELATIONSHIP)
	select distinct T.DEPTH+1, R1.RELATEDCASEID, R1.CASEID, R1.RELATIONSHIP
	from #CaseTree T
	join RELATEDCASE R1	on (R1.RELATEDCASEID=T.CHILDCASE)
	join CASERELATION CR	on (CR.RELATIONSHIP =R1.RELATIONSHIP)	
	where T.DEPTH=(select max(DEPTH) from #CaseTree)
	and CR.POINTERTOPARENT=1
	and not exists
	(select * from #CaseTree T1
	 where T1.PARENTCASE=R1.CASEID)
	-- exclude Child cases who have a Parent that is also a Child case
	and not exists
	(select * from RELATEDCASE R2
	 join CASERELATION CR2 on (CR2.RELATIONSHIP=R2.RELATIONSHIP
				 and CR2.POINTERTOPARENT=1)
	 where R2.CASEID=R1.CASEID
	 and   R2.RELATEDCASEID in (	select R3.CASEID
					from RELATEDCASE R3
					join CASERELATION CR3	on (CR3.RELATIONSHIP=R3.RELATIONSHIP
								and CR3.POINTERTOPARENT=1)
					where R3.RELATEDCASEID=R1.RELATEDCASEID))"

	exec (@sSQLString)

	Select  @pnRowCount=@@Rowcount,
		@ErrorCode =@@Error
end

-- As a final safeguard delete to ensure the hierarchy is displayed correctly
-- remove any  entries where the Child Case exists at a lower depth.

If @ErrorCode=0
begin
	Set @sSQLString="
	delete from #CaseTree
	where exists
	(select * from #CaseTree CT
	 where CT.CHILDCASE=#CaseTree.CHILDCASE
	 and   CT.DEPTH>#CaseTree.DEPTH)"

	exec @ErrorCode=sp_executesql @sSQLString

end

If @ErrorCode=0
begin
	Set @sSQLString="
	select  C.CASEID		as CaseKey,
		P.CASEID		as ParentCaseKey,
		P.IRN 			as ParentCaseReference, 
		C.IRN 			as CaseReference, 
		C.FAMILY		as CaseFamilyReference,
		CN.COUNTRYCODE		as CountryCode,
		CN.COUNTRY		as CountryName,
		CT.CASETYPE		as CaseTypeCode,
		CT.CASETYPEDESC		as CaseTypeDescription,
		VP.PROPERTYTYPE		as PropertyTypeCode,
		VP.PROPERTYNAME		as PropertyTypeDescription,
		VC.CASECATEGORY		as CaseCategoryCode,
		VC.CASECATEGORYDESC	as CaseCategoryDescription,
		VS.SUBTYPE		as SubTypeKey,
		VS.SUBTYPEDESC		as SubTypeDescription,
		VB.BASIS		as ApplicationBasisKey,
		VB.BASISDESCRIPTION	as ApplicationBasisDescription,
		S.INTERNALDESC		as StatusDescription,
		O1.OFFICIALNUMBER	as ApplicationNumber,
		CE1.EVENTDATE		as ApplicationDate,
		O2.OFFICIALNUMBER	as RegistrationNumber,
		CE2.EVENTDATE		as RegistrationDate,
		O3.OFFICIALNUMBER	as PublicationNumber,
		CE3.EVENTDATE		as PublicationDate
	from #CaseTree T
	join CASES P		on (P.CASEID=T.PARENTCASE)
	join CASES C		on (C.CASEID=T.CHILDCASE)
	join CASERELATION CR	on (CR.RELATIONSHIP=T.RELATIONSHIP)
	join COUNTRY CN		on (CN.COUNTRYCODE=C.COUNTRYCODE)
	join CASETYPE CT	on (CT.CASETYPE=C.CASETYPE)
	left join PROPERTY PR 		on PR.CASEID = C.CASEID
	join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
				and VP.COUNTRYCODE =(	select min(VP1.COUNTRYCODE)
							from VALIDPROPERTY VP1
							where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
							and   VP1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	left join VALIDCATEGORY VC
				on (VC.CASETYPE=C.CASETYPE
				and VC.PROPERTYTYPE=C.PROPERTYTYPE
				and VC.CASECATEGORY=C.CASECATEGORY
				and VC.COUNTRYCODE =(	select min(VC1.COUNTRYCODE)
							from VALIDCATEGORY VC1
							where VC1.CASETYPE=VC.CASETYPE
							and   VC1.PROPERTYTYPE=VC.PROPERTYTYPE
							and   VC1.CASECATEGORY=VC.CASECATEGORY
							and   VC1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))

	left join VALIDSUBTYPE VS	
				on (VS.SUBTYPE = C.SUBTYPE
				AND VS.PROPERTYTYPE = C.PROPERTYTYPE
			 	AND VS.COUNTRYCODE = (	select min(COUNTRYCODE)
							from 	VALIDSUBTYPE VS1
							where 	VS1.SUBTYPE      = C.SUBTYPE
							AND 	VS1.PROPERTYTYPE = C.PROPERTYTYPE
							AND 	VS1.CASETYPE     = C.CASETYPE
							AND 	VS1.CASECATEGORY = C.CASECATEGORY
							AND 	VS1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
			 	AND VS.CASETYPE = C.CASETYPE
			 	AND VS.CASECATEGORY = C.CASECATEGORY
	left join VALIDBASIS VB	
				on (VB.BASIS = PR.BASIS
				AND VB.PROPERTYTYPE = C.PROPERTYTYPE
			 	AND VB.COUNTRYCODE = (select min(COUNTRYCODE)
							from VALIDBASIS VB1
						     	where 	VB1.BASIS      = PR.BASIS
							AND 	VB1.PROPERTYTYPE = C.PROPERTYTYPE
							AND 	VB1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))

	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
	join NUMBERTYPES NT1	on (NT1.NUMBERTYPE='A')
	left join OFFICIALNUMBERS O1
				on (O1.CASEID=C.CASEID
				and O1.NUMBERTYPE=NT1.NUMBERTYPE
				and O1.ISCURRENT =1)
	left join CASEEVENT CE1	on (CE1.CASEID=C.CASEID
				and CE1.EVENTNO=NT1.RELATEDEVENTNO
				and CE1.CYCLE=1)
	join NUMBERTYPES NT2	on (NT2.NUMBERTYPE='R')
	left join OFFICIALNUMBERS O2
				on (O2.CASEID=C.CASEID
				and O2.NUMBERTYPE=NT2.NUMBERTYPE
				and O2.ISCURRENT =1)
	left join CASEEVENT CE2	on (CE2.CASEID=C.CASEID
				and CE2.EVENTNO=NT2.RELATEDEVENTNO
				and CE2.CYCLE=1)
	join NUMBERTYPES NT3	on (NT3.NUMBERTYPE='P')
	left join OFFICIALNUMBERS O3
				on (O3.CASEID=C.CASEID
				and O3.NUMBERTYPE=NT3.NUMBERTYPE
				and O3.ISCURRENT =1)
	left join CASEEVENT CE3	on (CE3.CASEID=C.CASEID
				and CE3.EVENTNO=NT3.RELATEDEVENTNO
				and CE3.CYCLE=1)
	order by DEPTH, P.IRN"

	exec (@sSQLString)

	Select  @pnRowCount=@@Rowcount,
		@ErrorCode =@@Error
end

RETURN @ErrorCode
go

grant execute on dbo.cs_ListCaseHierarchy  to public
go

