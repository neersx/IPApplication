----------------------------------------------------------------------------------------------
-- Creation of dbo.na_ListAssociatedNames
----------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListAssociatedNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_ListAssociatedNames.'
	drop procedure [dbo].[na_ListAssociatedNames]
	print '**** Creating Stored Procedure dbo.na_ListAssociatedNames...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.na_ListAssociatedNames
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnNameNo			int
)
-- PROCEDURE :	na_ListAssociatedNames
-- VERSION :	13
-- DESCRIPTON:	Populate the AssociatedName table in the NameDetails typed dataset.
-- CALLED BY :	

-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18/06/2002	SF			Procedure created
-- 10/07/2002	SF			Wrong relationship.  work backward.
-- 01/08/2002	SF			Reverse Relation is unioned.
-- 21/08/2002	SF			use fn_FormatName instead of ipfn_FormatName
-- 25/02/2004	TM	RFC867	9	Modify the logic extracting the 'Email' column to use new Name.MainEmail column.
-- 26/02/2004	TM	RFC867	10	Bring back the email address (if any) for the first non-null name instead of the
--					first non-null email address.
-- 26/02/2004	TM	RFC867	11	Bring back first non-null email address instead of the the email address 
--					for the first non-null name.
-- 15 Apr 2013	DV	R13270	12	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	13	Adjust formatted names logic (DR-15543).

AS
begin
	-- disable row counts
	set nocount on
	set concat_null_yields_null off

	-- declare variables
	declare	@ErrorCode	int

	select @ErrorCode=0
	
	If @ErrorCode=0
	begin
		select 
		AN.RELATIONSHIP				as 'RelationshipKey',
		NR.RELATIONDESCR			as 'RelationshipDescription',
		Cast(AN.RELATEDNAME 			as varchar(11))	as 'RelatedNameKey',
		dbo.fn_FormatNameUsingNameNo(REL.NAMENO, null) as 'RelatedDisplayName',
		AN.POSITION 				as 'Position',			
		
		CASE WHEN T.ISD IS NOT NULL THEN T.ISD + ' ' ELSE NULL END  +
		CASE WHEN T.AREACODE IS NOT NULL THEN T.AREACODE  + ' ' ELSE NULL END +
		T.TELECOMNUMBER +
		CASE WHEN T.EXTENSION IS NOT NULL THEN ' x' + T.EXTENSION ELSE NULL END as 'Telephone',
	
		CASE WHEN F.ISD IS NOT NULL THEN F.ISD + ' ' ELSE NULL END  +
		CASE WHEN F.AREACODE IS NOT NULL THEN F.AREACODE  + ' ' ELSE NULL END +
		F.TELECOMNUMBER +
		CASE WHEN F.EXTENSION IS NOT NULL THEN ' x' + F.EXTENSION ELSE NULL END as 'Fax', 			
		dbo.fn_FormatTelecom(E.TELECOMTYPE, E.ISD, E.AREACODE, E.TELECOMNUMBER, E.EXTENSION) as 'Email'
		from ASSOCIATEDNAME AN
		left join NAMERELATION NR on AN.RELATIONSHIP = NR.RELATIONSHIP
		left join NAME REL on AN.RELATEDNAME = REL.NAMENO
		left join COUNTRY C on AN.COUNTRYCODE = C.COUNTRYCODE
		left join NAME CONTACT on AN.CONTACT = CONTACT.NAMENO
		join NAME N			on (N.NAMENO=AN.RELATEDNAME)
		left join TELECOMMUNICATION T 	on (T.TELECODE= isnull(AN.TELEPHONE, isnull(CONTACT.MAINPHONE, N.MAINPHONE)) )
		left join TELECOMMUNICATION F	on (F.TELECODE= isnull(AN.FAX,       isnull(CONTACT.FAX,       N.FAX      )) )
		left join TELECOMMUNICATION E	on (E.TELECODE= isnull(CONTACT.MAINEMAIL, N.MAINEMAIL))
		where AN.NAMENO = @pnNameNo
		union
		select 
		AN.RELATIONSHIP				as 'RelationshipKey',
		NR.REVERSEDESCR				as 'RelationshipDescription',
		Cast(AN.NAMENO 			as varchar(11))	as 'RelatedNameKey',
		dbo.fn_FormatNameUsingNameNo(REL.NAMENO, null) as 'RelatedDisplayName',
		AN.POSITION 				as 'Position',			
		
		CASE WHEN T.ISD IS NOT NULL THEN T.ISD + ' ' ELSE NULL END  +
		CASE WHEN T.AREACODE IS NOT NULL THEN T.AREACODE  + ' ' ELSE NULL END +
		T.TELECOMNUMBER +
		CASE WHEN T.EXTENSION IS NOT NULL THEN ' x' + T.EXTENSION ELSE NULL END as 'Telephone',
	
		CASE WHEN F.ISD IS NOT NULL THEN F.ISD + ' ' ELSE NULL END  +
		CASE WHEN F.AREACODE IS NOT NULL THEN F.AREACODE  + ' ' ELSE NULL END +
		F.TELECOMNUMBER +
		CASE WHEN F.EXTENSION IS NOT NULL THEN ' x' + F.EXTENSION ELSE NULL END as 'Fax', 			
		dbo.fn_FormatTelecom(E.TELECOMTYPE, E.ISD, E.AREACODE, E.TELECOMNUMBER, E.EXTENSION) as 'Email'
		from ASSOCIATEDNAME AN
		left join NAMERELATION NR on AN.RELATIONSHIP = NR.RELATIONSHIP
		left join NAME REL on AN.NAMENO = REL.NAMENO
		left join COUNTRY C on AN.COUNTRYCODE = C.COUNTRYCODE
		left join NAME CONTACT on AN.CONTACT = CONTACT.NAMENO
		join NAME N			on (N.NAMENO=AN.NAMENO)
		left join TELECOMMUNICATION T 	on (T.TELECODE= isnull(AN.TELEPHONE, isnull(CONTACT.MAINPHONE, N.MAINPHONE)) )
		left join TELECOMMUNICATION F	on (F.TELECODE= isnull(AN.FAX,       isnull(CONTACT.FAX,       N.FAX      )) )
		left join TELECOMMUNICATION E	on (E.TELECODE= isnull(CONTACT.MAINEMAIL, N.MAINEMAIL))
		where AN.RELATEDNAME = @pnNameNo

	End

	
	RETURN @ErrorCode
end
go

grant execute on dbo.na_ListAssociatedNames to public
go
