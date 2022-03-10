using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Locality
{
    [Category(Categories.E2E)]
    [TestFixture]
    class Locality : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _localityDbSetup = new LocalityDbSetUp();
            _scenario = _localityDbSetup.Prepare();
        }

        LocalityDbSetUp _localityDbSetup;
        LocalityDbSetUp.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainLocality(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/names/locality");

            var statePicklist = new PickList(driver).ById("state-picklist");

            var pageDetails = new LocalityDetailPage(driver);

            #region Add Locality
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.Code(driver).SendKeys("E5E");
            pageDetails.DefaultsTopic.Name(driver).SendKeys("Add");
            statePicklist.SendKeys("South Australia");
            pageDetails.DefaultsTopic.City(driver).SendKeys("Add");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("Add");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Locality should get searched");
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual("E5E", searchResults.CellText(0, 1), "Ensure the text is same");
            Assert.AreEqual("Add", searchResults.CellText(0, 2), "Ensure the text is same");
            Assert.AreEqual("Add", searchResults.CellText(0, 3), "Ensure the text is same");
            Assert.AreEqual("South Australia", searchResults.CellText(0, 4), "Ensure the text is same");
            Assert.AreEqual("Australia", searchResults.CellText(0, 5), "Ensure the text is same");
            #endregion

            #region Edit Locality
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.ExistingLocalityCode2);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Locality should get searched");
            Assert.AreEqual(_scenario.ExistingLocalityCode2, searchResults.CellText(0, 1), "Ensure the text is same");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is disabled");
            Assert.IsTrue(pageDetails.DefaultsTopic.NavigationBar(driver).Displayed, "Ensure Navigation Bar is visible");
            pageDetails.DefaultsTopic.Name(driver).SendKeys("Edit");
            statePicklist.SendKeys("South Australia");
            pageDetails.DefaultsTopic.City(driver).SendKeys("Edit");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("Edit");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Locality should get searched");
            Assert.AreEqual(_scenario.ExistingLocalityCode2, searchResults.CellText(0, 1), "Ensure the text is same");
            Assert.AreEqual("Edit", searchResults.CellText(0, 2), "Ensure the text is same");
            Assert.AreEqual("Edit", searchResults.CellText(0, 3), "Ensure the text is same");
            Assert.AreEqual("South Australia", searchResults.CellText(0, 4), "Ensure the text is same");
            Assert.AreEqual("Australia", searchResults.CellText(0, 5), "Ensure the text is same");
            #endregion

            #region Duplicate Locality
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.ExistingLocalityCode2);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Locality should get searched");
            Assert.AreEqual(_scenario.ExistingLocalityCode2, searchResults.CellText(0, 1), "Ensure the text is same");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            pageDetails.DefaultsTopic.Code(driver).SendKeys("DUP");
            pageDetails.DefaultsTopic.Name(driver).Clear();
            pageDetails.DefaultsTopic.Name(driver).SendKeys("Duplicate");
            pageDetails.DefaultsTopic.City(driver).Clear();
            pageDetails.DefaultsTopic.City(driver).SendKeys("Duplicate");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("DUP");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Locality should get searched");
            Assert.AreEqual("DUP", searchResults.CellText(0, 1), "Ensure the text is same");
            Assert.AreEqual("Duplicate", searchResults.CellText(0, 2), "Ensure the text is same");
            Assert.AreEqual("Duplicate", searchResults.CellText(0, 3), "Ensure the text is same");
            Assert.AreEqual("South Australia", searchResults.CellText(0, 4), "Ensure the text is same");
            Assert.AreEqual("Australia", searchResults.CellText(0, 5), "Ensure the text is same");
            #endregion

            #region Delete Locality Successfully
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.ExistingLocalityCode2);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Locality should get searched");
            Assert.AreEqual(_scenario.ExistingLocalityCode2, searchResults.CellText(0, 1), "Ensure the text is same");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Locality should not get searched as deleted");
            #endregion

            #region Unable to Delete Locality as in use
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.ExistingLocalityCode1);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Locality should get searched");
            Assert.AreEqual(_scenario.ExistingLocalityCode1, searchResults.CellText(0, 1), "Ensure the text is same");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Result should get searched as in use");
            #endregion
        }
    }
}
