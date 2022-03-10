-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertRelatedCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertRelatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_InsertRelatedCase.'
	drop procedure [dbo].[cs_InsertRelatedCase]
	print '**** Creating Stored Procedure dbo.cs_InsertRelatedCase...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_InsertRelatedCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,  	
	@psCaseKey			varchar(11) 	= null, 
	@pnRelationshipSequence		int 	= null	output,
	@psRelationshipKey		varchar(3) 	= null,
	@psRelationshipDescription	varchar(50) 	= null,
	@psRelatedCaseKey		varchar(11) 	= null,
	@psRelatedCaseReference		nvarchar(20) 	= null,
	@psCaseFamilyReference 		nvarchar(20) 	= null,	
	@psCountryKey			nvarchar(3) 	= null,
	@psCountryName			nvarchar(60) 	= null,
	@psOfficialNumber		nvarchar(36) 	= null,
	@psPropertyTypeDescription	nvarchar(50) 	= null,
	@psCaseTypeDescription		nvarchar(50) 	= null,
	@psCaseCategoryKey 		nvarchar(2) 	= null, 
	@psCaseCategoryDescription	nvarchar(20)	= null, -- not being used at present 
	@psStatusDescription		nvarchar(50) 	= null,
	@pbCreateReciprocal		bit		= 1,	-- Create reciprocal by default
	@pbProcessPriorityEvent		bit	= null output	-- only process this when there is an eventno against the reciprocal relationship
)

-- PROCEDURE :	cs_InsertRelatedCase
-- VERSION :	18
-- DESCRIPTION:	Adds a row 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14/07/2002	JB			Function created
-- 17/07/2002	SF			Remove the output param
-- 25/07/2002	SF			1. Change Error Handling method.
--					2. Fix SequenceNo generation routine.
-- 26/07/2002	JB			Added reciprocal
-- 01/08/2002	JB			Make add reciprocal optional
-- 07/08/2002	SF			priority event
-- 08/08/2002	SF			Related Case row should only have either RELATEDCASEID or COUNTRYCODE, not both.
-- 15/04/2005	TM	RFC2514	14	Priority processing should only be performed when the case related event 
--						is not read only.
-- 07/07/2005	TM	RCF2329	15	Increase the size of all case category parameters and local variables to 2 characters.
-- 24 Jul 2009	MF	16548		16	FROMEVENTNO needs to be not null to allow priority processing to occur.
-- 11 Nov 2011	LP	R11460		17	Extend CaseKey and RelatedCaseKey to nvarchar(11)

-- 25 Nov 2011	ASH	R100640	18	Change the size of Case Key and Related Case key to 11.
as
begin
	Declare @nErrorCode int
	Set @nErrorCode = 0
	
	-- --------------
	-- Sort Out Data
	-- Minimum:
	If @psRelatedCaseKey is null or @psRelatedCaseKey = ''	
		Set @nErrorCode = -1
	
	-- Default data:
	If (@psRelationshipKey is null or @psRelationshipKey = '')
		Set @psRelationshipKey = 'REL'
	
	Declare @nCaseId int
	Set @nCaseId = Cast(@psCaseKey as int)
	
	
	
	-- -------------------------
	-- Get the next sequence no
	If @nErrorCode = 0
	Begin
		Select @pnRelationshipSequence = isnull(MAX([RELATIONSHIPNO])+1, 0)
			from [RELATEDCASE]
			where CASEID = @nCaseId
		
		Set @nErrorCode = @@error
	End
	
	-- ---------------------
	-- Create Relationship
	If @nErrorCode = 0
	Begin
		Insert into RELATEDCASE
			(
				CASEID,
				RELATIONSHIP,
				RELATEDCASEID,
				RELATIONSHIPNO,
				COUNTRYCODE,
				OFFICIALNUMBER
			)
			values
			(
				@nCaseId,
				@psRelationshipKey,
				@psRelatedCaseKey,
				@pnRelationshipSequence,
				@psCountryKey,
				@psOfficialNumber
			)
		Set @nErrorCode = @@error
	End
	
	-- ------------------
	-- Create reciprocal Relationship if necessary
	If 	@nErrorCode = 0
	and 	@pbCreateReciprocal = 1	
	Begin
		Declare @sReciprocalRelationship nvarchar(3)
		Select @sReciprocalRelationship = VR.RECIPRELATIONSHIP
			from CASES C
			join VALIDRELATIONSHIPS VR 
				on (VR.RELATIONSHIP = @psRelationshipKey
				and VR.PROPERTYTYPE = C.PROPERTYTYPE
				and VR.COUNTRYCODE = 
				( select min( VR1.COUNTRYCODE )
					from VALIDRELATIONSHIPS VR1
					where VR1.COUNTRYCODE in ( 'ZZZ', C.COUNTRYCODE ) 
					and VR1.PROPERTYTYPE=C.PROPERTYTYPE
					and VR1.RELATIONSHIP = VR.RELATIONSHIP ) )
			where C.CASEID = @nCaseId
	
		If @sReciprocalRelationship is not null
		Begin
			Select @pnRelationshipSequence = isnull(MAX([RELATIONSHIPNO])+1, 0)
				from [RELATEDCASE]
				where CASEID = CAST(@psRelatedCaseKey as int)
	
			Insert into RELATEDCASE
				(
					CASEID,
					RELATIONSHIP,
					RELATEDCASEID,
					RELATIONSHIPNO
					
				)
				values
				(
					@psRelatedCaseKey,
					@sReciprocalRelationship,
					@nCaseId,
					@pnRelationshipSequence
					
				)
			
			Set @nErrorCode = @@error		

			if @nErrorCode = 0
			and exists(	select 1 
					from 	CASERELATION 
					where 	RELATIONSHIP = @sReciprocalRelationship 
					and 	EVENTNO is not null
					and	FROMEVENTNO is not null
				   )
			begin
				set @pbProcessPriorityEvent = 1				
			end

		End

		
	End
	RETURN @nErrorCode
end
go

grant execute on dbo.cs_InsertRelatedCase to public
go
