set QUOTED_IDENTIFIER OFF

--	1. Apply procedure util_GenerateObjectRules to the database.
--	2. Set your query analyser output to text.
--	3. Set the value of @ptXMLRules to your prepared XML rules.
--	4. Run.
--	5. Copy output into new window and tidy up formatting as necessary.
--	6. Save as script.

exec util_GenerateObjectRules
@pnUserIdentityId = 5,
@ptXMLRules=
"
<!-- Rules for the creation of scripting to populate web part,
	 task and subject meta data database tables.
	 For use with the util_GenerateObjectRules stored procedure. -->
<Rules>
	<ChangeReference>RFCxxx</ChangeReference>
	<Comment>Description of script</Comment>
	<!-- Last Object.ObjectID used -->
	<!-- Necessary if any LicensedModules are to be created. -->
	<LastObjectKey></LastObjectKey>
	<!-- Fill in to create a new Feature Category -->
	<FeatureCategory>
		<Key></Key> <!-- Next number beginning with 98xx -->
		<Name></Name>
	</FeatureCategory>
	<!-- Fill in to create a new Feature -->
	<Feature>
		<Key></Key>
		<Name></Name>
		<CategoryKey></CategoryKey> <!-- Defaults to FeatureCategory.Key above if not supplied. -->
		<IsInternal></IsInternal> <!-- Defaults to 0 -->
		<IsExternal></IsExternal> <!-- Defaults to 0 -->
	</Feature>
	<!-- Fill in to create a new Web Part -->
	<Module>
		<!-- Create a module definition if there isn't one available -->
		<Definition>
			<ModuleDefID></ModuleDefID> <!-- Next available ModuleDefinition.ModuleDefID -->
			<Name></Name>				<!-- Internal label -->
			<DeskTopSrc></DeskTopSrc>
			<MobileSrc></MobileSrc>
		</Definition>
		<!-- Create the web part -->
		<WebPart>
			<Key></Key> <!-- Next available Module.ModuleID -->
			<ModuleDefID></ModuleDefID> <!-- Defaults to Definition above -->
			<Title></Title>
			<Description></Description>
			<CacheTime></CacheTime>		<!-- Defaults to 0 -->
		</WebPart>
		<!-- For example RowsPerPage. -->
		<PortalSetting>
			<SettingName></SettingName>
			<SettingValue></SettingValue> <!-- This is formatted as <Value></Value> only -->
		</PortalSetting>
		<!-- Attach the web part to one or more Feature(s) -->
		<Feature>
			<FeatureKey></FeatureKey>	<!-- The feature the object is attached to -->
		</Feature>
		<!-- Include the web part in one or more LicenseModule(s) -->
		<!-- Timesheet=6,Client=17,Professional=18,Manager=19,
			 Marketing=20,Clerical=21 -->
		<LicensedModule>
			<ModuleKey></ModuleKey>
		</LicensedModule>
		<!-- Grant Permissions to this role. -->
		<!-- -1=Administrator, -20=User, -21=Internal, -22=External -->
		<RolePermissions>
			<RoleKey></RoleKey>
			<GrantSelect></GrantSelect>			<!-- Defaults to 0 -->
			<GrantMandatory></GrantMandatory>	<!-- Defaults to 0 -->
		</RolePermissions>
	</Module>
	<!-- Fill in to create a new Task -->
	<Task>
		<Key></Key> <!-- Next available Task.TaskID -->
		<Name></Name>
		<Description></Description>
		<!-- Attach the task to one or more Feature(s) -->
		<Feature>
			<FeatureKey></FeatureKey> <!-- The feature the object is attached to -->
		</Feature>
		<!-- Attach the task to one or more License Module(s) -->
		<!-- Timesheet=6,Client=17,Professional=18,Manager=19,
			 Marketing=20,Clerical=21 -->
		<LicensedModule>
			<ModuleKey></ModuleKey>
		</LicensedModule>
		<!-- Place 0/1 in appropriate flags -->
		<PermissionDefinition>
			<GrantExecute></GrantExecute>	<!-- Defaults to 0 -->
			<GrantInsert></GrantInsert>		<!-- Defaults to 0 -->
			<GrantUpdate></GrantUpdate>		<!-- Defaults to 0 -->
			<GrantDelete></GrantDelete>		<!-- Defaults to 0 -->
		</PermissionDefinition>
		<!-- Grant Permissions to this role. -->
		<!-- -1=Administrator, -20=User, -21=Internal, -22=External -->
		<RolePermissions>
			<RoleKey></RoleKey>
			<GrantExecute></GrantExecute>	<!-- Defaults to 0 -->
			<GrantInsert></GrantInsert>		<!-- Defaults to 0 -->
			<GrantUpdate></GrantUpdate>		<!-- Defaults to 0 -->
			<GrantDelete></GrantDelete>		<!-- Defaults to 0 -->
		</RolePermissions>
	</Task>
	<!-- Fill in to create a new Subject -->
	<DataTopic>
		<Key></Key> <!-- Next available DataTopic.TopicID -->
		<Name></Name>
		<Description></Description>
		<IsInternal></IsInternal>
		<IsExternal></IsExternal>
		<!-- Attach the subject to one or more License Module(s) -->
		<!-- Timesheet=6,Client=17,Professional=18,Manager=19,
			 Marketing=20,Clerical=21 -->
		<LicensedModule>
			<ModuleKey></ModuleKey>
		</LicensedModule>
		<!-- The prerequisite modules; e.g. AR Items requires AR to be licensed -->
		<!-- See LicenseModule.ModuleID for valid values.
			 For no restriction, use 999. -->
		<PrerequisiteModule>
			<ModuleKey></ModuleKey>
		</PrerequisiteModule>
		<!-- The data items attached to a DATATOPIC -->
		<DataItems>
			<DataItem>
				<ProcedureName></ProcedureName>
				<ProcedureItemID></ProcedureItemID>
			</DataItem>
		</DataItems>
		<!-- Grant Permissions to this role. -->
		<!-- -1=Administrator, -20=User, -21=Internal, -22=External -->
		<RolePermissions>
			<RoleKey></RoleKey>
			<GrantSelect></GrantSelect>
		</RolePermissions>
	</DataTopic>
</Rules>
"

