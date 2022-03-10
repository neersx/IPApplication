using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;
using Office = InprotechKaizen.Model.Cases.Office;

namespace Inprotech.Tests.Web.Picklists
{
    public class TableCodePicklistControllerFacts
    {
        public class SearchMethod : FactBase
        {
            [Theory]
            [InlineData("NoteSharingGroup", 2)]
            [InlineData("EventGroup", 2)]
            [InlineData("Office", 0)]
            public void ReturnsRecordWithMatchingTableType(string tableTypeId, int expected)
            {
                new TableCode(1, (short) TableTypes.NoteSharingGroup, Fixture.String("EventNoteGroup")).In(Db);
                new TableCode(2, (short) TableTypes.NoteSharingGroup, Fixture.String("EventNoteGroup")).In(Db);
                new TableCode(3, (short) TableTypes.EventGroup, Fixture.String("EventGroup")).In(Db);
                new TableCode(4, (short) TableTypes.EventGroup, Fixture.String("EventGroup")).In(Db);

                var f = new TableCodePicklistControllerFixture(Db);
                var result = f.Subject.Search(null, null, tableTypeId).Data;
                Assert.Equal(result.Count(), expected);
            }

            [Theory]
            [InlineData("C", 3)]
            [InlineData("N", 1)]
            public void ReturnsRecordWithMatchingUserCode(string userCode, int expected)
            {
                new TableCode(1, (short) TableTypes.ValidateColumn, Fixture.String("CaseRef"), "C").In(Db);
                new TableCode(2, (short) TableTypes.ValidateColumn, Fixture.String("Name"), "N").In(Db);
                new TableCode(3, (short) TableTypes.ValidateColumn, Fixture.String("Description"), "C").In(Db);
                new TableCode(4, (short) TableTypes.ValidateColumn, Fixture.String("Goods"), "C").In(Db);

                var f = new TableCodePicklistControllerFixture(Db);
                var result = f.Subject.Search(null, null, "ValidateColumn", userCode).Data;
                Assert.Equal(result.Count(), expected);
            }

            [Theory]
            [InlineData("NoteSharingGroup", new[] {999, 888}, 2)]
            [InlineData("EventGroup", new[] {777, 123, 456}, 3)]
            public void ReturnsListOfIds(string tableTypeId, int[] ids, int expected)
            {
                new TableCode(999, (short) TableTypes.NoteSharingGroup, Fixture.String("EventNoteGroup")).In(Db);
                new TableCode(888, (short) TableTypes.NoteSharingGroup, Fixture.String("EventNoteGroup")).In(Db);
                new TableCode(777, (short) TableTypes.EventGroup, Fixture.String("EventGroup")).In(Db);
                new TableCode(123, (short) TableTypes.EventGroup, Fixture.String("EventGroup")).In(Db);
                new TableCode(456, (short) TableTypes.EventGroup, Fixture.String("EventGroup")).In(Db);
                var f = new TableCodePicklistControllerFixture(Db);
                var result = f.Subject.Search(null, null, tableTypeId).Ids;
                Assert.Equal(expected, ((int[]) result).Length);
                Assert.True(((int[]) result).All(i => ids.Contains(i)));
            }

            [Fact]
            public void ReturnsOfficeDataFromOfficeTable()
            {
                new TableType {Id = (int) TableTypes.Office, DatabaseTable = "Office", Name = Fixture.String("Office")}.In(Db);
                new Office(1, "Case Office").In(Db);
                var f = new TableCodePicklistControllerFixture(Db);
                var result = f.Subject.Search(null, null, "Office").Data;
                Assert.Single(result);
            }

            [Fact]
            public void ShouldOrderByExactMatchAndFollowedByDescriptionCode()
            {
                var builder = new TableCodeBuilder
                {
                    TableType = (short) TableTypes.NoteSharingGroup,
                    Description = "a2"
                };

                builder.Build().In(Db);
                builder.Description = "a1";
                builder.Build().In(Db);
                builder.Description = "a";
                builder.Build().In(Db);

                var f = new TableCodePicklistControllerFixture(Db);
                var r = f.Subject.Search(null, "a", TableTypes.NoteSharingGroup.ToString()).Data.ToArray();

                Assert.Equal(3, r.Count());
                Assert.Equal("a", ((TableCodePicklistController.TableCodePicklistItem) r[0]).Value);
                Assert.Equal("a1", ((TableCodePicklistController.TableCodePicklistItem) r[1]).Value);
                Assert.Equal("a2", ((TableCodePicklistController.TableCodePicklistItem) r[2]).Value);
            }

            [Fact]
            public void ShouldSearchForDescription()
            {
                var id = new TableCode(1, (short) TableTypes.NoteSharingGroup, "ab").In(Db).Id;
                var f = new TableCodePicklistControllerFixture(Db);
                var r = f.Subject.Search(null, "b", TableTypes.NoteSharingGroup.ToString()).Data.Single();
                Assert.Equal(id, ((TableCodePicklistController.TableCodePicklistItem) r).Key);
            }

            [Fact]
            public void ThrowsExceptionForInvalidTableType()
            {
                new TableCode(1, (short) TableTypes.NoteSharingGroup, "ab").In(Db);
                var f = new TableCodePicklistControllerFixture(Db);
                Assert.Throws<ArgumentException>(
                                                 () => { f.Subject.Search(null, "b", Fixture.String("InvalidTableType")); });
            }
        }

        public class Maintenance : FactBase
        {
            [Fact]
            public void AddsNewTableCode()
            {
                var e = new TableCodePicklistController.TableCodePicklistItem
                {
                    Code = Fixture.String(),
                    Value = Fixture.String(),
                    TypeId = Fixture.Short()
                };
                var f = new TableCodePicklistControllerFixture(Db);
                f.Subject.AddOrDuplicate(e);
                f.TableCodePicklistMaintenance.Received(1).Add(e);
            }

            [Fact]
            public void DeletesExistingTableCode()
            {
                var e = new TableCodePicklistController.TableCodePicklistItem
                {
                    Key = Fixture.Integer(),
                    Code = Fixture.String(),
                    Value = Fixture.String(),
                    TypeId = Fixture.Short()
                };
                var f = new TableCodePicklistControllerFixture(Db);
                f.Subject.Delete(e.Key);
                f.TableCodePicklistMaintenance.Received(1).Delete(e.Key);
            }

            [Fact]
            public void UpdatesExistingTableCode()
            {
                var id = Fixture.Integer();
                var e = new TableCodePicklistController.TableCodePicklistItem
                {
                    Key = id,
                    Code = Fixture.String(),
                    Value = Fixture.String(),
                    TypeId = Fixture.Short()
                };
                var f = new TableCodePicklistControllerFixture(Db);
                f.Subject.Update(id, e);
                f.TableCodePicklistMaintenance.Received(1).Update(e);
            }
        }

        public class GetTableCode : FactBase
        {
            [Fact]
            public void ReturnsErrorWhenNotFound()
            {
                var noneExistentId = Fixture.Integer();
                new TableCode(noneExistentId + 1, (short) TableTypes.NoteSharingGroup, Fixture.String("EventNoteGroup")).In(Db);
                new TableCode(noneExistentId + 2, (short) TableTypes.EventGroup, Fixture.String("EventGroup")).In(Db);
                var f = new TableCodePicklistControllerFixture(Db);
                Assert.Throws<HttpException>(() => { f.Subject.TableCode(noneExistentId); });
            }

            [Fact]
            public void ReturnsTableCodeMatchingId()
            {
                var existingId = Fixture.Integer();
                var tableCode = new TableCode(existingId, (short) TableTypes.NoteSharingGroup, Fixture.String("EventNoteGroup"), Fixture.String()).In(Db);
                new TableCode(existingId + 1, (short) TableTypes.EventGroup, Fixture.String("EventGroup")).In(Db);
                var f = new TableCodePicklistControllerFixture(Db);
                var r = f.Subject.TableCode(existingId);
                Assert.Equal(existingId, r.Data.Key);
                Assert.Equal(tableCode.Id, r.Data.Key);
                Assert.Equal(tableCode.TableTypeId, r.Data.TypeId);
                Assert.Equal(tableCode.Name, r.Data.Value);
                Assert.Equal(tableCode.UserCode, r.Data.Code);
                f.PreferredCultureResolver.Received(1).Resolve();
            }
        }
    }

    public class TableCodePicklistControllerFixture : IFixture<TableCodePicklistController>
    {
        public TableCodePicklistControllerFixture(InMemoryDbContext Db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            TableCodePicklistMaintenance = Substitute.For<ITableCodePicklistMaintenance>();
            TableCodePicklistMaintenance.Update(Arg.Any<TableCodePicklistController.TableCodePicklistItem>()).Returns(new { });
            TableCodePicklistMaintenance.Add(Arg.Any<TableCodePicklistController.TableCodePicklistItem>()).Returns(new { });
            TableCodePicklistMaintenance.Delete(Arg.Any<int>()).Returns(new { });
            CommonQueryService = Substitute.For<ICommonQueryService>();
            CommonQueryParameters = CommonQueryParameters.Default;
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

            Subject = new TableCodePicklistController(Db, PreferredCultureResolver, TableCodePicklistMaintenance);
            CommonQueryService.Filter(Arg.Any<IEnumerable<TableCodePicklistController.TableCodePicklistItem>>(), Arg.Any<CommonQueryParameters>()).Returns(x => x[0]);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public ITableCodePicklistMaintenance TableCodePicklistMaintenance { get; set; }
        public ICommonQueryService CommonQueryService { get; set; }
        public CommonQueryParameters CommonQueryParameters { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }

        public TableCodePicklistController Subject { get; }
    }
}