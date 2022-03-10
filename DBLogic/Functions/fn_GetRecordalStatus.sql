-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetRecordalStatus
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetRecordalStatus') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetRecordalStatus.'
	drop function dbo.fn_GetRecordalStatus
end
print '**** Creating function dbo.fn_GetRecordalStatus...'
print ''
go

set QUOTED_IDENTIFIER off
go
set CONCAT_NULL_YIELDS_NULL off
go

CREATE FUNCTION dbo.fn_GetRecordalStatus
		(
		@pnCaseId int,
		@pnRecordalCaseId int,
		@psRelationship nvarchar(3)
		)
Returns nvarchar(70)

-- FUNCTION :	fn_GetRecordalStatus
-- VERSION :	1
-- DESCRIPTION:	Determines the overall recordal status for the selected case.
-- NOTE: 	a case can be associated with  multiple recordal steps which could be any recordal status 
--		(i.e. Not Yet Filed, Filed, Recorded).  The case recordal status is 'Recorded' when all steps 
--		status are Recorded.  Otherwise the status is 'Pending ' + the Recordal Type Name of the first pending step.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 19/12/2005	DL	10666	1	Function created

AS
Begin
	Declare @sRecordalStatus nvarchar(70)

	IF @psRelationship = 'ASG' 
	Begin
		SELECT @sRecordalStatus   =
		CASE WHEN STEPCOUNT = STEPRECORDED THEN 'Recorded' 
		ELSE  'Pending ' + 
			(SELECT DISTINCT RT.RECORDALTYPE 
			FROM
				(SELECT  MIN(RS.STEPNO) STEPNO,  MIN(RS.CASEID) CASEID
				FROM RELATEDCASE RC 
				JOIN RECORDALAFFECTEDCASE RAC ON (RAC.CASEID = RC.RELATEDCASEID AND RC.RELATIONSHIP='ASG' AND RAC.RELATEDCASEID = RC.CASEID)
				JOIN RECORDALSTEP RS ON (RS.CASEID = RAC.CASEID AND RS.RECORDALTYPENO = RAC.RECORDALTYPENO)
				WHERE RC.CASEID = @pnCaseId
				AND RC.RELATEDCASEID = @pnRecordalCaseId
				AND RC.RELATIONSHIP ='ASG'
				AND RAC.STATUS != 'Recorded'

			) TMP 
			JOIN RECORDALSTEP RS ON (RS.CASEID = TMP.CASEID AND RS.STEPNO = TMP.STEPNO)
			JOIN RECORDALTYPE RT ON (RT.RECORDALTYPENO = RS.RECORDALTYPENO)
		)
		END

		FROM 	(
		SELECT 
			(SELECT COUNT(*) FROM RECORDALAFFECTEDCASE WHERE CASEID = @pnRecordalCaseId AND RELATEDCASEID = @pnCaseId ) STEPCOUNT, 
			(SELECT COUNT(*) FROM RECORDALAFFECTEDCASE WHERE CASEID = @pnRecordalCaseId AND RELATEDCASEID = @pnCaseId AND STATUS = 'Recorded') STEPRECORDED
			FROM RECORDALAFFECTEDCASE 
			WHERE RELATEDCASEID = @pnCaseId
			AND CASEID = @pnRecordalCaseId 
			GROUP BY RELATEDCASEID 
			) TMP2 

	End;

	Return @sRecordalStatus
End
go

grant execute on dbo.fn_GetRecordalStatus to public
GO
