-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListActionEventData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListActionEventData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListActionEventData.'
	Drop procedure [dbo].[csw_ListActionEventData]
End
Print '**** Creating Stored Procedure dbo.csw_ListActionEventData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListActionEventData
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,		-- Mandatory
	@psActionKey		nvarchar(2),
	@pnCycle		smallint
)
as
-- PROCEDURE:	csw_ListActionEventData
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates ActionEventData dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Jan 2006	TM	RFC3279	1	Procedure created
-- 08 Feb 2006	TM	RFC3427	2	Modify the extraction of events  for cyclic and non-cyclic actions 
--					to exclude any events that are not associated with a specific action.
-- 18 Sep 2006	AU	RFC4144	3	Return "FromCaseReference" column.
-- 11 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Oct 2011	ASH	R11460  5	Cast integer columns as nvarchar(11) data type.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @bIsCyclic	bit
Declare @sOrder		nvarchar(1000)

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @bIsCyclic 		= 0

-- Get information required to construct the main Select statement
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  @bIsCyclic = CASE WHEN A.NUMCYCLESALLOWED > 1 THEN 1 ELSE 0 END,
		@sOrder = 
		CASE  	WHEN SC.COLCHARACTER = 'ES'
			THEN 'EC.DISPLAYSEQUENCE, Cycle'
			WHEN SC.COLCHARACTER = 'ED'
			THEN 'EventDate, Cycle, EC.DISPLAYSEQUENCE'
			WHEN SC.COLCHARACTER = 'DD'
			THEN 'DueDate, Cycle, EC.DISPLAYSEQUENCE'
			WHEN SC.COLCHARACTER = 'NR'
			THEN 'NextPoliceDate, Cycle, EC.DISPLAYSEQUENCE'
			WHEN SC.COLCHARACTER = 'IL'
			THEN 'isnull(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL), Cycle, EC.DISPLAYSEQUENCE'
			WHEN SC.COLCHARACTER = 'CD'
			THEN 'Cycle, ISNULL(CE.EVENTDATE,CE.EVENTDUEDATE), EC.DISPLAYSEQUENCE'
			ELSE 'EC.DISPLAYSEQUENCE, Cycle'
		END				
	from    ACTIONS A
	left join SITECONTROL SC on (SC.CONTROLID = 'Case Event Default Sorting')
	where  A.ACTION = @psActionKey"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bIsCyclic	bit		output,
					  @sOrder	nvarchar(1000)	output,
					  @psActionKey	nvarchar(2)',
					  @bIsCyclic	= @bIsCyclic	output,
					  @sOrder	= @sOrder	output,
					  @psActionKey	= @psActionKey
End

-- Populate ActionEventData dataset
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  CAST(CE.CASEID as nvarchar(11))+'^'+
		CAST(CE.EVENTNO as nvarchar(11))+'^'+
		CAST(CE.CYCLE as nvarchar(5))	as 'RowKey',
		isnull("+
		dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+', '+
		dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")
						as 'EventDescription',
		CE.EVENTDATE			as 'EventDate',
		CE.EVENTDUEDATE			as 'DueDate',
		CE.CYCLE     			as 'Cycle',
		CE.DATEREMIND			as 'NextPoliceDate',
		case when CE.LONGFLAG = 1 then CE.EVENTLONGTEXT else CE.EVENTTEXT end
						as 'EventText',
		C.IRN				as 'FromCaseReference',
		E.IMPORTANCELEVEL as 'ImportanceLevel',
		cast(0 as bit) as 'IsNew',
		cast(case when (CE.IMPORTBATCHNO is null)then 0 else 1  end as bit) as 'HasImportBatchKey',
		cast(case when (CE.EVENTDUEDATE < getdate()) then 1 else 0 end as bit) as 'IsDueDatePast',
		cast(case when (CE.DATEREMIND < getdate()) then 1 else 0 end as bit) as 'IsReminderDatePast',
		cast(case when (CE.EVENTDUEDATE > getdate()and CE.DATEDUESAVED = 1 ) then 1 else 0 end as bit) as 'IsDueDateFuture'" +char(10)+
	"from OPENACTION OA
	join CASEEVENT CE		on (CE.CASEID = OA.CASEID"+
	CASE	WHEN @bIsCyclic = 1
		THEN char(10)+" and CE.CYCLE = OA.CYCLE)"		    
		ELSE char(10)+" and  CE.CYCLE = (Select max(CE2.CYCLE)"+
		     char(10)+"			from  CASEEVENT CE2"+
		     char(10)+"			where CE2.CASEID = CE.CASEID"+
		     char(10)+"			and   CE2.EVENTNO = CE.EVENTNO))"
	END+char(10)+"
	join EVENTS E 			on (E.EVENTNO = CE.EVENTNO)
	join EVENTCONTROL EC 		on (EC.CRITERIANO = OA.CRITERIANO
					and EC.EVENTNO = CE.EVENTNO)
	left join CASES C		on (C.CASEID = CE.FROMCASEID)
	where  OA.CASEID = @pnCaseKey
	and    OA.CYCLE = @pnCycle
	and    OA.ACTION = @psActionKey
	and    OA.CRITERIANO = EC.CRITERIANO 	
	-- CASEEVENT rows are only returned if there is at least  
	-- one of EVENTDATE or EVENTDUEDATE present.
	and   (CE.EVENTDUEDATE is not null 
	 or    CE.EVENTDATE is not null)
	-- Only events that are not satisfied are returned
	and    CE.OCCURREDFLAG < 9
	order by "+@sOrder 

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey	int,
				  @pnCycle	smallint,
				  @psActionKey	nvarchar(2)',
				  @pnCaseKey	= @pnCaseKey,
				  @pnCycle	= @pnCycle,
				  @psActionKey	= @psActionKey

	Set @pnRowCount = @@RowCount
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListActionEventData to public
GO
