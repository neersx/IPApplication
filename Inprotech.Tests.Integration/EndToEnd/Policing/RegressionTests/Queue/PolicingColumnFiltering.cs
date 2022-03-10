using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.Queue
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Regression)]
    public class PolicingColumnFiltering : IntegrationTest
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
        public void TestPolicingColumnFiltering(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            string irnTestRef3, userJohn;
            using (var setup = new QueueDbSetup())
            {
                var colleages = setup.OtherUsers.Create();
                userJohn = colleages.John.Name.LastName;

                setup.EnqueueFor(colleages.John, "on-hold", "due-date-changed", setup.GetCase("test-ref1"));
                setup.EnqueueFor(colleages.John, "on-hold", "due-date-changed", setup.GetCase("test-ref2"));

                var case3 = setup.GetCase("test-ref3");
                irnTestRef3 = case3.Irn;
                setup.EnqueueFor(colleages.Mary, "on-hold", "event-occurred", case3);
                setup.EnqueueFor(colleages.Mary, "in-progress", "event-occurred", setup.GetCase("test-ref4"));
            }

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) => { dashboard.Summary.Total.Link().WithJs().Click(); });

            driver.With<QueuePageObject>((queue, popups) =>
                                         {
                                             Assert.LessOrEqual(4, queue.QueueGrid.MasterRows.Count, "There should be atleast 4 policing items");

                                             queue.QueueGrid.CaseReferenceFilter.Open();
                                             queue.QueueGrid.CaseReferenceFilter.SelectOption(irnTestRef3);
                                             queue.QueueGrid.CaseReferenceFilter.Filter();

                                             Assert.AreEqual(1, queue.QueueGrid.MasterRows.Count, "The case test-ref3 only exists in the policing queue once.");

                                             queue.QueueGrid.CaseReferenceFilter.Open();
                                             queue.QueueGrid.CaseReferenceFilter.Clear();

                                             Assert.IsTrue(queue.QueueGrid.MasterRows.Count >= 4, "There should be 4 policing items after the case filter is cleared.");

                                             queue.QueueGrid.UserFilter.Open();
                                             queue.QueueGrid.UserFilter.SelectOption(userJohn);
                                             queue.QueueGrid.UserFilter.Filter();

                                             Assert.AreEqual(2, queue.QueueGrid.MasterRows.Count, "There are two policing items on queue that John has initiated on.");

                                             queue.QueueGrid.UserFilter.Open();
                                             queue.QueueGrid.UserFilter.Clear();

                                             Assert.IsTrue(queue.QueueGrid.MasterRows.Count >= 4, "There should be 4 policing items after the user filter is cleared.");

                                             queue.QueueGrid.StatusFilter.Open();
                                             queue.QueueGrid.StatusFilter.SelectOption("In Progress");
                                             queue.QueueGrid.StatusFilter.Filter();

                                             Assert.IsTrue(queue.QueueGrid.MasterRows.Count >= 1, "There should be atleast 1 policing items that is in-progress.");

                                             queue.QueueGrid.StatusFilter.Open();
                                             queue.QueueGrid.StatusFilter.Clear();

                                             Assert.IsTrue(queue.QueueGrid.MasterRows.Count >= 4, "There should be 4 policing items after the status filter is cleared.");

                                             queue.QueueGrid.RequestTypeFilter.Open();
                                             queue.QueueGrid.RequestTypeFilter.SelectOption("Event occurred");
                                             queue.QueueGrid.RequestTypeFilter.Filter();

                                             Assert.IsTrue(queue.QueueGrid.MasterRows.Count >= 2, "There should atleast 2 policing items that processing event occurred.");

                                             queue.QueueGrid.RequestTypeFilter.Open();
                                             queue.QueueGrid.RequestTypeFilter.Clear();

                                             Assert.IsTrue(queue.QueueGrid.MasterRows.Count >= 4, "There should be 4 policing items after the type of request filter is cleared.");
                                         });
        }
    }
}
