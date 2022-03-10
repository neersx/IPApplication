set QUOTED_IDENTIFIER OFF

--	This script generates template XML to be passed to the 
--	stored procedure/business entity code generators.

--	1. Apply procedure util_GenerateSPRulesXML to the database.
--	2. Set your query analyser output to text.
--	3. Set the parameters to the required values.
--	4. Run.
--	5. Copy output and fill out the missing tags.
--	   5.1 The following are required by the stored procedure generator.
--			<PropertyName>
--			<FetchCriteria>
--             The remainder are required by the business entity generator.
--	6. Pass to Run util_GenerateProcedureTemplates.


exec util_GenerateSPRulesXML
	@psTableName 	= 'CASES', 	-- The name of the database table
	@psInternalName	= 'Case', 	-- The version of the entity name to use when naming the stored procedures
	@psPrefix 	= 'csw' 	-- The prefix to be used for the stored procedures
