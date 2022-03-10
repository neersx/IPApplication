-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateRelatedCaseForNationalPhase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateRelatedCaseForNationalPhase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_UpdateRelatedCaseForNationalPhase.'
	drop procedure [dbo].[cs_UpdateRelatedCaseForNationalPhase]
	print '**** Creating Stored Procedure dbo.cs_UpdateRelatedCaseForNationalPhase...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

create procedure dbo.cs_UpdateRelatedCaseForNationalPhase
(
	@pnUserIdentityId		int,			-- Mandatory
	@pnrelationShipNo		int=null,		
	@psCulture			nvarchar(10)	= null,
	@psCaseKey			varchar(11)	= null,
	@psRelatedCaseKey		varchar(max)	= null,	-- comma separated list of related Cases
	@psCountryKey			nvarchar(3)	= null	-- Country codes to match Related Cases.	
)
AS
-- VERSION:	7
-- DESCRIPTION:	Update Related Case for National Phase
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Aug 2002	SF 			Revision 0.16 Implement Reciprocal Relationship.
-- 15 Nov 2002	SF		4	Update Version Number
-- 25 Nov 2011	ASH		5	Change the size of Case Key and Related Case key to 11.
-- 15 Dec 2011	MF	11628	6	Allowe multiple RelatedCaseKey values to be accepted as a comma separated list
-- 18 Jun 2013  AK	DR66	7	Added parameter @dtDesignatedDate and @pnrelationShipNo

SET NOCOUNT ON

declare @tbRelatedCase	table (
		CASEID		int		not null,
		ROWNUMBER	smallint	identity(1,1)
		)

declare @nErrorCode		int
declare @nRowCount		int
declare	@nRow			int
declare @nUpdatedCount		int
declare @nCaseId		int
declare @sRecipRelationship	nvarchar(3)

Set @nErrorCode = 0

--------------------------------
-- Convert the CaseKey passed as
-- a parameter into an integer
--------------------------------
if isnumeric(@psCaseKey)=1
begin
	set @nCaseId = cast(@psCaseKey as int)

	set @nErrorCode = @@error
end
else begin
	RAISERROR('@psCaseKey must be an integer', 14, 1)
	Set @nErrorCode = @@ERROR
End

--------------------------------
-- Load the Related Case Keys
-- into a table using the comma
-- to delimit each CaseId.
--------------------------------
If @nErrorCode=0
Begin
	insert into @tbRelatedCase(CASEID)
	select CS.Parameter
	from  dbo.fn_Tokenise(@psRelatedCaseKey, ',') CS
	join  CASES C on (C.CASEID=CS.Parameter)
	where isnumeric(CS.Parameter)=1

	Select  @nErrorCode=@@ERROR,
		@nRowCount=@@ROWCOUNT
End

-------------------------------------
-- Loop through each Related CaseId
-- and check if a RELATECASE row 
-- exists that can now be updated to
-- point to the RelatedCaseId.
-------------------------------------
Set @nRow=1

While @nRow<=@nRowCount
and   @nErrorCode=0
Begin
	-------------------------------------------
	-- Update the first RelatedCase row that
	-- matches the country and does not already
	-- point to a RelatedCaseId.
	-------------------------------------------
	update 	RC
	set	RELATEDCASEID = T.CASEID
	from	RELATEDCASE RC
	join	@tbRelatedCase T on (T.ROWNUMBER=@nRow)
	where	RC.CASEID = @nCaseId
	and	RC.RELATIONSHIP = 'DC1'	-- Designated Country relationship
	and	RC.COUNTRYCODE  = @psCountryKey
	and	RC.RELATEDCASEID is null	
	and RC.RELATIONSHIPNO=@pnrelationShipNo
		
	Select  @nErrorCode   =@@ERROR,
		@nUpdatedCount=@@ROWCOUNT

	If  @nErrorCode=0
	and @nUpdatedCount=0
	Begin
		------------------------------------
		-- If no RELATEDCASE row was updated
		-- then a new row will need to be 
		-- inserted.
		------------------------------------
		insert into RELATEDCASE
		(
			CASEID,
			RELATIONSHIP,
			RELATEDCASEID,
			RELATIONSHIPNO,
			COUNTRYCODE,
			COUNTRYFLAGS,
			CURRENTSTATUS,
			PRIORITYDATE
		)
		select	@nCaseId,
			'DC1',
			T.CASEID,
			isnull(RC1.RELATIONSHIPNO, 0)+1,
			@psCountryKey,
			RC2.COUNTRYFLAGS,
			RC2.CURRENTSTATUS,
			RC2.PRIORITYDATE
		from @tbRelatedCase T
		left join (select CASEID, max(RELATIONSHIPNO) as RELATIONSHIPNO
			   from RELATEDCASE
			   group by CASEID) RC1	on (RC1.CASEID=@nCaseId)
		------------------------------------
		-- Need to get the CurrentStatus and 
		-- CountryFlags from the existing 
		-- RelatedCase for this Country
		------------------------------------
		left join RELATEDCASE RC2	on (RC2.CASEID=@nCaseId
						and RC2.RELATIONSHIP='DC1'
						and RC2.COUNTRYCODE =@psCountryKey
						and RC2.RELATIONSHIPNO
							=(Select min(RC4.RELATIONSHIPNO)
							  from RELATEDCASE RC4
							  where RC4.CASEID=RC2.CASEID
							  and   RC4.RELATIONSHIP=RC2.RELATIONSHIP
							  and   RC4.COUNTRYCODE =RC2.COUNTRYCODE
							  and   RC4.CURRENTSTATUS is not null) )
		-- Don't insert a duplicate row
		left join RELATEDCASE RC3	on (RC3.CASEID=@nCaseId
						and RC3.RELATIONSHIP ='DC1'
						and RC3.RELATEDCASEID=T.CASEID)
		where T.ROWNUMBER=@nRow
		and RC3.CASEID is null
		
		set @nErrorCode = @@ERROR
	End	

	-- Now increment the row pointer

	Set @nRow=@nRow + 1
End

---------------------------------
-- Create reciprocal Relationship 
-- if necessary
---------------------------------
if  @nErrorCode = 0
and @nRowCount  > 0
begin
	---------------------------------
	-- Obtain reciprocal relationship 
	-- for 'DC1' and 'CaseKey' from 
	-- ValidRelationships.
	---------------------------------
	select @sRecipRelationship = VR.RECIPRELATIONSHIP
	from CASES C
	join VALIDRELATIONSHIPS VR 
		on (VR.RELATIONSHIP = 'DC1'
		and VR.PROPERTYTYPE = C.PROPERTYTYPE
		and VR.COUNTRYCODE = 
		( select min( VR1.COUNTRYCODE )
			from VALIDRELATIONSHIPS VR1
			where VR1.COUNTRYCODE in ( 'ZZZ', C.COUNTRYCODE ) 
			and VR1.PROPERTYTYPE=C.PROPERTYTYPE
			and VR1.RELATIONSHIP = VR.RELATIONSHIP ) )
	where C.CASEID = @nCaseId

	Set @nErrorCode = @@ERROR

	if @sRecipRelationship is not null
	and @nErrorCode = 0
	begin
		---------------------------------------
		-- Now insert a reciprocal related case
		-- for each case passed as a parameter.
		---------------------------------------
		insert into RELATEDCASE
		(
			CASEID,
			RELATIONSHIP,
			RELATEDCASEID,
			RELATIONSHIPNO
		)
		select	T.CASEID,
			@sRecipRelationship,
			@nCaseId,
			isnull(RC1.RELATIONSHIPNO, 0)+1
		from @tbRelatedCase T
		left join (select CASEID, max(RELATIONSHIPNO) as RELATIONSHIPNO
			   from RELATEDCASE
			   group by CASEID ) RC1 on (RC1.CASEID=T.CASEID)
		-- Don't insert a duplicate row
		left join RELATEDCASE RC2	 on (RC2.CASEID=T.CASEID
						 and RC2.RELATIONSHIP =@sRecipRelationship
						 and RC2.RELATEDCASEID=@nCaseId)
		where RC2.CASEID is null
		
		set @nErrorCode = @@error			
	end		
end

return @nErrorCode
GO

grant execute on dbo.cs_UpdateRelatedCaseForNationalPhase to public
go
