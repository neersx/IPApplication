using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Policing;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.SavedRequest
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestType(TestTypes.Regression)]
    public class SavedRequestsReadOnly : SavedRequestsTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CaseAttributes(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var requestPage = new SavedRequestsPageObject(driver);
            var requestTitle = "1A E2E " + RandomString.Next(6);
            var affectedCasesMessageSelector = By.CssSelector("span[translate='policing.request.maintenance.runRequest.affectedCases']");
            ValidCharacteristics characteristics;
            using (var setup = new RequestsDbSetup())
            {
                characteristics = setup.SetValidCharacteristics();
            }

            SignIn(driver, "/#/policing-saved-requests");

            requestPage.Add().Click();

            var modal = requestPage.MaintenanceModal;

            modal.Title().SendKeys(requestTitle);

            var caseAttributes = modal.Attributes;

            caseAttributes.CaseReference.EnterAndSelect("test");
            driver.WaitForAngularWithTimeout();

            caseAttributes.Jurisdiction.Typeahead.WithJs().ScrollIntoView();

            // If a Case Reference is selected, all the other fields will be disabled except for Action and Event
            Assert.AreEqual(true, caseAttributes.Jurisdiction.Typeahead.WithJs().IsDisabled());
            Assert.AreEqual(true, caseAttributes.PropertyType.Typeahead.WithJs().IsDisabled());
            Assert.AreEqual(true, caseAttributes.CaseType.Typeahead.WithJs().IsDisabled());
            Assert.AreEqual(true, caseAttributes.CaseCategory.Typeahead.WithJs().IsDisabled());
            Assert.AreEqual(true, caseAttributes.SubType.Typeahead.WithJs().IsDisabled());
            Assert.AreEqual(true, caseAttributes.Office.Typeahead.WithJs().IsDisabled());
            Assert.AreEqual(false, caseAttributes.Action.Typeahead.WithJs().IsDisabled());
            Assert.AreEqual(false, caseAttributes.Event.Typeahead.WithJs().IsDisabled());
            Assert.AreEqual(true, caseAttributes.Law.Typeahead.WithJs().IsDisabled());
            Assert.AreEqual(true, caseAttributes.Name.Typeahead.WithJs().IsDisabled());
            Assert.AreEqual(true, caseAttributes.NameType.Typeahead.WithJs().IsDisabled());

            caseAttributes.CaseReference.Typeahead.Clear();

            Assert.AreEqual(true, caseAttributes.Law.Typeahead.WithJs().IsDisabled(),
                            "Law Update Dates is not enabled till jurisdiction and property type are selected");

            caseAttributes.Jurisdiction.EnterAndSelect(characteristics.Jurisdiction);
            driver.WaitForAngularWithTimeout();
            caseAttributes.PropertyType.EnterAndSelect(characteristics.PropertyType);
            driver.WaitForAngularWithTimeout();
            caseAttributes.CaseType.EnterAndSelect(characteristics.CaseType);
            driver.WaitForAngularWithTimeout();
            caseAttributes.CaseCategory.EnterAndSelect(characteristics.CaseCategory);
            driver.WaitForAngularWithTimeout();
            caseAttributes.SubType.EnterAndSelect(characteristics.SubType);
            driver.WaitForAngularWithTimeout();
            caseAttributes.Office.EnterAndSelect(characteristics.Office);
            driver.WaitForAngularWithTimeout();
            caseAttributes.Action.EnterAndSelect(characteristics.Action);
            driver.WaitForAngularWithTimeout();
            caseAttributes.Event.EnterAndSelect(characteristics.EventName);
            driver.WaitForAngularWithTimeout();
            caseAttributes.NameType.EnterAndSelect(characteristics.NameType);
            driver.WaitForAngularWithTimeout();
            caseAttributes.Name.EnterAndSelect(characteristics.Name);
            driver.WaitForAngularWithTimeout();

            Assert.IsFalse(caseAttributes.Law.Typeahead.WithJs().IsDisabled());
            modal.Save.WithJs().Click();
            driver.WaitForAngular();

            Assert.NotNull(new CommonPopups(driver).FlashAlert());
            driver.Wait().ForVisible(affectedCasesMessageSelector, 10 * 1000);
            Assert.True(modal.AffectedCasesMessage.Contains("0 cases"));
            modal.Discard.Click();

            requestPage.SavedRequestGrid.Cell(0, 1).FindElement(By.TagName("a")).WithJs().Click();

            Assert.AreEqual(characteristics.Jurisdiction, caseAttributes.Jurisdiction.Typeahead.WithJs().GetValue());
            Assert.AreEqual(characteristics.PropertyType, caseAttributes.PropertyType.Typeahead.WithJs().GetValue());
            Assert.AreEqual(characteristics.CaseType, caseAttributes.CaseType.Typeahead.WithJs().GetValue());
            Assert.AreEqual(characteristics.CaseCategory, caseAttributes.CaseCategory.Typeahead.WithJs().GetValue());
            Assert.AreEqual(characteristics.SubType, caseAttributes.SubType.Typeahead.WithJs().GetValue());
            Assert.AreEqual(characteristics.Office, caseAttributes.Office.Typeahead.WithJs().GetValue());
            Assert.AreEqual(characteristics.Action, caseAttributes.Action.Typeahead.WithJs().GetValue());
            Assert.AreEqual(characteristics.EventName, caseAttributes.Event.Typeahead.WithJs().GetValue());
            Assert.AreEqual(characteristics.NameType, caseAttributes.NameType.Typeahead.WithJs().GetValue());
            Assert.AreEqual(characteristics.Name, caseAttributes.Name.Typeahead.WithJs().GetValue());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldSetScreenOptionsCorrectly(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var page = new SavedRequestsPageObject(driver);
            var requestTitle = "1A E2E " + RandomString.Next(6);

            SignIn(driver, "/#/policing-saved-requests", _loginUser.Username, _loginUser.Password);

            page.Add().Click();

            page.MaintenanceModal.Title().SendKeys(requestTitle);

            Assert.True(page.MaintenanceModal.Options.Reminders.IsChecked);
            Assert.True(page.MaintenanceModal.Options.EmailReminders.IsChecked);
            Assert.True(page.MaintenanceModal.Options.Documents.IsChecked);

            page.MaintenanceModal.Options.Reminders.Click();

            Assert.False(page.MaintenanceModal.Options.Reminders.IsChecked);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.EmailReminders, false, false);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.Documents, false, false);

            page.MaintenanceModal.Options.Reminders.Click();

            AssertEnabledAndSelection(page.MaintenanceModal.Options.EmailReminders, true, true);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.Documents, true, false);

            page.MaintenanceModal.Options.Reminders.Click();

            AssertDisabledRemindersSection(page.MaintenanceModal, true);

            page.MaintenanceModal.Options.AdhocReminders.Click();

            AssertDisabledRemindersSection(page.MaintenanceModal, false);

            page.MaintenanceModal.Options.RecalculateCriteria.Click();
            AssertDisabledRemindersSection(page.MaintenanceModal, true);

            AssertEnabledAndSelection(page.MaintenanceModal.Options.RecalculateDueDates, false, true);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.RecalculateReminderDates, false, true);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.RecalculateEventDates, true, false);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.AdhocReminders, false, false);

            page.MaintenanceModal.Options.RecalculateCriteria.Click();
            page.MaintenanceModal.Options.RecalculateEventDates.Click();

            AssertEnabledAndSelection(page.MaintenanceModal.Options.RecalculateDueDates, true, true);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.RecalculateReminderDates, false, true);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.RecalculateEventDates, true, true);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.AdhocReminders, false, false);

            page.MaintenanceModal.Options.RecalculateDueDates.Click();

            AssertEnabledAndSelection(page.MaintenanceModal.Options.RecalculateReminderDates, true, true);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.RecalculateEventDates, false, false);
            AssertEnabledAndSelection(page.MaintenanceModal.Options.AdhocReminders, false, false);

            page.MaintenanceModal.Options.RecalculateReminderDates.Click();

            AssertEnabledAndSelection(page.MaintenanceModal.Options.AdhocReminders, true, false);

            page.MaintenanceModal.Options.AdhocReminders.Click();

            AssertDisabledRemindersSection(page.MaintenanceModal, false);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldAllowUpto4DigitDaysRange(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var requestTitle = " A Policing Request" + RandomString.Next(6);
            var notes = "E2e Test";

            SignIn(driver, "/#/policing-saved-requests", _loginUser.Username, _loginUser.Password);

            driver.With<SavedRequestsPageObject>(page =>
            {
                page.Add().Click();

                page.MaintenanceModal.Title().SendKeys(requestTitle);

                page.MaintenanceModal.Notes().SendKeys(notes);
                page.MaintenanceModal.ForDays().SendKeys("-99999");
                page.MaintenanceModal.Options.Update.Click();

                var tooltip = page.MaintenanceModal.GetVisibleValidationTooltip();

                Assert.AreEqual("The value must be equal to or greater than -9999.", tooltip, "Should display tooltip indicating value less than -9999 is not accepted");

                page.MaintenanceModal.ForDays().Clear();
                page.MaintenanceModal.ForDays().SendKeys("9999");

                page.MaintenanceModal.Options.Update.Click();

                page.MaintenanceModal.Save.WithJs().Click();

                var savedRequest = DbSetup.Do(x => x.DbContext.Set<PolicingRequest>()
                                                    .OrderByDescending(_ => _.DateEntered)
                                                    .First());

                Assert.AreEqual(9999, savedRequest.NoOfDays, "Should have value 9999 as it is saved correctly");
            });

            ReloadPage(driver);

            driver.With<SavedRequestsPageObject>(page =>
            {
                page.SavedRequestGrid.SelectRow(0);
                page.ActionMenu.OpenOrClose();

                page.ActionMenu.EditOption().ClickWithTimeout();
                driver.WaitForAngularWithTimeout();

                page.MaintenanceModal.ForDays().Clear();
                page.MaintenanceModal.ForDays().SendKeys("99999");

                page.MaintenanceModal.Options.Update.Click();

                var tooltip = page.MaintenanceModal.GetVisibleValidationTooltip();

                Assert.AreEqual("The value must not be greater than 9999.", tooltip, "Should display tooltip indicating value greater than 9999 is not accepted");

                page.MaintenanceModal.ForDays().Clear();
                page.MaintenanceModal.ForDays().SendKeys("-9999");

                page.MaintenanceModal.Options.Update.Click();

                page.MaintenanceModal.Save.WithJs().Click();

                var savedRequest = DbSetup.Do(x => x.DbContext.Set<PolicingRequest>()
                                                    .OrderByDescending(_ => _.DateEntered)
                                                    .First());

                Assert.AreEqual(-9999, savedRequest.NoOfDays, "Should have value -9999 as it is saved correctly");
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShowsSavedRequestsWithNotes(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var savedRequest = new SavedRequestsPageObject(driver);

            using (var setup = new RequestsDbSetup())
            {
                setup.Insert(new PolicingRequest(null)
                {
                    IsSystemGenerated = 0,
                    Name = "1A Test1",
                    Notes = "Note1",
                    DateEntered = Helpers.UniqueDateTime()
                });

                setup.Insert(new PolicingRequest(null)
                {
                    IsSystemGenerated = 0,
                    Name = "1A Test2",
                    Notes = "Note2",
                    DateEntered = Helpers.UniqueDateTime()
                });
            }

            SignIn(driver, "/#/policing-saved-requests", _loginUser.Username, _loginUser.Password);

            Assert.LessOrEqual(2, savedRequest.SavedRequestGrid.Rows.Count);
            Assert.AreEqual("1A Test1", savedRequest.SavedRequestGrid.CellText(0, 1));
            Assert.AreEqual("Note1", savedRequest.SavedRequestGrid.CellText(0, 2));

            Assert.AreEqual("1A Test2", savedRequest.SavedRequestGrid.CellText(1, 1));
            Assert.AreEqual("Note2", savedRequest.SavedRequestGrid.CellText(1, 2));
        }
    }
}