-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseEventHistoryData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseEventHistoryData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseEventHistoryData.'
	Drop procedure [dbo].[csw_ListCaseEventHistoryData]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseEventHistoryData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseEventHistoryData
(	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseId		int,		-- Mandatory
	@pnCycle		int,		-- Mandatory
	@pnEventNo		int		-- Mandatory
)
as
-- PROCEDURE:	csw_ListCaseEventHistoryData
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists Case Event History data

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Sep 2009	NG		RFC8102	1	Procedure created
-- 02 Nov 2015	vql		R53910	2	Adjust formatted names logic (DR-15543).
-- 23 May 2015	MF		61817	3	Now that EVENTLONGTEXT is an nvarchar(max) field, it can be reported in the result.
-- 11 Jul 2016	MF		63127	4	If the cycle passed as parameter @pnCycle = 0 then this indicates that all cycles
--						are to be returned.
-- 07 Sep 2018	AV	74738	5	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
Set @sSQLString = "Select 	ROW_NUMBER() OVER(ORDER BY C.LOGACTION DESC) as RowKey,
							E.EVENTDESCRIPTION As 'Event', 
							C.EVENTNO As 'EventNo', 
							isnull(UI.LOGINID,C.LOGUSERID) As 'LoginId', 
							dbo.fn_FormatNameUsingNameNo(N.NAMENO, 7101) As 'AppliedBy',
							C.LOGDATETIMESTAMP As 'DateChanged', 
							C.LOGACTION As 'Action', 
							C.CYCLE As 'Cycle', 
							C.EVENTDATE As 'EventDate', 
							C.EVENTDUEDATE As 'DueDate', 
							C.DATEREMIND As 'DateRemind',
							coalesce(C.EVENTLONGTEXT, C.EVENTLONGTEXT) As 'EventText',
							C.CREATEDBYCRITERIA As 'CreatedByCriteria',
							C.CREATEDBYACTION As 'CreatedByAction',
							C.DATEDUESAVED As 'DueDateSaved',
							C.OCCURREDFLAG As 'OccurredFlag',
							C.ENTEREDDEADLINE As 'EnteredDeadline',
							C.PERIODTYPE As 'PeriodType',
							C.DOCUMENTNO As 'DocumentNo' , 
							C.DOCSREQUIRED As 'DocsRequired' ,
							C.DOCSRECEIVED As 'DocsReceived',
							C.USEMESSAGE2FLAG As 'UseMessage2Flag',
							C.GOVERNINGEVENTNO As 'GoverningEventNo',
							C.JOURNALNO As 'JournalNo',
							C.IMPORTBATCHNO As 'ImportBatchNo',
							C.FROMCASEID As 'FromCaseId', 
							CA.IRN As 'FromCase',
							C.LOGUSERID As 'SQLUser'                                                                                                                                                                                                                                                                                                                                                                                                                                                
					from 	CASEEVENT_iLOG C   
							inner join 	EVENTS E on E.EVENTNO = C.EVENTNO  
							left join	USERIDENTITY UI on (UI.IDENTITYID = C.LOGIDENTITYID)  
							left join	NAME N on (N.NAMENO = isnull(UI.NAMENO,(select min(UI1.NAMENO) from USERIDENTITY UI1  where UI1.LOGINID=C.LOGUSERID)))  
							left join 	CASES CA on (CA.CASEID = C.FROMCASEID)  
					where 	C.EVENTNO = @pnEventNo               	
							and C.CYCLE = CASE WHEN(@pnCycle>0) THEN @pnCycle ELSE C.CYCLE END
							and C.CASEID = @pnCaseId        
					order by 	C.CYCLE, C.LOGDATETIMESTAMP desc"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnEventNo	int,
				  @pnCaseId		int,
				  @pnCycle		int',
				  @pnEventNo = @pnEventNo ,
				  @pnCaseId = @pnCaseId,
				  @pnCycle = @pnCycle

End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseEventHistoryData to public
GO