-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_DeleteAttribute
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_DeleteAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_DeleteAttribute.'
	drop procedure [dbo].[na_DeleteAttribute]
	print '**** Creating Stored Procedure dbo.na_DeleteAttribute...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create   procedure dbo.na_DeleteAttribute
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture			nvarchar(10) = null, -- the language in which output is to be expressed
	@psNameKey			varchar(11) = null,
	@pnAttributeTypeId	int	= null,
	@psAttributeKey		varchar(11) = null	
)
-- PROCEDURE :	na_InsertAttribute
-- VERSION :	8
-- DESCRIPTION:	Insert an Address to a name
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 04/07/2002	SF	Procedure created
-- 06/08/2002	SF	the errorcode mechanism is forbidding the addition of AnalysisCode1 (-1).
-- 15 Apr 2013	DV	8	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
	-- requires that NameKey exists and maps to NAME.NAMENO.
	declare @nErrorCode int
	declare @nTableType int

	set @nErrorCode = 0
	if	@nErrorCode = 0
	and	@psAttributeKey is null 
	and	@pnAttributeTypeId is null
	begin
		/* minimum data missing */
		set @nErrorCode = -1
	end
	
	if	@nErrorCode = 0
	begin
		select @nTableType = 
			case @pnAttributeTypeId
				when 1 	then -1	-- AnalysisCode1 
				when 2	then -2 -- AnalysisCode2  
				when 3	then 26 -- EntitySize
				when 4 	then 40	-- Valediction
			else
				null  -- just a dummy to indicate error
			end					

		if @nTableType is null
		begin
			set @nErrorCode = -1
		end
		
		select	@psAttributeKey = Cast(TABLECODE as varchar(11))
		from	TABLEATTRIBUTES
		where	GENERICKEY = @psNameKey
		and	TABLETYPE = @nTableType
	end
	
	if @nErrorCode = 0
	begin
		delete  
		from 	TABLEATTRIBUTES
		where 	PARENTTABLE = 'NAME'
		and		GENERICKEY = @psNameKey
		and		TABLECODE = @psAttributeKey
			
		select @nErrorCode = @@Error		
	end
		
	return @nErrorCode
end
go

grant execute on dbo.na_DeleteAttribute to public
go
