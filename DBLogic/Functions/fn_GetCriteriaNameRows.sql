-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCriteriaNameRows
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCriteriaNameRows') and xtype='TF')
begin
	print '**** Drop function dbo.fn_GetCriteriaNameRows.'
	drop function dbo.fn_GetCriteriaNameRows
end
print '**** Creating function dbo.fn_GetCriteriaNameRows...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_GetCriteriaNameRows
			(
			@psPurposeCode		nchar(1),
			@psProgramID		nvarchar(8),
			@pnNameNo		int,
			@pnUsedAsFlag		smallint,
			@pbSupplierFlag		bit,
			@psCountryCode		nvarchar(3),
			@pbLocalClientFlag	bit,
			@pnCategory		int,
			@psNameType		nvarchar(3),
			@psRelationship		nvarchar(3),
			@pbRuleInUse		bit,
			@pbDataUnknown		bit,
			@pbExactMatch		bit,
			@pnProfileKey		int
			)

Returns @tbCriteria TABLE
   (      
	NAMECRITERIANO		int		NOT NULL,
	PURPOSECODE		nchar(1)	collate database_default NOT NULL,
	PROGRAMID		nvarchar(8)	collate database_default NULL,
	USEDASFLAG		smallint	NULL,
	SUPPLIERFLAG		decimal(1,0)	NULL,
	DATAUNKNOWN		bit		NOT NULL,
	COUNTRYCODE		nvarchar(3)	collate database_default NULL,
	LOCALCLIENTFLAG		bit		NULL,
	CATEGORY		int		NULL,
	NAMETYPE		nvarchar(3)	collate database_default NULL,
	RELATIONSHIP		nvarchar(3)	collate database_default NULL,
	USERDEFINEDRULE		bit		NOT NULL,
	RULEINUSE		bit		NOT NULL,
	PARENTCRITERIA          int             NULL,
	DESCRIPTION		nvarchar(254)	collate database_default NULL,
	DESCRIPTION_TID		int		NULL,
	BESTFIT			nvarchar(20)	collate database_default NULL,
	PROFILEID		int		NULL
   )

as
-- FUNCTION :	fn_GetCriteriaNameRows
-- VERSION  :	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This function returns NAMECRITERIA row details that match either exactly the 
--		non NULL input parameters or match based on the Best Fit search algorithm.
--		If an exact match is not required then the Best Fit search will determine
--		a BESTFIT value that indicates how well each returned row matches.
--		PurposeCode	Type of Control
--		===========     ===============
--		    W		Workbench Windows
 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Aug 2008	MF	RFC6546	1	Function created
-- 25 Jun 2009	MF	RFC8199	2	Remove NameTypeCriteria table.
-- 06 Jul 2009	MS	RFC7085 3	Added Relationship and NameType columns in result
-- 27 Aug 2009  LP	RFC7580 4	Added ParentCriteria to result set.
-- 09 Sep 2009	LP	RFC8047	5	Added ProfileKey to parameters and result set.
-- 23 Sep 2009	MF	RFC8472 6	Correct the Description of this function.
-- 07 Jul 2016	MF	63861	7	A null LOCALCLIENTFLAG should default to 0.


Begin
	If @pbLocalClientFlag is null
	and ISNULL(@pbExactMatch,0)=0
		set @pbLocalClientFlag=0
		
	If @pbExactMatch=1
	begin
		If @pnNameNo is null
		Begin
			Insert into @tbCriteria(
				NAMECRITERIANO, PURPOSECODE, PROGRAMID, USEDASFLAG, SUPPLIERFLAG, DATAUNKNOWN, COUNTRYCODE,
				LOCALCLIENTFLAG, CATEGORY, NAMETYPE, RELATIONSHIP, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DESCRIPTION_TID,
				PARENTCRITERIA, PROFILEID)
			SELECT	C.NAMECRITERIANO, C.PURPOSECODE, C.PROGRAMID, C.USEDASFLAG, C.SUPPLIERFLAG, C.DATAUNKNOWN, C.COUNTRYCODE,
				C.LOCALCLIENTFLAG, C.CATEGORY, C.NAMETYPE, C.RELATIONSHIP, C.USERDEFINEDRULE, C.RULEINUSE, C.DESCRIPTION, C.DESCRIPTION_TID,
				NI.FROMNAMECRITERIANO, C.PROFILEID
			FROM NAMECRITERIA C
			left join NAMECRITERIAINHERITS NI on (NI.NAMECRITERIANO = C.NAMECRITERIANO)
			WHERE 	(C.PURPOSECODE     =@psPurposeCode)
			and	(C.PROGRAMID	   =@psProgramID	OR @psProgramID        is null)
			and	(C.USEDASFLAG	   =@pnUsedAsFlag	OR @pnUsedAsFlag       is null	OR C.USEDASFLAG&1 = @pnUsedAsFlag)
			and	(C.SUPPLIERFLAG    =@pbSupplierFlag	OR @pbSupplierFlag     is null)
			and	(C.COUNTRYCODE	   =@psCountryCode	OR @psCountryCode      is null)
			and	(C.LOCALCLIENTFLAG =@pbLocalClientFlag	OR @pbLocalClientFlag  is null)
			and	(C.CATEGORY        =@pnCategory 	OR @pnCategory         is null)
			and	(C.RULEINUSE       =@pbRuleInUse	OR @pbRuleInUse        is null)
			and	(C.DATAUNKNOWN	   =@pbDataUnknown	OR @pbDataUnknown      is null)
			and	(C.NAMETYPE	   =@psNameType		OR @psNameType	       is null)
			and	(C.RELATIONSHIP    =@psRelationship     OR @psRelationship     is null)
			and	(C.PROFILEID       = @pnProfileKey	OR @pnProfileKey       is null)
		End
		Else Begin
			Insert into @tbCriteria(
				NAMECRITERIANO, PURPOSECODE, PROGRAMID, USEDASFLAG, SUPPLIERFLAG, DATAUNKNOWN, COUNTRYCODE,
				LOCALCLIENTFLAG, CATEGORY, NAMETYPE, RELATIONSHIP, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DESCRIPTION_TID,
				PARENTCRITERIA, PROFILEID)
			SELECT	C.NAMECRITERIANO, C.PURPOSECODE, C.PROGRAMID, C.USEDASFLAG, C.SUPPLIERFLAG, C.DATAUNKNOWN, C.COUNTRYCODE,
				C.LOCALCLIENTFLAG, C.CATEGORY, C.NAMETYPE, C.RELATIONSHIP, C.USERDEFINEDRULE, C.RULEINUSE, C.DESCRIPTION, C.DESCRIPTION_TID,
				NI.FROMNAMECRITERIANO, C.PROFILEID
			FROM NAME N
			join NAMECRITERIA C	on (C.PURPOSECODE=@psPurposeCode)
			left join NAMECRITERIAINHERITS NI on (NI.NAMECRITERIANO = C.NAMECRITERIANO)
			left join ADDRESS A		on (A.ADDRESSCODE=N.POSTALADDRESS)
			left join IPNAME I		on (I.NAMENO=N.NAMENO)
			left join (Select distinct RELATEDNAME, RELATIONSHIP from ASSOCIATEDNAME where RELATIONSHIP = 'EMP')AN 
					on (AN.RELATEDNAME = N.NAMENO)		
				-- Get the most relevant NAMETYPE allowed for the Name
				-- by applying a hardcode hierachy
			left join (select CL.NAMENO,
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
			WHERE 	N.NAMENO         =@pnNameNo
			and    (C.PROGRAMID      =@psProgramID			  OR @psProgramID      is null)
			and    (C.USEDASFLAG     =N.USEDASFLAG			  OR N.USEDASFLAG      is null	OR C.USEDASFLAG&1 = N.USEDASFLAG)
			and    (C.SUPPLIERFLAG   =N.SUPPLIERFLAG		  OR N.SUPPLIERFLAG    is null)
			and    (C.COUNTRYCODE    =A.COUNTRYCODE                   OR A.COUNTRYCODE     is null)
			and    (C.LOCALCLIENTFLAG=I.LOCALCLIENTFLAG               OR I.LOCALCLIENTFLAG is null)
			and    (C.CATEGORY       =I.CATEGORY			  OR I.CATEGORY        is null)
			and    (C.NAMETYPE 	 = substring(NC.BESTNAMETYPE,3,3) OR NC.BESTNAMETYPE   is null) 
			and    (C.RULEINUSE      =@pbRuleInUse			  OR @pbRuleInUse      is null)
			and    (C.RELATIONSHIP   =AN.RELATIONSHIP		  OR AN.RELATIONSHIP   is null)
			and    (C.PROFILEID	 =@pnProfileKey			  OR @pnProfileKey     is null)			
		End
	End
	-- CASE SCREEN CONTROL with no specific NameNo
	Else If @psPurposeCode = 'W'
	     and @pnNameNo is null
	begin
		Insert into @tbCriteria(
			NAMECRITERIANO, PURPOSECODE, PROGRAMID, USEDASFLAG, SUPPLIERFLAG, DATAUNKNOWN, COUNTRYCODE,
			LOCALCLIENTFLAG, CATEGORY, NAMETYPE, RELATIONSHIP, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DESCRIPTION_TID, PARENTCRITERIA, PROFILEID,
			BESTFIT)
		SELECT	C.NAMECRITERIANO, C.PURPOSECODE, C.PROGRAMID, C.USEDASFLAG, C.SUPPLIERFLAG, C.DATAUNKNOWN, C.COUNTRYCODE,
			C.LOCALCLIENTFLAG, C.CATEGORY, C.NAMETYPE, C.RELATIONSHIP, C.USERDEFINEDRULE, C.RULEINUSE, C.DESCRIPTION, C.DESCRIPTION_TID,
			NI.FROMNAMECRITERIANO, C.PROFILEID,		
			CASE WHEN (C.PROFILEID IS NULL)	THEN '0' ELSE '1' END +    
			CASE WHEN (C.USEDASFLAG IS NULL)	THEN '0' ELSE '1' END +    	
			CASE WHEN (C.SUPPLIERFLAG IS NULL)	THEN '0' ELSE '1' END +		
			CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.CATEGORY IS NULL)		THEN '0' ELSE '1' END +
			CASE WHEN (C.NAMETYPE IS NULL)		THEN '0' ELSE '1' END +
			CASE WHEN (C.RELATIONSHIP IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.USERDEFINEDRULE is NULL
				OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END
		FROM NAMECRITERIA C
		left join NAMECRITERIAINHERITS NI on (NI.NAMECRITERIANO = C.NAMECRITERIANO) 
		WHERE	C.RULEINUSE		= 1  	
		AND	C.PURPOSECODE		= @psPurposeCode
		AND 	C.PROGRAMID		= @psProgramID
		AND (	C.USEDASFLAG 		= @pnUsedAsFlag		OR C.USEDASFLAG 	IS NULL ) 
		AND (	C.SUPPLIERFLAG		= @pbSupplierFlag	OR C.SUPPLIERFLAG	IS NULL )
		AND (	C.COUNTRYCODE 		= @psCountryCode 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.LOCALCLIENTFLAG	= @pbLocalClientFlag 	OR C.LOCALCLIENTFLAG 	IS NULL ) 
		AND (	C.CATEGORY 		= @pnCategory 		OR C.CATEGORY 		IS NULL ) 
		AND (	C.NAMETYPE		= @psNameType		OR C.NAMETYPE		IS NULL )
		AND (	C.DATAUNKNOWN		= isnull(@pbDataUnknown,0) OR C.DATAUNKNOWN	IS NULL )
		AND (	C.RELATIONSHIP		= @psRelationship	OR C.RELATIONSHIP	IS NULL )
		AND (	C.PROFILEID		= @pnProfileKey         OR C.PROFILEID          IS NULL )
	End
	-- CASE SCREEN CONTROL with specific NameNo
	Else If @psPurposeCode = 'W'
	     and @pnNameNo is not null
	begin
		Insert into @tbCriteria(
			NAMECRITERIANO, PURPOSECODE, PROGRAMID, USEDASFLAG, SUPPLIERFLAG, DATAUNKNOWN, COUNTRYCODE,
			LOCALCLIENTFLAG, CATEGORY, NAMETYPE, RELATIONSHIP, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DESCRIPTION_TID, PARENTCRITERIA, PROFILEID,
			BESTFIT)
		SELECT	C.NAMECRITERIANO, C.PURPOSECODE, C.PROGRAMID, C.USEDASFLAG, C.SUPPLIERFLAG, C.DATAUNKNOWN, C.COUNTRYCODE,
			C.LOCALCLIENTFLAG, C.CATEGORY, C.NAMETYPE, C.RELATIONSHIP, C.USERDEFINEDRULE, C.RULEINUSE, C.DESCRIPTION, C.DESCRIPTION_TID,
			NI.FROMNAMECRITERIANO,C.PROFILEID,			
			CASE WHEN (C.PROFILEID IS NULL)	THEN '0' ELSE '1' END + 
			CASE WHEN (C.USEDASFLAG IS NULL)	THEN '0' ELSE '1' END +    	
			CASE WHEN (C.SUPPLIERFLAG IS NULL)	THEN '0' ELSE '1' END +		
			CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.CATEGORY IS NULL)		THEN '0' ELSE '1' END +
			CASE WHEN (C.NAMETYPE IS NULL)		THEN '0' ELSE '1' END +
			CASE WHEN (C.RELATIONSHIP IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.USERDEFINEDRULE is NULL
				OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END
		FROM NAMECRITERIA C
		join NAME N    on (N.NAMENO=@pnNameNo)
		left join ADDRESS A on (A.ADDRESSCODE=N.POSTALADDRESS)
		left join IPNAME I  on (I.NAMENO=N.NAMENO)
		left join (Select distinct RELATEDNAME, RELATIONSHIP from ASSOCIATEDNAME where RELATIONSHIP = 'EMP')AN 
					on (AN.RELATEDNAME = N.NAMENO)
				-- Get the most relevant NAMETYPE allowed for the Name
				-- by applying a hardcode hierachy
		left join (select CL.NAMENO,
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
		left join NAMECRITERIAINHERITS NI on (NI.NAMECRITERIANO = C.NAMECRITERIANO) 
		WHERE	C.RULEINUSE		= 1
		AND	C.PURPOSECODE		= 'W'
		AND 	C.PROGRAMID		= @psProgramID
		AND (	C.USEDASFLAG 		= N.USEDASFLAG 		OR C.USEDASFLAG 	IS NULL ) 
		AND (	C.SUPPLIERFLAG		= N.SUPPLIERFLAG	OR C.SUPPLIERFLAG	IS NULL )
		AND (	C.COUNTRYCODE 		= A.COUNTRYCODE 	OR C.COUNTRYCODE 	IS NULL ) 
		AND (	C.LOCALCLIENTFLAG	= I.LOCALCLIENTFLAG 	OR C.LOCALCLIENTFLAG 	IS NULL ) 
		AND (	C.CATEGORY 		= I.CATEGORY 		OR C.CATEGORY 		IS NULL ) 
		AND (	C.NAMETYPE 		= substring(NC.BESTNAMETYPE,3,3)	
									OR C.NAMETYPE 		IS NULL ) 	
		-- Since this function is called for an existing Name, all criteria are known
		AND (	C.DATAUNKNOWN		= 0 			OR C.DATAUNKNOWN 	IS NULL )
		AND (	C.RELATIONSHIP		= AN.RELATIONSHIP	OR C.RELATIONSHIP	IS NULL )
		AND (	C.PROFILEID		= @pnProfileKey		OR C.PROFILEID		IS NULL)
	End
	
	Return
End
go

grant REFERENCES, SELECT on dbo.fn_GetCriteriaNameRows to public
GO
