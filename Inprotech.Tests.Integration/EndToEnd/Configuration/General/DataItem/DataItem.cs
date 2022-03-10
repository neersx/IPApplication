using System;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.DataItem
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DataItem : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dataItemDbSetup = new DataItemDbSetup();
            _scenario = _dataItemDbSetup.Prepare();
        }

        DataItemDbSetup _dataItemDbSetup;
        DataItemDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchDataItem(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/dataitems");

            var dataItemGroupPicklist = new PickList(driver).ById("dataitem-group-picklist");

            var pageDetails = new DataItemDetailPage(driver);

            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Sql);
            pageDetails.DefaultsTopic.IncludeSqlCheckbox(driver).Click();
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(2, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Data Item name should include sql text");

            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Sql);
            pageDetails.DefaultsTopic.IncludeSqlCheckbox(driver).Click();
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Data Item name should not include sql text");

            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Name);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Data Item name should get searched");

            ExpandCollapseAll(pageDetails, driver);

            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            dataItemGroupPicklist.EnterAndSelect(_scenario.GroupName);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Data Item group should get searched");

            pageDetails.SummaryGrid.ExpandRow(0);
            var detailRow = pageDetails.SummaryGrid.SummaryDetail(0);
            Assert.AreEqual(detailRow.Notes.Value, _scenario.ExistingItemNote.ItemNotes, "Expand row Notes should get matched");
            Assert.AreEqual(detailRow.Sql.Value, _scenario.Sql, "Expand row sql should get matched");

            ApplyFilter(pageDetails, driver);
            VerifyPageFields(pageDetails, driver);

            var popups = new CommonPopups(driver);

            CheckUniqueNameAndMaxLength(pageDetails, driver);
            ValidateSQL(pageDetails, driver);
            AddDataItem(pageDetails, driver);

            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Data Item name should get searched");
            Assert.AreEqual(DataItemDbSetup.DataItemNameToBeAdded, searchResults.CellText(0, 2), "Ensure the text is updated");

            EditDataItems(pageDetails, driver, searchResults);

            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Data Item should not get searched as deleted");

        }

        private void ApplyFilter(DataItemDetailPage pageDetails, NgWebDriver driver)
        {
            var updatedByfilter = new MultiSelectGridFilter(driver, "searchResults", "createdBy");
            updatedByfilter.Open();
            Assert.AreEqual(1, updatedByfilter.ItemCount, "Ensure that correct number of updateBy filters are retrieved");

            updatedByfilter.SelectOption(_scenario.UpdatedBy);
            updatedByfilter.Filter();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Correctly filters by updatedBy");

            updatedByfilter.Clear();

            var updatedDatefilter = new DateGridFilter(driver, "searchResults", "dateUpdated");
            updatedDatefilter.Open();
            updatedDatefilter.SetDateIsEqual(_scenario.UpdatedDate);
            updatedDatefilter.Filter();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Correctly filters by updatedDate");

            updatedDatefilter.Open();
            updatedDatefilter.SetDateIsBefore(DateTime.Today.AddDays(-1), true);
            updatedDatefilter.Filter();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Shows no records when updatedDate is more than the filtered value");
            updatedDatefilter.Clear();

            var createdDatefilter = new DateGridFilter(driver, "searchResults", "dateCreated");
            createdDatefilter.Open();
            createdDatefilter.SetDateIsEqual(_scenario.CreatedDate);
            createdDatefilter.Filter();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Correctly filters by createdDate");

            createdDatefilter.Open();
            createdDatefilter.SetDateIsBefore(DateTime.Today.AddDays(-1), true);
            createdDatefilter.Filter();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Shows no records when createdDate is more than the filtered value");
            createdDatefilter.Clear();
        }
        private void VerifyPageFields(DataItemDetailPage pageDetails, NgWebDriver driver)
        {
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Name(driver).GetAttribute("value"), "Ensure Name is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Name(driver).GetAttribute("disabled"), "Ensure Name is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description(driver).GetAttribute("value"), "Ensure Description is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Description(driver).GetAttribute("disabled"), "Ensure Description is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.DataItemGroupPickList.GetText(), "Ensure Data Item Picklist is empty");
            Assert.AreEqual(true, pageDetails.DefaultsTopic.DataItemGroupPickList.Enabled, "Ensure Data Item Picklist is enabled");
            Assert.AreEqual(true, pageDetails.DefaultsTopic.SqlStatementRadioButton(driver).Enabled, "Ensure Sql statement radio button is enabled");
            Assert.AreEqual(true, pageDetails.DefaultsTopic.SqlProcedureRadioButton(driver).Enabled, "Ensure Sql procedure radio button is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.SqlStatementTextBox(driver).GetAttribute("value").Trim(), "Ensure Sql statement is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.SqlStatementTextBox(driver).GetAttribute("disabled"), "Ensure Sql statement text box is enabled");
            Assert.Throws<NoSuchElementException>(() => pageDetails.DefaultsTopic.SqlProcedureTextBox(driver), "Ensure Sql procedure text box is not visible");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.NotesTextBox(driver).GetAttribute("value"), "Ensure Notes is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.NotesTextBox(driver).GetAttribute("disabled"), "Ensure Notes text box is enabled");
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");

        }

        private void CheckUniqueNameAndMaxLength(DataItemDetailPage pageDetails, NgWebDriver driver)
        {

            pageDetails.DefaultsTopic.Name(driver).SendKeys(_scenario.Name);
            pageDetails.DefaultsTopic.Description(driver).SendKeys(_scenario.Description);
            pageDetails.DefaultsTopic.EntryPointPicklist.EnterAndSelect("The Refererence (IRN) of a Case");
            pageDetails.DefaultsTopic.DataItemGroupPickList.EnterAndSelect("Case");
            pageDetails.DefaultsTopic.SendSQL(driver, "SELECT * FROM ITEM");
            pageDetails.DefaultsTopic.ReturnImage.Click();
            driver.WaitForAngular();
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Name should be unique");

            pageDetails.DefaultsTopic.Name(driver).Clear();
            pageDetails.DefaultsTopic.Name(driver).SendKeys("1234567891234567891234567891234567891234567891234567890");
            Assert.IsTrue(new TextField(driver, "code").HasError, "Name should be maximum 40 characters");
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            pageDetails.DiscardButton.ClickWithTimeout();
            popups.DiscardChangesModal.Discard();

        }

        private void ValidateSQL(DataItemDetailPage pageDetails, NgWebDriver driver)
        {
            var popups = new CommonPopups(driver);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.SqlStatementRadioButton(driver).WithJs().Click();
            Assert.IsFalse(pageDetails.DefaultsTopic.TestButton(driver).Enabled, "Ensure Test Button is disabled");
            pageDetails.DefaultsTopic.SendSQL(driver, "SELECT * from");
            pageDetails.DefaultsTopic.Name(driver).Click();
            Assert.IsNull(pageDetails.DefaultsTopic.TestButton(driver).GetAttribute("disabled"), "Ensure Test Button is enabled");
            pageDetails.DefaultsTopic.TestButton(driver).ClickWithTimeout();
            Assert.IsNotNull(popups.AlertModal, "Alert modal is present");
            popups.AlertModal.Ok();

            pageDetails.DefaultsTopic.SendSQL(driver, "SELECT * FROM ITEM");
            pageDetails.DefaultsTopic.TestButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.SqlProcedureRadioButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.SqlProcedureTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SqlProcedureTextBox(driver).SendKeys("ipw_GetAvailableAppLinks");
            Assert.Null(pageDetails.DefaultsTopic.TestButton(driver).GetAttribute("disabled"), "Ensure Test Button is enabled");
        }

        private void ExpandCollapseAll(DataItemDetailPage pageDetails, NgWebDriver driver)
        {
            pageDetails.DefaultsTopic.ExpandCollapseIcon(driver).Click();
            Assert.IsNotNull(pageDetails.SummaryGrid.Cell(0, 0).FindElement(By.ClassName("k-i-collapse")));
            Assert.Throws<NoSuchElementException>(() => pageDetails.SummaryGrid.Cell(0, 0).FindElement(By.ClassName("k-plus")));
            pageDetails.DefaultsTopic.ExpandCollapseIcon(driver).Click();
            Assert.IsNotNull(pageDetails.SummaryGrid.Cell(0, 0).FindElement(By.ClassName("k-i-expand")));
            Assert.Throws<NoSuchElementException>(() => pageDetails.SummaryGrid.Cell(0, 0).FindElement(By.ClassName("k-minus")));

        }

        private void EditDataItems(DataItemDetailPage pageDetails, NgWebDriver driver, KendoGrid searchResults)
        {
            var popups = new CommonPopups(driver);

            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(DataItemDbSetup.DataItemNameToBeAdded);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNull(pageDetails.DefaultsTopic.Name(driver).GetAttribute("disabled"), "Ensure Name is enabled");
            pageDetails.DefaultsTopic.Name(driver).Clear();
            pageDetails.DefaultsTopic.Name(driver).SendKeys(DataItemDbSetup.DataItemNameToBeEdited);
            pageDetails.DefaultsTopic.SqlStatementRadioButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.SendSQL(driver, "SELECT ITEM_NAME FROM ITEM");

            driver.WaitForAngular();
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsNotNull(popups.ConfirmModal, "confirm modal is present");
            popups.ConfirmModal.Proceed();
            pageDetails.DiscardButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(DataItemDbSetup.DataItemNameToBeEdited);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(DataItemDbSetup.DataItemNameToBeEdited, searchResults.CellText(0, 2), "Ensure the text is updated");
            pageDetails.SummaryGrid.ExpandRow(0);
            var detailRow = pageDetails.SummaryGrid.SummaryDetail(0);
            Assert.AreEqual(detailRow.Sql.Value, "SELECT ITEM_NAME FROM ITEM", "Expand row sql should get matched");

        }

        private void AddDataItem(DataItemDetailPage pageDetails, NgWebDriver driver)
        {
            pageDetails.DefaultsTopic.Name(driver).Clear();
            pageDetails.DefaultsTopic.Name(driver).SendKeys(DataItemDbSetup.DataItemNameToBeAdded);
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(_scenario.Description);
            pageDetails.DefaultsTopic.EntryPointPicklist.EnterAndSelect("The Refererence (IRN) of a Case");
            pageDetails.DefaultsTopic.DataItemGroupPickList.EnterAndSelect("Case");
            pageDetails.DefaultsTopic.SqlProcedureRadioButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.SqlProcedureTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SqlProcedureTextBox(driver).SendKeys("ipw_GetAvailableAppLinks");
            driver.WaitForAngular();
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(DataItemDbSetup.DataItemNameToBeAdded);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateDataItemNotDeleteDataItemGroup(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/dataitems");

            var dataItemGroupPicklist = new PickList(driver).ById("dataitem-group-picklist");

            var pageDetails = new DataItemDetailPage(driver);

            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("e3e - Group");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(2, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Data Item name should return two rows.");
            var dataItemGroup1 = driver.FindElement(By.XPath("//tr[1]/td[9]")).Text;
            var dataItemGroup2 = driver.FindElement(By.XPath("//tr[2]/td[9]")).Text;
            Assert.AreEqual("Group 2", dataItemGroup1, "Data Item group name should match.");
            Assert.AreEqual("Group 2", dataItemGroup2, "Data Item name should match.");
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("e3e - Group1");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys("update");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("e3e - Group");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual("Group 2", dataItemGroup1, "Data Item group name should match.");
            Assert.AreEqual("Group 2", dataItemGroup2, "Data Item name should match.");
        }
    }
}
