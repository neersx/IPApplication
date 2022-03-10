using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.NumberPatternsMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    class NumberPatternsMaintenance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainNumberPatterns(BrowserType browserType)
        {
            var today = DateTime.Now.ToString("yyyy-MM-dd");
            var driver = BrowserProvider.Get(browserType);
            new NumberPatternsMaintenanceDbSetUp().Prepare();
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .Create();
            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);
            var pageDetails = new NumberPatternsMaintenanceDetailPage(driver);
            var topic = pageDetails.NumberPatternsTopic;

            var propertyTypePicklist = new PickList(driver).ByName("propertyType");
            var numberTypePicklist = new PickList(driver).ByName("numberType");
            var caseTypePicklist = new PickList(driver).ByName("caseType");
            var caseCategoryPicklist = new PickList(driver).ByName("caseCategory");
            var subTypePicklist = new PickList(driver).ByName("subType");
            var additionalValidationPicklist = new PickList(driver).ByName("additionalValidation");

            #region Add Number Patterns
            topic.SearchTextBox(driver).Clear();
            topic.SearchTextBox(driver).SendKeys(NumberPatternsMaintenanceDbSetUp.CountryCode);
            topic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(NumberPatternsMaintenanceDbSetUp.CountryCode, searchResults.CellText(0, 1), "Search returns record matching code");

            topic.BulkMenu(driver);
            topic.SelectPageOnly(driver);
            topic.EditButton(driver);
            topic.NavigateTo();
            topic.Add();

            Assert.IsFalse(caseCategoryPicklist.Enabled);
            topic.DisplayWarningOnlyCheckBox(driver).WithJs().Click();
            topic.ApplyButton(driver).ClickWithTimeout();
            Assert.IsTrue(propertyTypePicklist.HasError, "Required Field");
            Assert.IsTrue(numberTypePicklist.HasError, "Required Field");
            Assert.IsTrue(new TextField(driver, "pattern").HasError, "Required Field");
            Assert.IsTrue(new TextField(driver, "displayMessage").HasError, "Required Field");

            propertyTypePicklist.EnterAndSelect(NumberPatternsMaintenanceDbSetUp.PropertyTypeDesc);
            numberTypePicklist.EnterAndSelect(NumberPatternsMaintenanceDbSetUp.ApplicationNumber);
            caseTypePicklist.EnterAndSelect("Properties");
            caseCategoryPicklist.EnterAndSelect(NumberPatternsMaintenanceDbSetUp.CategoryDesc);
            subTypePicklist.EnterAndSelect(NumberPatternsMaintenanceDbSetUp.SubTypeDesc);
            topic.PatternTextBox(driver).SendKeys(NumberPatternsMaintenanceDbSetUp.Pattern);
            topic.ErrorMessageTextBox(driver).SendKeys("E2E Error Message");
            topic.ValidFromTextBox(driver).SendKeys(today);
            additionalValidationPicklist.EnterAndSelect(NumberPatternsMaintenanceDbSetUp.InvalidStoredProcName);
            Assert.IsTrue(additionalValidationPicklist.HasError, "Invalid stored Proc Name");
            additionalValidationPicklist.Clear();
            additionalValidationPicklist.EnterAndSelect(NumberPatternsMaintenanceDbSetUp.StoredProcName);
            topic.ApplyButton(driver).ClickWithTimeout();
            topic.SaveButton(driver).ClickWithTimeout();
            topic.NavigateTo();
            var numberPatternsSearchResults = new KendoGrid(driver, "validNumbersGrid");

            Assert.AreEqual(1, numberPatternsSearchResults.Rows.Count);
            Assert.AreEqual(NumberPatternsMaintenanceDbSetUp.PropertyTypeDesc, numberPatternsSearchResults.CellText(0, 1), "Search returns record matching Property Type");
            Assert.AreEqual(NumberPatternsMaintenanceDbSetUp.ApplicationNumber, numberPatternsSearchResults.CellText(0, 2), "Search returns record matching Number Type");
            Assert.AreEqual("Properties", numberPatternsSearchResults.CellText(0, 3), "Search returns record matching Case Type");
            Assert.AreEqual(NumberPatternsMaintenanceDbSetUp.CategoryDesc, numberPatternsSearchResults.CellText(0, 4), "Search returns record matching Category");
            Assert.AreEqual(NumberPatternsMaintenanceDbSetUp.SubTypeDesc, numberPatternsSearchResults.CellText(0, 5), "Search returns record matching Sub Type");
            Assert.AreEqual(DateTime.Now.ToShortDateString(), Convert.ToDateTime(numberPatternsSearchResults.CellText(0, 6)).ToShortDateString(), "Search returns record matching Code");
            Assert.AreEqual(NumberPatternsMaintenanceDbSetUp.Pattern, numberPatternsSearchResults.CellText(0, 7), "Search returns record matching Pattern");
            Assert.AreEqual("E2E Error Message", numberPatternsSearchResults.CellText(0, 9), "Search returns record matching Error Message");
            #endregion

            #region Check for Duplicate Number Patterns
            topic.Add();
            propertyTypePicklist.EnterAndSelect(NumberPatternsMaintenanceDbSetUp.PropertyTypeDesc);
            numberTypePicklist.EnterAndSelect(NumberPatternsMaintenanceDbSetUp.ApplicationNumber);
            topic.ValidFromTextBox(driver).SendKeys(today);
            topic.PatternTextBox(driver).SendKeys(NumberPatternsMaintenanceDbSetUp.Pattern);
            topic.ErrorMessageTextBox(driver).SendKeys("E2E Error Message");
            topic.ApplyButton(driver).WithJs().Click();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();

            topic.CloseButton(driver).Click();
            popups.DiscardChangesModal.Discard();
            #endregion

            #region Edit Number Patterns
            topic.NavigateTo();
            numberPatternsSearchResults.ClickEdit(0);
            numberTypePicklist.Clear();
            numberTypePicklist.EnterAndSelect(NumberPatternsMaintenanceDbSetUp.AcceptanceNumber);
            topic.ApplyButton(driver).ClickWithTimeout();
            topic.SaveButton(driver).ClickWithTimeout();
            topic.NavigateTo();
            Assert.AreEqual(NumberPatternsMaintenanceDbSetUp.AcceptanceNumber, numberPatternsSearchResults.CellText(0, 2), "Search returns record matching Number Type");
            Assert.AreEqual(1, topic.NumberOfRecords(), "Topic displays count");
            #endregion

            #region Delete Number Patterns
            topic.NavigateTo();
            topic.Grid.ToggleDelete(0);
            topic.SaveButton(driver).ClickWithTimeout();
            topic.NavigateTo();
            Assert.AreEqual(0, numberPatternsSearchResults.Rows.Count);
            #endregion

            #region Test Number Patterns
            topic.NavigateTo();
            topic.Add();
            topic.TestPatternButton(driver).ClickWithTimeout();
            Assert.IsTrue(topic.RunTestButton(driver).IsDisabled(), "Run Test Button is disabled");
            topic.RegexNumberPatternTextBox(driver).SendKeys("abcd");
            topic.EnterTestNumberPatternTextBox(driver).SendKeys("abc");
            topic.RunTestButton(driver).ClickWithTimeout();
            Assert.IsTrue(new TextField(driver, "testPatternNumber").HasError, "Required Field");
            topic.EnterTestNumberPatternTextBox(driver).Clear();
            topic.EnterTestNumberPatternTextBox(driver).SendKeys("abcd");
            topic.RunTestButton(driver).ClickWithTimeout();
            Assert.IsFalse(new TextField(driver, "testPatternNumber").HasError, "Required Field");
            topic.ApplyButton(driver).ClickWithTimeout();
            Assert.AreEqual("abcd", topic.PatternTextBox(driver).GetAttribute("value"), "Ensure Text Equal");
            #endregion

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard();  //edit mode discard
            pageDetails.Discard(); // discard confirm.
        }
    }
}
