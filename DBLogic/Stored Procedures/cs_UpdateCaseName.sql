-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateCaseName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_UpdateCaseName.'
	drop procedure [dbo].[cs_UpdateCaseName]
	print '**** Creating Stored Procedure dbo.cs_UpdateCaseName...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_UpdateCaseName
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(11) = null, 
	@pnNameTypeId			int = null,
	@psNameTypeKey			nvarchar(3) = null,
	@psNameTypeDescription		nvarchar(50) = null,
	@psNameKey			nvarchar(11) = null,
	@psDisplayName			nvarchar(254) = null,
	@pnNameSequence			int = null,
	@psReferenceNo			nvarchar(80) = null,

	@pbNameTypeIdModified		bit = null,
	@pbNameTypeKeyModified		bit = null,
	@pbNameTypeDescriptionModified	bit = null,
	@pbNameKeyModified		bit = null, 		-- Mandatory
	@pbDisplayNameModified		bit = null,
	@pbNameSequenceModified		bit = null,
	@pbReferenceNoModified		bit = null,

	@psOriginalNameKey		nvarchar(11),
	@psOriginalNameTypeKey		nvarchar(3)

)

-- PROCEDURE :	cs_UpdateCaseName
-- VERSION :	8
-- DESCRIPTION:	updates a row 

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17/07/2002	SF			Stub Created
-- 27/07/2002	SF			Procedure Created
-- 02/08/2002	SF			Use new keys for inserted rows.
-- 29/11/2002	SF		6	Use pnNameSequence when updating/deleting
-- 23/Jul/2004	TM	RFC1610	7	Increase the datasize of the @psReferenceNo from nvarchar(50) to nvarchar(80).	
-- 15 Apr 2013	DV	R13270	8	Increase the length of nvarchar to 11 when casting or declaring integer

as
begin
	declare @nErrorCode int
	set @nErrorCode = 0

	if @psNameKey is null 
	or @pbNameKeyModified = 1
	or @pbNameTypeKeyModified = 1
	begin
		exec @nErrorCode = cs_DeleteCaseName 
				@pnUserIdentityId = @pnUserIdentityId, 
				@psCulture = @psCulture,
				@psCaseKey = @psCaseKey,
				@psNameTypeKey = @psOriginalNameTypeKey,
				@psNameKey = @psOriginalNameKey,
				@pnNameSequence = @pnNameSequence


		if @psNameKey is null 
		begin
			/* if the NameKey is deliberately set to null */
			/* the processing stops here */
			return @nErrorCode
		end
		else
		begin
			exec @nErrorCode = cs_InsertCaseName
				@pnUserIdentityId = @pnUserIdentityId, 
				@psCulture = @psCulture,
				@psCaseKey = @psCaseKey,
				@psNameTypeKey = @psNameTypeKey,
				@psNameKey = @psNameKey,
				@psReferenceNo = @psReferenceNo
			/* a new relationship has been created for this name */
			return @nErrorCode
		end
	end
	
	if @nErrorCode = 0
	and @pbNameTypeKeyModified is null
	and @pbNameKeyModified is null
	and @pbNameSequenceModified is null
	begin
		/* all keys haven't been changed, so update proceeds */
		
		update	CASENAME
		set	REFERENCENO = @psReferenceNo
		where 	CASEID = cast(@psCaseKey as int)
		and	NAMETYPE = @psNameTypeKey
		and	NAMENO = cast(@psNameKey as int)
		and	SEQUENCE = @pnNameSequence

		set @nErrorCode = @@error		
	end
	
	return @nErrorCode
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on cs_UpdateCaseName to public
GO
