if exists (select * from sysobjects where type='TR' and name = 'td_CaseNameType')
begin
	PRINT 'Refreshing trigger td_CaseNameType...'
	DROP TRIGGER td_CaseNameType
end
go

CREATE TRIGGER td_CaseNameType
ON CASENAME
FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER:	td_CaseNameType  
-- VERSION:	3
-- DESCRIPTION:	When a CASENAME row is deleted then check if the row has been deleted by the
--		application "Cases" or "Inprotech".  If so then if the NAMETYPE is linked to 
--		insert an EVENTNO then we should delete the CASEEVENT row if that case has no
--		other entries for the NAMETYPE being deleted.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18-Apr-2011	MF	10405	 1	Procedure created
-- 24 Oct 2017	AK	R72645	 2	Make compatible with case sensitive server with case insensitive database.
-- 14 Nov 2018  AV  75198/DR-45358	3   Date conversion errors when creating cases and opening names in Chinese DB

If APP_NAME() in ('Case','Inprotech')
Begin
	declare @nRowcount			int
	declare @nIdentityId			int

	declare @tblPolicing table
			(	CASEID		int	NOT NULL,
				EVENTNO		int	NOT NULL,
				CYCLE		int	NOT NULL,
				SEQUENCENO	int	identity(1,1)
				)

	-------------------------------------------------------
	-- Where the CASEEVENT row is to be deleted as a result
	-- of a CASENAME being removed, we need to raise a
	-- Policing request.
	------------------------------------------------------
	Insert into @tblPolicing(CASEID, EVENTNO, CYCLE)
	Select CE.CASEID, CE.EVENTNO, CE.CYCLE
	from deleted d
	join NAMETYPE NT	on (NT.NAMETYPE=d.NAMETYPE)
	join CASEEVENT CE	on (CE.CASEID  =d.CASEID
				and CE.EVENTNO =NT.CHANGEEVENTNO
				and CE.CYCLE   =1
				and CE.OCCURREDFLAG=1)
	left join CASENAME CN	on (CN.CASEID=d.CASEID
				and CN.NAMETYPE=d.NAMETYPE
				and CN.NAMENO <>d.NAMENO)
	where CN.CASEID is null

	Set @nRowcount=@@Rowcount

	If @nRowcount>0
	Begin
		---------------------------
		-- Get the User Identity Id
		---------------------------
		select	@nIdentityId=CASE WHEN(substring(context_info,1,4) <>0x0000000) THEN cast(substring(context_info,1,4)  as int) END
		from master.dbo.sysprocesses
		where spid=@@SPID
		and substring(context_info,1, 4)<>0x0000000

		-------------------------------------------------------
		-- Now update the CASEEVENT row just identified to
		-- indicate that we want to delete the row.
		------------------------------------------------------
		Update CE
		Set	EVENTDATE   =null,
			OCCURREDFLAG=0
		from @tblPolicing P
		join CASEEVENT CE	on (CE.CASEID  =P.CASEID
					and CE.EVENTNO =P.EVENTNO
					and CE.CYCLE   =P.CYCLE)

		-------------------------------------------------------
		-- Now copy the temporary Policing rows into the live
		-- Policing table
		------------------------------------------------------

		insert into POLICING (DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
		 		      ONHOLDFLAG, CASEID, EVENTNO, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
		select	getdate(), 
			T.SEQUENCENO, 
			'CN Delete-'+convert(varchar, getdate(),126)+convert(varchar,T.SEQUENCENO),
			1,
			0, 
			T.CASEID,
			T.EVENTNO,
			T.CYCLE, 
			3, 
			substring(SYSTEM_USER,1,60), 
			@nIdentityId
		from @tblPolicing T
	End
End	
go