using System.Linq;
using System.Net;
using System.Web;
using System.Xml.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web.FinancialReports.RevenueAnalysis;
using InprotechKaizen.Model.Accounting;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.FinancialReports.Api
{
    public class RevenueAnalysisControllerFacts
    {
        public class ControllerFacts
        {
            [Fact]
            public void OnlyAuthorisedUserCanAccess()
            {
                var r = TaskSecurity.Secures<RevenueAnalysisController>(ApplicationTask.ViewRevenueAnalysisReport);

                Assert.True(r);
            }
        }

        public class ReportMethod : FactBase
        {
            [Theory]
            [InlineData("")]
            [InlineData(null)]
            public void ThrowsBadRequestIfDebtorNotProvided(string debtorArg)
            {
                var periodStartId = Fixture.Integer();
                var periodEndId = Fixture.Integer();
                var debtorCode = debtorArg;

                var exception = Assert.Throws<HttpException>(() => { new RevenueAnalysisControllerFixture(Db).Subject.Report(periodStartId, periodEndId, debtorCode); });

                Assert.Equal((int) HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("Either an exact debtor code or a debtor code wildcard must be provided.", exception.Message);
            }

            [Fact]
            public void AllowsReporting()
            {
                var startPeriod = new Period
                {
                    StartDate = Fixture.PastDate()
                }.In(Db);

                var endPeriod = new Period
                {
                    StartDate = Fixture.Today()
                }.In(Db);

                var debtorCode = Fixture.String();

                var f = new RevenueAnalysisControllerFixture(Db);

                var configuredReturn = new XElement("any");
                f.RevenueAnalysisReportDataProvider
                 .Fetch(startPeriod, endPeriod, debtorCode)
                 .Returns(configuredReturn);

                var r = f.Subject.Report(startPeriod.Id, endPeriod.Id, debtorCode);

                Assert.Equal(configuredReturn, r);
            }

            [Fact]
            public void AllowsSamePeriodReporting()
            {
                var currentPeriod = new Period
                {
                    StartDate = Fixture.Today()
                }.In(Db);

                var debtorCode = Fixture.String();

                var f = new RevenueAnalysisControllerFixture(Db);

                var configuredReturn = new XElement("any");
                f.RevenueAnalysisReportDataProvider
                 .Fetch(currentPeriod, currentPeriod, debtorCode)
                 .Returns(configuredReturn);

                var r = f.Subject.Report(currentPeriod.Id, currentPeriod.Id, debtorCode);

                Assert.Equal(configuredReturn, r);
            }

            [Fact]
            public void ThrowsBadRequestWhenStartPeriodIsLaterThanEndPeriod()
            {
                var startPeriod = new Period
                {
                    StartDate = Fixture.Today()
                }.In(Db);

                var endPeriod = new Period
                {
                    StartDate = Fixture.PastDate()
                }.In(Db);

                var periodStartId = startPeriod.Id;
                var periodEndId = endPeriod.Id;
                var debtorCode = Fixture.String();

                var exception = Assert.Throws<HttpException>(() => { new RevenueAnalysisControllerFixture(Db).Subject.Report(periodStartId, periodEndId, debtorCode); });

                Assert.Equal((int) HttpStatusCode.BadRequest, exception.GetHttpCode());
                Assert.Equal("From period must be less than To period", exception.Message);
            }

            [Fact]
            public void ThrowsNotFoundExceptionWhenInvalidPeriodIdIsProvided()
            {
                var periodStartId = Fixture.Integer();
                var periodEndId = Fixture.Integer();
                var debtorCode = Fixture.String();

                var exception = Assert.Throws<HttpException>(() => { new RevenueAnalysisControllerFixture(Db).Subject.Report(periodStartId, periodEndId, debtorCode); });

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

                var r = new RevenueAnalysisControllerFixture(Db).Subject.AvailablePeriods();

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

        public class RevenueAnalysisControllerFixture : IFixture<RevenueAnalysisController>
        {
            public RevenueAnalysisControllerFixture(InMemoryDbContext db)
            {
                RevenueAnalysisReportDataProvider = Substitute.For<IRevenueAnalysisReportDataProvider>();

                Subject = new RevenueAnalysisController(db, RevenueAnalysisReportDataProvider);
            }

            public IRevenueAnalysisReportDataProvider RevenueAnalysisReportDataProvider { get; set; }

            public RevenueAnalysisController Subject { get; }
        }
    }
}