-----------------------------------------------------------------------------------------------------------------------------
-- Creation of demo_generateCasesForPolicing
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[demo_generateCasesForPolicing]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.demo_generateCasesForPolicing.'
	Drop procedure [dbo].[demo_generateCasesForPolicing]
End
Print '**** Creating Stored Procedure dbo.demo_generateCasesForPolicing...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.demo_generateCasesForPolicing
(
	@pnRequired int = null,
	@psGenOptions nchar = null
)
as
begin

	declare @current int
	declare @count int
	set		@current = 0
	set		@count = 0
	
	create table #candidate
	(
		CASEID int not null,
		EVENTNO int not null,
		CYCLE int not null,
		CRITERIANO int null,
		MODIFIED datetime null
	)

	set @pnRequired = isnull(@pnRequired, FLOOR(RAND()*(200-10)+10))

	declare @sql nvarchar(max)
	declare @caseId int
	declare @eventNo int
	declare @cycle int
	declare @identityId int
	declare @modified datetime
	declare @error int
	declare @seq int
	declare @now datetime
	declare @today datetime
	
	set @sql = '
	insert #candidate (CASEID, EVENTNO, CYCLE, CRITERIANO, MODIFIED)
	select top ' + cast(@pnRequired as nvarchar(12)) +' CE.CASEID, CE.EVENTNO, CE.CYCLE, CE.CREATEDBYCRITERIA, CE.LOGDATETIMESTAMP
	from CASEEVENT CE
	join (	select top 1000 CE1.CASEID, CE1.EVENTNO, CE1.CYCLE, CE1.CREATEDBYCRITERIA
			from CASEEVENT CE1 
			left join EVENTS E on E.EVENTNO = CE1.EVENTNO and E.EVENTDESCRIPTION not like ''Close%''
			where CE1.EVENTNO not in (-14, -16, -13)
			order by CE1.LOGDATETIMESTAMP asc) e on 
				(CE.CASEID = e.CASEID and CE.EVENTNO = e.EVENTNO and CE.CYCLE = e.CYCLE)
	ORDER BY newid()'
	
	exec @error = sp_executesql @sql

	select @now = case when @psGenOptions = 'f' then getdate() else dateadd(minute, -3, getdate()) end

	set @today = dbo.fn_DateOnly(getdate())

	declare candidate_cursor cursor for select CASEID, EVENTNO, CYCLE, MODIFIED from #candidate  
		
	open candidate_cursor

	fetch next from candidate_cursor into @caseId, @eventNo, @cycle, @modified

	while @@FETCH_STATUS = 0 and @current <= @pnRequired
	begin
	
		select top 1 @identityId = P.IDENTITYID 
		from POLICING P
		WHERE SYSGENERATEDFLAG = 1 
		AND CASEID = @caseId
		AND P.IDENTITYID IS NOT NULL

		select top 1 @identityId = U.IDENTITYID 
		from USERIDENTITY U
		where exists (
			select *
			from dbo.fn_PermissionsGranted(U.IDENTITYID, 'TASK', 56, null, @now) P /* Maintain Case, Update Permission */
			where P.CanUpdate = 1
		)
		and @identityId is null
		and U.ISVALIDWORKBENCH = 1
		order by newid()

		exec @error = csw_MaintainCaseEvent
			@pnUserIdentityId		= @identityId,
			@pnCaseKey				= @caseId,
			@pnEventKey				= @eventNo,
			@pnEventCycle			= @cycle,
			@pdtEventDate			= @today,
			@pdtLastModifiedDate	= @modified output

		if (@psGenOptions = 'e' or @psGenOptions = 'f')
		begin
			begin transaction;
				DISABLE TRIGGER [tU_POLICING_Audit] on POLICING
				begin
					update POLICING
					set ONHOLDFLAG = case when @psGenOptions = 'e' then 2 else 4 end,
						LOGDATETIMESTAMP = case when @psGenOptions = 'e' then LOGDATETIMESTAMP else DATEADD(minute, -2, LOGDATETIMESTAMP) end
					where DATEENTERED > @now 
					and CASEID = @caseId 
					and EVENTNO = @eventNo 
					and CYCLE = @cycle
					and SYSGENERATEDFLAG = 1
				end;
				ENABLE TRIGGER [tU_POLICING_Audit] on POLICING
			commit transaction;

			insert POLICINGLOG(STARTDATETIME, IDENTITYID)
			select DATEENTERED, @identityId
			from POLICING P
			where DATEENTERED > @now 
			and CASEID = @caseId 
			and EVENTNO = @eventNo 
			and CYCLE = @cycle
			and SYSGENERATEDFLAG = 1
			and ONHOLDFLAG = case when @psGenOptions = 'e' then 2 else 4 end

			if (@psGenOptions = 'e')
			begin

				SELECT @count = FLOOR(RAND()*(25-3)+3)

				select @seq = max(ERRORSEQNO)
				from POLICINGERRORS PE 
				where STARTDATETIME > @now 
				and CASEID = @caseId 
				and EVENTNO = @eventNo 
				and CYCLENO = @cycle

				while @count > isnull(@seq, 1)
				begin
			
					insert POLICINGERRORS(STARTDATETIME, ERRORSEQNO, CASEID, CRITERIANO, EVENTNO, CYCLENO, MESSAGE)
					select DATEENTERED, ROW_NUMBER() over (order by REQUESTID) + isnull(@seq, 0), CASEID, CRITERIANO, EVENTNO, CYCLE, N'This is a pretend error'
					from POLICING
					where DATEENTERED > @now 
					and CASEID = @caseId 
					and EVENTNO = @eventNo 
					and CYCLE = @cycle
					and SYSGENERATEDFLAG = 1
			
					select @seq = max(ERRORSEQNO)
					from POLICINGERRORS PE 
					where STARTDATETIME > @now 
					and CASEID = @caseId 
					and EVENTNO = @eventNo 
					and CYCLENO = @cycle

				end
			end
		end

		set @current = @current + 1

		fetch next from candidate_cursor into @caseId, @eventNo, @cycle, @modified
	end 

	close candidate_cursor;
	deallocate candidate_cursor;

	Return @error
end


Grant execute on dbo.demo_generateCasesForPolicing to public

