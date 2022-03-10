-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedNameAttentions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedNameAttentions') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetConcatenatedNameAttentions.'
	drop function dbo.fn_GetConcatenatedNameAttentions
	print '**** Creating function dbo.fn_GetConcatenatedNameAttentions...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetConcatenatedNameAttentions
	(
		@pnCaseId		int,
		@psNameType		nvarchar(3),
		@psSeparator		nvarchar(10), 
		@pdtToday		datetime,
		@pnNameStyle		int
	)
Returns nvarchar(max)

-- FUNCTION :	fn_GetConcatenatedNameAttentions
-- VERSION :	1
-- DESCRIPTION:	This function accepts a CaseId and NameType and gets the formatted 
--		attention names and concatenates them with the Separator between each name.

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 05 Jul 2017	MF 	71861	1	Function created

AS
Begin
	-- Get the Item with the lowest value from the delimited string
	Declare @sFormattedNameList	nvarchar(max)

	If @psNameType in ('D','Z')
	Begin
		-------------------------------------------------------------------------------------
		-- Specific logic is required to retrieve the Debtor and Renewal Debtor 
		-- Attention ('D' and 'Z' name types):
		-- 1)	Details recorded on the CaseName table; if no information is found then 
		-- 	step 2 will be performed;
		-- 2)	If the debtor was inherited from the associated name then the details 
		-- 	recorded against this associated name will be returned; if the debtor was not 
		-- 	inherited then go to the step 3;
		-- 3)	Check if the Address/Attention has been overridden on the AssociatedName 
		-- 	table with Relationship = ‘BIL’ and NameNo = RelatedName; if no information
		--	was found then go to the step 4; 
		-- 4)	Extract the Billing Address/Attention details stored against the Name as 
		--	the PostalAddress and MainContact.
		-------------------------------------------------------------------------------------	
		Select @sFormattedNameList= CASE WHEN(@sFormattedNameList is not null) THEN @sFormattedNameList+@psSeparator ELSE '' END+
						dbo.fn_FormatNameUsingNameNo(N.NAMENO, @pnNameStyle)
		From CASENAME CN
		join NAME N1		     on ( N1.NAMENO      =CN.NAMENO)
		left join ASSOCIATEDNAME AN1 on (AN1.NAMENO      =CN.INHERITEDNAMENO
		                             and AN1.RELATIONSHIP=CN.INHERITEDRELATIONS
					     and AN1.RELATEDNAME =CN.NAMENO
					     and AN1.SEQUENCE    =CN.INHERITEDSEQUENCE)
		left join ASSOCIATEDNAME AN2 on (AN2.NAMENO      =CN.NAMENO
		                             and AN2.RELATIONSHIP='BIL'
					     and AN2.RELATEDNAME =AN2.NAMENO
					     and AN1.NAMENO is null)
		Join NAME N		     on (  N.NAMENO=COALESCE(CN.CORRESPONDNAME,AN1.CONTACT,AN2.CONTACT,N1.MAINCONTACT))
		Where CN.CASEID  =@pnCaseId
		and   CN.NAMETYPE=@psNameType
		and  (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>@pdtToday)
		order by CN.SEQUENCE, CN.NAMENO
	End
	Else Begin
		Select @sFormattedNameList= CASE WHEN(@sFormattedNameList is not null) THEN @sFormattedNameList+@psSeparator ELSE '' END+
						dbo.fn_FormatNameUsingNameNo(N.NAMENO, @pnNameStyle)
		From CASENAME CN
		join NAME N1 on (N1.NAMENO=CN.NAMENO)
		join NAME N  on ( N.NAMENO=COALESCE(CN.CORRESPONDNAME,N1.MAINCONTACT))
		Where CN.CASEID  =@pnCaseId
		and   CN.NAMETYPE=@psNameType
		and  (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>@pdtToday)
		order by CN.SEQUENCE, CN.NAMENO
	End

Return @sFormattedNameList
End
go

grant execute on dbo.fn_GetConcatenatedNameAttentions to public
GO
