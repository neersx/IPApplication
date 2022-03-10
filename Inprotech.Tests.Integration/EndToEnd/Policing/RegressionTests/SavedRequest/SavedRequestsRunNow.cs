using System;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Policing;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.SavedRequest
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestType(TestTypes.Regression)]
    public class SavedRequestsRunNow : SavedRequestsTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void RunNowConfirmationDates(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var savedRequest = new SavedRequestsPageObject(driver);
            var today = DateTime.Now;

            const string dateFormat = "dd-MMM-yyyy";

            using (var setup = new RequestsDbSetup())
            {
                setup.Insert(new PolicingRequest(null) {Name = " a", DateEntered = Helpers.UniqueDateTime()});
                setup.Insert(new PolicingRequest(null) {Name = " b", DateEntered = Helpers.UniqueDateTime(), NoOfDays = 5});
                setup.Insert(new PolicingRequest(null) {Name = " c", DateEntered = Helpers.UniqueDateTime(), NoOfDays = -6});
                setup.Insert(new PolicingRequest(null) {Name = " d", DateEntered = Helpers.UniqueDateTime(), FromDate = DateTime.Now.AddDays(-5), NoOfDays = 2});
                setup.Insert(new PolicingRequest(null) {Name = " e", DateEntered = Helpers.UniqueDateTime(), UntilDate = DateTime.Now.AddDays(2)});
            }

            SignIn(driver, "/#/policing-saved-requests", _loginUser.Username, _loginUser.Password);

            savedRequest.SavedRequestGrid.SelectIpCheckbox(0);

            savedRequest.ActionMenu.OpenOrClose();
            savedRequest.ActionMenu.RunNowOption().WithJs().Click();
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.StartDate().Text, "Oldest");
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.UntilDate().Text, today.ToString(dateFormat));
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.ForDays().Text, "Varies");
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.DateLetters().Text, today.ToString(dateFormat));
            savedRequest.RunNowConfirmationModal.Cancel().ClickWithTimeout();
            savedRequest.SavedRequestGrid.SelectIpCheckbox(0);

            savedRequest.SavedRequestGrid.SelectIpCheckbox(1);
            savedRequest.ActionMenu.OpenOrClose();
            savedRequest.ActionMenu.RunNowOption().WithJs().Click();
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.StartDate().Text, today.ToString(dateFormat));
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.UntilDate().Text, today.AddDays(5 - 1).ToString(dateFormat));
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.ForDays().Text, "5");
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.DateLetters().Text, today.ToString(dateFormat));
            savedRequest.RunNowConfirmationModal.Cancel().ClickWithTimeout();
            savedRequest.SavedRequestGrid.SelectIpCheckbox(1);

            savedRequest.SavedRequestGrid.SelectIpCheckbox(2);
            savedRequest.ActionMenu.OpenOrClose();
            savedRequest.ActionMenu.RunNowOption().WithJs().Click();
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.StartDate().Text, today.AddDays(-6).ToString(dateFormat));
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.UntilDate().Text, today.ToString(dateFormat));
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.ForDays().Text, "-6");
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.DateLetters().Text, today.ToString(dateFormat));
            savedRequest.RunNowConfirmationModal.Cancel().ClickWithTimeout();
            savedRequest.SavedRequestGrid.SelectIpCheckbox(2);

            savedRequest.SavedRequestGrid.SelectIpCheckbox(3);
            savedRequest.ActionMenu.OpenOrClose();
            savedRequest.ActionMenu.RunNowOption().WithJs().Click();
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.StartDate().Text, DateTime.Now.AddDays(-5).ToString(dateFormat));
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.UntilDate().Text, today.ToString(dateFormat));
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.ForDays().Text, "2");
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.DateLetters().Text, today.ToString(dateFormat));
            savedRequest.RunNowConfirmationModal.Cancel().ClickWithTimeout();
            savedRequest.SavedRequestGrid.SelectIpCheckbox(3);

            savedRequest.SavedRequestGrid.SelectIpCheckbox(4);
            savedRequest.ActionMenu.OpenOrClose();
            savedRequest.ActionMenu.RunNowOption().WithJs().Click();
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.StartDate().Text, "Oldest");
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.UntilDate().Text, DateTime.Now.AddDays(2).ToString(dateFormat));
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.ForDays().Text, "Varies");
            Assert.AreEqual(savedRequest.RunNowConfirmationModal.DateLetters().Text, today.ToString(dateFormat));
            savedRequest.RunNowConfirmationModal.Cancel().ClickWithTimeout();
            savedRequest.SavedRequestGrid.SelectIpCheckbox(4);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void RunNowSelectedRequestWithAffectedCases(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var savedRequest = new SavedRequestsPageObject(driver);
            var popups = new CommonPopups(savedRequest.Driver);
            using (var setup = new RequestsDbSetup())
            {
                setup.PolicingRequestAndOpenAction();
            }

            SignIn(driver, "/#/policing-saved-requests", _loginUser.Username, _loginUser.Password);

            savedRequest.SavedRequestGrid.SelectIpCheckbox(0);

            savedRequest.ActionMenu.OpenOrClose();
            savedRequest.ActionMenu.RunNowOption().ClickWithTimeout();

            savedRequest.RunNowConfirmationModal.Proceed().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            Assert.NotNull(popups.FlashAlert());

            savedRequest.SavedRequestGrid.SelectIpCheckbox(0);

            savedRequest.ActionMenu.OpenOrClose();
            savedRequest.ActionMenu.RunNowOption().ClickWithTimeout();

            savedRequest.RunNowConfirmationModal.WaitForCasesToLoad();

            savedRequest.RunNowConfirmationModal.RunTypeSeperateCases.Input.ClickWithTimeout();

            savedRequest.RunNowConfirmationModal.Proceed().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            Assert.NotNull(popups.FlashAlert());

            using (var setup = new RequestsDbSetup())
            {
                setup.DbContext.RenameStoredProcedureAsBackup(IpWhatWillBePoliced);
            }

            ReloadPage(driver);
            savedRequest.SavedRequestGrid.SelectIpCheckbox(0);

            savedRequest.ActionMenu.OpenOrClose();
            savedRequest.ActionMenu.RunNowOption().ClickWithTimeout();

            Assert.False(savedRequest.RunNowConfirmationModal.RequestRunTypeVisible(), "The Run Type options must be hidden if calculate cases feature is not available");
            savedRequest.RunNowConfirmationModal.Proceed().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            Assert.NotNull(popups.FlashAlert());
        }
    }
}