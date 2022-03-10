using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.InproDoc.Config;
using Inprotech.Web.Picklists;
using Inprotech.Web.SchemaMapping;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class DataItemMaintenanceFacts : FactBase
    {
        static DataItemPayload SetupSaveData()
        {
            var saveDetails = new DataItemPayload
            {
                IsSqlStatement = true,
                EntryPointUsage = new EntryPoint { Name = 1 },
                Sql = new Sql { SqlStatement = "SELECT * FROM ITEM" },
                ReturnsImage = false,
                ItemGroups = new List<DataItemGroup> { new DataItemGroup { Code = 0, Value = "Case" } },
                Notes = "Data Item Notes"
            };

            return saveDetails;
        }

        public class DataItemMaintenanceFixture : IFixture<DataItemMaintenance>
        {
            readonly InMemoryDbContext _db;
            readonly Func<DateTime> _now = () => DateTime.Now;

            public DataItemMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new UserBuilder(db).Build());
                DocItemReader = Substitute.For<IDocItemReader>();
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
                SqlHelper = Substitute.For<ISqlHelper>();

                Subject = new DataItemMaintenance(_db, Substitute.For<IPreferredCultureResolver>(), Substitute.For<IPassThruManager>(),
                                                  DocItemReader, SqlHelper, LastInternalCodeGenerator,
                                                  SecurityContext, _now);
            }

            public ISecurityContext SecurityContext { get; set; }

            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }

            public IDocItemReader DocItemReader { get; set; }

            public ISqlHelper SqlHelper { get; set; }

            public DataItemMaintenance Subject { get; }

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
                    ItemType = 0
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
                    CreatedBy = "def"
                }.In(_db);

                var item3 = new DocItem
                {
                    Id = 3,
                    Name = "item_a",
                    Description = "item3",
                    ItemType = 3,
                    DateCreated = Fixture.Date("2017-01-03"),
                    DateUpdated = Fixture.Date("2017-09-10"),
                    CreatedBy = "def"
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
                    CreatedBy = "abc"
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

                return new List<DocItem> { item1, item2, item3, item4 };
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ShouldCreateNewDataItemWithGivenDetails()
            {
                var f = new DataItemMaintenanceFixture(Db);

                var saveDetails = SetupSaveData();
                saveDetails.IsSqlStatement = true;

                dynamic keyInfo = new
                {
                    Id = 0,
                    Name = "item_c",
                    Description = "Data Item Description"
                };

                f.DocItemReader.ReturnColumnInformation(Arg.Any<DocItem>(), Arg.Any<bool>()).Returns(new { SqlDescribe = "1", SqlInto = "s[0]" });
                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(new List<ReturnColumnSchema> { new ReturnColumnSchema("A", "nvarchar", 1000) });

                var result = f.Subject.Save(saveDetails, keyInfo);

                var dataItem =
                    Db.Set<DocItem>().Last();

                var id = (int)keyInfo.Id;

                var itemGroup =
                    Db.Set<ItemGroup>().FirstOrDefault(nt => nt.ItemId == id);

                var itemNote =
                    Db.Set<ItemNote>().Last();

                Assert.NotNull(dataItem);
                Assert.Equal(keyInfo.Name, dataItem.Name);
                Assert.Equal(keyInfo.Description, dataItem.Description);
                Assert.Equal(saveDetails.EntryPointUsage.Name, dataItem.EntryPointUsage);
                Assert.Equal(saveDetails.Sql.SqlStatement, dataItem.Sql);
                Assert.Equal(0, dataItem.ItemType ?? 0);
                Assert.Equal("success", result.Result);
                Assert.Equal(dataItem.Id, result.UpdatedId);
                Assert.NotNull(itemGroup);
                Assert.Equal(saveDetails.Notes, itemNote.ItemNotes);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenDataItemNameAlreadyExist()
            {
                var f = new DataItemMaintenanceFixture(Db);

                f.Setup();

                var saveDetails = SetupSaveData();

                dynamic keyInfo = new
                {
                    Id = Fixture.Integer(),
                    Name = "item_c",
                    Description = "Data Item Description"
                };

                var result = f.Subject.Save(saveDetails, keyInfo);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("field.errors.notunique", result.Errors[0].Message);
                Assert.Equal("code", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldSetCorrectItemTypeForStoredProcedure()
            {
                var f = new DataItemMaintenanceFixture(Db);

                var saveDetails = SetupSaveData();
                saveDetails.IsSqlStatement = false;
                saveDetails.Sql = new Sql { StoredProcedure = "ac_ListCurrency" };

                dynamic keyInfo = new
                {
                    Id = 0,
                    Name = "item_c",
                    Description = "Data Item Description"
                };

                f.DocItemReader.ReturnColumnInformation(Arg.Any<DocItem>(), Arg.Any<bool>()).Returns(new { SqlDescribe = "1", SqlInto = "s[0]" });
                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(new List<ReturnColumnSchema> { new ReturnColumnSchema("A", "nvarchar", 1000) });
                f.SqlHelper.DeriveParameters(Arg.Any<string>()).Returns(new List<KeyValuePair<string, SqlDbType>> { new KeyValuePair<string, SqlDbType>("A", SqlDbType.NText) });

                f.Subject.Save(saveDetails, keyInfo);

                var dataItem =
                    Db.Set<DocItem>().Last();

                Assert.NotNull(dataItem);
                Assert.Equal(1, dataItem.ItemType ?? 0);
            }

            [Fact]
            public void ShouldSetCorrectItemTypeForStoredProcedureIfUseSourceFileIsSet()
            {
                var f = new DataItemMaintenanceFixture(Db);

                var saveDetails = SetupSaveData();
                saveDetails.IsSqlStatement = false;
                saveDetails.UseSourceFile = true;
                saveDetails.Sql = new Sql { StoredProcedure = "test" };

                dynamic keyInfo = new
                {
                    Id = Fixture.Integer(),
                    Name = "item_c",
                    Description = "Data Item Description"
                };

                f.DocItemReader.ReturnColumnInformation(Arg.Any<DocItem>(), Arg.Any<bool>()).Returns(new { SqlDescribe = "1", SqlInto = "s[0]" });
                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(new List<ReturnColumnSchema> { new ReturnColumnSchema("A", "nvarchar", 1000) });
                f.SqlHelper.DeriveParameters(Arg.Any<string>()).Returns(new List<KeyValuePair<string, SqlDbType>> { new KeyValuePair<string, SqlDbType>("A", SqlDbType.NText) });
                f.Subject.Save(saveDetails, keyInfo);

                var dataItem = Db.Set<DocItem>().Last();

                Assert.NotNull(dataItem);
                Assert.Equal(3, dataItem.ItemType ?? 0);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void UniqueDataItemGroupWhenUpdate()
            {
                var f = new DataItemMaintenanceFixture(Db);

                f.Setup();

                var updateDetails = SetupSaveData();

                dynamic keyInfo = new
                {
                    Id = 1,
                    Name = "item_b",
                    Description = "Data Item Description"
                };

                updateDetails.IsSqlStatement = false;
                updateDetails.Sql = new Sql { StoredProcedure = "test" };

                f.DocItemReader.ReturnColumnInformation(Arg.Any<DocItem>(), Arg.Any<bool>()).Returns(new { SqlDescribe = "1", SqlInto = "s[0]" });

                var r = f.Subject.Update((short)keyInfo.Id, updateDetails, keyInfo);
                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void UpdateDataItem()
            {
                var f = new DataItemMaintenanceFixture(Db);

                f.Setup();

                var updateDetails = SetupSaveData();

                updateDetails.IsSqlStatement = true;
                updateDetails.Sql = new Sql { SqlStatement = "Select CASEID FROM CASES" };

                dynamic keyInfo = new
                {
                    Id = 1,
                    Name = "item_updated",
                    Description = "Data Item Description Updated"
                };

                f.DocItemReader.ReturnColumnInformation(Arg.Any<DocItem>(), Arg.Any<bool>()).Returns(new { SqlDescribe = "1", SqlInto = "s[0]" });
                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(new List<ReturnColumnSchema> { new ReturnColumnSchema("A", "nvarchar", 1000) });

                var r = f.Subject.Update((short)keyInfo.Id, updateDetails, keyInfo);

                var docItems =
                    Db.Set<DocItem>().Where(di => di.Id == 1).ToArray();

                var itemGroups =
                    Db.Set<ItemGroup>().Where(di => di.ItemId == 1).ToArray();

                Assert.Equal("success", r.Result);
                Assert.Single(docItems);
                Assert.Single(itemGroups);
                Assert.Equal(keyInfo.Description, docItems[0].Description);
                Assert.Equal(updateDetails.EntryPointUsage.Name, docItems[0].EntryPointUsage);
                Assert.Equal(updateDetails.Sql.SqlStatement, docItems[0].Sql);
                Assert.Equal(updateDetails.ItemGroups.First().Code, itemGroups[0].Code);
            }
        }

        public class ValidateMethod : FactBase
        {
            DataItemEntity SetupValidateData()
            {
                var saveDetails = new DataItemEntity
                {
                    Id = Fixture.Integer(),
                    Name = "item_c",
                    Description = "Data Item Description",
                    IsSqlStatement = false,
                    EntryPointUsage = new EntryPoint { Name = 1 },
                    Sql = new Sql { SqlStatement = "SELECT * FROM ITEM" },
                    ReturnsImage = false,
                    ItemGroups = new List<DataItemGroup> { new DataItemGroup { Code = 0, Value = "Case" } },
                    Notes = "Data Item Notes"
                };

                return saveDetails;
            }

            [Fact]
            public void ShouldReturnNoErrorMessageWhenAllValidationPass()
            {
                var f = new DataItemMaintenanceFixture(Db);

                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(new List<ReturnColumnSchema> { new ReturnColumnSchema("A", "nvarchar", 100) });
                var result = f.Subject.ValidateSql(
                                                   new DocItem().FromSaveDetails(SetupValidateData()),
                                                   new DataItemEntity { Sql = new Sql { SqlStatement = "A" }, IsSqlStatement = true }).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void ShouldReturnTheErrorMessageIfExceptionIsThrown()
            {
                var f = new DataItemMaintenanceFixture(Db);
                var exceptionMessage = "Invalid Sql";
                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(x => throw new Exception(exceptionMessage));
                var result = f.Subject.ValidateSql(
                                                   new DocItem().FromSaveDetails(SetupValidateData()),
                                                   new DataItemEntity { ReturnsImage = true, Sql = new Sql { SqlStatement = "A" }, IsSqlStatement = true }).ToArray();

                Assert.NotNull(result);
                Assert.Equal("statement", result[0].Field);
                Assert.Equal("Unable to parse the SQL statement to derive values for the columns SQL_DESCRIBE and SQL_INTO in the ITEM table. This is probably because the SQL statement contains comments, or a subquery or complex expression. Please simplify the SQL statement or use a stored procedure instead.", result[0].Message);
            }

            [Fact]
            public void ShouldReturnValidationErrorNoColumnsAreReturned()
            {
                var f = new DataItemMaintenanceFixture(Db);

                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(new List<ReturnColumnSchema>());
                var result = f.Subject.ValidateSql(
                                                   new DocItem().FromSaveDetails(SetupValidateData()),
                                                   new DataItemEntity { Sql = new Sql { SqlStatement = "A" }, IsSqlStatement = true }).ToArray();

                Assert.NotNull(result);
                Assert.Equal("statement", result[0].Field);
                Assert.Equal("Unable to parse the SQL statement to derive values for the columns SQL_DESCRIBE and SQL_INTO in the ITEM table. This is probably because the SQL statement contains comments, or a subquery or complex expression. Please simplify the SQL statement or use a stored procedure instead.",
                             result[0].Message);
            }

            [Fact]
            public void ShouldReturnValidationErrorNoColumnsAreReturnedIfNoInputParamsExistsForStoredProcedure()
            {
                var f = new DataItemMaintenanceFixture(Db);

                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(new List<ReturnColumnSchema>());
                f.SqlHelper.DeriveParameters(Arg.Any<string>()).Returns(new List<KeyValuePair<string, SqlDbType>> { new KeyValuePair<string, SqlDbType>() });
                var result = f.Subject.ValidateSql(new DocItem().FromSaveDetails(SetupValidateData()), new DataItemEntity { Sql = new Sql { StoredProcedure = "A" } }).ToArray();

                Assert.NotNull(result);
                Assert.Equal("procedurename", result[0].Field);
                Assert.Equal("There is no return value from the stored procedure used by the data item. The stored procedure must use SELECT to return values instead of using the RETURN or OUTPUT parameters.", result[0].Message);
            }

            [Fact]
            public void ShouldReturnValidationErrorWhenMultipleImageColumnExists()
            {
                var f = new DataItemMaintenanceFixture(Db);

                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(new List<ReturnColumnSchema> { new ReturnColumnSchema("A", "nvarchar", 1000), new ReturnColumnSchema("A", "ntext", 1000) });
                var result = f.Subject.ValidateSql(new DocItem().FromSaveDetails(SetupValidateData()), new DataItemEntity { ReturnsImage = true, Sql = new Sql { SqlStatement = "A" }, IsSqlStatement = true }).ToArray();

                Assert.NotNull(result);
                Assert.Equal("statement", result[0].Field);
                Assert.Equal("There is more than one column selected in the SQL statement which is potentially an image. Please change the SELECT statement to only return one (long) column or de-select the Image option.", result[0].Message);
            }

            [Fact]
            public void ShouldReturnValidationErrorWhenNoImageColumnExists()
            {
                var f = new DataItemMaintenanceFixture(Db);

                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(new List<ReturnColumnSchema> { new ReturnColumnSchema("A", "nvarchar", 100) });
                var result = f.Subject.ValidateSql(
                                                   new DocItem().FromSaveDetails(SetupValidateData()),
                                                   new DataItemEntity { ReturnsImage = true, Sql = new Sql { SqlStatement = "A" }, IsSqlStatement = true }).ToArray();

                Assert.NotNull(result);
                Assert.Equal("statement", result[0].Field);
                Assert.Equal("There are no columns selected in the SQL statement which could potentially contain an image. Please change the SELECT statement or untick the 'Returns an image' option.", result[0].Message);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteSuccessfully()
            {
                var f = new DataItemMaintenanceFixture(Db);
                f.Setup();

                var deleteIds = new List<int> { 1, 2 };

                var deleteRequestModel = new DeleteRequestModel { Ids = deleteIds };
                var r = f.Subject.Delete(deleteRequestModel);

                Assert.Empty(r.InUseIds);
                Assert.Equal(2, Db.Set<DocItem>().Count());
                Assert.False(Db.Set<DocItem>().Any(_ => _.Id == 2 || _.Id == 1));
                Assert.False(Db.Set<ItemNote>().Any(_ => _.ItemId == 1));
            }
        }

        public class ValidateCaseIdFormat : FactBase
        {
            DataItemEntity SetupCaseValidationData()
            {
                var saveDetails = new DataItemEntity
                {
                    Id = Fixture.Integer(),
                    Name = "item_case",
                    Description = "Data Item Description",
                    IsSqlStatement = false,
                    EntryPointUsage = new EntryPoint { Name = 1 },
                    Sql = new Sql { SqlStatement = "SELECT * FROM ITEM where id = :CaseId" },
                    ReturnsImage = false,
                    ItemGroups = new List<DataItemGroup> { new DataItemGroup { Code = 0, Value = "Case Validation" } },
                    Notes = "Data Item Notes"
                };

                return saveDetails;
            }

            [Fact]
            public void ShouldReturnTheErrorMessageIfExceptionIsThrown()
            {
                var f = new DataItemMaintenanceFixture(Db);
                f.DocItemReader.ReturnColumnSchema(Arg.Any<DocItem>()).Returns(new List<ReturnColumnSchema> { new ReturnColumnSchema("A", "nvarchar", 1000) });
                f.DocItemReader.InvalidFormatCaseIdForCaseValidation(Arg.Any<DocItem>()).Returns(true);
                var result = f.Subject.ValidateSql(
                                                   new DocItem().FromSaveDetails(SetupCaseValidationData()),
                                                   new DataItemEntity { ReturnsImage = true, Sql = new Sql { SqlStatement = "SELECT * FROM ITEM where id = :CaseId" }, IsSqlStatement = true, ItemGroups = new List<DataItemGroup> { new DataItemGroup { Code = 0, Value = "Case Validation" } }}).ToArray();

                Assert.NotNull(result);
                Assert.Equal("Invalid Sanity Check Data Item entry point. The SQL Statement for a Data Item that belongs to the Data Validation group must contain the entry point formatted as '=:CaseId'.", result[0].Message);
            }
        }
    }
}