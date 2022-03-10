using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Names.NameAliasType
{
    public class NameAliasTypeDbSetup : DbSetup
    {
        public const string NameAliasTypeCode = "!";
        public const string NameAliasTypeCode1 = "@";
        public const string NameAliasDescription = "e2e - AliasType";
        public const string NameAliasTypeToBeAdded = NameAliasDescription + " add";
        public const string NameAliasTypeToBeEdit = NameAliasDescription + " edit";
        public const string NameAliasTypeToBeDuplicate = NameAliasDescription + " duplicate";
        public const string NameCode = "E2E";
        public const string Name = "E2E";

        public ScenarioData Prepare()
        {
            var existingNameAliasType = InsertWithNewId(new InprotechKaizen.Model.Names.NameAliasType
            {
                Code = NameAliasTypeCode,
                Description = NameAliasDescription,
                IsUnique = true
            });

            var name = InsertWithNewId(new Name
            {
                NameCode = NameCode,
                LastName = Name,
                UsedAs = 4
            });

            InsertWithNewId(new NameAlias
            {
                Name = name,
                Alias = "AliasE2E",
                AliasType = existingNameAliasType
            });

            return new ScenarioData
            {
                Code = existingNameAliasType.Code,
                Description = existingNameAliasType.Description,
                IsUnique = existingNameAliasType.IsUnique,
                ExistingNameAliasType = existingNameAliasType,
            };

        }

        public class ScenarioData
        {
            public string Code;
            public string Description;
            public bool? IsUnique;
            public InprotechKaizen.Model.Names.NameAliasType ExistingNameAliasType;

        }
    }
}
