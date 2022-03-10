-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_DeleteAssociatedName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_DeleteAssociatedName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_DeleteAssociatedName.'
	drop procedure [dbo].[na_DeleteAssociatedName]
	print '**** Creating Stored Procedure dbo.na_DeleteAssociatedName...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.na_DeleteAssociatedName
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11),		-- Mandatory
	
	@pnRelationshipTypeId	int = null,
	@psRelatedNameKey	varchar(11) = null,
	@pnRelatedNameSequence	int = null,
	@pbIsReverseRelationship bit = null,
	@pbIsMainContact	bit = null
		
)
-- VERSION:	8
-- DESCRIPTION:	Delete Associated Name for a Name
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF	4	Update Version Number
-- 02 Dec 2002	SF	5	Added 3 more parameters to delete the correct row.
-- 19 Feb 2003	SF	6	Clear Main Contact
-- 17 May 2006	IB	7	RFC3690	Recalculate derived case name attention
-- 15 Apr 2013	DV	8	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
As
Begin
			
	-- requires that NameKey exists and maps to NAME.NAMENO.
	Declare @nErrorCode 			int
	Declare @sRelationShip 			nvarchar(3)
	declare @nNameKeyForAttention 		int
	declare @nRelatedNameKeyForAttention	int

	Set @nErrorCode = 0

	If @nErrorCode = 0
	Begin
		If @pnRelationshipTypeId = 1 or @pnRelationshipTypeId = 2
			Set @sRelationShip = 'EMP'
		Else
			Set @nErrorCode = -1
	End

	If @nErrorCode = 0
	and @pbIsMainContact = 1 
	Begin
		If @pbIsReverseRelationship = 1
		Begin
			Update 	NAME
			Set	MAINCONTACT = null
			Where	NAMENO = Cast(@psRelatedNameKey as int)
		End 		
		Else
		If @pbIsReverseRelationship = 0
		Begin
			Update 	NAME
			Set	MAINCONTACT = null
			Where	NAMENO = Cast(@psNameKey as int)
		End 	

		Set @nErrorCode = @@error
	End

	If @nErrorCode = 0
	Begin
		Delete  
		from 	ASSOCIATEDNAME
		where 	RELATEDNAME = case @pbIsReverseRelationship 
						when 0 then cast(@psRelatedNameKey as int)
						else Cast(@psNameKey as int) 
					end
		and	RELATIONSHIP = @sRelationShip
		and	NAMENO	= case @pbIsReverseRelationship 
						when 1 then cast(@psRelatedNameKey as int)
						else Cast(@psNameKey as int) 
					end
		and	SEQUENCE = @pnRelatedNameSequence
			
		Set @nErrorCode = @@Error		
	End

	If @nErrorCode = 0
	Begin
		-- Define NameKey and RelatedNameKey so that their usage 
		-- in recalculating Derived Attention is clear
		Set @nNameKeyForAttention 	 = Cast(@psNameKey as int)
		Set @nRelatedNameKeyForAttention = Cast(@psRelatedNameKey as int)

		If @pbIsReverseRelationship = 1
		Begin		
			If @pbIsMainContact = 1		
			Begin
				Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
					@pnMainNameKey 		= @nRelatedNameKeyForAttention,
					@pnOldAttentionKey 	= @nNameKeyForAttention,
					@pnNewAttentionKey 	= null 
			End
			Else
			Begin
				Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
					@pnMainNameKey 		= @nRelatedNameKeyForAttention,
					@pnNewAttentionKey 	= null
			End
		End
		Else
		Begin			
			If @pbIsMainContact = 1		
			Begin
				Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
					@pnMainNameKey 		= @nNameKeyForAttention,
					@pnOldAttentionKey 	= @nRelatedNameKeyForAttention,
					@pnNewAttentionKey 	= null 
			End
			Else
			Begin
				Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
					@pnMainNameKey 		= @nNameKeyForAttention,
					@pnNewAttentionKey 	= null
			End		
		End
	End
		
	Return @nErrorCode
End
GO
SET QUOTED_IDENTIFIER OFF  
GO
SET ANSI_NULLS ON  
GO

grant exec on dbo.na_DeleteAssociatedName to public
go
