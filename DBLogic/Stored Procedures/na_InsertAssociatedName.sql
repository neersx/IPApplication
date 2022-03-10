----------------------------------------------------------------------------------------------
-- Creation of dbo.na_InsertAssociatedName
----------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_InsertAssociatedName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_InsertAssociatedName.'
	drop procedure [dbo].[na_InsertAssociatedName]
	print '**** Creating Stored Procedure dbo.na_InsertAssociatedName...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.na_InsertAssociatedName
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11) = null, 	-- RelatedName
	@pnRelationshipTypeId	int = null, 		-- if Organisation = 1 then EMP
	@psRelatedNameKey	varchar(11) = null,	-- NameNo
	@pnRelatedNameSequence	int = null,		-- just created, so zero
	@psPosition		nvarchar(60) = null,
	@pbIsReverseRelationship bit = null,
	@pbIsMainContact	bit = null
)
-- VERSION:	10
-- DESCRIPTION:	Insert an Associated Name for a Name
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change	Description
-- ------------	-------	-------	------	----------------------------------------- 
-- 15 Nov 2002 	SF	6		Update Version Number
-- 20 Feb 2003	SF	7	RFC08	Implement Main Contact
-- 17 May 2006	IB	8	RFC3690	Recalculate derived case name attention
-- 05 Mar 2009	MF	9	17453	Include an explict transaction to reduce the chance of locking.
-- 15 Apr 2013	DV	10	R13270	Increase the length of nvarchar to 11 when casting or declaring integer
as
		
-- assumes that a new row needs to be created.
declare @nErrorCode 			int
declare @TransactionCountStart		int
declare @sRelationship 			varchar(3)
declare @nRelatedNameKey 		int
declare @nNameKey 			int
declare @nNameKeyForAttention		int
declare @nRelatedNameKeyForAttention	int

set @nErrorCode = 0

if @nErrorCode = 0
and @psRelatedNameKey is null
begin
	set @nErrorCode = -1
end

if @nErrorCode = 0
begin
	if @pnRelationshipTypeId = 1
		set @sRelationship = 'EMP'
	else
		set @nErrorCode = -1

	-- CPA.net only allows EMP to be defined.  Relationship is a non null field.
end

if @nErrorCode = 0
Begin
	Set @nNameKey = Case @pbIsReverseRelationship 
				when 1 then Cast(@psRelatedNameKey as int)
				else Cast(@psNameKey as int)
			End

	Set @nRelatedNameKey =	Case @pbIsReverseRelationship 
					when 1 then Cast(@psNameKey as int)
					else Cast(@psRelatedNameKey as int)
				End
End

if @nErrorCode = 0
and @pnRelatedNameSequence is null
begin		
	select 	@pnRelatedNameSequence = MAX(SEQUENCE) + 1
	from 	ASSOCIATEDNAME
	where	NAMENO = @nNameKey
	and	RELATIONSHIP = @sRelationship
	and	RELATEDNAME = @nRelatedNameKey

	set @pnRelatedNameSequence = isnull(@pnRelatedNameSequence, 0)
	
	set @nErrorCode = @@Error
end

if @nErrorCode = 0
begin
	-- Start new transaction.
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION
	
	insert into ASSOCIATEDNAME (
		NAMENO,
		RELATIONSHIP,
		RELATEDNAME,
		SEQUENCE,
		POSITION,
		MAINORGANISATION
	) values (
		@nNameKey,
		@sRelationship,
		@nRelatedNameKey,
		@pnRelatedNameSequence,
		@psPosition,
		case @pbIsReverseRelationship 
			when 1 then 1 else null 
		end
	)

	set @nErrorCode = @@Error				
end

if @nErrorCode = 0
and @pbIsMainContact = 1
Begin
	Update 	NAME
	Set	MAINCONTACT = @nRelatedNameKey
	Where	NAMENO = @nNameKey

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
		Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
					@pnMainNameKey 	= @nRelatedNameKeyForAttention
	End
	Else
	Begin			
		If @pbIsMainContact = 1		
		Begin
			Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
						@pnMainNameKey 		= @nNameKeyForAttention,
						@pnOldAttentionKey 	= null,
						@pnNewAttentionKey 	= @nRelatedNameKeyForAttention 
		End
		Else
		Begin
			Exec @nErrorCode = dbo.cs_RecalculateDerivedAttention
						@pnMainNameKey 		= @nNameKeyForAttention,
						@pnOldAttentionKey 	= null
		End		
	End
End

-- Commit transaction if successful.
If @@TranCount > @TransactionCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

Return @nErrorCode
GO

grant exec on dbo.na_InsertAssociatedName to public
go
