-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListCaseGoods
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListCaseGoods]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListCaseGoods'
	drop procedure [dbo].[wa_ListCaseGoods]
	print '**** Creating procedure dbo.wa_ListCaseGoods...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListCaseGoods]
	@pnCaseId 	int
AS
-- PROCEDURE :	wa_ListCaseGoods
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns a list of Goods & Services text for a given Case passed as a parameter.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 01/07/2001	MF		Procedure created
-- 03/08/2001	MF		Only display details if the user has the correct access rights
-- 10/01/2002	MF	SQA7313	Modify the SELECT to cater for rows where MODIFIEDDATE is NULL

begin
	-- disable row counts
	set nocount on
	
	declare @ErrorCode	int

	-- Check that external users have access to see the details of the case.

	Execute @ErrorCode=wa_CheckSecurityForCase @pnCaseId

	If @ErrorCode=0
	Begin
	
		select	DESCRIPTION = TT.TEXTDESCRIPTION + CASE	
						WHEN (select COUNT(CT.CASEID)
							from	CASETEXT CT
							join	TEXTTYPE TT
							on	CT.TEXTTYPE = TT.TEXTTYPE
							where	CT.TEXTTYPE = 'G'
							and	CT.CASEID = @pnCaseId) > 1
						 THEN ' (' + CT.CLASS + ')'
						ELSE ''
						END,
			TEXT = 	CASE	
					WHEN CT.TEXT IS NULL THEN CT.SHORTTEXT
					WHEN CT.TEXT LIKE '' THEN CT.SHORTTEXT	/* cater for crappy data */			
					ELSE CT.TEXT
				END
		from	CASETEXT CT
		join	TEXTTYPE TT
			on	CT.TEXTTYPE 	= TT.TEXTTYPE
		where	CT.TEXTTYPE = 'G'
		and	CT.CASEID = @pnCaseId
	   	and    (CT.MODIFIEDDATE = (select max(MODIFIEDDATE) from CASETEXT CT1
	                                    where CT1.CASEID=CT.CASEID
	                                    and   CT1.TEXTTYPE=CT.TEXTTYPE
					    and   CT1.MODIFIEDDATE is not null
	                                    and  (CT1.CLASS=CT.CLASS or
						 (CT.CLASS is null and CT1.CLASS is NULL))
	                                    and  (CT1.LANGUAGE=CT.LANGUAGE or
					 	 (CT.LANGUAGE is null and CT1.LANGUAGE is null)))
		 OR	CT.MODIFIEDDATE is NULL
		 and	not exists (	Select * from CASETEXT CT2
					where CT2.CASEID  =CT.CASEID
					and   CT2.TEXTTYPE=CT.TEXTTYPE
					and   CT2.MODIFIEDDATE is not null
					and  (CT2.CLASS   =CT.CLASS or
					     (CT2.CLASS is null and CT.CLASS is NULL))
					and  (CT2.LANGUAGE=CT.LANGUAGE or
					     (CT2.LANGUAGE is null and CT.LANGUAGE is null))))
		ORDER BY  TT.TEXTDESCRIPTION, CLASS, CT.LANGUAGE
	
		set @ErrorCode=@@Error
	End

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_ListCaseGoods] to public
go
