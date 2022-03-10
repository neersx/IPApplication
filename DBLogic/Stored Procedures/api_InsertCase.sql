-----------------------------------------------------------------------------------------------------------------------------
-- Creation of api_InsertCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'dbo.api_InsertCase') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.api_InsertCase.'
	drop procedure dbo.api_InsertCase
	print '**** Creating Stored Procedure dbo.api_InsertCase...'
	print ''
end
GO

set QUOTED_IDENTIFIER on -- this is required for the XML Nodes method
go
SET ANSI_NULLS ON 
GO

create procedure dbo.api_InsertCase
	@pnCaseId			int		output,	
	@pnUserIdentityId		int		= null,	-- optional identifier of the user
	@psCaseReference		nvarchar(30)	= '<Generate Reference>', -- User supplied Case Reference
	@psStem 			nvarchar(30)	= null,	-- Stem used for generated Case Reference 
	@pdtInstructionsReceivedDate	datetime	= null,	-- date instructions for Case were received
	@psCaseType			nchar(1)	= null, 
	@psCountryCode			nvarchar(3) 	= null,	
	@psPropertyType			nchar(1) 	= null,
	@psCaseCategory 		nvarchar(2) 	= null,
	@psSubType			nvarchar(2) 	= null,
	@psApplicationBasis		nvarchar(2)	= null,
	@pnOfficeId			int		= null,
	@pnInstructor			int		= null,
	@pnStaffMember			int		= null,
	@pnSignatory			int		= null,
	@pbNameInheritance		bit		= 1,	-- Names will trigger inheritance of other Name Types
	@psTitle			nvarchar(254)	= null,
	@psRemarks			nvarchar(254)	= null,
	-- Extended optional parameters
	@psFamily			nvarchar(20)	= null, -- Family the Case belongs to. References the CASEFAMILY table.
	@pnTypeOfMark			int		= null, -- Type Of Mark is a reference to the TABLECODES table where TABLETYPE=51
	@pnStatus			int		= null, -- Status of the case referencing the STATUS table
	
	@pxOfficialNumbers		xml		= null,	-- Official Numbers catering for multiple rows with XML formatted as in the following example:
								--<OfficialNumbers>
								--  <OfficialNumber>
								--    <OFFICIALNUMBER>1,067,000</OFFICIALNUMBER>
								--    <NUMBERTYPE>A</NUMBERTYPE>
								--  </OfficialNumber>
								--  <OfficialNumber>
								--    <OFFICIALNUMBER>777777</OFFICIALNUMBER>
								--    <NUMBERTYPE>C</NUMBERTYPE>
								--  </OfficialNumber>
								--</OfficialNumbers>
								
	@pxCaseEvents			xml		= null,	-- Case Events catering for multiple rows with XML formatted as in the following example:
								--<CaseEvents>
								--  <CaseEvent>
								--    <EVENTNO>-4</EVENTNO>
								--    <CYCLE>1</CYCLE>
								--    <EVENTDATE>1995-07-30</EVENTDATE>
								--  </CaseEvent>
								--  <CaseEvent>
								--    <EVENTNO>-11</EVENTNO>
								--    <CYCLE>2</CYCLE>
								--    <EVENTDUEDATE>2016-11-22</EVENTDUEDATE>
								--  </CaseEvent>
								--  <CaseEvent>
								--    <EVENTNO>-11</EVENTNO>
								--    <CYCLE>1</CYCLE>
								--    <EVENTDATE>2006-11-22</EVENTDATE>
								--  </CaseEvent>
								--</CaseEvents>
								
	@pxCaseNames			xml		= null,	-- Case Names catering from multiple rows with XML formatted as in the following example:
								--<CaseNames>
								--  <CaseName>
								--    <NAMETYPE>A</NAMETYPE>
								--    <NAMENO>10052</NAMENO>
								--    <SEQUENCE>0</SEQUENCE>
								--    <CORRESPONDNAME>1005299</CORRESPONDNAME>
								--    <ADDRESSCODE>-1052</ADDRESSCODE>
								--  </CaseName>
								--  <CaseName>
								--    <NAMETYPE>O</NAMETYPE>
								--    <NAMENO>-492</NAMENO>
								--    <SEQUENCE>0</SEQUENCE>
								--    <ADDRESSCODE>-495</ADDRESSCODE>
								--  </CaseName>
								--  <CaseName>
								--    <NAMETYPE>O</NAMETYPE>
								--    <NAMENO>42</NAMENO>
								--    <SEQUENCE>1</SEQUENCE>
								--    <ADDRESSCODE>33</ADDRESSCODE>
								--  </CaseName>
								--</CaseNames>
								
	@pxRelatedCases			xml		= null,	-- Related Case details catering for multiple rows with XML formatted as in the following example:
								--<RelatedCases>
								--  <RelatedCase>
								--    <RELATIONSHIP>BAS</RELATIONSHIP>
								--    <OFFICIALNUMBER>887,765</OFFICIALNUMBER>
								--    <COUNTRYCODE>US</COUNTRYCODE>
								--    <PRIORITYDATE>1994-08-12T00:00:00</PRIORITYDATE>
								--  </RelatedCase>
								--  <RelatedCase>
								--    <RELATIONSHIP>BAS</RELATIONSHIP>
								--    <RELATEDCASEID>-490</RELATEDCASEID>
								--  </RelatedCase>
								--</RelatedCases>
								
	@pxClassGoods			xml		= null,	-- Classes and Goods allow for multiple rows with XML formatted as in the following example :
								--<Classes>
								--  <ClassText>
								--    <CLASS>42</CLASS>
								--    <GOODS>Providing of food and drink; temporary accommodation; medical, hygienic and beauty care; veterinary and agricultural services; legal services; scientific and industrial research; computer programming; services that cannot be placed in other classes.</GOODS>
								--  </ClassText>
								--  <ClassText>
								--    <CLASS>46</CLASS>
								--    <GOODS>Test only.</GOODS>
								--  </ClassText>
								--</Classes>
								
	@pxTableAttributes		xml		= null	-- Table Attributes that allow for multiple rows with XML formatted as in the following example:
								--<TableAttributes>
								--  <TableAttribute>
								--    <TABLECODE>15117</TABLECODE>
								--  </TableAttribute>
								--  <TableAttribute>
								--    <TABLECODE>15118</TABLECODE>
								--  </TableAttribute>
								--</TableAttributes>
	
as
-- PROCEDURE :	api_InsertCase
-- VERSION :	5
-- DESCRIPTION:	An application program interface (api) that will accept Case characteristics and
--		create an Inprotech Case within the Inprotech database.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 11 FEB 2008	MF	15732	1	Procedure created
-- 09 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 17 Jan 2011	MF	R10175	3	Change the name of #TEMPCASES table to #TEMPCASES_API as there is a conflict with that table
--					name in the cs_GlobalNameChange stored procedure.
-- 07 Jan 2013	MF	R13095	4	Extend the procedure to receive additional parameters including some repeating groups delivered as XML.
-- 19 Jul 2017	MF	71968	5	When determining the default Case program, first consider the Profile of the User.

set nocount on

create table #TEMPCASES_API (	CASEID		int	NOT NULL)

create table #TEMPCASENAME_API
			    (	CASEID		int		NOT NULL,
				NAMETYPE	nvarchar(3)	collate database_default NOT NULL,
				NAMENO		int		NOT NULL,
				SEQUENCE	smallint	NOT NULL,
				CORRESPONDNAME	int		NULL,
				ADDRESSCODE	int		NULL,
				REFERENCENO	nvarchar(80)	collate database_default NULL,
				ROWSEQUENCE	int		identity(1,1)
				)

create table #TEMPRELATEDCASE_API
			    (	CASEID		int		NOT NULL,
				RELATIONSHIPNO	int		identity(1,1),
				RELATIONSHIP	nvarchar(3)	collate database_default NOT NULL,
				RELATEDCASEID	int		NULL,
				OFFICIALNUMBER	nvarchar(36)	collate database_default NULL,
				COUNTRYCODE	nvarchar(3)	collate database_default NULL,
				PRIORITYDATE	datetime	NULL
				)

create table #TEMPCLASSTEXT_API
			    (	TEXTNO		int		identity(0,1),
				CLASS		nvarchar(100)	collate database_default NOT NULL,
				TEXT		nvarchar(max)	collate database_default NULL
				)

create table #TEMPRESULT	(RelationshipNo	int		NULL)

declare	@sSQLString		nvarchar(4000)
declare	@bHexNumber		varbinary(128)
declare @nOfficeID		int
declare	@nLogMinutes		int 
declare	@nTransNo		int
declare	@nBatchNo		int		-- place holder only as not used here
declare @nNamesUpdatedCount	int
declare	@nNamesInsertedCount	int
declare	@nNamesDeletedCount	int
declare	@nHomeNameNo		int
declare	@nNameNo		int
declare	@nAttention		int
declare	@nAddressCode		int
declare @nRelatedCaseId		int
declare @sRelationship		nvarchar(3)
declare @sOfficialNo		nvarchar(36)
declare @sCountryCode		nvarchar(3)
declare @dtPriorityDate		datetime
declare	@sNameType		nvarchar(3)
declare	@sReferenceNo		nvarchar(80)
declare	@sClassList		nvarchar(254)
declare @sIntClassList		nvarchar(254)

declare	@sProgramId		nvarchar(20)
declare @sInterimAction		nvarchar(2)

declare @nErrorCode		int
declare	@nRowCount		int
declare	@nRowNumber		int
declare @TranCountStart		int

-----------------------
-- Initialise Variables
-----------------------
set @nErrorCode = 0

--------------------------------------------------
-- D A T A   V A L I D A T I O N
-- Validate the input parameters before attempting
-- to create the Case
--------------------------------------------------

--------------------
-- Validate CaseType
--------------------
If @nErrorCode = 0
Begin
	If @psCaseType is null
	Begin
		RAISERROR('@psCaseType must not be NULL', 14, 1)
		Set @nErrorCode = @@ERROR
	End
	Else If not exists (select 1 from CASETYPE where CASETYPE=@psCaseType)
	Begin
		RAISERROR('@psCaseType must exist in CASETYPE table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

------------------------
-- Validate PropertyType
------------------------
If @nErrorCode = 0
Begin
	If @psPropertyType is null
	Begin
		RAISERROR('@psPropertyType must not be NULL', 14, 1)
		Set @nErrorCode = @@ERROR
	End
	Else If not exists (select 1 from PROPERTYTYPE where PROPERTYTYPE=@psPropertyType)
	Begin
		RAISERROR('@psPropertyType must exist in PROPERTYTYPE table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

-------------------
-- Validate Country
-------------------
If @nErrorCode = 0
Begin
	If @psCountryCode is null
	Begin
		RAISERROR('@psCountryCode must not be NULL', 14, 1)
		Set @nErrorCode = @@ERROR
	End
	Else If not exists (select 1 from COUNTRY where COUNTRYCODE=@psCountryCode)
	Begin
		RAISERROR('@psCountryCode must exist in COUNTRY table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

------------------------
-- Validate CaseCategory
------------------------
If @nErrorCode = 0
and @psCaseCategory is not null
Begin
	If not exists (select 1 from CASECATEGORY where CASETYPE=@psCaseType and CASECATEGORY=@psCaseCategory)
	Begin
		RAISERROR('@psCaseCategory must exist in CASECATEGORY table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

-------------------
-- Validate SubType
-------------------
If @nErrorCode = 0
and @psSubType is not null
Begin
	If not exists (select 1 from SUBTYPE where SUBTYPE=@psSubType)
	Begin
		RAISERROR('@psSubType must exist in SUBTYPE table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

----------------------------
-- Validate ApplicationBasis
----------------------------
If @nErrorCode = 0
and @psApplicationBasis is not null
Begin
	If not exists (select 1 from APPLICATIONBASIS where BASIS=@psApplicationBasis)
	Begin
		RAISERROR('@psApplicationBasis must exist in APPLICATIONBASIS table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

------------------
-- Validate Office
------------------
If @nErrorCode = 0
and @pnOfficeId is not null
Begin
	If not exists (select 1 from OFFICE where OFFICEID=@pnOfficeId)
	Begin
		RAISERROR('@pnOfficeId must exist in OFFICE table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

----------------------
-- Validate Instructor
----------------------
If @nErrorCode = 0
and @pnInstructor is not null
Begin
	If not exists (select 1 from IPNAME where NAMENO=@pnInstructor)
	Begin
		RAISERROR('@pnInstructor must be a Name marked as a client and exist in IPNAME table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

------------------------
-- Validate Staff Member
------------------------
If @nErrorCode = 0
and @pnStaffMember is not null
Begin
	If not exists (select 1 from EMPLOYEE where EMPLOYEENO=@pnStaffMember)
	Begin
		RAISERROR('@pnStaffMember must be a Name marked as a staff and exist in EMPLOYEE table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

---------------------
-- Validate Signatory
---------------------
If @nErrorCode = 0
and @pnSignatory is not null
Begin
	If not exists (select 1 from EMPLOYEE where EMPLOYEENO=@pnSignatory)
	Begin
		RAISERROR('@pnSignatory must be a Name marked as a staff and exist in EMPLOYEE table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

------------------------------
-- Valid Country/Property Type
-- combination
------------------------------
If @nErrorCode = 0
Begin
	If not exists (	select 1 from VALIDPROPERTY VP
			where VP.PROPERTYTYPE=@psPropertyType
			and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)
						from VALIDPROPERTY VP1
						where VP1.COUNTRYCODE in ('ZZZ',@psCountryCode)))
	Begin
		RAISERROR('@psPropertyType must be a valid Property Type for the Country or Country=ZZZ', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

-------------------------------------------------
-- Valid Country/Property Type/Case Type/Category
-- combination
-------------------------------------------------
If @nErrorCode = 0
and @psCaseCategory is not null
Begin
	If not exists (	select 1 from VALIDCATEGORY VC
			where VC.PROPERTYTYPE=@psPropertyType
			and VC.CASETYPE      =@psCaseType
			and VC.CASECATEGORY  =@psCaseCategory
			and VC.COUNTRYCODE=(	select min(VC1.COUNTRYCODE)
						from VALIDCATEGORY VC1
						where VC1.COUNTRYCODE in ('ZZZ',@psCountryCode)
						and VC1.PROPERTYTYPE=@psPropertyType
						and VC1.CASETYPE    =@psCaseType))
	Begin
		RAISERROR('@psCaseCategory must be a valid Case Category for the Country/Property/Case Type', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

---------------------------------------------------------
-- Valid Country/Property Type/Case Type/Category/SubType
-- combination
---------------------------------------------------------
If @nErrorCode = 0
and @psSubType is not null
Begin
	------------------------------------------
	-- If CaseCategory is NULL then SubType is
	-- to also be set to NULL.
	------------------------------------------
	If @psCaseCategory is null
		Set @psSubType=null
	Else
	If not exists (	select 1 from VALIDSUBTYPE VS
			where VS.PROPERTYTYPE=@psPropertyType
			and VS.CASETYPE    =@psCaseType
			and VS.CASECATEGORY=@psCaseCategory
			and VS.SUBTYPE     =@psSubType
			and VS.COUNTRYCODE=(	select min(VS1.COUNTRYCODE)
						from VALIDSUBTYPE VS1
						where VS1.COUNTRYCODE in ('ZZZ',@psCountryCode)
						and VS1.PROPERTYTYPE=@psPropertyType
						and VS1.CASETYPE    =@psCaseType
						and VS1.CASECATEGORY=@psCaseCategory))
	Begin
		RAISERROR('@psSubType must be a valid Sub Type for the Country/Property/Case Type/Category', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

-------------------------------------
-- Validate the supplied UserIdentity
-------------------------------------
If @nErrorCode=0
Begin
	If (@pnUserIdentityId is null
	 or @pnUserIdentityId='')
	Begin
		Select @pnUserIdentityId=min(IDENTITYID)
		from USERIDENTITY
		where LOGINID=substring(SYSTEM_USER,1,50)

		Set @nErrorCode=@@ERROR
	End
	Else If not exists (select 1 from USERIDENTITY where IDENTITYID=@pnUserIdentityId)
	Begin
		RAISERROR('@pnUserIdentityId must exist in USERIDENTITY table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

---------------------------------------
-- Validate that user supplied Case 
-- Reference has not already been used.
---------------------------------------
If  @nErrorCode = 0
and @psCaseReference<>'<Generate Reference>'
Begin
	-- Case Reference is always forced to upper case
	Set @psCaseReference = upper(@psCaseReference) 

	If exists (select 1 from CASES where IRN=@psCaseReference)
	Begin
		RAISERROR('@psCaseReference must not already exist as IRN in CASES table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End 

------------------
-- Validate Family
------------------
If @nErrorCode = 0
and @psFamily is not null
Begin
	If not exists (select 1 from CASEFAMILY where FAMILY=@psFamily)
	Begin
		RAISERROR('@psFamily must exist in CASEFAMILY table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

------------------------
-- Validate Type Of Mark
------------------------
If @nErrorCode = 0
and @pnTypeOfMark is not null
Begin
	If not exists (select 1 from TABLECODES where TABLECODE=@pnTypeOfMark and TABLETYPE=51)
	Begin
		RAISERROR('@pnTypeOfMark must exist in TABLECODES table with a TABLETYPE = 51', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

------------------------
-- Validate Status
------------------------
If @nErrorCode = 0
and @pnStatus is not null
Begin
	If not exists (select 1 from STATUS where STATUSCODE=@pnStatus and RENEWALFLAG=0)
	Begin
		RAISERROR('@pnStatus must exist in STATUS table with a RENEWALFLAG=0', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

--------------------------------------
-- Initialise variables that will be 
-- loaded into CONTEXT_INFO for access
-- by the audit triggers
--------------------------------------

If @nErrorCode=0
Begin
	Select @nOfficeID=COLINTEGER
	from SITECONTROL
	where CONTROLID='Office For Replication'

	Select @nLogMinutes=COLINTEGER
	from SITECONTROL
	where CONTROLID='Log Time Offset'

	Set @nErrorCode=@@ERROR
End

--------------------------------------------------
-- Get Transaction Number for use in audit records.
-- Get the next CASEID to use to create the Case.
---------------------------------------------------
If @nErrorCode=0
Begin
	-----------------------------------------------------------------------------
	-- A separate database transaction will be used to insert the TRANSACTIONINFO
	-- row to ensure the lock on the database is kept to a minimum as this table
	-- will be used extensively by other processes.
	-----------------------------------------------------------------------------

	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Allocate a transaction id that can be accessed by the audit logs
	-- for inclusion.

	Insert into TRANSACTIONINFO(TRANSACTIONDATE) values(getdate())
	Select @nTransNo  =SCOPE_IDENTITY(),
	       @nErrorCode=@@ERROR	

	--------------------------------------------------------------
	-- Load a common area accessible from the database server with
	-- the UserIdentityId and the TransactionNo just generated.
	-- This will be used by the audit logs.
	--------------------------------------------------------------
	If @nErrorCode=0
	Begin
		Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4)+ 
				substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
				substring(cast(isnull(@nBatchNo,'') as varbinary),1,4) +
				substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
				substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
		SET CONTEXT_INFO @bHexNumber
	End

	If @nErrorCode=0
	Begin
		update 	LASTINTERNALCODE
		set 	INTERNALSEQUENCE = INTERNALSEQUENCE + 1,
			@pnCaseId = INTERNALSEQUENCE + 1
		from	LASTINTERNALCODE		
		where 	TABLENAME = 'CASES'

		set @nErrorCode=@@ERROR
	End

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-----------------------------------------------------------------------------------------------
-- C A S E   C R E A T I O N
-- All the inserts to the database are to be applied as a single transaction so that the entire
-- transaction can be rolled back should a failure occur.
-----------------------------------------------------------------------------------------------
If @nErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-------------------
	-- Insert CASES row
	-------------------
	if @nErrorCode = 0
	begin
		insert into 	CASES
			(	CASEID,
				IRN,
				STEM,
				CASETYPE,
				PROPERTYTYPE,
				COUNTRYCODE,
				CASECATEGORY,
				SUBTYPE,
				TITLE,
				LOCALCLIENTFLAG,
				OFFICEID,
				FAMILY,
				TYPEOFMARK,
				STATUSCODE
			)
		Select		@pnCaseId,
				ltrim(rtrim(@psCaseReference)),
				upper(@psStem),		
				@psCaseType,
				@psPropertyType,
				@psCountryCode,	
				@psCaseCategory, 
				@psSubType, 
				@psTitle,
				IP.LOCALCLIENTFLAG,
				@pnOfficeId,
				@psFamily,
				@pnTypeOfMark,
				@pnStatus
		from CASETYPE CT
		left join IPNAME IP on (IP.NAMENO=@pnInstructor)
		where CT.CASETYPE=@psCaseType

		Set @nErrorCode = @@ERROR
	end


	----------------------------
	-- Insert PROPERTY row if
	-- ApplicationBasis supplied
	----------------------------
	if @nErrorCode = 0
	and @psApplicationBasis is not null
	begin
		insert into PROPERTY
			(	CASEID,
				BASIS
			)
		values	
			(	@pnCaseId,
				@psApplicationBasis
			)

		Set @nErrorCode=@@ERROR
	end
	

	------------------------------------
	-- Load Classes and Goods/Services
	-- into a temporary table as an
	-- interim step to generate the 
	-- TEXTNO and to allow the list of
	-- classes to be concatenated before
	-- the CASES row is inserted.
	------------------------------------
	If @nErrorCode=0
	and @pxClassGoods is not null
	Begin
		------------------------------------
		-- Load into a temporary table as an
		-- interim step to generate the 
		-- RELATIONSHIPNO.
		------------------------------------
		insert into 	#TEMPCLASSTEXT_API
			(	CLASS,
				TEXT
			)

		select	CT.value(N'CLASS[1]',N'nvarchar(100)')	as Class,
			CT.value(N'GOODS[1]',N'nvarchar(max)')	as Goods
		from @pxClassGoods.nodes(N'/Classes/ClassText') Class(CT)
		order by 1

		Select  @nErrorCode=@@ERROR,
			@nRowCount=@@ROWCOUNT
			
		If  @nRowCount>0
		and @nErrorCode=0
		Begin
			--------------------------------------
			-- Now concatenate the list of classes
			-- into a single comma separated list.
			--------------------------------------
			SELECT @sClassList = CASE WHEN(@sClassList is not null) THEN @sClassList+',' ELSE '' END  + CLASS
			FROM #TEMPCLASSTEXT_API
			
			Set @nErrorCode=@@Error
			
			--------------------------------------------
			-- Now concatenate the list of international
			-- classes associated with the local classes
			-- into a single comma separated list.
			--------------------------------------------
			If @nErrorCode=0
			Begin
				SELECT @sIntClassList = CASE WHEN(@sIntClassList is not null) THEN @sIntClassList+',' ELSE '' END  + C.INTERNATIONALCLASS
				FROM #TEMPCLASSTEXT_API T
				join TMCLASS C	on (C.CLASS=T.CLASS
						and C.COUNTRYCODE=(	select min(C1.COUNTRYCODE)
									from TMCLASS C1
									where C1.COUNTRYCODE in ('ZZZ',@psCountryCode)))
				where C.INTERNATIONALCLASS is not null
				
				Set @nErrorCode=@@Error
			End
			
			------------------------------
			-- Insert Goods/Services for
			-- Classes into CASETEXT
			------------------------------
			If  @nErrorCode=0
			Begin	
				insert into CASETEXT
					(	CASEID,
						TEXTTYPE,
						TEXTNO,
						CLASS,
						MODIFIEDDATE,
						LONGFLAG,
						SHORTTEXT,
						TEXT)
				select	@pnCaseId,
					'G',
					TEXTNO,
					CLASS,
					GETDATE(),
					CASE WHEN(LEN(TEXT))>254 THEN 1    ELSE 0    END,
					CASE WHEN(LEN(TEXT))>254 THEN NULL ELSE TEXT END,
					CASE WHEN(LEN(TEXT))>254 THEN TEXT ELSE NULL END
				From #TEMPCLASSTEXT_API
				
				Set @nErrorCode=@@ERROR
			End
			
			-------------------------------------
			-- Now we have a list of Classes we
			-- can update the CASES row.
			-- NOTE: This is done here rather 
			--       than when the CASES row is
			--       inserted as a trigger would
			--	 write the CASETEXT rows for 
			--	 each class without the Goods
			-------------------------------------
			If  @sClassList is not null
			and @nErrorCode=0
			Begin
				Update CASES
				Set NOOFCLASSES =@nRowCount,
				    LOCALCLASSES=@sClassList,
				    INTCLASSES  =@sIntClassList
				Where CASEID=@pnCaseId
				
				Set @nErrorCode=@@ERROR
			End
		End
	End
	------------------------------
	-- Insert into OFFICIALNUMBERS
	------------------------------
	If @nErrorCode=0
	and @pxOfficialNumbers is not null
	Begin
		insert into 	OFFICIALNUMBERS
			(	CASEID,
				OFFICIALNUMBER,
				NUMBERTYPE,
				ISCURRENT
			)
		
		select		@pnCaseId,
				O.value(N'OFFICIALNUMBER[1]',N'nvarchar(30)')	as OfficialNumber,
				O.value(N'NUMBERTYPE[1]',N'nvarchar(3)')	as NumberType,
				1						as IsCurrent
		from @pxOfficialNumbers.nodes(N'/OfficialNumbers/OfficialNumber') OFFICIALNUMBERS(O)
		join NUMBERTYPES NT on (NT.NUMBERTYPE=O.value(N'NUMBERTYPE[1]',N'nvarchar(3)'))

		Set @nErrorCode=@@ERROR
	End
	
	------------------------------
	-- Insert into CASEEVENT
	------------------------------
	If @nErrorCode=0
	and @pxCaseEvents is not null
	Begin
		insert into 	CASEEVENT
			(	CASEID,
				EVENTNO,
				CYCLE,
				EVENTDATE,
				EVENTDUEDATE,
				OCCURREDFLAG,
				DATEDUESAVED
			)
		
		select	@pnCaseId				 as CaseId,
			CE.value(N'EVENTNO[1]',     N'int')	 as EventNo,
			CE.value(N'CYCLE[1]',       N'smallint') as Cycle,
			CE.value(N'EVENTDATE[1]',   N'datetime') as EventDate,
			CE.value(N'EVENTDUEDATE[1]',N'datetime') as EventDueDate,
			CASE WHEN(CE.value(N'EVENTDATE[1]',N'datetime') IS NOT NULL) THEN 1 ELSE 0 END as OccurredFlag,
			CASE WHEN(CE.value(N'EVENTDATE[1]',N'datetime') IS NOT NULL) THEN 0 ELSE 1 END as DateDueFlag
		from @pxCaseEvents.nodes(N'/CaseEvents/CaseEvent') CASEEVENT(CE)
		join EVENTS EV on (EV.EVENTNO=CE.value(N'EVENTNO[1]',N'int'))
		where (CE.value(N'EVENTDATE[1]',   N'datetime') is not null
		   OR  CE.value(N'EVENTDUEDATE[1]',N'datetime') is not null)

		Set @nErrorCode=@@ERROR
	End

	------------------------
	-- Insert into CASEEVENT
	-- 1) Date of Entry
	------------------------
	if @nErrorCode = 0
	and not exists(select 1 from CASEEVENT where CASEID=@pnCaseId and EVENTNO=-13 and CYCLE=1)
	begin
		insert into 	CASEEVENT
			(	CASEID,
				EVENTNO,
				EVENTDATE,
				CYCLE,
				DATEDUESAVED,
				OCCURREDFLAG
			)
		values		
			(	@pnCaseId,
				-13,
				dbo.fn_DateOnly(GETDATE()),  -- this needs to be date only!
				1,
				0,
				1
			)

		Set @nErrorCode = @@ERROR
	end

	---------------------------
	-- Insert into CASEEVENT
	-- 2) Instructions Received
	---------------------------
	if @nErrorCode = 0
	and not exists(select 1 from CASEEVENT where CASEID=@pnCaseId and EVENTNO=-16 and CYCLE=1)
	begin
		insert into 	CASEEVENT
			(	CASEID,
				EVENTNO,
				EVENTDATE,
				CYCLE,
				DATEDUESAVED,
				OCCURREDFLAG
			)
		values	(	@pnCaseId,
				-16,
				dbo.fn_DateOnly(isnull(@pdtInstructionsReceivedDate,GETDATE())),
				1,
				0,
				1
			)

		Set @nErrorCode = @@ERROR
	end

	----------------------------------------------------
	-- Insertion of Names against the Case will be done
	-- using the Global Name Change functionality if
	-- inheritance of Names is required otherwise just
	-- the specific Name will be inserted against the
	-- Case.
	----------------------------------------------------
	If @pbNameInheritance=0
	and (@pnInstructor  is not null
	 OR  @pnStaffMember is not null
	 OR  @pnSignatory   is not null
	 OR  @pxCaseNames   is not null)
	Begin
		If @nErrorCode=0
		and @pnInstructor is not null
		Begin
			insert into CASENAME(CASEID, NAMETYPE, NAMENO, SEQUENCE, INHERITED, ADDRESSCODE)
			select	@pnCaseId, NT.NAMETYPE, N.NAMENO, 0, 0,
				CASE WHEN(NT.KEEPSTREETFLAG=1) THEN N.STREETADDRESS END
			from NAME N
			join NAMETYPE NT on (NT.NAMETYPE='I')
			where N.NAMENO=@pnInstructor

			Set @nErrorCode=@@ERROR
		End

		If @nErrorCode=0
		and @pnStaffMember is not null
		Begin
			insert into CASENAME(CASEID, NAMETYPE, NAMENO, SEQUENCE, INHERITED, ADDRESSCODE)
			select	@pnCaseId, NT.NAMETYPE, N.NAMENO, 0, 0,
				CASE WHEN(NT.KEEPSTREETFLAG=1) THEN N.STREETADDRESS END
			from NAME N
			join NAMETYPE NT on (NT.NAMETYPE='EMP')
			where N.NAMENO=@pnStaffMember

			Set @nErrorCode=@@ERROR
		End

		If @nErrorCode=0
		and @pnSignatory is not null
		Begin
			insert into CASENAME(CASEID, NAMETYPE, NAMENO, SEQUENCE, INHERITED, ADDRESSCODE)
			select	@pnCaseId, NT.NAMETYPE, N.NAMENO, 0, 0,
				CASE WHEN(NT.KEEPSTREETFLAG=1) THEN N.STREETADDRESS END
			from NAME N
			join NAMETYPE NT on (NT.NAMETYPE='SIG')
			where N.NAMENO=@pnSignatory

			Set @nErrorCode=@@ERROR
		End
	
		------------------------------
		-- Insert into CASENAME
		------------------------------
		If @nErrorCode=0
		and @pxCaseNames is not null
		Begin
			insert into 	CASENAME
				(	CASEID,
					NAMETYPE,
					NAMENO,
					SEQUENCE,
					CORRESPONDNAME,
					ADDRESSCODE,
					REFERENCENO,
					INHERITED
				)
			
			select	@pnCaseId					as CaseId,
				CN.value(N'NAMETYPE[1]',     N'nvarchar(3)')	as NameType,
				CN.value(N'NAMENO[1]',       N'int')		as NameNo,
				CN.value(N'SEQUENCE[1]',     N'smallint')	as Sequence,
				CN.value(N'CORESPONDNAME[1]',N'int')		as CorrespondName,
				CN.value(N'ADDRESSCODE[1]',  N'int')		as AddressCode,
				CN.value(N'REFERENCENO[1]',  N'nvarchar(80)')	as ReferenceNo,
				0						as Inherited
			from @pxCaseNames.nodes(N'/CaseNames/CaseName') CaseName(CN)
			     join NAMETYPE NT  on (NT.NAMETYPE  =CN.value(N'NAMETYPE[1]',     N'nvarchar(3)'))
			     join NAME N1      on (N1.NAMENO    =CN.value(N'NAMENO[1]',       N'int'))
			left join NAME N2      on (N2.NAMENO    =CN.value(N'CORESPONDNAME[1]',N'int'))
			left join ADDRESS A    on (A.ADDRESSCODE=CN.value(N'ADDRESSCODE[1]',  N'int'))
			left join CASENAME CN1 on (CN1.CASEID=@pnCaseId
			                       and CN1.NAMETYPE=CN.value(N'NAMETYPE[1]',     N'nvarchar(3)') )
			where (N2.NAMENO     is not null OR CN.value(N'CORESPONDNAME[1]',N'int') is null)
			and   (A.ADDRESSCODE is not null OR CN.value(N'ADDRESSCODE[1]',  N'int') is null)
			and  CN1.CASEID is null -- To ensure a CaseName for the NameType has not already been inserted

			Set @nErrorCode=@@ERROR
		End
	End
	
	------------------------------
	-- Insert into RELATEDCASE
	------------------------------
	If @nErrorCode=0
	and @pxRelatedCases is not null
	Begin
		------------------------------------
		-- Load into a temporary table as an
		-- interim step to generate the 
		-- RELATIONSHIPNO.
		------------------------------------
		insert into 	#TEMPRELATEDCASE_API
			(	CASEID,
				RELATIONSHIP,
				RELATEDCASEID,
				OFFICIALNUMBER,
				COUNTRYCODE,
				PRIORITYDATE
			)

		select	@pnCaseId,
			RC.value(N'RELATIONSHIP[1]',  N'nvarchar(3)') as Relationship,
			RC.value(N'RELATEDCASEID[1]', N'int')	      as RelatedCaseId,
			RC.value(N'OFFICIALNUMBER[1]',N'nvarchar(36)')as OfficialNumber,
			RC.value(N'COUNTRYCODE[1]',   N'nvarchar(3)') as CountryCode,
			RC.value(N'PRIORITYDATE[1]',  N'datetime')    as PriorityDate
		from @pxRelatedCases.nodes(N'/RelatedCases/RelatedCase') RelatedCase(RC)
		     join CASERELATION CR on (CR.RELATIONSHIP=RC.value(N'RELATIONSHIP[1]', N'nvarchar(3)'))
		left join COUNTRY C       on (C.COUNTRYCODE  =RC.value(N'COUNTRYCODE[1]',  N'nvarchar(3)'))
		left join CASES CS        on (CS.CASEID      =RC.value(N'RELATEDCASEID[1]',N'int'))
		where (C.COUNTRYCODE is not null OR RC.value(N'COUNTRYCODE[1]',  N'nvarchar(3)') is null)
		and   (CS.CASEID     is not null OR RC.value(N'RELATEDCASEID[1]',N'int')         is null)

		Select  @nErrorCode=@@ERROR,
			@nRowCount=@@ROWCOUNT

		--------------------------------
		-- If rows have been loaded into 
		-- the temporary table then move
		-- them to the live table one 
		-- row at a time.
		--------------------------------
		Set @nRowNumber=1
		
		While @nRowNumber<=@nRowCount
		and   @nErrorCode=0
		Begin
			select	@sRelationship =RELATIONSHIP,
				@nRelatedCaseId=RELATEDCASEID,
				@sOfficialNo   =OFFICIALNUMBER,
				@sCountryCode  =COUNTRYCODE,
				@dtPriorityDate=PRIORITYDATE
			from #TEMPRELATEDCASE_API
			where RELATIONSHIPNO=@nRowNumber
			
			Set @nErrorCode=@@ERROR
			
			If @nErrorCode=0
			Begin
				insert into #TEMPRESULT(RelationshipNo)		-- This is being used to capture result from procedure call. It is not used anywhere
				exec @nErrorCode=csw_InsertRelatedCase 
						@pnUserIdentityId         =@pnUserIdentityId,
						@pnCaseKey                =@pnCaseId,
						@psRelationshipCode       =@sRelationship,
						@pnRelatedCaseKey         =@nRelatedCaseId,
						@psOfficialNumber         =@sOfficialNo,
						@psCountryCode            =@sCountryCode,
						@pdtEventDate             =@dtPriorityDate,
						@pbIsRelationshipCodeInUse=1,
						@pbIsRelatedCaseKeyInUse  =1,
						@pbIsOfficialNumberInUse  =1,
						@pbIsCountryCodeInUse     =1,
						@pbIsEventDateInUse       =1
			End

			set @nRowNumber=@nRowNumber+1
		End
		
		If  @nRowCount>0
		and @nErrorCode=0
		Begin
			-------------------------------------------
			-- Once the Related Cases have been loaded
			-- check to see if there are any CaseEvents
			-- to be created
			-------------------------------------------
			exec @nErrorCode=dbo.cs_UpdatePriorityEvents
						@pnUserIdentityId	=@pnUserIdentityId,	
						@pnCaseKey		=@pnCaseId
		End
	End

	---------------------------
	-- Insert into CASETEXT
	-- for Remarks
	---------------------------
	if @nErrorCode = 0
	and @psRemarks is not null
	begin
		insert into 	CASETEXT
			(	CASEID,
				TEXTTYPE,
				TEXTNO,
				MODIFIEDDATE,
				LONGFLAG,
				SHORTTEXT
			)
		values	(	@pnCaseId,
				'R',
				0,
				getdate(),
				0,
				@psRemarks
			)

		Set @nErrorCode = @@ERROR
	end
	
	------------------------------
	-- Insert into TABLEATTRIBUTES
	------------------------------
	If @nErrorCode=0
	and @pxTableAttributes is not null
	Begin
		insert into 	TABLEATTRIBUTES
			(	PARENTTABLE,
				GENERICKEY,
				TABLECODE,
				TABLETYPE
			)
		
		select	'CASES'						as ParentTale,
			cast(@pnCaseId as nvarchar(20))			as CaseId,	
			T.value(N'TABLECODE[1]',N'int')			as TableCode,
			TC.TABLETYPE					as TableType
		from @pxTableAttributes.nodes(N'/TableAttributes/TableAttribute') TABLEATTRIBUTES(T)
		join TABLECODES TC on (TC.TABLECODE=T.value(N'TABLECODE[1]',N'int'))

		Set @nErrorCode=@@ERROR
	End
	
	----------------------------------------
	-- Commit or Rollback the transaction
	-- This will save the basic Case details
	-- to the database
	----------------------------------------
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

----------------------------------------------------
-- Insertion of Names against the Case will be done
-- using the Global Name Change functionality. This
-- will automatically handle Name Type inheritance
-- if required.
-- NOTE: No database transaction is used from this
--	 procedure because the Global Name Change 
--	 provides its own TRANSACTION and COMMIT.
----------------------------------------------------
If @nErrorCode=0
and @pnCaseId is not null
and @pbNameInheritance=1
Begin
	If @nErrorCode=0
	and (@pnInstructor  is not null
	 OR  @pnStaffMember is not null
	 OR  @pnSignatory   is not null
	 OR  @pxCaseNames   is not null)
	Begin
		---------------------------------------------------
		-- If any Name is to be inserted against the Case
		-- then we will require a default version of the 
		-- Case program to determine what other Name Types
		-- might default for this Case based on inheritance
		-- rules defined against those Name Types.
		---------------------------------------------------
		Select @sProgramId=left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8)
		from SITECONTROL S
		     join USERIDENTITY U        on (U.IDENTITYID=@pnUserIdentityId)
		left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=U.PROFILEID
						and PA.ATTRIBUTEID=2)	-- Default Cases Program
		where S.CONTROLID='Case Screen Default Program'

		Set @nErrorCode=@@ERROR

		------------------------------------------------
		-- Get the HomeNameNo from the Site Control
		-- as this can be used in Name inheritance rules
		------------------------------------------------
		If @nErrorCode=0
		Begin
			Select @nHomeNameNo=COLINTEGER
			from SITECONTROL
			where CONTROLID='HOMENAMENO'

			Set @nErrorCode=@@ERROR
		End

		-----------------------------------
		-- Load the CASEID into a temporary
		-- table for use by the global name
		-- change procedure.
		-----------------------------------
		If @nErrorCode=0
		Begin
			insert into #TEMPCASES_API(CASEID) values(@pnCaseId)

			Set @nErrorCode=@@ERROR
		End
	End
	-----------------------
	-- Insert into CASENAME
	-- 1) Instructor
	-----------------------

	if @nErrorCode = 0
	and @pnInstructor is not null
	begin
		exec @nErrorCode=dbo.cs_GlobalNameChange
				@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
				@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
				@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
				@pnUserIdentityId	=@pnUserIdentityId,
				-- Filter Parameters
				@psGlobalTempTable	='#TEMPCASES_API',
				@psProgramId		= @sProgramId,
				@psNameType		= 'I',
				-- Change Details
				@pnNewNameNo		= @pnInstructor,
				-- Options
				@pbUpdateName		= 0,
				@pbInsertName		= 1,		-- indicates that the Name is to be inserted
				@pbApplyInheritance	= 1,
				@pbSuppressOutput	= 1,
				@pnHomeNameNo		= @nHomeNameNo
	end

	-----------------------
	-- Insert into CASENAME
	-- 2) Staff Member
	-----------------------
	if @nErrorCode = 0
	and @pnStaffMember is not null
	begin
		exec @nErrorCode=dbo.cs_GlobalNameChange
				@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
				@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
				@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
				@pnUserIdentityId	=@pnUserIdentityId,
				-- Filter Parameters
				@psGlobalTempTable	='#TEMPCASES_API',
				@psProgramId		= @sProgramId,
				@psNameType		= 'EMP',
				-- Change Details
				@pnNewNameNo		= @pnStaffMember,
				-- Options
				@pbUpdateName		= 0,
				@pbInsertName		= 1,		-- indicates that the Name is to be inserted
				@pbApplyInheritance	= 1,
				@pbSuppressOutput	= 1,
				@pnHomeNameNo		= @nHomeNameNo
	end

	-----------------------
	-- Insert into CASENAME
	-- 3) Staff Signatory
	-----------------------
	if @nErrorCode = 0
	and @pnSignatory is not null
	begin
		exec @nErrorCode=dbo.cs_GlobalNameChange
				@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
				@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
				@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
				@pnUserIdentityId	=@pnUserIdentityId,
				-- Filter Parameters
				@psGlobalTempTable	='#TEMPCASES_API',
				@psProgramId		= @sProgramId,
				@psNameType		= 'SIG',
				-- Change Details
				@pnNewNameNo		= @pnSignatory,
				-- Options
				@pbUpdateName		= 0,
				@pbInsertName		= 1,		-- indicates that the Name is to be inserted
				@pbApplyInheritance	= 1,
				@pbSuppressOutput	= 1,
				@pnHomeNameNo		= @nHomeNameNo
	end
	
	------------------------------
	-- Additional CASENAME rows 
	-- will need to be loaded into
	-- a temporary table so that 
	-- each row can then be used
	-- with the Global Name Change
	-- functionality.
	------------------------------
	If @nErrorCode=0
	and @pxCaseNames is not null
	Begin
		
		insert into #TEMPCASENAME_API
			(	CASEID,
				NAMETYPE,
				NAMENO,
				SEQUENCE,
				CORRESPONDNAME,
				ADDRESSCODE,
				REFERENCENO
			)
		select	@pnCaseId					as CaseId,
			CN.value(N'NAMETYPE[1]',     N'nvarchar(3)')	as NameType,
			CN.value(N'NAMENO[1]',       N'int')		as NameNo,
			CN.value(N'SEQUENCE[1]',     N'smallint')	as Sequence,
			CN.value(N'CORESPONDNAME[1]',N'int')		as CorrespondName,
			CN.value(N'ADDRESSCODE[1]',  N'int')		as AddressCode,
			CN.value(N'REFERENCENO[1]',  N'nvarchar(80)')	as ReferenceNo
		from @pxCaseNames.nodes(N'/CaseNames/CaseName') CaseName(CN)
		     join NAMETYPE NT  on (NT.NAMETYPE  =CN.value(N'NAMETYPE[1]',     N'nvarchar(3)'))
		     join NAME N1      on (N1.NAMENO    =CN.value(N'NAMENO[1]',       N'int'))
		left join NAME N2      on (N2.NAMENO    =CN.value(N'CORESPONDNAME[1]',N'int'))
		left join ADDRESS A    on (A.ADDRESSCODE=CN.value(N'ADDRESSCODE[1]',  N'int'))
		left join CASENAME CN1 on (CN1.CASEID=@pnCaseId
		                       and CN1.NAMETYPE=CN.value(N'NAMETYPE[1]',     N'nvarchar(3)') )
		where (N2.NAMENO     is not null OR CN.value(N'CORESPONDNAME[1]',N'int') is null)
		and   (A.ADDRESSCODE is not null OR CN.value(N'ADDRESSCODE[1]',  N'int') is null)
		and  CN1.CASEID is null -- To ensure a CaseName for the NameType has not already been inserted
		order by 2, 4

		Select @nErrorCode=@@ERROR,
		       @nRowCount =@@ROWCOUNT
	End
	
	Set @nRowNumber=1
	---------------------------------------
	-- Now loop through each additional row
	-- and extract the details to use with 
	-- the global name change
	---------------------------------------
	While @nRowNumber<=@nRowCount
	Begin
		select	@sNameType   = NAMETYPE,
			@nNameNo     = NAMENO,
			@nAttention  = CORRESPONDNAME,
			@nAddressCode= ADDRESSCODE,
			@sReferenceNo= REFERENCENO
		from #TEMPCASENAME_API
		where ROWSEQUENCE= @nRowNumber
		
		exec @nErrorCode=dbo.cs_GlobalNameChange
				@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
				@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
				@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
				@pnUserIdentityId	=@pnUserIdentityId,
				-- Filter Parameters
				@psGlobalTempTable	='#TEMPCASES_API',
				@psProgramId		= @sProgramId,
				@psNameType		= @sNameType,
				-- Change Details
				@pnNewNameNo		= @nNameNo,
				@pnNewCorrespondName	= @nAttention,
				-- Options
				@pbUpdateName		= 0,
				@pbInsertName		= 1,		-- indicates that the Name is to be inserted
				@pbApplyInheritance	= 1,
				@psReferenceNo		= @sReferenceNo,
				@pbSuppressOutput	= 1,
				@pnAddressCode		= @nAddressCode,
				@pnHomeNameNo		= @nHomeNameNo
				
		Set @nRowNumber = @nRowNumber + 1
	
	End
End
----------------------------------------------------
-- Commence a new database transaction to continue
-- creation of other Case details that may be slower
-- to process.  This is done outside of the main
-- transaction to reduce the locks held on the 
-- database.
----------------------------------------------------
If @nErrorCode=0
and @pnCaseId is not null
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-------------------------------------------------------------
	-- Call a stored procedure to get the IRN to use for the Case
	-- The procedure will actually update the CASES row.
	-------------------------------------------------------------
	If @psCaseReference='<Generate Reference>'
	Begin
		exec @nErrorCode=dbo.cs_ApplyGeneratedReference
						@psCaseReference =@psCaseReference	OUTPUT,
						@pnUserIdentityId=@pnUserIdentityId,
						@pnCaseKey	 =@pnCaseId
	End

	------------------------------
	-- Create Key Words from Title
	------------------------------
	if @nErrorCode = 0
	and @psTitle is not null
	begin
		exec @nErrorCode = dbo.cs_InsertKeyWordsFromTitle 
					@nCaseId = @pnCaseId	
	end

	-- --------------------------------
	-- Prepare policing to open Action	
	if @nErrorCode = 0
	begin
		select 	@sInterimAction = COLCHARACTER 
		from 	SITECONTROL 
		where 	CONTROLID = 'Interim Case Action'

		set @nErrorCode = @@error
	end

	if @nErrorCode = 0
	and @sInterimAction is not null
	begin

		Exec @nErrorCode = ip_InsertPolicing
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= default,
			@psCaseKey		= @pnCaseId,
			@psAction		= @sInterimAction, 
			@pnTypeOfRequest	= 1,
			@pnPolicingBatchNo	= default
	end

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

return @nErrorCode
go

grant execute on dbo.api_InsertCase to public
go
