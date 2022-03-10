using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.Action
{
    [Category(Categories.E2E)]
    [TestFixture]
    class Action : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var actionDbSetup = new ActionDbSetup();
            actionDbSetup.PrepareEnvironment();
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainValidCombinationAction(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/validcombination/action");

            var caseType = new PickList(driver).ById("case-type-picklist");
            var jurisdiction = new PickList(driver).ById("jurisdiction-picklist");
            var propertyType = new PickList(driver).ById("property-type-picklist");
            var maintainCaseType = new PickList(driver).ById("pk-case-type");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainAction = new PickList(driver).ById("pk-action");

            var pageDetails = new ActionDetailPage(driver);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            #region verify page fields
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion

            #region Verify SearchCriteria is prepopulated
            caseType.EnterAndSelect("Properties");
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            Assert.IsNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            #endregion

            #region Add and Search Valid Action
            Assert.IsFalse(pageDetails.SaveButton.IsDisabled(), "Ensure Save Button is enabled");
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(maintainJurisdiction.HasError, "Required Field");
            Assert.IsTrue(maintainPropertyType.HasError, "Required Field");
            Assert.IsTrue(maintainAction.HasError, "Required Field");
            Assert.IsTrue(new IpTextField(driver).ByName("validDescription").HasError, "Required Field");
            maintainJurisdiction.EnterAndSelect("e2e");
            maintainPropertyType.EnterAndSelect("Patents");
            maintainAction.EnterAndSelect("Acceptance");
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(pageDetails.DefaultsTopic.ActionOrderWindow(driver).Displayed);
            Assert.IsTrue(pageDetails.DefaultsTopic.ActionOrderWindowUpButton(driver).IsDisabled());
            Assert.IsTrue(pageDetails.DefaultsTopic.ActionOrderWindowDownButton(driver).IsDisabled());
            Assert.IsTrue(pageDetails.SaveButton.IsDisabled());
            Assert.IsFalse(pageDetails.DiscardButton.IsDisabled());
            Assert.IsFalse(pageDetails.DefaultsTopic.ActionOrderWindowNavigationBar(driver).IsDisabled());
            Assert.IsFalse(maintainCaseType.Enabled);
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.AreEqual("Properties", maintainCaseType.GetText(), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", maintainJurisdiction.GetText(), "Ensure value");
            Assert.AreEqual("Patents", maintainPropertyType.GetText(), "Ensure value");
            var prioritySearchResults = new KendoGrid(driver, "validActionResults");
            Assert.AreEqual("AC", prioritySearchResults.CellText(0, 0), "Ensure value");
            Assert.AreEqual("Acceptance", prioritySearchResults.CellText(0, 1), "Ensure value");
            pageDetails.DiscardButton.ClickWithTimeout();

            caseType.EnterAndSelect("Properties");
            jurisdiction.EnterAndSelect("e2e");
            propertyType.EnterAndSelect("Patents");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            var actionSearchResults = new KendoGrid(driver, "validCombinationSearchResults");
            Assert.IsTrue(actionSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Properties", actionSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", actionSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", actionSearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual("Acceptance", actionSearchResults.CellText(0, 4), "Ensure value");
            Assert.AreEqual("Acceptance", actionSearchResults.CellText(0, 5), "Ensure value");
            #endregion

            #region Edit Valid Action
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainCaseType.Enabled);
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsFalse(maintainAction.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys("e2e description");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(actionSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("e2e description", actionSearchResults.CellText(0, 5), "Ensure value");
            #endregion

            #region Duplicate Valid Action
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainCaseType.Enabled);
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainAction.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual("Properties", maintainCaseType.GetText(), "Ensure value");
            Assert.AreEqual("Patents", maintainPropertyType.GetText(), "Ensure value");
            Assert.AreEqual("Acceptance", maintainAction.GetText(), "Ensure value");
            Assert.AreEqual("e2e description", pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");

            maintainAction.Clear();
            maintainAction.EnterAndSelect("CPA Events");
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(pageDetails.DefaultsTopic.ActionOrderWindow(driver).Displayed);
            Assert.AreEqual("CP", prioritySearchResults.CellText(1, 0), "Ensure value");
            Assert.AreEqual("CPA Events", prioritySearchResults.CellText(1, 1), "Ensure value");
            pageDetails.DiscardButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(actionSearchResults.Rows.Count.Equals(2));
            Assert.AreEqual("Properties", actionSearchResults.CellText(1, 1), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", actionSearchResults.CellText(1, 2), "Ensure value");
            Assert.AreEqual("Patents", actionSearchResults.CellText(1, 3), "Ensure value");
            Assert.AreEqual("CPA Events", actionSearchResults.CellText(1, 4), "Ensure value");
            Assert.AreEqual("CPA Events", actionSearchResults.CellText(1, 5), "Ensure value");
            #endregion

            #region Delete Valid Action
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.IsTrue(actionSearchResults.Rows.Count.Equals(0));
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainValidActionPriorityOrder(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/validcombination/action");

            var caseType = new PickList(driver).ById("case-type-picklist");
            var jurisdiction = new PickList(driver).ById("jurisdiction-picklist");
            var propertyType = new PickList(driver).ById("property-type-picklist");
            var maintainCaseType = new PickList(driver).ById("pk-case-type");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");

            var pageDetails = new ActionDetailPage(driver);

            #region Maintain Valid Action Priority
            caseType.EnterAndSelect("Properties");
            jurisdiction.EnterAndSelect("Australia");
            propertyType.EnterAndSelect("Patents");
            pageDetails.DefaultsTopic.ActionPriorityOrderLink(driver).ClickWithTimeout();

            Assert.IsTrue(pageDetails.DefaultsTopic.ActionOrderWindow(driver).Displayed);
            Assert.IsTrue(pageDetails.DefaultsTopic.ActionOrderWindowUpButton(driver).IsDisabled());
            Assert.IsTrue(pageDetails.DefaultsTopic.ActionOrderWindowDownButton(driver).IsDisabled());
            Assert.IsTrue(pageDetails.SaveButton.IsDisabled());
            Assert.IsFalse(pageDetails.DiscardButton.IsDisabled());
            Assert.IsTrue(maintainCaseType.Enabled);
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.AreEqual("Properties", maintainCaseType.GetText(), "Ensure value");
            Assert.AreEqual("Australia", maintainJurisdiction.GetText(), "Ensure value");
            Assert.AreEqual("Patents", maintainPropertyType.GetText(), "Ensure value");
            var prioritySearchResults = new KendoGrid(driver, "validActionResults");
            var secondRowCodeValue = prioritySearchResults.CellText(1, 0);
            prioritySearchResults.Cell(1, 0).Click();
            pageDetails.DefaultsTopic.ActionOrderWindowUpButton(driver).Click();
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.AreEqual(secondRowCodeValue, prioritySearchResults.CellText(0, 0), "Ensure priority order updated");
            prioritySearchResults.Cell(0, 0).Click();
            pageDetails.DefaultsTopic.ActionOrderWindowDownButton(driver).Click();
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.AreEqual(secondRowCodeValue, prioritySearchResults.CellText(1, 0), "Ensure priority order updated");
            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion

        }
    }
}
