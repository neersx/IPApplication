using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Tests.Web.Picklists
{
    public class DataItemsPicklistControllerFacts : FactBase
    {
        public class DataItemsMethod : FactBase
        {
            [Fact]
            public void ReturnsDataItemsSortedByName()
            {
                var f = new DataItemsPicklistControllerFixture(Db);
                f.Setup();

                var r = f.Subject.DataItems();
                var di = r.Data.OfType<DataItem>().ToArray();

                Assert.Equal(4, di.Length);
                Assert.Equal("item_c", di.Last().Code);
                Assert.Equal("hidden", di.First().Code);
            }

            [Fact]
            public void ReturnsDataItemsWithExactMatchFlagOnDescription()
            {
                var f = new DataItemsPicklistControllerFixture(Db);
                var dataItems = f.Setup();

                var r = f.Subject.DataItems(null, "item3");
                var di = r.Data.OfType<DataItem>().ToArray();

                Assert.Equal(2, di.Length);
                Assert.Equal(dataItems.item3.Name, di.First().Code);
                Assert.Equal(dataItems.item4.Name, di.Last().Code);
            }

            [Fact]
            public void ReturnsDataItemsWithExactMatchFlagOnName()
            {
                var f = new DataItemsPicklistControllerFixture(Db);
                var dataItems = f.Setup();

                var r = f.Subject.DataItems(null, "item_c");
                var di = r.Data.OfType<DataItem>().ToArray();

                Assert.Equal(2, di.Length);
                Assert.Equal(dataItems.item1.Name, di.First().Code);
                Assert.Equal(dataItems.item2.Name, di.Last().Code);
            }
        }

        public class DataItemMethod : FactBase
        {
            [Fact]
            public void CallsDataItemMaintenanceDataItemMethod()
            {
                var f = new DataItemsPicklistControllerFixture(Db);
                var mock = new DataItem {Key = 1};

                f.DataItemMaintenance.DataItem(1, true).Returns(mock);

                var result = f.Subject.DataItem(1);

                Assert.Equal(mock, result);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDataItemMaintenanceDeleteMethodWithErrorResponse()
            {
                var f = new DataItemsPicklistControllerFixture(Db);

                var mockResponse = new DeleteResponseModel {InUseIds = new List<int> {1}};

                f.DataItemMaintenance.Delete(Arg.Any<DeleteRequestModel>()).ReturnsForAnyArgs(mockResponse);

                var result = f.Subject.Delete(1);

                Assert.Equal("entity.cannotdelete", ((IEnumerable<ValidationError>) result.Errors).First().Message);
            }

            [Fact]
            public void CallsDataItemMaintenanceDeleteMethodWithSuccessfullResponse()
            {
                var f = new DataItemsPicklistControllerFixture(Db);

                var mockResponse = new DeleteResponseModel();

                f.DataItemMaintenance.Delete(Arg.Any<DeleteRequestModel>()).ReturnsForAnyArgs(mockResponse);

                var result = f.Subject.Delete(1);

                Assert.Equal("success", result.Result);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void CallsDataItemMaintenanceSaveMethod()
            {
                var f = new DataItemsPicklistControllerFixture(Db);
                var mock = new object();

                f.DataItemMaintenance.Save(Arg.Any<DataItemPayload>(), Arg.Any<dynamic>()).Returns(mock);

                var result = f.Subject.Save(new DataItem());

                Assert.Equal(mock, result);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsDataItemMaintenanceUpdateMethod()
            {
                var f = new DataItemsPicklistControllerFixture(Db);
                var mock = new object();

                f.DataItemMaintenance.Update(Arg.Any<int>(), Arg.Any<DataItemPayload>(), Arg.Any<dynamic>()).Returns(mock);

                var result = f.Subject.Update(1, new DataItem());

                Assert.Equal(mock, result);
            }
        }

        public class ValidateMethod : FactBase
        {
            [Fact]
            public void CallsDataItemMaintenanceValidateSqlMethod()
            {
                var f = new DataItemsPicklistControllerFixture(Db);
                var mock = Enumerable.Empty<ValidationError>();

                f.DataItemMaintenance.ValidateSql(Arg.Any<DocItem>(), Arg.Any<DataItemPayload>()).Returns(mock);

                var result = f.Subject.Validate(new DataItem {Sql = new Sql()});

                Assert.Null(result);
            }
        }
    }

    public class DataItemsPicklistControllerFixture : IFixture<DataItemsPicklistController>
    {
        readonly InMemoryDbContext _db;

        public DataItemsPicklistControllerFixture(InMemoryDbContext db)
        {
            _db = db;
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            DataItemMaintenance = Substitute.For<IDataItemMaintenance>();
            Subject = new DataItemsPicklistController(_db, PreferredCultureResolver, DataItemMaintenance);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public IDataItemMaintenance DataItemMaintenance { get; set; }
        public DataItemsPicklistController Subject { get; }

        public dynamic Setup()
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

            var item3 = new DocItem
            {
                Id = 3,
                Name = "item_a",
                Description = "item3",
                ItemType = 3
            }.In(_db);

            var item4 = new DocItem
            {
                Id = 4,
                Name = "hidden",
                Description = "item3 description copy",
                ItemType = 1
            }.In(_db);

            var group1 = new Group(0, "Case").In(_db);

            var group2 = new Group(40, "Case Validation").In(_db);

            var group3 = new Group(41, "Name Validation").In(_db);

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
                Code = group3.Code,
                ItemId = item3.Id
            }.In(_db);

            new ItemGroup
            {
                Code = group2.Code,
                ItemId = item1.Id
            }.In(_db);

            var expectedGroupsForItemCode1 = new[] {group1, group2};
            return new {item1, item2, item3, item4, expectedGroupsForItemCode1};
        }
    }
}