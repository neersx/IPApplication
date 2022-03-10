using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Locality
{
    class LocalityDbSetUp : DbSetup
    {
        public const string LocalityCode = "E2E";
        public const string LocalityCode1 = "E3E";
        public const string NameCode = "E2E";
        public const string Name = "E2E";

        public ScenarioData Prepare()
        {
            var existingLocality = InsertWithNewId(new InprotechKaizen.Model.Names.Locality
            {
                Code = LocalityCode,
                Name = string.Empty
            });

            var existingLocality1 = InsertWithNewId(new InprotechKaizen.Model.Names.Locality
            {
                Code = LocalityCode1,
                Name = string.Empty
            });

            var name = InsertWithNewId(new Name
            {
                NameCode = NameCode,
                LastName = Name,
                UsedAs = 4
            });

            InsertWithNewId(new ClientDetail(name.Id, name)
            {
                AirportCode = existingLocality.Code
            });

            return new ScenarioData
            {
                ExistingLocalityCode1 = existingLocality.Code,
                ExistingLocalityCode2 = existingLocality1.Code
            };
        }

        public class ScenarioData
        {
            public string ExistingLocalityCode1;
            public string ExistingLocalityCode2;
        }
    }
}
