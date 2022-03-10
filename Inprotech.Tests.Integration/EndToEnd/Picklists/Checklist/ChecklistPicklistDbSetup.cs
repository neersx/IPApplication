using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Checklist
{
    class ChecklistPicklistDbSetup
    {
        public const string ChecklistPrefix = "e2e - checklist";
        public const string ExistingChecklist = ChecklistPrefix + " existing";
        public const string ExistingChecklist2 = ExistingChecklist + "2";
        public const string ExistingChecklist3 = ExistingChecklist + "3";
        public const string ChecklistToBeAdded = ChecklistPrefix + " add";

        public ChecklistPicklistDbSetup()
        {
            DbContext = new SqlDbContext();
        }

        public IDbContext DbContext { get; }

        public ScenarioData Prepare()
        {
            var existingChecklist = AddChecklist(GetMaxChecklistTypeId(), ExistingChecklist);
            AddChecklist(GetMaxChecklistTypeId(), ExistingChecklist2);
            AddChecklist(GetMaxChecklistTypeId(), ExistingChecklist3);

            return new ScenarioData
            {
                ChecklistName = existingChecklist.Description,
                ExistingApplicationChecklist = existingChecklist
            };
        }

        public CheckList AddChecklist(short id, string name)
        {
            var checklist = DbContext.Set<CheckList>().FirstOrDefault(_ => _.Description == name);
            if (checklist != null)
                return checklist;

            checklist = new CheckList(id, name);

            DbContext.Set<CheckList>().Add(checklist);
            DbContext.SaveChanges();

            return checklist;
        }

        public void AddValidChecklist(CheckList checklist)
        {
            var country = DbContext.Set<Country>().FirstOrDefault();
            var propertyType = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().FirstOrDefault();
            var caseType = DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().FirstOrDefault();
            var validChecklist = new ValidChecklist(country, propertyType, caseType, checklist);

            DbContext.Set<ValidChecklist>().Add(validChecklist);
            DbContext.SaveChanges();
        }

        public short GetMaxChecklistTypeId()
        {
            return Convert.ToInt16(DbContext.Set<CheckList>().Max(st => st.Id) + 1);

        }

        public class ScenarioData
        {
            public string ChecklistName;
            public CheckList ExistingApplicationChecklist;
        }
    }
}