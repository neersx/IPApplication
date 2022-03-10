if exists (select * from sysobjects where type='TR' and name = 'DeleteCASEINDEXES_CASENAME')
begin
	PRINT 'Refreshing trigger DeleteCASEINDEXES_CASENAME...'
	DROP TRIGGER DeleteCASEINDEXES_CASENAME
end
go
Create trigger DeleteCASEINDEXES_CASENAME on CASENAME for DELETE NOT FOR REPLICATION as 
Begin
-- TRIGGER:	DeleteCASEINDEXES_CASENAME    
-- VERSION:	5
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 			8883 	1	Created
-- 24-OCT-2006	MF	13706	2	Correction to prevent duplicates
-- 11-FEB-2008	MF	RFC6191	3	Generic Index stored as UPPER case so must join
--					using UPPER()
-- 24-Jun-2010	MF	RFC9296	4	When a CASENAME row is deleted the Case level
--					standing instructions are to be triggered to recalculate
--					if the NameType is used in any instruction type.
-- 30-Aug-2010	MF	RFC9296	5	Ensure the a CASES row exists before inserting CASEINSTRUCTIONSRECALC.

	-------------------------------------------
	-- Only delete the row from CASEINDEXES if 
	-- there is no other CASENAME row for 
	-- the Case that generated the same index
	-------------------------------------------

	Delete CASEINDEXES
	from CASEINDEXES CI
	join deleted d		on (d.CASEID=CI.CASEID
				and UPPER(d.REFERENCENO)=CI.GENERICINDEX)
	left join CASENAME CN	on (CN.CASEID=CI.CASEID
				and UPPER(CN.REFERENCENO)=CI.GENERICINDEX
				and CN.EXPIRYDATE is null)
	where CI.SOURCE=4
	and CN.CASEID is null

	-------------------------------------------------------
	-- If the NAMETYPE of the CASENAME row deleted
	-- is used by an INSTRUCTIONTYPE then trigger the
	-- Case to have its standing instructions recalculated
	-- if a Case level instruction for the instruction type
	-- does not already exist.
	-------------------------------------------------------
	Insert into CASEINSTRUCTIONSRECALC(CASEID, ONHOLDFLAG)
	select	distinct d.CASEID, 0
	from deleted d
	join CASES C	on (C.CASEID=d.CASEID)
	join INSTRUCTIONTYPE IT	on (d.NAMETYPE in (IT.NAMETYPE, IT.RESTRICTEDBYTYPE))
	left join (	select NI.CASEID, I.INSTRUCTIONTYPE
			from NAMEINSTRUCTIONS NI
			join INSTRUCTIONS I on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
			where NI.CASEID is not null) NI	
						on (NI.CASEID=d.CASEID
						and NI.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
	left join CASEINSTRUCTIONSRECALC CI	on (CI.CASEID=d.CASEID
						and CI.ONHOLDFLAG=0)
	where NI.CASEID is null -- A case level instruction does not already exist
	and CI.CASEID is null


End
go
