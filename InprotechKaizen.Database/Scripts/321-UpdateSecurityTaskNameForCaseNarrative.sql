/**********************************************************************************************************/
/*** DR-72518 Update task security for the Case Narrative - Task							***/
/**********************************************************************************************************/
	PRINT '**** DR-72518 Try update TASKNAME for TASK 191'
	UPDATE TASK SET TASKNAME = 'Maintain Case Bill Narrative'
	WHERE TASKID = 191
	GO