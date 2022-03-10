-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertCaseAttribute
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertCaseAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_InsertCaseAttribute.'
	drop procedure [dbo].[cs_InsertCaseAttribute]
	Print '**** Creating Stored Procedure dbo.cs_InsertCaseAttribute...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_InsertCaseAttribute
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey		varchar(11) = null, 
	@pnAttributeTypeId	int = null,
	@psAttributeKey		varchar(11) = null,
	@psAttributeDescription	nvarchar(80) = null
)
-- VERSION:	7
-- DESCRIPTION:	Insert a Case Attribute row to database.
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 19 Jul 2002	SF		1. Only insert TableCodes when @psAttributeKey is null.
--				2. LastInternalCode is set to AttributeKey int value if not set previously.
-- 05 Nov 2002	SF	5	Update Version Number
-- 28 Nov 2002	SF	6	New Analysis Codes for Cases
-- 15 Apr 2013	DV	7	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
	declare @nErrorCode int
	declare @nTableType int
	declare @nLastInternalCode int
	set @nErrorCode = 0

	if @psAttributeKey is null and @psAttributeDescription is null
	begin
		/* minimum data missing */
		set @nErrorCode = -1
	end 

	if @nErrorCode = 0
	begin
		select @nTableType = 
			case @pnAttributeTypeId
				when 1 	then -3		/* AnalysisCode1 */
				when 2	then -498 	/* AnalysisCode2 */
				when 3	then -4 	/* AnalysisCode3 */
				when 4 	then -5 	/* AnalysisCode4 */
				when 5 	then -6		/* AnalysisCode5 */
			else
				-2  -- just a dummy to indicate error
			end					

		if @nTableType = -1
			select @nErrorCode = @nTableType
	end
	
	if @nErrorCode = 0
	and @psAttributeKey is null
	begin	

		Select 	@nLastInternalCode=TABLECODE
		from 	TABLECODES 
		where 	DESCRIPTION=@psAttributeDescription
		  and 	TABLETYPE=@nTableType
		
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
				'CASES',
				@psCaseKey,
				@nLastInternalCode,
				@nTableType
			)

			select @nErrorCode = @@Error
		end
	end

	return @nErrorCode
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_InsertCaseAttribute to public
go
