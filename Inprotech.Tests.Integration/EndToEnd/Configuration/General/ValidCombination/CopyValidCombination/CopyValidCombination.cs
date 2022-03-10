using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.CopyValidCombination
{
    [Category(Categories.E2E)]
    [TestFixture]
    class CopyValidCombination : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var copyValidCombinationDbSetup = new CopyValidCombinationDbSetup();
            copyValidCombinationDbSetup.PrepareEnvironment();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CopyValidCombinations(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/validcombination");

            var searchCharacteristic = new SelectElement(driver.FindElement(By.Name("searchcharacteristic")));
            var jurisdiction = new PickList(driver).ById("jurisdiction-picklist");
            var fromjurisdiction = new PickList(driver).ById("from-jurisdiction");
            var toJurisdiction = new PickList(driver).ById("to-jurisdiction");

            var pageDetails = new CopyValidCombinationDetailPage(driver);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            #region verify page fields
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            #endregion

            #region Copy Valid Combination
            pageDetails.DefaultsTopic.CopyRadioButton(driver).WithJs().Click();
            fromjurisdiction.EnterAndSelect("e2e");
            Assert.IsFalse(pageDetails.SaveButton.IsDisabled(), "Ensure Save Button is enabled");
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(toJurisdiction.HasError, "Required Field");
            toJurisdiction.EnterAndSelect("e3e");
            pageDetails.SaveButton.ClickWithTimeout();
            var popups = new CommonPopups(driver);
            popups.ConfirmModal.Save().ClickWithTimeout();
            #endregion

            #region Search Newly Copied Valid Combination
            //Search Action
            searchCharacteristic.SelectByText("Action");
            jurisdiction.EnterAndSelect("e3e");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            var validCombinationSearchResults = new KendoGrid(driver, "validCombinationSearchResults");
            Assert.IsTrue(validCombinationSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Properties", validCombinationSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e3e - jurisdiction", validCombinationSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", validCombinationSearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual("CPA Events", validCombinationSearchResults.CellText(0, 4), "Ensure value");

            //Search Basis
            searchCharacteristic.SelectByText("Basis");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(validCombinationSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("e3e - jurisdiction", validCombinationSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", validCombinationSearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual("Claiming Paris Convention", validCombinationSearchResults.CellText(0, 5), "Ensure value");

            //Search Category
            searchCharacteristic.SelectByText("Category");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(validCombinationSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Properties", validCombinationSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e3e - jurisdiction", validCombinationSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", validCombinationSearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual(".BIZ", validCombinationSearchResults.CellText(0, 4), "Ensure value");
            Assert.AreEqual(".BIZ", validCombinationSearchResults.CellText(0, 5), "Ensure value");

            //Search Checklist
            searchCharacteristic.SelectByText("Checklist");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(validCombinationSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Properties", validCombinationSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e3e - jurisdiction", validCombinationSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", validCombinationSearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual("Initial information", validCombinationSearchResults.CellText(0, 4), "Ensure value");
            Assert.AreEqual("Initial information", validCombinationSearchResults.CellText(0, 5), "Ensure value");

            //Search Property Type
            searchCharacteristic.SelectByText("Property Type");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(validCombinationSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("e3e - jurisdiction", validCombinationSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("Patents", validCombinationSearchResults.CellText(0, 2), "Ensure value");

            //Search Relationship
            searchCharacteristic.SelectByText("Case Relationship");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(validCombinationSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("e3e - jurisdiction", validCombinationSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("Patents", validCombinationSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Agreement", validCombinationSearchResults.CellText(0, 3), "Ensure value");

            //Search Status
            searchCharacteristic.SelectByText("Status");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(validCombinationSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Properties", validCombinationSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e3e - jurisdiction", validCombinationSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", validCombinationSearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual("Abandoned by client", validCombinationSearchResults.CellText(0, 4), "Ensure value");

            //Search Sub Type
            searchCharacteristic.SelectByText("Sub Type");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(validCombinationSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Properties", validCombinationSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e3e - jurisdiction", validCombinationSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", validCombinationSearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual(".BIZ", validCombinationSearchResults.CellText(0, 4), "Ensure value");
            Assert.AreEqual("5 yearly renewals", validCombinationSearchResults.CellText(0, 5), "Ensure value");
            #endregion
        }
    }
}