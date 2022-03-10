if exists (select * from sysobjects where type='TR' and name = 'InsertCASEINDEXES_CASENAME')
begin
	PRINT 'Refreshing trigger InsertCASEINDEXES_CASENAME...'
	DROP TRIGGER InsertCASEINDEXES_CASENAME
end
go

Create trigger InsertCASEINDEXES_CASENAME on CASENAME for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertCASEINDEXES_CASENAME    
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 			8883 	1	Created
-- 24-OCT-2006	MF	13706	2	Correction to prevent duplicates
-- 11-FEB-2008	MF	RFC6191	3	Store generic index in UPPER case.
-- 24-Jun-2010	MF	RFC9296	4	When a CASENAME row is inserted the Case level
--					standing instructions are to be triggered to recalculate
--					if the NameType is used in any instruction type.
	Insert into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
	Select distinct UPPER(i.REFERENCENO), i.CASEID, 4
	from inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.GENERICINDEX=UPPER(i.REFERENCENO)
				 and CI.SOURCE=4)
	where i.REFERENCENO is not null
	and CI.CASEID is null

	-------------------------------------------------------
	-- If a NAMETYPE of the CASENAME row inserted
	-- is used by an INSTRUCTIONTYPE then trigger the
	-- Case to have its standing instructions recalculated
	-- if a Case level instruction for the instruction type
	-- does not already exist.
	-------------------------------------------------------
	Insert into CASEINSTRUCTIONSRECALC(CASEID, ONHOLDFLAG)
	select	distinct i.CASEID, 0
	from inserted i
	join INSTRUCTIONTYPE IT	on (i.NAMETYPE in (IT.NAMETYPE, IT.RESTRICTEDBYTYPE))
	left join (	select NI.CASEID, I.INSTRUCTIONTYPE
			from NAMEINSTRUCTIONS NI
			join INSTRUCTIONS I on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
			where NI.CASEID is not null) NI	
						on (NI.CASEID=i.CASEID
						and NI.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
	left join CASEINSTRUCTIONSRECALC CI	on (CI.CASEID=i.CASEID
						and CI.ONHOLDFLAG=0)
	where NI.CASEID is null -- A case level instruction does not already exist
	and CI.CASEID is null
End
go
