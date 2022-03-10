using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ImportanceLevel
{
    class ImportanceLevelDbSetup : DbSetup
    {
        public const string ImportanceLevelDescription = "e2e - importance level";
        public const string ImportanceLevelToBeAdded = ImportanceLevelDescription + " add";
        public const string ImportanceLevelToBeEdit = ImportanceLevelDescription + " edit";
        public const string ImportanceLevelToBeDelete = ImportanceLevelDescription + "delete";
        public ScenarioData Prepare()
        {
            var importanceLevels = ImportanceLevels();
            
            return new ScenarioData
            {
                ImportanceLevels = importanceLevels
            };
        }
        public class ScenarioData
        {
            public dynamic ImportanceLevels { get; set; }
        }

        dynamic ImportanceLevels()
        {
            var importanceLevel1 = InsertWithNewId(new Importance {Description = ImportanceLevelDescription});
            var importanceLevel2 = InsertWithNewId(new Importance {Description = ImportanceLevelToBeDelete});

            return new
            {
                importanceLevel1,
                importanceLevel2
            };
        }
    }
}
