using System;
using System.Data.Entity;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting.Cost;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class AdjustTimeValues : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup();
            DbSetup.Do(x =>
            {
                x.Insert(new TimeCosting {ChargeUnitRate = 100, NameNo = _dbData.Debtor2.Id, EffectiveDate = new DateTime(1999, 1, 1), CurrencyCode = _dbData.Currency.Id});
            });
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        TimeRecordingData _dbData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AdjustLocalValue(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.AdjustValue();

            var dialog = new AdjustValuesDialog(driver);
            Assert.IsTrue(dialog.Save.WithJs().IsDisabled(), "Expected Save button to be disabled initially");
            dialog.LocalAmount.SendKeys("543.21");
            dialog.LocalAmount.WithJs().Blur();
            driver.WaitForAngular();
            dialog.Cancel.WithJs().Click();
            Assert.IsTrue(entriesList.CellText(0, "Local Value").EndsWith("300.00"), "Expected Local Value to be updated");

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.AdjustValue();
            dialog = new AdjustValuesDialog(driver);
            dialog.LocalAmount.SendKeys("999");

            driver.WaitForAngular();
            dialog.Save.WithJs().Click();

            entriesList = page.Timesheet;
            Assert.IsTrue(entriesList.CellText(0, "Local Value").EndsWith("999.00"), "Expected Local Value to be updated");

            entriesList.OpenTaskMenuFor(5);
            Assert.IsTrue(page.ContextMenu.AdjustMenu.Disabled(), "Expected Adjust Value to be disabled for Incomplete entries");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AdjustForeignValue(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            page.AddButton.Click();
            
            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            editableRow.Duration.SetValue("1:00");
            editableRow.Name.EnterExactSelectAndBlur("E2E2");
            editableRow.Activity.EnterExactSelectAndBlur("E2E");
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().ClickWithTimeout();

            entriesList = page.Timesheet;
            var newTimeEntryIndex = entriesList.Rows.Count - 1;
            entriesList.OpenTaskMenuFor(newTimeEntryIndex);
            page.ContextMenu.AdjustValue();

            var dialog = new AdjustValuesDialog(driver);
            Assert.IsTrue(dialog.Save.WithJs().IsDisabled(), "Expected Save button to be disabled initially");
            dialog.ForeignAmount.SendKeys("999.00");
            driver.WaitForAngular();
            dialog.Save.WithJs().Click();
            entriesList = page.Timesheet;
            Assert.IsTrue(entriesList.CellText(newTimeEntryIndex, "Foreign Value").EndsWith("999.00"), "Expected Foreign Value to be updated");
            Assert.IsTrue(entriesList.CellText(newTimeEntryIndex, "Foreign Value").StartsWith(_dbData.Currency.Id), $"Expected Foreign Currency to be {_dbData.Currency.Id}");
        }
    }

    public class AdjustValuesDialog : MaintenanceModal
    {
        public AdjustValuesDialog(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement LocalAmount => Modal.FindElements(By.CssSelector("div ipx-numeric")).First().FindElement(By.TagName("input"));
        public NgWebElement ForeignAmount => Modal.FindElements(By.CssSelector("div ipx-numeric")).Last().FindElement(By.TagName("input"));

        public NgWebElement Save => Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Save')]"));
        public NgWebElement Cancel => Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Cancel')]"));
    }
}