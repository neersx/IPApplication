using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Picklists;
using Inprotech.Web.SchemaMapping;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class DataItemMaintenanceControllerFacts : FactBase
    {
        public class DataItemMaintenanceControllerFixture : IFixture<DataItemMaintenanceController>
        {
            readonly InMemoryDbContext _db;

            public DataItemMaintenanceControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                DocItemReader = Substitute.For<IDocItemReader>();
                DataItemMaintenance = Substitute.For<IDataItemMaintenance>();
                CommonQueryService = new CommonQueryService();

                Subject = new DataItemMaintenanceController(_db, DocItemReader, CommonQueryService,
                                                            Substitute.For<IPreferredCultureResolver>(), DataItemMaintenance);
            }

            public IDocItemReader DocItemReader { get; set; }

            ICommonQueryService CommonQueryService { get; }

            public IDataItemMaintenance DataItemMaintenance { get; set; }

            public DataItemMaintenanceController Subject { get; }

            public List<DocItem> Setup()
            {
                var item1 = new DocItem
                {
                    Id = 1,
                    Name = "item_c",
                    Description = "description of item c",
                    DateCreated = Fixture.Date("2017-01-02"),
                    DateUpdated = Fixture.Date("2017-09-09"),
                    CreatedBy = "abc",
                    ItemType = 0,
                    Sql = string.Empty
                }.In(_db);

                new ItemNote
                {
                    ItemId = item1.Id,
                    ItemNotes = "Item Notes 1"
                }.In(_db);

                var item2 = new DocItem
                {
                    Id = 2,
                    Name = "item_b",
                    Description = "item_c description copy",
                    ItemType = 0,
                    DateCreated = Fixture.Date("2017-01-01"),
                    DateUpdated = Fixture.Date("2017-09-08"),
                    SqlDescribe = "9",
                    CreatedBy = "def",
                    Sql = string.Empty
                }.In(_db);

                var item3 = new DocItem
                {
                    Id = 3,
                    Name = "item_a",
                    Description = "item3",
                    ItemType = 3,
                    DateCreated = Fixture.Date("2017-01-03"),
                    DateUpdated = Fixture.Date("2017-09-10"),
                    CreatedBy = "def",
                    Sql = string.Empty
                }.In(_db);

                var itemNote = new ItemNote
                {
                    ItemId = item3.Id,
                    ItemNotes = "Item Notes 3"
                }.In(_db);

                _db.Set<DocItem>().Single(_ => _.Id == item3.Id).Note = itemNote;
                _db.SaveChanges();

                var item4 = new DocItem
                {
                    Id = 4,
                    Name = "hidden",
                    Description = "item3 description copy",
                    ItemType = 1,
                    DateCreated = Fixture.Date("2017-01-02"),
                    DateUpdated = Fixture.Date("2017-09-09"),
                    CreatedBy = "abc",
                    Sql = string.Empty
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
                
                return new List<DocItem> {item1, item2, item3, item4};
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldNotReturnAnyDocItemsWhenUnMatchedGroupAndNameIsProvided()
            {
                var group = new DataItemGroup(0, "Case");

                var groupList = new List<DataItemGroup> {group};

                var searchOptions = new DataItemMaintenanceController.DataItemSearchOptions
                {
                    Text = "item_a",
                    Group = groupList
                };
                var f = new DataItemMaintenanceControllerFixture(Db);
                f.Setup();

                var e = f.Subject.Search(searchOptions);
                Assert.NotNull(e);

                var results = ((IEnumerable<dynamic>) e.Results.Data).ToArray();

                Assert.Empty(results);
            }

            [Fact]
            public void ShouldReturnListOfDocItemsWhenSearchOptionIsNotProvided()
            {
                var f = new DataItemMaintenanceControllerFixture(Db);
                var dataItem = f.Setup();
                var e = f.Subject.Search(null);

                var results = ((IEnumerable<dynamic>) e.Results.Data).ToArray();
                var ids = ((IEnumerable<dynamic>) e.Ids).ToArray();
                Assert.NotNull(e);
                Assert.Equal(results.Length, dataItem.Count);
                Assert.Equal(ids.Length, dataItem.Count);
            }

            [Fact]
            public void ShouldReturnMatchingDocItemsWhenGroupIsProvided()
            {
                var group = new DataItemGroup(0, "Case");

                var groupList = new List<DataItemGroup> {group};

                var searchOptions = new DataItemMaintenanceController.DataItemSearchOptions
                {
                    Text = string.Empty,
                    Group = groupList
                };
                var f = new DataItemMaintenanceControllerFixture(Db);

                var dataItemList = f.Setup();

                var e = f.Subject.Search(searchOptions);
                Assert.NotNull(e);

                var results = ((IEnumerable<dynamic>) e.Results.Data).ToArray();

                Assert.Single(results);
                Assert.Equal(results[0].Name, dataItemList[0].Name);
            }

            [Fact]
            public void ShouldReturnMatchingDocItemsWhenNameIsProvided()
            {
                var searchOptions = new DataItemMaintenanceController.DataItemSearchOptions
                {
                    Text = "item_a"
                };

                var f = new DataItemMaintenanceControllerFixture(Db);
                var dataItemList = f.Setup();
                var e = f.Subject.Search(searchOptions);
                Assert.NotNull(e);

                var results = ((IEnumerable<dynamic>) e.Results.Data).ToArray();

                Assert.Single(results);
                Assert.Equal(results[0].Name, dataItemList[2].Name);
                Assert.Equal(results[0].Notes, "Item Notes 3");
            }

            [Fact]
            public void ShouldReturnMatchingDocItemsWhenSqlIsProvided()
            {
                var searchOptions = new DataItemMaintenanceController.DataItemSearchOptions
                {
                    Text = "table",
                    IncludeSql = true
                };

                var f = new DataItemMaintenanceControllerFixture(Db);
                
                var item = new DocItem
                {
                    Id = 5,
                    Name = "item_sql",
                    Description = "item5",
                    Sql = "Select * FROM table",
                    ItemType = 0,
                    DateCreated = Fixture.Date("2017-01-03"),
                    DateUpdated = Fixture.Date("2017-09-10"),
                    CreatedBy = "def"
                }.In(Db);

                var e = f.Subject.Search(searchOptions);
                Assert.NotNull(e);

                var results = ((IEnumerable<dynamic>) e.Results.Data).ToArray();

                Assert.Single(results);
                Assert.Equal(results[0].Name, item.Name);
            }

            [Fact]
            public void ShouldNotReturnMatchingDocItemsWhenSqlIsNotIncluded()
            {
                var searchOptions = new DataItemMaintenanceController.DataItemSearchOptions
                {
                    Text = "table",
                    IncludeSql = false
                };

                var f = new DataItemMaintenanceControllerFixture(Db);
               
                new DocItem
                {
                    Id = 5,
                    Name = "item_sql",
                    Description = "item5",
                    Sql = "Select * FROM table",
                    ItemType = 0,
                    DateCreated = Fixture.Date("2017-01-03"),
                    DateUpdated = Fixture.Date("2017-09-10"),
                    CreatedBy = "def"
                }.In(Db);

                var e = f.Subject.Search(searchOptions);
                Assert.NotNull(e);

                var results = ((IEnumerable<dynamic>) e.Results.Data).ToArray();

                Assert.Equal(0, results.Length);
            }

            [Fact]
            public void ShouldReturnMatchingDocItemsWhenSpIsProvided()
            {
                var searchOptions = new DataItemMaintenanceController.DataItemSearchOptions
                {
                    Text = "SP_Sql",
                    IncludeSql = true
                };

                var f = new DataItemMaintenanceControllerFixture(Db);
                var item = new DocItem
                {
                    Id = 6,
                    Name = "item_sp",
                    Description = "item6",
                    Sql = "SP_SqlFrom",
                    ItemType = 3,
                    DateCreated = Fixture.Date("2017-01-03"),
                    DateUpdated = Fixture.Date("2017-09-10"),
                    CreatedBy = "def"
                }.In(Db);

                var e = f.Subject.Search(searchOptions);
                Assert.NotNull(e);

                var results = ((IEnumerable<dynamic>) e.Results.Data).ToArray();

                Assert.Single(results);
                Assert.Equal(results[0].Name, item.Name);
            }
        }

        public class GetFilterDataMethod : FactBase
        {
            [Fact]
            public void GetDistinctCreatedByInAscendingOrder()
            {
                var f = new DataItemMaintenanceControllerFixture(Db);
                var s = new DataItemMaintenanceController.DataItemSearchOptions {Text = string.Empty};

                f.Setup();

                var r = f.Subject.GetFilterDataForColumn("createdBy", s).ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal("abc", r[0].Code);
                Assert.Equal("def", r[1].Code);
            }

            [Fact]
            public void GetDistinctCreatedDateInAscendingOrder()
            {
                var f = new DataItemMaintenanceControllerFixture(Db);
                var s = new DataItemMaintenanceController.DataItemSearchOptions {Text = string.Empty};

                f.Setup();

                var r = f.Subject.GetFilterDataForColumn("dateCreated", s).ToArray();

                Assert.Equal(3, r.Length);
                Assert.Equal(Convert.ToDateTime(r[0].Code), Convert.ToDateTime("2017-01-01"));
                Assert.Equal(Convert.ToDateTime(r[1].Code), Convert.ToDateTime("2017-01-02"));
                Assert.Equal(Convert.ToDateTime(r[2].Code), Convert.ToDateTime("2017-01-03"));
            }

            [Fact]
            public void GetDistinctUpdatedDateInAscendingOrder()
            {
                var f = new DataItemMaintenanceControllerFixture(Db);
                var s = new DataItemMaintenanceController.DataItemSearchOptions {Text = string.Empty};

                f.Setup();

                var r = f.Subject.GetFilterDataForColumn("dateUpdated", s).ToArray();

                Assert.Equal(3, r.Length);
                Assert.Equal(Convert.ToDateTime(r[0].Code), Convert.ToDateTime("2017-09-08"));
                Assert.Equal(Convert.ToDateTime(r[1].Code), Convert.ToDateTime("2017-09-09"));
                Assert.Equal(Convert.ToDateTime(r[2].Code), Convert.ToDateTime("2017-09-10"));
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDataItemMaintenanceDeleteMethodWithSuccessfullResponse()
            {
                var f = new DataItemMaintenanceControllerFixture(Db);

                var mockResponse = new DeleteResponseModel();

                f.DataItemMaintenance.Delete(Arg.Any<DeleteRequestModel>()).ReturnsForAnyArgs(mockResponse);

                var result = f.Subject.Delete(new DeleteRequestModel());

                Assert.Equal(mockResponse, result);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void CallsDataItemMaintenanceSaveMethod()
            {
                var f = new DataItemMaintenanceControllerFixture(Db);
                var mock = new object();

                f.DataItemMaintenance.Save(Arg.Any<DataItemPayload>(), Arg.Any<dynamic>()).Returns(mock);

                var result = f.Subject.Save(new DataItemEntity());

                Assert.Equal(mock, result);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsDataItemMaintenanceUpdateMethod()
            {
                var f = new DataItemMaintenanceControllerFixture(Db);
                var mock = new object();

                f.DataItemMaintenance.Update(Arg.Any<int>(), Arg.Any<DataItemPayload>(), Arg.Any<dynamic>()).Returns(mock);

                var result = f.Subject.Update(1, new DataItemEntity());

                Assert.Equal(mock, result);
            }
        }

        public class ValidateMethod : FactBase
        {
            [Fact]
            public void CallsDataItemMaintenanceValidateSqlMethod()
            {
                var f = new DataItemMaintenanceControllerFixture(Db);
                var mock = Enumerable.Empty<ValidationError>();

                f.DataItemMaintenance.ValidateSql(Arg.Any<DocItem>(), Arg.Any<DataItemPayload>()).Returns(mock);

                var result = f.Subject.Validate(new DataItemEntity {Sql = new Sql()});

                Assert.Null(result);
            }
        }
    }
}