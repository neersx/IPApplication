-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListAssociatedNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListAssociatedNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListAssociatedNames'
	drop procedure [dbo].[wa_ListAssociatedNames]
	print '**** Creating procedure dbo.wa_ListAssociatedNames...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListAssociatedNames]
			@pnNameNo	int

-- PROCEDURE :	wa_ListAssociatedNames
-- VERSION :	2.2.0
-- DESCRIPTION:	Display the Names associated with the name whose NameNo is passed
--		as a parameter.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 24/07/2001	MF	Procedure created	
-- 24/07/2001	AF	Provide row titles
-- 03/08/2001	MF	Check if the user has access to this Name.
as 
	-- set server options
	set NOCOUNT on
	SET CONCAT_NULL_YIELDS_NULL off

	-- declare variables
	declare	@ErrorCode	int

	-- Check if the user is allowed to see the details of the Name.
	Execute @ErrorCode=wa_CheckSecurityForName @pnNameNo

	if @ErrorCode=0
	Begin
		SELECT	R.RELATIONDESCR, 
			ASSOCIATEDNAME = N.NAME+	CASE WHEN (N.TITLE IS NOT NULL or N.FIRSTNAME IS NOT NULL) THEN ', ' ELSE NULL END  +
				CASE WHEN  N.TITLE IS NOT NULL THEN N.TITLE + ' ' ELSE NULL END  +
				CASE WHEN  N.FIRSTNAME IS NOT NULL THEN N.FIRSTNAME ELSE NULL END, 
			ASSOCIATEDNAMENO = N.NAMENO,
	
			CONTACTNAME = C.NAME+	CASE WHEN (C.TITLE IS NOT NULL or C.FIRSTNAME IS NOT NULL) THEN ', ' ELSE NULL END  +
				CASE WHEN  C.TITLE IS NOT NULL THEN C.TITLE + ' ' ELSE NULL END  +
				CASE WHEN  C.FIRSTNAME IS NOT NULL THEN C.FIRSTNAME ELSE NULL END, 
			CONTACTNAMENO = C.NAMENO,
			
			A.POSITION,
		
			PHONE = CASE WHEN T.ISD IS NOT NULL THEN T.ISD + ' ' ELSE NULL END  +
			CASE WHEN T.AREACODE IS NOT NULL THEN T.AREACODE  + ' ' ELSE NULL END +
			T.TELECOMNUMBER +
			CASE WHEN T.EXTENSION IS NOT NULL THEN ' x' + T.EXTENSION ELSE NULL END,
	
			FAX = CASE WHEN F.ISD IS NOT NULL THEN F.ISD + ' ' ELSE NULL END  +
			CASE WHEN F.AREACODE IS NOT NULL THEN F.AREACODE  + ' ' ELSE NULL END +
			F.TELECOMNUMBER +
			CASE WHEN F.EXTENSION IS NOT NULL THEN ' x' + F.EXTENSION ELSE NULL END, 
			
			EMAIL = E.TELECOMNUMBER
			
		FROM    ASSOCIATEDNAME A
		     join NAMERELATION R	on (R.RELATIONSHIP=A.RELATIONSHIP)
		     join NAME N		on (N.NAMENO=A.RELATEDNAME)
			left join NAME C 		on (C.NAMENO=A.CONTACT)
			
			left join TELECOMMUNICATION T 	on (T.TELECODE= isnull(A.TELEPHONE, isnull(C.MAINPHONE, N.MAINPHONE)) )
			left join TELECOMMUNICATION F	on (F.TELECODE= isnull(A.FAX,       isnull(C.FAX,       N.FAX      )) )
			left join TELECOMMUNICATION E	on (E.TELECODE=(select min(E1.TELECODE)
									    from NAMETELECOM NT1
									    join TELECOMMUNICATION E1 on (E1.TELECODE=NT1.TELECODE
												      and E1.TELECOMTYPE=1903)
									    where NT1.NAMENO=isnull(C.NAMENO, N.NAMENO) ))
		WHERE   A.NAMENO = @pnNameNo
			AND    (A.CEASEDDATE is null or A.CEASEDDATE>getdate())
			AND     R.USEDBYNAMETYPE  IN (4, 5, 6, 7 )
			AND		exists (select 0 from USERS
					where USERID = user
					AND (EXTERNALUSERFLAG < 2 or EXTERNALUSERFLAG is null ))
		ORDER BY 1,2,3
		
		Select @ErrorCode=@@Error
	End

return @ErrorCode

go

grant execute on [dbo].[wa_ListAssociatedNames] to public
go
