-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCriteriaNoForLawImportBlocking
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCriteriaNoForLawImportBlocking') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetCriteriaNoForLawImportBlocking.'
	drop function dbo.fn_GetCriteriaNoForLawImportBlocking
	print '**** Creating function dbo.fn_GetCriteriaNoForLawImportBlocking...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_GetCriteriaNoForLawImportBlocking
			(
			@psCaseType		nchar(1),
			@psAction		nvarchar(2),
			@psPropertyType		nchar(1),
			@psCountryCode		nvarchar(3),
			@psCaseCategory		nvarchar(2),
			@psSubType		nvarchar(2),
			@psBasis		nvarchar(2),
			@pdtDateOfAct		datetime
			)
Returns int

-- FUNCTION :	fn_GetCriteriaNoForLawImportBlocking
-- VERSION :	1
-- DESCRIPTION:	This function returns the CRITERIANO for characteristics provided 
--		from a Criteria that is a candidate to be imported to either load a 
--		a new criteria or update an existing criteria.
--		The CRITERIANO returned will be for the best rule that matches those
--		characteristics to determine if the incoming Criteria is allowed to
--		be imported or not.
 
-- MODIFICATION
-- Date		Who	No.	Version	Description
-- ====         ===	=== 	=======	===========
-- 11 Jul 2013	MF	R13596	1	Function created
as
Begin
	declare @nCriteriaNo	int

	-- Law Update Blocking
	SELECT 
	@nCriteriaNo   =
	convert(int,
	substring(
	max (
	CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
		ELSE CASE WHEN(C.CASETYPE=@psCaseType) 	 THEN '2' ELSE '1' END 
	END +  
	CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
	CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (C.BASIS IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (C.DATEOFACT IS NULL)		THEN '0' ELSE '1' END +
	isnull(convert(varchar, DATEOFACT, 112),'00000000') +
	convert(varchar,C.CRITERIANO)), 16,20))
	FROM CRITERIA C 
	left join CASETYPE CT	on (CT.CASETYPE=@psCaseType)
	WHERE	C.PURPOSECODE		= 'X'
	AND (	C.CASETYPE	      in (CT.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
	AND 	C.ACTION		= @psAction
	AND (	C.PROPERTYTYPE 		= @psPropertyType 	OR C.PROPERTYTYPE 	IS NULL ) 
	AND (	C.COUNTRYCODE 		= @psCountryCode	OR C.COUNTRYCODE 	IS NULL ) 
	AND (	C.CASECATEGORY 		= @psCaseCategory 	OR C.CASECATEGORY 	IS NULL ) 
	AND (	C.SUBTYPE 		= @psSubType		OR C.SUBTYPE 		IS NULL ) 
	AND (	C.BASIS 		= @psBasis		OR C.BASIS 		IS NULL ) 
	AND (	C.DATEOFACT 	       <= @pdtDateOfAct         OR C.DATEOFACT IS NULL )

	Return @nCriteriaNo
End
go

grant execute on dbo.fn_GetCriteriaNoForLawImportBlocking to public
GO