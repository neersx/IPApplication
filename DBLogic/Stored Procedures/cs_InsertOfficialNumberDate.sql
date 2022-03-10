-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertOfficialNumberDate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertOfficialNumberDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_InsertOfficialNumberDate.'
	drop procedure [dbo].[cs_InsertOfficialNumberDate]
	print '**** Creating Stored Procedure dbo.cs_InsertOfficialNumberDate...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_InsertOfficialNumberDate
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey		varchar(11) = null, 
	@pnNumberTypeId		int = null,
	@psOfficialNumber	nvarchar(36) = null,
	@pdtEventDate		datetime = null,

	@pnPolicingBatchNo	int = null
)

-- PROCEDURE :	cs_InsertOfficialNumberDate
-- VERSION :	17
-- DESCRIPTION:	See CaseData.doc

-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 14/07/2002	JB		Function created
-- 15/07/2002	SF		Some typos
-- 25/07/2002	JB		Proper error handling
-- 31/07/2002	SF		OFFICIALNUMBERS.DATEENTERED should be null.
-- 23 Oct 2002	JEK	9	Validate official number format.
-- 11 Nov 2002	JEK	10	Update either official number or date or both.
-- 10 Mar 2003	JEK	13	RFC082 Localise stored procedure errors.
-- 17 Mar 2003	SF	14	RFC084 Change to work with the new ip_InsertPolicing
-- 21 Mar 2003	JEK	15	RFC003 Implement cs_MaintainOfficialNumber
-- 15 Apr 2013	DV	16	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
-- 14 May 2020	DL	17  DR-58943 Ability to enter up to 3 characters for Number type code via client server	

as
begin
	declare @nErrorCode int
	declare @nCaseId int
	declare @sCurrentOfficialNo nvarchar(36)
	declare @nRelatedEvent int
	declare @sNumberType nvarchar(3)
	declare @sAlertXML nvarchar(400)

	-- --------------------------
	-- Minimum data requirements
	-- (JB) surely we need @psCaseKey!!
	if (@psOfficialNumber is null 
		or @psOfficialNumber = '')
		and @pdtEventDate is null
		Set @nErrorCode = -1
	else
	begin
		Set @nCaseId = Cast(@psCaseKey as int)

		set @sNumberType = dbo.fn_NumberType(@pnNumberTypeId, null)

		set @nRelatedEvent = null

		set @nErrorCode = @@error
	end


	-- --------------
	-- Create Event
	If @nErrorCode = 0
	   AND @pdtEventDate IS NOT NULL
	Begin
		Select 	@nRelatedEvent = [RELATEDEVENTNO]
			from 	[NUMBERTYPES]
			where 	[NUMBERTYPE] = @sNumberType
	
		Insert into [CASEEVENT]
			(	[CASEID],
				[EVENTNO],
				[EVENTDATE],
				[CYCLE],
				[DATEDUESAVED],
				[OCCURREDFLAG]
			)
			values
			(	@nCaseId,
				@nRelatedEvent,
				@pdtEventDate,
				1,
				0,
				1
			)
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0 and
	   @psOfficialNumber is not null 
	   and @psOfficialNumber != ''
	begin

		exec @nErrorCode = cs_MaintainOfficialNumber
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnCaseKey		= @nCaseId, 
			@psNumberTypeKey	= @sNumberType,
			@psOfficialNumber	= @psOfficialNumber,
			@psOldOfficialNumber	= null

	end

	-- Prepare/Add Policing request
	If @nErrorCode = 0
	   and @nRelatedEvent is not null
	begin
		exec @nErrorCode = ip_InsertPolicing
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@psCaseKey 		= @psCaseKey,
			@psEventKey		= @nRelatedEvent,
			@pnCycle		= 1,
			@psAction		= null,
			@pnTypeOfRequest	= 3,
			@pnPolicingBatchNo	= @pnPolicingBatchNo
	end	

	RETURN @nErrorCode
end
go

grant execute on dbo.cs_InsertOfficialNumberDate to public
go
