-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetDerivedAttnNameNo
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetDerivedAttnNameNo') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetDerivedAttnNameNo'
	Drop function [dbo].[fn_GetDerivedAttnNameNo]
End
Print '**** Creating Function dbo.fn_GetDerivedAttnNameNo...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetDerivedAttnNameNo
(
	@pnNameNo	int,
	@pnCaseId	int,
	@psNameType nvarchar(3)
)
Returns int
AS
-- FUNCTION :	fn_GetDerivedAttnNameNo
-- VERSION :	6
-- DESCRIPTION:	This function returns NAMENO to be used as the Attention Name for the given
--		CASENAME (case id, name no, name type).
 
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Mar 2006	DR	8911	1	Function created
-- 30 May 2006	DR	8911	2	Set derived attention to main contact regardless of its property type or country.
-- 16 Jun 2006	DR	8911	3	If 'MAIN CONTACT USED AS ATTENTION' is on, set to main contact always.
-- 15 Dec 2006	DR	14023	4	Return null if no associated name matching property type or country and no main contact.
-- 26 Apr 2007	JS	14323	5	Added attention name derivation logic for Debtor/Renewal Debtor.
-- 15 Dec 2008	MF	17136	6	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

Begin
	Declare	@nAttnNameNo		int,
		@nMainContactAsAttn	decimal(1,0)

	If (@pnNameNo is null)
		Return null

	If (@pnCaseId is not null)
		select @nMainContactAsAttn = COLBOOLEAN
		from SITECONTROL 
		where CONTROLID = 'Main Contact used as Attention'

	If (@pnCaseId is null) or (@nMainContactAsAttn = 1)
	Begin
		-- Just get the main contact if no case id specified.
		Select	@nAttnNameNo = MAINCONTACT
		from	NAME
		where	NAMENO = @pnNameNo
	End
	Else If @psNameType in ('D','Z')
	Begin
		-- Work out contact for Debtor/Renewal Debtor
		Select	@nAttnNameNo = isnull( A.CONTACT, N.MAINCONTACT )
		from	NAME N
		Left Join ASSOCIATEDNAME A on ( A.NAMENO = N.NAMENO
					and A.RELATIONSHIP = 'BIL'
					and A.CEASEDDATE is null
					and A.NAMENO = A.RELATEDNAME )
		Where N.NAMENO = @pnNameNo
	End
	Else
	Begin
		-- Work out the contact with the best match
		Select	@nAttnNameNo =
			    convert( int,
				substring( min( case when( A.PROPERTYTYPE is not null ) then '0' else '1' end +
						case when( A.COUNTRYCODE is not null ) then '0' else '1' end +
						case when( A.RELATEDNAME = N.MAINCONTACT ) then '0' else '1' end +
						replicate( '0', 6-datalength( convert( varchar(6), A.SEQUENCE ) ) ) +
						convert( varchar(6), A.SEQUENCE ) +
						convert( varchar, A.RELATEDNAME ) ), 10, 20 ) )
		from	CASES C
		join 	NAME  N	         on ( N.NAMENO = @pnNameNo )
		join	ASSOCIATEDNAME A on ( A.NAMENO = N.NAMENO
						and A.RELATIONSHIP = 'EMP'
						and A.CEASEDDATE is null
						-- 14023 Name must match either property type or country or be the main contact.
						and (	A.PROPERTYTYPE is not null or
							A.COUNTRYCODE is not null or
							A.RELATEDNAME = N.MAINCONTACT )
						and ( A.PROPERTYTYPE = C.PROPERTYTYPE or A.PROPERTYTYPE is null )
						and ( A.COUNTRYCODE = C.COUNTRYCODE or A.COUNTRYCODE  is null ) )
		where C.CASEID = @pnCaseId
	End

	Return @nAttnNameNo
End
GO

grant execute on dbo.fn_GetDerivedAttnNameNo to public
go
