using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.FinancialReports
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class RevenueAnalysis : IntegrationTest
    {
        TimeRecordingData _dbData;

        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withEntriesToday: true);
            TimeRecordingDbHelper.SetupLastInvoicedDate(_dbData);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [Test]
        public void ReturnsNullIfNoDataAvailable()
        {
            var result = ApiClient.Get<JObject>($"reports/revenueanalysis/report?fromPeriodId=200001&toPeriodId=200012&debtorCodeFilter={_dbData.Debtor.NameCode}");
            Assert.IsEmpty(result["RevenueAnalysisReport"]);
        }

        [Test]
        public void ReturnsDataWhereAvailable()
        {
            var result = ApiClient.Get<JObject>($"reports/revenueanalysis/report?fromPeriodId={_dbData.CurrentPeriod}&toPeriodId={_dbData.CurrentPeriod}&debtorCodeFilter={_dbData.Debtor.NameCode}");
            var revenueAnalysisReport = result["RevenueAnalysisReport"];
            Assert.IsNotNull(revenueAnalysisReport["RevenueAnalysis"]);
            var revenueData = revenueAnalysisReport["RevenueAnalysis"];
            Assert.IsNotNull(revenueData["REVENUE"]);
        }
    }
}
