using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
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
    public class SavedRequestsEditing : SavedRequestsTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DisplaysDataForSelectedRequestToEdit(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var savedRequest = new SavedRequestsPageObject(driver);
            string caseIrn;
            using (var setup = new RequestsDbSetup())
            {
                var @case = setup.GetCase("test-ref1");
                caseIrn = @case.Irn;
                setup.Insert(new PolicingRequest(null)
                {
                    IsSystemGenerated = 0,
                    Name = " A Policing Request",
                    DateEntered = Helpers.UniqueDateTime(),
                    Irn = caseIrn,
                    IsReminder = 1,
                    NoOfDays = 5
                });
            }

            SignIn(driver, "/#/policing-saved-requests", _loginUser.Username, _loginUser.Password);

            Assert.LessOrEqual(1, savedRequest.SavedRequestGrid.Rows.Count);

            savedRequest.SavedRequestGrid.SelectRow(0);
            savedRequest.ActionMenu.OpenOrClose();
            Assert.True(savedRequest.ActionMenu.EditOption().Enabled);
            savedRequest.ActionMenu.EditOption().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            Assert.AreEqual(" A Policing Request", savedRequest.MaintenanceModal.Title().GetAttribute("value"));
            Assert.NotNull(savedRequest.MaintenanceModal.StartDate().Input.Text);
            Assert.AreEqual("5", savedRequest.MaintenanceModal.ForDays().GetAttribute("value"));
            Assert.AreEqual(caseIrn, savedRequest.MaintenanceModal.Attributes.CaseReference.GetText());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditSelectedRequestFromHyperlink(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var savedRequest = new SavedRequestsPageObject(driver);
            var popups = new CommonPopups(savedRequest.Driver);

            using (var setup = new RequestsDbSetup())
            {
                setup.Insert(new PolicingRequest(null)
                {
                    IsSystemGenerated = 0,
                    Name = "1A New Title",
                    DateEntered = Helpers.UniqueDateTime()
                });
            }

            SignIn(driver, "/#/policing-saved-requests", _loginUser.Username, _loginUser.Password);

            Assert.LessOrEqual(1, savedRequest.SavedRequestGrid.Rows.Count);

            savedRequest.FirstTitleLink.Click();
            Assert.AreEqual("1A New Title", savedRequest.MaintenanceModal.Title().GetAttribute("value"));

            savedRequest.MaintenanceModal.Attributes.CaseReference.Clear();
            savedRequest.MaintenanceModal.Attributes.Jurisdiction.EnterAndSelect("Australia");
            savedRequest.MaintenanceModal.Attributes.Jurisdiction.Blur();
            driver.WaitForAngularWithTimeout();
            savedRequest.MaintenanceModal.Title().Clear();
            savedRequest.MaintenanceModal.Title().SendKeys("01New Title");

            savedRequest.MaintenanceModal.Save.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            Assert.NotNull(popups.FlashAlert());

            savedRequest.MaintenanceModal.Discard.Click();

            var updatedText = savedRequest.SavedRequestGrid.CellText(0, 1);
            Assert.AreEqual("01New Title", updatedText);

            savedRequest.FirstTitleLink.WithJs().Click();
            Assert.AreEqual("Australia", savedRequest.MaintenanceModal.Attributes.Jurisdiction.GetText());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DuplicatePolicingRequest(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var page = new SavedRequestsPageObject(driver);

            PolicingRequest originalRequest;
            using (var setup = new RequestsDbSetup())
            {
                originalRequest = setup.Insert(new PolicingRequest(null)
                {
                    Name = "1A Test1" + RandomString.Next(2),
                    IsSystemGenerated = 0,
                    DateEntered = Helpers.UniqueDateTime(),
                    IsReminder = 1,
                    NoOfDays = 5,
                    IsDueDateOnly = 1
                });
            }

            SignIn(driver, "/#/policing-saved-requests");
            Assert.LessOrEqual(1, page.SavedRequestGrid.Rows.Count);

            page.SavedRequestGrid.SelectRow(0);
            page.ActionMenu.OpenOrClose();
            Assert.True(page.ActionMenu.DuplicateOption().Enabled);
            page.ActionMenu.DuplicateOption().ClickWithTimeout();

            Assert.AreEqual($"{originalRequest.Name} - Copy", page.MaintenanceModal.Title().Value());
            Assert.NotNull(page.MaintenanceModal.StartDate().Input.Text);
            Assert.AreEqual(page.MaintenanceModal.ForDays().Value(), originalRequest.NoOfDays.ToString());

            page.MaintenanceModal.Title().Clear();
            page.MaintenanceModal.Title().SendKeys("Duplicate Request E2E");
            page.MaintenanceModal.Save.ClickWithTimeout();

            var newRequest = DbSetup.Do(x => x.DbContext.Set<PolicingRequest>()
                                              .OrderByDescending(_ => _.DateEntered)
                                              .First(_ => _.Name.Equals("Duplicate Request E2E")));

            Assert.AreEqual(newRequest.Name, "Duplicate Request E2E");
            Assert.AreEqual(newRequest.Notes, originalRequest.Notes);
            Assert.AreEqual(newRequest.FromDate, originalRequest.FromDate);
            Assert.AreEqual(newRequest.UntilDate, originalRequest.UntilDate);
            Assert.AreEqual(newRequest.LetterDate, originalRequest.LetterDate);
            Assert.AreEqual(newRequest.NoOfDays, originalRequest.NoOfDays);
            Assert.AreEqual(newRequest.IsDueDateOnly, originalRequest.IsDueDateOnly.GetValueOrDefault());
            Assert.AreEqual(newRequest.IsReminder, originalRequest.IsReminder.GetValueOrDefault());
            Assert.AreEqual(newRequest.IsLetter, originalRequest.IsLetter.GetValueOrDefault());

            Assert.AreNotEqual(newRequest.Name, originalRequest.Name);
            Assert.AreNotEqual(newRequest.DateEntered, originalRequest.DateEntered);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldSaveRequestWithReminders(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var page = new SavedRequestsPageObject(driver);
            var requestTitle = "1A E2E " + RandomString.Next(6);
            var notes = "E2e Test";

            SignIn(driver, "/#/policing-saved-requests", _loginUser.Username, _loginUser.Password);

            page.Add().Click();

            page.MaintenanceModal.Title().SendKeys(requestTitle);

            page.MaintenanceModal.Notes().SendKeys(notes);

            page.MaintenanceModal.StartDate().Input.SendKeys("26-Aug-2016");
            page.MaintenanceModal.EndDate().Input.SendKeys("29-Aug-2016");
            page.MaintenanceModal.DueDateOnly().WithJs().Click();

            page.MaintenanceModal.Options.Update.Click();
            page.MaintenanceModal.Options.AdhocReminders.Click();

            page.MaintenanceModal.Save.WithJs().Click();
            Assert.NotNull(new CommonPopups(driver).FlashAlert(), "Should automatically calculate affected cases on save");

            var savedRequest = DbSetup.Do(x => x.DbContext.Set<PolicingRequest>()
                                                .OrderByDescending(_ => _.DateEntered)
                                                .First());

            Assert.AreEqual(savedRequest.Name, requestTitle);
            Assert.AreEqual(savedRequest.Notes, notes);
            Assert.AreEqual(savedRequest.FromDate, DateTime.Parse("26-Aug-2016"));
            Assert.AreEqual(savedRequest.UntilDate, DateTime.Parse("29-Aug-2016"));
            Assert.AreEqual(savedRequest.LetterDate, DateTime.Parse("29-Aug-2016"));
            Assert.AreEqual(savedRequest.IsDueDateOnly, 1);
            Assert.AreEqual(savedRequest.IsReminder, 1);
            Assert.AreEqual(savedRequest.IsLetter, 1);

            Assert.AreEqual(savedRequest.IsReminder, 1);
            Assert.AreEqual(savedRequest.IsEmailFlag, true);
            Assert.AreEqual(savedRequest.IsLetter, 1);
            Assert.AreEqual(savedRequest.IsUpdate, 1);
            Assert.AreEqual(savedRequest.IsAdhocReminder, 1);
        }
    }
}