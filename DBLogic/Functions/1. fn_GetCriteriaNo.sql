-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCriteriaNo
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCriteriaNo') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetCriteriaNo.'
	drop function dbo.fn_GetCriteriaNo
	print '**** Creating function dbo.fn_GetCriteriaNo...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_GetCriteriaNo
			(
			@pnCaseID	int,
			@psPurposeCode	nchar(1),
			@psGenericParm	nvarchar(8),
			@pdtToday	datetime,	-- Required when @psPurposeCode='E'
							-- This is required because a userdefined function 
							-- may not use GETDATE()
			@pnProfileKey   int             -- The profile key associated with the user
			)
Returns int

-- FUNCTION :	fn_GetCriteriaNo
-- VERSION :	17
-- DESCRIPTION:	This function returns the CRITERIANO for a Case when it is given 
--		a specific Purpose Code and an additional generic key component required 
--		by some criteria.  Events & Entries also requires the current system date.
--		PurposeCode	Generic Parameter	Type of Control
--		===========     =================	===============
--		    A		None			CPA Renewal Type
--		    C		ChecklistType		Checklist
--		    D		None			USPTO/PAIR
--		    E		Action			Events & Entries
--		    F		RateNo			Fees & Charges
--		    L		None			Case Links
--		    P		None			Copy Profile
--		    R		None			IRN Generation
--		    S		Programid		Screen Control
--		    U		Rule Type		Update Rules
--		    W		ProgramId		Workbench Windows
--		    X		Action			Import Law Blocking
 
-- MODIFICATION
-- Date		Who	No.	Version	Description
-- ====         ===	=== 	=======	===========
-- 11/07/2002	MF			Function created
-- 06/12/2002	JB		4	@pnCaseID changed to @pnCaseID
-- 12/08/2003	TM		5	RFC224 Office level rules. Include Cases.OfficeId as the most 
--					important criteria in all the best fit calculations except for
--					CPA Renewal Rules (@psPurposeCode = 'A').
-- 05 Aug 2004	MF	10336	6	The USERDEFINEDRULE should be the lowest test in the hierarchy for
--					Event & Entries.  Is was coming before the DateOfAct.
-- 22 Sep 2004	MF	10301	7	Include the Basis in the best fit for IRN Generation.
-- 23 May 2005	MF	11403	8	LocalClientFlag was not being considered for best fit on Fees & Charges.
-- 03 Jan 2006	TM	RFC3361	9	Only criteria rows with known properties should be selected for 
--					the CASE SCREEN CONTROL
-- 03 Oct 2006	MF	12413	10	Allow substitution of an alternate CASETYPE if not match is found
--					for the CaseType of the Case.  The alternate CaseType is the 
--					ACTUALCASETYPE from the CASETYPE table.
-- 18 Dec 2006	MF	12298	11	New Update Rules criteria to be catered for.
-- 08 Aug 2008	MF	RFC6921	12	New PurposeCode for Workbench Case Windows.
-- 17 Feb 2009	MF	17399	13	Criteria for IRN Generation (PurposeCode='R') to include Subtype.
-- 21 Sep 2009  LP      RFC8047 14      Added new ProfileKey parameter, used for PurposeCode='W'
-- 25 Nov 2010	MF	18285	15	When determining the Date of Law to use then match on EventNo specified against
--					the VALIDACTDATES table in preference to the EventNo specified against the ACTIONS table.
--					This resolved a problem for an AU Trademark where Filing=1952 & Registration=1966.
-- 01 Jul 2013	MF	R13596	16	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 07 Jul 2016	MF	63861	17	A null LOCALCLIENTFLAG should default to 0.
as
Begin
	declare @nCriteriaNo	int
	declare @dtDateOfLaw	datetime
	
	-------------------------------------------------------------
	-- We need to get the date of the law to use so this can
	-- be used as a parameter for finding the best CriteriaNo.
	-- for PurposeCode 'E' (Events/Entries) or 'X' (Import Block)
	-------------------------------------------------------------
	If @psPurposeCode in ('E', 'X')
	begin
		SELECT 
		@dtDateOfLaw=
		substring(max(
		CASE WHEN(A.COUNTRYCODE='ZZZ') THEN  '0' ELSE '9' END+
		CASE WHEN (D.RETROSPECTIVEACTIO is NULL)
		     THEN CASE 	WHEN (E.EVENTNO=D.ACTEVENTNO) 	THEN '9'
		               	WHEN (E.EVENTNO=A.ACTEVENTNO) 	THEN '8'
	        	       	WHEN (E.EVENTNO=-13)          	THEN '5'
	                 					ELSE '0'
	        	  END 
	 	     ELSE CASE	WHEN (E.EVENTNO=D.RETROEVENTNO)	THEN '9'
				WHEN (E.EVENTNO=A.RETROEVENTNO)	THEN '8'
				WHEN (E.EVENTNO=D.ACTEVENTNO)  	THEN '7'
				WHEN (E.EVENTNO=A.ACTEVENTNO)  	THEN '6'
								ELSE '5'
			  END 
		END +
		convert(nvarchar,DATEOFACT,112)), 3,8)
		FROM CASES C
		join VALIDACTION A	on ((A.COUNTRYCODE = C.COUNTRYCODE OR A.COUNTRYCODE = 'ZZZ' )  
					AND  A.PROPERTYTYPE= C.PROPERTYTYPE
					AND  A.CASETYPE    = C.CASETYPE
					AND  A.ACTION      = @psGenericParm)
		join VALIDACTDATES D	on ( D.COUNTRYCODE	  = C.COUNTRYCODE
					and  D.PROPERTYTYPE	  = C.PROPERTYTYPE
					and (D.RETROSPECTIVEACTIO = A.ACTION OR D.RETROSPECTIVEACTIO IS NULL ))
		join CASEEVENT E	on ( E.CASEID = C.CASEID							
					and  E.EVENTNO in (A.ACTEVENTNO, A.RETROEVENTNO, D.ACTEVENTNO, D.RETROEVENTNO, -13))
		WHERE   C.CASEID=@pnCaseID
		AND	D.DATEOFACT <= E.EVENTDATE
	End		
	
	-- CPA RENEWAL TYPE
	If @psPurposeCode = 'A'
	begin
		SELECT 
		@nCriteriaNo   =
		convert(int,
		substring(
		max (
		CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
		CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.TABLECODE is NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.USERDEFINEDRULE is NULL
			OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
		convert(varchar,C.CRITERIANO)), 7,20))
		FROM CRITERIA C 
		     join CASES CS	on (CS.CASEID=@pnCaseID)
		left join PROPERTY P	on ( P.CASEID=CS.CASEID)
		WHERE	C.RULEINUSE		= 1  	
		AND	C.PURPOSECODE		= 'A' 
		AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
		AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
		AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL )
		AND (	C.TABLECODE 		= P.RENEWALTYPE         OR C.TABLECODE IS NULL )
	end

	-- CHECKLISTS
	Else If @psPurposeCode = 'C'
	begin
		SELECT 
		@nCriteriaNo   =
		convert(int,
		substring(
		max (
		CASE WHEN (C.CASEOFFICEID IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
			ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
		END +  
		CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
		CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.BASIS IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.REGISTEREDUSERS IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.USERDEFINEDRULE is NULL
			OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
		convert(varchar,C.CRITERIANO)), 11,20))
		FROM CRITERIA C 
		     join CASES CS	on (CS.CASEID=@pnCaseID)
		     join CASETYPE CT	on (CT.CASETYPE=CS.CASETYPE)
		left join PROPERTY P	on (P.CASEID=CS.CASEID)
		WHERE	C.RULEINUSE		= 1  	
		AND	C.PURPOSECODE		= 'C' 
		AND 	C.CHECKLISTTYPE		= convert(int,@psGenericParm)
		AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
		AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
		AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
		AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
		AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
		AND (	C.BASIS 		= P.BASIS 		OR C.BASIS 		IS NULL ) 	
		AND (	C.REGISTEREDUSERS 	= P.REGISTEREDUSERS	OR C.REGISTEREDUSERS	IS NULL )
		AND (	C.LOCALCLIENTFLAG 	= isnull(CS.LOCALCLIENTFLAG,0)
								 	OR C.LOCALCLIENTFLAG	IS NULL ) 
	end

	-- EVENTS & ENTRIES
	Else If @psPurposeCode = 'E'
	begin
		SELECT 
		@nCriteriaNo   =
		convert(int,
		substring(
		max (
		CASE WHEN (C.CASEOFFICEID IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
			ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
		END +  
		CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
		CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.BASIS IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.TABLECODE is NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.DATEOFACT IS NULL)		THEN '0' ELSE '1' END +
		isnull(convert(varchar, DATEOFACT, 112),'00000000') +
		CASE WHEN (C.USERDEFINEDRULE is NULL
			OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
		convert(varchar,C.CRITERIANO)), 20,20))
		FROM CRITERIA C 
		     join CASES CS	on (CS.CASEID=@pnCaseID)
		     join CASETYPE CT	on (CT.CASETYPE=CS.CASETYPE)
		left join PROPERTY P	on (P.CASEID=CS.CASEID)
		WHERE	C.RULEINUSE		= 1  	
		AND	C.PURPOSECODE		= 'E'
		AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
		AND 	C.ACTION		= @psGenericParm
		AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
		AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
		AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
		AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
		AND (	C.BASIS 		= P.BASIS 		OR C.BASIS 		IS NULL ) 	
		AND (	C.REGISTEREDUSERS 	= P.REGISTEREDUSERS	OR C.REGISTEREDUSERS	IS NULL )
		AND (	C.LOCALCLIENTFLAG 	= isnull(CS.LOCALCLIENTFLAG,0)   OR C.LOCALCLIENTFLAG IS NULL ) 
		AND (	C.DATEOFACT 	       <= isnull(@dtDateOfLaw,@pdtToday) OR C.DATEOFACT IS NULL )
		AND (	C.TABLECODE 		= P.EXAMTYPE 		OR C.TABLECODE = P.RENEWALTYPE OR C.TABLECODE IS NULL )
	end

	-- FEES & CHARGES
	Else If @psPurposeCode = 'F'
	begin
		SELECT 
		@nCriteriaNo   =
		convert(int,
		substring(
		max (
		CASE WHEN (C.CASEOFFICEID IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
			ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
		END +  
		CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
		CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.TYPEOFMARK      IS NULL)   THEN '0' ELSE '1' END +
		CASE WHEN (C.TABLECODE	    IS NULL)    THEN '0' ELSE '1' END +
		CASE WHEN (C.USERDEFINEDRULE is NULL
			OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
		convert(varchar,C.CRITERIANO)), 11,20))
		FROM CRITERIA C 
		     join CASES CS on (CS.CASEID=@pnCaseID)
		     join CASETYPE CT	on (CT.CASETYPE=CS.CASETYPE)
		WHERE	C.RULEINUSE		= 1  	
		AND	C.PURPOSECODE		= 'F' 
		AND 	C.RATENO		= convert(int,@psGenericParm)
		AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
		AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
		AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
		AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
		AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
		AND (	C.TYPEOFMARK 		= CS.TYPEOFMARK		OR C.TYPEOFMARK		IS NULL ) 	
		AND (	C.TABLECODE	 	= CS.ENTITYSIZE		OR C.TABLECODE		IS NULL )
		AND (	C.LOCALCLIENTFLAG 	= isnull(CS.LOCALCLIENTFLAG,0)
								 	OR C.LOCALCLIENTFLAG	IS NULL ) 
	end

	-- INTERNAL REFERENCE FORMAT
	Else If @psPurposeCode = 'R'
	begin
		SELECT 
		@nCriteriaNo   =
		convert(int,
		substring(
		max (
		CASE WHEN (C.CASEOFFICEID IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
			ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
		END +  
		CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
		CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.BASIS IS NULL)		THEN '0' ELSE '1' END +
		convert(varchar,C.CRITERIANO)), 8,20))
		FROM CRITERIA C 
		     join CASES CS   on (CS.CASEID=@pnCaseID)
		     join CASETYPE CT	on (CT.CASETYPE=CS.CASETYPE)
		left join PROPERTY P on (P.CASEID=CS.CASEID)
		WHERE	C.RULEINUSE		= 1  	
		AND	C.PURPOSECODE		= 'R'
		AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
		AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
		AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
		AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL )
		AND (	C.SUBTYPE 		= CS.SUBTYPE	 	OR C.SUBTYPE	 	IS NULL ) 
		AND (	C.BASIS 		= P.BASIS	 	OR C.BASIS	 	IS NULL ) 
	end

	-- CASE SCREEN CONTROL
	Else If @psPurposeCode in ('S','W')
	begin
		SELECT 
		@nCriteriaNo   =
		convert(int,
		substring(
		max (
		CASE WHEN (C.PROFILEID IS NULL)	        THEN '0' ELSE '1' END +
		CASE WHEN (C.CASEOFFICEID IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
			ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
		END +  
		CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
		CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.BASIS   IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.USERDEFINEDRULE is NULL
			OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
		convert(varchar,C.CRITERIANO)), 10,20))
		FROM CRITERIA C 
		     join CASES CS    on (CS.CASEID=@pnCaseID)
		     join CASETYPE CT on (CT.CASETYPE=CS.CASETYPE)
		left join PROPERTY P  on ( P.CASEID=CS.CASEID)
		WHERE	C.RULEINUSE		= 1  	
		AND	C.PURPOSECODE		= @psPurposeCode
		AND 	C.PROGRAMID		= @psGenericParm
		AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
		AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
		AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
		AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
		AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
		AND (	C.BASIS 		= P.BASIS 		OR C.BASIS 		IS NULL ) 	
		-- Since this function is called for an existing case, all criteria are known
		AND (	C.PROPERTYUNKNOWN	= 0 			OR C.PROPERTYUNKNOWN 	IS NULL )
		AND (	C.COUNTRYUNKNOWN	= 0 			OR C.COUNTRYUNKNOWN 	IS NULL )
		AND (	C.CATEGORYUNKNOWN	= 0 			OR C.CATEGORYUNKNOWN 	IS NULL )
		AND (	C.SUBTYPEUNKNOWN	= 0 			OR C.SUBTYPEUNKNOWN 	IS NULL )
		AND (   C.PROFILEID             = @pnProfileKey         OR C.PROFILEID          IS NULL )
	end

	-- UPDATE Rules
	Else If @psPurposeCode = 'U'
	begin
		SELECT 
		@nCriteriaNo   =
		convert(int,
		substring(
		max (
		CASE WHEN (C.CASEOFFICEID IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.REQUESTTYPE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.DATASOURCETYPE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.DATASOURCENAMENO IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
			ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
		END +  
		CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
		CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
		CASE WHEN (C.RENEWALSTATUS IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.STATUSCODE IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (C.USERDEFINEDRULE is NULL
			OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
		convert(varchar,C.CRITERIANO)), 13,20))
		FROM CRITERIA C 
		     join CASES CS    on (CS.CASEID=@pnCaseID)
		     join CASETYPE CT on (CT.CASETYPE=CS.CASETYPE)
		left join PROPERTY P  on ( P.CASEID=CS.CASEID)
		left join EDECASEMATCH CM	on (CM.DRAFTCASEID=CS.CASEID)
		left join EDESENDERDETAILS SD	on (SD.BATCHNO=CM.BATCHNO)		
		left join EDEREQUESTTYPE RT 	on (RT.REQUESTTYPECODE=SD.SENDERREQUESTTYPE )		
		left join CASENAME CN1		on (CN1.CASEID=CS.CASEID 
						and CN1.NAMETYPE = 'I'
						and CN1.EXPIRYDATE is null)
		left join CASENAME CN2		on (CN2.CASEID=CS.CASEID 
						and CN2.NAMETYPE = RT.REQUESTORNAMETYPE
						and CN2.EXPIRYDATE is null)
		WHERE	C.RULEINUSE		= 1  	
		AND	C.PURPOSECODE		= 'U' 
		AND	C.RULETYPE		= convert(int,@psGenericParm)
		AND (	C.CASEOFFICEID 		= CS.OFFICEID 		OR C.CASEOFFICEID 	IS NULL )
		AND (	C.REQUESTTYPE 		= SD.SENDERREQUESTTYPE 	OR C.REQUESTTYPE 	IS NULL )
		AND (	C.DATASOURCETYPE	= CASE WHEN(SD.SENDERREQUESTTYPE ='Data Verfication')
								THEN 10302
						       WHEN(CN1.NAMENO=CN2.NAMENO OR CN2.NAMENO is null) 
								THEN 10300
						                ELSE 10301
						  END 	
						                        OR C.DATASOURCETYPE 	IS NULL )
		AND (	C.DATASOURCENAMENO	= SD.SENDERNAMENO	OR C.DATASOURCENAMENO 	IS NULL )
		AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
		AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
		AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
		AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
		AND (	C.RENEWALSTATUS		= P.RENEWALSTATUS	OR C.RENEWALSTATUS	IS NULL ) 
		AND (	C.STATUSCODE		= CS.STATUSCODE		OR C.STATUSCODE		IS NULL )
	end

	-- Law Update Blocking
	Else If @psPurposeCode = 'X'
	begin
		SELECT 
		@nCriteriaNo   =
		convert(int,
		substring(
		max (
		CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
			ELSE CASE WHEN(C.CASETYPE=CS.CASETYPE) 	 THEN '2' ELSE '1' END 
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
		     join CASES CS	on (CS.CASEID=@pnCaseID)
		     join CASETYPE CT	on (CT.CASETYPE=CS.CASETYPE)
		left join PROPERTY P	on (P.CASEID=CS.CASEID)
		WHERE	C.PURPOSECODE		= 'X'
		AND (	C.CASETYPE	      in (CS.CASETYPE,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
		AND 	C.ACTION		= @psGenericParm
		AND (	C.PROPERTYTYPE 		= CS.PROPERTYTYPE 	OR C.PROPERTYTYPE 	IS NULL ) 
		AND (	C.COUNTRYCODE 		= CS.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.CASECATEGORY 		= CS.CASECATEGORY 	OR C.CASECATEGORY 	IS NULL ) 
		AND (	C.SUBTYPE 		= CS.SUBTYPE 		OR C.SUBTYPE 		IS NULL ) 
		AND (	C.BASIS 		= P.BASIS 		OR C.BASIS 		IS NULL )
		AND (	C.DATEOFACT 	       <= isnull(@dtDateOfLaw,@pdtToday) OR C.DATEOFACT IS NULL )	
	end

	Return @nCriteriaNo
End
go

grant execute on dbo.fn_GetCriteriaNo to public
GO