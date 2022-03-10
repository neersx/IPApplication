using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.SchemaMapping;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class DocItemReaderFacts : FactBase
    {
        public class DocItemReaderFixture : IFixture<IDocItemReader>
        {
            readonly InMemoryDbContext _db;

            public DocItemReaderFixture(InMemoryDbContext db)
            {
                _db = db;
                SqlHelper = Substitute.For<ISqlHelper>();
                SqlHelper.WhenForAnyArgs(_ => _.DeriveReturnColumns(null)).Do(_ => SqlHelperArguments = _.Args()[1]);
                SetupData();
            }

            public ISqlHelper SqlHelper { get; set; }

            public dynamic SqlHelperArguments { get; private set; }

            public IDocItemReader Subject => new DocItemReader(_db, SqlHelper);

            public DocItemReaderFixture WithParameters(List<KeyValuePair<string, SqlDbType>> parameters)
            {
                SqlHelper.DeriveParameters(null).ReturnsForAnyArgs(parameters);

                return this;
            }

            public DocItemReaderFixture WithReturnColumns(List<KeyValuePair<string, string>> returnColumns)
            {
                SqlHelper.DeriveReturnColumns(null).ReturnsForAnyArgs(returnColumns);

                return this;
            }

            public void SetupData()
            {
                new DocItem
                {
                    Id = 1,
                    Name = "item_a",
                    Description = "doc item with sql statement",
                    Sql = "Select CaseId from CASES where caseid = :gstrEntryPoint",
                    ItemType = 0
                }.In(_db);

                new DocItem
                {
                    Id = 2,
                    Name = "item_b",
                    Description = "doc item with stored proc",
                    Sql = "sp_test",
                    ItemType = 3,
                    SqlDescribe = "1, 2 "
                }.In(_db);

                new DocItem
                {
                    Id = 3,
                    Name = "item_c",
                    Description = "empty doc item type",
                    Sql = string.Empty,
                    ItemType = null
                }.In(_db);
            }
        }

        public class ReadMethod : FactBase
        {
            [Fact]
            public void ShouldCallSqlHelperDeriveReturnColumnsWithNullSqlParameters()
            {
                var fixture = new DocItemReaderFixture(Db);

                var controller = fixture.Subject;

                controller.Read(1);

                Dictionary<string, object> args = fixture.SqlHelperArguments;

                Assert.Equal("nvarchar", args["@gstrEntryPoint"]);
            }

            [Fact]
            public void ShouldReturnCorrectDocItem()
            {
                var controller = new DocItemReaderFixture(Db).Subject;

                var docItem = controller.Read(3);

                Assert.Equal("item_c", docItem.Code);
            }

            [Fact]
            public void ShouldReturnNoResultsForNullDocItemType()
            {
                var controller = new DocItemReaderFixture(Db).WithReturnColumns(null).Subject;

                var docItem = controller.Read(3);

                Assert.Null(docItem.Parameters);
                Assert.Null(docItem.Columns);
            }

            [Fact]
            public void ShouldReturnSqlStatementParameters()
            {
                var controller = new DocItemReaderFixture(Db).Subject;

                var docItem = controller.Read(1);

                Assert.Equal("gstrEntryPoint", docItem.Parameters[0].Name);
                Assert.Equal("nvarchar", docItem.Parameters[0].Type);
            }

            [Fact]
            public void ShouldReturnSqlStatementReturnColumns()
            {
                var returnColumns = new List<KeyValuePair<string, string>>
                {
                    new KeyValuePair<string, string>("CaseId", "int")
                };

                var controller = new DocItemReaderFixture(Db).WithReturnColumns(returnColumns).Subject;

                var docItem = controller.Read(1);

                Assert.Equal("CaseId", docItem.Columns[0].Name);
                Assert.Equal("int", docItem.Columns[0].Type);
            }

            [Fact]
            public void ShouldReturnStoredProcParameters()
            {
                var parameters = new List<KeyValuePair<string, SqlDbType>>
                {
                    new KeyValuePair<string, SqlDbType>("p1", SqlDbType.Int)
                };

                var controller = new DocItemReaderFixture(Db).WithParameters(parameters).Subject;

                var docItem = controller.Read(2);

                Assert.Equal("p1", docItem.Parameters[0].Name);
                Assert.Equal("Int", docItem.Parameters[0].Type);
            }

            [Fact]
            public void ShouldReturnStoredProcReturnColumns()
            {
                var returnColumns = new List<KeyValuePair<string, string>>
                {
                    new KeyValuePair<string, string>("CaseId", "int")
                };

                var controller = new DocItemReaderFixture(Db).WithReturnColumns(returnColumns).Subject;

                var docItem = controller.Read(2);

                Assert.Equal("CaseId", docItem.Columns[0].Name);
                Assert.Equal("int", docItem.Columns[0].Type);
            }
        }

        public class ReturnColumnInformationMethod : FactBase
        {
            [Fact]
            public void ShouldSetImageCorrectlyWhenOnlyOneImageIsBeingReturned()
            {
                var f = new DocItemReaderFixture(Db);
                var controller = f.Subject;
                var returnColumns = new[]
                {
                    new ReturnColumnSchema("A", "char", 254),
                    new ReturnColumnSchema("B", "image", 1000)
                };

                f.SqlHelper.DeriveReturnColumnsSchema(null).ReturnsForAnyArgs(returnColumns);

                var docItem = Db.Set<DocItem>().First(_ => _.ItemType == 0);

                var result = controller.ReturnColumnInformation(docItem, true);
                Assert.Equal(result.SqlDescribe, "1,9");
                Assert.Equal(result.SqlInto, ":s[0], :l[0]");
            }

            [Fact]
            public void ShouldSetMultipleLongStringIfImageIsNotExpected()
            {
                var f = new DocItemReaderFixture(Db);
                var controller = f.Subject;
                var returnColumns = new[]
                {
                    new ReturnColumnSchema("A", "ntext", 1000),
                    new ReturnColumnSchema("A", "image", 1000)
                };

                f.SqlHelper.DeriveReturnColumnsSchema(null).ReturnsForAnyArgs(returnColumns);

                var docItem = Db.Set<DocItem>().First(_ => _.ItemType == 0);

                var result = controller.ReturnColumnInformation(docItem, false);
                Assert.Equal(result.SqlDescribe, "4,4");
                Assert.Equal(result.SqlInto, ":l[0], :l[1]");
            }

            [Fact]
            public void ShouldSetTheOutputForDateTimeColumns()
            {
                var f = new DocItemReaderFixture(Db);
                var controller = f.Subject;
                var returnColumns = new[]
                {
                    new ReturnColumnSchema("A", "date", 10),
                    new ReturnColumnSchema("A", "datetime", 10),
                    new ReturnColumnSchema("A", "datetime2", 10),
                    new ReturnColumnSchema("A", "datetimeoffset", 10)
                };

                f.SqlHelper.DeriveReturnColumnsSchema(null).ReturnsForAnyArgs(returnColumns);

                var docItem = Db.Set<DocItem>().First(_ => _.ItemType == 0);

                var result = controller.ReturnColumnInformation(docItem, false);
                Assert.Equal(result.SqlDescribe, "3,3,3,3");
                Assert.Equal(result.SqlInto, ":d[0], :d[1], :d[2], :d[3]");
            }

            [Fact]
            public void ShouldSetTheOutputForNumericColumns()
            {
                var f = new DocItemReaderFixture(Db);
                var controller = f.Subject;
                var returnColumns = new[]
                {
                    new ReturnColumnSchema("A", "int", 10),
                    new ReturnColumnSchema("A", "bit", 10),
                    new ReturnColumnSchema("A", "money", 10),
                    new ReturnColumnSchema("A", "float", 10)
                };

                f.SqlHelper.DeriveReturnColumnsSchema(null).ReturnsForAnyArgs(returnColumns);

                var docItem = Db.Set<DocItem>().First(_ => _.ItemType == 0);

                var result = controller.ReturnColumnInformation(docItem, false);
                Assert.Equal(result.SqlDescribe, "2,2,2,2");
                Assert.Equal(result.SqlInto, ":n[0], :n[1], :n[2], :n[3]");
            }

            [Fact]
            public void ShouldSetTheOutputtoShortStringForUnknownNumericColumns()
            {
                var f = new DocItemReaderFixture(Db);
                var controller = f.Subject;
                var returnColumns = new[]
                {
                    new ReturnColumnSchema("A", "ABC", 10),
                    new ReturnColumnSchema("B", "char", 10)
                };

                f.SqlHelper.DeriveReturnColumnsSchema(null).ReturnsForAnyArgs(returnColumns);

                var docItem = Db.Set<DocItem>().First(_ => _.ItemType == 0);

                var result = controller.ReturnColumnInformation(docItem, false);
                Assert.Equal(result.SqlDescribe, "1,1");
                Assert.Equal(result.SqlInto, ":s[0], :s[1]");
            }
        }

        public class ValidateCaseIdFormat : FactBase
        {

            [Fact]
            public void ShouldValidateCaseIdFormatCorrectly()
            {
                var f = new DocItemReaderFixture(Db);
                var docItem = new DocItem()
                {
                    ItemType = Convert.ToInt16(ItemType.SqlStatement),
                    Sql = @"Select CE.CASEID, 1 as Result From SITECONTROL S join CASEEVENT CE on (CE.EVENTNO=S.COLINTEGER) Where CE.CASEID = :CaseId"
                };

                Assert.True(f.Subject.InvalidFormatCaseIdForCaseValidation(docItem));
            }
        }
    }
}