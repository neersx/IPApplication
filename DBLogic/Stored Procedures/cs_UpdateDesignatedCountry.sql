-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateDesignatedCountry
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateDesignatedCountry]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_UpdateDesignatedCountry.'
	drop procedure [dbo].[cs_UpdateDesignatedCountry]
	print '**** Creating Stored Procedure dbo.cs_UpdateDesignatedCountry...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_UpdateDesignatedCountry
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(11) = null, 

	@pnSequence			int = null,
	@psCountryKey			nvarchar(3) = null,
	@psCountryCode			nvarchar(3) = null,
	@psCountryName			nvarchar(60) = null,
	@pbIsDesignated			bit = null,
	@pbIsNationalPhase		bit = null,

	@pbSequenceModified		bit = null,
	@pbCountryKeyModified		bit = null,
	@pbCountryCodeModified		bit = null,
	@pbCountryNameModified		bit = null,
	@pbIsDesignatedModified		bit = null,
	@pbIsNationalPhaseModified	bit = null,

	@pnInitialStatus		int = null,
	@pnNationalPhaseStatus		int = null,

	@psProfileName			nvarchar(100) output
)

-- PROCEDURE :	cs_UpdateDesignatedCountry
-- VERSION :	7
-- DESCRIPTION:	updates a row 


-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 17 Jul 2002	SF		Procedure Created
-- 08 Aug 2002	SF		Implement CaseData.doc rev 0.14
--				deletes and updates.
-- 03 Dec 2002	SF	6	1. Add InitialStatus and NationalPhaseStatus as parameters
--				2. Add ability to remove National status.
-- 15 Apr 2013	DV	7	R13270 Increase the length of nvarchar to 11 when casting or declaring integer

as
begin
	declare @nErrorCode int
	declare @nCaseId int
	declare @nRelSeq int

	
	if @pbIsDesignated = 0 
	and @pnSequence is null
	begin
		set @nErrorCode = -1
	end
	else
	begin
		set @nCaseId = cast(@psCaseKey as int)
		set @nErrorCode = @@error
	end

	if @nErrorCode = 0
	begin
		if @pbIsDesignated = 1
		begin			
			-- determine whether to insert or update
			if @pnSequence is null
			begin 
				-- -------------------
				-- Get Relationship No
				if @nErrorCode = 0
				begin
					select 	@nRelSeq = isnull(max(RELATIONSHIPNO)+1, 0)
					from	RELATEDCASE 
					where 	CASEID = @nCaseId
			
					-- ------------------
					-- Get Insert the row
					insert RELATEDCASE (
						CASEID,
						RELATIONSHIPNO,
						RELATIONSHIP,
						COUNTRYCODE,
						COUNTRYFLAGS,
						CURRENTSTATUS)
					values (
						@nCaseId,
						@nRelSeq,
						'DC1',
						@psCountryKey,	
						case @pbIsNationalPhase when 1 then @pnInitialStatus | @pnNationalPhaseStatus else @pnInitialStatus end,
						case @pbIsNationalPhase when 1 then @pnNationalPhaseStatus else @pnInitialStatus end
						)
			
					set @nErrorCode = @@error
					
				end -- insert related case
			end -- designated is true, sequence is null
			else
			begin
				if @pbIsNationalPhaseModified is not null
				begin					
					if @pbIsNationalPhase = 1
					begin
						-- existing designation becomes national
						update 	RELATEDCASE
						set	COUNTRYFLAGS = @pnInitialStatus | @pnNationalPhaseStatus,
							CURRENTSTATUS = @pnNationalPhaseStatus
						where	CASEID = @nCaseId
						and	RELATIONSHIPNO = @pnSequence
												
						set @nErrorCode = @@error
					end
					else
					begin
						-- existing designation no longer national
						update 	RELATEDCASE
						set	COUNTRYFLAGS = @pnInitialStatus,
							CURRENTSTATUS = @pnInitialStatus
						where	CASEID = @nCaseId
						and	RELATIONSHIPNO = @pnSequence

						set @nErrorCode = @@error					
					end
				end
				
			end -- designated is true, sequence is not null
		end -- is designated
		else	
		begin
			-- remove designated country
			-- (added CaseData.doc rev 0.14)
			delete
			from	RELATEDCASE
			where	CASEID = @nCaseId
			and	RELATIONSHIPNO = @pnSequence
	
			set @nErrorCode = @@error
		end -- remove designation
	end
	
	-- ------------------------
	-- Get Default Profile Name
	if @nErrorCode = 0
	and @pbIsNationalPhase = 1
	and @pbIsNationalPhaseModified = 1
	begin
		select 	@psProfileName = PROFILENAME
		from	CASES C
		join	COUNTRYFLAGS CF on (C.COUNTRYCODE = CF.COUNTRYCODE
					and FLAGNUMBER = @pnNationalPhaseStatus)
		and	C.CASEID = @nCaseId
	end

	return @nErrorCode
end
GO

grant execute on dbo.cs_UpdateDesignatedCountry to public
GO
