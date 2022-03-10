-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListCaseSummaryEvents
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListCaseSummaryEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListCaseSummaryEvents'
	drop procedure [dbo].[wa_ListCaseSummaryEvents]
	print '**** Creating procedure dbo.wa_ListCaseSummaryEvents...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

CREATE PROCEDURE [dbo].[wa_ListCaseSummaryEvents]
	@pnCaseId	int
AS
-- PROCEDURE :	wa_ListCaseSummaryEvents
-- VERSION :	9
-- DESCRIPTION:	Selects a list of events for a given CaseID
--				If the currently connected user is external then the list is filtered by
--				an importance level set as a Site Control
-- CALLED BY :	

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/07/2001	AF			Procedure created
-- 03/08/2001	MF			Only display details if the user has the correct access rights
-- 13/08/2001	MF			Change the extraction of CaseEvents so that it uses the SiteControl option
--					to determine the importance level for internal users as well as external
--					users.  Also get the default sort order from the Sitecontrol.
-- 27/08/2001	MF			Restrict the Events displayed if a specific Action is elected via a Sitecontrol.
-- 28/11/2001	MF	7245		If the DATEOFACT is null then return 1-JAN-1800 when determining the 
--					best Criteriano to use.
-- 04/12/2001	MF	7261		Change 'Client Action' and 'Enquiry Action' to 'Client PublishAction' and
--					'Publish Action' respectively.
-- 17/10/2002	MF	8088		If the EventDate exists then do not dislay the EventDueDate
-- 15 Dec 2008	MF	17136	8	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Jul 2016	MF	63861	9	A null LOCALCLIENTFLAG should default to 0.

begin
	-- disable row counts
	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF
	
	-- declare variables
	declare @sSql			nvarchar(4000) 	-- the SQL to execute
	declare @sOrder			nvarchar(500)	-- the SQL to order
	declare @sColCharacter		nvarchar(254)	-- the defaul sort order
	declare	@sParmDefinition	nvarchar(500)	-- definition of parameters for dynamic SQL
	
	declare @ErrorCode		int
	declare	@nImportanceLevel	smallint	-- the importance level of events the user is allowed to see 
	declare @sDisplayAction		varchar(2)	-- the default action the user will see events for
	declare @nCriteriaNo		int		-- the Criteria to extract the details for

	set @nCriteriaNo=NULL

	-- Check that external users have access to see the details of the case.

	Execute @ErrorCode=wa_CheckSecurityForCase @pnCaseId
	
	if @ErrorCode=0
	begin
		-- Initialise the ImportanceLevel and the Action the user is allowed to see

		select 	@nImportanceLevel=	CASE WHEN(EXTERNALUSERFLAG > 1) THEN isnull(S1.COLINTEGER,0)
										ELSE isnull(S2.COLINTEGER,0)
						END,
			@sDisplayAction  =	CASE WHEN(EXTERNALUSERFLAG > 1) THEN S3.COLCHARACTER 
										ELSE S4.COLCHARACTER
						END,
			@sColCharacter	= 	S5.COLCHARACTER
		from USERS U
		left join SITECONTROL S1	on (S1.CONTROLID='Client Importance')
		left join SITECONTROL S2	on (S2.CONTROLID='Events Displayed')
		left join SITECONTROL S3	on (S3.CONTROLID='Client PublishAction')
		left join SITECONTROL S4	on (S4.CONTROLID='Publish Action')
		left join SITECONTROL S5	on (S5.CONTROLID='Event Display Order')
	 	where	U.USERID      = user

		select @ErrorCode=@@Error
	end

	-- initialise the sort order of the rows returned.

	If @ErrorCode=0
	Begin
		set @sOrder = "		Order By "

		if  @sColCharacter = 'AA' Set @sOrder = @sOrder + "E.EVENTDATE ASC, 3 ASC"
		else
		if  @sColCharacter = 'AD' Set @sOrder = @sOrder + "E.EVENTDATE ASC, 3 DESC"
		else
		if  @sColCharacter = 'DA' Set @sOrder = @sOrder + "E.EVENTDATE DESC, 3 ASC"
		else
		if  @sColCharacter = 'DD' Set @sOrder = @sOrder + "E.EVENTDATE DESC, 3 DESC"
		
	End

	if  @ErrorCode=0
	and @sDisplayAction is not null
	begin
		-- if an action has been passed then extract the events for that Action

		-- first check if an OpenAction row exists for the Case and the elected Action to get the CriteriaNo.

		select @nCriteriaNo=min(CRITERIANO)
		from OPENACTION 
		where CASEID=@pnCaseId 
		and ACTION=@sDisplayAction

		select @ErrorCode=@@Error

		if  @ErrorCode=0
		and @nCriteriaNo is null
		begin
			-- if the CriteriaNo is still not known then perform a best fit to get the Criteriano

			SELECT @nCriteriaNo = convert (int, substring (
			max (	CASE WHEN (C.PROPERTYTYPE    IS NULL) THEN '0' ELSE '1' END
			+	CASE WHEN (C.COUNTRYCODE     IS NULL) THEN '0' ELSE '1' END 
			+	CASE WHEN (C.CASECATEGORY    IS NULL) THEN '0' ELSE '1' END 
			+	CASE WHEN (C.SUBTYPE         IS NULL) THEN '0' ELSE '1' END 
			+	CASE WHEN (C.BASIS           IS NULL) THEN '0' ELSE '1' END 
			+	CASE WHEN (C.REGISTEREDUSERS IS NULL) THEN '0' ELSE '1' END 
			+	CASE WHEN (C.LOCALCLIENTFLAG IS NULL) THEN '0' ELSE '1' END 
			+	CASE WHEN (C.TABLECODE       IS NULL) THEN '0' ELSE '1' END 
			+	CASE WHEN (C.DATEOFACT       IS NULL) THEN '0' ELSE '1' END 
			+	convert(char(8),isnull(C.DATEOFACT,'1-JAN-1800'),112)
			+	convert(char(9),C.CRITERIANO) ), 18,9))
			FROM CRITERIA C
			     join CASES CS	on (CS.CASEID=@pnCaseId)
			left join PROPERTY P	on (P.CASEID =CS.CASEID)
			WHERE C.RULEINUSE = 1  
			AND C.PURPOSECODE = 'E' 
			AND C.CASETYPE    = CS.CASETYPE
			AND C.ACTION      = @sDisplayAction
			AND ( C.PROPERTYTYPE    = CS.PROPERTYTYPE OR C.PROPERTYTYPE IS NULL ) 
			AND ( C.COUNTRYCODE     = CS.COUNTRYCODE  OR C.COUNTRYCODE  IS NULL ) 
			AND ( C.CASECATEGORY    = CS.CASECATEGORY OR C.CASECATEGORY IS NULL ) 
			AND ( C.SUBTYPE         = CS.SUBTYPE      OR C.SUBTYPE      IS NULL ) 
			AND ( C.BASIS           = P.BASIS         OR C.BASIS        IS NULL ) 
			AND ( C.REGISTEREDUSERS = P.REGISTEREDUSERS OR C.REGISTEREDUSERS is NULL ) 
			AND ( C.LOCALCLIENTFLAG = isnull(CS.LOCALCLIENTFLAG,0) OR C.LOCALCLIENTFLAG is NULL ) 
			AND ( C.TABLECODE       = P.EXAMTYPE
			OR C.TABLECODE = P.RENEWALTYPE OR C.TABLECODE IS NULL ) 
			AND ( C.DATEOFACT      <=  getdate() OR C.DATEOFACT IS NULL ) 

			select @ErrorCode=@@Error
		end
	end

	if  @ErrorCode=0
	and @nCriteriaNo is not null
	begin

		--  If the CriteriaNo is known then get events for the Event Control

		set @sParmDefinition=N'@pnCaseId int,  @nImportanceLevel smallint, @nCriteriaNo int'

		set @sSql="	
		select 	DISTINCT 
			E.EVENTNO,
			E.EVENTDATE,
			CASE WHEN(E.OCCURREDFLAG=0 or E.OCCURREDFLAG is null) THEN E.EVENTDUEDATE END as EVENTDUEDATE,
			EC.EVENTDESCRIPTION,
			E.CREATEDBYCRITERIA,
			E.EVENTTEXT,
			E.LONGFLAG,
			E.CYCLE,
			E.IMPORTBATCHNO,
			EC.DISPLAYSEQUENCE
		from EVENTCONTROL EC
		join CASEEVENT E	on (E.EVENTNO= EC.EVENTNO
					and E.OCCURREDFLAG<9)
	 	where	EC.CRITERIANO=@nCriteriaNo
		and	E.CASEID = @pnCaseId
		and	EC.IMPORTANCELEVEL>=@nImportanceLevel"

		-- If specific sort order has not been set then sort by EventControl Display Sequence

		if @sColCharacter is null 
			Set @sOrder = @sOrder + "EC.DISPLAYSEQUENCE ASC, EC.EVENTNO, E.CYCLE"
		
		-- Construct the SELECT and execute it

		Set @sSql = @sSql + char(10) + @sOrder

		exec @ErrorCode=sp_executesql @sSql, @sParmDefinition, @pnCaseId, @nImportanceLevel, @nCriteriaNo

	end
	else if  @ErrorCode = 0
	     and @nCriteriaNo is null
	begin

		--  If the CriteriaNo is not known then just get events that match the Importance Level

		set @sParmDefinition=N'@pnCaseId int,  @nImportanceLevel smallint'

		set @sSql="	
		select 	DISTINCT 
			E.EVENTNO,
			E.EVENTDATE,
			CASE WHEN(E.OCCURREDFLAG=0 or E.OCCURREDFLAG is null) THEN E.EVENTDUEDATE END as EVENTDUEDATE,
			isnull(EC.EVENTDESCRIPTION, EV.EVENTDESCRIPTION) as EVENTDESCRIPTION,
			E.CREATEDBYCRITERIA,
			E.EVENTTEXT,
			E.LONGFLAG,
			E.CYCLE,
			E.IMPORTBATCHNO,
			EC.DISPLAYSEQUENCE
		from CASEEVENT E
		     join EVENTS EV	  on (EV.EVENTNO=E.EVENTNO)
		left join EVENTCONTROL EC on (EC.CRITERIANO=E.CREATEDBYCRITERIA
					  and EC.EVENTNO=E.EVENTNO)
	 	where	E.CASEID = @pnCaseId
		and	E.OCCURREDFLAG<9
		and	E.EVENTNO <> -11	-- Exclude the NRD which is extracted on its own
		and	(EC.IMPORTANCELEVEL>=@nImportanceLevel OR (EV.IMPORTANCELEVEL>=@nImportanceLevel AND EC.IMPORTANCELEVEL is null))"

		-- If specific sort order has not been set then sort by EventDate descending and Event Due Date ascending

		if @sColCharacter is null 
			Set @sOrder = @sOrder + "E.EVENTDATE DESC, 3 ASC"
		
		-- Construct the SELECT and execute it

		Set @sSql = @sSql + char(10) + @sOrder

		exec @ErrorCode=sp_executesql @sSql, @sParmDefinition, @pnCaseId, @nImportanceLevel
	end

	return @ErrorCode
end
go

grant execute on [dbo].[wa_ListCaseSummaryEvents] to public
go
