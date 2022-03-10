-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCriteriaNoWithCopyProfile
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCriteriaNoWithCopyProfile') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetCriteriaNoWithCopyProfile.'
	drop function dbo.fn_GetCriteriaNoWithCopyProfile
end
print '**** Creating function dbo.fn_GetCriteriaNoWithCopyProfile...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

create Function dbo.fn_GetCriteriaNoWithCopyProfile
			(
			@pnCaseID	int,
			@pnParentCaseID	int,
			@psPurposeCode	nchar(1),
			@psGenericParm	nvarchar(8),
			@pdtToday	datetime	
			)
Returns int
as
-- FUNCTION :	fn_GetCriteriaNoWithCopyProfile
-- VERSION :	4
-- DESCRIPTION:	This function returns the CRITERIANO for a Case when it is given 
--		a specific Purpose Code. It is a wrapper for the fn_GetCriteriaNo
--		function, containing the 'P' Copy Profile best fit.
--		PurposeCode	Generic Parameter	Type of Control
--		===========     =================	===============
--		    P		None			Copy Profile
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 08/06/2005	JD			Function created
-- 03 Oct 2006	MF	12413	2	Allow substitution of an alternate CASETYPE if not match is found
--					for the CaseType of the Case.  The alternate CaseType is the 
--					ACTUALCASETYPE from the CASETYPE table.
-- 21 Sep 2009  LP      RFC8047 3       Pass null as ProfileKey parameter for fn_GetCriteriaNo
-- 22 Jul 2013	DL	S21395	4	Include SubType in the determination of the defaul Copy Profile to use


Begin
	declare @nCriteriaNo	int
	declare @dtDateOfLaw	datetime
	
	If @psPurposeCode = 'P'
	begin
		SELECT 
		@nCriteriaNo   =
		convert(int,
		substring(
		max (
		CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
			ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
		END +  
		CASE WHEN (C.NEWCASETYPE IS NULL)	THEN '0' 
			ELSE CASE WHEN(C.NEWCASETYPE=CS.CASETYPE)THEN '2' ELSE '1' END 
		END + 
		CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
		CASE WHEN (C.NEWPROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.NEWCOUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.NEWCASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.NEWSUBTYPE IS NULL)	THEN '0' ELSE '1' END +
		convert(varchar,C.CRITERIANO)), 9,20))
		FROM CRITERIA C 
		     join CASES CS	on (CS.CASEID=@pnCaseID)
		     join CASETYPE CT	on (CT.CASETYPE=CS.CASETYPE)
		     join CASES P	on (P.CASEID=@pnParentCaseID)
		WHERE	C.RULEINUSE		= 1  	
		AND	C.PURPOSECODE		= 'P' 
		AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	  is NULL )
		AND (	C.NEWCASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.NEWCASETYPE is NULL )
		AND (	C.NEWCASETYPE		= CS.CASETYPE		or C.NEWCASETYPE	is NULL )
		AND (	C.PROPERTYTYPE 		= P.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL )
		AND (	C.NEWPROPERTYTYPE	= CS.PROPERTYTYPE 	OR C.NEWPROPERTYTYPE 	IS NULL ) 
		AND (	C.COUNTRYCODE 		= P.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.NEWCOUNTRYCODE	= CS.COUNTRYCODE 	OR C.NEWCOUNTRYCODE 	IS NULL ) 
		AND (	C.CASECATEGORY 		= P.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
		AND (	C.NEWCASECATEGORY	= CS.CASECATEGORY 	OR C.NEWCASECATEGORY 	IS NULL )
		AND (	C.SUBTYPE 		= P.SUBTYPE	 	OR C.SUBTYPE	 	IS NULL ) 
		AND (	C.NEWSUBTYPE		= CS.SUBTYPE		OR C.NEWSUBTYPE 	IS NULL )
	end
	ELSE
		SELECT @nCriteriaNo = [dbo].[fn_GetCriteriaNo] ( @pnCaseID, @psPurposeCode, @psGenericParm, @pdtToday, null)
	
	Return @nCriteriaNo
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant REFERENCES, EXECUTE on dbo.fn_GetCriteriaNoWithCopyProfile to public
GO
