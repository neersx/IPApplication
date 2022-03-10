-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateCaseAttribute
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateCaseAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_UpdateCaseAttribute.'
	Drop procedure [dbo].[cs_UpdateCaseAttribute]
	Print '**** Creating Stored Procedure dbo.cs_UpdateCaseAttribute...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_UpdateCaseAttribute
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(11) = null, 
	@pnAttributeTypeId		int = null,
	@psAttributeKey			varchar(11)= null,
	@psAttributeDescription		nvarchar(80) = null,

	@pbAttributeTypeIdModified	bit = null,
	@pbAttributeKeyModified		bit = null,
	@pbAttributeDescriptionModified	bit = null

)

-- PROCEDURE :	cs_UpdateCaseAttribute
-- VERSION :	7
-- DESCRIPTION:	updates a row 

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 17 Jul 2002	UNKNOWN
-- 04 Dec 2002	SF	6	AttributeKey does not need to be an output parameter (367)
-- 15 Apr 2013	DV	7	R13270 Increase the length of nvarchar to 11 when casting or declaring integer

as
begin
	declare @nErrorCode int
	declare @nTableType int
	declare @nAttributeKey varchar(11)
			
	set @nErrorCode = @@Error
	
	if @nErrorCode = 0	
	begin
		/*	is minumum data missing?  
			either AttributeKey or AttributeDescription must be present
			delete it 
		*/
		if	@nErrorCode = 0
		and	@psAttributeKey is null 
		or 	@pbAttributeKeyModified = 1	
		begin
		  	Select 	@nTableType = 
			  case 	@pnAttributeTypeId
				  when 1 	then -3		/* AnalysisCode1 */
				  when 2	then -498 	/* AnalysisCode2 */
				  when 3	then -4 	/* AnalysisCode3 */
				  when 4 	then -5 	/* AnalysisCode4 */
				  when 5 	then -6		/* AnalysisCode5 */
			  else
				  -2  -- just a dummy to indicate error
			  end
			  
			Select 	@nAttributeKey = Cast(T.TABLECODE As varchar(11))
			from 	TABLEATTRIBUTES T
			where 	T.PARENTTABLE	= 'CASES'
			and	T.TABLETYPE = @nTableType
			and	T.GENERICKEY	= @psCaseKey
          	
			exec @nErrorCode = [dbo].[cs_DeleteCaseAttribute] 
				@pnUserIdentityId = @pnUserIdentityId, 
				@psCulture = @psCulture, 
				@psCaseKey = @psCaseKey, 
				@pnAttributeTypeId = @pnAttributeTypeId, 
				@psAttributeKey = @nAttributeKey
		
			if	@nErrorCode = 0
			and	@psAttributeDescription is not null
			begin
				exec @nErrorCode = [dbo].[cs_InsertCaseAttribute] 
						@pnUserIdentityId = @pnUserIdentityId, 
						@psCulture = @psCulture, 
						@psCaseKey = @psCaseKey, 
						@pnAttributeTypeId = @pnAttributeTypeId, 
						@psAttributeKey = @psAttributeKey, 
						@psAttributeDescription = @psAttributeDescription
			end
		end
		
	end
	
	RETURN @nErrorCode
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_UpdateCaseAttribute to public
GO
