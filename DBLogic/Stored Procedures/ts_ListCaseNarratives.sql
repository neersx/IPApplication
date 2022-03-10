---------------------------------------------------------------------------------------------
-- Creation of dbo.ts_ListCaseNarratives
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_ListCaseNarratives]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_ListCaseNarratives.'
	drop procedure [dbo].[ts_ListCaseNarratives]
	Print '**** Creating Stored Procedure dbo.ts_ListCaseNarratives...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ts_ListCaseNarratives
(	
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@pnStaffKey		int		= null, -- The key of the staff member. If not supplied, the name key of the @pnUserIdentityId will be used.
	@pnCaseKey		int,	        -- Mandatory
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ts_ListCaseNarratives
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates the Case narratives entered in timesheet.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Jan 2013  MS	R12396	1	Procedure created
-- 23 May 2013  MS      R12396  2       Continued entries have been excluded from the list
--                                      HasWipChanged column is added
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(max)
Declare @sCurrentUserName	nvarchar(254)
Declare @sCurrentUserCode	nvarchar(10)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      	= 0
Set 	@pnRowCount		= 0

If @pnStaffKey is null
Begin
	Set @sSQLString = "
	Select  @pnStaffKey 		= UI.NAMENO
	from 	USERIDENTITY UI
	where 	UI.IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int			OUTPUT,
			  @pnUserIdentityId	int',
			  @pnStaffKey		= @pnStaffKey		OUTPUT,
			  @pnUserIdentityId	= @pnUserIdentityId
	
End

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  N.NAMENO	as 'StaffKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
				as 'StaffName',
		N.NAMECODE	as 'StaffCode',
		C.CASEID        as 'CaseKey',
		C.IRN           as 'CaseReference'
	from 	NAME N, CASES C	
	where 	N.NAMENO = @pnStaffKey
	and     C.CASEID = @pnCaseKey"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey	int,
			  @pnCaseKey    int',
			  @pnStaffKey	= @pnStaffKey,
			  @pnCaseKey    = @pnCaseKey
End

-- Populate the Time result set
If  @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  CAST(D.EMPLOYEENO as nvarchar(11)) + '^'+ CAST(D.ENTRYNO as nvarchar(11)) 
	                                as 'RowKey',
	        C.CASEID		as 'CaseKey',
	        D.EMPLOYEENO		as 'StaffKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as 'StaffName',
		N.NAMECODE		as 'StaffCode',
		D.ENTRYNO		as 'EntryNo',
		D.CREATEDON		as 'CreatedOn',	
		D.WIPENTITYNO           as 'EntityNo',
		D.TRANSNO               as 'TransNo',			
		D.NARRATIVENO		as 'NarrativeKey',
		ISNULL("+ dbo.fn_SqlTranslatedColumn('DIARY',null,'LONGNARRATIVE','D',@sLookupCulture,@pbCalledFromCentura)+", "+ dbo.fn_SqlTranslatedColumn('DIARY','SHORTNARRATIVE',null,'D',@sLookupCulture,@pbCalledFromCentura)+")
					as 'Narrative',
		CASE 	WHEN D.TRANSNO is not null
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END 			as 'IsPosted',
		CASE 	WHEN (D.TRANSNO is not null) and ((WIP.TRANSNO is null and WH.BILLLINENO is not null) or WIP.STATUS=2)
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END 			as 'IsBilled',
		CASE 	WHEN (D.TRANSNO is not null) and (WIP.TRANSNO is null and WH.REASONCODE is not null)
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END 			as 'HasWipChanged',
		CASE WHEN D.TRANSNO is not null and ((WH.BILLLINENO is not null or WH.REASONCODE is not null) or WIP.STATUS=2)
		        THEN convert(bit,0)
		     WHEN D.TRANSNO is not null
		        THEN convert(bit,ISNULL(P.CanExecute,0))
		     ELSE CASE WHEN (convert(bit,(substring(FS.ACCESSPRIVILEGES,4,5)&4))=1 OR D.EMPLOYEENO = @pnStaffKey) 
		                THEN convert(bit,1)
		                ELSE convert(bit,0)
		             END
		END                     as 'HasUpdateAccess',
		D.LOGDATETIMESTAMP	as 'LogDateTimeStamp'
	from 	DIARY D	
	left join NAME N 		on (N.NAMENO = D.EMPLOYEENO)
	left join WORKINPROGRESS WIP    on (WIP.TRANSNO = D.TRANSNO
					        and WIP.ENTITYNO = D.WIPENTITYNO
					        and WIP.WIPSEQNO = 1)
	left join WORKHISTORY   WH      on (WH.TRANSNO = D.TRANSNO
	                                        and WH.ENTITYNO = D.WIPENTITYNO
	                                        and WH.WIPSEQNO = 1
	                                        and (WH.BILLLINENO is not null or WH.REASONCODE is not null))
	left join CASES C		on (C.CASEID = D.CASEID)
	left join NARRATIVE NRT		on (NRT.NARRATIVENO = D.NARRATIVENO)
	left join fn_PermissionsGrantedAll('TASK',212, null, GETDATE()) as P on (P.IdentityKey = "+convert(varchar,@pnUserIdentityId)+")
	left join (Select D1.EMPLOYEENO, 
			max(CASE WHEN (F.OWNERNO   IS NULL) THEN '0' ELSE '1' END +    			
			CASE WHEN (F.ACCESSSTAFFNO IS NULL) THEN '0' ELSE '1' END +	
			CASE WHEN (F.ACCESSGROUP   IS NULL) THEN '0' ELSE '1' END +
			convert(varchar(5), F.ACCESSPRIVILEGES) ) as ACCESSPRIVILEGES
		FROM (select distinct EMPLOYEENO from DIARY) D1
		JOIN FUNCTIONSECURITY F ON (F.FUNCTIONTYPE=1)
		JOIN USERIDENTITY UI ON (UI.IDENTITYID = "+convert(varchar,@pnUserIdentityId)+")
		JOIN NAME N          ON (UI.NAMENO = N.NAMENO)
		WHERE (F.OWNERNO     = D1.EMPLOYEENO  OR F.OWNERNO       IS NULL)
		AND (F.ACCESSSTAFFNO = UI.NAMENO     OR F.ACCESSSTAFFNO IS NULL) 
		AND (F.ACCESSGROUP   = N.FAMILYNO    OR F.ACCESSGROUP   IS NULL)
		group by D1.EMPLOYEENO) FS on (FS.EMPLOYEENO=D.EMPLOYEENO)
	where 	D.CASEID = @pnCaseKey	
	and (convert(bit,(substring(FS.ACCESSPRIVILEGES,4,5)&1))=1 or D.EMPLOYEENO = @pnStaffKey)
	and D.ENTRYNO not in (
	        Select D1.ENTRYNO
	        FROM DIARY D1
	        left join DIARY D2 on (D2.PARENTENTRYNO = D1.ENTRYNO and D2.EMPLOYEENO = D1.EMPLOYEENO and D2.CASEID = D1.CASEID)
	        where D1.CASEID = @pnCaseKey
	        and D1.STARTTIME is not null 
	        and D1.FINISHTIME is not null
	        and D1.TOTALTIME is null
	        and D2.PARENTENTRYNO = D1.ENTRYNO)
	order by D.CREATEDON desc"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int,
			  @pnCaseKey		int',
			  @pnStaffKey		= @pnStaffKey,
			  @pnCaseKey		= @pnCaseKey

	Set @pnRowCount=@@Rowcount
End

Return @nErrorCode
GO

Grant exec on dbo.ts_ListCaseNarratives to public
GO
