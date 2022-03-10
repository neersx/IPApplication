using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.StatusType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Status : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _statusDbSetup = new StatusDbSetup();
            _scenario = _statusDbSetup.Prepare();
        }

        StatusDbSetup _statusDbSetup;
        StatusDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddStatus(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingStatusType = _scenario.ExistingStatusType;

            SignIn(driver, "/#/configuration/general/status");

            var pageDetails = new StatusDetailPage(driver);
            TestExtensions.ClickWithTimeout(pageDetails.DefaultsTopic.AddButton(driver));

            #region verify page fields
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Name(driver).GetAttribute("value"), "Ensure Internal Description is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Name(driver).GetAttribute("disabled"), "Ensure Internal Description is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.ExternalName(driver).GetAttribute("value"), "Ensure External Description is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.ExternalName(driver).GetAttribute("disabled"), "Ensure External Description is enabled");
            Assert.IsTrue(pageDetails.DefaultsTopic.CaseStatusRadioButton(driver).Selected, "Case Status radio button exists and is checked");
            Assert.IsFalse(pageDetails.DefaultsTopic.RenewalStatusRadioButton(driver).Selected, "Renewal Status radio button exists and is unchecked");
            Assert.IsTrue(pageDetails.DefaultsTopic.PendingRadioButton(driver).Selected, "Status Summary Pending radio button exists and is checked");
            Assert.IsFalse(pageDetails.DefaultsTopic.RegisteredRadioButton(driver).Selected, "Status Summary Registered radio button exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.PoliceRenewalsCheckbox(driver).Selected, "Police Renewals checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.PoliceExaminationCheckbox(driver).Selected, "Police Examination checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.PoliceOtherCheckbox(driver).Selected, "Police Other checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.ProduceLettersCheckbox(driver).Selected, "Produce Letters checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.GenerateChargesCheckbox(driver).Selected, "Generate Charges checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.PriorArtFromCheckbox(driver).Selected, "Prior Art checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.ReminderFromCheckbox(driver).Selected, "Reminder checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.BillingCheckbox(driver).Selected, "Billing checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.PrepaymentCheckbox(driver).Selected, "Prepayment checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.WipCheckbox(driver).Selected, "WIP checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.ManualStatusChangeCheckbox(driver).Selected, "Manual Status Change checkbox exists and is unchecked");

            Assert.IsTrue(pageDetails.SaveButton.IsDisabled(), "Ensure Save Button is disabled");
            Assert.IsFalse(pageDetails.DiscardButton.IsDisabled(), "Ensure Discard Button is enabled");
            #endregion

            #region Check For Unique InternalDescription And Max Length
            WithJsExt.WithJs((NgWebElement) pageDetails.DefaultsTopic.RenewalStatusRadioButton(driver)).Click();
            pageDetails.DefaultsTopic.Name(driver).SendKeys(existingStatusType.Name);
            WithJsExt.WithJs((NgWebElement) pageDetails.DefaultsTopic.RenewalStatusMaintenanceRadioButton(driver)).Click();
            driver.WaitForAngular();
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "internalName").HasError, "Internal Description should be unique");

            pageDetails.DefaultsTopic.Name(driver).Clear();

            pageDetails.DefaultsTopic.Name(driver).SendKeys("1234567891234567891234567891234567891234567891234567890");
            Assert.IsTrue(new TextField(driver, "internalName").HasError, "Description should be maximum 50 characters");
            #endregion

            #region Add Status Type
            pageDetails.DefaultsTopic.Name(driver).Clear();

            pageDetails.DefaultsTopic.Name(driver).SendKeys(StatusDbSetup.StatusToBeAdded);
            WithJsExt.WithJs((NgWebElement) pageDetails.DefaultsTopic.RenewalStatusRadioButton(driver)).Click();
            var reasonToStopSelectElement = new SelectElement(driver.FindElement(By.Name("stoppayreasons")));
            reasonToStopSelectElement.SelectByText("Unspecified");
            driver.WaitForAngularWithTimeout();
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(StatusDbSetup.StatusToBeAdded);
            WithJsExt.WithJs((NgWebElement) pageDetails.DefaultsTopic.SearchButton(driver)).Click();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(StatusDbSetup.StatusToBeAdded, searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Duplicate Status Type
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            ResetSearchTextBox(StatusDbSetup.StatusToBeAdded, pageDetails, browserType);

            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNull(pageDetails.DefaultsTopic.Name(driver).GetAttribute("disabled"), "Ensure Internal Description is enabled");

            pageDetails.DefaultsTopic.Name(driver).Clear();
            pageDetails.DefaultsTopic.Name(driver).SendKeys(StatusDbSetup.StatusToBeDuplicate);
            reasonToStopSelectElement = new SelectElement(driver.FindElement(By.Name("stoppayreasons")));
            reasonToStopSelectElement.SelectByText("Unspecified");
            driver.WaitForAngularWithTimeout();
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            ResetSearchTextBox(StatusDbSetup.StatusToBeDuplicate, pageDetails, browserType);

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(StatusDbSetup.StatusToBeDuplicate, searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Edit Status
            pageDetails = new StatusDetailPage(driver);
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            ResetSearchTextBox(StatusDbSetup.StatusToBeDuplicate, pageDetails, browserType);

            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Record should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);

            pageDetails.DefaultsTopic.Name(driver).Clear();
            pageDetails.DefaultsTopic.Name(driver).SendKeys(StatusDbSetup.StatusToBeEdit);
            reasonToStopSelectElement = new SelectElement(driver.FindElement(By.Name("stoppayreasons")));
            reasonToStopSelectElement.SelectByText("Unspecified");
            pageDetails.SaveButton.ClickWithTimeout();
            ResetSearchTextBox(StatusDbSetup.StatusToBeEdit, pageDetails, browserType);

            searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(StatusDbSetup.StatusToBeEdit, searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Delete Successfully
            ResetSearchTextBox(StatusDbSetup.StatusToBeAdded, pageDetails, browserType);
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            ResetSearchTextBox(StatusDbSetup.StatusToBeAdded, pageDetails, browserType);

            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Status should not get searched as deleted");
            #endregion

            #region Valid Status
            ResetSearchTextBox(_scenario.Name, pageDetails, browserType);
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnValidStatus(driver);
            var validStatusSelectElement = new SelectElement(driver.FindElement(By.Name("searchcharacteristic")));
            Assert.AreEqual("Status", validStatusSelectElement.SelectedOption.Text, "Ensure Internal Description is enabled");
            Assert.AreEqual(_scenario.Name, TestExtensions.Value(pageDetails.DefaultsTopic.ValidStatusPicklist(driver)), "Ensure Data Item Picklist is enabled");
            #endregion
        }

        private void ResetSearchTextBox(string internalDesc, StatusDetailPage pageDetails, BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(internalDesc);
            WithJsExt.WithJs((NgWebElement) pageDetails.DefaultsTopic.RenewalStatusRadioButton(driver)).Click();
            WithJsExt.WithJs((NgWebElement) pageDetails.DefaultsTopic.SearchButton(driver)).Click();
        }
    }
}
