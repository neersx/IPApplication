using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class DataItemGroupPicklistMaintenanceFacts : FactBase
    {
        public class SaveMethod : FactBase
        {
            DataItemGroup SetupSaveData()
            {
                var fixture = new DataItemGroupPicklistMaintenanceFixture(Db);

                var saveDetails = new DataItemGroup
                {
                    Code = (short) fixture.LastInternalCodeGenerator.GenerateLastInternalCode("GROUPS"),
                    Value = "Group1"
                };

                return saveDetails;
            }

            [Fact]
            public void AddGroup()
            {
                var fixture = new DataItemGroupPicklistMaintenanceFixture(Db);

                var model = new DataItemGroup
                {
                    Code = (short) fixture.LastInternalCodeGenerator.GenerateLastInternalCode("GROUPS"),
                    Value = "Group 1"
                };

                var r = fixture.Subject.Save(model, Operation.Add);

                var justAdded = Db.Set<Group>().Last();

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Value, justAdded.Name);
            }

            [Fact]
            public void RequiresGroupName()
            {
                var subject = new DataItemGroupPicklistMaintenanceFixture(Db)
                    .Subject;

                var saveDetails = SetupSaveData();

                saveDetails.Value = string.Empty;

                var r = subject.Save(saveDetails, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresGroupNameToBeNotGreaterThan40Characters()
            {
                var fixture = new DataItemGroupPicklistMaintenanceFixture(Db);

                var saveDetails = SetupSaveData();

                saveDetails.Value = "1234567890123456789012345678901234567890123456789012345678901234567890123456789";

                var r = fixture.Subject.Save(saveDetails, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 40), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueGroup()
            {
                var saveDetails = SetupSaveData();

                saveDetails.Value = "Case";

                var fixture = new DataItemGroupPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();

                var r = fixture.Subject.Save(saveDetails, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            DataItemGroup SetupSaveData()
            {
                var fixture = new DataItemGroupPicklistMaintenanceFixture(Db);

                var saveDetails = new DataItemGroup
                {
                    Code = (short) fixture.LastInternalCodeGenerator.GenerateLastInternalCode("GROUPS"),
                    Value = "Group1"
                };

                return saveDetails;
            }

            [Fact]
            public void UniqueGroupNameWhenUpdate()
            {
                var fixture = new DataItemGroupPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();

                var updateDetails = SetupSaveData();

                updateDetails.Code = 0;
                updateDetails.Value = "Case Validation";

                var r = fixture.Subject.Save(updateDetails, Operation.Update);
                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void UpdateGroupName()
            {
                var fixture = new DataItemGroupPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();

                var updateDetails = SetupSaveData();

                updateDetails.Code = 41;
                updateDetails.Value = "Name Validation Updated";

                var r = fixture.Subject.Save(updateDetails, Operation.Update);

                Assert.Equal("success", r.Result);
                var groups = Db.Set<Group>().Where(gp => gp.Code == updateDetails.Code).ToArray();
                Assert.Single(groups);
                Assert.Equal(updateDetails.Value, groups[0].Name);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeleteGroup()
            {
                var fixture = new DataItemGroupPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();

                var r = fixture.Subject.Delete(41);

                var group = Db.Set<Group>().Where(gp => gp.Code == 41).ToArray();

                Assert.Equal("success", r.Result);
                Assert.Empty(group);
            }

            [Fact]
            public void InUseCheckWhenDelete()
            {
                var fixture = new DataItemGroupPicklistMaintenanceFixture(Db);
                fixture.SetupDbData();

                var r = fixture.Subject.Delete(40);

                var group = Db.Set<Group>().Where(ng => ng.Code == 40).ToArray();

                Assert.Single(group);
                Assert.Equal("entity.cannotdelete", r.Errors[0].Message);
            }
        }

        public class DataItemGroupPicklistMaintenanceFixture : IFixture<DataItemGroupPicklistMaintenance>
        {
            readonly InMemoryDbContext _db;

            public DataItemGroupPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
                Subject = new DataItemGroupPicklistMaintenance(_db, LastInternalCodeGenerator);
            }

            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; }

            public DataItemGroupPicklistMaintenance Subject { get; set; }

            public void SetupDbData()
            {
                var item1 = new DocItem
                {
                    Id = 1,
                    Name = "item_c",
                    Description = "description of item c",
                    ItemType = 0
                }.In(_db);

                var item2 = new DocItem
                {
                    Id = 2,
                    Name = "item_b",
                    Description = "item_c description copy",
                    ItemType = 0,
                    SqlDescribe = "9"
                }.In(_db);

                var group1 = new Group(0, "Case").In(_db);

                var group2 = new Group(40, "Case Validation").In(_db);

                new Group(41, "Name Validation").In(_db);

                new ItemGroup
                {
                    Code = group1.Code,
                    ItemId = item1.Id
                }.In(_db);

                new ItemGroup
                {
                    Code = group2.Code,
                    ItemId = item2.Id
                }.In(_db);

                new ItemGroup
                {
                    Code = group2.Code,
                    ItemId = item1.Id
                }.In(_db);
            }
        }
    }
}