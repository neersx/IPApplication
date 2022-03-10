-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedReminderNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedReminderNames') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetConcatenatedReminderNames.'
	drop function dbo.fn_GetConcatenatedReminderNames
	print '**** Creating function dbo.fn_GetConcatenatedReminderNames...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetConcatenatedReminderNames
	(
		@pnCaseKey		int,
		@pnEventKey		int,
		@pnCycle		smallint,
		@psSeparator		nvarchar(10), 
		@pnNameStyle		int
	)
Returns nvarchar(max)

-- FUNCTION :	fn_GetConcatenatedReminderNames
-- VERSION :	4
-- DESCRIPTION:	This function accepts a CaseKey,EventKey,Cycle and gets the formatted 
--		names of reminder recipients and concatenates them with the Separator between each name.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 30 Apr 2003  JEK		1	RFC13 Review delivered reports
-- 23 Jun 2004	MF	RFC1586	2	Simplify code by removing WHILE loop to make perform faster
-- 14 Apr 2011	MF	RFC10475 3	Change nvarchar(4000) to nvarchar(max)
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).

AS
Begin
	Declare @sFormattedNameList	nvarchar(max)

	Select @sFormattedNameList=nullif(@sFormattedNameList+@psSeparator, @psSeparator)+
					dbo.fn_FormatNameUsingNameNo(N.NAMENO, @pnNameStyle)
	From EMPLOYEEREMINDER ER
	Join NAME N on (N.NAMENO=ER.EMPLOYEENO)
	Where ER.CASEID  =@pnCaseKey
	and   ER.EVENTNO =@pnEventKey
	and   ER.CYCLENO =@pnCycle
	order by ER.EMPLOYEENO

Return @sFormattedNameList
End
go

grant execute on dbo.fn_GetConcatenatedReminderNames to public
GO
