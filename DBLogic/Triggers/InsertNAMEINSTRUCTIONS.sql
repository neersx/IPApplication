/******************************************************************************************************************/
/*** Create InsertNAMEINSTRUCTIONS trigger									***/
/******************************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'InsertNAMEINSTRUCTIONS')
begin
 	PRINT 'Refreshing trigger InsertNAMEINSTRUCTIONS...'
	DROP TRIGGER InsertNAMEINSTRUCTIONS
end
else
	PRINT 'Creating trigger InsertNAMEINSTRUCTIONS...'
	print ''
go
	
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE TRIGGER InsertNAMEINSTRUCTIONS ON NAMEINSTRUCTIONS FOR INSERT NOT FOR REPLICATION AS
-- TRIGGER:	InsertNAMEINSTRUCTIONS    
-- VERSION:	2
-- DESCRIPTION:	If a NameInstructions row that is specific to a particular Case
--		is inserted then a recalculation is required for Case level
--		standing instructions used to improve the performance of Case queries.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30-Nov-2010	MF	 	1	Trigger created
-- 06 Jun 2014	MF	S22209	2	Ensures NAMEINSTRUCTIONS rows that include a CASEID
--					donot have any data in COUNTRYCODE and PROPERTYTYPE

	---------------------------------------------------
	-- Insert of a Standing Instruction against either
	-- a Name or a Case is to trigger the recalculation
	-- of the Standing Instructions against Cases.
	---------------------------------------------------
	-- Case Level
	Insert into CASEINSTRUCTIONSRECALC(CASEID, ONHOLDFLAG)
	select	i.CASEID, 0
	from inserted i
	left join CASEINSTRUCTIONSRECALC CI	on (CI.CASEID=i.CASEID
						and CI.ONHOLDFLAG=0)
	where i.CASEID is not null
	AND  CI.CASEID is null

	-- Name Level
	Insert into CASEINSTRUCTIONSRECALC(NAMENO, ONHOLDFLAG)
	select	i.NAMENO, 0
	from inserted i
	left join CASEINSTRUCTIONSRECALC CI	on (CI.NAMENO=i.NAMENO
						and CI.ONHOLDFLAG=0)
	where i.CASEID is null
	AND  CI.NAMENO is null
	
	---------------------------------------------------
	-- If CASEID exists in the NAMEINSTRUCTION row then 
	-- ensure COUNTRYCODE and PROPERTYTYPE are null.
	---------------------------------------------------
	If exists(select 1 from inserted where CASEID is not null and (PROPERTYTYPE is not NULL OR COUNTRYCODE is not null))
	Begin
		update NI
		set COUNTRYCODE=null,
		    PROPERTYTYPE=null
		from inserted i
		join NAMEINSTRUCTIONS NI on (NI.NAMENO=i.NAMENO
					 and NI.INTERNALSEQUENCE=i.INTERNALSEQUENCE
					 and NI.CASEID=i.CASEID)
		where NI.COUNTRYCODE  is not null
		   OR NI.PROPERTYTYPE is not null
	End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
