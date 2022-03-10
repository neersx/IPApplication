-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_RecalculateDerivedAttention
-----------------------------------------------------------------------------------------------------------------------------
if exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_RecalculateDerivedAttention]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_RecalculateDerivedAttention.'
	drop procedure [dbo].[cs_RecalculateDerivedAttention]
end
print '**** Creating Stored Procedure dbo.cs_RecalculateDerivedAttention...'
print ''
go

set quoted_identifier off
go

Create procedure dbo.cs_RecalculateDerivedAttention
(
	@pnUserIdentityId	int		= null,
	@pnMainNameKey		int,		-- Mandatory
	@pnOldAttentionKey	int		= null,
	@pnNewAttentionKey	int		= null,
	@pnAssociatedNameKey	int		= null,
	@psAssociatedRelation	nvarchar(3)	= null,
	@pnAssociatedSequence	smallint	= null,
	@pnRowCount		int		= 0 output,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE :	cs_RecalculateDerivedAttention
-- VERSION :	10
-- DESCRIPTION:	When an attention name has not been explicitly provided for a case name, the system derives one.
--		This information is held on the database against the case name.  Whenever information at the name
--		level changes that might affect the derived attention, the values stored on the case names need
--		to be recalculated. This procedure recalculates the derived attention information on case names that
--		match the supplied parameters,
-- SCOPE:	CPA.net, InPro.net
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 16 Mar 2006	DR	8911	1	Procedure created
-- 12 May 2006	DR	8911	2	Minor bug fixes.
-- 25 May 2006	DR	8911	3	Swap @pnAssociatedNameKey and @pnMainNameKey around in selects when @pnAssociatedNameKey!=null
-- 30 May 2006	DR	8911	4	Set derived attention to main contact regardless of its property type or country.
-- 20 Jun 2006	DR	8911	5	Fix bug in sql for main contact only.
-- 27 Jun 2006	DR	8911	6	Remove 'old attention name' condition from when main contact only.
-- 15 Dec 2006	DR	14023	7	Set attention to null if name type 'show contact' flag is off, except for Instructor and Agent,
--					or no associated name matching property type or country and no main contact.
-- 26 Apr 2007	JS	14323	8	Added attention name derivation logic for Debtor/Renewal Debtor.
-- 11 Dec 2008	MF	17136	9	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 19 May 2011	MF	19632	10	When NULL has been passed in the @pnMainNameKey parameter then do not attempt to update the
--					derived attention.

Begin
	Declare @nMainContactOnly	decimal(1, 0)
	Declare	@nErrorCode		int
	Declare	@nRowCount		int
	Declare @sSQLString		nvarchar(4000)

	Set @nErrorCode=0
	Set @nRowCount =0

	If @pnMainNameKey is not null
	Begin
		-- If updating for an associated name relationship and new key is given, can do update directly.
		If @pnAssociatedNameKey is not null and @pnNewAttentionKey is not null
		Begin
			Set @sSQLString=
			"Update	CASENAME"+char(10)+
			"set CORRESPONDNAME="+convert(varchar,@pnNewAttentionKey)+char(10)+
			"from CASENAME CN"+char(10)+
			"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
			"where CN.NAMENO="+convert(varchar,@pnMainNameKey)+char(10)+
			"and ( CN.NAMETYPE in ('I','A') or convert(bit,NT.COLUMNFLAGS&1)=1 )"+char(10)+
			"and CN.DERIVEDCORRNAME=1"+char(10)+
			"and CN.INHERITED=1"+char(10)+
			"and CN.INHERITEDNAMENO="+convert(varchar,@pnAssociatedNameKey)+char(10)+
			"and CN.INHERITEDRELATIONS='"+@psAssociatedRelation+"'"+char(10)+
			"and CN.INHERITEDSEQUENCE="+convert(varchar,isnull(@pnAssociatedSequence,0))
		End
		Else
		Begin
			-- Get the site control value to tell us how to derive the attention names ---
			Select	@nMainContactOnly = COLBOOLEAN
			from	SITECONTROL
			where	CONTROLID = 'Main Contact used as Attention' 

			If @nMainContactOnly = 1
			   or not exists (	select	1
						from	ASSOCIATEDNAME
						where	NAMENO=@pnMainNameKey
						and	RELATIONSHIP='EMP'
						and	CEASEDDATE is null )
			Begin
				If @pnAssociatedNameKey is null
				Begin
					Set @sSQLString=
					"Update	CASENAME"+char(10)+
					"set CORRESPONDNAME=case when(AN.CONTACT is not null) then AN.CONTACT"+char(10)+
					"			 else "

					If @pnNewAttentionKey is not null
						Set @sSQLString=@sSQLString+convert(varchar,@pnNewAttentionKey)
					Else
						Set @sSQLString=@sSQLString+"N.MAINCONTACT"

					Set @sSQLString=@sSQLString+" end"+char(10)+
					"from CASENAME CN"+char(10)+
					"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
					"join NAME N on (N.NAMENO=CN.NAMENO)"+char(10)+
					"left join ASSOCIATEDNAME AN on (AN.NAMENO=CN.INHERITEDNAMENO"+char(10)+
					"				and AN.RELATEDNAME=CN.NAMENO"+char(10)+
					"				and AN.RELATIONSHIP=CN.INHERITEDRELATIONS"+char(10)+
					"				and AN.SEQUENCE=CN.INHERITEDSEQUENCE)"+char(10)+
					"where CN.NAMENO="+convert(varchar,@pnMainNameKey)+char(10)+
					"and CN.DERIVEDCORRNAME=1"+char(10)+
					"and ( CN.NAMETYPE in ('I','A') or convert(bit,NT.COLUMNFLAGS&1)=1 )"
				End
				Else
				Begin
					-- At this point the new attention must be null because of earlier condition,
					-- so just set derived attention to main contact of related associated name.
					Set @sSQLString=
					"Update	CASENAME"+char(10)+
					"set CORRESPONDNAME=N.MAINCONTACT"+char(10)+
					"from CASENAME CN"+char(10)+
					"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
					"join NAME N on (N.NAMENO=CN.NAMENO)"+char(10)+
					"where CN.NAMENO="+convert(varchar,@pnMainNameKey)+char(10)+
					"and CN.DERIVEDCORRNAME=1"+char(10)+
					"and ( CN.NAMETYPE in ('I','A') or convert(bit,NT.COLUMNFLAGS&1)=1 )"+char(10)+
					"and CN.INHERITED=1"+char(10)+
					"and CN.INHERITEDNAMENO="+convert(varchar,@pnAssociatedNameKey)+char(10)+
					"and CN.INHERITEDRELATIONS='"+@psAssociatedRelation+"'"+char(10)+
					"and CN.INHERITEDSEQUENCE="+convert(varchar,isnull(@pnAssociatedSequence,0))
				End
			End
			Else If @pnAssociatedNameKey is null
			Begin
				Set @sSQLString=
				"Update	CASENAME"+char(10)+
				"set CORRESPONDNAME="+char(10)+
				"	case when(AN.CONTACT is not null) then AN.CONTACT"+char(10)+
				"	     when(convert(bit,NT.COLUMNFLAGS&1)=0 and CN.NAMETYPE not in ('I','A')) then null"+char(10)+
				"	     when(CN.NAMETYPE in ('D','Z')) then ("+char(10)+
				"		    select	isnull( A.CONTACT, N.MAINCONTACT )"+char(10)+
				"		    from NAME N"+char(10)+
				"		    left join ASSOCIATEDNAME A on ( A.NAMENO = N.NAMENO"+char(10)+
				"					and A.RELATIONSHIP = 'BIL'"+char(10)+
				"					and A.CEASEDDATE is null"+char(10)+
				"					and A.NAMENO = A.RELATEDNAME )"+char(10)+
				"		    where N.NAMENO="+convert(varchar,@pnMainNameKey)+")"+char(10)+
				"	     else(select"+char(10)+
				"		convert(int,substring(min("+char(10)+
				"		   case when(A.PROPERTYTYPE is not null) then '0' else '1' end+"+char(10)+
				"		   case when(A.COUNTRYCODE is not null) then '0' else '1' end+"+char(10)+
				"		   case when(A.RELATEDNAME = N.MAINCONTACT) then '0' else '1' end+"+char(10)+
				"		   replicate('0',6-datalength(convert(varchar(6),A.SEQUENCE)))+"+char(10)+
				"		   convert(varchar(6),A.SEQUENCE)+"+char(10)+
				"		   convert(varchar,A.RELATEDNAME)),10,20))"+char(10)+
				"		from CASES C"+char(10)+
				"		join NAME N on (N.NAMENO=CN.NAMENO)"+char(10)+
				"		join ASSOCIATEDNAME A on (A.NAMENO=N.NAMENO"+char(10)+
				"			and A.RELATIONSHIP='EMP'"+char(10)+
				"			and A.CEASEDDATE is null"+char(10)+
				"			and (A.PROPERTYTYPE is not null or A.COUNTRYCODE is not null or A.RELATEDNAME = N.MAINCONTACT )"+char(10)+
				"			and (A.PROPERTYTYPE=C.PROPERTYTYPE or A.PROPERTYTYPE is null)"+char(10)+
				"			and (A.COUNTRYCODE=C.COUNTRYCODE or A.COUNTRYCODE is null))"+char(10)+
				"		where C.CASEID=CN.CASEID) end"+char(10)+
				"from CASENAME CN"+char(10)+
				"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
				"left join ASSOCIATEDNAME AN on (AN.NAMENO=CN.INHERITEDNAMENO"+char(10)+
				"				and AN.RELATEDNAME=CN.NAMENO"+char(10)+
				"				and AN.RELATIONSHIP=CN.INHERITEDRELATIONS"+char(10)+
				"				and AN.SEQUENCE=CN.INHERITEDSEQUENCE)"+char(10)+
				"where CN.NAMENO="+convert(varchar,@pnMainNameKey)+char(10)+
				"and CN.DERIVEDCORRNAME=1"
			End
			Else
			Begin
				-- At this point the new attention must be null because of earlier condition,
				-- so set derive attention for related associated name.
				Set @sSQLString=
				"Update	CASENAME"+char(10)+
				"set CORRESPONDNAME="+char(10)+
				"	case when(convert(bit,NT.COLUMNFLAGS&1)=0 and CN.NAMETYPE not in ('I','A')) then null"+char(10)+
				"	     when(CN.NAMETYPE in ('D','Z')) then ("+char(10)+
				"		    select	isnull( A.CONTACT, N.MAINCONTACT )"+char(10)+
				"		    from NAME N"+char(10)+
				"		    left join ASSOCIATEDNAME A on ( A.NAMENO = N.NAMENO"+char(10)+
				"					and A.RELATIONSHIP = 'BIL'"+char(10)+
				"					and A.CEASEDDATE is null"+char(10)+
				"					and A.NAMENO = A.RELATEDNAME )"+char(10)+
				"		    where N.NAMENO="+convert(varchar,@pnMainNameKey)+")"+char(10)+			
				"	     else(select convert(int,substring(min("+char(10)+
				"			case when(A.PROPERTYTYPE is not null) then '0' else '1' end+"+char(10)+
				"			case when(A.COUNTRYCODE is not null) then '0' else '1' end+"+char(10)+
				"			case when(A.RELATEDNAME = N.MAINCONTACT) then '0' else '1' end+"+char(10)+
				"			replicate('0',6-datalength(convert(varchar(6),A.SEQUENCE)))+"+char(10)+
				"			convert(varchar(6),A.SEQUENCE)+"+char(10)+
				"			convert(varchar,A.RELATEDNAME)),10,20))"+char(10)+
				"	from CASES C"+char(10)+
				"	join NAME N on (N.NAMENO=CN.NAMENO)"+char(10)+
				"	join ASSOCIATEDNAME A on (A.NAMENO=N.NAMENO"+char(10)+
				"			and A.RELATIONSHIP='EMP'"+char(10)+
				"			and A.CEASEDDATE is null"+char(10)+
				"			and (A.PROPERTYTYPE is not null or A.COUNTRYCODE is not null or A.RELATEDNAME = N.MAINCONTACT )"+char(10)+
				"			and (A.PROPERTYTYPE=C.PROPERTYTYPE or A.PROPERTYTYPE is null)"+char(10)+
				"			and (A.COUNTRYCODE=C.COUNTRYCODE or A.COUNTRYCODE is null))"+char(10)+
				"	where C.CASEID=CN.CASEID) end"+char(10)+
				"from CASENAME CN"+char(10)+
				"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
				"where CN.NAMENO="+convert(varchar,@pnMainNameKey)+char(10)+
				"and CN.DERIVEDCORRNAME=1"+char(10)+
				"and CN.INHERITED=1"+char(10)+
				"and CN.INHERITEDNAMENO="+convert(varchar,@pnAssociatedNameKey)+char(10)+
				"and CN.INHERITEDRELATIONS='"+@psAssociatedRelation+"'"+char(10)+
				"and CN.INHERITEDSEQUENCE="+convert(varchar,isnull(@pnAssociatedSequence,0))
			End
		End

		Exec(@sSQLString)

		Select	@nErrorCode=@@Error,
			@nRowCount=@@Rowcount
	End

	-- Select count of CaseName records updated if called from Centura
	If @nErrorCode = 0 and @pbCalledFromCentura = 1
		Select @nRowCount

	Return @nErrorCode
End
go

Grant execute on dbo.cs_RecalculateDerivedAttention to public
go
