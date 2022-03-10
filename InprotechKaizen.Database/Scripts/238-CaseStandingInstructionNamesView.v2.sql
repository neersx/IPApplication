-----------------------------------------------------------------------------------------------------------------------------
-- Creation of CASESTANDINGINSTRUCTIONNAMES_VIEW 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CASESTANDINGINSTRUCTIONNAMES_VIEW ]', 'V'))
Begin
	Print '**** Drop View dbo.CASESTANDINGINSTRUCTIONNAMES_VIEW .'
	Drop view [dbo].CASESTANDINGINSTRUCTIONNAMES_VIEW 
End
Print '**** Creating View dbo.CASESTANDINGINSTRUCTIONNAMES_VIEW ...'
Print ''
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.CASESTANDINGINSTRUCTIONNAMES_VIEW 
as
-- VIEW:	CASESTANDINGINSTRUCTIONNAMES_VIEW 
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	view of the current policing queue

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	----	---			------	-------	----------------------------------------------- 
-- 11 Oct 2019	SF		DR-42724	1		Procedure created
-- 07 Feb 2020	SF		SDR-28975	2		Remove ROW_NUMBER() function to improve performace

SELECT  CASEID, NAMETYPE, NAMENO
FROM (
       SELECT CN.CASEID, CN.NAMETYPE, CN.NAMENO
       FROM CASENAME CN
       JOIN ( SELECT CN.CASEID, CN.NAMETYPE, MIN(CN.SEQUENCE) AS SEQUENCE
                     FROM CASENAME CN
                     WHERE (CN.EXPIRYDATE IS NULL OR CN.EXPIRYDATE>GETDATE())
                     AND CN.NAMETYPE IN (
                           SELECT NAMETYPE AS NAMETYPE
                           FROM INSTRUCTIONTYPE
                           WHERE NAMETYPE IS NOT NULL
                           UNION
                           SELECT RESTRICTEDBYTYPE
                           FROM INSTRUCTIONTYPE
                           WHERE RESTRICTEDBYTYPE IS NOT NULL              
                     )
                     GROUP BY CN.CASEID, CN.NAMETYPE) CN1
                     ON (CN1.CASEID=CN.CASEID
                     AND CN1.NAMETYPE=CN.NAMETYPE
                     AND CN1.SEQUENCE=CN.SEQUENCE)) EXISTING
UNION
SELECT C.CASEID, NT.NAMETYPE, ISNULL(O.ORGNAMENO, SC.COLINTEGER)
FROM CASES C
LEFT JOIN OFFICE O ON C.OFFICEID = O.OFFICEID
LEFT JOIN SITECONTROL SC ON SC.CONTROLID = 'HOMENAMENO'
LEFT JOIN (SELECT NAMETYPE AS NAMETYPE
                     FROM INSTRUCTIONTYPE
                     WHERE NAMETYPE IS NOT NULL
                     UNION
                     SELECT RESTRICTEDBYTYPE
                     FROM INSTRUCTIONTYPE
                     WHERE RESTRICTEDBYTYPE IS NOT NULL) NT ON (1=1)
WHERE NOT EXISTS (
              SELECT CASEID, NAMETYPE
              FROM CASENAME
              WHERE (EXPIRYDATE IS NULL OR EXPIRYDATE>GETDATE()) AND NAMETYPE = NT.NAMETYPE AND CASEID = C.CASEID
)
GO

Grant REFERENCES, SELECT on dbo.CASESTANDINGINSTRUCTIONNAMES_VIEW  to public
GO

sp_refreshview 'dbo.CASESTANDINGINSTRUCTIONNAMES_VIEW '
GO