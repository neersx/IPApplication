-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_DefaultNameForSimulatedCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_DefaultNameForSimulatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_DefaultNameForSimulatedCase.'
	drop procedure dbo.cs_DefaultNameForSimulatedCase
end
print '**** Creating procedure dbo.cs_DefaultNameForSimulatedCase...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_DefaultNameForSimulatedCase
	@pnDefaultNameNo		int		output, -- the default NameNo
	@psNameTypeToFind		nvarchar(3),		-- the NameType we are trying to default
	@pnNameNo			int,			-- NameNo to trigger default
	@psCaseType			nchar(1)	= null,	-- User entered CaseType
	@psCountryCode			nvarchar(3)	= null, -- User entered Country
	@psPropertyType			nchar(1)	= null, -- User entered Property Type
	@psCaseCategory			nvarchar(2)	= null, -- User entered Category
	@psSubType			nvarchar(2)	= null -- User entered Sub Type
	
AS
-- PROCEDURE :	cs_DefaultNameForSimulatedCase
-- VERSION :	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns a default Name to be used as a NameType for a virtual case defined by parameterised
--		characteristics of the Case.
-- CALLED BY :	Centura

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 Sep 2007	MF	SQA15357  1	Procedure created.
-- 15 OCT 2007	CR	SQA15357  1	Select Output Parameter for use with Centura.
-- 11 Dec 2008	MF	SQA17136  2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 01 Jul 2010	MF	SQA18758  3	Increase the column size of Instruction Type to allow for expanded list.
-- 05 Dec 2011	LP	RFC11070  4	Include Instruction against Office Entity in best fit calculation

set nocount on

--

create table #TEMPNAMETYPES (
	COPYFROMNAMETYPE	nvarchar(3)	collate database_default NOT NULL,
	INSTRUCTIONTYPE		nvarchar(3)	collate database_default NOT NULL,
	FLAGNUMBER		smallint	NOT NULL)

Declare	@ErrorCode		int,
	@nRowCount		int,
	@nCriteriaNo		int,
	@nHomeNameNo		int,
	@sNameType		nvarchar(3),
	@sSQLString		nvarchar(4000),
	@nOfficeNameNo		int
	

set @ErrorCode=0

If @ErrorCode=0
Begin
	----------------------------------------------
	-- Get the CRITERIANO that holds the rules for
	-- setting the NameType required.
	----------------------------------------------
	
	Set @sSQLString="
	SELECT 
	@nCriteriaNo   =
	convert(int,
	substring(
	max (
	CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
		ELSE CASE WHEN(C.CASETYPE=@psCaseType) 	 THEN '2' ELSE '1' END 
	END +  
	CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
	CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (C.DATEOFACT IS NULL)		THEN '0' ELSE '1' END +
	isnull(convert(varchar, DATEOFACT, 112),'00000000') +
	CASE WHEN (C.USERDEFINEDRULE is NULL
		OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
	convert(varchar,C.CRITERIANO)), 16,20))
	FROM CRITERIA C 
	join CASETYPE CT	on (CT.CASETYPE=@psCaseType)
	join EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO
				and EC.CHANGENAMETYPE=@psNameTypeToFind
				and EC.INSTRUCTIONTYPE is not null
				and EC.FLAGNUMBER      is not null)
	WHERE	C.RULEINUSE		= 1  	
	AND	C.PURPOSECODE		= 'E'
	AND (	C.CASETYPE	      in (@psCaseType,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
	AND (	C.PROPERTYTYPE 		= @psPropertyType 	OR C.PROPERTYTYPE 	IS NULL ) 
	AND (	C.COUNTRYCODE 		= @psCountryCode 	OR C.COUNTRYCODE 	IS NULL ) 
	AND (	C.CASECATEGORY 		= @psCaseCategory 	OR C.CASECATEGORY 	IS NULL ) 
	AND (	C.SUBTYPE 		= @psSubType		OR C.SUBTYPE 		IS NULL ) 
	AND (	C.DATEOFACT 	       <= getdate()		OR C.DATEOFACT 		IS NULL )"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCriteriaNo		int		OUTPUT,
				  @psNameTypeToFind	nvarchar(3),
				  @psCaseType		nchar(1),
				  @psCountryCode	nvarchar(3),
				  @psPropertyType	nchar(1),
				  @psCaseCategory	nvarchar(2),
				  @psSubType		nvarchar(2)',
				  @nCriteriaNo		=@nCriteriaNo	OUTPUT,
				  @psNameTypeToFind	=@psNameTypeToFind,
				  @psCaseType		=@psCaseType,
				  @psCountryCode	=@psCountryCode,
				  @psPropertyType	=@psPropertyType,
				  @psCaseCategory	=@psCaseCategory,
				  @psSubType		=@psSubType
End

If  @nCriteriaNo is not null
and @ErrorCode=0
Begin
	-- Load a temporary table with the possible NameTypes that could be copied
	-- into NameTypeToFind along with the Standing Instruction details required
	-- for this to occur.

	Set @sSQLString="
	insert into #TEMPNAMETYPES (COPYFROMNAMETYPE,INSTRUCTIONTYPE,FLAGNUMBER)
	select distinct COPYFROMNAMETYPE,INSTRUCTIONTYPE,FLAGNUMBER
	from EVENTCONTROL EC
	where CRITERIANO=@nCriteriaNo
	and CHANGENAMETYPE=@psNameTypeToFind
	and INSTRUCTIONTYPE is not null
	and FLAGNUMBER is not null"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCriteriaNo		int,
				  @psNameTypeToFind	nvarchar(3)',
				  @nCriteriaNo     =@nCriteriaNo,
				  @psNameTypeToFind=@psNameTypeToFind

	Set @nRowCount=@@rowcount

	If @ErrorCode=0
	and @nRowCount>0
	Begin
		-- If there are Standing Instructions to find then get the HomeName
		-- which may be required as a default.

		Set @sSQLString="
		Select  @nHomeNameNo=S.COLINTEGER
		From 	SITECONTROL S 
		Where	S.CONTROLID='HOMENAMENO'"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nHomeNameNo		int	OUTPUT',
					  @nHomeNameNo  =@nHomeNameNo	OUTPUT
					  
		Set @sSQLString="
		Select  @nOfficeNameNo = O.ORGNAMENO
		from TABLEATTRIBUTES T
		join OFFICE O on (O.OFFICEID = T.TABLECODE)
		and T.PARENTTABLE = 'NAME'
		and T.GENERICKEY = @pnNameNo
		and T.TABLETYPE = (SELECT TABLETYPE from TABLETYPE where DATABASETABLE = 'OFFICE')"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nOfficeNameNo	int		OUTPUT,
					  @pnNameNo		int		',
					  @nOfficeNameNo 	=@nOfficeNameNo	OUTPUT,
					  @pnNameNo		=@pnNameNo

		If @ErrorCode=0
		Begin
			--------------------------------------------------------------
			-- Find the NameType associated with the Standing Instruction.
			-- To determine the best InstructionCode a weighting is	given
			-- based on the existence of characteristics found in the
			-- NAMEINSTRUCTIONS row.  The MAX function returns the highest
			-- weighting to which the required INSTRUCTIONCODE has been
			-- concatenated.
			--------------------------------------------------------------
			set @sSQLString="
			Select @sNameType=max(COPYFROMNAMETYPE)
			from #TEMPNAMETYPES NT
			join (	SELECT T.INSTRUCTIONTYPE,
					convert(int,
					substring(max (isnull(
				 	CASE WHEN(NI.NAMENO	  = @pnNameNo) THEN '1' ELSE '0' END +
				 	CASE WHEN(NI.NAMENO	= @nOfficeNameNo) THEN '1' ELSE '0' END +
					CASE WHEN(NI.PROPERTYTYPE is not null) THEN '1' ELSE '0' END +
					CASE WHEN(NI.COUNTRYCODE  is not null) THEN '1' ELSE '0' END +
					convert(nchar(11),NI.INSTRUCTIONCODE),'')),5,11)) as INSTRUCTIONCODE
				FROM (select distinct INSTRUCTIONTYPE
				      from #TEMPNAMETYPES) T
				join INSTRUCTIONS I	 on (  I.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
				join NAMEINSTRUCTIONS NI on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
							 and (NI.NAMENO		=@pnNameNo	 OR NI.NAMENO=@nHomeNameNo OR NI.NAMENO=@nOfficeNameNo)
							 and (NI.PROPERTYTYPE	=@psPropertyType OR NI.PROPERTYTYPE is NULL)
							 and (NI.COUNTRYCODE	=@psCountryCode  OR NI.COUNTRYCODE  is NULL)
							 and (NI.CASEID is NULL) 
							 and (NI.RESTRICTEDTONAME is NULL) )
				group by T.INSTRUCTIONTYPE) CI	on (CI.INSTRUCTIONTYPE=NT.INSTRUCTIONTYPE)
			join INSTRUCTIONFLAG I	on (I.INSTRUCTIONCODE=CI.INSTRUCTIONCODE
						and I.FLAGNUMBER     =NT.FLAGNUMBER)"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sNameType		nvarchar(3)	OUTPUT,
						  @pnNameNo		int,
						  @nHomeNameNo		int,
						  @nOfficeNameNo	int,
						  @psPropertyType	nchar(1),
						  @psCountryCode	nvarchar(3)',
						  @sNameType     	=@sNameType	OUTPUT,
						  @pnNameNo      	=@pnNameNo,
						  @nHomeNameNo		=@nHomeNameNo,
						  @nOfficeNameNo	=@nOfficeNameNo,
						  @psPropertyType	=@psPropertyType,
						  @psCountryCode	=@psCountryCode
		End
	End
End

-----------------------------------------------------
-- If a NameType has been found then apply the normal
-- default rules for that NameType to find the NameNo
-- to return as the default to use.
-----------------------------------------------------

If  @sNameType is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	select 	distinct @pnDefaultNameNo=N.NAMENO
	from 	NAMETYPE NT  
	-- Pick up the CaseName's associated Name
     	left join ASSOCIATEDNAME A 
				on (A.NAMENO	   = @pnNameNo
				and A.RELATIONSHIP = NT.PATHRELATIONSHIP
				and(A.PROPERTYTYPE = @psPropertyType OR A.PROPERTYTYPE is null)
				and(A.COUNTRYCODE  = @psCountryCode  OR A.COUNTRYCODE  is null)
				-- There may be multiple AssociatedNames.  
				-- A best fit against the Case attributes is required to determine
				-- the characteristics of the Associated Name that best match the Case.
				-- This then allows for all of the associated names with the best
				-- characteristics for the Case to be returned.
				and CASE WHEN(A.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
				    CASE WHEN(A.COUNTRYCODE  is null) THEN '0' ELSE '1' END
					=	(	select
							max (	case when (A1.PROPERTYTYPE is null) then '0' else '1' end +    			
								case when (A1.COUNTRYCODE  is null) then '0' else '1' end)
							from ASSOCIATEDNAME A1
							where A1.NAMENO=A.NAMENO
							and   A1.RELATIONSHIP=A.RELATIONSHIP
							and  (A1.PROPERTYTYPE=@psPropertyType OR A1.PROPERTYTYPE is null)
							and  (A1.COUNTRYCODE =@psCountryCode  OR A1.COUNTRYCODE  is null)))
	-- If no associated Name found and inheritance
	-- is to also consider the Home Name
	-- then get the Home Name associated Name
     	left join ASSOCIATEDNAME AH 
				on (AH.NAMENO	    = @nHomeNameNo
				and AH.RELATIONSHIP = NT.PATHRELATIONSHIP
				and(AH.PROPERTYTYPE = @psPropertyType OR AH.PROPERTYTYPE is null)
				and(AH.COUNTRYCODE  = @psCountryCode  OR AH.COUNTRYCODE  is null)
				and A.RELATEDNAME is null
				and NT.USEHOMENAMEREL=1
				-- There may be multiple AssociatedNames.  
				-- A best fit against the Case attributes is required to determine
				-- the characteristics of the Associated Name that best match the Case.
				-- This then allows for all of the associated names with the best
				-- characteristics for the Case to be returned.
				
				and CASE WHEN(AH.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
				    CASE WHEN(AH.COUNTRYCODE  is null) THEN '0' ELSE '1' END
					=	(	select
							max (	case when (AH1.PROPERTYTYPE is null) then '0' else '1' end +    			
								case when (AH1.COUNTRYCODE  is null) then '0' else '1' end)
							from ASSOCIATEDNAME AH1
							where AH1.NAMENO=AH.NAMENO
							and   AH1.RELATIONSHIP=AH.RELATIONSHIP
							and  (AH1.PROPERTYTYPE=@psPropertyType OR AH1.PROPERTYTYPE is null)
							and  (AH1.COUNTRYCODE =@psCountryCode  OR AH1.COUNTRYCODE  is null)))
	-- Choose the name to use as the default
     	join NAME N  on (N.NAMENO= 	CASE WHEN(A.RELATEDNAME is not null) THEN A.RELATEDNAME
					     -- Only default to parent name if hierarchy flag set on.
					     WHEN(NT.HIERARCHYFLAG=1)        THEN @pnNameNo
					     -- Use Default Name if relationship not there for home name.
					     WHEN(NT.USEHOMENAMEREL=1)       THEN AH.RELATEDNAME
					     -- Use Default Name if nothing else found.
				     	     ELSE NT.DEFAULTNAMENO

					END)
	Where NT.NAMETYPE=@sNameType"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnDefaultNameNo	int			OUTPUT,
				  @sNameType		nvarchar(3),
				  @pnNameNo		int,
				  @nHomeNameNo		int,
				  @psPropertyType	nchar(1),
				  @psCountryCode	nvarchar(3)',
				  @pnDefaultNameNo	=@pnDefaultNameNo	OUTPUT,
				  @sNameType     	=@sNameType,
				  @pnNameNo      	=@pnNameNo,
				  @nHomeNameNo		=@nHomeNameNo,
				  @psPropertyType	=@psPropertyType,
				  @psCountryCode	=@psCountryCode

	SELECT @pnDefaultNameNo
End

RETURN @ErrorCode
go

grant execute on dbo.cs_DefaultNameForSimulatedCase  to public
go

