-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ListCaseCopy
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_ListCaseCopy]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_ListCaseCopy.'
	Drop procedure [dbo].[cs_ListCaseCopy]
	Print '**** Creating Stored Procedure dbo.cs_ListCaseCopy...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

CREATE procedure dbo.cs_ListCaseCopy
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			nvarchar(11)		-- Mandatory 

-- PROCEDURE :	cs_ListCaseCopy
-- VERSION :	6
-- DESCRIPTION:	Populates the CaseCopy dataset.
-- SCOPE:	CPA.net, InPro.net

-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 23/07/2002	JB	1	Procedure created
-- 23 Oct 2002	JEK	2	Restrict profiles to those with relationships
--				that are valid for the case.
-- 27 May 2005	TM	5	RFC2584	Data should not be defaulted if the CopyProfile.StopCopy flag = 1.
-- 11 Apr 2013	DV	6	R13270  Increase the length of nvarchar to 11 when casting or declaring integer
as 

------------
-- Settings
set nocount on
set concat_null_yields_null off


-------------
-- Declarations
Declare @nCaseId int
Set @nCaseId = Cast(@psCaseKey as int)

Declare	@nErrorCode	 int
Set	@nErrorCode=0


------------
-- Profile
If @nErrorCode=0
Begin
	Select 	DISTINCT
		CP.[PROFILENAME] as ProfileKey,
		CP.[PROFILENAME] as ProfileName
	From	[COPYPROFILE] CP
	join 	CASES C on		(C.CASEID = @nCaseId)
	left join [COPYPROFILE] REL ON	(REL.[PROFILENAME] = CP.[PROFILENAME]
					 AND REL.[COPYAREA] = 'ADD_RELATIONSHIP')
	Where	not EXISTS
		(Select * from [COUNTRYFLAGS] CF
			Where CF.[PROFILENAME] = CP.[PROFILENAME] ) 
	and	(
		REL.CHARACTERKEY IS NULL 
		OR
		REL.CHARACTERKEY IN 
			(Select VR.RELATIONSHIP
			from VALIDRELATIONSHIPS VR 
			where 
			C.PROPERTYTYPE = VR.PROPERTYTYPE AND
			VR.COUNTRYCODE = 
			( 	select min( VR1.COUNTRYCODE )
				from VALIDRELATIONSHIPS VR1
				where VR1.COUNTRYCODE in ( 'ZZZ', C.COUNTRYCODE )
					and VR1.PROPERTYTYPE = C.PROPERTYTYPE
				AND VR1.RELATIONSHIP = VR.RELATIONSHIP 
			))
		)

	Set @nErrorCode=@@Error
End

-------------------
-- Profile Default
If @nErrorCode=0
Begin
	Select	P.[PROFILENAME] as ProfileKey, 
		case when FAM.[PROFILENAME] is null
			then null
			else case when FAM.[REPLACEMENTDATA] is null 
				then C.[FAMILY]
				else FAM.[REPLACEMENTDATA]
				end
			end as CaseFamilyReference,
		case when CTRY.[PROFILENAME] is null
			then null
			else case when CTRY.[REPLACEMENTDATA] is null 
				then C.[COUNTRYCODE]
				else CTRY.[REPLACEMENTDATA]
				end
			end as CountryKey,
		CY.[COUNTRY] as CountryName,
		case when CAT.[PROFILENAME] is null
			then null
			else case when CAT.[REPLACEMENTDATA] is null 
				then C.[CASECATEGORY]
				else CAT.[REPLACEMENTDATA]
				end
			end as CaseCategoryKey,
		CC.[CASECATEGORYDESC] AS CaseCategoryDescription,
		case when SUB.[PROFILENAME] is null
			then null
			else case when SUB.[REPLACEMENTDATA] is null 
				then C.[SUBTYPE]
				else SUB.[REPLACEMENTDATA]
				end
			end as SubTypeKey,
		ST.[SUBTYPEDESC] as SubTypeDescription,
		case when STAT.[PROFILENAME] is null
			then null
			else case when STAT.[REPLACEMENTDATA] is null 
				then C.[STATUSCODE]
				else STAT.[REPLACEMENTDATA]
				end
			end as CaseStatusKey,
		S.[INTERNALDESC] AS CaseStatusDescription,
		case when APP.[PROFILENAME] is null
			then null
			else case when APP.[REPLACEMENTDATA] is null 
				then O.[OFFICIALNUMBER]
				else APP.[REPLACEMENTDATA]
				end
			end as ApplicationNumber,
		case when APD.[PROFILENAME] is null
			then null
			else case when APD.[REPLACEMENTDATA] is null 
				then CE.[EVENTDATE]
				else APD.[REPLACEMENTDATA]
				end
			end as ApplicationDate
	
	from [COPYPROFILE] P 
	
	join [CASES] C ON		(C.[CASEID] = @nCaseId)
	
	join [NUMBERTYPES] NT ON	(NT.[NUMBERTYPE] = 'A')
	
	left join [CASEEVENT] CE ON	(CE.[CASEID] = C.[CASEID] 
					and	 CE.[EVENTNO] = NT.[RELATEDEVENTNO])
	left join [OFFICIALNUMBERS] O ON 
				(	O.[CASEID] = C.[CASEID]
				and	O.[NUMBERTYPE] = 'A' 
				and (	O.[ISCURRENT] = 1 
				or    (	O.[ISCURRENT] is null 
				and not exists 
					( 	select 	* 
						from  	OFFICIALNUMBERS O1 
						where 	O1.CASEID = O.CASEID 
						and 	O1.NUMBERTYPE = O.NUMBERTYPE 
						and 	O1.ISCURRENT = 1
					)
				      )
				    )
				)
	
	left join [COPYPROFILE] FAM ON	(FAM.[PROFILENAME] = P.[PROFILENAME]
					 AND FAM.[COPYAREA] = 'CASES'
					 AND FAM.[CHARACTERKEY] = 'FAMILY'
					 AND    (FAM.STOPCOPY = 0
					  OR     FAM.STOPCOPY is null))
	
	left join [COPYPROFILE] CTRY ON	(CTRY.[PROFILENAME] = P.[PROFILENAME]
					 AND CTRY.[COPYAREA] = 'CASES'
					 AND CTRY.[CHARACTERKEY] = 'COUNTRYCODE'
					  AND   (CTRY.STOPCOPY = 0
					  OR     CTRY.STOPCOPY is null))
	
	left join [COPYPROFILE] CAT ON	(CAT.[PROFILENAME] = P.[PROFILENAME]
					 AND CAT.[COPYAREA] = 'CASES'
					 AND CAT.[CHARACTERKEY] = 'CASECATEGORY'
					 AND   (CAT.STOPCOPY = 0
					  OR    CAT.STOPCOPY is null))
	
	left join [COPYPROFILE] SUB ON	(SUB.[PROFILENAME] = P.[PROFILENAME]
					 AND SUB.[COPYAREA] = 'CASES'
					 AND SUB.[CHARACTERKEY] = 'SUBTYPE'
					 AND   (SUB.STOPCOPY = 0
					  OR    SUB.STOPCOPY is null))
	
	left join [COPYPROFILE] STAT ON	(STAT.[PROFILENAME] = P.[PROFILENAME]
					 AND STAT.[COPYAREA] = 'CASES'
					 AND STAT.[CHARACTERKEY] = 'STATUSCODE'
					 AND   (STAT.STOPCOPY = 0
					  OR    STAT.STOPCOPY is null))
	
	left join [COPYPROFILE] APP ON	(APP.[PROFILENAME] = P.[PROFILENAME]
					 AND APP.[COPYAREA] = 'OFFICIALNUMBERS'
					 AND APP.[CHARACTERKEY] = 'A'
					 AND   (APP.STOPCOPY = 0
					  OR    APP.STOPCOPY is null))
	
	left join [COPYPROFILE] APD ON	(APD.[PROFILENAME] = P.[PROFILENAME]
					 AND APD.[COPYAREA] = 'CASEEVENT'
					 AND APD.[NUMERICKEY] = NT.[RELATEDEVENTNO]
					  AND   (APD.STOPCOPY = 0
					  OR     APD.STOPCOPY is null))
	
	left join [COPYPROFILE] REL ON	(REL.[PROFILENAME] = P.[PROFILENAME]
					 AND REL.[COPYAREA] = 'ADD_RELATIONSHIP'
					 AND   (REL.STOPCOPY = 0
					  OR    REL.STOPCOPY is null))
	
	left join [COUNTRY] CY ON	
		(case when CTRY.[PROFILENAME] is null
			then null
			else case when CTRY.[REPLACEMENTDATA] is null 
				then C.[COUNTRYCODE]
				else CTRY.[REPLACEMENTDATA]
				end
			end
			 = CY.[COUNTRYCODE])
	
	left join [CASECATEGORY] CC ON	
		(case when CAT.[PROFILENAME] is null
			then null
			else case when CAT.[REPLACEMENTDATA] is null 
				then C.[CASECATEGORY]
				else CAT.[REPLACEMENTDATA]
				end
			end
			= CC.[CASECATEGORY] 
			and CC.[CASETYPE] = C.[CASETYPE])
	
	left join SUBTYPE ST ON
		(case when SUB.[PROFILENAME] is null
			then null
			else case when SUB.[REPLACEMENTDATA] is null 
				then C.[SUBTYPE]
				else SUB.[REPLACEMENTDATA]
				end
			end
			= ST.[SUBTYPE])
	
	left join STATUS S ON
		(case when STAT.[PROFILENAME] is null
			then null
			else case when STAT.[REPLACEMENTDATA] is null 
				then C.[STATUSCODE]
				else STAT.[REPLACEMENTDATA]
				end
			end
			= S.[STATUSCODE])
	
	Where not exists
		(SELECT * FROM COUNTRYFLAGS CF
			where CF.PROFILENAME = P.PROFILENAME) 
			and P.SEQUENCENO IN
				(SELECT MIN(P1.SEQUENCENO)
				 FROM COPYPROFILE P1
				 WHERE P1.PROFILENAME = P.PROFILENAME)
	and	(
		REL.CHARACTERKEY IS NULL 
		OR
		REL.CHARACTERKEY IN 
			(Select VR.RELATIONSHIP
			from VALIDRELATIONSHIPS VR 
			where 
			C.PROPERTYTYPE = VR.PROPERTYTYPE AND
			VR.COUNTRYCODE = 
			( 	select min( VR1.COUNTRYCODE )
				from VALIDRELATIONSHIPS VR1
				where VR1.COUNTRYCODE in ( 'ZZZ', C.COUNTRYCODE )
					and VR1.PROPERTYTYPE = C.PROPERTYTYPE
				AND VR1.RELATIONSHIP = VR.RELATIONSHIP 
			))
		)

	Set @nErrorCode=@@Error
End

RETURN @nErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_ListCaseCopy to public
go
