-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rem_GetReminderDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rem_GetReminderDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rem_GetReminderDetails.'
	Drop procedure [dbo].[rem_GetReminderDetails]
End
Print '**** Creating Stored Procedure dbo.rem_GetReminderDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.rem_GetReminderDetails
(							
	@pnEmployeeNo	int,
	@pdtMessageSeq	datetime

)
as
-- PROCEDURE:	rem_GetReminderDetails
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns reminder details as two columns: Detail Name - Detail Value

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	------	--------	-------	----------------------------------------------- 
-- 27 Apr 2007	IB	SQA14511	1	Procedure created
-- 20 Nov 2008	MF	SQA17137	2	Client reference incorrectly looking at Owner instead of Instructor
-- 20 Dec 2008	MF	SQA17251	3	Return the name of the governing event and date.
-- 20 Jan 2009	MF	SQA17252	4	Return the designated countries associated with the reminder.
-- 17 Sep 2010	MF	RFC9777		5	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 05 Jul 2013	vql	R13629		6	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910		7	Adjust formatted names logic (DR-15543).
-- 30 Mar 2016	MF	R59842		8	The Governing Event being reported as "Arising from" is allowed to be a due date.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int	

-- Initialise variables
Set @nErrorCode 		= 0

If  @nErrorCode = 0
Begin
	Select 	'Case Title', 
		C.TITLE,
		1
	from EMPLOYEEREMINDER ER
     	left join CASES C 		on (C.CASEID = ER.CASEID)
	where 				ER.EMPLOYEENO = @pnEmployeeNo
					and   ER.MESSAGESEQ = @pdtMessageSeq
					and   C.TITLE is not null

	Union All

	Select 	'Client',
		cast(dbo.fn_FormatNameUsingNameNo(N.NAMENO, N.NAMESTYLE) as nvarchar(254)),
		2
	from EMPLOYEEREMINDER ER
	join CASENAME CN 		on (CN.CASEID = ER.CASEID
					and CN.NAMETYPE = 'I'
					and CN.SEQUENCE = (select min(SEQUENCE)
						from  CASENAME CN2
						where CN2.CASEID = ER.CASEID
						and CN2.NAMETYPE = CN.NAMETYPE
						and CN2.EXPIRYDATE is null))
	join NAME N 			on (N.NAMENO = CN.NAMENO)
	where 				ER.EMPLOYEENO = @pnEmployeeNo
					and   ER.MESSAGESEQ = @pdtMessageSeq

	Union All

	Select 	'Client Reference',
		CN.REFERENCENO,
		3
	from EMPLOYEEREMINDER ER
	join CASENAME CN 		on (CN.CASEID = ER.CASEID
					and CN.NAMETYPE = 'I'
					and CN.SEQUENCE = (select min(SEQUENCE)
						from  CASENAME CN2
						where CN2.CASEID = ER.CASEID
						and CN2.NAMETYPE = CN.NAMETYPE
						and CN2.EXPIRYDATE is null))
	join NAME N 			on (N.NAMENO = CN.NAMENO)
	where 				ER.EMPLOYEENO = @pnEmployeeNo
					and   ER.MESSAGESEQ = @pdtMessageSeq

	Union All

	Select 	'Classes', 
		isnull(C.LOCALCLASSES,C.INTCLASSES),
		4
	from EMPLOYEEREMINDER ER
     	join CASES C 			on (C.CASEID = ER.CASEID)
	where 				ER.EMPLOYEENO = @pnEmployeeNo
					and   ER.MESSAGESEQ = @pdtMessageSeq
					and isnull(C.LOCALCLASSES,C.INTCLASSES) is not null

	Union All

	Select 	'Application No:', 
		O.OFFICIALNUMBER,
		5
	from EMPLOYEEREMINDER ER
     	join OFFICIALNUMBERS O		on (O.CASEID = ER.CASEID
					and O.NUMBERTYPE='A')
	where 				ER.EMPLOYEENO = @pnEmployeeNo
					and   ER.MESSAGESEQ = @pdtMessageSeq

	Union All

	Select 	'Owner', 	
		cast(dbo.fn_FormatNameUsingNameNo(N.NAMENO, N.NAMESTYLE) as nvarchar(254)),
		6
	from EMPLOYEEREMINDER ER
	left join CASENAME CN 		on (CN.CASEID = ER.CASEID
					and CN.NAMETYPE = 'O'
					and CN.SEQUENCE = (select min(SEQUENCE)
						from  CASENAME CN2
						where CN2.CASEID = ER.CASEID
						and CN2.NAMETYPE = CN.NAMETYPE
						and CN2.EXPIRYDATE is null))
	left join NAME N 		on (N.NAMENO = CN.NAMENO)
	where 				ER.EMPLOYEENO = @pnEmployeeNo
					and   ER.MESSAGESEQ = @pdtMessageSeq

	Union All

	Select 	'Arising from', 	
		EC.EVENTDESCRIPTION+': '+convert(nvarchar,isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE),106),
		7
	from EMPLOYEEREMINDER ER
	join CASEEVENT CE		on (CE.CASEID=ER.CASEID
					and CE.EVENTNO=ER.EVENTNO
					and CE.CYCLE=ER.CYCLENO)
	join CASEEVENT CE1		on (CE1.CASEID=CE.CASEID
					and CE1.EVENTNO=CE.GOVERNINGEVENTNO
					and CE1.CYCLE=(	select max(CE2.CYCLE)
							from CASEEVENT CE2
							where CE2.CASEID=CE1.CASEID
							and CE2.EVENTNO=CE1.EVENTNO))
	join EVENTS E			on (E.EVENTNO=CE1.EVENTNO)
	left join OPENACTION OA		on (OA.CASEID=CE1.CASEID
					and OA.ACTION=E.CONTROLLINGACTION
					and OA.CYCLE=(	select max(OA1.CYCLE)
							from OPENACTION OA1
							where OA1.CASEID=OA.CASEID
							and OA1.ACTION=OA.ACTION))
	join EVENTCONTROL EC		on (EC.CRITERIANO=isnull(OA.CRITERIANO,CE1.CREATEDBYCRITERIA)
					and EC.EVENTNO=CE1.EVENTNO)							
	where 				ER.EMPLOYEENO = @pnEmployeeNo
					and   ER.MESSAGESEQ = @pdtMessageSeq

	Union All

	Select 	C.COUNTRY, 	
		CF.FLAGNAME,
		8
	from EMPLOYEEREMINDER ER
	join CASES CS			on (CS.CASEID=ER.CASEID)
	join CASEEVENT CE		on (CE.CASEID=ER.CASEID
					and CE.EVENTNO=ER.EVENTNO
					and CE.CYCLE=ER.CYCLENO)
	join EVENTCONTROL EC		on (EC.CRITERIANO=CE.CREATEDBYCRITERIA
					and EC.EVENTNO=CE.EVENTNO)
	join DUEDATECALC DD		on (DD.CRITERIANO=CE.CREATEDBYCRITERIA
					and DD.EVENTNO=CE.EVENTNO
					and DD.FROMEVENT is null)
	join RELATEDCASE RC		on (RC.CASEID=CE.CASEID
					and RC.RELATIONSHIP='DC1'
					and RC.COUNTRYCODE =DD.COUNTRYCODE
					and RC.COUNTRYFLAGS<EC.CHECKCOUNTRYFLAG)
	join COUNTRY C			on (C.COUNTRYCODE=DD.COUNTRYCODE)
	left join COUNTRYFLAGS CF	on (CF.COUNTRYCODE=CS.COUNTRYCODE
					and CF.FLAGNUMBER=RC.CURRENTSTATUS)								
	where 				ER.EMPLOYEENO = @pnEmployeeNo
					and   ER.MESSAGESEQ = @pdtMessageSeq
	order by 3,1,2

End

Return @nErrorCode
GO

Grant execute on dbo.rem_GetReminderDetails to public
GO
