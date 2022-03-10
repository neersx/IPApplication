-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateCaseText
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateCaseText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_UpdateCaseText.'
	Drop procedure [dbo].[cs_UpdateCaseText]
	Print '**** Creating Stored Procedure dbo.cs_UpdateCaseText...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_UpdateCaseText
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(11) = null, 
	@pnTextTypeId			int = null,
	@pnTextSequence			int = null,
	@psText				ntext = null,

	@pbTextTypeIdModified		bit = null,
	@pbTextSequenceModified		bit = null,
	@pbTextModified			bit = null

)

-- PROCEDURE :	cs_UpdateCaseText
-- VERSION :	6
-- DESCRIPTION:	updates a row 

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 17/07/2002	SF 	Stub Created
-- 27/07/2002	SF	Procedure Created
-- 02/08/2002	SF	Test @psText = ''
-- 15 Apr 2013	DV	6 R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
	declare @nErrorCode int
	declare @bLongFlag bit
	declare @sTextType nvarchar(2)

	set @nErrorCode = 0

	if @nErrorCode = 0 
	and @pbTextModified = 1
	and len(cast(@psText as nvarchar(300)))=0
	begin
		exec @nErrorCode = cs_DeleteCaseText
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture, 
				@psCaseKey = @psCaseKey,
				@pnTextTypeId = @pnTextTypeId,
				@pnTextSequence = @pnTextSequence
	
		return @nErrorCode
	end

	if @nErrorCode = 0
	begin
		if len(cast(@psText as nvarchar(300))) <= 254
			set @bLongFlag = 0
		else
			set @bLongFlag = 1
	
		set @nErrorCode = @@error
	end

	if @nErrorCode = 0
	begin
		set @sTextType = case @pnTextTypeId
				  when	0	then 'T'	/* Title 	*/
				  when	1	then 'R'	/* Remarks 	*/
				  when 	2	then 'CL'	/* Claims 	*/
				  when 	3	then 'A'	/* Abstract 	*/
				  when	4	then 'T1'	/* Text1 	*/
				  when 	5	then 'T2'	/* Text2 	*/
				  when	6	then 'T3'	/* Text3 	*/
				end

		if @sTextType is null
			set @nErrorCode = -1
	end

	if @nErrorCode = 0
	begin
		update 	CASETEXT 
		set 	MODIFIEDDATE = getdate(),
			LONGFLAG = @bLongFlag,
			SHORTTEXT = CASE WHEN @bLongFlag = 1 THEN null ELSE CAST(@psText as nvarchar(254)) END,
			TEXT = CASE WHEN @bLongFlag = 1 THEN @psText ELSE null END
		where	CASEID = cast(@psCaseKey as int)
		and	TEXTNO = @pnTextSequence
		and	TEXTTYPE = @sTextType

		set @nErrorCode = @@error
	end	
	
	return @nErrorCode
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_UpdateCaseText to public
GO
