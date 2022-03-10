-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ListCaseTree
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_ListCaseTree]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_ListCaseTree.'
	drop procedure dbo.cs_ListCaseTree
end
print '**** Creating procedure dbo.cs_ListCaseTree...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_ListCaseTree
(
	@pnRowCount			int 		= null	OUTPUT,
	@pnUserIdentityId		int,			-- Mandatory
	@pbIsExternalUser		bit,			-- External user flag which should already be known
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnCaseKey			int,			-- the Case whose hierarchy is to be displayed.
	@pbCalledFromCentura		bit 		= 0
)
AS
-- PROCEDURE :	cs_ListCaseTree
-- VERSION :	21
-- DESCRIPTION:	Lists the CHILDCASE Cases and their direct PARENTCASE Case
-- SCOPE:	CPA.net, InPro.net
-- CALLED BY :	DataAccess directly

-- MODIFICTIONS :
-- Date         Who	Number	Version	Change
-- ------------ ----	------	-------	------------------------------------------- 
-- 09 Sep 2003	MF		1	Procedure created
-- 03-Oct-2003	MF	RFC519	2	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 14-Jan-2004	TM	RFC768	3	Rename columns OurReference and ParentOurReference to CaseReference 
--					and ParentCaseReference for internal users. Remove YourReference and 
--					ParentYourReference.
-- 04-Mar-2004	TM	RFC1032	4	Pass NULL as the @pnCaseKey to the fn_FilterUserCases.
-- 05-Aug-2004	TM	RFC1671	5	Sort the result set by DEPTH, CaseReference, CurrentOfficialNumber and 
--					CountryName for internal users and by DEPTH, OurReference, CurrentOfficialNumber
--					and CountryName for external users instead of DEPTH and P.IRN.
-- 18 Aug 2004	AB	8035	6	Add collate database_default syntax to temp tables.
-- 14 Sep 2004	TM	RFC886	7	Implement translation.
-- 20 Oct 2004	TM	RFC1156	8	Add new EventDescription, EventDefinition and EventDate columns.
-- 12 Nov 2004	TM	RFC1156	9	Correct the extraction of the Event data.
-- 15 Dec 2004	TM	RFC1156	10	Add new RowKey column.
-- 01 Dec 2005	TM	RFC3254	11	Remove EventDescription, EventDefinition and EventDate columns.
-- 06 Jan 2006  TM	RFC3375	12	Modify the population of the PARENTOFFICIALNO and CHILDOFFICIALNO columns to use 
--					Application No instead of CURRENTOFFICIALNO for internal related cases.
-- 10 Jan 2006	TM	RFC3375	13	If Application Number does not exists then use Current Official Number 
--					to populate CurrentOfficialNumber and ParentOfficialNumber columns.
-- 17 Jan 2006	TM	RFC3375	14	For the Curren tOfficial Number, use the following code:
--					coalesce(OFFICIALNUMBERS.OFFICIALNUMBER, CASES.CURRENTOFFICIALNO, 
--					RELATEDCASE.OFFICIALNUMBER).
-- 30 Aug 2006	AU	RFC4062	15	Check EARLIEST PRIORITY site control before returning application number as
--					CurrentOfficialNumber
-- 21 Mar 2007	SF	RFC5188	16	Only display relationships where SHOWFLAG=1
-- 11 Dec 2008	MF	17136	17	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 17 Dec 2012	MF	R12975	18	Change the method of determining the related cases so that a more complete set of relationships
--					that better reflects the hierarchy is returned.
--					1. Determinine the full direct ancestry of the Case using relationships that POINTTOPARENT
--					2. For each generation then determine the offspring Cases that point to those parent cases.
--					3. Add any related cases that do not use a POINTTOPARENT relationship that have not already been added.
-- 21 Aug 2014	MF	R38600	19	Need to cater for poor quality related case data where the relationships entered result in a confusing 
--					hierarchy.  This can happen when a child points directly to ancestors older than its direct parent even
--					though the direct parent is correctly pointing to the early ancestor.  E.g. Child A is point to Parent B and
--					to Grandparent C and the Parent B is also correctly pointing to its Parent C.
-- 15 Apr 2015	MF	R41474	20	Remove multiple parents from a Case by choosing the parent as follows :
--					- parent case on database takes precedence over external case
--					- use earliest priority date where parents exist on database
--					- use latest priority date where parents are external
-- 20 Aug 2015	MF	R50942	21	Reversing changes from RFC41474 as this caused other problems.
set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

-- NOTE : Using a table variable.  This means that dynamic SQL methods are not able 
--        to be used.  Testing has shown that this approach is still faster than 
--        using a temporary table with sp_executesql.

declare @tbCaseTree 
		table (	ROWKEY			int		identity (1,1),
			DEPTH			smallint	not null,
			PARENTCASE		int		null,
			PARENTOFFICIALNO	nvarchar(36)	collate database_default null,
			CHILDCASE		int		null,
			CHILDOFFICIALNO		nvarchar(36)	collate database_default null,
			RELATIONSHIP		nvarchar(3)	collate database_default null,
			POINTERTOPARENT		bit		null,
			COUNTRYCODE		nvarchar(3)	collate database_default null,
			CHILDCOUNTRYCODE	nvarchar(3)	collate database_default null
			)

declare @nError		int	
declare @nRowCount	int
declare @nTotalRows	int
declare	@nDepth		int

declare @sLookupCulture nvarchar(10)

Set @nError    =0
Set @nRowCount =0
Set @nTotalRows=0
Set @nDepth    =1
	--------------------------------------------
	-- Load the Case whose hierarchy is to be 
	-- returned along with its direct parent
	--------------------------------------------
If @nError=0
Begin
	insert into @tbCaseTree(DEPTH, PARENTCASE, PARENTOFFICIALNO, CHILDCASE, CHILDOFFICIALNO, RELATIONSHIP, POINTERTOPARENT, COUNTRYCODE, CHILDCOUNTRYCODE)
	-- Case with a pointer to its parent
	select	@nDepth, 
		R.RELATEDCASEID,
		R.OFFICIALNUMBER,
		R.CASEID, 
		NULL,
		CR.RELATIONSHIP,
		CR.POINTERTOPARENT,
		R.COUNTRYCODE,
		NULL
	from RELATEDCASE R
	join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP)
	where R.CASEID=@pnCaseKey
	and (R.RELATEDCASEID<>R.CASEID OR (R.RELATEDCASEID is null and R.OFFICIALNUMBER is not null))
	and CR.POINTERTOPARENT=1
	and CR.SHOWFLAG=1
	UNION
	-- Case that does not indicate a parent
	select	@nDepth, 
		NULL,
		NULL,
		C.CASEID, 
		NULL,
		NULL,
		0,
		NULL,
		NULL
	from CASES C
	where C.CASEID=@pnCaseKey
	and not exists
	(select 1
	 from RELATEDCASE R
	 join CASERELATION CR on (CR.RELATIONSHIP=R.RELATIONSHIP)
	 where R.CASEID=C.CASEID
	 and (R.RELATEDCASEID<>R.CASEID OR (R.RELATEDCASEID is null and R.OFFICIALNUMBER is not null))
	 and CR.POINTERTOPARENT=1
	 and CR.SHOWFLAG=1)
	 
	 Select @nError   =@@ERROR,
		@nRowCount=@@ROWCOUNT,
		@nTotalRows=@@ROWCOUNT
End

---------------------------------------------
-- Now loop through each row just added and 
-- get all of the cases related as the parent.
-- This is to find the entire list of direct
-- ancestors of the original Case.
---------------------------------------------
While @nRowCount>0
and @nError=0
Begin
	set @nDepth=@nDepth-1
	insert into @tbCaseTree(DEPTH, PARENTCASE, PARENTOFFICIALNO, CHILDCASE, CHILDOFFICIALNO, RELATIONSHIP, POINTERTOPARENT, COUNTRYCODE, CHILDCOUNTRYCODE)
	-- Case with a pointer to its parent
	select	@nDepth,
		R.RELATEDCASEID,
		R.OFFICIALNUMBER,
		R.CASEID, 
		NULL,
		CR.RELATIONSHIP,
		CR.POINTERTOPARENT,
		R.COUNTRYCODE,
		NULL
	from @tbCaseTree T
	join RELATEDCASE R	 on (R.CASEID=T.PARENTCASE)
	join CASERELATION CR	 on (CR.RELATIONSHIP=R.RELATIONSHIP)
	left join @tbCaseTree T2 on (T2.PARENTCASE=R.RELATEDCASEID	-- Do not insert Parent/Child combination that already exists
				 and T2.CHILDCASE =R.CASEID)
	where T.DEPTH=@nDepth+1
	and (R.RELATEDCASEID<>R.CASEID OR (R.RELATEDCASEID is null and R.OFFICIALNUMBER is not null))
	and CR.POINTERTOPARENT=1
	and CR.SHOWFLAG=1
	and T2.CHILDCASE is null
	UNION
	-- Case that does not indicate a parent
	select	@nDepth, 
		NULL,
		NULL,
		T.PARENTCASE, 
		T.PARENTOFFICIALNO,
		NULL,
		0,
		NULL,
		T.COUNTRYCODE
	from @tbCaseTree T
	where T.DEPTH=@nDepth+1
	and (T.PARENTCASE is not null OR T.PARENTOFFICIALNO is not null)
	and not exists
	(select 1
	 from RELATEDCASE R
	 join CASERELATION CR on (CR.RELATIONSHIP=R.RELATIONSHIP)
	 where R.CASEID=T.PARENTCASE
	 and (R.RELATEDCASEID<>R.CASEID OR (R.RELATEDCASEID is null and R.OFFICIALNUMBER is not null))
	 and CR.POINTERTOPARENT=1
	 and CR.SHOWFLAG=1)

	Select	@nError=@@ERROR,
		@nRowCount=@@ROWCOUNT
		
	Set @nTotalRows=@nTotalRows+@nRowCount
	
	If @nError=0
	Begin
		-- Remove any rows just added if the Parent Case
		-- already exists as a Child Case.
		delete T
		from @tbCaseTree T
		where T.DEPTH=@nDepth
		and exists
		(select 1
		 from @tbCaseTree T1
		 where T1.CHILDCASE=T.PARENTCASE
		 OR    T1.CHILDOFFICIALNO=T.PARENTOFFICIALNO)
		 
		 Select @nError=@@ERROR,
			@nTotalRows=@nTotalRows-@@ROWCOUNT
	End
End

---------------------------------------------
-- Now starting from the last depth inserted,
-- loop through finding all of the child
-- cases for that generation and add these
-- with an incremented depth.
---------------------------------------------
Set @nRowCount=1
Set @nDepth=@nDepth+1

While @nRowCount>0
and @nError=0
Begin
	insert into @tbCaseTree(DEPTH, PARENTCASE, PARENTOFFICIALNO, CHILDCASE, CHILDOFFICIALNO, RELATIONSHIP, POINTERTOPARENT, COUNTRYCODE, CHILDCOUNTRYCODE)
	-- Case with a pointer to its parent
	select	@nDepth+1,
		R.RELATEDCASEID,
		NULL,
		R.CASEID, 
		NULL,
		CR.RELATIONSHIP,
		CR.POINTERTOPARENT,
		NULL,
		NULL
	from @tbCaseTree T
	join RELATEDCASE R	on (R.RELATEDCASEID=T.CHILDCASE)
	join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP)
	where T.DEPTH=@nDepth
	and  R.RELATEDCASEID<>R.CASEID
	and CR.POINTERTOPARENT=1
	and CR.SHOWFLAG=1
	and not exists
	(Select 1 
	 from @tbCaseTree T
	 where T.CHILDCASE=R.CASEID
	 and T.DEPTH=@nDepth+1)
	-- Case with a pointer to its parent which is identified by Country and Official Number
	UNION ALL
	select	@nDepth+1,
		NULL,
		R.OFFICIALNUMBER,
		R.CASEID, 
		NULL,
		CR.RELATIONSHIP,
		CR.POINTERTOPARENT,
		R.COUNTRYCODE,
		NULL
	from @tbCaseTree T
	join RELATEDCASE R	on (R.RELATEDCASEID is null
				and R.OFFICIALNUMBER=T.CHILDOFFICIALNO
				and R.COUNTRYCODE   =T.CHILDCOUNTRYCODE)
	join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP)
	where T.DEPTH=@nDepth
	and CR.POINTERTOPARENT=1
	and CR.SHOWFLAG=1
	and not exists
	(Select 1 
	 from @tbCaseTree T
	 where T.CHILDCASE=R.CASEID
	 and T.DEPTH=@nDepth+1)

	Select	@nError=@@ERROR,
		@nRowCount=@@ROWCOUNT
		
	Set @nTotalRows=@nTotalRows+@nRowCount
	
	Set @nDepth=@nDepth+1
End

--------------------------------------
-- Load any related Cases where the
-- pointer to parent flag is not on
-- for the relationship and child case
-- has not already been inserted
--------------------------------------
If @nError=0
Begin
	insert into @tbCaseTree(DEPTH, PARENTCASE, PARENTOFFICIALNO, CHILDCASE, CHILDOFFICIALNO, RELATIONSHIP, POINTERTOPARENT, COUNTRYCODE, CHILDCOUNTRYCODE)
	select	T.DEPTH+1,
		R.CASEID,
		NULL,
		R.RELATEDCASEID, 
		NULL,
		CR.RELATIONSHIP,
		0,
		NULL,
		NULL
	from @tbCaseTree T
	join RELATEDCASE R	on (R.RELATEDCASEID=T.CHILDCASE)
	join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP)
	where isnull(CR.POINTERTOPARENT,0)=0
	and  R.RELATEDCASEID<>R.CASEID
	and CR.SHOWFLAG=1
	and not exists
	(Select 1 
	 from @tbCaseTree T
	 where T.CHILDCASE=R.RELATEDCASEID)
	UNION
	select	T.DEPTH+1,
		R.CASEID,
		NULL,
		R.RELATEDCASEID, 
		NULL,
		CR.RELATIONSHIP,
		0,
		NULL,
		NULL
	from @tbCaseTree T
	join RELATEDCASE R	on (R.CASEID=T.CHILDCASE)
	join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP)
	where isnull(CR.POINTERTOPARENT,0)=0
	and  R.RELATEDCASEID<>R.CASEID
	and CR.SHOWFLAG=1
	and not exists
	(Select 1 
	 from @tbCaseTree T
	 where T.CHILDCASE=R.RELATEDCASEID)

	Select	@nError=@@ERROR,
		@nRowCount=@@ROWCOUNT
		
	Set @nTotalRows=@nTotalRows+@nRowCount
End

--------------------------------------
-- Tidy up the hierarchy by removing
-- any child rows pointing to a parent
-- where that same child case exists
-- lower in the hierarchy and the
-- parent exists elsewhere.
--------------------------------------
If @nError=0
and @nTotalRows>0
Begin
	delete T
	from @tbCaseTree T
	where exists
	(Select 1
	 from @tbCaseTree T1
	 where T1.CHILDCASE=T.CHILDCASE
	 and (T1.DEPTH>T.DEPTH OR (T1.DEPTH=T.DEPTH and T1.ROWKEY>T.ROWKEY)))
	and exists
	(Select 1
	 from @tbCaseTree T1
	 where (T1.PARENTCASE=T.PARENTCASE OR T1.PARENTOFFICIALNO=T.PARENTOFFICIALNO)
	 and T1.ROWKEY<>T.ROWKEY)
	 
	 Select	@nError=@@ERROR,
		@nRowCount=@@ROWCOUNT
		
	Set @nTotalRows=@nTotalRows-@nRowCount
End

-----------------------------------------
-- Tidy up the hierarchy by removing
-- any child rows pointing to the same
-- parent with more than one Relationship
-----------------------------------------
If @nError=0
and @nTotalRows>0
Begin
	delete T
	from @tbCaseTree T
	where exists
	(Select 1
	 from @tbCaseTree T1
	 where(T1.CHILDCASE=T.CHILDCASE   OR T1.CHILDOFFICIALNO =T.CHILDOFFICIALNO)
	 and  (T1.PARENTCASE=T.PARENTCASE OR T1.PARENTOFFICIALNO=T.PARENTOFFICIALNO)
	 and   T1.DEPTH     =T.DEPTH
	 and   T1.ROWKEY    >T.ROWKEY)
	 
	 Select	@nError=@@ERROR,
		@nRowCount=@@ROWCOUNT
		
	Set @nTotalRows=@nTotalRows-@nRowCount
End

If @nError=0
begin
	set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)	

	-- For External Users:
	If @pbIsExternalUser=1
	Begin
		-- Is a translation required?
		If @nError=0
		and @sLookupCulture is not null
		Begin
			If @pbCalledFromCentura = 1
			Begin
				select  C.CASEID		as CaseKey,
					P.CASEID		as ParentCaseKey,
					coalesce(O2.OFFICIALNUMBER, C.CURRENTOFFICIALNO, T.CHILDOFFICIALNO)
								as CurrentOfficialNumber,
					coalesce(O.OFFICIALNUMBER, P.CURRENTOFFICIALNO, T.PARENTOFFICIALNO)
								as ParentOfficialNumber,
					FC.CLIENTREFERENCENO	as YourReference,
					FP.CLIENTREFERENCENO	as ParentYourReference,
					C.IRN			as OurReference,
					P.IRN			as ParentOurReference,					
					dbo.fn_GetTranslationLimited(CC.COUNTRY,null,CC.COUNTRY_TID,@sLookupCulture)
								as CountryName,
					dbo.fn_GetTranslationLimited(CP.COUNTRY,null,CP.COUNTRY_TID,@sLookupCulture)
								as ParentCountryName,
					dbo.fn_GetTranslationLimited(C.TITLE,null,C.TITLE_TID,@sLookupCulture)
								as Title,
					dbo.fn_GetTranslationLimited(P.TITLE,null,P.TITLE_TID,@sLookupCulture)
								as ParentTitle,
					dbo.fn_GetTranslationLimited(TC.DESCRIPTION,null,TC.DESCRIPTION_TID,@sLookupCulture)
								as StatusSummary,
					dbo.fn_GetTranslationLimited(TP.DESCRIPTION,null,TP.DESCRIPTION_TID,@sLookupCulture)
								as ParentStatusSummary,
					dbo.fn_GetTranslationLimited(CR.RELATIONSHIPDESC,null,CR.RELATIONSHIPDESC_TID,@sLookupCulture)
								as RelationshipDescription,					
					T.ROWKEY		as RowKey
				from @tbCaseTree T
				left join CASES P	on (P.CASEID=T.PARENTCASE)
				left join fn_FilterUserCases(@pnUserIdentityId, 1, null) FP	
							on (FP.CASEID=P.CASEID)
				left join CASES C	on (C.CASEID=T.CHILDCASE)
				left join fn_FilterUserCases(@pnUserIdentityId, 1, null) FC	
							on (FC.CASEID=C.CASEID)
				join CASERELATION CR	on (CR.RELATIONSHIP=T.RELATIONSHIP)
				left join PROPERTY PRP	on (PRP.CASEID=P.CASEID)
				left join PROPERTY PRC	on (PRC.CASEID=C.CASEID)
				left join COUNTRY CC	on (CC.COUNTRYCODE=isnull(C.COUNTRYCODE,T.CHILDCOUNTRYCODE))
				left join COUNTRY CP	on (CP.COUNTRYCODE=isnull(P.COUNTRYCODE,T.COUNTRYCODE))
				left join STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
				left join STATUS RC	on (RC.STATUSCODE=PRC.RENEWALSTATUS)
				left join TABLECODES TC	on (TC.TABLECODE=CASE WHEN(SC.LIVEFLAG=0 OR RC.LIVEFLAG=0)
											THEN 7603	-- Dead
									      WHEN(SC.REGISTEREDFLAG=1)
											THEN 7602	-- Registered
											ELSE 7601	-- Pending
									 END)
				left join STATUS SP	on (SP.STATUSCODE=P.STATUSCODE)
				left join STATUS RP	on (RP.STATUSCODE=PRP.RENEWALSTATUS)
				left join TABLECODES TP	on (TP.TABLECODE=CASE WHEN(SP.LIVEFLAG=0 OR RP.LIVEFLAG=0)
											THEN 7603	-- Dead
									      WHEN(SP.REGISTEREDFLAG=1)
											THEN 7602	-- Registered
											ELSE 7601	-- Pending
									 END)
				left join SITECONTROL SCT on (SCT.CONTROLID = 'Earliest Priority')
				left join OFFICIALNUMBERS O on (O.CASEID = T.PARENTCASE
							and O.NUMBERTYPE = N'A'  
							and O.ISCURRENT = 1
							and T.RELATIONSHIP = SCT.COLCHARACTER)
				left join OFFICIALNUMBERS O2 on (O2.CASEID = T.CHILDCASE
							and O2.NUMBERTYPE = N'A'  
							and O2.ISCURRENT = 1
							and T.RELATIONSHIP = SCT.COLCHARACTER)
				where (FP.CASEID=P.CASEID or P.CASEID is null)
				and   (FC.CASEID=C.CASEID or C.CASEID is null)
				order by DEPTH, OurReference, CurrentOfficialNumber, CountryName
			
				Select  @pnRowCount=@@Rowcount,
					@nError =@@Error
			End
			Else
			Begin 
				select  C.CASEID		as CaseKey,
					P.CASEID		as ParentCaseKey,
					coalesce(O2.OFFICIALNUMBER, C.CURRENTOFFICIALNO, T.CHILDOFFICIALNO)
								as CurrentOfficialNumber,
					coalesce(O.OFFICIALNUMBER, P.CURRENTOFFICIALNO, T.PARENTOFFICIALNO)
								as ParentOfficialNumber,
					FC.CLIENTREFERENCENO	as YourReference,
					FP.CLIENTREFERENCENO	as ParentYourReference,
					C.IRN			as OurReference,
					P.IRN			as ParentOurReference,					
					dbo.fn_GetTranslation(CC.COUNTRY,null,CC.COUNTRY_TID,@sLookupCulture)
								as CountryName,
					dbo.fn_GetTranslation(CP.COUNTRY,null,CP.COUNTRY_TID,@sLookupCulture)
								as ParentCountryName,
					dbo.fn_GetTranslation(C.TITLE,null,C.TITLE_TID,@sLookupCulture)
								as Title,
					dbo.fn_GetTranslation(P.TITLE,null,P.TITLE_TID,@sLookupCulture)
								as ParentTitle,
					dbo.fn_GetTranslation(TC.DESCRIPTION,null,TC.DESCRIPTION_TID,@sLookupCulture)
								as StatusSummary,
					dbo.fn_GetTranslation(TP.DESCRIPTION,null,TP.DESCRIPTION_TID,@sLookupCulture)
								as ParentStatusSummary,
					dbo.fn_GetTranslation(CR.RELATIONSHIPDESC,null,CR.RELATIONSHIPDESC_TID,@sLookupCulture)
								as RelationshipDescription,					
					T.ROWKEY		as RowKey
				from @tbCaseTree T
				left join CASES P	on (P.CASEID=T.PARENTCASE)
				left join fn_FilterUserCases(@pnUserIdentityId, 1, null) FP	
							on (FP.CASEID=P.CASEID)
				left join CASES C	on (C.CASEID=T.CHILDCASE)
				left join fn_FilterUserCases(@pnUserIdentityId, 1, null) FC	
							on (FC.CASEID=C.CASEID)
				join CASERELATION CR	on (CR.RELATIONSHIP=T.RELATIONSHIP)
				left join PROPERTY PRP	on (PRP.CASEID=P.CASEID)
				left join PROPERTY PRC	on (PRC.CASEID=C.CASEID)
				left join COUNTRY CC	on (CC.COUNTRYCODE=isnull(C.COUNTRYCODE,T.CHILDCOUNTRYCODE))
				left join COUNTRY CP	on (CP.COUNTRYCODE=isnull(P.COUNTRYCODE,T.COUNTRYCODE))
				left join STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
				left join STATUS RC	on (RC.STATUSCODE=PRC.RENEWALSTATUS)
				left join TABLECODES TC	on (TC.TABLECODE=CASE WHEN(SC.LIVEFLAG=0 OR RC.LIVEFLAG=0)
											THEN 7603	-- Dead
									      WHEN(SC.REGISTEREDFLAG=1)
											THEN 7602	-- Registered
											ELSE 7601	-- Pending
									 END)
				left join STATUS SP	on (SP.STATUSCODE=P.STATUSCODE)
				left join STATUS RP	on (RP.STATUSCODE=PRP.RENEWALSTATUS)
				left join TABLECODES TP	on (TP.TABLECODE=CASE WHEN(SP.LIVEFLAG=0 OR RP.LIVEFLAG=0)
											THEN 7603	-- Dead
									      WHEN(SP.REGISTEREDFLAG=1)
											THEN 7602	-- Registered
											ELSE 7601	-- Pending
									 END)
				left join SITECONTROL SCT on (SCT.CONTROLID = 'Earliest Priority')
				left join OFFICIALNUMBERS O on (O.CASEID = T.PARENTCASE
							and O.NUMBERTYPE = N'A'  
							and O.ISCURRENT = 1
							and T.RELATIONSHIP = SCT.COLCHARACTER)
				left join OFFICIALNUMBERS O2 on (O2.CASEID = T.CHILDCASE
							and O2.NUMBERTYPE = N'A'  
							and O2.ISCURRENT = 1
							and T.RELATIONSHIP = SCT.COLCHARACTER)
				where (FP.CASEID=P.CASEID or P.CASEID is null)
				and   (FC.CASEID=C.CASEID or C.CASEID is null)
				order by DEPTH, OurReference, CurrentOfficialNumber, CountryName
			
				Select  @pnRowCount=@@Rowcount,
					@nError =@@Error				
			End
		End
		-- No translation is required
		Else Begin
			select  C.CASEID		as CaseKey,
				P.CASEID		as ParentCaseKey,
				coalesce(O2.OFFICIALNUMBER, C.CURRENTOFFICIALNO, T.CHILDOFFICIALNO)
							as CurrentOfficialNumber,
				coalesce(O.OFFICIALNUMBER, P.CURRENTOFFICIALNO, T.PARENTOFFICIALNO)
							as ParentOfficialNumber,
				FC.CLIENTREFERENCENO	as YourReference,
				FP.CLIENTREFERENCENO	as ParentYourReference,
				C.IRN			as OurReference,
				P.IRN			as ParentOurReference,
				CC.COUNTRY		as CountryName,
				CP.COUNTRY		as ParentCountryName,
				C.TITLE			as Title,
				P.TITLE			as ParentTitle,
				TC.DESCRIPTION		as StatusSummary,
				TP.DESCRIPTION		as ParentStatusSummary,
				CR.RELATIONSHIPDESC	as RelationshipDescription,
				T.ROWKEY		as RowKey
			from @tbCaseTree T
			left join CASES P	on (P.CASEID=T.PARENTCASE)
			left join fn_FilterUserCases(@pnUserIdentityId, 1, null) FP	
						on (FP.CASEID=P.CASEID)
			left join CASES C	on (C.CASEID=T.CHILDCASE)
			left join fn_FilterUserCases(@pnUserIdentityId, 1, null) FC	
						on (FC.CASEID=C.CASEID)
			join CASERELATION CR	on (CR.RELATIONSHIP=T.RELATIONSHIP)
			left join PROPERTY PRP	on (PRP.CASEID=P.CASEID)
			left join PROPERTY PRC	on (PRC.CASEID=C.CASEID)
			left join COUNTRY CC	on (CC.COUNTRYCODE=isnull(C.COUNTRYCODE,T.CHILDCOUNTRYCODE))
			left join COUNTRY CP	on (CP.COUNTRYCODE=isnull(P.COUNTRYCODE,T.COUNTRYCODE))
			left join STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
			left join STATUS RC	on (RC.STATUSCODE=PRC.RENEWALSTATUS)
			left join TABLECODES TC	on (TC.TABLECODE=CASE WHEN(SC.LIVEFLAG=0 OR RC.LIVEFLAG=0)
										THEN 7603	-- Dead
								      WHEN(SC.REGISTEREDFLAG=1)
										THEN 7602	-- Registered
										ELSE 7601	-- Pending
								 END)
			left join STATUS SP	on (SP.STATUSCODE=P.STATUSCODE)
			left join STATUS RP	on (RP.STATUSCODE=PRP.RENEWALSTATUS)
			left join TABLECODES TP	on (TP.TABLECODE=CASE WHEN(SP.LIVEFLAG=0 OR RP.LIVEFLAG=0)
										THEN 7603	-- Dead
								      WHEN(SP.REGISTEREDFLAG=1)
										THEN 7602	-- Registered
										ELSE 7601	-- Pending
								 END)
			left join SITECONTROL SCT on (SCT.CONTROLID = 'Earliest Priority')
			left join OFFICIALNUMBERS O on (O.CASEID = T.PARENTCASE
							and O.NUMBERTYPE = N'A'  
							and O.ISCURRENT = 1
							and T.RELATIONSHIP = SCT.COLCHARACTER)
			left join OFFICIALNUMBERS O2 on (O2.CASEID = T.CHILDCASE
							and O2.NUMBERTYPE = N'A'  
							and O2.ISCURRENT = 1
							and T.RELATIONSHIP = SCT.COLCHARACTER)
			where (FP.CASEID=P.CASEID or P.CASEID is null)
			and   (FC.CASEID=C.CASEID or C.CASEID is null)
			order by DEPTH, OurReference, CurrentOfficialNumber, CountryName
		
			Select  @pnRowCount=@@Rowcount,
				@nError =@@Error
		End		
	end
	-- For Internal Users:
	Else Begin
		-- Is a translation required?
		If @nError=0
		and @sLookupCulture is not null
		Begin
			If @pbCalledFromCentura = 1
			Begin 
				select  C.CASEID		as CaseKey,
					P.CASEID		as ParentCaseKey,
					coalesce(O2.OFFICIALNUMBER, C.CURRENTOFFICIALNO, T.CHILDOFFICIALNO)
								as CurrentOfficialNumber,
					coalesce(O.OFFICIALNUMBER, P.CURRENTOFFICIALNO, T.PARENTOFFICIALNO)
								as ParentOfficialNumber,
					C.IRN			as CaseReference,
					P.IRN			as ParentCaseReference,
					dbo.fn_GetTranslationLimited(CC.COUNTRY,null,CC.COUNTRY_TID,@sLookupCulture)
								as CountryName,
					dbo.fn_GetTranslation(CP.COUNTRY,null,CP.COUNTRY_TID,@sLookupCulture)
								as ParentCountryName,
					dbo.fn_GetTranslationLimited(C.TITLE,null,C.TITLE_TID,@sLookupCulture)
								as Title,
					dbo.fn_GetTranslationLimited(P.TITLE,null,P.TITLE_TID,@sLookupCulture)
								as ParentTitle,
					dbo.fn_GetTranslationLimited(TC.DESCRIPTION,null,TC.DESCRIPTION_TID,@sLookupCulture)
								as StatusSummary,
					dbo.fn_GetTranslationLimited(TP.DESCRIPTION,null,TP.DESCRIPTION_TID,@sLookupCulture)
								as ParentStatusSummary,
					dbo.fn_GetTranslationLimited(CR.RELATIONSHIPDESC,null,CR.RELATIONSHIPDESC_TID,@sLookupCulture)
								as RelationshipDescription,
					T.ROWKEY		as RowKey
				from @tbCaseTree T
				left join CASES P	on (P.CASEID=T.PARENTCASE)
				left join CASES C	on (C.CASEID=T.CHILDCASE)
				join CASERELATION CR	on (CR.RELATIONSHIP=T.RELATIONSHIP)
				left join PROPERTY PRP	on (PRP.CASEID=P.CASEID)
				left join PROPERTY PRC	on (PRC.CASEID=C.CASEID)
				left join COUNTRY CC	on (CC.COUNTRYCODE=isnull(C.COUNTRYCODE,T.CHILDCOUNTRYCODE))
				left join COUNTRY CP	on (CP.COUNTRYCODE=isnull(P.COUNTRYCODE,T.COUNTRYCODE))
				left join STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
				left join STATUS RC	on (RC.STATUSCODE=PRC.RENEWALSTATUS)
				left join TABLECODES TC	on (TC.TABLECODE=CASE WHEN(SC.LIVEFLAG=0 OR RC.LIVEFLAG=0)
											THEN 7603	-- Dead
									      WHEN(SC.REGISTEREDFLAG=1)
											THEN 7602	-- Registered
											ELSE 7601	-- Pending
									 END)
				left join STATUS SP	on (SP.STATUSCODE=P.STATUSCODE)
				left join STATUS RP	on (RP.STATUSCODE=PRP.RENEWALSTATUS)
				left join TABLECODES TP	on (TP.TABLECODE=CASE WHEN(SP.LIVEFLAG=0 OR RP.LIVEFLAG=0)
											THEN 7603	-- Dead
									      WHEN(SP.REGISTEREDFLAG=1)
											THEN 7602	-- Registered
											ELSE 7601	-- Pending
									 END)
				left join SITECONTROL SCT on (SCT.CONTROLID = 'Earliest Priority')
				left join OFFICIALNUMBERS O on (O.CASEID = T.PARENTCASE
							and O.NUMBERTYPE = N'A'  
							and O.ISCURRENT = 1
							and T.RELATIONSHIP = SCT.COLCHARACTER)
				left join OFFICIALNUMBERS O2 on (O2.CASEID = T.CHILDCASE
							and O2.NUMBERTYPE = N'A'  
							and O2.ISCURRENT = 1
							and T.RELATIONSHIP = SCT.COLCHARACTER)
				order by DEPTH, CaseReference, CurrentOfficialNumber, CountryName
			
				Select  @pnRowCount=@@Rowcount,
					@nError =@@Error
			End
			Else Begin  
				select  C.CASEID		as CaseKey,
					P.CASEID		as ParentCaseKey,
					coalesce(O2.OFFICIALNUMBER, C.CURRENTOFFICIALNO, T.CHILDOFFICIALNO)
								as CurrentOfficialNumber,
					coalesce(O.OFFICIALNUMBER, P.CURRENTOFFICIALNO, T.PARENTOFFICIALNO)
								as ParentOfficialNumber,
					C.IRN			as CaseReference,
					P.IRN			as ParentCaseReference,
					dbo.fn_GetTranslation(CC.COUNTRY,null,CC.COUNTRY_TID,@sLookupCulture)
								as CountryName,
					dbo.fn_GetTranslation(CP.COUNTRY,null,CP.COUNTRY_TID,@sLookupCulture)
								as ParentCountryName,
					dbo.fn_GetTranslation(C.TITLE,null,C.TITLE_TID,@sLookupCulture)
								as Title,
					dbo.fn_GetTranslation(P.TITLE,null,P.TITLE_TID,@sLookupCulture)
								as ParentTitle,
					dbo.fn_GetTranslation(TC.DESCRIPTION,null,TC.DESCRIPTION_TID,@sLookupCulture)
								as StatusSummary,
					dbo.fn_GetTranslation(TP.DESCRIPTION,null,TP.DESCRIPTION_TID,@sLookupCulture)
								as ParentStatusSummary,
					dbo.fn_GetTranslation(CR.RELATIONSHIPDESC,null,CR.RELATIONSHIPDESC_TID,@sLookupCulture)
								as RelationshipDescription,
					T.ROWKEY		as RowKey
				from @tbCaseTree T
				left join CASES P	on (P.CASEID=T.PARENTCASE)
				left join CASES C	on (C.CASEID=T.CHILDCASE)
				join CASERELATION CR	on (CR.RELATIONSHIP=T.RELATIONSHIP)
				left join PROPERTY PRP	on (PRP.CASEID=P.CASEID)
				left join PROPERTY PRC	on (PRC.CASEID=C.CASEID)
				left join COUNTRY CC	on (CC.COUNTRYCODE=isnull(C.COUNTRYCODE,T.CHILDCOUNTRYCODE))
				left join COUNTRY CP	on (CP.COUNTRYCODE=isnull(P.COUNTRYCODE,T.COUNTRYCODE))
				left join STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
				left join STATUS RC	on (RC.STATUSCODE=PRC.RENEWALSTATUS)
				left join TABLECODES TC	on (TC.TABLECODE=CASE WHEN(SC.LIVEFLAG=0 OR RC.LIVEFLAG=0)
											THEN 7603	-- Dead
									      WHEN(SC.REGISTEREDFLAG=1)
											THEN 7602	-- Registered
											ELSE 7601	-- Pending
									 END)
				left join STATUS SP	on (SP.STATUSCODE=P.STATUSCODE)
				left join STATUS RP	on (RP.STATUSCODE=PRP.RENEWALSTATUS)
				left join TABLECODES TP	on (TP.TABLECODE=CASE WHEN(SP.LIVEFLAG=0 OR RP.LIVEFLAG=0)
											THEN 7603	-- Dead
									      WHEN(SP.REGISTEREDFLAG=1)
											THEN 7602	-- Registered
											ELSE 7601	-- Pending
									 END)
				left join SITECONTROL SCT on (SCT.CONTROLID = 'Earliest Priority')
				left join OFFICIALNUMBERS O on (O.CASEID = T.PARENTCASE
							and O.NUMBERTYPE = N'A'  
							and O.ISCURRENT = 1
							and T.RELATIONSHIP = SCT.COLCHARACTER)
				left join OFFICIALNUMBERS O2 on (O2.CASEID = T.CHILDCASE
							and O2.NUMBERTYPE = N'A'  
							and O2.ISCURRENT = 1
							and T.RELATIONSHIP = SCT.COLCHARACTER)
				order by DEPTH, CaseReference, CurrentOfficialNumber, CountryName
			
				Select  @pnRowCount=@@Rowcount,
					@nError =@@Error			
			End
		End
		-- No translation is required
		Else Begin     
			select  C.CASEID		as CaseKey,
				P.CASEID		as ParentCaseKey,
				coalesce(O2.OFFICIALNUMBER, C.CURRENTOFFICIALNO, T.CHILDOFFICIALNO)
							as CurrentOfficialNumber,
				coalesce(O.OFFICIALNUMBER, P.CURRENTOFFICIALNO, T.PARENTOFFICIALNO)
							as ParentOfficialNumber,
				C.IRN			as CaseReference,
				P.IRN			as ParentCaseReference,
				CC.COUNTRY		as CountryName,
				CP.COUNTRY		as ParentCountryName,
				C.TITLE			as Title,
				P.TITLE			as ParentTitle,
				TC.DESCRIPTION		as StatusSummary,
				TP.DESCRIPTION		as ParentStatusSummary,
				CR.RELATIONSHIPDESC	as RelationshipDescription,
				T.ROWKEY		as RowKey
			from @tbCaseTree T
			left join CASES P	on (P.CASEID=T.PARENTCASE)
			left join CASES C	on (C.CASEID=T.CHILDCASE)
			join CASERELATION CR	on (CR.RELATIONSHIP=T.RELATIONSHIP)
			left join PROPERTY PRP	on (PRP.CASEID=P.CASEID)
			left join PROPERTY PRC	on (PRC.CASEID=C.CASEID)
			left join COUNTRY CC	on (CC.COUNTRYCODE=isnull(C.COUNTRYCODE,T.CHILDCOUNTRYCODE))
			left join COUNTRY CP	on (CP.COUNTRYCODE=isnull(P.COUNTRYCODE,T.COUNTRYCODE))
			left join STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
			left join STATUS RC	on (RC.STATUSCODE=PRC.RENEWALSTATUS)
			left join TABLECODES TC	on (TC.TABLECODE=CASE WHEN(SC.LIVEFLAG=0 OR RC.LIVEFLAG=0)
										THEN 7603	-- Dead
								      WHEN(SC.REGISTEREDFLAG=1)
										THEN 7602	-- Registered
										ELSE 7601	-- Pending
								 END)
			left join STATUS SP	on (SP.STATUSCODE=P.STATUSCODE)
			left join STATUS RP	on (RP.STATUSCODE=PRP.RENEWALSTATUS)
			left join TABLECODES TP	on (TP.TABLECODE=CASE WHEN(SP.LIVEFLAG=0 OR RP.LIVEFLAG=0)
										THEN 7603	-- Dead
								      WHEN(SP.REGISTEREDFLAG=1)
										THEN 7602	-- Registered
										ELSE 7601	-- Pending
								 END)
			left join SITECONTROL SCT on (SCT.CONTROLID = 'Earliest Priority')
			left join OFFICIALNUMBERS O on (O.CASEID = T.PARENTCASE
						and O.NUMBERTYPE = N'A'  
						and O.ISCURRENT = 1
						and T.RELATIONSHIP = SCT.COLCHARACTER)
			left join OFFICIALNUMBERS O2 on (O2.CASEID = T.CHILDCASE
						and O2.NUMBERTYPE = N'A'  
						and O2.ISCURRENT = 1
						and T.RELATIONSHIP = SCT.COLCHARACTER)
			order by DEPTH, CaseReference, CurrentOfficialNumber, CountryName
		
			Select  @pnRowCount=@@Rowcount,
				@nError =@@Error
		End		
	end
end

RETURN @nError
go

grant execute on dbo.cs_ListCaseTree  to public
go
