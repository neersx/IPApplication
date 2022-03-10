-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_InsertCase.'
	drop procedure [dbo].[cs_InsertCase]
	print '**** Creating Stored Procedure dbo.cs_InsertCase...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE procedure dbo.cs_InsertCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psCaseKey			nvarchar(11)	output,	-- CaseId:int
	@psCaseReference		nvarchar(30)	= '<Generate Reference>', -- IRN
	@psStem 			nvarchar(30)	= null,	-- Cases.Stem 
	@pnOfficeKey			int		= null, -- Cases.OfficeId
	@psCaseFamilyReference 		nvarchar(20) 	= null,	
	@psCaseTypeKey			nvarchar(1)	= null,
	@psCaseTypeDescription		nvarchar(50)	= null, -- not being used at present 
	@psCountryKey			nvarchar(3) 	= null,	
	@psCountryName			nvarchar(60)	= null, -- not being used at present 
	@psPropertyTypeKey		nvarchar(1) 	= null,
	@psPropertyTypeDescription	nvarchar(50)	= null, -- not being used at present 
	@psCaseCategoryKey 		nvarchar(2) 	= null, 
	@psCaseCategoryDescription	nvarchar(20)	= null, -- not being used at present 
	@psSubTypeKey			nvarchar(2) 	= null, 
	@psSubTypeDescription		nvarchar(50)	= null, -- not being used at present
	@psStatusKey			nvarchar(10)	= null,	-- StatusCode:smallint
	@psStatusDescription		nvarchar(50)	= null, -- not being used at present 
	@psShortTitle			nvarchar(254)	= null,
	@pbReportToThirdParty		bit		= null,
	@pnNoOfClaims			int		= null,
	@pnNoInSeries			int		= null,
	@psEntitySizeKey		nvarchar(11)	= null, -- EntitySize:int
	@psEntitySizeDescription	nvarchar(80)	= null, -- not used at present
	@psFileLocationKey		nvarchar(11)	= null, -- not used at present CasesLocation.FileLocation??
	@psFileLocationDescription	nvarchar(80)	= null, -- not used at present
	@psStopPayReasonKey		nvarchar(1)	= null,
	@psStopPayReasonDescription	nvarchar(80)	= null, -- not used at present
	@psTypeOfMarkKey		nvarchar(11) 	= null,	-- @pnTypeOfMark:int
	@psTypeOfMarkDescription	nvarchar(80)	= null, -- not used at present
	@pdtInstructionsReceivedDate	datetime	= null,
	@psApplicationBasisKey		nvarchar(2)	= null,	-- RFC005
	@psApplicationBasisDescription	nvarchar(50)	= null, -- RFC005 not used at present
	@pbIsLocalClient		bit		= null, -- RFC005
	@pbIsUseByOwner			bit		= null, -- RFC005
	@pbIsUseByOthers		bit		= null, -- RFC005
	@pnExaminationTypeKey		int		= null, -- RFC085
	@psExaminationTypeDescription	nvarchar(80)	= null, -- RFC085  not used at present
	@pnRenewalTypeKey		int		= null, -- RFC085
	@psRenewalTypeDescription	nvarchar(80)	= null, -- RFC085  not used at present
	@pnPolicingBatchNo		int		= null -- RFC084

)
-- PROCEDURE :	cs_InsertCase
-- VERSION :	30
-- DESCRIPTION:	See CaseData.doc

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 12 JUL 2002	JB			Procedure created
-- 15 JUL 2002	SF			Added nErrorCode and Call SP to generate Case Reference
-- 25 JUL 2002	SF			1. 	Change ErrorHandling method
--					2.	Perform Policing Immediately if Site Control Police Immediately says so.
-- 28 JUL 2002	SF			Fix SQLUser
-- 05 AUG 2002	SF			Use cs_InsertKeyWordsFromTitle
-- 05 AUG 2002	SF			Use cs_InsertFileLocation
-- 23 OCT 2002	JB		12	Implemented row level security
-- 23 OCT 2002	JB		13	Minor bug fixed
-- 23 OCT 2002	JB		14	Backed out row level security
-- 08 NOV 2002	JEK		15	Instructions Received date was not being defaulted
-- 12 FEB 2003	SF		16	RFC005 - Implement ApplicationBasisKey, IsLocalClient, IsUseByOwner, IsUseByOthers
-- 03 Mar 2003	SF		17	RFC073 - Change to work with Case Sensitive Server
-- 17 Mar 2003	SF		18	RFC084 - Change to work with new ip_InsertPolicing
--					RFC085 - Implement ExaminationTypeKey, RenewalTypeKey
-- 20 MAY 2003  TM      	21      RFC179 - Name Code and Case Family Case Sensitivity
-- 11 JUL 2003	TM		22	RFC26  - Remove the call to cs_GenerateCaseReference.  Save any NumericStem provided by the user. 
-- 11 AUG 2003	TM		23	RFC224 - Office level rules. Add a new @pnOfficeKey parameter and write this to the CASES table.
-- 21 AUG 2003	TM		24	RFC26  - Case Ref Generation - stored procedure changes. Ensure that the @psCaseReference  
--					is written in the CASES.IRN in upper case (it should not be converted to upper case if
--					the @psCaseReference = '<Generate Reference>')
-- 10 MAR 2004	TM	RFC857	25	Strip off any leading and trailing spaces from the @psCaseReference before inserting it into 
--					the CASES table.	
-- 24 May 2005	TM	RFC1990	26	Increase @psStem parameter from 12 to 30.
-- 25 May 2005	TM	RFC1990	27	Convert the stem to upper case before inserting into the database.
-- 07 Jul 2005	TM	RFC2329	28	Increase the size of all case category parameters and local variables to 2 characters.
-- 24 Oct 2011	ASH	R11460  29	Cast integer columns as nvarchar(11) data type.
-- 15 Apr 2013	DV	R13270	30	Increase the length of nvarchar to 11 when casting or declaring integer

as
begin
	SET CONCAT_NULL_YIELDS_NULL OFF		-- just to make sure!

	declare @nErrorCode int
	declare @nCaseId int
	declare @sInterimAction nvarchar(254)

	set @nErrorCode = 0
	set @psCaseFamilyReference = upper(@psCaseFamilyReference)	--Ensure case family reference is upper case

	-- Ensure that @psCaseReference is in upper case if @psCaseReference <> '<Generate Reference>'

	If @psCaseReference<>'<Generate Reference>'
	Begin
		Set @psCaseReference = upper(@psCaseReference) 
	End 

	-- -----------------
	-- Create Family
	If @psCaseFamilyReference is not null
		If not exists(SELECT * FROM [CASEFAMILY] 
				WHERE [FAMILY] = @psCaseFamilyReference)
			INSERT INTO [CASEFAMILY]
				(	[FAMILY] 
				)
			VALUES 	( 	@psCaseFamilyReference 
				)

	set @nErrorCode = @@error

	-- -------------------
	-- Create Parent

	if @nErrorCode = 0
	begin
		update 	[LASTINTERNALCODE]
		set 	[INTERNALSEQUENCE] = [INTERNALSEQUENCE] + 1,
			@nCaseId = [INTERNALSEQUENCE] + 1
		from	[LASTINTERNALCODE]		
		where 	[TABLENAME] = 'CASES'

		set @nErrorCode = @@error
	end

	if @nErrorCode = 0
	begin
		insert into 	[CASES]
			(	[CASEID],
				[IRN],
				[FAMILY],
				[STEM],
				[STATUSCODE],
				[CASETYPE],
				[PROPERTYTYPE],
				[COUNTRYCODE],
				[CASECATEGORY],
				[SUBTYPE],
				[TYPEOFMARK],
				[TITLE],
				[NOINSERIES],
				[ENTITYSIZE],
				[REPORTTOTHIRDPARTY],
				[STOPPAYREASON],
				[LOCALCLIENTFLAG],
				[OFFICEID]
			)
		values
			(	@nCaseId,
				ltrim(rtrim(@psCaseReference)),
				@psCaseFamilyReference,
				upper(@psStem),		
				Cast(@psStatusKey as smallint),
				@psCaseTypeKey,
				@psPropertyTypeKey,
				@psCountryKey,	
				@psCaseCategoryKey, 
				@psSubTypeKey, 
				Cast(@psTypeOfMarkKey as int),
				@psShortTitle,
				@pnNoInSeries,	
				cast(@psEntitySizeKey as int),
				@pbReportToThirdParty,
				@psStopPayReasonKey,
				@pbIsLocalClient,	-- RFC5
				@pnOfficeKey
			)

		set @nErrorCode = @@error
	end

	if @nErrorCode = 0
	begin
		set @psCaseKey = Cast(@nCaseId as nvarchar(11))
		
		set @nErrorCode = @@error
	end

	-- ------------------------
	-- Create Case Variations
	if @nErrorCode = 0
	and (	@pnNoOfClaims is not null 
	or	@pbIsUseByOwner is not null
	or	@pbIsUseByOthers is not null
	or	@psApplicationBasisKey is not null)
	begin
		
		insert into [PROPERTY]
			(	[CASEID],
				[NOOFCLAIMS],
				[BASIS],
				[REGISTEREDUSERS],
				[EXAMTYPE],
				[RENEWALTYPE]
			)
		values	
			(	@nCaseId,
				@pnNoOfClaims,
				@psApplicationBasisKey,
				case @pbIsUseByOwner 
					when 1 then case @pbIsUseByOthers 
							when 0 then 'N'
							when 1 then 'B'
							else null
						    end
					when 0 then case @pbIsUseByOthers
							when 1 then 'Y'
						    	else null
						    end
					else null
				end,
				@pnExaminationTypeKey,
				@pnRenewalTypeKey
			)

		set @nErrorCode = @@error	
	end

	-- -----------------------
	-- Create Title Key words
	if @nErrorCode = 0
	begin
		-- exec @nErrorCode = ipu_GenerateKeyWordsFromTitle @nCaseid = @nCaseId

		exec @nErrorCode = dbo.cs_InsertKeyWordsFromTitle @nCaseId = @nCaseId	
	end


	-- file location changes
	if @nErrorCode = 0
	begin		
		exec @nErrorCode = dbo.cs_InsertFileLocation 
			@pnUserIdentityId = @pnUserIdentityId,
 			@psCulture = @psCulture,
			@psCaseKey = @psCaseKey,
			@psFileLocationKey = @psFileLocationKey
	end

	-- ------------------------
	-- Create Events
	-- 1) Date of Entry - again we may want to replace with another SP
	if @nErrorCode = 0
	begin
		insert into 	[CASEEVENT]
			(	[CASEID],
				[EVENTNO],
				[EVENTDATE],
				[CYCLE],
				[DATEDUESAVED],
				[OCCURREDFLAG]
			)
		values		
			(	@nCaseId,
				-13,
				dbo.fn_DateOnly(GETDATE()),  -- this needs to be date only!
				1,
				0,
				1
			)

		set @nErrorCode = @@error
	end

	-- 2) Instructions Received
	if @nErrorCode = @@error
	begin
		insert into 	[CASEEVENT]
			(	[CASEID],
				[EVENTNO],
				[EVENTDATE],
				[CYCLE],
				[DATEDUESAVED],
				[OCCURREDFLAG]
			)
		values	(	@nCaseId,
				-16,
				dbo.fn_DateOnly(isnull(@pdtInstructionsReceivedDate,GETDATE())),
				1,
				0,
				1
			)
	
		set @nErrorCode = @@error
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
			@psCulture		= @psCulture,
			@psCaseKey		= @psCaseKey,
			@psAction		= @sInterimAction, 
			@pnTypeOfRequest	= 1,
			@pnPolicingBatchNo	= @pnPolicingBatchNo
	end
	return @nErrorCode

end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_InsertCase to public
go
