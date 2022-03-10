using System.Globalization;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.PropertyType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class PropertyTypePicklist : IntegrationTest
    {
        [SetUp]
        public void ClassInit()
        {
            _propertyTypePicklistDbSetup = new PropertyTypePicklistDbSetup();
            _scenario = _propertyTypePicklistDbSetup.Prepare();
        }

        PropertyTypePicklistDbSetup _propertyTypePicklistDbSetup;
        PropertyTypePicklistDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CopyPropertyTypeDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/propertytype");

            var propertyTypePicklist = new PickList(driver).ByName(string.Empty, "propertyType");
            propertyTypePicklist.OpenPickList(PropertyTypePicklistDbSetup.ExistingPropertyType3);
            propertyTypePicklist.DuplicateRow(0);

            var pageDetails = new PropertyTypeDetailPage(driver);
            Assert.AreEqual("3", pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is same");
            Assert.IsNull(pageDetails.DefaultsTopic.Code.GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(PropertyTypePicklistDbSetup.ExistingPropertyType3, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is same");
            Assert.AreEqual(pageDetails.DefaultsTopic.AllowSubClass.Value, "1");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("Z");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(PropertyTypePicklistDbSetup.PropertyTypeToBeAdded);

            pageDetails.SaveButton.ClickWithTimeout();

            propertyTypePicklist.SearchFor(PropertyTypePicklistDbSetup.PropertyTypeToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(PropertyTypePicklistDbSetup.PropertyTypeToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("Z", searchResults.CellText(0, 1), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckClientSideValidationForMandatoryAndMaxLength(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/propertytype");

            var propertyTypePicklist = new PickList(driver).ByName(string.Empty, "propertyType");
            propertyTypePicklist.SearchButton.Click();
            propertyTypePicklist.AddPickListItem();

            var pageDetails = new PropertyTypeDetailPage(driver);
            Assert.IsTrue(pageDetails.SaveButton.GetAttribute("disabled").Equals("true"), "Ensure Save is disabled");

            pageDetails.DefaultsTopic.Code.SendKeys("Z");
            driver.WaitForAngular();
            pageDetails.SaveButton.Click();

            Assert.IsTrue(new TextField(driver, "value").HasError, "Description is mandatory");

            pageDetails.DefaultsTopic.Code.Clear();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code is mandatory");

            pageDetails.DefaultsTopic.Code.SendKeys("ZZ");
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be maximum 1 character");

            pageDetails.DefaultsTopic.Description.SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be maximum 50 characters");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("Z");
            Assert.IsFalse(new TextField(driver, "code").HasError);

            driver.WaitForAngular();
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys("AAA");
            Assert.IsFalse(new TextField(driver, "value").HasError);

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); // edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckForUniqueCodeAndDescription(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingPropertyType = _scenario.ExistingPropertyType;

            SignIn(driver, "/#/configuration/general/validcombination/propertytype");

            var propertyTypePicklist = new PickList(driver).ByName(string.Empty, "propertyType");
            propertyTypePicklist.SearchButton.Click();
            propertyTypePicklist.AddPickListItem();

            var pageDetails = new PropertyTypeDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys(existingPropertyType.Code);
            pageDetails.DefaultsTopic.Description.SendKeys("abcd");
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be unique");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("Z");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(existingPropertyType.Name);
            pageDetails.SaveButton.ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be unique");

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); // edit mode discard
            pageDetails.Discard(); // discard confirm.
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class PropertyTypePicklistDelete : IntegrationTest
    {
        [SetUp]
        public void ClassInit()
        {
            _propertyTypePicklistDbSetup = new PropertyTypePicklistDbSetup();
            _scenario = _propertyTypePicklistDbSetup.Prepare();
        }

        PropertyTypePicklistDbSetup _propertyTypePicklistDbSetup;
        PropertyTypePicklistDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeletePropertyTypeDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/propertytype");

            var propertyTypePicklist = new PickList(driver).ByName(string.Empty, "propertyType");
            propertyTypePicklist.OpenPickList(PropertyTypePicklistDbSetup.ExistingPropertyType2);
            propertyTypePicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            propertyTypePicklist.SearchFor(PropertyTypePicklistDbSetup.ExistingPropertyType2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "Property type should get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ClickDeletePropertyTypeAndThenClickNoOnConfirmation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/propertytype");

            var propertyTypePicklist = new PickList(driver).ByName(string.Empty, "propertyType");
            propertyTypePicklist.OpenPickList(PropertyTypePicklistDbSetup.ExistingPropertyType2);
            propertyTypePicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Cancel().ClickWithTimeout();

            propertyTypePicklist.SearchFor(PropertyTypePicklistDbSetup.ExistingPropertyType2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Property type value should not get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeletePropertyTypeDetailsWhichIsInUse(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            _propertyTypePicklistDbSetup.AddValidPropertyType(_scenario.ExistingPropertyType);

            SignIn(driver, "/#/configuration/general/validcombination/propertytype");

            var propertyTypePicklist = new PickList(driver).ByName(string.Empty, "propertyType");
            propertyTypePicklist.OpenPickList(_scenario.ExistingPropertyType.Name);
            propertyTypePicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();

            propertyTypePicklist.SearchFor(PropertyTypePicklistDbSetup.ExistingPropertyType);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(3, searchResults.Rows.Count, "Property type should not get deleted");
            Assert.AreEqual(_scenario.ExistingPropertyType.Name, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class PropertyTypePicklistEditing : IntegrationTest
    {
        [SetUp]
        public void ClassInit()
        {
            _propertyTypePicklistDbSetup = new PropertyTypePicklistDbSetup();
            _scenario = _propertyTypePicklistDbSetup.Prepare();
        }

        PropertyTypePicklistDbSetup _propertyTypePicklistDbSetup;
        PropertyTypePicklistDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddPropertyTypeDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/propertytype");

            var propertyTypePicklist = new PickList(driver).ByName(string.Empty, "propertyType");
            propertyTypePicklist.SearchButton.Click();
            propertyTypePicklist.AddPickListItem();

            var pageDetails = new PropertyTypeDetailPage(driver);
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Code.GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.AllowSubClass.Element.GetAttribute("disabled"), "Allow sub class drop down is enabled");

            pageDetails.DefaultsTopic.Code.SendKeys("Z");
            pageDetails.DefaultsTopic.Description.SendKeys(PropertyTypePicklistDbSetup.PropertyTypeToBeAdded);
            pageDetails.DefaultsTopic.AllowSubClass.Input.SelectByText("Allow Sub-Classes");
            pageDetails.DefaultsTopic.Icon.SendKeys(_scenario.IconName);
            pageDetails.SaveButton.ClickWithTimeout();

            Assert.AreEqual(PropertyTypePicklistDbSetup.PropertyTypeToBeAdded, propertyTypePicklist.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("Z", propertyTypePicklist.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            Assert.IsTrue(propertyTypePicklist.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            propertyTypePicklist.SearchFor(PropertyTypePicklistDbSetup.PropertyTypeToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(PropertyTypePicklistDbSetup.PropertyTypeToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("Z", searchResults.CellText(0, 1), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditAndSavePropertyTypeDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingPropertyType = _scenario.ExistingPropertyType;

            SignIn(driver, "/#/configuration/general/validcombination/propertytype");

            var propertyTypePicklist = new PickList(driver).ByName(string.Empty, "propertyType");
            propertyTypePicklist.OpenPickList(_scenario.PropertyTypeName);
            propertyTypePicklist.EditRow(0);
            var pageDetails = new PropertyTypeDetailPage(driver);

            Assert.AreEqual(existingPropertyType.Code, pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is equal");
            Assert.IsTrue(pageDetails.DefaultsTopic.Code.GetAttribute("disabled").Equals("true"), "Ensure Code is disabled");
            Assert.AreEqual(existingPropertyType.Name, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is equal");
            Assert.AreEqual(existingPropertyType.AllowSubClass.ToString(CultureInfo.InvariantCulture), pageDetails.DefaultsTopic.AllowSubClass.Value);

            var editedName = existingPropertyType.Name + " edited";
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(editedName);
            pageDetails.DefaultsTopic.Icon.SendKeys(_scenario.IconName);
            pageDetails.SaveButton.ClickWithTimeout();

            propertyTypePicklist.SearchFor(editedName);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Only one row is returned");
            Assert.AreEqual(editedName, searchResults.CellText(0, 0), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DiscardCancelDialogOnPropertyTypeChange(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/propertytype");

            var propertyTypePicklist = new PickList(driver).ByName(string.Empty, "propertyType");
            propertyTypePicklist.OpenPickList(_scenario.PropertyTypeName);
            propertyTypePicklist.AddPickListItem();

            var pageDetails = new PropertyTypeDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys("Z");

            pageDetails.DefaultsTopic.AllowSubClass.Input.SelectByText("Allow Sub-Classes");
            pageDetails.Discard();

            var popup = new CommonPopups(driver);
            popup.DiscardChangesModal.Cancel();
            Assert.AreEqual(pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Z", "Code is not lost");

            pageDetails.Discard();
            popup.DiscardChangesModal.Discard();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("code")));
        }
    }
}