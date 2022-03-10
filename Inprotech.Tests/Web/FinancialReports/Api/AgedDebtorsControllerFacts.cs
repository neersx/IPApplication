using System.Linq;
using System.Net;
using System.Web;
using System.Xml.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.FinancialReports.AgeDebtorAnalysis;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.FinancialReports.Api
{
    public class AgedDebtorsControllerFacts
    {
        public class ControllerFacts
        {
            [Fact]
            public void OnlyAuthorisedUserCanAccess()
            {
                var r = TaskSecurity.Secures<AgedDebtorsController>(ApplicationTask.ViewAgedDebtorsReport);

                Assert.True(r);
            }
        }

        public class ReportMethod : FactBase
        {
            [Theory]
            [InlineData("")]
            [InlineData(null)]
            public void ThrowsBadRequestIfEntityNotProvided(string entityArg)
            {
                var periodId = Fixture.Integer();
                var entity = entityArg;
                var debtorCode = Fixture.String();
                var category = Fixture.String();

                var exception = Assert.Throws<HttpException>(() => { new AgedDebtorsControllerFixture(Db).Subject.Report(periodId, entity, debtorCode, category); });

                Assert.Equal((int) HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("Either an exact entity name or a wildcard must be provided.", exception.Message);
            }

            [Theory]
            [InlineData("")]
            [InlineData(null)]
            public void ThrowsBadRequestIfCategoryNotProvided(string categoryArg)
            {
                var periodId = Fixture.Integer();
                var entity = Fixture.String();
                var debtorCode = Fixture.String();
                var category = categoryArg;

                var exception = Assert.Throws<HttpException>(() => { new AgedDebtorsControllerFixture(Db).Subject.Report(periodId, entity, debtorCode, category); });

                Assert.Equal((int) HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("Either an exact category name or a wildcard must be provided.", exception.Message);
            }

            [Theory]
            [InlineData("")]
            [InlineData(null)]
            public void ThrowsBadRequestIfDebtorNotProvided(string debtorArg)
            {
                var periodId = Fixture.Integer();
                var entity = Fixture.String();
                var debtorCode = debtorArg;
                var category = Fixture.String();

                var exception = Assert.Throws<HttpException>(() => { new AgedDebtorsControllerFixture(Db).Subject.Report(periodId, entity, debtorCode, category); });

                Assert.Equal((int) HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("Either an exact debtor code or a debtor code wildcard must be provided.", exception.Message);
            }

            [Fact]
            public void ReturnsDataFromReportDataProvider()
            {
                var period = new Period().In(Db);
                var entity = Fixture.String();
                var debtorCode = Fixture.String();
                var category = Fixture.String();

                var fixture = new AgedDebtorsControllerFixture(Db);

                var configuredReturn = new XElement("any");

                fixture.AgedDebtorsReportDataProvider
                       .Fetch(period, entity, debtorCode, category)
                       .Returns(configuredReturn);

                var r = fixture.Subject.Report(period.Id, entity, debtorCode, category);

                fixture.AgedDebtorsReportDataProvider.Received(1).Fetch(period, entity, debtorCode, category);

                Assert.Equal(configuredReturn, r);
            }

            [Fact]
            public void ThrowsNotFoundIfPeriodSpecifiedDoNotExist()
            {
                var periodId = Fixture.Integer();
                var entity = Fixture.String();
                var debtorCode = Fixture.String();
                var category = Fixture.String();

                var exception = Assert.Throws<HttpException>(() => { new AgedDebtorsControllerFixture(Db).Subject.Report(periodId, entity, debtorCode, category); });

                Assert.Equal((int) HttpStatusCode.NotFound, exception.GetHttpCode());
                Assert.Equal("No such period", exception.Message);
            }
        }

        public class AvailablePeriodsMethod : FactBase
        {
            [Fact]
            public void ReturnsAvailablePeriods()
            {
                var ap = new[]
                {
                    new Period {Label = Fixture.String()}.In(Db),
                    new Period {Label = Fixture.String()}.In(Db),
                    new Period {Label = Fixture.String()}.In(Db)
                };

                var extract = ap.Select(_ => new
                                {
                                    _.Id,
                                    _.Label
                                })
                                .ToArray();

                var r = new AgedDebtorsControllerFixture(Db).Subject.AvailablePeriods();

                var rExtract = r.Elements("Period")
                                .Select(_ => new
                                {
                                    Id = (int) _.Element("Id"),
                                    Label = (string) _.Element("Label")
                                });

                Assert.Equal(extract, rExtract);
                Assert.Equal("AvailablePeriods", r.Name);
            }
        }

        public class AvailableEntitiesMethod : FactBase
        {
            [Theory]
            [InlineData(null)]
            [InlineData(false)]
            public void NonEntityAreNotAvailable(bool? entityFlag)
            {
                new SpecialName(entityFlag, new Name {LastName = Fixture.String()}.In(Db)).In(Db);

                var r = new AgedDebtorsControllerFixture(Db).Subject.AvailableEntities();

                Assert.Empty(r.Elements("Entity"));
            }

            [Fact]
            public void ReturnsAvailableEntities()
            {
                var ae = new[]
                {
                    new SpecialName(true, new Name {LastName = Fixture.String()}.In(Db)).In(Db),
                    new SpecialName(true, new Name {LastName = Fixture.String()}.In(Db)).In(Db),
                    new SpecialName(true, new Name {LastName = Fixture.String()}.In(Db)).In(Db)
                };

                var extract = ae.Select(_ => new
                                {
                                    _.Id,
                                    Name = _.EntityName.LastName
                                })
                                .ToArray();

                var r = new AgedDebtorsControllerFixture(Db).Subject.AvailableEntities();

                var rExtract = r.Elements("Entity")
                                .Select(_ => new
                                {
                                    Id = (int) _.Element("Id"),
                                    Name = (string) _.Element("Name")
                                });

                Assert.Equal(extract, rExtract);
                Assert.Equal("AvailableEntities", r.Name);
            }
        }

        public class AvailableCategoriesMethod : FactBase
        {
            [Fact]
            public void OtherTableCodesAreNotReturned()
            {
                var tableType = Fixture.Short();
                while (tableType == (short) ProtectedTableTypes.Category)
                    tableType = Fixture.Short();

                new TableCodeBuilder {TableType = tableType}.Build().In(Db);

                var r = new AgedDebtorsControllerFixture(Db).Subject.AvailableCategories();

                Assert.Empty(r.Elements("Category"));
            }

            [Fact]
            public void ReturnsAvailableCategories()
            {
                var ac = new[]
                {
                    new TableCodeBuilder {TableType = (short) ProtectedTableTypes.Category}.Build().In(Db),
                    new TableCodeBuilder {TableType = (short) ProtectedTableTypes.Category}.Build().In(Db),
                    new TableCodeBuilder {TableType = (short) ProtectedTableTypes.Category}.Build().In(Db)
                };

                var extract = ac.Select(_ => new
                                {
                                    _.Id,
                                    _.Name
                                })
                                .ToArray();

                var r = new AgedDebtorsControllerFixture(Db).Subject.AvailableCategories();

                var rExtract = r.Elements("Category")
                                .Select(_ => new
                                {
                                    Id = (int) _.Element("Id"),
                                    Name = (string) _.Element("Name")
                                });

                Assert.Equal(extract, rExtract);
                Assert.Equal("AvailableCategories", r.Name);
            }
        }

        public class AgedDebtorsControllerFixture : IFixture<AgedDebtorsController>
        {
            public AgedDebtorsControllerFixture(InMemoryDbContext db)
            {
                AgedDebtorsReportDataProvider =
                    Substitute.For<IAgedDebtorsReportDataProvider>();

                Subject = new AgedDebtorsController(db, AgedDebtorsReportDataProvider);
            }

            public IAgedDebtorsReportDataProvider AgedDebtorsReportDataProvider { get; set; }

            public AgedDebtorsController Subject { get; }
        }
    }
}