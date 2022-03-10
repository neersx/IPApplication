-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_ListDiaryDates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_ListDiaryDates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_ListDiaryDates.'
	Drop procedure [dbo].[ts_ListDiaryDates]
	Print '**** Creating Stored Procedure dbo.ts_ListDiaryDates...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ts_ListDiaryDates
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLFilterCriteria	ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura	bit		= 0
)
AS 
-- PROCEDURE:	ts_ListDiaryDates
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	InPro.net
-- DESCRIPTION:	This stored procedure produces returns a result set containing two columns EntryDate 
--		and AccumulatedMinutes (int) in EntryDate order that match the supplied filter criteria.

-- MODIFICATIONS :
-- Date			Who	Number	Version	Change
-- ---------	---	-------	-------	------------------------------------------------------ 
-- 28 Jun 2005  TM	RFC2556	1		Procedure created. 
-- 28 Mar 2007	LP	RFC5242	2		Populate ENTRYDATE from FINISHTIME if STARTTIME is NULL
-- 19 Apr 2007	LP	RFC5299	3		Add STARTTIME and FINISHTIME in GROUP BY clause

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int
Declare @sSQLString			nvarchar(4000)

Declare @bIsExternalUser		bit
Declare @sCurrentDiaryTable		nvarchar(60)
Declare @sDiaryWhere			nvarchar(4000)

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

-- Initialise variables
Set     @nErrorCode = 0			

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser = ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	= @bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	= @pnUserIdentityId
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE  clause  ****/
/****                                       ****/
/***********************************************/

If   @nErrorCode=0
and (datalength(@ptXMLFilterCriteria) <> 0
or   datalength(@ptXMLFilterCriteria) is not null)
Begin
	exec @nErrorCode=dbo.ts_FilterDiary
				@psReturnClause		= @sDiaryWhere	  	OUTPUT, 
				@psCurrentDiaryTable	= @sCurrentDiaryTable	OUTPUT,
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,		
				@pbIsExternalUser	= @bIsExternalUser,	
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,	
				@pbCalledFromCentura	= @pbCalledFromCentura	
End

If   @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	convert(datetime, convert(char(10),convert(datetime,ISNULL(XD.STARTTIME,XD.FINISHTIME),120),120), 120)
			as 'EntryDate',
		sum(isnull(DATEPART(HOUR,XD.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, XD.TOTALTIME),0)
		    +
		    isnull(DATEPART(HOUR,XD.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, XD.TIMECARRIEDFORWARD),0))
			as 'AccumulatedMinutes'"+char(10)+
	@sDiaryWhere+char(10)+
	"group by convert(datetime, convert(char(10),convert(datetime,ISNULL(XD.STARTTIME,XD.FINISHTIME),120),120), 120)
	order by 'EntryDate'"    
	
	exec @nErrorCode = sp_executesql @sSQLString
	Set @pnRowCount=@@Rowcount	
End

-- Now drop the temporary table holding the Entries results:
If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentDiaryTable)
and @nErrorCode=0
Begin
	Set @sSQLString = "drop table "+@sCurrentDiaryTable
		
	exec @nErrorCode=sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.ts_ListDiaryDates to public
GO
