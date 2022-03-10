-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GenerateCaseName
-----------------------------------------------------------------------------------------------------------------------------
if exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GenerateCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_GenerateCaseName.'
	drop procedure [dbo].[cs_GenerateCaseName]
end
print '**** Creating Stored Procedure dbo.cs_GenerateCaseName...'
print ''
go

set quoted_identifier off
go

Create procedure dbo.cs_GenerateCaseName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,		-- Mandatory
	@psProgramKey		nvarchar(8)	= null,
	@pnInsertedRowCount	int		= 0 output,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE :	cs_GenerateCaseName
-- VERSION :	29
-- DESCRIPTION:	This stored procedure default names against the specified Case 
--		according to rules defined in the NameType table.
--		It may result in none, one or more rows being added to the CaseName table.
-- SCOPE:	CPA.net, InPro.net
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 12 Aug 2002	SF		1	Procedure created
-- 28 Oct 2002	SF		2	Changed Parameter @pnCaseId to @pnCaseKey (for standard conformance)
-- 21 Feb 2003	SF		3	RFC09 Retrict nametypes with Screen Control 
-- 18 Aug 2004	AB		4	Add collate database_default syntax to temp tables.
-- 22 Dec 2005	TM	RFC3200	5	Only inherit the Contact when inheriting from a CASENAME.
-- 13 Jan 2006	DR	11871	6	Added @psProgramKey to pass the version of Cases (used by fn_GetScreenControlNameTypes instead of 'default').
--					Added @pbCalledFromCentura parameter and select count of CASENAME records inserted if @pbCalledFromCentura = 1.
--					Include AddressCode in insert to CASENAME if NAMETYPE.KEEPSTREETFLAG = 1.
-- 01 Feb 2006	DR	11871	7	Change so that Contact can inherit from Associated Name.
-- 03 May 2006	DR	8911	8	Add setting of new column CASENAME.DERIVEDCORRNAME.
-- 24 May 2006	MF	12315	9	The insertion of a CaseName may now trigger the update or creation of a 
--					CaseEvent along with its Policing.
-- 24 May 2006	MF	12317	9	A new inheritance option against a NameType can indicate that a Name should
--					inherit from the Associated Name of the Home Name if no associated Name is
--					found against the parent NameType
-- 30 May 2006	MF	12327	9	NameTypes may now be flagged to indicate if changing the parent name entry
--					of an inherited name should result in the inherited name also being reinherited.
--					Note that no change is actually required to this stored procedure because it is 
--					only concerned with determining the inherited child NameType if no entry already
--					exists for the child NameType.
-- 07 Jun 2006	DR	8911	10	Don't set CORRESPONDNAME to ASSOCIATEDNAME.CONTACT for Debtor/Renewal Debtor.
-- 19 Jun 2006	DR	8911	11	Set name to parent case name if path relationship is null.
-- 21 Jul 2006	DR	13092	12	Only default if parent name type exists against the case, or no parent name type and default name defined.
-- 05 Dec 2006	DR	13785	13	Correct usage of NAMETYPE.DEFAULTNAMENO.
-- 08 Jan 2007	DR	13785	14	Set INHERITEDNAMENO for all inherited records, not just when inherited by associated name.
-- 19 Jan 2007	DR	13785	15	Fix setting of INHERITEDNAMENO to point to Home Name when it is used to inherit by associated name.
-- 29 Jan 2007	DR	14023	16	Only set attention if name type flag indicates it is used, except for Instructor and Agent.
-- 26 Apr 2007	JS	14323	17	Pass new parameter NameType to fn_GetDerivedAttnNameNo.
-- 21 Sep 2007	vql	15296	18	Staff Member (EMP) name not copied to Relationship Manager (RM)  name field on the Instructor tab.
-- 11 Dec 2008	MF	17136	19	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 03 Feb 2010	KR	8868	20	Loop date to get unique date to avoid primary key violation for POLICING table.
-- 21 Dec 2010	MF	9969	21	A name that is being inherited for a particular Name Type must be allowed to be used as that NameType. If the
--					NameType is flagged as "Same Name Type" then only those Names that can be used for that Name Type are to be
--					inherited.  
-- 16 Mar 2011	MF	19472	22	Revist of RFC9969. On some databases the introduced code slowed execution down. Move the join into an EXISTS clause.
-- 25 May 2011	vql	19486	23	Renewal instruction reference not being copied when creating new case.
-- 07 Jul 2011	DL	R10830	24	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 07 Aug 2012	DV	R12163	25	If KEEPSTREETFLAG is 1 then street address should be first picked from ASSOCIATEDNAME
-- 07 Sep 2012	DV	R12572	26	Fixed logic to get the REFERENCENO
-- 24 Jun 2015	KR	DR-13176 27	Made the SP call different functions for web and client server to obtain the name types.
-- 23 Sep 2015	MF	53105	28	Consider the CEASEDDATE when determining names to default from.
-- 18 Apr 2016	MF	60222	29	The REFERENCENO for an inherited name should only inherit if the Name being created is the same as the Name from which it is inheriting.

set nocount on
set ansi_warnings off

Declare @nErrorCode 	int
Declare @nRowCount 	int
Declare @nNameSequence 	int
Declare @sNameType	nvarchar(3)
Declare	@dtDateEntered datetime

Declare @tbDefaultNames table (
	CASEID			int		not null,
	NAMETYPE		nvarchar(3) 	collate database_default not null,
	NAMENO			int		not null,
	SEQUENCE		int		not null,
	CORRESPONDNAME		int		null, 
	DERIVEDCORRNAME		decimal(1,0) 	null,	-- 8911
	ADDRESSCODE		int 		null,
	BILLPERCENTAGE		decimal(5,2)	null,
	INHERITED		decimal(1,0)	null,
	INHERITEDNAMENO		int		null,
	INHERITEDRELATIONS	nvarchar(3)	collate database_default null,
	INHERITEDSEQUENCE	smallint	null,
	CHANGEEVENTNO		int		null,	--12315
	REFERENCENO		nvarchar(80)	collate database_default null	--19486	
)

Declare @tbTempPolicing table (
        POLICINGSEQNO		int		identity,
        EVENTNO			int 		not null
 )
declare @tblNameType table (
	NameTypeKey nvarchar(5)
	)

Set @nErrorCode = @@error

If @nErrorCode = 0
begin
	if @pbCalledFromCentura = 1
		insert into @tblNameType
		select NameTypeKey from dbo.fn_GetScreenControlNameTypes(@pnUserIdentityId, @pnCaseKey, @psProgramKey)
	else
		insert into @tblNameType
		select NameTypeKey from dbo.fnw_GetScreenControlNameTypes(@pnUserIdentityId, @pnCaseKey, @psProgramKey)	
	-- get all default names and insert it into the temp table.
	-- a straight insert into CASENAME is not possible because SEQUENCE number has to be generated.
	Insert into @tbDefaultNames
		(
			CASEID,
			NAMETYPE,
			NAMENO,
			[SEQUENCE],
			CORRESPONDNAME,
			DERIVEDCORRNAME,	-- 8911
			ADDRESSCODE,
			BILLPERCENTAGE,
			INHERITED,
			INHERITEDNAMENO,
			INHERITEDRELATIONS,
			INHERITEDSEQUENCE,
			CHANGEEVENTNO,		-- 12315
			REFERENCENO
		)
	select 	distinct
		CS.CASEID, 
		NT.NAMETYPE,
		N.NAMENO as NAMENO,
		0 as [SEQUENCE],
		-- 14023 Only set correspondname if name type indicates, or Instructor or Agent.
		CASE	WHEN (convert(bit,NT.COLUMNFLAGS&1)=0 and NT.NAMETYPE not in ('I','A')) THEN null
			WHEN (A.CONTACT is not null) THEN A.CONTACT
			WHEN (A.RELATEDNAME is not null)
					THEN dbo.fn_GetDerivedAttnNameNo(A.RELATEDNAME,CS.CASEID,NT.NAMETYPE)
			WHEN (NT.HIERARCHYFLAG=1 and CN.NAMENO is not null)
					THEN CN.CORRESPONDNAME
			WHEN (NT.USEHOMENAMEREL=1 and AH.RELATEDNAME is not null)
					THEN CASE WHEN(AH.CONTACT is not null) THEN AH.CONTACT
						  ELSE dbo.fn_GetDerivedAttnNameNo(AH.RELATEDNAME,CS.CASEID,NT.NAMETYPE)
					     END
			WHEN (NT.DEFAULTNAMENO is not null)
					THEN dbo.fn_GetDerivedAttnNameNo(NT.DEFAULTNAMENO,CS.CASEID,NT.NAMETYPE)
		END as CORRESPONDNAME,
		-- 8911 copy derived correspondname flag from parent.
		-- 14023 copy derived correspondname flag if name type uses attention, or Instructor or Agent.
		CASE	WHEN ((convert(bit,NT.COLUMNFLAGS&1)=0 and NT.NAMETYPE not in ('I','A'))
				or A.RELATEDNAME is not null
				or AH.RELATEDNAME is not null
				or CN.NAMENO is null
				or isnull(NT.HIERARCHYFLAG,0)=0 ) then 1
			ELSE CN.DERIVEDCORRNAME
		END as DERIVEDCORRNAME,
		-- Save address code if the Name Type requires one.
		CASE WHEN NT.KEEPSTREETFLAG = 1
		     THEN isnull(A.STREETADDRESS,N.STREETADDRESS)
		END  as ADDRESSCODE, 			
		-- If the bill percent flag is on, default to 100
		CASE WHEN convert(bit, NT.COLUMNFLAGS & 64) = 1 THEN 100 ELSE null END as BILLPERCENTAGE,
		1 as INHERITED,
		-- Save pointer to parent name.
		CASE WHEN (NT.PATHRELATIONSHIP is null
				or A.RELATEDNAME is not null
				or NT.USEHOMENAMEREL=0
				or AH.RELATEDNAME is null) THEN CN.NAMENO
		     ELSE S.COLINTEGER
		END as INHERITEDNAMENO,
		isnull(A.RELATIONSHIP,AH.RELATIONSHIP) as INHERITEDRELATIONS,
		isnull(A.SEQUENCE,AH.SEQUENCE) as INHERITEDSEQUENCE,
		NT.CHANGEEVENTNO,
		--CASE WHEN (NT.PATHRELATIONSHIP is null
		--		or A.RELATEDNAME is not null
		--		or NT.USEHOMENAMEREL=0
		--		or AH.RELATEDNAME is null) THEN CN.REFERENCENO
		--ELSE NULL END
		-------------------------------------------------
		-- RFC 60222
		-- The ReferenceNo shoul only be inherited if the
		-- Name being created matches the Name from which
		-- it was inherited.
		-------------------------------------------------
		CASE WHEN(N.NAMENO=CN.NAMENO) THEN CN.REFERENCENO ELSE NULL END
	from 	NAMETYPE NT 
     	join CASES CS 	on (CS.CASEID = @pnCaseKey)
	-- The CaseName that acts as the starting point
	left join CASENAME CN	on (CN.CASEID = CS.CASEID
			    	and CN.NAMETYPE = NT.PATHNAMETYPE) 
	-- Pick up the CaseName's associated Name
     	left join ASSOCIATEDNAME A 
				on (A.NAMENO = CN.NAMENO 
				and A.RELATIONSHIP = NT.PATHRELATIONSHIP
				and(A.CEASEDDATE is null or A.CEASEDDATE>GETDATE())
				and(A.PROPERTYTYPE = CS.PROPERTYTYPE or A.PROPERTYTYPE is null)
				and(A.COUNTRYCODE  = CS.COUNTRYCODE  or A.COUNTRYCODE  is null)
				-- There may be multiple AssociatedNames.  
				-- A best fit against the Case attributes is required to determine
				-- the characteristics of the Associated Name that best match the Case.
				-- This then allows for all of the associated names with the best
				-- characteristics for the Case to be returned.
				and CASE WHEN(A.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
				    CASE WHEN(A.COUNTRYCODE  is null) THEN '0' ELSE '1' END
					=	(	select
							max (	case when (A1.PROPERTYTYPE is null) then '0' else '1' end +    			
								case when (A1.COUNTRYCODE  is null) then '0' else '1' end)
							from ASSOCIATEDNAME A1
							where A1.NAMENO=A.NAMENO
							and  (A1.CEASEDDATE is null or A1.CEASEDDATE>GETDATE())
							and   A1.RELATIONSHIP=A.RELATIONSHIP
							and  (A1.PROPERTYTYPE=CS.PROPERTYTYPE OR A1.PROPERTYTYPE is null)
							and  (A1.COUNTRYCODE =CS.COUNTRYCODE  OR A1.COUNTRYCODE  is null)))
	-- Get the Home NameNo if no associated Name found and inheritance
	-- is to also consider the Home Name.
	left join SITECONTROL S	on (S.CONTROLID='HOMENAMENO'
				and A.RELATEDNAME is null
				and NT.USEHOMENAMEREL=1) 
	-- Pick up the Home Name's associated Name
     	left join ASSOCIATEDNAME AH 
				on (AH.NAMENO = S.COLINTEGER 
				and AH.RELATIONSHIP = NT.PATHRELATIONSHIP
				and(AH.CEASEDDATE is null or AH.CEASEDDATE>GETDATE())
				and(AH.PROPERTYTYPE = CS.PROPERTYTYPE or AH.PROPERTYTYPE is null)
				and(AH.COUNTRYCODE  = CS.COUNTRYCODE  or AH.COUNTRYCODE  is null)
				-- There may be multiple AssociatedNames.  
				-- A best fit against the Case attributes is required to determine
				-- the characteristics of the Associated Name that best match the Case.
				-- This then allows for all of the associated names with the best
				-- characteristics for the Case to be returned.
				
				and CASE WHEN(AH.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
				    CASE WHEN(AH.COUNTRYCODE  is null) THEN '0' ELSE '1' END
					=	(	select
							max (	case when (AH1.PROPERTYTYPE is null) then '0' else '1' end +    			
								case when (AH1.COUNTRYCODE  is null) then '0' else '1' end)
							from ASSOCIATEDNAME AH1
							where AH1.NAMENO=AH.NAMENO
							and  (AH1.CEASEDDATE is null or AH1.CEASEDDATE>GETDATE())
							and   AH1.RELATIONSHIP=AH.RELATIONSHIP
							and  (AH1.PROPERTYTYPE=CS.PROPERTYTYPE OR AH1.PROPERTYTYPE is null)
							and  (AH1.COUNTRYCODE =CS.COUNTRYCODE  OR AH1.COUNTRYCODE  is null)))
	-- Choose the name to add
     	join NAME N  on (N.NAMENO= 	CASE 
					     -- 15296 Handle when defaulting directly from another NameType.
					     WHEN (NT.PATHNAMETYPE is not null and NT.PATHRELATIONSHIP is null)THEN CN.NAMENO
					     WHEN(A.RELATEDNAME is not null) THEN A.RELATEDNAME
					     -- 13785 Only default to parent name if hierarchy flag set on.
					     WHEN(NT.HIERARCHYFLAG=1)	     THEN CN.NAMENO
					     -- 13785 Use Default Name if relationship not there for home name.
					     WHEN(NT.USEHOMENAMEREL=1)       THEN isnull(AH.RELATEDNAME, NT.DEFAULTNAMENO)
					     -- 13785 Use Default Name if nothing else found.
					     ELSE NT.DEFAULTNAMENO
					END)
	left join CASENAME CN1	on (CN1.CASEID=CS.CASEID
				and CN1.NAMETYPE=NT.NAMETYPE)
	where CN1.CASEID is null-- Only default if the name type is not already present against the case
				-- 13092 Only default if parent name type exists against the case,
				-- or no parent name type and default name defined.
	and ( CN.NAMENO is not null or (NT.PATHNAMETYPE is null and NT.DEFAULTNAMENO is not null) )
				-- Only default relevant name types against screen control
	and NT.NAMETYPE in (Select NameTypeKey 
				from @tblNameType)

	-- RFC9969
	-- The name to be used as the inherited name must be allowed
	-- to be used in the context of the given NameType if the nametype
	-- is flagged to use "Same Name Type" otherwise check that the
	-- Name may be used for any Name that does not explicitly require
	-- this option. 
	and exists(	select 1 from NAMETYPECLASSIFICATION NTC
			where NTC.NAMENO=N.NAMENO
			and NTC.NAMETYPE=CASE WHEN((PICKLISTFLAGS & 16) =  16) THEN NT.NAMETYPE ELSE '~~~' END
			and NTC.ALLOW   =1)
	Order by NT.NAMETYPE


	Select @nRowCount = @@rowcount, @nErrorCode = @@Error
end

-- Allocate the SEQUENCE number for the CASENAME rows.  The number is reset
-- on each change of NAMETYPE.  This is a very fast way of incrementing a sequence
-- that needs to be reset on a control break.
If  @nErrorCode=0
and @nRowCount > 1	-- only need to do this if more than 1 row was inserted
Begin	
	Set @sNameType=''

	Update @tbDefaultNames
	Set @nNameSequence=CASE WHEN(@sNameType=NAMETYPE)
				THEN @nNameSequence+1
				ELSE [SEQUENCE]
			   END,
	[SEQUENCE]=@nNameSequence,
	@sNameType=NAMETYPE

	Set @nErrorCode=@@Error
End

-- Now load the CASENAME table
If  @nErrorCode= 0 
and @nRowCount > 0
begin
	insert	into CASENAME (
		CASEID,
		NAMETYPE,
		NAMENO,
		[SEQUENCE],
		CORRESPONDNAME, 
		DERIVEDCORRNAME,	-- 8911
		ADDRESSCODE,
		BILLPERCENTAGE,
		INHERITED,
		INHERITEDNAMENO,
		INHERITEDRELATIONS,
		INHERITEDSEQUENCE,
		REFERENCENO		--19486
	)
	select 
		T.CASEID,
		T.NAMETYPE,
		T.NAMENO,
		T.[SEQUENCE],
		T.CORRESPONDNAME,
		T.DERIVEDCORRNAME,	-- 8911
		T.ADDRESSCODE,
		T.BILLPERCENTAGE,
		T.INHERITED,
		T.INHERITEDNAMENO,
		T.INHERITEDRELATIONS,
		T.INHERITEDSEQUENCE,
		T.REFERENCENO		--19486
	from 	@tbDefaultNames T
	join 	NAMETYPE NT on (NT.NAMETYPE=T.NAMETYPE)
	Where	T.[SEQUENCE]<isnull(NT.MAXIMUMALLOWED,999)	-- ensure you do not exceed maximum limits on NameType

	Select @nErrorCode = @@error,
		@pnInsertedRowCount=@@rowcount
end		

-- SQA12315
-- A NameType that has been associated with an EventNo will cause the
-- CASEEVENT row to be inserted or updated and a Policing request raised.
If  @nErrorCode=0
and @pnInsertedRowCount>0
Begin
	-- First create the Policing rows in a temporary table
	-- so that a Sequence number is allocated
	insert into @tbTempPolicing(EVENTNO)
	select distinct T.CHANGEEVENTNO
	from @tbDefaultNames T
	left join CASEEVENT CE	on (CE.CASEID =T.CASEID
				and CE.EVENTNO=T.CHANGEEVENTNO
				and CE.CYCLE  =1)
	where T.CHANGEEVENTNO is not null
	and (CE.EVENTDATE is null OR CE.EVENTDATE<>convert(varchar,getdate(),112))

	Select @nErrorCode=@@error,
	       @nRowCount =@@rowcount
End

If @nErrorCode=0
and @nRowCount>0
Begin
	-- Now Update any CaseEvent rows that previously existed
	Update CASEEVENT
	Set EVENTDATE=convert(varchar,getdate(),112),
	    OCCURREDFLAG=1
	from CASEEVENT CE
	join @tbDefaultNames T	on (T.CASEID=CE.CASEID
				and T.CHANGEEVENTNO=CE.EVENTNO)
	where CE.CYCLE=1
	and (CE.EVENTDATE is null OR CE.EVENTDATE<>convert(varchar,getdate(),112))

	Set @nErrorCode=@@error

	-- insert CASEEVENT rows that previously did not exist
	If @nErrorCode=0
	Begin
		insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)
		select distinct T.CASEID, T.CHANGEEVENTNO, 1, convert(varchar,getdate(),112), 1
		from @tbDefaultNames T
		left join CASEEVENT CE	on (CE.CASEID=T.CASEID
					and CE.EVENTNO=T.CHANGEEVENTNO
					and CE.CYCLE=1)
		where T.CHANGEEVENTNO is not null
		and CE.CASEID is null

		Set @nErrorCode=@@error
	End

	-- Now load the live Policing table
	If @nErrorCode=0
	Begin
		-- Since DateTime is part of the key it is possible to
		-- get a duplicate key.  Keep trying until a unique DateTime
		-- is extracted.
		set @dtDateEntered = getdate()

		While exists
			(Select 1 from POLICING
			where	CASEID = @pnCaseKey
			and	DATEENTERED = @dtDateEntered)
		Begin
			-- millisecond are held to equivalent to 3.33, so need to add 3
			Set @dtDateEntered = DateAdd(millisecond,3,@dtDateEntered)
		End

		insert into POLICING(DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, EVENTNO, 
				     CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
		select	@dtDateEntered, 
			T.POLICINGSEQNO, 
			convert(varchar, @dtDateEntered, 121)+' '+convert(varchar,T.POLICINGSEQNO), 
			1, 
			0, 
			T.EVENTNO, 
			@pnCaseKey,
			1,
			3, 
			SYSTEM_USER, 
			@pnUserIdentityId
		from @tbTempPolicing T

		Set @nErrorCode=@@error
	End
End	

-- Select count of CaseName records inserted if called from Centura
If  @nErrorCode = 0 
and @pbCalledFromCentura = 1
begin
	Select @pnInsertedRowCount
end

Return @nErrorCode
go

Grant execute on dbo.cs_GenerateCaseName to public
go
