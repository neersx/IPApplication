-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListSubjectAreaColumns
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListSubjectAreaColumns]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListSubjectAreaColumns.'
	Drop procedure [dbo].[ip_ListSubjectAreaColumns]
	Print '**** Creating Stored Procedure dbo.ip_ListSubjectAreaColumns...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
-- The procedure is recursively called.
-- This CREATE will stop a warning message appearing.
CREATE PROCEDURE dbo.ip_ListSubjectAreaColumns
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pnSubjectArea		int
)
-- PROCEDURE:	ip_ListSubjectAreaColumns
-- VERSION :	5
-- DESCRIPTION:	Returns the table and columns that have been logged for a given subject area

-- MODIFICATIONS :
-- Date		Who	Version	Change	Description
-- ------------	-------	-------	------	----------------------------------------------- 
-- 24-JUN-2005  MF	1		Procedure created
-- 14-JUL-2005	MF	2	SQA8238	Format the Display Name in the output result set as
--					COLUMN_NAME (TABLE_NAME)
-- 16-Sep-2005	MF	3	11869	Don't return SEQUENCE columns
-- 28-Sep-2005	MF	4	12135	Improve performance by getting audit tables for a Subject Area
--					from previously loaded table structure
-- 19-Dec-2007	MF	5	15192	Do not return the audit columns that are now included on the table
--					being logged. E.g LOGUSERID,LOGIDENTITYID,LOGTRANSACTIONNO,
--					LOGDATETIMESTAMP,LOGACTION,LOGOFFICEID,LOGAPPLICATION

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@ErrorCode		int
declare @sSQLString		nvarchar(4000)
declare @sTempColumns		nvarchar(50)

-- Initialise variables
Set @ErrorCode = 0

If @ErrorCode=0
Begin
	-- Report on the columns that have been logged
	Set @sSQLString="
	Select	left(T.TABLENAME,30) 	as [TABLENAME], 
		left(C.COLUMN_NAME,30)	as [COLUMNNAME], 
		left(C.COLUMN_NAME+' ('+T.TABLENAME+')',50)	
					as [DISPLAYNAME],
		CASE WHEN(C1.DATA_TYPE like '%char')
			THEN 'String'
		     WHEN(C1.DATA_TYPE like '%date%')
			THEN 'Date'
			ELSE 'Number'
		END			as [COLUMNTYPE]
	from SUBJECTAREATABLES T
	join INFORMATION_SCHEMA.COLUMNS C  on (C.TABLE_NAME=T.TABLENAME)
	join INFORMATION_SCHEMA.COLUMNS C1 on (C1.TABLE_NAME=T.TABLENAME+'_iLOG'
					   and C1.COLUMN_NAME=C.COLUMN_NAME)
	where T.SUBJECTAREANO=@pnSubjectArea
	and C.COLUMN_NAME not like '%SEQ%'
	and C.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
	order by T.DEPTH, C.TABLE_NAME, C.COLUMN_NAME" --C.ORDINAL_POSITION


	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnSubjectArea	int',
				  @pnSubjectArea=@pnSubjectArea
End

Return @ErrorCode
GO

Grant execute on dbo.ip_ListSubjectAreaColumns to public
GO
