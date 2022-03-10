using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Action
{
    class ActionPicklistsDbSetup
    {
        public const string ActionPrefix = "e2e - action";
        public const string ExistingAction = ActionPrefix + " existing";
        public const string ExistingAction2 = ExistingAction + "2";
        public const string ExistingAction3 = ExistingAction + "3";
        public const string ActionToBeAdded = ActionPrefix + " add";
        public const string ImportanceLevel = "Critical";

        public ActionPicklistsDbSetup()
        {
            DbContext = new SqlDbContext();
        }

        public IDbContext DbContext { get; }

        public ScenarioData Prepare()
        {
            var existingAction = AddAction(ExistingAction, "1");
            AddAction(ExistingAction2, "2");
            AddAction(ExistingAction3, "3");

            return new ScenarioData
                   {
                       ActionId = existingAction.Code,
                       ActionName = existingAction.Name,
                       UnlimitedCycles = true,
                       ActionCycles = 9999,
                       ExistingApplicationAction = existingAction
                   };
        }

        public InprotechKaizen.Model.Cases.Action AddAction(string name, string id)
        {
            var action = DbContext.Set<InprotechKaizen.Model.Cases.Action>().FirstOrDefault(_ => _.Name == name);
            if (action != null)
                return action;

            action = new InprotechKaizen.Model.Cases.Action(name, null, 9999, id);

            DbContext.Set<InprotechKaizen.Model.Cases.Action>().Add(action);
            DbContext.SaveChanges();

            return action;
        }

        public void AddValidAction(InprotechKaizen.Model.Cases.Action action)
        {
            var country = DbContext.Set<Country>().FirstOrDefault();
            var propertyType = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().FirstOrDefault();
            var caseType = DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().FirstOrDefault();
            var validAction = new ValidAction(action.Name, action, country, caseType, propertyType);

            DbContext.Set<ValidAction>().Add(validAction);
            DbContext.SaveChanges();
        }

        public class ScenarioData
        {
            public short ActionCycles;
            public string ActionId;
            public string ActionName;
            public bool UnlimitedCycles;
            public InprotechKaizen.Model.Cases.Action ExistingApplicationAction;
        }
    }
}