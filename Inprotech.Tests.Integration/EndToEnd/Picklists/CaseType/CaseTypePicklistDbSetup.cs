using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseType
{
    public class CaseTypePicklistDbSetup
    {
        public const string CaseTypePrefix = "e2e - caseType";
        public const string ExistingCaseType = CaseTypePrefix + " existing";
        public const string ExistingCaseType2 = ExistingCaseType + "2";
        public const string ExistingCaseType3 = ExistingCaseType + "3";
        public const string CaseTypeToBeAdded = CaseTypePrefix + " add";
        public const string ImportanceLevel = "Critical";

        public CaseTypePicklistDbSetup()
        {
            DbContext = new SqlDbContext();
        }

        public IDbContext DbContext { get; }

        public ScenarioData Prepare()
        {
            var existingCaseType = AddCaseType("1", ExistingCaseType);
            AddCaseType("2", ExistingCaseType2);
            AddCaseType("3", ExistingCaseType3);

            return new ScenarioData
            {
                CaseTypeId = existingCaseType.Code,
                CaseTypeName = existingCaseType.Name,
                ExistingApplicationCaseType = existingCaseType
            };
        }

        public InprotechKaizen.Model.Cases.CaseType AddCaseType(string id, string name)
        {
            var caseType = DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().FirstOrDefault(_ => _.Name == name);
            if (caseType != null)
                return caseType;

            caseType = new InprotechKaizen.Model.Cases.CaseType(id, name);

            DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().Add(caseType);
            DbContext.SaveChanges();

            return caseType;
        }

        public void AddValidAction(InprotechKaizen.Model.Cases.CaseType caseType)
        {
            var country = DbContext.Set<Country>().FirstOrDefault();
            var propertyType = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().FirstOrDefault();
            var action = DbContext.Set<InprotechKaizen.Model.Cases.Action>().First();
            var validAction = new ValidAction(action.Name, action, country, caseType, propertyType);

            DbContext.Set<ValidAction>().Add(validAction);
            DbContext.SaveChanges();
        }

        public class ScenarioData
        {
            public string CaseTypeId;
            public string CaseTypeName;
            public InprotechKaizen.Model.Cases.CaseType ExistingApplicationCaseType;
        }
    }
}