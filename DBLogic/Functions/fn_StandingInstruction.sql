-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_StandingInstruction
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_StandingInstruction') and xtype='FN')
begin
	print '**** Drop function dbo.fn_StandingInstruction.'
	drop function dbo.fn_StandingInstruction
	print '**** Creating function dbo.fn_StandingInstruction...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_StandingInstruction 
			(
			@pnCaseid		int,
			@psInstructionType	nvarchar(3)
			)
Returns smallint

-- FUNCTION :	fn_StandingInstruction
-- VERSION :	13
-- DESCRIPTION:	This function accepts the CASEID and Instruction Type and returns the specific
--		Standing Instruction

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Sep 2002	MF			Function created
-- 09 Nov 2005	MF	12007		Default instruction against Home Name not being returned if the CaseName
--					of the Name Type associated with the Instruction Type is missing.
-- 10 Apr 2006	MF	12537	6	If the CASEID is being used directly against the NameInstruction then ignore
--					the other characteristics
-- 29 Aug 2006	MF	13162	7	Performance improvement
-- 05 Feb 2007	MF	13162	8	Further performance improvement
-- 15 Dec 2008	MF	17136	9	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 29 Jun 2010	MF	18756	10	Performance improvement by separating the best fit on Names directly linked to Case from the default
--					instructions held against the Home Name. This also resolves a problem where no Standing Instruction was
--					returned if the Case was missing the main Name Type.
-- 01 Jul 2010	MF	18758	11	Increase the column size of Instruction Type to allow for expanded list.
-- 05 Dec 2011	LP	R11070	12	Default Instruction from ORGNAMENO of Name Office first before the HOMENAMENO
-- 20 May 2016	MF	61870	13	Error in join to OFFICE table. Should be using OFFICEID instead of the CASEID column.

as
Begin
	Declare @pnInstructionCode	smallint
	Declare @sInstNameType		nvarchar(3)
	Declare	@sRestrictedByType	nvarchar(3)
	Declare @nHomeNameno		int
	Declare @nOfficeNameNo		int

	Select  @sInstNameType    =I.NAMETYPE,
		@sRestrictedByType=I.RESTRICTEDBYTYPE,
		@nHomeNameno      =S.COLINTEGER
	From 	INSTRUCTIONTYPE I
	join	SITECONTROL S on (S.CONTROLID='HOMENAMENO')
	Where	INSTRUCTIONTYPE=@psInstructionType

	If  @sInstNameType is not null
	and @sRestrictedByType is null
	Begin
					-- To determine the best InstructionCode a weighting is	
					-- given based on the existence of characteristics	
					-- found in the NAMEINSTRUCTIONS row.  The MAX function 
					-- returns the highest weighting to which the required	
					-- INSTRUCTIONCODE has been concatenated.		
		SELECT	@pnInstructionCode=
			cast(
			substring(max (
			CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
			convert(nchar(11),NI.INSTRUCTIONCODE)),4,11) as smallint)
		FROM INSTRUCTIONS I
		join CASES C   			on (  C.CASEID=@pnCaseid)
		-- Use JOIN instead of LEFT JOIN for performance reasons
		join	(select NAMETYPE, min(replicate('0',6-len(SEQUENCE))+convert(varchar, SEQUENCE)+convert(varchar,NAMENO)) as NAMENO
			 from CASENAME
			 where EXPIRYDATE is null
			 and CASEID=@pnCaseid
			 group by NAMETYPE) X1	on (X1.NAMETYPE=@sInstNameType)
		join NAMEINSTRUCTIONS NI	on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
						and (NI.NAMENO=convert(int,substring(X1.NAMENO,7,12)))
						and (NI.CASEID=C.CASEID             OR NI.CASEID       is NULL) 
						and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE is NULL OR NI.CASEID is not NULL)
						and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE  is NULL OR NI.CASEID is not NULL) )
		where I.INSTRUCTIONTYPE=@psInstructionType

		-- Default Instruction from Case Office Entity
		If @pnInstructionCode is null
		Begin
			-- If no InstructionCode has been found against
			-- the main Name then drop back and use the Office Entity if available
			Select  @nOfficeNameNo = O.ORGNAMENO
			from CASES C
			join OFFICE O on (O.OFFICEID = C.OFFICEID)
			where C.CASEID = @pnCaseid
			
			If @nOfficeNameNo is not null
			Begin
				SELECT	@pnInstructionCode=
					cast(
					substring(max (
					CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
					CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
					CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
					convert(nchar(11),NI.INSTRUCTIONCODE)),4,11) as smallint)
				FROM INSTRUCTIONS I
				join CASES C   			on (  C.CASEID=@pnCaseid)
				join NAMEINSTRUCTIONS NI	on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
								and  NI.NAMENO=@nOfficeNameNo
								and (NI.CASEID is NULL) 
								and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE is NULL OR NI.CASEID is not NULL)
								and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE  is NULL OR NI.CASEID is not NULL) )
				where I.INSTRUCTIONTYPE=@psInstructionType
			End
		End
		
		If @pnInstructionCode is null
		Begin
			-- If no InstructionCode has been found against
			-- the Office Entity then drop back and use the HomeNmae
			-- NOTE
			-- This is coded separately to improve performance.		
			SELECT	@pnInstructionCode=
				cast(
				substring(max (
				CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
				convert(nchar(11),NI.INSTRUCTIONCODE)),4,11) as smallint)
			FROM INSTRUCTIONS I
			join CASES C   			on (  C.CASEID=@pnCaseid)
			join NAMEINSTRUCTIONS NI	on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
							and  NI.NAMENO=@nHomeNameno
							and (NI.CASEID is NULL) 
							and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE is NULL OR NI.CASEID is not NULL)
							and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE  is NULL OR NI.CASEID is not NULL) )
			where I.INSTRUCTIONTYPE=@psInstructionType
		End
	End
	Else If @sRestrictedByType is not null
	Begin
					-- To determine the best InstructionCode a weighting is	
					-- given based on the existence of characteristics	
					-- found in the NAMEINSTRUCTIONS row.  The MAX function 
					-- returns the highest weighting to which the required	
					-- INSTRUCTIONCODE has been concatenated.		
		SELECT	@pnInstructionCode=
			cast(
			substring(max (
			CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.RESTRICTEDTONAME	is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
			convert(nchar(11),NI.INSTRUCTIONCODE)),5,11) as smallint)
		FROM INSTRUCTIONS I
		join CASES C   			on (  C.CASEID=@pnCaseid)
		-- Use JOIN instead of LEFT JOIN for performance reasons
		join	(select NAMETYPE, min(replicate('0',6-len(SEQUENCE))+convert(varchar, SEQUENCE)+convert(varchar,NAMENO)) as NAMENO
			 from CASENAME
			 where EXPIRYDATE is null
			 and CASEID=@pnCaseid
			 group by NAMETYPE) X1	on (X1.NAMETYPE=@sInstNameType)
		left join	(select NAMETYPE, min(replicate('0',6-len(SEQUENCE))+convert(varchar, SEQUENCE)+convert(varchar,NAMENO)) as NAMENO
				 from CASENAME
				 where EXPIRYDATE is null
				 and CASEID=@pnCaseid
				 group by NAMETYPE) X2	on (X2.NAMETYPE=@sRestrictedByType)
		join NAMEINSTRUCTIONS NI	on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
						and  NI.NAMENO=convert(int,substring(X1.NAMENO,7,12))
						and (NI.CASEID=C.CASEID             OR NI.CASEID           is NULL) 
						and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE     is NULL OR NI.CASEID is not NULL)
						and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL OR NI.CASEID is not NULL)
						and (NI.RESTRICTEDTONAME=convert(int,substring(X2.NAMENO,7,12))
										    OR NI.RESTRICTEDTONAME is NULL) )
		where I.INSTRUCTIONTYPE=@psInstructionType

		-- Default Instruction from Case Office Entity
		If @pnInstructionCode is null
		Begin
			-- If no InstructionCode has been found against
			-- the main Name then drop back and use the Office Entity if available
			Select  @nOfficeNameNo = O.ORGNAMENO
			from CASES C
			join OFFICE O on (O.OFFICEID = C.OFFICEID)
			where C.CASEID = @pnCaseid
			
			If @nOfficeNameNo is not null
			Begin
				SELECT	@pnInstructionCode=
					cast(
					substring(max (
					CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
					CASE WHEN(NI.RESTRICTEDTONAME	is not null) THEN '1' ELSE '0' END +
					CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
					CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
					convert(nchar(11),NI.INSTRUCTIONCODE)),5,11) as smallint)
				FROM INSTRUCTIONS I
				join CASES C   			on (  C.CASEID=@pnCaseid)
				-- Get the restricted by name in case it is defined within the Office
				left join (select NAMETYPE, min(replicate('0',6-len(SEQUENCE))+convert(varchar, SEQUENCE)+convert(varchar,NAMENO)) as NAMENO
					 from CASENAME
					 where EXPIRYDATE is null
					 and CASEID=@pnCaseid
					 group by NAMETYPE) X2	on (X2.NAMETYPE=@sRestrictedByType)

				join NAMEINSTRUCTIONS NI	on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
								and  NI.NAMENO=@nOfficeNameNo
								and  NI.CASEID is NULL
								and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE is NULL)
								and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE  is NULL) 
								and (NI.RESTRICTEDTONAME=convert(int,substring(X2.NAMENO,7,12))
												    OR NI.RESTRICTEDTONAME is NULL))
				where I.INSTRUCTIONTYPE=@psInstructionType
			End
		End
		
		If @pnInstructionCode is null
		Begin
			-- If no InstructionCode has been found against
			-- the Office Entity then drop back and use the HomeName
			-- NOTE
			-- This is coded separately to improve performance.		
			SELECT	@pnInstructionCode=
				cast(
				substring(max (
				CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
				convert(nchar(11),NI.INSTRUCTIONCODE)),4,11) as smallint)
			FROM INSTRUCTIONS I
			join CASES C   			on (  C.CASEID=@pnCaseid)
			join NAMEINSTRUCTIONS NI	on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
							and  NI.NAMENO=@nHomeNameno
							and  NI.CASEID is NULL 
							and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE     is NULL OR NI.CASEID is not NULL)
							and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL OR NI.CASEID is not NULL)
							and  NI.RESTRICTEDTONAME is NULL )
			where I.INSTRUCTIONTYPE=@psInstructionType
		End
	End

	Return @pnInstructionCode
End
go

grant execute on dbo.fn_StandingInstruction to public
go
