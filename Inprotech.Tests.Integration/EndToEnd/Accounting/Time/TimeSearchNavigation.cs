using System;
using System.Drawing;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeSearchNavigation : IntegrationTest
    {
        TimeRecordingData _dbData;

        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup();
            TimeRecordingDbHelper.SetupFunctionSecurity(new[]
            {
                FunctionSecurityPrivilege.CanRead,
                FunctionSecurityPrivilege.CanInsert,
                FunctionSecurityPrivilege.CanPost,
                FunctionSecurityPrivilege.CanUpdate
            }, _dbData.User.NameId);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchEntryPoint(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();

            var search = new TimeSearchPage(driver);
            search.CloseSearch.Click();

            page = new TimeRecordingPage(driver);
            Assert.IsNotNull(page.Timesheet, "Closing Time Search navigates back to Time Recording page");

            page.StaffName.EnterAndSelect("Func");
            var newStaffName = page.StaffName.Element.Value();

            page.PreviousButton.Click();
            var originalSelectedDate = page.SelectedDate.Input.WithJs().GetValue();
            page.SearchButton.Click();
            search = new TimeSearchPage(driver);
            search.CloseSearch.Click();

            page = new TimeRecordingPage(driver);
            var selectedDate = page.SelectedDate.Input.WithJs().GetValue();
            var selectedStaff = page.StaffName.Element.Value();
            Assert.AreEqual(originalSelectedDate, selectedDate, $"Expected Time Recording to navigate to {originalSelectedDate} but is {selectedDate}");
            Assert.AreEqual(newStaffName, selectedStaff, $"Expected Time Recording to display time for {newStaffName} but is {selectedStaff}");

            page.SearchButton.Click();
            ReloadPage(driver);

            search = new TimeSearchPage(driver);
            Assert.False(search.CloseSearch.Enabled, "Close button is disabled when navigating directly to Time Search");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DisabledNameLinks(BrowserType browserType)
        {
            TestUser noLinkUser = null;
            DbSetup.Do(x =>
            {
                noLinkUser = new Users(x.DbContext) { Name = _dbData.StaffName }.WithPermission(ApplicationTask.MaintainTimeViaTimeRecording)
                                                                              .WithPermission(ApplicationTask.ShowLinkstoWeb, Deny.Execute)
                                                                              .Create();
                x.DbContext.SaveChanges();
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", noLinkUser.Username, noLinkUser.Password);

            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();

            var search = new TimeSearchPage(driver);

            search.SearchButton.ClickWithTimeout();
            Assert.Throws<NoSuchElementException>(() => search.NameLink(0), "Expected Name Link to not be available when ShowLinksToWeb is not granted");
            Assert.Throws<NoSuchElementException>(() => search.NameLink(1), "Expected Name Link to not be available for Case entries when ShowLinksToWeb is not granted");
            Assert.True(search.CaseLink(1).Displayed, "Expected Case Link to be displayed even when ShowLinksToWeb is not granted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void RecordAndSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();

            var search = new TimeSearchPage(driver);
            search.SetSearchDates();
            search.SearchButton.ClickWithTimeout();
            var searchResults = search.SearchResults;
            var entryDate = searchResults.Cell(0, 2).Text;
            searchResults.Cell(0, 2).FindElement(By.TagName("a")).ClickWithTimeout();

            page = new TimeRecordingPage(driver);
            var selectedDate = page.SelectedDate.Input.WithJs().GetValue();
            Assert.AreEqual(entryDate, selectedDate, $"Expected Time Recording to navigate to {entryDate} but is {selectedDate}");

            page.SearchButton.Click();
            driver.WaitForAngularWithTimeout();

            ReloadPage(driver);

            search = new TimeSearchPage(driver);
            search.SetSearchDates();
            search.SearchButton.ClickWithTimeout();
            searchResults = search.SearchResults;
            entryDate = searchResults.Cell(6, 2).Text;
            searchResults.Cell(6, 2).FindElement(By.TagName("a")).ClickWithTimeout();
            page = new TimeRecordingPage(driver);
            selectedDate = page.SelectedDate.Input.WithJs().GetValue();
            Assert.AreEqual(entryDate, selectedDate, $"Expected Time Recording to navigate to {entryDate} but is {selectedDate}");

            var timeForStaff = new AngularPicklist(driver).ByName("timeForStaff");
            timeForStaff.EnterAndSelect("Func");
            var otherStaff = timeForStaff.InputValue;
            page.SearchButton.Click();
            driver.WaitForAngularWithTimeout();

            search = new TimeSearchPage(driver);
            Assert.AreEqual(otherStaff, search.StaffName.InputValue, $"Expected Staff to be {otherStaff} but is {search.StaffName.InputValue}");
        }
    }
}