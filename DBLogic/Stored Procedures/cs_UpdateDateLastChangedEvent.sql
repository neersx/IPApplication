-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateDateLastChangedEvent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateDateLastChangedEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_UpdateDateLastChangedEvent.'
	Drop procedure [dbo].[cs_UpdateDateLastChangedEvent]
	Print '**** Creating Stored Procedure dbo.cs_UpdateDateLastChangedEvent...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

CREATE PROCEDURE dbo.cs_UpdateDateLastChangedEvent
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psCaseKey		nvarchar(11)	= null
)
-- PROCEDURE :	cs_UpdateDateLastChangedEvent
-- VERSION :	4
-- DESCRIPTION:	See CaseData.doc
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 27/07/2002	SF	Procedure created
-- 15 Apr 2013	DV	4 R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
	declare @nErrorCode int
	declare @nCaseId int

	set @nCaseId = cast(@psCaseKey as int)

	set @nErrorCode = @@error

	if @nErrorCode = 0
	and exists(	select 	* 
			from	CASEEVENT
			where	CASEID = @nCaseId
			and	EVENTNO = -14)
	begin
		update 	CASEEVENT
		set	EVENTDATE = dbo.fn_DateOnly(getdate())
		where	CASEID = @nCaseId
		and	EVENTNO = -14
		
		set @nErrorCode = @@Error
	end
	else
	begin
		insert 	CASEEVENT (
			CASEID,
			EVENTNO,
			EVENTDATE,
			CYCLE,
			DATEDUESAVED,
			OCCURREDFLAG)
		values (
			@nCaseId,
			-14,
			dbo.fn_DateOnly(getdate()),
			1,
			0,
			1)

		set @nErrorCode = @@error
	end

	return @nErrorCode
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_UpdateDateLastChangedEvent to public
GO
