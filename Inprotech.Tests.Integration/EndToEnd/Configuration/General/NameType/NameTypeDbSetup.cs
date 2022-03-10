using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.NameType
{
    class NameTypeDbSetup : DbSetup
    {
        public const string NameTypeCode = "!";
        public const string NameTypeCode1 = "@";
        public const string NameTypeDescription = "e2e - nametypes";
        public const string NameTypeToBeAdded = NameTypeDescription + " add";
        public const string NameTypeToBeEdit = NameTypeDescription + " edit";
        public const string NameTypeToBeDuplicate = NameTypeDescription + " duplicate";

        public ScenarioData Prepare()
        {
            var existingNameType = InsertWithNewId(new InprotechKaizen.Model.Cases.NameType
            {
                Name = NameTypeDescription,
                NationalityFlag = Fixture.Boolean()
            });

            return new ScenarioData
            {
                Code = existingNameType.NameTypeCode,
                Name = existingNameType.Name,
                ExistingApplicationNameType = existingNameType
            };
        }

        public class ScenarioData
        {
            public string Code;
            public string Name;
            public InprotechKaizen.Model.Cases.NameType ExistingApplicationNameType;
        }
    }
}
