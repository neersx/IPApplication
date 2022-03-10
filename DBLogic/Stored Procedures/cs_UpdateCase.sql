-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_UpdateCase.'
	Drop procedure [dbo].[cs_UpdateCase]
	Print '**** Creating Stored Procedure dbo.cs_UpdateCase...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_UpdateCase
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture				nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey				varchar(11) = null, 
	@psCaseReference			nvarchar(30)	= null,	-- IRN
	@pnOfficeKey				int		= null, -- Cases.OfficeId
	@psCaseFamilyReference 			nvarchar(20) 	= null,	
	@psCaseTypeKey				nvarchar(1)	= null,
	@psCaseTypeDescription			nvarchar(50)	= null, -- not being used at present 
	@psCountryKey				nvarchar(3) 	= null,	
	@psCountryName				nvarchar(60)	= null, -- not being used at present 
	@psPropertyTypeKey			nvarchar(1) 	= null,
	@psPropertyTypeDescription		nvarchar(50)	= null, -- not being used at present 
	@psCaseCategoryKey 			nvarchar(2) 	= null, 
	@psCaseCategoryDescription		nvarchar(20)	= null, -- not being used at present 
	@psSubTypeKey				nvarchar(2) 	= null, 
	@psSubTypeDescription			nvarchar(50)	= null, -- not being used at present
	@psStatusKey				nvarchar(10)	= null,	-- StatusCode:smallint
	@psStatusDescription			nvarchar(50)	= null, -- not being used at present 
	@psShortTitle				nvarchar(254)	= null,
	@pbReportToThirdParty			bit		= null,
	@pnNoOfClaims				int		= null,
	@pnNoInSeries				int		= null,
	@psEntitySizeKey			nvarchar(11)	= null, -- EntitySize:int
	@psEntitySizeDescription		nvarchar(80)	= null, -- not used at present
	@psFileLocationKey			nvarchar(11)	= null, -- not used at present CasesLocation.FileLocation??
	@psFileLocationDescription		nvarchar(80)	= null, -- not used at present
	@psStopPayReasonKey			nvarchar(1)	= null,
	@psStopPayReasonDescription		nvarchar(80)	= null, -- not used at present
	@psTypeOfMarkKey			nvarchar(11) 	= null,	-- @pnTypeOfMark:int
	@psTypeOfMarkDescription		nvarchar(80)	= null, -- not used at present
	@pdtInstructionsReceivedDate		datetime	= null,
	@psApplicationBasisKey			nvarchar(2)	= null,	-- RFC005
	@psApplicationBasisDescription		nvarchar(50)	= null, -- RFC005 not used at present
	@pbIsLocalClient			bit		= null, -- RFC005
	@pbIsUseByOwner				bit		= null, -- RFC005
	@pbIsUseByOthers			bit		= null, -- RFC005
	@pnPolicingBatchNo			int		= null, -- RFC084
	@pnExaminationTypeKey			int		= null, -- RFC085
	@psExaminationTypeDescription		nvarchar(80)	= null, -- RFC085  not used at present
	@pnRenewalTypeKey			int		= null, -- RFC085
	@psRenewalTypeDescription		nvarchar(80)	= null, -- RFC085  not used at present

	@pbCaseReferenceModified		bit	= null,
	@pbOfficeModified			bit	= null, -- RFC224
	@pbCaseFamilyReferenceModified 		bit 	= null,	
	@pbCaseTypeKeyModified			bit	= null,
	@pbCaseTypeDescriptionModified		bit	= null,
	@pbCountryKeyModified			bit 	= null,	
	@pbCountryNameModified			bit	= null,
	@pbPropertyTypeKeyModified		bit 	= null,
	@pbPropertyTypeDescriptionModified	bit	= null, 
	@pbCaseCategoryKeyModified 		bit 	= null, 
	@pbCaseCategoryDescriptionModified	bit	= null, 
	@pbSubTypeKeyModified			bit 	= null, 
	@pbSubTypeDescriptionModified		bit	= null, 
	@pbStatusKeyModified			bit	= null,	
	@pbStatusDescriptionModified		bit	= null, 
	@pbShortTitleModified			bit	= null,
	@pbReportToThirdPartyModified		bit	= null,
	@pbNoOfClaimsModified			int	= null,
	@pbNoInSeriesModified			int	= null,
	@pbEntitySizeKeyModified		bit	= null,
	@pbEntitySizeDescriptionModified	bit	= null,
	@pbFileLocationKeyModified		bit	= null,
	@pbFileLocationDescriptionModified	bit	= null,
	@pbStopPayReasonKeyModified		bit	= null,
	@pbStopPayReasonDescriptionModified	bit	= null, 
	@pbTypeOfMarkKeyModified		bit 	= null,	
	@pbTypeOfMarkDescriptionModified	bit	= null, 
	@pbInstructionsReceivedDateModified	bit	= null,
	@pbApplicationBasisKeyModified		bit	= null,	-- RFC5
	@pbIsLocalClientModified		bit	= null, -- RFC5
	@pbIsUseByOwnerModified			bit	= null, -- RFC5
	@pbIsUseByOthersModified		bit	= null, -- RFC5
	@pbExaminationTypeKeyModified		bit	= null, -- RFC85
	@pbExaminationTypeDescriptionModified	bit	= null, -- RFC85
	@pbRenewalTypeKeyModified		bit 	= null, -- RFC85
	@pbRenewalTypeDescriptionModified	bit	= null, -- RFC85

	@psOriginalShortTitle			nvarchar(254) = null,
	@psOriginalCaseFamilyReference		nvarchar(20) = null,
	@psOriginalFileLocationKey		nvarchar(11) = null

)

-- PROCEDURE :	cs_UpdateCase
-- VERSION :	21
-- DESCRIPTION:	updates a row 

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 JUL 2002	SF			Stub created
-- 05 AUG 2002	SF			Procedure created
-- 05 AUG 2002	SF			Add policing steps
-- 07 AUG 2002	SF			Some minor fixes on file locations.
-- 08 AUG 2002	SF			CPAReportable and Entitysize is not saving correctly.
-- 23 OCT 2002	JB		6	Implemented row level security
-- 23 OCT 2002	JB		7	Backed out row level security - to be in DAL
-- 12 FEB 2003	SF		8	RFC005 - Implement ApplicationBasisKey, IsLocalClient, IsUseByOwner, IsUseByOthers
-- 06 MAR 2003	JEK		10	RFC005 - Recalculate open actions when the best fit criteria changes.
-- 17 MAR 2003	SF		11	RFC084 - 1. Add @pnPolicingBatchNo
--					 	2. Change to work with new ip_InsertPolicing
--					RFC085 - Implement RenewalTypeKey, ExaminationTypeKey
-- 21 MAR 2003	JEK		12	RFC003 - Implement cs_UpdateStatuses.
-- 22 MAY 2003  TM      	13      RFC179 - Name Code and Case Family Case Sensitivity
-- 11 AUG 2003  TM		14	RFC224 - Office level rules. Add new @pnOfficeKey and @pbOfficeModified parameters, 
--					write the @pnOfficeKey to the CASES table, and recalculate open actions if the Office 
--					has changed.
-- 21 AUG 2003	TM		15	RFC26  - Case Ref Generation - stored procedure changes. Change @psCaseReference 
-- 					parameter datatype from nvarchar(20) to nvarchar(30). Ensure that the @psCaseReference
--					is written in the CASES.IRN in upper case (it should not be converted to upper case if
--					the @psCaseReference = '<Generate Reference>')
-- 25 Sep 2003	TM		16	RFC412 - Case Status field is not consistant with Improma. Call cs_UpdateStatuses if 
--					the @psStatusKey is not null, otherwise update CASES.STATUSCODE to null.
-- 10 Mar 2004	TM	RFC857	17	Strip off any leading and trailing spaces from the @psCaseReference before updating 
--					CASES.IRN with its value.
-- 07 Jul 2005	TM	RFC2329	18	Increase the size of all case category parameters and local variables to 2 characters.
-- 07 Jul 2011	DL	R10830	19	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 15 Apr 2013	DV	R13270	20	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Aug 2016	MF	64248	21	CaseEvent for EventNo -14 will now be updated by database trigger so no need to perform this directly.

as
begin
	declare @nErrorCode int
	declare @nCaseId int
	declare @dtDateEntered datetime
	declare @nPolicingSeqNo int
	declare @bOnHoldFlag int
	declare @nRowCount int
	declare @nCounter int
	declare @sAction nvarchar(2)
	declare @nCycle int
	declare @nStatusKey smallint

	set @nCaseId = cast(@psCaseKey as int)
	set @nErrorCode = @@error
	set @psCaseFamilyReference = upper(@psCaseFamilyReference)	--Ensure case family reference is upper case

	-- Ensure that @psCaseReference is in upper case if @psCaseReference <> '<Generate Reference>'

	If @psCaseReference<>'<Generate Reference>'
	Begin
		Set @psCaseReference = upper(@psCaseReference) 
	End  

	if @nErrorCode = 0
	and @pbCaseFamilyReferenceModified = 1
	begin
		-- Create Family if necessary
		if @psCaseFamilyReference is not null
		and not exists(select * from CASEFAMILY where FAMILY = @psCaseFamilyReference)
		begin
			insert into CASEFAMILY (FAMILY, FAMILYTITLE)
			values (@psCaseFamilyReference, null)

			set @nErrorCode = @@error
		end 
	end
	
	-- Update Parent
	if @nErrorCode = 0
	and (	@pbCaseReferenceModified = 1
	or	@pbOfficeModified = 1
	or 	@pbCaseFamilyReferenceModified = 1
	or 	@pbCaseTypeKeyModified = 1
	or	@pbCountryKeyModified = 1
	or	@pbPropertyTypeKeyModified = 1
	or	@pbCaseCategoryKeyModified = 1
	or	@pbSubTypeKeyModified = 1
	or	@pbShortTitleModified = 1
	or	@pbNoInSeriesModified = 1
	or	@pbStopPayReasonKeyModified = 1
	or	@pbTypeOfMarkKeyModified = 1
	or 	@pbReportToThirdPartyModified = 1
	or 	@pbEntitySizeKeyModified = 1
	or	@pbIsLocalClientModified = 1)
	begin
		update 	CASES
		set 	IRN = 		case when (@pbCaseReferenceModified=1) 	then ltrim(rtrim(@psCaseReference)) else IRN end,
			OFFICEID = 	case when (@pbOfficeModified=1)		then @pnOfficeKey else OFFICEID end, 
			FAMILY = 	case when (@pbCaseFamilyReferenceModified=1) then @psCaseFamilyReference else FAMILY end,
			CASETYPE = 	case when (@pbCaseTypeKeyModified=1) 	then @psCaseTypeKey else CASETYPE end,
			COUNTRYCODE = 	case when (@pbCountryKeyModified=1) 	then @psCountryKey else COUNTRYCODE end,
			PROPERTYTYPE = 	case when (@pbPropertyTypeKeyModified=1)then @psPropertyTypeKey else PROPERTYTYPE end,
			CASECATEGORY = 	case when (@pbCaseCategoryKeyModified=1)then @psCaseCategoryKey else CASECATEGORY end,
			SUBTYPE = 	case when (@pbSubTypeKeyModified=1) 	then @psSubTypeKey else SUBTYPE end,
			TITLE = 	case when (@pbShortTitleModified=1) 	then @psShortTitle else TITLE end,
			NOINSERIES = 	case when (@pbNoInSeriesModified=1) 	then @pnNoInSeries else NOINSERIES end,
			STOPPAYREASON = case when (@pbStopPayReasonKeyModified=1) then @psStopPayReasonKey else STOPPAYREASON end,
			TYPEOFMARK = 	case when (@pbTypeOfMarkKeyModified=1) 	then cast(@psTypeOfMarkKey as int) else TYPEOFMARK end,	
			REPORTTOTHIRDPARTY = case when (@pbReportToThirdPartyModified=1) then @pbReportToThirdParty else REPORTTOTHIRDPARTY end,
			ENTITYSIZE = case when (@pbEntitySizeKeyModified=1) then cast(@psEntitySizeKey as int) else ENTITYSIZE end,
			LOCALCLIENTFLAG = case when (@pbIsLocalClientModified=1) then @pbIsLocalClient else LOCALCLIENTFLAG end
		where	CASEID = @nCaseId

		set @nErrorCode = @@error
	end		

	-- Update Case Status
	if @nErrorCode = 0
	and	@pbStatusKeyModified = 1
	and	@psStatusKey is not null 
	begin
		Set @nStatusKey = cast(@psStatusKey as int)
		exec @nErrorCode = cs_UpdateStatuses
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psProgramID		= 'CPAStart',
			@pnCaseKey		= @nCaseId,
			@pnCaseStatus		= @nStatusKey
	end
	else if @nErrorCode = 0
	and	@pbStatusKeyModified = 1
	and	@psStatusKey is null
	begin
		Set @nStatusKey = cast(@psStatusKey as int)

		Update	CASES
		set STATUSCODE = @nStatusKey
		where CASEID = @nCaseId

		Set @nErrorCode = @@ERROR	
	end
	
	-- case family reference house keeping
	if @nErrorCode = 0
	and @pbCaseFamilyReferenceModified = 1
	begin 
		--Delete old Family if necessary
		if @nErrorCode = 0
		and @psOriginalCaseFamilyReference is not null
		and not exists(select * from CASES where FAMILY = @psOriginalCaseFamilyReference)
		begin
			-- housekeeping
			delete from CASEFAMILY
			where FAMILY = @psOriginalCaseFamilyReference

			set @nErrorCode =@@error
		end
	end

	-- property changes
	if @nErrorCode = 0
	and (	@pbNoOfClaimsModified = 1
	or  	@pbIsUseByOwnerModified = 1
	or	@pbIsUseByOthersModified = 1
	or	@pbApplicationBasisKeyModified = 1
	or 	@pbRenewalTypeKeyModified = 1
	or	@pbExaminationTypeKeyModified = 1)
	begin
		if exists(select * from PROPERTY where CASEID = @nCaseId)
		begin
			update	PROPERTY
			set	NOOFCLAIMS = case when @pbNoOfClaimsModified=1 then @pnNoOfClaims else NOOFCLAIMS end,
				BASIS = case when @pbApplicationBasisKeyModified=1 then @psApplicationBasisKey else BASIS end,
				REGISTEREDUSERS = case when (@pbIsUseByOthersModified=1 or @pbIsUseByOwnerModified=1) then
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
					end
				else 	REGISTEREDUSERS end,
				RENEWALTYPE = case when @pbRenewalTypeKeyModified=1 then @pnRenewalTypeKey else RENEWALTYPE end,
				EXAMTYPE = case when @pbExaminationTypeKeyModified=1 then @pnExaminationTypeKey else EXAMTYPE end
			where 	CASEID = @nCaseId
		end
		else
		begin
			if (	@pnNoOfClaims is not null 
			or	@pbIsUseByOwner is not null
			or	@pbIsUseByOthers is not null
			or	@psApplicationBasisKey is not null
			or	@pnRenewalTypeKey is not null
			or	@pnExaminationTypeKey is not null)
			begin
				insert into PROPERTY(
					CASEID,
					NOOFCLAIMS,
					BASIS,
					REGISTEREDUSERS,
					EXAMTYPE,
					RENEWALTYPE)
				values	(
					@nCaseId,
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
					@pnRenewalTypeKey)
			end
		end
		set @nErrorCode = @@error
	end
	
	-- short title changes
	if @nErrorCode = 0
--	and @psOriginalShortTitle <> @psShortTitle
	and @pbShortTitleModified = 1
	begin
		exec @nErrorCode = dbo.cs_InsertKeyWordsFromTitle @nCaseId = @nCaseId
	end

	-- file location changes
	if @nErrorCode = 0
	and @pbFileLocationKeyModified = 1
--	and @psOriginalFileLocationKey <> @psFileLocationKey
	begin		
		exec @nErrorCode = dbo.cs_InsertFileLocation 
			@pnUserIdentityId = @pnUserIdentityId,
 			@psCulture = @psCulture,
			@psCaseKey = @psCaseKey,
			@psFileLocationKey = @psFileLocationKey
	end

--	RFC05 recalculate open actions if Criteria keys change
	if 	@nErrorCode = 0
	and (	@pbOfficeModified = 1
	or	@pbCountryKeyModified = 1 
	or	@pbPropertyTypeKeyModified = 1
	or	@pbCaseCategoryKeyModified = 1
	or	@pbSubTypeKeyModified = 1
	or	@pbApplicationBasisKeyModified = 1
	or	@pbIsLocalClientModified = 1
	or	@pbIsUseByOwnerModified = 1
	or	@pbIsUseByOthersModified = 1
	or	@pbExaminationTypeKeyModified = 1
	or	@pbRenewalTypeKeyModified = 1)
	begin
		-- get policing information	
		declare @tOpenActions table
		(	IDENT	int identity(1,1) not null,
			ACTION	nvarchar(2) collate database_default not null,
			CYCLE	int not null)

		set @nErrorCode = @@error

		if @nErrorCode = 0
		begin
			insert into @tOpenActions ([ACTION], CYCLE)
				select 	distinct [ACTION], CYCLE
					from 	OPENACTION
					where	CASEID = @nCaseId
					and	POLICEEVENTS = 1
					order by [ACTION]

			select @nRowCount = @@rowcount, @nErrorCode = @@error
		end
			
		if @nErrorCode = 0 
		and @nRowCount > 0
		begin	
			set @nCounter = 1
			while @nCounter <= @nRowCount and @nErrorCode = 0
			begin
				
				select 	@sAction = [ACTION], 
					@nCycle = CYCLE,
					@dtDateEntered = null,
					@nPolicingSeqNo = null
					from 	@tOpenActions
					where 	IDENT = @nCounter

				if 	@sAction is not null
				and	@nCycle is not null
				begin
					-- Add Policing Request
					exec @nErrorCode = dbo.ip_InsertPolicing
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,  	
						@psCaseKey = @psCaseKey, 
						@psAction = @sAction,
						@pnCycle = @nCycle,
						@pnTypeOfRequest = 4, -- recalc
						@pnPolicingBatchNo = @pnPolicingBatchNo

					select @psCaseKey, @sAction, @nCycle, 4
	
				end
				set @nCounter = @nCounter + 1
			end
		end		
		set @nErrorCode = @@error
	end

	return @nErrorCode

end
GO

grant execute on dbo.cs_UpdateCase to public
GO
