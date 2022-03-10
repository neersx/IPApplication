using System;
using System.Collections;
using System.Linq;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Policing;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Policing.Graphs
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class PolicingGraph : IntegrationTest
    {
        [Test]
        public void CheckCurrentQueueStatus()
        {
            using (var setup = new PolicingGraphDbSetup())
            {
                try
                {
                    setup.StopModificationTrigger();

                    var now = DateTime.Now;

                    now = now.AddTicks(-now.Ticks%TimeSpan.TicksPerSecond);
                    //Waiting to start
                    // < 2 mins
                    setup.EnqueueFor("waiting-to-start", "designated-country-change", now, "testW1");
                    setup.EnqueueFor("waiting-to-start", "due-date-recalculation", now, "testW2");
                    setup.EnqueueFor("waiting-to-start", "patent-term-adjustment", now, "testW3");

                    // < 2 mins and < 20 mins
                    setup.EnqueueFor("waiting-to-start", "designated-country-change", now.AddMinutes(-8), "testW4");

                    // > 20 mins
                    setup.EnqueueFor("waiting-to-start", "designated-country-change", now.AddMinutes(-21), "testW5");
                    setup.EnqueueFor("waiting-to-start", "patent-term-adjustment", now.AddMinutes(-21), "testW6");

                    //In Progress items
                    // < 2 mins
                    setup.EnqueueFor("in-progress", "designated-country-change", now, "testIP1");

                    // < 2 mins and < 20 mins
                    setup.EnqueueFor("in-progress", "open-action", now.AddMinutes(-3), "testIP2");
                    setup.EnqueueFor("in-progress", "designated-country-change", now.AddMinutes(-8), "testIP3");

                    // > 20 mins
                    setup.EnqueueFor("in-progress", "patent-term-adjustment", now.AddMinutes(-25), "testIP4");

                    //Error Items
                    // < 2 mins
                    var errorItem1 = setup.EnqueueFor("in-error", "open-action", now.AddMinutes(-1), "testE1");
                    setup.CreateErrorFor(errorItem1);

                    // > 20 mins
                    var errorItem2 = setup.EnqueueFor("in-error", "patent-term-adjustment", now.AddMinutes(-23), "testE2");
                    setup.CreateErrorFor(errorItem2);

                    //Unsuccessful
                    //< 2 mins and < 20 mins
                    setup.EnqueueFor("in-error", "designated-country-change", now.AddMinutes(-4), "testU1");
                    setup.EnqueueFor("in-error", "patent-term-adjustment", now.AddMinutes(-5), "testU2");

                    // > 20 mins
                    setup.EnqueueFor("in-error", "patent-term-adjustment", now.AddMinutes(-23), "testU3");
                    setup.EnqueueFor("in-error", "patent-term-adjustment", now.AddMinutes(-24), "testU4");
                    setup.EnqueueFor("in-error", "patent-term-adjustment", now.AddMinutes(-25), "testU5");

                    //Blocked
                    //// < 2 mins
                    setup.EnqueueFor("waiting-to-start", "patent-term-adjustment", now, "testE1");

                    //////< 2 mins and < 20 mins
                    setup.EnqueueFor("waiting-to-start", "patent-term-adjustment", now.AddMinutes(-3), "testIP2");

                    //// > 20 mins
                    setup.EnqueueFor("waiting-to-start", "designated-country-change", now.AddMinutes(-23), "testE1");
                    setup.EnqueueFor("waiting-to-start", "designated-country-change", now.AddMinutes(-24), "testIP2");
                }
                finally
                {
                    setup.EnableModificationTrigger();
                }
            }

            var result = ApiClient.Get<DashboardData>("policing/dashboard/view");

            Assert.IsTrue(3 <= result.Summary.WaitingToStart.Fresh, "Summary - Waiting to Start - Fresh items >= 3");
            Assert.IsTrue(1 <= result.Summary.WaitingToStart.Tolerable, "Summary - Waiting to Start - Tolerable items >= 1");
            Assert.IsTrue(2 <= result.Summary.WaitingToStart.Stuck, "Summary - Waiting to Start - Stuck items >= 2");

            Assert.IsTrue(1 <= result.Summary.InProgress.Fresh, "Summary - Inprogress - Fresh items >= 1");
            Assert.IsTrue(2 <= result.Summary.InProgress.Tolerable, "Summary - Inprogress - Tolerable items >= 2");
            Assert.IsTrue(1 <= result.Summary.InProgress.Stuck, "Summary - Inprogress - Stuck items >= 1");

            Assert.IsTrue(1 <= result.Summary.InError.Fresh, "Summary - In Error - Fresh items >= 1");
            Assert.IsTrue(0 <= result.Summary.InError.Tolerable, "Summary - In Error - Tolerable items >= 0");
            Assert.IsTrue(1 <= result.Summary.InError.Stuck, "Summary - In Error - Stuck items >= 1");

            Assert.IsTrue(0 <= result.Summary.Failed.Fresh, "Summary - Failed - Fresh items >= 0");
            Assert.IsTrue(2 <= result.Summary.Failed.Tolerable, "Summary - Failed - Fresh items >= 2");
            Assert.IsTrue(3 <= result.Summary.Failed.Stuck, "Summary - Failed - Fresh items >= 3");

            Assert.IsTrue(1 <= result.Summary.Blocked.Fresh);
            Assert.IsTrue(1 <= result.Summary.Blocked.Tolerable);
            Assert.IsTrue(2 <= result.Summary.Blocked.Stuck);
        }

        [Test]
        public void CheckQueueRate()
        {
            using (var setup = new PolicingGraphDbSetup())
            {
                setup.EnsureLogExists();

                var now = DateTime.Now;
                now = now.AddTicks(-now.Ticks%TimeSpan.TicksPerSecond);

                //This wil add - assume currently its 2.10PM
                //2PM : 10 inserted and 1 deleted
                //1PM : 20 inserted and 2 deleted
                //12PM: 30 inserted and 3 deleted
                //and so on
                for (var i = 1; i < 11; i++)
                {
                    var forHour = now.AddHours(-1*(i - 1));
                    Enumerable.Range(1, i*10)
                              .ToList()
                              .ForEach(x => { setup.AddLogForInsert(forHour); });

                    Enumerable.Range(1, i)
                              .ToList()
                              .ForEach(x => { setup.AddLogForDelete(forHour); });
                }

                var result = ApiClient.Get<DashboardData>("policing/dashboard/view");

                var trend = (JObject) result.Trend;
                Assert.IsTrue((bool)trend["historicalDataAvailable"]);
                Assert.IsFalse((bool)trend["hasError"]);

                var j = 0;
                foreach (var item in (IEnumerable)trend["items"].Reverse())
                {
                    var currentSlot = (JObject) item;
                    var timeSlot = (DateTime)currentSlot["timeSlot"];
                    if (timeSlot.Hour != now.Hour + 1)
                        continue;

                    Assert.AreEqual(now.Hour+1 - j++ , timeSlot.Hour);
                    Assert.IsTrue(j*10 <= (int)currentSlot["enterQueue"]);
                    Assert.IsTrue(j <= (int)currentSlot["exitQueue"]);
                }
            }
        }
    }
}