-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.qr_ListQueries 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_ListQueries ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_ListQueries.'
	Drop procedure [dbo].[qr_ListQueries ]
	Print '**** Creating Stored Procedure dbo.qr_ListQueries ...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.qr_ListQueries 
(
	@pnRowCount		int		= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryContextKey	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	qr_ListQueries 
-- VERSION:	16
-- SCOPE:	InPro.net
-- DESCRIPTION:	Provide a list of the saved queries available for use.  

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 26-Mar-2004  TM	RFC1250	1	Procedure created
-- 30-Mar-2004	TM	RFC399	2	Modify the logic for the IsMaintainable column to ensure it is false 
--					when IsProtected = 1.
-- 20-Apr-2004	TM	RFC919	3	Add the following columns: HasPresentation, GroupName, ExportFormatKey,
--					ReportToolKey, ReportToolDescription.
-- 23-Apr-2004	TM	RFC919	4	Add a GroupKey colum; order by QUERYGROUP.DISPLAYSEQUENCE, IsPublic, QueryName.
--					Rreturn null values for  ReportToolKey, ReportToolDescription and ExportFormatKey
--					when QUERYPRESENATION.REPORTTOOL = 9401.
-- 19-Jul-2004	TM	RFC1543	5	Return a new IsDefault column.
-- 15 Sep 2004	JEK	RFC886	6	Implement translation.
-- 15 May 2005	JEK	RFC2508	7	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 21 Dec 2005	TM	RFC3221	8	Implement default searches by access account.
-- 18 Dec 2006	JEK	RFC2984	9	Make protected searches with presentation only Run-only.
-- 09 May 2007	SW	RFC4795	10	Return saved search for all external users if ISPUBLICTOEXTERNAL = 1
-- 17-Oct-2008  LP      RFC6964 11      Return IsReportOnly, ReportTemplate and ReportTitle columns.
-- 03 Nov 2009	LP	RFC8260	12	Return IsReadOnly flag for queries to be displayed in WorkBenches, but not executed.
-- 28 Jan 2010	SF	RFC8483	13	Return all boolean values using bit
-- 15 Feb 2010	LP	RFC8729	14	Return IsReadOnly flag as FALSE for Case Fees Searches that are older than 24 hours - CPA Specific
--					Check for existence of iLOG view before referencing the iLOG tables.
-- 18 Mar 2010  LP      RFC8801 15      Modify logic for IsMaintainable column to include ISREADONLY = 0.
-- 12 Oct 2011  ASH     R11111 16       Return boolean value using bit when logging is enabled on QUERY table.
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString 		nvarchar(4000)

Declare @nErrorCode		int

Declare @sLookupCulture		nvarchar(10)
Declare @bIsExternalUser	bit
Declare @bUsesLogging		bit

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set 	@nErrorCode 		= 0
Set	@pnRowCount		= 0
Set	@bUsesLogging		= 0

-- We need to determine if the user is external

If @nErrorCode=0
Begin
	Set @sSQLString="
		Select	@bIsExternalUser=ISEXTERNALUSER
		from USERIDENTITY
		where IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit	OUTPUT,
				  @pnUserIdentityId		int',
				  @bIsExternalUser=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId
End

-- Check if logging is used
If @nErrorCode = 0
Begin
	If OBJECT_ID ('dbo.QUERY_iLOG','V') IS NOT NULL
	Begin		
		Set @bUsesLogging = 1	
	End
End

-- Populating the dataset

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  Q.QUERYID	as 'QueryKey',
		"+dbo.fn_SqlTranslatedColumn('QUERY','QUERYNAME',null,'Q',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'QueryName',
		"+dbo.fn_SqlTranslatedColumn('QUERY','DESCRIPTION',null,'Q',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description',
		CASE WHEN Q.IDENTITYID is null 
		     THEN cast(1 as bit) 
		     ELSE cast(0 as bit) 
		END 		as 'IsPublic',
		CASE WHEN Q.ISCLIENTSERVER = 0 and Q.ISPROTECTED = 0
		     THEN cast(1 as bit) 
		     ELSE cast(0 as bit) 
		END		as 'IsMaintainable',
		CASE WHEN ((Q.ISCLIENTSERVER = 1 and Q.FILTERID is not null) 
			  or (Q.ISCLIENTSERVER = 0 and Q.ISPROTECTED=0) 
			  or (Q.ISCLIENTSERVER = 0 AND Q.ISPROTECTED=1 AND Q.FILTERID is not null))
			  AND Q.ISREADONLY=0
		     THEN cast(1 as bit) 
		     ELSE cast(0 as bit) 
		END		as 'IsRunable',
		CASE WHEN Q.FILTERID is null
		     THEN cast(1 as bit)
		     ELSE cast(0 as bit)
		END 		as 'IsReportOnly',
		CASE WHEN Q.PRESENTATIONID is not null
		     THEN cast(1 as bit)
		     ELSE cast(0 as bit)
		END 		as 'HasPresentation',
		QG.GROUPID	as 'GroupKey',
		"+dbo.fn_SqlTranslatedColumn('QUERYGROUP','GROUPNAME',null,'QG',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'GroupName',
		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE QP.EXPORTFORMAT	
		END 		as 'ExportFormatKey',
		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE QP.REPORTTOOL	
		END		as 'ReportToolKey',
		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'RTD',@sLookupCulture,@pbCalledFromCentura)+"
 		END		as 'ReportToolDescription',
 		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE QP.REPORTTEMPLATE
 		END		as 'ReportTemplate',
 		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE QP.REPORTTITLE
 		END		as 'ReportTitle',
		-- 'IsDefault' column is 1 for the query that is 
		-- the best default for the user.
		CASE WHEN Q.QUERYID = COALESCE(QD1.QUERYID, QD2.QUERYID, QD3.QUERYID) 
		     THEN cast(1 as bit)
		     ELSE cast(0 as bit)
		END		as 'IsDefault',
		CASE "+char(10)+
		CASE WHEN @bUsesLogging = 1 THEN 
			"WHEN Q.ISCLIENTSERVER = 0 and Q.ISREADONLY = 1 and Q.GROUPID in (-330,-331) and Qi.QUERYID IS NOT NULL THEN cast(0 as bit)" ELSE "" END
		     +char(10)+
		     "WHEN Q.ISCLIENTSERVER = 0 and Q.ISREADONLY = 1 and Q.LOGDATETIMESTAMP < dateadd(HH, -1, getdate())
		     
		     THEN cast(1 as bit) 
		     ELSE cast(0 as bit) 
		END		as 'IsReadOnly'
	from	QUERY Q 
	join USERIDENTITY UI 	 	on (UI.IDENTITYID = @pnUserIdentityId)
	left join QUERYGROUP QG		on (QG.GROUPID = Q.GROUPID)
	left join QUERYPRESENTATION QP	on (QP.PRESENTATIONID = Q.PRESENTATIONID)
	left join TABLECODES RTD	on (RTD.TABLECODE = QP.REPORTTOOL)	 
	left join QUERYDEFAULT QD1	on (QD1.CONTEXTID = Q.CONTEXTID
					and QD1.IDENTITYID = @pnUserIdentityId)
	left join QUERYDEFAULT QD2	on (QD2.CONTEXTID = Q.CONTEXTID 
					and QD2.ACCESSACCOUNTID = UI.ACCOUNTID) 	
	left join QUERYDEFAULT QD3	on (QD3.CONTEXTID = Q.CONTEXTID 
					and (QD3.IDENTITYID is null and
					     Q.IDENTITYID is null and
					     QD3.ACCESSACCOUNTID is null and 
					     Q.ACCESSACCOUNTID is null))"+char(10)+
	CASE WHEN @bUsesLogging = 1 THEN				     
	"left join QUERY_iLOG Qi on (Q.QUERYID = Qi.QUERYID and Qi.CONTEXTID in (330,331) and Qi.LOGACTION = 'I' and Qi.LOGDATETIMESTAMP < dateadd(HH, -1, getdate()))"
	ELSE "" END
 	+char(10)+
 	"where Q.CONTEXTID = @pnQueryContextKey
	-- All public and personal query rows should be returned
	and    ((Q.IDENTITYID is null and Q.ACCESSACCOUNTID is null)
	 or     (Q.IDENTITYID = @pnUserIdentityId)
	 or     (Q.ACCESSACCOUNTID  = UI.ACCOUNTID)
	 or	(Q.ISPUBLICTOEXTERNAL = 1 and @bIsExternalUser = 1)
	       )
	order by QG.DISPLAYSEQUENCE, 'IsPublic', 2"	

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnQueryContextKey		int,
					  @pnUserIdentityId	 	int,
					  @bIsExternalUser		bit',					
					  @pnQueryContextKey		= @pnQueryContextKey,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @bIsExternalUser		= @bIsExternalUser

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.qr_ListQueries  to public
GO


