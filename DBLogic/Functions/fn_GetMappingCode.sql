if exists (select * from sysobjects where id = object_id('dbo.fn_GetMappingCode') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetMappingCode'
	Drop function [dbo].[fn_GetMappingCode]
End
Print '**** Creating Function dbo.fn_GetMappingCode...'
Print ''
GO



SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  FUNCTION dbo.fn_GetMappingCode
(
		@pnInputSchemeId	 int,
		@pnOutputSchemeId	 int,
		@psMapStructureTableName nvarchar(30),
		@psInputCode		 nvarchar(50),
		@pnDataSourceId		 int		= -4	-- Key describing the source of a raw data that has been mapped.  Default to EDE data source.
)
RETURNS nvarchar(50)
AS
-- FUNCTION: 	fn_GetMappingCode
-- VERSION:  	5
-- SCOPE:    	Inprotech client server
-- DESCRIPTION: This function maps a code from one scheme to another.  If
--		no mapping is defined returns NULL.  Only support mapping translation between 
--		CPAXML and CPAINPRO.
--		For example: 1)Inprotech name type 'I' is mapped CPAXML 'Client' 
--			      select dbo.fn_GetMappingCode(-1, -3, 'NAMETYPE', 'I', DEFAULT)
--			OR   
--			     2) CPAXML 'Client' is mapped to CPAINPRO 'I' (Instructor)
--			      dbo.fn_GetMappingCode(-3, -1, 'NAMETYPE', 'Client', DEFAULT)
--
-- PARAMENTERS:
--		@pnInputSchemeId	 Input schema id. eg. CPAXML or CPAINPRO schema id (ENCODINGSCHEME.SCHEMEID)
--		@pnOutputSchemeId	 Output schema id
--		@psMapStructureTableName Table name. eg. NAMETYPE, EVENT…(MAPSTRUCTURE.TABLENAME)
--		@psInputCode		 Code to be converted. e.g. ‘DATA INSTRUCTOR’ (ENCODEDVALUE.CODE)
--
-- CALLED BY :	Used in stored procedure that generates CEF, Portfolio fiels in CPAXML format.  
-- COPYRIGHT :	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date  		Who 	 SQA#	        Version 	Change
-- ------------	-------  ------- 	----------      ------------------------------------------------- 
-- 30-Nov-2006  DL 			1 		Function created
-- 18-Apr-2007  DL			2		Handle raw mapping for 'Electronic Data Exchange'
-- 02-May-2007	DL			3		raw mapping overide standard mappings for Inpro to CPAXML
-- 08-Sep-2015  MS       R51336         4               Use table variable instead of union and interchange joins to improve performance
-- 29-Jul-2019	DL		DR-50608		5				Extend logic to derive mapping for a specific datasource			

Begin

   Declare	@sMappedValue 		nvarchar(50),
		@nErrorCode 		int,
		@nCPAXMLSchemeId	int,
		@nCPAINPROSchemeId	int,
		@nDataSourceId int

   Declare  @temp table (
        MAPPEDCODE nvarchar(50) null, 
        SEQ int null) 

   Set @nErrorCode = 0

   -- Ensure the specified data source parameter is invalid, otherwise default it to EDE data source
	If not exists( select 1 from DATASOURCE where DATASOURCEID = @pnDataSourceId )
		select @nDataSourceId = -4
	else
		select @nDataSourceId = isnull(@pnDataSourceId, -4)

   -- Get CPAXML SCHEME ID
   If @nErrorCode = 0
   Begin  
		Select @nCPAXMLSchemeId = SCHEMEID 
		from ENCODINGSCHEME 
		where SCHEMECODE = 'CPAXML'
	
		Set @nErrorCode = @@error
   End

   -- Get CPAINPRO SCHEME ID
   If @nErrorCode = 0
   Begin  
		Select @nCPAINPROSchemeId = SCHEMEID 
		from ENCODINGSCHEME 
		where SCHEMECODE = 'CPAINPRO'
	
		Set @nErrorCode = @@error
   End


   -- Find mapping from CPAINPRO to CPAXML
   -- Raw mapping will override the standard mapping
   If @nErrorCode = 0 and @pnInputSchemeId = @nCPAINPROSchemeId and @pnOutputSchemeId = @nCPAXMLSchemeId
   Begin
		-- CPAXML code mapped to Inpro
                insert into @temp(MAPPEDCODE, SEQ)
                Select EV.OUTBOUNDVALUE as MAPPEDCODE, 2 SEQ
				from MAPSTRUCTURE MS
				 join MAPPING M on (M.STRUCTUREID = MS.STRUCTUREID
						   and M.DATASOURCEID is null
						   and M.ISNOTAPPLICABLE = 0 
							and M.OUTPUTVALUE = @psInputCode )
				 join ENCODEDVALUE EV on (EV.STRUCTUREID = MS.STRUCTUREID
							and EV.SCHEMEID = @pnOutputSchemeId
							and EV.CODEID = M.INPUTCODEID) 
				where MS.TABLENAME = @psMapStructureTableName
                                
                -- CPAXML code mapped to standard value
                insert into @temp(MAPPEDCODE, SEQ)     
                Select EV1.OUTBOUNDVALUE as MAPPEDCODE, 2  SEQ 
				from MAPPING M
				join ENCODEDVALUE EV1 on (EV1.SCHEMEID = @pnOutputSchemeId
							and EV1.CODEID = M.INPUTCODEID)
                                join MAPSTRUCTURE MS on (M.STRUCTUREID = MS.STRUCTUREID                                                         
                                                        and EV1.STRUCTUREID = MS.STRUCTUREID
                                                        and MS.TABLENAME = @psMapStructureTableName)
				where M.DATASOURCEID is null
                                        and M.ISNOTAPPLICABLE = 0 
                                        and M.OUTPUTCODEID in ( Select M1.INPUTCODEID 
                                                                from MAPPING M1 
                                                                where M1.DATASOURCEID is null 
                                                                        and M1.ISNOTAPPLICABLE = 0 
                                                                        and M1.STRUCTUREID = MS.STRUCTUREID 
                                                                        and M1.OUTPUTVALUE = @psInputCode)

                -- Raw mapping overrides standard mapping
		-- Raw mapping for 'Electronic Data Exchange' to your system
                insert into @temp(MAPPEDCODE, SEQ)  
		Select isnull(M.INPUTCODE, M.INPUTDESCRIPTION), 1
				from MAPSTRUCTURE MS
				join MAPPING M on (M.STRUCTUREID = MS.STRUCTUREID
					   	and M.DATASOURCEID = @nDataSourceId 
					   	and M.ISNOTAPPLICABLE = 0
							and M.OUTPUTVALUE = @psInputCode )
				where MS.TABLENAME = @psMapStructureTableName

                -- Raw mapping for 'Electronic Data Exchange' to standard encoded value.
                insert into @temp(MAPPEDCODE, SEQ)                
		Select isnull(M.INPUTCODE, M.INPUTDESCRIPTION), 1 
                                from MAPPING M 
                                join MAPSTRUCTURE MS on (M.STRUCTUREID = MS.STRUCTUREID 
                                                and MS.TABLENAME = @psMapStructureTableName)
                                where M.DATASOURCEID = @nDataSourceId 
                                        and M.ISNOTAPPLICABLE = 0
                                        and M.OUTPUTCODEID in ( Select M1.INPUTCODEID 
                                                                from  MAPPING M1 
                                                                where M1.DATASOURCEID is null
                                                                        and M1.ISNOTAPPLICABLE = 0 
                                                                        and M1.STRUCTUREID = MS.STRUCTUREID				                                        
				                                        and M1.OUTPUTVALUE = @psInputCode)

		Select top 1 @sMappedValue =  MAPPEDCODE 
		From
		(                
		    Select distinct MAPPEDCODE, SEQ from @temp    
		) Temp
		Order by SEQ

		Set @nErrorCode = @@error
	
		Return @sMappedValue
   End

   -- Find mapping from CPAXML to CPAINPRO
   If @nErrorCode = 0 and @pnInputSchemeId = @nCPAXMLSchemeId and @pnOutputSchemeId = @nCPAINPROSchemeId
   Begin
		Select @sMappedValue = isnull( E1.CODE, isnull( M2.OUTPUTVALUE, M3.OUTPUTVALUE))
		from MAPSTRUCTURE MS
		left join ENCODEDVALUE E on (E.STRUCTUREID = MS.STRUCTUREID
							and E.SCHEMEID = @pnInputSchemeId
						   -- E.OUTBOUNDVALUE value is CPAXML mixed cases (E.CODE all upper case). 
							and E.OUTBOUNDVALUE = @psInputCode)
		left join MAPPING M on (M.INPUTCODEID = E.CODEID
				   and M.STRUCTUREID = E.STRUCTUREID)
		left join ENCODEDVALUE E1 on  (E1.CODEID = M.OUTPUTCODEID
					 and E1.STRUCTUREID = M.STRUCTUREID 
					 and E1.SCHEMEID = @pnOutputSchemeId )
		-- raw mapping for 'Electronic Data Exchange' (direct mapping to Inpro)
		left join MAPPING M2 on (M2.STRUCTUREID = MS.STRUCTUREID
			   	and M2.DATASOURCEID = @nDataSourceId 
			   	and M2.ISNOTAPPLICABLE = 0
					and M2.INPUTCODE = @psInputCode )
		-- raw mapping for 'Electronic Data Exchange' (mapping via CPAXML Standard)
		left join MAPPING M3 on (M3.STRUCTUREID = MS.STRUCTUREID
			   	and M3.DATASOURCEID is null
			   	and M3.ISNOTAPPLICABLE = 0
					and M3.INPUTCODEID = M2.OUTPUTCODEID )

		where  MS.TABLENAME = @psMapStructureTableName
		


		Set @nErrorCode = @@error
	
		Return @sMappedValue 
   End	


   Return @sMappedValue 

End

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


grant execute on dbo.fn_GetMappingCode to public
go

