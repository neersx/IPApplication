----------------------------------------------------------------------------------------------
-- Creation of dbo.na_InsertAttribute
----------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_InsertAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_InsertAttribute.'
	drop procedure [dbo].[na_InsertAttribute]
	print '**** Creating Stored Procedure dbo.na_InsertAttribute...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create   procedure dbo.na_InsertAttribute
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11), 		
	@pnAttributeTypeId	int, 			-- refer doco below
	@psAttributeKey		varchar(11) = null,		-- Key
	@psAttributeDescription	nvarchar(254) = null	-- Description
)
-- PROCEDURE :	na_InsertAttribute
-- VERSION :	11
-- DESCRIPTION:	Insert an Address to a name
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 04/07/2002	SF	Procedure created
-- 19/07/2002	SF	1. Insert Table Codes only when Attribute Key is not provided.
--			2. LastInternalCode is set to Attribute Key int value if not set previously
-- 06/08/2002	SF	use -1, -2 for analysis code
-- 06-NOV-2002	JG	set the @psAttributeKey parameter to non mandatory and remove the output option because not needed
--                  + add a test before inserting a new value in TABLECODE
-- 15 Apr 2013	DV	11	R13270 Increase the length of nvarchar to 11 when casting or declaring integer

as
begin
	
	
	-- assumes that a new row needs to be created.
	declare @nErrorCode int
	declare @nTableType int
	-- get last internal code.
	declare @nLastInternalCode int

	set @nErrorCode = 0

	if @nErrorCode = 0
	begin
		select @nTableType = 
			case @pnAttributeTypeId
				when 1 	then -1	-- AnalysisCode1  (41 is a temporary code)
				when 2	then -2 -- AnalysisCode2  (42 is a temporary code)
				when 3	then 26 -- EntitySize
				when 4 	then 40	-- Valediction
			else
				null  -- just a dummy to indicate error
			end					

		if @nTableType = null
			select @nErrorCode = @nTableType
	end

	if @nErrorCode = 0
	and @psAttributeKey is null
	begin
		-- Added by JG 06/11
		select @nLastInternalCode=TABLECODE
		from TABLECODES 
		where DESCRIPTION=@psAttributeDescription
		  and TABLETYPE=@nTableType
		
		if @nLastInternalCode is null
		begin
		
			-- Added by JB 16/7
			Exec @nErrorCode = ip_GetLastInternalCode 1, NULL, 'TABLECODES', @nLastInternalCode OUTPUT
		
			if @nErrorCode = 0
			begin
				insert into TABLECODES (
					TABLECODE,
					TABLETYPE,
					DESCRIPTION
				) values (
					@nLastInternalCode,
					@nTableType,
					@psAttributeDescription
				
				)
				
				select @nErrorCode = @@Error
			end
		end
	end
	
	if @nErrorCode = 0
	begin

		if @nLastInternalCode is null
		begin
			set @nLastInternalCode = cast(@psAttributeKey as int)

			set @nErrorCode = @@error
		end

		if @nErrorCode = 0
		begin
			insert into TABLEATTRIBUTES (
				PARENTTABLE,
				GENERICKEY,
				TABLECODE,
				TABLETYPE
			) values (
				'NAME',
				@psNameKey,
				@nLastInternalCode,
				@nTableType
			)

			select @nErrorCode = @@Error
		end


	end

end
go

grant execute on dbo.na_InsertAttribute to public
go
