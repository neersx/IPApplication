-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListExternalRenewalStatus
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListExternalRenewalStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListExternalRenewalStatus.'
	Drop procedure [dbo].[ipw_ListExternalRenewalStatus]
	Print '**** Creating Stored Procedure dbo.ipw_ListExternalRenewalStatus...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListExternalRenewalStatus
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psStatusKeys		nvarchar(3500)	= null -- An optional comma separate list of the status keys required.
)
AS
-- PROCEDURE:	ipw_ListExternalRenewalStatus
-- VERSION:	5
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a result set containing the disting external descriptions for
--		renewal statuses, along with a comma separate list of the status keys
--		that implement that external description.
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 08 Oct 2003  TM		1	Procedure created
-- 15 Sep 2004	JEK	RFC886	2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 13 Dec 2006	JEK	RFC2984	4	Add a new StatusKey column that contains a comma separated list of the
--					the keys that match the external description.
-- 08 Feb 2011	ASH	RFC9978	5	Extract the value of LIVE FLAG and REGISTERED FLAG from STATUS table.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @tblStatus table (
	SequenceNo		int identity(1,1),
	ExternalDescription	nvarchar(254) collate database_default null,
	Keys			nvarchar(3500) collate database_default null,
	LiveFlag bit,
	RegisteredFlag	bit	
	)

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(500)
Declare @sLookupCulture	nvarchar(10)
Declare @nRowCount 	int
Declare @nCurrentRow	smallint

Declare @sDescription	nvarchar(254)
Declare @sKeys		nvarchar(3500)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
-- Don't implement translation unless this particular column is translated
If dbo.fn_GetTranslatedTIDColumn('STATUS','EXTERNALDESC') is null
Begin
	Set @sLookupCulture=null
End

If @nErrorCode = 0
and @sLookupCulture is null
Begin
	insert into @tblStatus (ExternalDescription)
	select distinct EXTERNALDESC
	FROM STATUS
	WHERE RENEWALFLAG=1
	group by EXTERNALDESC
	having count(*)>1

	select @nErrorCode=@@ERROR, @nRowCount=@@Rowcount

	If @nErrorCode = 0
	Begin
		-- Now load the Status that have a unique External Description
		insert into @tblStatus (ExternalDescription, Keys, LiveFlag, RegisteredFlag)
		select S.EXTERNALDESC, S.STATUSCODE,S.LIVEFLAG,S.REGISTEREDFLAG
		FROM STATUS S
		join (	select EXTERNALDESC
			from STATUS
			where RENEWALFLAG=1
			group by EXTERNALDESC
			having count(*)=1) S1	on (S1.EXTERNALDESC=S.EXTERNALDESC)
		WHERE RENEWALFLAG=1

		set @nErrorCode=@@ERROR
	End

	Set @nCurrentRow=0

	-- Now prepare a comma separated list of keys where the external description appears
	-- multiple times.	
	While @nCurrentRow<@nRowCount
	and @nErrorCode = 0
	Begin
		Set @nCurrentRow=@nCurrentRow+1
		Set @sKeys=null
	
		Select @sKeys=@sKeys+nullif(',', ',' + @sKeys)+cast(S.STATUSCODE as nvarchar)
		from @tblStatus T
		join STATUS S on (S.EXTERNALDESC=T.ExternalDescription
				and S.RENEWALFLAG=1)
		WHERE T.SequenceNo=@nCurrentRow

		set @nErrorCode=@@ERROR

		If @nErrorCode = 0
		Begin
			Update @tblStatus
			Set Keys=@sKeys
			WHERE SequenceNo=@nCurrentRow
		End
	End
End
-- Translation in use
Else
Begin
	insert into @tblStatus (ExternalDescription)
	select distinct dbo.fn_GetTranslationLimited(EXTERNALDESC,null,EXTERNALDESC_TID,@sLookupCulture)
	FROM STATUS
	WHERE RENEWALFLAG=1
	group by dbo.fn_GetTranslationLimited(EXTERNALDESC,null,EXTERNALDESC_TID,@sLookupCulture)
	having count(*)>1

	select @nErrorCode=@@ERROR, @nRowCount=@@Rowcount

	If @nErrorCode = 0
	Begin
		-- Now load the Status that have a unique External Description
		insert into @tblStatus (ExternalDescription, Keys)
		select 	S.EXTERNALDESC, S.STATUSCODE
		FROM	(SELECT dbo.fn_GetTranslationLimited(EXTERNALDESC,null,EXTERNALDESC_TID,@sLookupCulture) as EXTERNALDESC, STATUSCODE
			FROM STATUS
			WHERE RENEWALFLAG=1) S
		join (	select dbo.fn_GetTranslationLimited(EXTERNALDESC,null,EXTERNALDESC_TID,@sLookupCulture) as EXTERNALDESC
			from STATUS
			where RENEWALFLAG=1
			group by dbo.fn_GetTranslationLimited(EXTERNALDESC,null,EXTERNALDESC_TID,@sLookupCulture)
			having count(*)=1) S1	on (S1.EXTERNALDESC=S.EXTERNALDESC)

		set @nErrorCode=@@ERROR
	End

	Set @nCurrentRow=0

	-- Now prepare a comma separated list of keys where the external description appears
	-- multiple times.	
	While @nCurrentRow<@nRowCount
	and @nErrorCode = 0
	Begin
		Set @nCurrentRow=@nCurrentRow+1
		Set @sKeys=null
	
		Select @sKeys=@sKeys+nullif(',', ',' + @sKeys)+cast(S.STATUSCODE as nvarchar)
		from @tblStatus T
		join STATUS S on (dbo.fn_GetTranslationLimited(S.EXTERNALDESC,null,S.EXTERNALDESC_TID,@sLookupCulture)=T.ExternalDescription
				and S.RENEWALFLAG=1)
		WHERE T.SequenceNo=@nCurrentRow

		set @nErrorCode=@@ERROR

		If @nErrorCode = 0
		Begin
			Update @tblStatus
			Set Keys=@sKeys
			WHERE SequenceNo=@nCurrentRow
		End
	End

End
	
If @nErrorCode = 0
and @psStatusKeys is null
Begin
	Select 	ExternalDescription 	as 'StatusDescription',
		Keys			as 'StatusKey',
		LiveFlag as 'LiveFlag', 
		RegisteredFlag as 'RegisteredFlag'
	from @tblStatus S
	ORDER BY 1
	
	select @nErrorCode=@@ERROR, @pnRowCount = @@Rowcount

End
Else If @nErrorCode = 0
and @psStatusKeys is not null
Begin
	Select 	ExternalDescription 	as 'StatusDescription',
		Keys			as 'StatusKey',
		LiveFlag as 'LiveFlag', 
		RegisteredFlag as 'RegisteredFlag'
	from @tblStatus S
	where exists (select 1
		   from dbo.fn_Tokenise(@psStatusKeys, ',') K
		   where patindex('%'+','+K.Parameter+','+'%',',' + replace(S.Keys, ' ', '') + ',')>0)
	ORDER BY 1
	
	select @nErrorCode=@@ERROR, @pnRowCount = @@Rowcount

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListExternalRenewalStatus to public
GO
