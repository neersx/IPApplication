set QUOTED_IDENTIFIER OFF

--	1. Apply procedure util_GenerateMappingRules to the database.
--	2. Set your query analyser output to text.
--	3. Set the value of @ptXMLRules to your prepared XML rules.
--	4. Run.
--	5. Copy output into new window and tidy up formatting as necessary.
--	6. Save as script.

exec util_GenerateMappingRules
@pnUserIdentityId = 5,
@ptXMLRules=
"
<Rules>
	<ChangeReference>RFCxxx</ChangeReference>
	<Comment>Description of script</Comment>
	<!-- Last MAPPING.MAPPING used -->
	<LastMappingKey>0</LastMappingKey>
	<Mapping>
		<StructureID>4</StructureID> <!-- MAPSTRUCTURE.STRUCTUREID -->
		<DataSourceCode>USPTO/PAIR</DataSourceCode> <!-- The code of the source system EXTERNALSYSTEM.SYSTEMCODE -->
		<InputCode></InputCode>
		<InputDescription></InputDescription>
		<InputEncoded>
			<SchemeCode>wipo</SchemeCode> <!-- ENCODINGSCHEME.SCHEMECODE -->
			<Code>AU</Code> <!-- The Code of the item as it appears in the encoded value list -->
		</InputEncoded>
		<OutputEncoded>
			<SchemeCode>cpainpro</SchemeCode> <!-- ENCODINGSCHEME.SCHEMECODE -->
			<Code>AU</Code> <!-- The Code of the item as it appears in the encoded value list -->
		</OutputEncoded>
		<OutputValue></OutputValue>
		<IsNotApplicable></IsNotApplicable> <!-- Defaults to 0 -->
	</Mapping>
</Rules>
"

