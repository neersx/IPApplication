---------------------------------------------------------------------------------------------
-- Creation of dbo.na_UpdateAssociatedName
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_UpdateAssociatedName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_UpdateAssociatedName.'
	drop procedure [dbo].[na_UpdateAssociatedName]
	Print '**** Creating Stored Procedure dbo.na_UpdateAssociatedName...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create   PROCEDURE dbo.na_UpdateAssociatedName
(
	@pnUserIdentityId			int,					-- Mandatory
	@psCulture				nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey				varchar(11) = null,		-- RelatedName
	@pnRelationshipTypeId			int = null, 			-- if Organisation = 1 then EMP
	@psRelatedNameKey			varchar(11) = null,		-- NameNo
	@psRelatedDisplayName			nvarchar(254) = null,	-- not used.
	@pnRelatedNameSequence			int = null,		
	@psPosition				nvarchar(60) = null,
	@pbIsReverseRelationship		bit = null,
	@pbIsMainContact			bit = null,
	
	@pnNameKeyModified			int = null,
	@pnRelationshipTypeIdModified		int = null,
	@pnRelatedNameKeyModified		int = null,
	@pnRelatedDisplayNameModified		int = null,
	@pnRelatedNameSequenceModified		int = null,		
	@pnPositionModified			int = null,
	@pbIsMainContactModified		bit = null,

	@pnOriginalRelationshipTypeId		int = null,
	@psOriginalRelatedNameKey		varchar(11) = null,
	@pnOriginalRelatedNameSequence		int = null

)
-- VERSION:	9
-- DESCRIPTION:	Update an Associated Name
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF	5	Update Version Number
-- 10 Dec 2002	SF	6	1. Use Named parameter when calling other sps.
--				2. Supply Original info while deleting the row.
-- 19 Feb 2002	SF	7	RFC08 Main Contact
-- 17 May 2006	IB	8	RFC3690	Recalculate derived case name attention
-- 15 Apr 2013	DV	9	R13270 Increase the length of nvarchar to 11 when casting or declaring integer

AS
begin
	/* SET NOCOUNT ON */
	declare @nErrorCode 				int	
	declare @bParentRelationshipKeyUnchanged 	bit
	declare @bSubtableKeyUnchanged 			bit		
	declare @nRelatedNameKey 			int
	declare @nNameKey 				int
	declare @nNameKeyForAttention 			int
	declare @nRelatedNameKeyForAttention		int


	set @nErrorCode = @@Error
	
	if @nErrorCode = 0
	begin
		if	@pnRelationshipTypeIdModified is null 
		and	@pnRelatedNameKeyModified is null
		begin			
			set @bParentRelationshipKeyUnchanged = 1
		end
	end
	
	if @nErrorCode = 0
	begin
		if @pnNameKeyModified is null
		and @pnRelationshipTypeIdModified is null
		and	@pnRelatedNameKeyModified is null
		and	@pnRelatedNameSequenceModified is null
		begin
			set @bSubtableKeyUnchanged = 1
		end
	end
	
	if	@nErrorCode = 0 
	and @bParentRelationshipKeyUnchanged = 1
	begin
		Set @nNameKey = Case @pbIsReverseRelationship 
					when 1 then Cast(@psRelatedNameKey as int)
					else Cast(@psNameKey as int)
				End

		Set @nRelatedNameKey = Case @pbIsReverseRelationship 
					when 1 then Cast(@psNameKey as int)
					else Cast(@psRelatedNameKey as int)
				End

		if 	@nErrorCode = 0 
		and	@bSubtableKeyUnchanged = 1 
		and 	@pnPositionModified is not null
		begin
			/* Update the AssociatedName row using the RelatedNameKey */	


			Update ASSOCIATEDNAME set
				[POSITION] = @psPosition
			where	NAMENO = @nNameKey
			and	RELATIONSHIP = 'EMP'
			and	RELATEDNAME = @nRelatedNameKey
			and	[SEQUENCE] = @pnRelatedNameSequence			
			
			set @nErrorCode = @@Error
		end

		if @nErrorCode = 0
		and	@bSubtableKeyUnchanged = 1 
		and	@pbIsMainContactModified is not null
		Begin
			Update 	NAME
			Set	MAINCONTACT = case @pbIsMainContact 
						when 1 then @nRelatedNameKey
						else null
					end
			Where	NAMENO = @nNameKey
	
			Set @nErrorCode = @@Error
		End

		if  @nErrorCode = 0
		and @bSubtableKeyUnchanged = 1 
		and @pbIsMainContactModified = 1
		Begin
			-- Define NameKey and RelatedNameKey so that their usage 
			-- in recalculating Derived Attention is clear
			Set @nNameKeyForAttention 	 = Cast(@psNameKey as int)
			Set @nRelatedNameKeyForAttention = Cast(@psRelatedNameKey as int)

			If @pbIsReverseRelationship = 1
			Begin	
				Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
					@pnMainNameKey 	= @nRelatedNameKeyForAttention
			End
			Else
			Begin	
				Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
					@pnMainNameKey 	= @nNameKeyForAttention
			End
		End

	end
	else
	begin
		/*	if Child key has altered, 
			Delete old child and 
			Create new child	*/
			
		/*	@psNameKey represents ASSOCIATEDNAME.RELATEDNAME 
		and	@psRelatedNameKey represents ASSOCIATEDNAME.NAMENO */
		
		if	@psNameKey is not null
		begin
			/* Delete if the data has been cleared */
			exec @nErrorCode = [dbo].[na_DeleteAssociatedName] 
				@pnUserIdentityId = @pnUserIdentityId, 
				@psCulture = @psCulture, 
				@psNameKey = @psNameKey,
				@psRelatedNameKey = @psOriginalRelatedNameKey,
				@pnRelatedNameSequence = @pnOriginalRelatedNameSequence,
				@pnRelationshipTypeId = @pnOriginalRelationshipTypeId,
				@pbIsMainContact = @pbIsMainContact,
				@pbIsReverseRelationship = @pbIsReverseRelationship
		end
		
		if @psRelatedNameKey is not null
		begin
			exec @nErrorCode = [dbo].[na_InsertAssociatedName] 
				@pnUserIdentityId = @pnUserIdentityId, 
				@psCulture = @psCulture, 
				@psNameKey = @psNameKey,
				@pnRelationshipTypeId = @pnRelationshipTypeId, 
				@psRelatedNameKey = @psRelatedNameKey, 
				@pnRelatedNameSequence = @pnRelatedNameSequence, 
				@psPosition = @psPosition,
				@pbIsReverseRelationship = @pbIsReverseRelationship,
				@pbIsMainContact = @pbIsMainContact
		end
	end
--	end
	
	RETURN @nErrorCode
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_UpdateAssociatedName to public
go
