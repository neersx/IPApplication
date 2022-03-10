-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ev_ListNewEvents
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ev_ListNewEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ev_ListNewEvents.'
	Drop procedure [dbo].[ev_ListNewEvents]
	Print '**** Creating Stored Procedure dbo.ev_ListNewEvents...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ev_ListNewEvents
	@pnRowCount			int		= 0	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	-- Filter Parameters
	@pnLogTransactionNo		int		= null, -- TransactionNo used in audit log to create the Event.
	@pdtLogDateCreatedFrom		datetime	= null,	-- The starting log date from which the Event was created.
	@pdtLogDateCreatedUntil		datetime	= null, -- The ending log date for the filter in which the Event was created.
	@psEventDescription		nvarchar(100)	= null, -- Returns Events whose description is LIKE the entered description
	@psActionKey			nvarchar(2)	= null,	-- Restricts Events associated with a specific Action
	@pbLastLawUpdatesDelivered	bit		= 0	-- When 1 get the Events added with the last Law Update Service.

AS

-- PROCEDURE :	ev_ListNewEvents
-- VERSION :	2
-- DESCRIPTION:	Returns the recently added Events, that matches the filter criteria provided.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date			Who		Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 24 Jun 2013	MF 		S21404	1		Procedure created.
-- 08 Jul 2013	DL		S21404	2		Extract Events and EventControl separately to display the event and criteria as a tree structure.		

set nocount on

------------
-- Variables
------------
declare @ErrorCode		int
declare @sSQLString		nvarchar(max)
declare @sSQLString2		nvarchar(max)
declare @sSQLStringFilter		nvarchar(max)

set @ErrorCode = 0

--------------------------
-- Validate the existence 
-- of logging tables for 
-- Events.
--------------------------
If @pnLogTransactionNo     is not null
or @pdtLogDateCreatedFrom  is not null
or @pdtLogDateCreatedUntil is not null
Begin
	If not exists(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EVENTS_iLOG')
	Begin
		RAISERROR('Audit logs for the EVENTS table is required to use this functionality.', 14, 1)
		Set @ErrorCode = @@ERROR
	End
End

---------------------------
-- Get the LOGTRANSACTIONNO 
-- used to load the last
-- CPA Law Updates.
---------------------------
If  @pbLastLawUpdatesDelivered=1
and @ErrorCode=0
Begin
	Select @pnLogTransactionNo=LOGTRANSACTIONNO
	from SITECONTROL
	where CONTROLID='CPA Law Update Service'
	and LOGTRANSACTIONNO is not null
	
	Set @ErrorCode=@@ERROR
	
	If  @pnLogTransactionNo is null
	and @ErrorCode=0
	Begin
		RAISERROR('Unable to determine when Law Updates were loaded. Try using a different filter.', 14, 1)
		Set @ErrorCode = @@ERROR
	End
End

If @ErrorCode=0
Begin
	-----------------------------	
	-- Strip time from date range
	-----------------------------
	If @pdtLogDateCreatedFrom is not null
		Set @pdtLogDateCreatedFrom   = cast(convert(varchar, @pdtLogDateCreatedFrom, 112) as datetime)
		
	If @pdtLogDateCreatedUntil is not null
		Set @pdtLogDateCreatedUntil  = cast(convert(varchar, @pdtLogDateCreatedUntil+1, 112) as datetime)
End

-----------------------------	
-- Construct dynamic SQL
-----------------------------
If @ErrorCode=0
Begin
	----------------------------
	-- Construct the SELECT list
	----------------------------
	-- This query extracts the distinct events only
	Set @sSQLString="
	Select distinct E.EVENTNO, 
		E.EVENTDESCRIPTION, 
		null as 'EC.EVENTDESCRIPTION', 
		null as 'EC.CRITERIANO', 
		null as 'C.DESCRIPTION',
		E.SUPPRESSCALCULATION,
		null as 'EC.SUPPRESSCALCULATION'
	from EVENTS E
	join EVENTCONTROL EC on (EC.EVENTNO=E.EVENTNO)
	join CRITERIA C      on ( C.CRITERIANO=EC.CRITERIANO)"

	-- This query extracts events and associated criteria controls
	-- These queries (@sSQLString and @sSQLString2) will be unioned to return one result set.
	Set @sSQLString2="
	Select E.EVENTNO, 
		E.EVENTDESCRIPTION, 
		EC.EVENTDESCRIPTION, 
		EC.CRITERIANO, 
		C.DESCRIPTION,
		null as 'E.SUPPRESSCALCULATION',
		EC.SUPPRESSCALCULATION
	from EVENTS E
	join EVENTCONTROL EC on (EC.EVENTNO=E.EVENTNO)
	join CRITERIA C      on ( C.CRITERIANO=EC.CRITERIANO)"
	
	
	Set @sSQLStringFilter = ""
	
	----------------------------------------------
	-- Any filtering on when the row was inserted
	-- requires the use of EVENTS_iLOG
	----------------------------------------------
	If @pnLogTransactionNo     is not null
	or @pdtLogDateCreatedFrom  is not null
	or @pdtLogDateCreatedUntil is not null
	Begin
		Set @sSQLStringFilter=@sSQLStringFilter+char(10)+char(9)+
			"join EVENTS_iLOG EL  on (EL.EVENTNO=E.EVENTNO"+char(10)+char(9)+
			"                     and EL.LOGACTION='I')"
	End
	
	-----------------------------
	-- Construct the WHERE clause
	-----------------------------
		
	Set @sSQLStringFilter=@sSQLStringFilter+char(10)+char(9)+"Where 1=1"
	
	If @pnLogTransactionNo is not null
	Begin
		Set @sSQLStringFilter=@sSQLStringFilter+char(10)+char(9)+
			"and EL.LOGTRANSACTIONNO=@pnLogTransactionNo"
	End
	
	If  @pdtLogDateCreatedFrom  is not null
	and @pdtLogDateCreatedUntil is not null
	Begin		
		Set @sSQLStringFilter=@sSQLStringFilter+char(10)+char(9)+
			"and EL.LOGDATETIMESTAMP between @pdtLogDateCreatedFrom and @pdtLogDateCreatedUntil"
	End
	Else If @pdtLogDateCreatedFrom is not null
	Begin
		Set @sSQLStringFilter=@sSQLStringFilter+char(10)+char(9)+
			"and EL.LOGDATETIMESTAMP >= @pdtLogDateCreatedFrom"
	End
	Else If @pdtLogDateCreatedUntil is not null
	Begin
		Set @sSQLStringFilter=@sSQLStringFilter+char(10)+char(9)+
			"and EL.LOGDATETIMESTAMP < @pdtLogDateCreatedUntil"
	End
	
	If @psEventDescription is not null
	Begin
		Set @sSQLStringFilter=@sSQLStringFilter+char(10)+char(9)+
			"and (E.EVENTDESCRIPTION LIKE '"+ @psEventDescription+"' OR EC.EVENTDESCRIPTION LIKE '"+ @psEventDescription+"')"
	End
	
	IF @psActionKey is not null
	Begin
		Set @sSQLStringFilter=@sSQLStringFilter+char(10)+char(9)+
			"and C.ACTION = @psActionKey"
	End

	--------------------------------
	-- Construct the query with union
	--------------------------------
	Set @sSQLString=@sSQLString+char(10)+char(9)+ @sSQLStringFilter +char(10)+char(9)+ 'UNION ALL ' +char(10)+char(9)+ @sSQLString2 + char(10)+char(9)+ @sSQLStringFilter 
	
	--------------------------------
	-- Construct the ORDER BY clause
	--------------------------------
	Set @sSQLString=@sSQLString+char(10)+char(9)+"ORDER BY 2,1,3,5,4"
	
	--------------------------------
	-- Execute the constructed SQL
	--------------------------------
	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnLogTransactionNo		int,
				  @pdtLogDateCreatedFrom	datetime,
				  @pdtLogDateCreatedUntil	datetime,
				  @psActionKey			nvarchar(2)',
				  @pnLogTransactionNo		= @pnLogTransactionNo, 
				  @pdtLogDateCreatedFrom	= @pdtLogDateCreatedFrom, 
				  @pdtLogDateCreatedUntil	= @pdtLogDateCreatedUntil,
				  @psActionKey			= @psActionKey
	Set @pnRowCount=@@ROWCOUNT
End

Return @ErrorCode
GO

Grant execute on dbo.ev_ListNewEvents to public
GO
