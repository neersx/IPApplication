using System;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Documents;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.DataItem
{
    public class DataItemDbSetup : DbSetup
    {
        const string DataItemName = "e2e - dataitem";
        public const string DataItemNameToBeAdded = DataItemName + " add";
        public const string DataItemNameToBeEdited = DataItemName + " edited";
        const string DataItemDescription = "e2e - dataitem description";
        const string DataItemSqlQuery = "e2e - data item sql query";
        const string UpdatedByName = "e2e - UpdatedBy";

        public ScenarioData Prepare()
        {
            var existingDataItem = InsertWithNewId(new DocItem
            {
                Name = DataItemName,
                Description = DataItemDescription,
                Sql = DataItemSqlQuery,
                DateUpdated = DateTime.Now,
                DateCreated = DateTime.Now,
                CreatedBy = UpdatedByName
            });

            var existingDataItem1 = InsertWithNewId(new DocItem
            {
                Name = "e3e - Group1",
                Description = "e3e - Group1",
                ItemType = 0,
                Sql = "select * from dbo.cases",
                DateUpdated = DateTime.Now,
                DateCreated = DateTime.Now,
                CreatedBy = UpdatedByName
            });

            var existingDataItem2 = InsertWithNewId(new DocItem
            {
                Name = "e3e - Group2",
                Description = "e3e - Group2",
                ItemType = 0,
                Sql = "select * from dbo.cases",
                DateUpdated = DateTime.Now,
                DateCreated = DateTime.Now,
                CreatedBy = UpdatedByName
            });

            InsertWithNewId(new DocItem
            {
                Name = "e2e - Data Item Name",
                Description = "e2e - Data Item Description",
                Sql = "e2e - Data Item Sql Query"
            });

            var existingDataItemGroup = new Group(Fixture.Integer(),"Group 1");
            DbContext.Set<Group>().Add(existingDataItemGroup);

            var existingDataItemGroup1 = new Group(Fixture.Integer(),"Group 2");
            DbContext.Set<Group>().Add(existingDataItemGroup1);
            DbContext.SaveChanges();

            var itemGroup = new ItemGroup{Code = existingDataItemGroup.Code, ItemId = existingDataItem.Id };
            DbContext.Set<ItemGroup>().Add(itemGroup);

            var itemGroup1 = new ItemGroup{Code = existingDataItemGroup1.Code, ItemId = existingDataItem1.Id };
            DbContext.Set<ItemGroup>().Add(itemGroup1);

            var itemGroup2 = new ItemGroup{Code = existingDataItemGroup1.Code, ItemId = existingDataItem2.Id };
            DbContext.Set<ItemGroup>().Add(itemGroup2);
            DbContext.SaveChanges();

            var itemNote = new ItemNote {ItemId = existingDataItem.Id, ItemNotes = "Text Notes"};
            DbContext.Set<ItemNote>().Add(itemNote);
            DbContext.SaveChanges();

            return new ScenarioData
            {
                Name = existingDataItem.Name,
                Description = existingDataItem.Description,
                GroupName = existingDataItemGroup.Name,
                UpdatedBy = existingDataItem.CreatedBy,
                Sql = existingDataItem.Sql,
                CreatedDate = existingDataItem.DateCreated ?? DateTime.Now,
                UpdatedDate = existingDataItem.DateUpdated ?? DateTime.Now,
                ExistingItemNote = itemNote
            };
        }

        public class ScenarioData
        {
            public string Name;
            public string Description;
            public string UpdatedBy;
            public DateTime CreatedDate;
            public DateTime UpdatedDate;
            public string GroupName;
            public ItemNote ExistingItemNote;
            public string Sql;
        }
    }
}
