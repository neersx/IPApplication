-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCriteriaNoForName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCriteriaNoForName') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetCriteriaNoForName.'
	drop function dbo.fn_GetCriteriaNoForName
	print '**** Creating function dbo.fn_GetCriteriaNoForName...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_GetCriteriaNoForName
			(
			@pnNameNo	int,
			@psPurposeCode	nchar(1),
			@psGenericParm	nvarchar(8),
			@pnProfileKey   int
			)
Returns int

-- FUNCTION :	fn_GetCriteriaNoForName
-- VERSION :	7
-- DESCRIPTION:	This function returns the CRITERIANO for a Name when it is given 
--		a specific Purpose Code and an additional generic key component required 
--		by some criteria.
--		PurposeCode	Generic Parameter	Type of Control
--		===========     =================	===============
--		    W		ProgramId		Workbench Windows
 
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 Aug 2008	MF	RFC6546	1	Function created
-- 25 Jun 2009	MF	RFC8199	2	Remove NameTypeCriteria table.
-- 06 Jul 2009	KR	RFC6546	3	Added Relationship column. 
-- 21 Sep 2009  LP      RFC8047 4       Add ProfileKey parameter.
-- 09 Oct 2009	AT	100080	5	Fix name relationship matching to check reverse relations
-- 12 Oct 2009	AT	200080	6	Change best fit to get DATAUNKNOWN=1 as default criteria when nothing matches
-- 07 Jul 2016	MF	63861	7	A null LOCALCLIENTFLAG should default to 0.
--
as
Begin
	declare @nCriteriaNo	int
	
	-- NAME SCREEN CONTROL
	If @psPurposeCode='W'
	begin
		SELECT 
		top 1 @nCriteriaNo   =
		convert(int,
		substring(
		max (
		CASE WHEN (C.PROFILEID IS NULL)	        THEN '0' ELSE '1' END +  
		CASE WHEN (C.USEDASFLAG IS NULL)	THEN '0' ELSE '1' END +    	
		CASE WHEN (C.SUPPLIERFLAG IS NULL)	THEN '0' ELSE '1' END +		
		CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CATEGORY IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.NAMETYPE IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.USERDEFINEDRULE is NULL
			OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
		CASE WHEN (C.RELATIONSHIP IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN C.DATAUNKNOWN = 0 THEN '0' ELSE '1' END +
		convert(varchar,C.NAMECRITERIANO)),11,11))
		FROM NAMECRITERIA C 
		     join NAME N    on (N.NAMENO=@pnNameNo)
		left join ADDRESS A on (A.ADDRESSCODE=N.POSTALADDRESS)
		left join IPNAME I  on (I.NAMENO=N.NAMENO)
		left join (Select distinct NAMENO, RELATEDNAME, RELATIONSHIP from ASSOCIATEDNAME where RELATIONSHIP = 'EMP') AN 
					on (AN.RELATEDNAME = N.NAMENO 
						or AN.NAMENO = N.NAMENO)
				-- Get the most relevant NAMETYPE allowed for the Name
				-- by applying a hardcode hierachy
		left join (	select CL.NAMENO,
				       min(CASE WHEN(NT.PICKLISTFLAGS&4=4)	-- Name types used as clients
						 THEN CASE(NT.NAMETYPE)
							WHEN('I')	THEN '00'
							WHEN('R')	THEN '01'
							WHEN('A')	THEN '02'
							WHEN('&')	THEN '03'
							WHEN('D')	THEN '04'
							WHEN('Z')	THEN '05'
									ELSE '06'
						      END
						WHEN(NT.PICKLISTFLAGS&2=2)	-- Name types used as staff
						 THEN CASE(NT.NAMETYPE)
							WHEN('EMP')	THEN '10'
							WHEN('SIG')	THEN '11'
									ELSE '13'
						      END
						WHEN(PICKLISTFLAGS&32=32)	-- Name types used by CRM
						 THEN CASE(NT.NAMETYPE)
							WHEN('~PR')	THEN '20'
							WHEN('~LD')	THEN '21'
							WHEN('~CN')	THEN '22'
							WHEN('~EP')	THEN '23'
							WHEN('~CM')	THEN '24'
									ELSE '25'
						      END
						 ELSE CASE(NT.NAMETYPE)
							WHEN('O')	THEN '30'
							WHEN('J')	THEN '31'
									ELSE '99'
						      END
				           END +
				           NT.NAMETYPE) as BESTNAMETYPE
				from NAMETYPECLASSIFICATION CL
				join NAMETYPE NT on (NT.NAMETYPE=CL.NAMETYPE)
				where CL.NAMENO=@pnNameNo
				and CL.ALLOW=1
				group by CL.NAMENO) NC on (NC.NAMENO=N.NAMENO)
		WHERE	C.RULEINUSE		= 1
		AND	C.PURPOSECODE		= 'W'
		AND 	C.PROGRAMID		= @psGenericParm
		AND (	C.USEDASFLAG 		= N.USEDASFLAG 		OR C.USEDASFLAG 	IS NULL ) 
		AND (	C.SUPPLIERFLAG		= N.SUPPLIERFLAG	OR C.SUPPLIERFLAG	IS NULL )
		AND (	C.COUNTRYCODE 		= A.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.LOCALCLIENTFLAG	= isnull(I.LOCALCLIENTFLAG,0)
								 	OR C.LOCALCLIENTFLAG 	IS NULL ) 
		AND (	C.CATEGORY 		= I.CATEGORY 		OR C.CATEGORY 		IS NULL ) 
		AND (	C.NAMETYPE 		= substring(NC.BESTNAMETYPE,3,3)	
									OR C.NAMETYPE 		IS NULL ) 	
		-- Since this function is called for an existing Name, all criteria are known
		--AND (	C.DATAUNKNOWN	= 0 				OR C.DATAUNKNOWN 	IS NULL )
		AND (	C.RELATIONSHIP	= AN.RELATIONSHIP	OR C.RELATIONSHIP 	IS NULL )
		AND (	C.PROFILEID	= @pnProfileKey 	OR C.PROFILEID 	                IS NULL )
	end

	Return @nCriteriaNo
End
go

grant execute on dbo.fn_GetCriteriaNoForName to public
GO
