-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_MaintainAccountCaseContact
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_MaintainAccountCaseContact]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_MaintainAccountCaseContact.'
	Drop procedure [dbo].[ua_MaintainAccountCaseContact]
End
Print '**** Creating Stored Procedure dbo.ua_MaintainAccountCaseContact...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_MaintainAccountCaseContact
(
	@pnAccountKey		int		= null,
	@pnCaseKey		int		= null
)
as
-- PROCEDURE:	ua_MaintainAccountCaseContact
-- VERSION:	4
-- DESCRIPTION:	Recalculate the contents of the Account Case Contact table,
--		for an Account, a Case or everything.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Apr-2004	JEK	1033	1	Procedure created
-- 27-Mar-2008	MF	6361	2	Improve performance for Names with a large number of 
--					associated Cases by using a temporary table with an 
--					index created after the data load.
-- 13-Feb-2009  LP      7647    3       Use of UPPER in join on SITECONTROL causes index scan.
--					Remove the UPPER to use faster index seek.  
-- 25-Feb-2009	MF	7647	4	Improve performance by pulling SITECONTROL out of main
--					statements. Also reduce locking level.                                    

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


create table #TEMPDATA(	CASEID		int					 NOT NULL,
			ACCOUNTID	int					 NOT NULL,
			NAMESTUFF	nvarchar(27)	collate database_default NOT NULL
			)

declare @TranCountStart	int
declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @sNameTypeList	nvarchar(200)
declare @sNameTypes	nvarchar(250)
declare @sCaseTypeList	nvarchar(200)
declare @sCaseTypes	nvarchar(250)

-- set locking level to the lowest level
set transaction isolation level read uncommitted

-- Initialise variables
Set @nErrorCode = 0

-------------------------------------------
-- Get the list of NameTypes that determine
-- what Cases a client can access.
-- String these together in a quote and 
-- comma separated list as this will have
-- a positive performance benefit.
-------------------------------------------
If @nErrorCode = 0
Begin
	select @sNameTypeList=replace(COLCHARACTER, ' ', '')
	from SITECONTROL
	where CONTROLID='Client Name Types'
	
	Set @nErrorCode=@@Error
	
	If @nErrorCode=0
	and @sNameTypeList is not null
	Begin
		----------------------------------------------
		-- Now split out each comma separated NameType
		-- and combine into a single list with each
		-- nametype within quotes and comma separated
		----------------------------------------------
		Select @sNameTypes=CASE WHEN(@sNameTypes is not null) 
							THEN @sNameTypes+','''+Parameter+''''
							ELSE ''''+Parameter+'''' 
				   END
		from dbo.fn_Tokenise(@sNameTypeList,',')
		
		Set @nErrorCode=@@Error
	End
End

-------------------------------------------
-- Get the list of CaseTypes that determine
-- what Cases a client can access.
-- String these together in a quote and 
-- comma separated list as this will have
-- a positive performance benefit.
-------------------------------------------
If @nErrorCode = 0
Begin
	select @sCaseTypeList=replace(COLCHARACTER, ' ', '')
	from SITECONTROL
	where CONTROLID='Client Case Types'
	
	Set @nErrorCode=@@Error
	
	If @nErrorCode=0
	and @sCaseTypeList is not null
	Begin
		----------------------------------------------
		-- Now split out each comma separated CaseType
		-- and combine into a single list with each
		-- casetype within quotes and comma separated
		----------------------------------------------
		Select @sCaseTypes=CASE WHEN(@sCaseTypes is not null) 
							THEN @sCaseTypes+','''+Parameter+''''
							ELSE ''''+Parameter+'''' 
				   END
		from dbo.fn_Tokenise(@sCaseTypeList,',')
		
		Set @nErrorCode=@@Error
	End
End

If @nErrorCode = 0
and @sNameTypes is not null
Begin
	---------------------------------------------------------------------------------------
	-- We need to get a single CASENAME row for each Case which presented a problem as
	-- the user may be linked to multiple name and allow access via multiple Name Types.
	-- The solution is to give certain hardcoded NameTypes a relative weighting in order to
	-- determine which NameType to use.
	-- Load into a temporary table so that an index can be added to improve performance.
	---------------------------------------------------------------------------------------
	Set @sSQLString="
	Insert into #TEMPDATA(CASEID, ACCOUNTID, NAMESTUFF)
	select	CN.CASEID   as CASEID, 
		A.ACCOUNTID as ACCOUNTID,
		min(CASE (NAMETYPE) WHEN('I') THEN '01'
				    WHEN('R') THEN '02'
				    WHEN('A') THEN '03'
				    WHEN('&') THEN '04'
				    WHEN('D') THEN '05'
				    WHEN('Z') THEN '06'
				    WHEN('O') THEN '07'
				    WHEN('J') THEN '08'
				              ELSE '10'
		    END 
			+ convert(nchar(3),CN.NAMETYPE)
			+ convert(char(11),CN.NAMENO)
			+ convert(char(11),CN.SEQUENCE)) as NAMESTUFF
      	from ACCESSACCOUNT A
	join ACCESSACCOUNTNAMES N on (N.ACCOUNTID = A.ACCOUNTID)
      	join CASENAME CN	on (CN.NAMENO=N.NAMENO
				and CN.EXPIRYDATE is null
				and CN.NAMETYPE in ("+@sNameTypes+"))
	Where A.ISINTERNAL = 0"

	If @pnCaseKey is not null
		set @sSQLString=@sSQLString+"
		and CN.CASEID = @pnCaseKey"

	If @pnAccountKey is not null
		set @sSQLString=@sSQLString+"
		and A.ACCOUNTID = @pnAccountKey"

	set @sSQLString=@sSQLString+"
	group by CN.CASEID,A.ACCOUNTID
	order by CN.CASEID,A.ACCOUNTID"

	-- Now generate the index on the loaded
	-- temporary table

	Set @sSQLString=@sSQLString+"

	CREATE CLUSTERED INDEX XPKTEMPDATA ON #TEMPDATA (CASEID,ACCOUNTID, NAMESTUFF)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @pnAccountKey		int',
					  @pnCaseKey		= @pnCaseKey,
					  @pnAccountKey		= @pnAccountKey

End

------------------------
-- Remove the old values
------------------------
If @nErrorCode = 0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	----------------------------------------
	-- Construct the DELETE statement
	-- depending upon the key values passed
	-- as this will build the most efficient
	-- statement.
	----------------------------------------
	Set @sSQLString="
	Delete from ACCOUNTCASECONTACT
	where 1=1"

	If @pnCaseKey is not null
		Set @sSQLString=@sSQLString+"
		and ACCOUNTCASEID = @pnCaseKey"

	If @pnAccountKey is not null
		Set @sSQLString=@sSQLString+"
		and ACCOUNTID = @pnAccountKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @pnAccountKey		int',
					  @pnCaseKey		= @pnCaseKey,
					  @pnAccountKey		= @pnAccountKey
End
--------------------
-- Insert new values
--------------------
If @nErrorCode = 0
and @sCaseTypes is not null
Begin
	Set @sSQLString = "
	Insert into ACCOUNTCASECONTACT (ACCOUNTID, ACCOUNTCASEID, CASEID, NAMETYPE, NAMENO, SEQUENCE)
	select NT.ACCOUNTID, NT.CASEID, NT.CASEID, substring(NT.NAMESTUFF,3,3), convert(int,substring(NT.NAMESTUFF,6,11)), convert(int,substring(NT.NAMESTUFF,17,11))
	from #TEMPDATA NT
	join CASES C		on (C.CASEID=NT.CASEID)
	where C.CASETYPE in ("+@sCaseTypes+")"

	If @pnCaseKey is not null
		Set @sSQLString=@sSQLString+"
		AND C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int',
					  @pnCaseKey		= @pnCaseKey

End

-- Commit or Rollback the transaction

If @@TranCount > @TranCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

drop table #TEMPDATA

Return @nErrorCode
GO

Grant execute on dbo.ua_MaintainAccountCaseContact to public
GO
