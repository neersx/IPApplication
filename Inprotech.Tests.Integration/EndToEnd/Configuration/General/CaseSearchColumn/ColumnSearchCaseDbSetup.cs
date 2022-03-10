using System;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.CaseSearchColumn
{
    class ColumnSearchCaseDbSetup : DbSetup
    {
        public ScenarioData Prepare()
        {
            var existingDataItem1 = InsertWithNewId(new DocItem
            {
                Name = "e2e - DataItem",
                Description = "e2e - DataItem",
                ItemType = 0,
                Sql = "select * from dbo.cases",
                DateUpdated = DateTime.Now,
                DateCreated = DateTime.Now,
                CreatedBy = "e2e - UpdatedBy"
            });

            InsertWithNewId(new QueryColumnGroup
            {
                GroupName = "e2e - Group",
                ContextId = 2
            });

            return new ColumnSearchCaseDbSetup.ScenarioData
            {
                Name = existingDataItem1.Name,
                Description = existingDataItem1.Description,
                UpdatedBy = existingDataItem1.CreatedBy,
                Sql = existingDataItem1.Sql,
                CreatedDate = existingDataItem1.DateCreated ?? DateTime.Now,
                UpdatedDate = existingDataItem1.DateUpdated ?? DateTime.Now
            };
        }

        public class ScenarioData
        {
            public string Name { get; set; }
            public string Description { get; set; }
            public string UpdatedBy { get; set; }
            public DateTime CreatedDate { get; set; }
            public DateTime UpdatedDate { get; set; }
            public string Sql { get; set; }
        }
    }
}