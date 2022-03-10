-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_MaintainOfficialNumber
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_MaintainOfficialNumber]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_MaintainOfficialNumber.'
	drop procedure [dbo].[cs_MaintainOfficialNumber]
	print '**** Creating Stored Procedure dbo.cs_MaintainOfficialNumber...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_MaintainOfficialNumber
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnCaseKey			int, 
	@psNumberTypeKey		nvarchar(3),
	@psOfficialNumber		nvarchar(36) = null,	-- Use null to delete the existing number
	@psOldOfficialNumber 		nvarchar(36) = null	-- Use null to insert a new number

)

-- PROCEDURE :	cs_MaintainOfficialNumber
-- VERSION :	2
-- DESCRIPTION:	Adds, updates or deletes an official number against a case.

-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 20 Mar 2002	JEK	1			RFC03 Case Workflow
-- 19 May 2020	DL	2			DR-58943 Ability to enter up to 3 characters for Number type code via client server	

as
begin
	declare @nErrorCode int
	declare	@bUpdateOfficialNumber bit
	declare @sAlertXML nvarchar(400)

	set @nErrorCode = @@error

	set @bUpdateOfficialNumber = 0

	if @nErrorCode = 0
	and @psOfficialNumber is null
	and @psOldOfficialNumber is not null
	begin
		--Delete Official Number if the data has been cleared.
		set @bUpdateOfficialNumber = 1

		delete 
		from 	OFFICIALNUMBERS
		where	CASEID = @pnCaseKey
		and	NUMBERTYPE = @psNumberTypeKey
		and	OFFICIALNUMBER = @psOldOfficialNumber

		set @nErrorCode = @@error
	end

	if @nErrorCode = 0
	and @psOfficialNumber is not null
	begin

		-- -----------------------
		-- Validate official number format
		-- Note: the stored procedure uses the event date,
		-- so the event must be written first.

		declare @nPatternError	int
		declare	@sErrorMessage	nvarchar(254)
		declare @nWarningFlag	tinyint	

		exec @nErrorCode = cs_ValidateOfficialNumber 
			@pnPatternError		= @nPatternError output,
			@psErrorMessage		= @sErrorMessage output,
			@pnWarningFlag		= @nWarningFlag output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@pbInvokedByCentura	= 0,
			@pnCaseId 		= @pnCaseKey,
			@psNumberType		= @psNumberTypeKey,
			@psOfficialNumber	= @psOfficialNumber

		set @sErrorMessage = ltrim(rtrim (@sErrorMessage))

		If @nPatternError <> 0 
		and @nWarningFlag = 0 
		and @nErrorCode = 0
		begin
			If @nPatternError = -1
			begin
				-- Format of official number {0} is invalid. {1}.
				-- Message not included because AlertXML exceeds limit with large substitution text.
				Set @sAlertXML = dbo.fn_GetAlertXML('CS9', null,
					'%s', '%s', null, null, null)
				RAISERROR(@sAlertXML, 12, 1, @psOfficialNumber, @sErrorMessage)
				Set @nErrorCode = @@ERROR
			end
			Else
			begin
				-- Validation of official number {0} failed. {1}.
				-- Message not included because AlertXML exceeds limit with large substitution text.
				Set @sAlertXML = dbo.fn_GetAlertXML('CS10', null,
					'%s', '%s', null, null, null)
				RAISERROR(@sAlertXML, 16, 1, @psOfficialNumber, @sErrorMessage)
				Set @nErrorCode = @@ERROR
			end
		end

		if @nErrorCode = 0
		begin
			-- update Official number if necessary
			set @bUpdateOfficialNumber = 1
	
			if @psOldOfficialNumber is not null
			begin
				-- previously existed.			
	
				update 	OFFICIALNUMBERS
				set	OFFICIALNUMBER = @psOfficialNumber,
					ISCURRENT = 1
				where	CASEID = @pnCaseKey
				and	NUMBERTYPE = @psNumberTypeKey
				and	OFFICIALNUMBER = @psOldOfficialNumber
			
				set @nErrorCode = @@error
			end
			else
			begin
				-- add
	
				insert 
				into	OFFICIALNUMBERS (CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)
				values	( @pnCaseKey, @psOfficialNumber, @psNumberTypeKey, 1)
				
				
				set @nErrorCode = @@error
			end
		end
	end

	if @nErrorCode = 0
	and @bUpdateOfficialNumber = 1
	begin
		--update parent reference
		update 	CASES
		set	CURRENTOFFICIALNO = dbo.fn_GetCurrentOfficialNo(@pnCaseKey)
		where	CASEID = @pnCaseKey

		set @nErrorCode = @@error
	end
		
	return @nErrorCode
end
GO

grant execute on dbo.cs_MaintainOfficialNumber to public
go
