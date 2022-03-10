using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Time
{
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(14)]
    public class TimePostingEntityFromCaseOffice : IntegrationTest
    {
        TimeRecordingData _data;

        [SetUp]
        public void Setup()
        {
            _data = TimeRecordingDbHelper.Setup();
            AccountingDbHelper.SetupCaseOfficeEntity(true, true);
            AccountingDbHelper.SetupPeriod();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [Test]
        public void ReturnsErrorWhenPosting()
        {
            var result = ApiClient.Post<JObject>("accounting/time-posting/post", "{entityKey: null, selectedDates :['"+DateTime.Now.ToShortTimeString()+"'], staffNameId: "+_data.StaffName.Id+", warningAccepted: true}");
            Assert.AreEqual(true, (bool) result["hasOfficeEntityError"]);
        }

        [Test]
        public void HideEntitiesIfCaseOfficeEntityEnabled()
        {
            var result = ApiClient.Get<JObject>("accounting/time-posting/view");
            Assert.AreEqual(0, result["entities"].Count());
            Assert.AreEqual(true, (bool) result["postToCaseOfficeEntity"]);
        }

        [Test]
        public void SendsToBackgroundForProcessing()
        {
            var result = ApiClient.Post<JObject>("accounting/time-posting/post", "{entityKey: null, selectedDates :null, staffNameId: "+_data.StaffName.Id+", warningAccepted: true}");
            Assert.AreEqual(true, (bool) result["isBackground"]);
        }
    }
}