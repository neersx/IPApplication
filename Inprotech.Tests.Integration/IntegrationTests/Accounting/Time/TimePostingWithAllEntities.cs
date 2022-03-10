using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Time
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class TimePostingWithAllEntities : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            AccountingDbHelper.SetupCaseOfficeEntity(true, false);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [Test]
        public void ReturnAllAvailableEntitiesIfCaseOfficeEntityNotAvailable()
        {
            var result = ApiClient.Get<JObject>("accounting/time-posting/view");
            Assert.IsTrue(result["entities"].Any());
            Assert.AreEqual(false, (bool) result["postToCaseOfficeEntity"]);
        }
    }
}