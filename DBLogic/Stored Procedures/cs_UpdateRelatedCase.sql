-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateRelatedCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateRelatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_UpdateRelatedCase.'
	drop procedure [dbo].[cs_UpdateRelatedCase]
	print '**** Creating Stored Procedure dbo.cs_UpdateRelatedCase...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_UpdateRelatedCase
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(11) = null, 
	@pnRelationshipSequence		int 	     = null output,
	@psRelationshipKey		varchar(3)   = null,
	@psRelationshipDescription	varchar(50)  = null,
	@psRelatedCaseKey		varchar(11)  = null,
	@psRelatedCaseReference		nvarchar(20) = null,
	@psCaseFamilyReference 		nvarchar(20) = null,	
	@psCountryKey			nvarchar(3)  = null,
	@psCountryName			nvarchar(60) = null,
	@psOfficialNumber		nvarchar(36) = null,
	@psPropertyTypeDescription	nvarchar(50) = null,
	@psCaseTypeDescription		nvarchar(50) = null,
	@psCaseCategoryKey 		nvarchar(2)  = null, 
	@psCaseCategoryDescription	nvarchar(20) = null, -- not being used at present 
	@psStatusDescription		nvarchar(50) = null,

	@pbRelationshipSequenceModified		bit = null,
	@pbRelationshipKeyModified		bit = null,
	@pbRelationshipDescriptionModified	bit = null,
	@pbRelatedCaseKeyModified		bit = null,
	@pbRelatedCaseReferenceModified		bit = null,
	@pbCaseFamilyReferenceModified 		bit = null,
	@pbCountryKeyModified			bit = null,
	@pbCountryNameModified			bit = null,
	@pbOfficialNumberModified		bit = null,
	@pbPropertyTypeDescriptionModified	bit = null,
	@pbCaseTypeDescriptionModified		bit = null,
	@pbCaseCategoryKeyModified 		bit = null,
	@pbCaseCategoryDescriptionModified	bit = null,
	@pbStatusDescriptionModified		bit = null,

	@psOriginalRelatedCaseKey 		varchar(11)  = null,
	@psOriginalRelationshipKey		varchar(3)  = null,
	@pnOriginalRelationshipSequence		int 	     = null,
	@pbProcessPriorityEvent			bit = null output
)

-- PROCEDURE :	cs_UpdateRelatedCase
-- VERSION :	6
-- DESCRIPTION:	updates a row 

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 17/07/2002	SF	Stub Created
-- 07/08/2002	SF	Procedure Created
-- 07/07/2005	TM	RCF2329	Increase the size of all case category parameters and local variables to 2 characters.
-- 25/11/2011	Ash	R100640 Change the size of Case Key and Related Case key to 11.
as
begin
	declare @nErrorCode int
	declare @nCaseId int
	declare @nRelatedCase int

	if 	@psRelatedCaseKey is null
	and 	@pbRelationshipKeyModified is null
	begin
		-- this relationship has been cleared.
		exec @nErrorCode = dbo.cs_DeleteRelatedCase 
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@psCaseKey = @psCaseKey,
					@pnRelationshipSequence = @pnOriginalRelationshipSequence,
					@psRelationshipKey = @psOriginalRelationshipKey,
					@psRelatedCaseKey = @psOriginalRelatedCaseKey,
					@psCountryKey = @psCountryKey,
					@psOfficialNumber = @psOfficialNumber					
	end
	else
	begin
		
		if 	@psRelationshipKey <> @psOriginalRelationshipKey
		or	@psRelatedCaseKey <> @psOriginalRelatedCaseKey
		begin
			exec @nErrorCode = dbo.cs_DeleteRelatedCase 
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@psCaseKey = @psCaseKey,
					@pnRelationshipSequence = @pnOriginalRelationshipSequence,
					@psRelationshipKey = @psOriginalRelationshipKey,
					@psRelatedCaseKey = @psOriginalRelatedCaseKey,
					@psCountryKey = @psCountryKey,
					@psOfficialNumber = @psOfficialNumber	
			
			
			if @nErrorCode = 0
			begin

				exec @nErrorCode = dbo.cs_InsertRelatedCase
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@psCaseKey = @psCaseKey,
					@pnRelationshipSequence = @pnRelationshipSequence,
					@psRelationshipKey = @psRelationshipKey ,
					@psRelationshipDescription = @psRelationshipDescription,
					@psRelatedCaseKey = @psRelatedCaseKey,
					@psRelatedCaseReference = @psRelatedCaseReference,
					@psCaseFamilyReference = @psCaseFamilyReference,					
					@psCountryKey = @psCountryKey,
					@psOfficialNumber = @psOfficialNumber,	
					@psPropertyTypeDescription = @psPropertyTypeDescription,
					@psCaseTypeDescription = @psCaseTypeDescription,
					@psCaseCategoryKey = @psCaseCategoryKey,
					@psCaseCategoryDescription = @psCaseCategoryDescription,
					@psStatusDescription = @psStatusDescription,
					@pbProcessPriorityEvent = @pbProcessPriorityEvent output
			end

		end
	end

	return @nErrorCode
end
GO

grant execute on dbo.cs_UpdateRelatedCase to public
go
