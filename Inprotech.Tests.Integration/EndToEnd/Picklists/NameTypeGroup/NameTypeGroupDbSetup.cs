using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.NameTypeGroup
{
   public class NameTypeGroupDbSetup
    {
        public const string NameTypeGroupPrefix = "e2e - nameTypeGroup";
        public const string ExistingNameTypeGroup = NameTypeGroupPrefix + " existing";
        public const string ExistingNameTypeGroup2 = ExistingNameTypeGroup + "2";
        public const string ExistingNameTypeGroup3 = ExistingNameTypeGroup + "3";
        public const string NameTypeGroupToBeAdded = NameTypeGroupPrefix + " add";

        public NameTypeGroupDbSetup()
        {
            DbContext = new SqlDbContext();
        }

        public IDbContext DbContext { get; }

        public ScenarioData Prepare()
        {
            var existingNameTypeGroup = AddNameTypeGroup(1, ExistingNameTypeGroup);
            AddNameTypeGroup(2, ExistingNameTypeGroup2);
            AddNameTypeGroup(3, ExistingNameTypeGroup2);

            return new ScenarioData
            {
                NameTypeGroupId = existingNameTypeGroup.Id,
                NameTypeGroupDesc = existingNameTypeGroup.Value,
                ExistingNameTypeGroup = existingNameTypeGroup
            };
        }

        public NameGroup AddNameTypeGroup(short id, string name)
        {
            var nameTypeGroup = DbContext.Set<NameGroup>().FirstOrDefault(_ => _.Value == name);
            if (nameTypeGroup != null)
                return nameTypeGroup;

            nameTypeGroup = new NameGroup(id, name);

            DbContext.Set<NameGroup>().Add(nameTypeGroup);
            DbContext.SaveChanges();

            return nameTypeGroup;
        }

        public class ScenarioData
        {
            public short NameTypeGroupId;
            public string NameTypeGroupDesc;
            public NameGroup ExistingNameTypeGroup;
        }
    }
}
