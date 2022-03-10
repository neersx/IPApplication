using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CopyTimeFromSearch : TimeSearchBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void Copy(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time/query", DbData.User.Username, DbData.User.Password);

            var searchPage = new TimeSearchPage(driver);
            searchPage.PerformSearch();

            var entryDate = searchPage.SearchResults.Cell(0, 2).Text;
            var caseReference = searchPage.SearchResults.Cell(0, 3).Text;
            var instructorName = searchPage.SearchResults.Cell(0, 4).Text;
            var activity = searchPage.SearchResults.Cell(0, 5).Text;
            searchPage.SearchResults.ActionMenu.OpenOrClose();
            searchPage.SearchResults.SelectRow(0);
            searchPage.SearchResults.ActionMenu.OpenOrClose();
            searchPage.Copy.Click();

            var wipWarningDialog = new WipWarningsModal(driver);
            wipWarningDialog.Proceed();

            driver.WaitForAngular();

            var timeRecordingPage = new TimeRecordingPage(driver);
            var selectedDate = timeRecordingPage.SelectedDate.Input.WithJs().GetValue();
            Assert.AreEqual(entryDate, selectedDate, $"Expected Time Recording to navigate to {entryDate} but is {selectedDate}");
            var entriesList = timeRecordingPage.Timesheet;

            var activeRow = entriesList.MasterRows[0];
            var durationPicker = activeRow.FindElement(By.Id("elapsedTime"));
            Assert.IsNull(durationPicker.Value(), "Expected Duration to be blank on copied entry");
            var casePicker = new AngularPicklist(driver).ByName("caseRef");
            Assert.AreEqual(caseReference, casePicker.InputValue, $"Expected Case to be set to: {caseReference} but was {casePicker.InputValue}");
            var namePicker = new AngularPicklist(driver).ByName("name");
            Assert.AreEqual(instructorName, namePicker.InputValue, $"Expected Name to be set to: {instructorName} but was {namePicker.InputValue}");
            var activityPicker = new AngularPicklist(driver).ByName("wipTemplates");
            Assert.AreEqual(activity, activityPicker.InputValue, $"Expected Activity to be set to: {activity} but was {activityPicker.InputValue}");

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().WithJs().Click();
            var popup = new CommonPopups(driver);
            Assert.IsTrue(popup.FlashAlertIsDisplayed());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CopyToOtherDate(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.PreviousButton.ClickWithTimeout();
            var originalSelectedDate = page.SelectedDate.Input.WithJs().GetValue();

            page.SearchButton.Click();
            var searchPage = new TimeSearchPage(driver);
            searchPage.PerformSearch();

            var entryDate = searchPage.SearchResults.Cell(0, 2).Text;
            var caseReference = searchPage.SearchResults.Cell(0, 3).Text;
            var instructorName = searchPage.SearchResults.Cell(0, 4).Text;
            var activity = searchPage.SearchResults.Cell(0, 5).Text;
            searchPage.SearchResults.ActionMenu.OpenOrClose();
            searchPage.SearchResults.SelectRow(0);
            searchPage.SearchResults.ActionMenu.OpenOrClose();
            searchPage.Copy.Click();

            var wipWarningDialog = new WipWarningsModal(driver);
            wipWarningDialog.Proceed();

            driver.WaitForAngular();

            var timeRecordingPage = new TimeRecordingPage(driver);
            var selectedDate = timeRecordingPage.SelectedDate.Input.WithJs().GetValue();
            Assert.AreEqual(originalSelectedDate, selectedDate, $"Expected Time Recording to navigate to {originalSelectedDate} but is {selectedDate}");
            var entriesList = timeRecordingPage.Timesheet;

            var activeRow = entriesList.MasterRows[0];
            var durationPicker = activeRow.FindElement(By.Id("elapsedTime"));
            Assert.IsNull(durationPicker.Value(), "Expected Duration to be blank on copied entry");
            var casePicker = new AngularPicklist(driver).ByName("caseRef");
            Assert.AreEqual(caseReference, casePicker.InputValue, $"Expected Case to be set to: {caseReference} but was {casePicker.InputValue}");
            var namePicker = new AngularPicklist(driver).ByName("name");
            Assert.AreEqual(instructorName, namePicker.InputValue, $"Expected Name to be set to: {instructorName} but was {namePicker.InputValue}");
            var activityPicker = new AngularPicklist(driver).ByName("wipTemplates");
            Assert.AreEqual(activity, activityPicker.InputValue, $"Expected Activity to be set to: {activity} but was {activityPicker.InputValue}");

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().WithJs().Click();
            var popup = new CommonPopups(driver);
            Assert.IsTrue(popup.FlashAlertIsDisplayed());
        }
    }
}