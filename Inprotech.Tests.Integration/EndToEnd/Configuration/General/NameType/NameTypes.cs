using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.NameType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class NameTypes : IntegrationTest
    {
        NameTypeDbSetup _nameTypeDbSetup;
        NameTypeDbSetup.ScenarioData _scenario;

        [SetUp]
        public void Setup()
        {
            _nameTypeDbSetup = new NameTypeDbSetup();
            _scenario = _nameTypeDbSetup.Prepare();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchNameTypeByCodeAndDescription(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/nametypes");

            #region search by code
            var pageDetails = new NameTypeDetailPage(driver);
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name type code should get searched");
            #endregion

            #region search by description
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Name);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name type description should get searched");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddNameType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingNameType = _scenario.ExistingApplicationNameType;

            SignIn(driver, "/#/configuration/general/nametypes");

            var pageDetails = new NameTypeDetailPage(driver);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            #region verify page fields
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Code(driver).GetAttribute("value"), "Ensure Code is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description(driver).GetAttribute("value"), "Ensure Description is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Description(driver).GetAttribute("disabled"), "Ensure Description is enabled");
            Assert.IsTrue(pageDetails.DefaultsTopic.MinAllowedForCaseIs0(driver).Selected, "Minimum allowed for case 0 is selected");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.MaxAllowedForCase(driver).GetAttribute("value"), "Ensure Maximum allowed for case is empty");
            Assert.IsTrue(pageDetails.DefaultsTopic.EthicalWallOptionNotApplicable(driver).Selected, "Ethical Wall option not applicable is selected");
            Assert.IsTrue(pageDetails.DefaultsTopic.DisplayNameCodeNone(driver).Selected, "Display Name Code none is selected");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.DefaultRelationshipNameType(driver).GetAttribute("value"), "Ensure Default Relationship Name Type is empty");
            Assert.IsNull(pageDetails.DefaultsTopic.DefaultRelationshipNameType(driver).GetAttribute("disabled"), "Ensure Default Relationship Name Type is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.DefaultRelationship(driver).GetAttribute("value"), "Ensure Default Relationship is empty");
            Assert.IsNotNull(pageDetails.DefaultsTopic.DefaultRelationship(driver).GetAttribute("disabled"), "Ensure Default Relationship is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.UpdateWhenParentNameChange(driver).GetAttribute("disabled"), "Ensure Update when parent name changes checkbox is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.UseNameType(driver).GetAttribute("disabled"), "Ensure use Name no checkbox is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.UseHomeNameRelationship(driver).GetAttribute("disabled"), "Ensure Use Home name relationship checkbox is disabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.DefaultToName(driver).GetAttribute("value"), "Ensure Default to Name Type is empty");
            Assert.IsNull(pageDetails.DefaultsTopic.DefaultToName(driver).GetAttribute("disabled"), "Ensure Default to Name Type is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.ChangeEvent(driver).GetAttribute("value"), "Ensure Change Event Picklist is empty");
            Assert.IsNull(pageDetails.DefaultsTopic.ChangeEvent(driver).GetAttribute("disabled"), "Ensure Change Event Picklist is enabled");
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            #endregion

            #region Check For Unique Code And Description And Max Length
            pageDetails.DefaultsTopic.Code(driver).SendKeys(existingNameType.NameTypeCode);
            pageDetails.DefaultsTopic.Description(driver).SendKeys(existingNameType.Name);
            driver.WaitForAngular();
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            Assert.IsNotNull(popups.AlertModal, "Alert modal is present");
            popups.AlertModal.Ok();

            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();

            pageDetails.DefaultsTopic.Code(driver).SendKeys("****");
            Assert.IsTrue(new TextField(driver, "nameTypeCode").HasError, "Code should be maximum 3 characters");

            pageDetails.DefaultsTopic.Description(driver).SendKeys("12345678901234567890123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "name").HasError, "Description should be maximum 50 characters");
            #endregion

            #region Verify mutually exclusive fields
            pageDetails.DefaultsTopic.Attention.Click();
            Assert.IsTrue(pageDetails.DefaultsTopic.Attention.IsChecked, "contact name should be checked");
            
            pageDetails.DefaultsTopic.NationalityCheckBox.Click();
            Assert.IsTrue(pageDetails.DefaultsTopic.NationalityCheckBox.IsChecked, "nationality is selected");

            pageDetails.DefaultsTopic.NameTypePicklist.EnterAndSelect("Instructor");
            driver.WaitForAngularWithTimeout();

            pageDetails.DefaultsTopic.RelationshipPicklist.EnterAndSelect("Bank Branch Of");
            driver.WaitForAngularWithTimeout();

            pageDetails.DefaultsTopic.UseNameTypeCheckbox.Click();
            Assert.IsTrue(pageDetails.DefaultsTopic.UseNameTypeCheckbox.IsChecked, "use name no is selected");
            Assert.IsFalse(pageDetails.DefaultsTopic.UseHomeNameRelationshipCheckbox.IsChecked, "use home name relationship should not be selected when use name no is selected");

            pageDetails.DefaultsTopic.UseHomeNameRelationshipCheckbox.Click();
            Assert.IsFalse(pageDetails.DefaultsTopic.UseNameTypeCheckbox.IsChecked, "use name type is not selected");
            Assert.IsTrue(pageDetails.DefaultsTopic.UseHomeNameRelationshipCheckbox.IsChecked, "use home name relationship is selected");

            pageDetails.DefaultsTopic.NameTypePicklist.Clear();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.DefaultRelationship(driver).GetAttribute("value"), "Ensure Default Relationship is empty");
            Assert.IsNotNull(pageDetails.DefaultsTopic.DefaultRelationship(driver).GetAttribute("disabled"), "Ensure Default Relationship is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.UpdateWhenParentNameChange(driver).GetAttribute("disabled"), "Ensure Update when parent name changes checkbox is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.UseNameType(driver).GetAttribute("disabled"), "Ensure use Name no checkbox is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.UseHomeNameRelationship(driver).GetAttribute("disabled"), "Ensure Use Home name relationship checkbox is disabled");

            #endregion

            #region Add Name Type
            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();

            pageDetails.DefaultsTopic.Code(driver).SendKeys(NameTypeDbSetup.NameTypeCode);
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NameTypeDbSetup.NameTypeToBeAdded);

            pageDetails.DefaultsTopic.NameTypePicklist.EnterAndSelect("Renewal Agent");
            driver.WaitForAngularWithTimeout();

            pageDetails.DefaultsTopic.RelationshipPicklist.EnterAndSelect("Bank Branch Of");
            driver.WaitForAngularWithTimeout();

            pageDetails.DefaultsTopic.EventPicklist.EnterAndSelect("-1011828");
            driver.WaitForAngularWithTimeout();
            pageDetails.DefaultsTopic.UseHomeNameRelationshipCheckbox.Click();
            pageDetails.DefaultsTopic.NameTypeGroupPicklist.EnterAndSelect("EDE NAME GROUP");
            pageDetails.SaveButton.ClickWithTimeout();

            // verify if the saved value has the nationality set to true.
            var savedNameType = DbSetup.Do(x =>
            {
                return x.DbContext.Set<InprotechKaizen.Model.Cases.NameType>()
                                                          .SingleOrDefault(_ => _.NameTypeCode == NameTypeDbSetup.NameTypeCode);
            });
            Assert.IsTrue(savedNameType.NationalityFlag);

            // Priority window
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.SetNameTypePriorityButtonDown(driver).GetAttribute("disabled"), "Ensure Down Button is disabled");
            Assert.Null(pageDetails.DefaultsTopic.SetNameTypePriorityButtonUp(driver).GetAttribute("disabled"), "Ensure Up Button is enabled");
            var prioritySearchResults = new KendoGrid(driver, "validNameTypesResults");
            var secondRowCodeValue = prioritySearchResults.CellText(1, 0);
            prioritySearchResults.Cell(1, 0).Click();
            pageDetails.DefaultsTopic.SetNameTypePriorityButtonUp(driver).Click();
            pageDetails.SaveButton.ClickWithTimeout();

            Assert.AreEqual(secondRowCodeValue, prioritySearchResults.CellText(0, 0), "Ensure priority order updated");
            pageDetails.DiscardButton.ClickWithTimeout();

            // Search by Name Type Description and Name Type Group
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameTypeDbSetup.NameTypeToBeAdded);
            pageDetails.DefaultsTopic.NameTypeGroupSearchPicklist.EnterAndSelect("EDE NAME GROUP");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(NameTypeDbSetup.NameTypeCode, searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual(NameTypeDbSetup.NameTypeToBeAdded, searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DuplicateNameType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/nametypes");

            var pageDetails = new NameTypeDetailPage(driver);

            #region Duplicate Name Type
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name type code should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Code(driver).SendKeys("#");
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NameTypeDbSetup.NameTypeToBeDuplicate);
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            var prioritySearchResults = new KendoGrid(driver, "validNameTypesResults");
            var secondRowCodeValue = prioritySearchResults.CellText(1, 0);
            prioritySearchResults.Cell(1, 0).Click();
            pageDetails.DefaultsTopic.SetNameTypePriorityButtonUp(driver).Click();
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.AreEqual(secondRowCodeValue, prioritySearchResults.CellText(0, 0), "Ensure priority order updated");
            pageDetails.DiscardButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameTypeDbSetup.NameTypeToBeDuplicate);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("#", searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual(NameTypeDbSetup.NameTypeToBeDuplicate, searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteNameType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/nametypes");

            var pageDetails = new NameTypeDetailPage(driver);
            var popups = new CommonPopups(driver);

            #region Delete Successfully
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name type code should not get searched as deleted");
            #endregion

            #region Unable to complete as records in use
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("Contact");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Result should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Result should get searched as in use");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditNameType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/nametypes");

            var pageDetails = new NameTypeDetailPage(driver);
            var popups = new CommonPopups(driver);

            #region Edit Name Type
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameTypeDbSetup.NameTypeDescription);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Record should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is disabled");
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NameTypeDbSetup.NameTypeToBeEdit);
            
            #region Verify Same Name Type dialog
            pageDetails.DefaultsTopic.SameNameType.Click();
            Assert.IsNotNull(popups.ConfirmModal, "confirm modal is present");
            popups.ConfirmModal.No().Click();
            #endregion

            // click on the nationalityChkBox and get its state, so it can be compared to how it's got saved later
            pageDetails.DefaultsTopic.NationalityCheckBox.Click();
            var isNationalityChecked = pageDetails.DefaultsTopic.NationalityCheckBox.IsChecked;

            pageDetails.SaveButton.ClickWithTimeout();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(NameTypeDbSetup.NameTypeToBeEdit, searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion

            var savedNameType = DbSetup.Do(x =>
            {
                return x.DbContext.Set<InprotechKaizen.Model.Cases.NameType>()
                                                            .SingleOrDefault(_ => _.NameTypeCode == _scenario.Code);
            });

            Assert.AreEqual(isNationalityChecked, savedNameType.NationalityFlag ); 
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SetNameTypePriority(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/nametypes");

            var pageDetails = new NameTypeDetailPage(driver);

            #region Set Name Type Priority by button up
            pageDetails.DefaultsTopic.SetNameTypePriorityLink(driver).Click();
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.SetNameTypePriorityButtonDown(driver).GetAttribute("disabled"), "Ensure Down Button is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.SetNameTypePriorityButtonUp(driver).GetAttribute("disabled"), "Ensure Up Button is disabled");
            var searchResults = new KendoGrid(driver, "validNameTypesResults");
            var secondRowCodeValue = searchResults.CellText(1, 0);
            searchResults.Cell(1, 0).Click();
            pageDetails.DefaultsTopic.SetNameTypePriorityButtonUp(driver).Click();
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SetNameTypePriorityLink(driver).Click();
            Assert.AreEqual(secondRowCodeValue, searchResults.CellText(0, 0), "Ensure priority order updated");
            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion

            #region Set Name Type Priority by button down
            pageDetails.DefaultsTopic.SetNameTypePriorityLink(driver).Click();
            var firstRowCodeValue = searchResults.CellText(0, 0);
            searchResults.Cell(0, 0).Click();
            pageDetails.DefaultsTopic.SetNameTypePriorityButtonDown(driver).Click();
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SetNameTypePriorityLink(driver).Click();
            Assert.AreEqual(firstRowCodeValue, searchResults.CellText(1, 0), "Ensure priority order updated");
            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion
        }
    }
}
