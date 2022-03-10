using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.Queue
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Regression)]
    public class QueueFiltering : IntegrationTest
    {
        TestUser _loginUser;

        [SetUp]
        public void CreatePoliceAdminUser()
        {
            _loginUser = new Users()
                .WithPermission(ApplicationTask.PolicingAdministration)
                .Create();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PolicingCascadingColumnFiltering(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            string irnTestRef2;
            OtherUserBuilder.OtherUser colleages;
            using (var setup = new QueueDbSetup())
            {
                colleages = setup.OtherUsers.Create();

                var case2 = setup.GetCase("test-ref2");
                irnTestRef2 = case2.Irn;

                setup.EnqueueFor(colleages.John, "waiting-to-start", "open-action", setup.GetCase("test-ref1"));
                setup.EnqueueFor(colleages.Mary, "waiting-to-start", "due-date-changed", case2);
                setup.EnqueueFor(colleages.John, "on-hold", "due-date-changed", setup.GetCase("test-ref2"));
                setup.EnqueueFor(colleages.Mary, "on-hold", "open-action", setup.GetCase("test-ref1"));
            }

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) => { dashboard.Summary.Total.Link().WithJs().Click(); });

            driver.With<QueuePageObject>
                ((queue, popups) =>
                 {
                     Assert.IsTrue(queue.QueueGrid.MasterRows.Count >= 4);

                     queue.QueueGrid.UserFilter.Open();
                     queue.QueueGrid.UserFilter.SelectOption(colleages.John.Name.LastName);
                     queue.QueueGrid.UserFilter.Filter();

                     Assert.AreEqual(2, queue.QueueGrid.MasterRows.Count, "There are two policing requests initiated by John");

                     queue.QueueGrid.CaseReferenceFilter.Open();
                     Assert.AreEqual(2, queue.QueueGrid.CaseReferenceFilter.ItemCount, "The cases test-ref1 and test-ref2 should exist");

                     queue.QueueGrid.CaseReferenceFilter.SelectOption(irnTestRef2);
                     queue.QueueGrid.CaseReferenceFilter.Filter();
                     Assert.AreEqual(1, queue.QueueGrid.MasterRows.Count, "There should only be one test-ref2 that is actioned by John.");

                     queue.QueueGrid.UserFilter.Open();
                     Assert.AreEqual(2, queue.QueueGrid.UserFilter.ItemCount, "The users Mary and John should exist due to test-ref2 is selected.");
                     Assert.AreEqual(1, queue.QueueGrid.UserFilter.CheckedItemCount, "The users John should already be selected.");
                     queue.QueueGrid.UserFilter.Dismiss();

                     queue.QueueGrid.RequestTypeFilter.Open();
                     Assert.AreEqual(1, queue.QueueGrid.RequestTypeFilter.ItemCount, "The 'due-date-changed' should exists in this filter.");
                     queue.QueueGrid.RequestTypeFilter.Dismiss();

                     queue.QueueGrid.UserFilter.Open();
                     queue.QueueGrid.UserFilter.SelectOption(colleages.Mary.Name.LastName);
                     queue.QueueGrid.UserFilter.Filter();

                     Assert.AreEqual(2, queue.QueueGrid.MasterRows.Count);
                     queue.QueueGrid.RequestTypeFilter.Open();
                     Assert.AreEqual(1, queue.QueueGrid.RequestTypeFilter.ItemCount, "The 'due-date-changed' should exists in this filter.");

                     queue.QueueGrid.RequestTypeFilter.Dismiss();
                     queue.QueueGrid.CaseReferenceFilter.Open();

                     Assert.AreEqual(2, queue.QueueGrid.CaseReferenceFilter.ItemCount, "The cases test-ref1 and test-ref2 should exist due to both Marry and John works on it.");
                 });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PolicingStaleColumnFiltering(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            string testRef1Irn, testRef5Irn;
            using (var setup = new QueueDbSetup())
            {
                var colleages = setup.OtherUsers.Create();

                var case1 = setup.GetCase("test-ref1");
                testRef1Irn = case1.Irn;

                setup.EnqueueFor(colleages.John, "in-error", "open-action", case1);
                setup.EnqueueFor(colleages.Mary, "waiting-to-start", "due-date-changed", setup.GetCase("test-ref2"));
                setup.EnqueueFor(colleages.Mary, "waiting-to-start", "due-date-changed", setup.GetCase("test-ref3"));
                setup.EnqueueFor(colleages.Mary, "waiting-to-start", "due-date-changed", setup.GetCase("test-ref4"));
            }

            const int autoRefreshSeconds = 5;
            SignIn(driver, "/#/policing-queue/all?rinterval=" + autoRefreshSeconds, _loginUser.Username, _loginUser.Password);

            driver.With<QueuePageObject>((queue, popups) =>
                                         {
                                             Assert.IsTrue(queue.QueueGrid.MasterRows.Count >= 4, "Records displayed are 4 or more");

                                             WaitHelper.WaitForGridLoadComplete(driver, queue.QueueGrid);
                                             queue.QueueGrid.CaseReferenceFilter.Open();
                                             var previousItemCount = queue.QueueGrid.CaseReferenceFilter.ItemCount;
                                             queue.QueueGrid.CaseReferenceFilter.SelectOption(testRef1Irn);
                                             queue.QueueGrid.CaseReferenceFilter.Filter();

                                             WaitHelper.WaitForGridLoadComplete(driver, queue.QueueGrid);
                                             Assert.AreEqual(1, queue.QueueGrid.MasterRows.Count, "Single record displayed after filtering");

                                             using (var setup = new QueueDbSetup())
                                             {
                                                 setup.DeletePolicingItemFor(testRef1Irn);

                                                 var colleages = setup.OtherUsers.Create();
                                                 var case5 = setup.GetCase("test-ref5");
                                                 testRef5Irn = case5.Irn;
                                                 setup.EnqueueFor(colleages.Mary, "waiting-to-start", "due-date-changed", case5);
                                             }

                                             driver.Wait().ForTrue(() => queue.QueueGrid.MasterRows.Count == 0, 10000, 100);

                                             WaitHelper.WaitForGridLoadComplete(driver, queue.QueueGrid);
                                             queue.QueueGrid.CaseReferenceFilter.Open();
                                             Assert.AreEqual(previousItemCount + 1, queue.QueueGrid.CaseReferenceFilter.ItemCount);
                                             Assert.AreEqual(1, queue.QueueGrid.CaseReferenceFilter.CheckedItemCount);

                                             queue.QueueGrid.CaseReferenceFilter.SelectOption(testRef5Irn);
                                             queue.QueueGrid.CaseReferenceFilter.Filter();

                                             driver.Wait().ForTrue(() => queue.QueueGrid.MasterRows.Count == 1);
                                         });
        }
    }
}