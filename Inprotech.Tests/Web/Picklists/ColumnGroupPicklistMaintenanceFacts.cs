using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Queries;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ColumnGroupPicklistMaintenanceFacts : FactBase
    {
        public class SaveMethod : FactBase
        {
            QueryColumnGroupPayload SetupSaveData()
            { 

                var saveDetails = new QueryColumnGroupPayload
                {
                    Value = "Group1",
                    ContextId = (int)QueryContext.CaseSearch
                };

                return saveDetails;
            }

            [Fact]
            public void AddGroup()
            {
                var fixture = new ColumnGroupPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();

                var model = new QueryColumnGroupPayload
                {
                    ContextId = (int)QueryContext.CaseSearch,
                    Value = "Group 1"
                };

                var r = fixture.Subject.Save(model, Operation.Add);

                var justAdded = Db.Set<QueryColumnGroup>().Last();

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Value, justAdded.GroupName);
            }

            [Fact]
            public void RequiresGroupName()
            {
                var subject = new ColumnGroupPicklistMaintenanceFixture(Db)
                    .Subject;

                var saveDetails = SetupSaveData();

                saveDetails.Value = string.Empty;

                var r = subject.Save(saveDetails, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresGroupNameToBeNotGreaterThan50Characters()
            {
                var fixture = new ColumnGroupPicklistMaintenanceFixture(Db);

                var saveDetails = SetupSaveData();

                saveDetails.Value = "12345678901234567890123456789012345678901234567890123456";

                var r = fixture.Subject.Save(saveDetails, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueGroup()
            {
                var saveDetails = SetupSaveData();

                saveDetails.Value = "Law Update Date Changes";

                var fixture = new ColumnGroupPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();

                var r = fixture.Subject.Save(saveDetails, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void UpdateGroupName()
            {
                var fixture = new ColumnGroupPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();

                var updateDetails = new QueryColumnGroupPayload
                {
                    ContextId = (int) QueryContext.CaseSearch,
                    Value = "Updated Goods and services list",
                    Key = -41
                };

                var r = fixture.Subject.Save(updateDetails, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.Equal(updateDetails.Value, Db.Set<QueryColumnGroup>().Single(gp => gp.Id == updateDetails.Key).GroupName);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeleteGroup()
            {
                var fixture = new ColumnGroupPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();

                var r = fixture.Subject.Delete(-46);

                var group = Db.Set<QueryColumnGroup>().Where(gp => gp.Id == -46).ToArray();

                Assert.Equal("success", r.Result);
                Assert.Empty(group);
            }
        }

        public class ColumnGroupPicklistMaintenanceFixture : IFixture<ColumnGroupPicklistMaintenance>
        {
            readonly InMemoryDbContext _db;

            public ColumnGroupPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new ColumnGroupPicklistMaintenance(_db);
            }

            public ColumnGroupPicklistMaintenance Subject { get; set; }

            public void SetupDbData()
            {
                new QueryColumnGroup
                {
                    Id = -46,
                    ContextId = (int)QueryContext.CaseSearch,
                    DisplaySequence = 1,
                    GroupName = "Law Update Date Changes"
                }.In(_db);

                var item2 = new QueryColumnGroup
                {
                    Id = -41,
                    ContextId = (int)QueryContext.CaseSearch,
                    DisplaySequence = 1,
                    GroupName = "Goods and Services List"
                }.In(_db);

                new QueryContextColumn
                {
                    ContextId = (int)QueryContext.CaseSearch,
                    GroupId = item2.Id,
                    ColumnId = 1,
                    IsMandatory = true,
                    IsSortOnly = true
                }.In(_db);
            }
        }
    }
}