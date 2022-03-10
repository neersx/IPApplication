---------------------------------------------------------------------------------------------
-- Creation of dbo.na_UpdateAttribute
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_UpdateAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_UpdateAttribute.'
	drop procedure [dbo].[na_UpdateAttribute]
	print '**** Creating Stored Procedure dbo.na_UpdateAttribute...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE  PROCEDURE dbo.na_UpdateAttribute
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey			varchar(11), 		
	@pnAttributeTypeId		int = null, 		-- refer doco below
	@psAttributeKey			varchar(11)=null,
	@psAttributeDescription		nvarchar(254) = null,	-- Description
	
	@pnNameKeyModified		int = null,
	@pnAttributeTypeIdModified	int = null,
	@pnAttributeKeyModified		int = null,
	@pnAttributeDescriptionModified	int = null
)
-- VERSION :	8
--	DESCRIPTION	: Updates the Attribute
--	AUTHOR		: Siew Fai

--	MODIFICATION	: 
--		19/07/2002 	SF 	removed the Parent Relationship unchange check.
--		06/08/2002	SF	incorrectly inserting duplicates
--		04-NOV-2002	JG	remove the Output term from the AttributeKey parameter
--		15 Apr 2013	DV	8	RFC13270 Increase the length of nvarchar to 11 when casting or declaring integer
AS
begin
	/* SET NOCOUNT ON */
	declare @nErrorCode int
	declare @nTableType int
	declare @sAttributeKey int
			
	set @nErrorCode = @@Error
	
	if @nErrorCode = 0	
	begin
		/*	is minumum data missing?  
			either AttributeKey or AttributeDescription must be present
			delete it 
		*/
		if	@nErrorCode = 0
		and	@psAttributeKey is null or @pnAttributeKeyModified is not null		
		begin

			select @nTableType = 
				  case @pnAttributeTypeId
					  when 1 	then -1		/* AnalysisCode1 */
					  when 2	then -2 	/* AnalysisCode2 */
					  when 3	then 26 	/* EntitySize */
					  when 4 	then 40 	/* Valediction */
				  else
					  null 	-- just a dummy to indicate error
				  end
				  
			if @nTableType is null
				set @nErrorCode = -1

			if @nErrorCode = 0
			begin
			    	Select @sAttributeKey = Cast(T.TABLECODE As varchar(11))
					from TABLEATTRIBUTES T
				        where 	T.PARENTTABLE	= 'NAME'
				        and	T.TABLETYPE 	= @nTableType
				        and	T.GENERICKEY	= @psNameKey
			          	
				exec @nErrorCode = [dbo].[na_DeleteAttribute] 
								@pnUserIdentityId = @pnUserIdentityId, 
								@psCulture = @psCulture, 
								@psNameKey = @psNameKey, 
								@pnAttributeTypeId = @pnAttributeTypeId, 
								@psAttributeKey = @sAttributeKey

			end
			if	@nErrorCode = 0
			and	@psAttributeDescription is not null
			begin
				exec @nErrorCode = [dbo].[na_InsertAttribute] 
							@pnUserIdentityId = @pnUserIdentityId,
							@psCulture = @psCulture, 
							@psNameKey = @psNameKey, 
							@pnAttributeTypeId = @pnAttributeTypeId, 
							@psAttributeKey = @psAttributeKey, 
							@psAttributeDescription = @psAttributeDescription
			end
		end
		
	end
	
	RETURN @nErrorCode
end
go

grant execute on dbo.na_UpdateAttribute to public
go
