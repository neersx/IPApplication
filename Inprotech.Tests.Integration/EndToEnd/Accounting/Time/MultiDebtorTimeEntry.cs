using System.Collections.Generic;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Names;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [SplitWipMultiDebtor]
    [Category(Categories.E2E)]
    [TestFixture]
    public class MultiDebtorTimeEntry : IntegrationTest
    {
        protected TimeRecordingData _dbData;

        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withStartTime: true, withValueOnEntryPreference: true, withMultiDebtorEnabled: true);
            TimeRecordingDbHelper.SetAccessForEditPostedTask(_dbData.User, Allow.Modify | Allow.Delete);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditTimeEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            driver.WaitForAngularWithTimeout();

            entriesList.Add();

            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            editableRow.Duration.SetValue("01:00");

            editableRow.CaseRef.EnterAndSelect(_dbData.Case.Irn);
            var wipWarningDialog = new WipWarningsModal(driver);
            wipWarningDialog.Proceed();
            
            var activityPicker = editableRow.Activity;
            activityPicker.SendKeys(Keys.ArrowDown);
            activityPicker.SendKeys(Keys.ArrowDown);
            activityPicker.SendKeys(Keys.Enter);

            driver.WaitForAngular();

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().ClickWithTimeout();

            driver.WaitForAngular();

            entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual(string.Empty, details.ChargeRate, $"Expected charge rate to be blank but was '{details.ChargeRate}'.");
            Assert.True(details.MultiDebtorChargeRate.Displayed, "Expected icon for different charge rates is displayed");
            Assert.True(details.LocalValue.Contains("120.00"), $"Expected local value to display aggregate but was '{details.LocalValue}'.");

            details.ViewDebtorValuation();
            var debtorSplitsModal = new DebtorValuationsModal(driver);
            debtorSplitsModal.VerifySplits(new List<DebtorSplit>
            {
                new DebtorSplit
                {
                    DebtorName = _dbData.Debtor.Formatted(),
                    DebtorNameNo = _dbData.Debtor.Id,
                    LocalValue = (decimal?) 60.00,
                    ChargeOutRate = (decimal) 150.00,
                    ForeignCurrency = _dbData.HomeCurrency.Id
                },
                new DebtorSplit
                {
                    DebtorName = _dbData.Debtor2.Formatted(),
                    DebtorNameNo = _dbData.Debtor2.Id,
                    LocalValue = (decimal?) 60.00,
                    ChargeOutRate = (decimal) 100.00,
                    ForeignCurrency = _dbData.HomeCurrency.Id
                }
            });
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}120.00", debtorSplitsModal.TotalLocalValue);
            debtorSplitsModal.CloseModal();

            const string newNarrativeText = "Performing the same task for multiple debtors...";
            editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            editableRow.Duration.SetValue("02:00");
            details.NarrativeText.Clear();
            details.NarrativeText.SendKeys(newNarrativeText);

            details.SaveButton().ClickWithTimeout();

            ReloadPage(driver);

            page = new TimeRecordingPage(driver);
            entriesList = page.Timesheet;
            entriesList.ToggleDetailsRow(0);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual(string.Empty, details.ChargeRate, $"Expected charge rate to be blank but was '{details.ChargeRate}'.");
            Assert.True(details.MultiDebtorChargeRate.Displayed, "Expected icon for different charge rates is displayed");
            Assert.True(details.LocalValue.Contains("240.00"), $"Expected local value to display aggregate but was '{details.LocalValue}'.");
            Assert.AreEqual(newNarrativeText, details.NarrativeText.WithJs().GetValue(), $"Expected narrative to be '{newNarrativeText}' but was '{details.NarrativeText}'.");

            details.ViewDebtorValuation();
            debtorSplitsModal = new DebtorValuationsModal(driver);
            debtorSplitsModal.VerifySplits(new List<DebtorSplit>
            {
                new DebtorSplit
                {
                    DebtorName = _dbData.Debtor.Formatted(),
                    DebtorNameNo = _dbData.Debtor.Id,
                    LocalValue = (decimal?) 120.00,
                    ChargeOutRate = (decimal) 150.00,
                    ForeignCurrency = _dbData.HomeCurrency.Id
                },
                new DebtorSplit
                {
                    DebtorName = _dbData.Debtor2.Formatted(),
                    DebtorNameNo = _dbData.Debtor2.Id,
                    LocalValue = (decimal?) 120.00,
                    ChargeOutRate = (decimal) 100.00,
                    ForeignCurrency = _dbData.HomeCurrency.Id
                }
            });
            Assert.AreEqual($"{_dbData.HomeCurrency.Id}240.00", debtorSplitsModal.TotalLocalValue);
            debtorSplitsModal.CloseModal();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AdjustValueNotAllowed_ChangeEntryDatePerformed(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            entriesList.Add();

            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            editableRow.Duration.SetValue("01:00");

            editableRow.CaseRef.EnterAndSelect(_dbData.Case.Irn);
            var wipWarningDialog = new WipWarningsModal(driver);
            wipWarningDialog.Proceed();
            
            var activityPicker = editableRow.Activity;
            activityPicker.SendKeys(Keys.ArrowDown);
            activityPicker.SendKeys(Keys.ArrowDown);
            activityPicker.SendKeys(Keys.Enter);

            driver.WaitForAngular();

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().ClickWithTimeout();

            driver.WaitForAngular();
            var entriesCount = page.Timesheet.MasterRows.Count;

            page.Timesheet.OpenTaskMenuFor(0);
            page.ContextMenu.AdjustValue();
            var popups = new CommonPopups(driver);
            Assert.True(popups.AlertModal.Description.Contains("This function is not available for multi-debtor"), "Adjust value - not available for multi debtor entries");
            popups.AlertModal.Ok();

            page.ChangeEntryDate(0, "2000", 5);

            var newCount = page.Timesheet.MasterRows.Count;
            Assert.AreEqual(entriesCount - 1, newCount, "Expected entries to be refreshed after save.");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class MultiDebtorPostedTime : MultiDebtorTimeEntry
    {
        void CreatePostedEntry(NgWebDriver driver, string caseIrn)
        {
            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            driver.WaitForAngularWithTimeout();
            entriesList.Add();

            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            editableRow.Duration.SetValue("01:00");

            editableRow.CaseRef.EnterAndSelect(caseIrn);
            var wipWarningDialog = new WipWarningsModal(driver);
            wipWarningDialog.Proceed();

            var activityPicker = editableRow.Activity;
            activityPicker.SendKeys(Keys.ArrowDown);
            activityPicker.SendKeys(Keys.ArrowDown);
            activityPicker.SendKeys(Keys.Enter);
            driver.WaitForAngular();

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().ClickWithTimeout();
            driver.WaitForAngular();

            entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Post();
             
            var postTimePopup = new PostTimePopup(driver, "postTimeModal");
            Assert.False(postTimePopup.PostButton.IsDisabled());
            postTimePopup.PostButton.Click();

            var postTimeFeedbackDlg = new PostFeedbackDlg(driver, "postTimeResDlg");
            postTimeFeedbackDlg.OkButton.WithJs().Click();
            driver.WaitForAngular();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ModificationsNotAllowed(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            CreatePostedEntry(driver, _dbData.Case.Irn);
            var page = new TimeRecordingPage(driver);
            var popups = new CommonPopups(driver);

            page.Timesheet.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();
            Assert.True(popups.AlertModal.Description.Contains("This function is not available for posted multi-debtor"), "Edit posted time - not available for multi debtor entries");
            popups.AlertModal.Ok();

            page.Timesheet.OpenTaskMenuFor(0);
            page.ContextMenu.ChangeEntryDate();
            Assert.True(popups.AlertModal.Description.Contains("This function is not available for posted multi-debtor"), "Change entry for posted time - not available for multi debtor entries");
            popups.AlertModal.Ok();

            page.Timesheet.OpenTaskMenuFor(0);
            page.ContextMenu.Delete();
            Assert.True(popups.AlertModal.Description.Contains("This function is not available for posted multi-debtor"), "Delete posted time - not available for multi debtor entries");
            popups.AlertModal.Ok();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PostedEntryCanNotBeTurnedToMultiDebtor(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            CreatePostedEntry(driver, _dbData.NewCaseSameDebtor.Irn);
            var page = new TimeRecordingPage(driver);
            var popups = new CommonPopups(driver);
            
            page.Timesheet.OpenTaskMenuFor(0);
            page.ContextMenu.Edit();

            Assert.NotNull(popups.ConfirmModal, "Confirmation to edit posted entry is displayed");
            popups.ConfirmModal.Proceed();
            
            var entriesList = page.Timesheet;
            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            editableRow.CaseRef.EnterAndSelect(_dbData.Case.Irn);
            var wipWarningDialog = new WipWarningsModal(driver);
            wipWarningDialog.Proceed();
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().ClickWithTimeout();

            Assert.True(popups.AlertModal.Description.Contains("Posted time cannot be re-assigned to a multi-debtor case"));
            popups.AlertModal.Ok();
        }
    }
}