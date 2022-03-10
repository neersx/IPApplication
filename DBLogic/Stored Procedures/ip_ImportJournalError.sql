-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ImportJournalError
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ImportJournalError]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ImportJournalError.'
	Drop procedure [dbo].[ip_ImportJournalError]
End
Print '**** Creating Stored Procedure dbo.ip_ImportJournalError...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.ip_ImportJournalError
			@pnRowCount		int=0		OUTPUT,
			@pnUserIdentityId	int		= null,	-- User in the Workbench system
			@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
			@pnBatchNo		int,
			@pnPolicingBatchNo	int		= null, -- batch number to be used for Policing
			@psTransType		nvarchar(20)
AS
-- PROCEDURE :	ip_ImportJournalError
-- VERSION:	6
-- DESCRIPTION:	Process errors found while processing a particular transaction type on an 
--		Import Journal batch.
--
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 30 Mar 2004	MF		1	Process a previously loaded Import Journal Batch.
-- 01 Apr 2004	MF		2	Allow Policing transactions to be batched together for immediate processing
-- 06 Aug 2004	AB	8035	3	Add collate database_default to temp table definitions
-- 17 Mar 2005	MF	11167	4	Increase TRANSACTIONNO to INT
-- 05 Jul 2013	vql	R13629	5	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	6   Date conversion errors when creating cases and opening names in Chinese DB


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Create table #TEMPCASEEVENT   (	CASEID		int		NOT NULL,
				TRANSACTIONNO	int		NOT NULL,
				EVENTNO		int		NOT NULL,
				CYCLE		int		NOT NULL,
				REJECTREASON	nvarchar(254) 	collate database_default NOT NULL,
				JOURNALNO	nvarchar(20)  	collate database_default NULL
				)

declare @nErrorCode 		int
declare	@nRejectCount		int

declare	@sSQLString 		nvarchar(4000)

Set @nErrorCode=0

If @nErrorCode=0
Begin
	-- For each transaction with a rejected reason determine if there is an ImportControl row that
	-- indicates that an event is to be inserted or updated to process the error.

	set @sSQLString="
	insert into #TEMPCASEEVENT(CASEID, TRANSACTIONNO, REJECTREASON, JOURNALNO, CYCLE, EVENTNO)
	select	I.CASEID, I.TRANSACTIONNO, I.REJECTREASON, I.JOURNALNO, 1,
	convert(int,
	substring(
	max(
	CASE WHEN(IC.TRANSACTIONTYPE is null) THEN '0' ELSE '1' END+
	CASE WHEN(IC.PROPERTYTYPE    is null) THEN '0' ELSE '1' END+
	CASE WHEN(IC.COUNTRYCODE     is null) THEN '0' ELSE '1' END+
	convert(varchar(11), IC.EVENTNO)),4,20))		
	from IMPORTCONTROL IC
	join IMPORTJOURNAL I	on (I.IMPORTBATCHNO  =@pnBatchNo
				and I.TRANSACTIONTYPE=@psTransType
				and I.REJECTREASON is not null)
	join CASES C		on (C.CASEID=I.CASEID)
	where (IC.COUNTRYCODE    =C.COUNTRYCODE     or IC.COUNTRYCODE      is null)
	and   (IC.PROPERTYTYPE   =C.PROPERTYTYPE    or IC.PROPERTYTYPE    is null)
	and   (IC.TRANSACTIONTYPE=I.TRANSACTIONTYPE or IC.TRANSACTIONTYPE is null)
	and    IC.AUTOMATICFLAG=1
	group by I.CASEID, I.TRANSACTIONNO, I.REJECTREASON, I.JOURNALNO"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo		int,
				  @psTransType		nvarchar(20)',
				  @pnBatchNo  =@pnBatchNo,
				  @psTransType=@psTransType

	Set @nRejectCount=@@Rowcount

	-- If there were rows written to #TEMPCASEEVENT then load them into CASEEVENT
	If @nRejectCount>0
	Begin
		-- Update the IMPORTJOURNAL with details of the Event to be inserted.
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Update IMPORTJOURNAL
			Set ERROREVENTNO=T.EVENTNO
			from IMPORTJOURNAL I
			join #TEMPCASEEVENT T	on (T.CASEID=I.CASEID
						and T.TRANSACTIONNO=I.TRANSACTIONNO)
			where I.IMPORTBATCHNO=@pnBatchNo"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End

		-- Update any preexisting CASEEVENT rows
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			update CASEEVENT
			set	EVENTDATE=convert(nvarchar,getdate(),112),
				OCCURREDFLAG=1,
				DATEREMIND=NULL,
				EVENTTEXT=T.REJECTREASON,
				JOURNALNO=T.JOURNALNO,
				IMPORTBATCHNO=@pnBatchNo
			from CASEEVENT CE
			join #TEMPCASEEVENT T	on (T.CASEID =CE.CASEID
						and T.EVENTNO=CE.EVENTNO
						and T.CYCLE  =CE.CYCLE)
			where T.CYCLE=1"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End
		
		-- Insert new CASEEVENT rows
		If @nErrorCode=0
		Begin
			-- It is possible for the same transaction type to exist in the batch for the same
			-- CASEID.  To avoid the possibility of a duplicate key error use the DISTINCT clause.
			Set @sSQLString="
			insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, EVENTTEXT, JOURNALNO, IMPORTBATCHNO)
			select distinct T.CASEID, T.EVENTNO, T.CYCLE, convert(nvarchar,getdate(),112), 1, T.REJECTREASON, T.JOURNALNO, @pnBatchNo
			from #TEMPCASEEVENT T
			left join CASEEVENT CE	on (CE.CASEID =T.CASEID
						and CE.EVENTNO=T.EVENTNO
						and CE.CYCLE  =T.CYCLE)
			where CE.CASEID is null"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo	int',
						  @pnBatchNo=@pnBatchNo
		End

		-- Now insert a Policing row for each CASEEVENT updated or inserted.
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, 
						EVENTNO, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID, BATCHNO)
			select	getdate(), T.TRANSACTIONNO, 
				convert(varchar, getdate(),126)+convert(varchar,T.TRANSACTIONNO),1,
				CASE WHEN(@pnPolicingBatchNo is null) THEN 0 ELSE 1 END,
				T.EVENTNO, T.CASEID, 1, 3, substring(SYSTEM_USER,1,60),@pnUserIdentityId, @pnPolicingBatchNo
			from #TEMPCASEEVENT T"
	
			Exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnUserIdentityId	int,
							  @pnPolicingBatchNo	int',
							  @pnUserIdentityId =@pnUserIdentityId,
							  @pnPolicingBatchNo=@pnPolicingBatchNo
		End
	End	
End

RETURN @nErrorCode
go
grant execute on dbo.ip_ImportJournalError to public
go

