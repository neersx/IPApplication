using System.Linq;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.DataItemGroup
{
    class DataItemGroupDbSetup
    {
        public const string DataItemGroupPrefix = "e2e - dataItemGroup";
        public const string ExistingDataItemGroup = DataItemGroupPrefix + " existing";
        public const string ExistingDataItemGroup2 = ExistingDataItemGroup + "2";
        public const string ExistingDataItemGroup3 = ExistingDataItemGroup + "3";
        public const string DataItemGroupToBeAdded = DataItemGroupPrefix + " add";

        public DataItemGroupDbSetup()
        {
            DbContext = new SqlDbContext();
        }

        public IDbContext DbContext { get; }

        public ScenarioData Prepare()
        {
            var existingDataItemGroup = AddDataItemGroup(ExistingDataItemGroup);
            AddDataItemGroup(ExistingDataItemGroup2);
            AddDataItemGroup(ExistingDataItemGroup3);
            AddDocItem("e2e-delete");
            return new ScenarioData
            {
                DataItemGroupDesc = existingDataItemGroup.Name,
                ExistingItemGroup = existingDataItemGroup
            };
        }

        public Group AddDataItemGroup(string name)
        {
            var code = DbContext.Set<Group>().Any() ? DbContext.Set<Group>().Max(m => m.Code) : 0;
            code++;
            var dataItemGroup = new Group(code, name);

            DbContext.Set<Group>().Add(dataItemGroup);

            var lastinternalCode = DbContext.Set<LastInternalCode>().First(_ => _.TableName.Equals("GROUPS"));
            lastinternalCode.InternalSequence = code;

            DbContext.SaveChanges();

            return dataItemGroup;
        }

        public void AddDocItem(string name)
        {
            var dataItemGroup = AddDataItemGroup(name);

            var id = DbContext.Set<DocItem>().Any() ? DbContext.Set<DocItem>().Max(m => m.Id) : 0;
            id++;

            var item = new DocItem
            {
                Id = id,
                Name = "item_c",
                Description = "description of item c",
                ItemType = 0,
                Sql = "select CASEID from CASES"
                
            };

            DbContext.Set<DocItem>().Add(item);
            DbContext.SaveChanges();

            var itemGroup = new ItemGroup
            {
                Code = dataItemGroup.Code,
                ItemId = id
            };

            DbContext.Set<ItemGroup>().Add(itemGroup);
            DbContext.SaveChanges();
        }

        public class ScenarioData
        {
            public string DataItemGroupDesc;
            public Group ExistingItemGroup;
        }
    }
}

