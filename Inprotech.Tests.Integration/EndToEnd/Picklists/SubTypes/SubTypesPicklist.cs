using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.SubTypes
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SubTypePicklist : IntegrationTest
    {
        [SetUp]
        public void SetUp()
        {
            _subTypePicklistsDbSetup = new SubtypePicklistsDbSetup();
            _scenario = _subTypePicklistsDbSetup.Prepare();
        }

        SubtypePicklistsDbSetup _subTypePicklistsDbSetup;
        SubtypePicklistsDbSetup.ScenarioData _scenario;
        const string ValidcombinationSubtypeUrl = "/#/configuration/general/validcombination/subtype";

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddSubTypeDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, ValidcombinationSubtypeUrl);
            var subTypePicklist = new PickList(driver).ByName(string.Empty, "subType");
            subTypePicklist.OpenPickList(string.Empty);

            driver.FindElement(By.Name("plus-circle")).Click();

            var pageDetails = new SubTypesDetailPage(driver);
            Assert.True(pageDetails.SaveButton.GetAttribute("disabled").Equals("true"));

            var addSubTypeDescription = _scenario.PrefixSubTypes + " added";

            pageDetails.DefaultsTopic.Code.SendKeys("x9");
            pageDetails.DefaultsTopic.Description.SendKeys(addSubTypeDescription);
            pageDetails.SaveButton.ClickWithTimeout();

            Assert.AreEqual(addSubTypeDescription, subTypePicklist.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("x9", subTypePicklist.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            Assert.IsTrue(subTypePicklist.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            subTypePicklist.SearchFor(_scenario.PrefixSubTypes + " added");

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CopySubTypeDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, ValidcombinationSubtypeUrl);
            var subTypePicklist = new PickList(driver).ByName(string.Empty, "subType");
            subTypePicklist.OpenPickList(_scenario.ExistingSubType.Name);

            subTypePicklist.DuplicateRow(0);

            var pageDetails = new SubTypesDetailPage(driver);
            Assert.True(pageDetails.SaveButton.GetAttribute("disabled").Equals("true"));
            Assert.True(pageDetails.DefaultsTopic.Code.Enabled);
            Assert.True(pageDetails.DefaultsTopic.Description.Enabled);

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("x");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(_scenario.ExistingSubType.Name + " copy");
            pageDetails.SaveButton.ClickWithTimeout();

            subTypePicklist.SearchFor(_scenario.ExistingSubType.Name + " copy");
            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ClickDeleteSaveSubTypeAndThenClickNoOnConfirmation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, ValidcombinationSubtypeUrl);

            var subTypePicklist = new PickList(driver).ByName(string.Empty, "subType");
            subTypePicklist.OpenPickList(_scenario.ExistingSubType2.Name);
            subTypePicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Cancel().ClickWithTimeout();

            subTypePicklist.SearchFor(_scenario.ExistingSubType2.Name);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "SubType should not get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteSubTypeWhenNotInUse(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, ValidcombinationSubtypeUrl);

            var subTypePicklist = new PickList(driver).ByName(string.Empty, "subType");
            subTypePicklist.OpenPickList(_scenario.ExistingSubType2.Name);
            subTypePicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();
            driver.WaitForAngular();

            subTypePicklist.SearchFor(_scenario.ExistingSubType2.Name);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "SubType should get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldNotDeleteSubTypeWhenInUse(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            _subTypePicklistsDbSetup.CreateValidSubTypeCombination(_scenario.ExistingSubType);
            SignIn(driver, ValidcombinationSubtypeUrl);

            var subTypePicklist = new PickList(driver).ByName(string.Empty, "subType");
            subTypePicklist.OpenPickList(_scenario.ExistingSubType.Name);
            subTypePicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            driver.WaitForAngular();
            popups.AlertModal.Ok();

            subTypePicklist.SearchFor(_scenario.ExistingSubType.Name);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "SubType should not get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditAndSaveSubTypeDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingSubType = _scenario.ExistingSubType;

            SignIn(driver, ValidcombinationSubtypeUrl);
            var subTypePicklist = new PickList(driver).ByName(string.Empty, "subType");
            subTypePicklist.OpenPickList(_scenario.ExistingSubType.Name);
            subTypePicklist.EditRow(0);

            var pageDetails = new SubTypesDetailPage(driver);

            Assert.AreEqual(existingSubType.Code, pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is equal");
            Assert.IsTrue(pageDetails.DefaultsTopic.Code.GetAttribute("disabled").Equals("true"), "Ensure Code is disabled");
            Assert.AreEqual(existingSubType.Name, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is equal");

            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(_scenario.ExistingSubType.Name + " edited");
            pageDetails.SaveButton.ClickWithTimeout();

            driver.FindElement(By.ClassName("basic-addon-r-2")).Clear();
            driver.FindElement(By.ClassName("basic-addon-r-2")).SendKeys(_scenario.ExistingSubType.Name + " edited");
            driver.FindElement(By.CssSelector("button[button-icon='search']")).Click();

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckClientSideValidationForMandatoryAndMaxLength(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, ValidcombinationSubtypeUrl);

            var subTypePicklist = new PickList(driver).ByName(string.Empty, "subType");
            subTypePicklist.SearchButton.Click();

            driver.FindElement(By.Name("plus-circle")).Click();

            var pageDetails = new SubTypesDetailPage(driver);
            Assert.IsTrue(pageDetails.SaveButton.GetAttribute("disabled").Equals("true"), "Ensure Save is disabled");

            pageDetails.DefaultsTopic.Code.SendKeys("A");
            driver.WaitForAngular();
            pageDetails.SaveButton.Click();

            Assert.IsTrue(new TextField(driver, "value").HasError, "Description is mandatory");

            pageDetails.DefaultsTopic.Code.Clear();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code is mandatory");

            pageDetails.DefaultsTopic.Code.SendKeys("AAA");
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be maximum 2 characters");

            pageDetails.DefaultsTopic.Description.SendKeys("123456789012345678901234567890123456789012345678901123456789012");
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be maximum 60 characters");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("A");
            Assert.IsFalse(new TextField(driver, "code").HasError);

            driver.WaitForAngular();
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys("AAA");
            Assert.IsFalse(new TextField(driver, "value").HasError);

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); //edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckForUniqueCodeAndDescription(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingSubType = _scenario.ExistingSubType;

            SignIn(driver, ValidcombinationSubtypeUrl);

            var subTypePicklist = new PickList(driver).ByName(string.Empty, "subType");
            subTypePicklist.OpenPickList(string.Empty);

            driver.FindElement(By.Name("plus-circle")).Click();

            var pageDetails = new SubTypesDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys(existingSubType.Code);
            pageDetails.DefaultsTopic.Description.SendKeys("e2e duplicate check");
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.True(new TextField(driver, "code").HasError, "Code should be unique");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("99");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(existingSubType.Name);
            pageDetails.SaveButton.ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.True(new TextField(driver, "value").HasError, "Description should be unique");
            
            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); //edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DiscardCancelDialogOnSubTypeChange(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, ValidcombinationSubtypeUrl);

            var subTypePicklist = new PickList(driver).ByName(string.Empty, "subType");
            subTypePicklist.OpenPickList(string.Empty);
            driver.FindElement(By.Name("plus-circle")).Click();

            var pageDetails = new SubTypesDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys("A");
            pageDetails.DefaultsTopic.Description.SendKeys("Desc");
            pageDetails.Discard();

            var popup = new CommonPopups(driver);
            popup.DiscardChangesModal.Cancel();
            Assert.AreEqual(pageDetails.DefaultsTopic.Code.GetAttribute("value"), "A", "Code is not lost");
            Assert.AreEqual(pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Desc", "Description is not lost");

            pageDetails.Discard();
            popup.DiscardChangesModal.Discard();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("code")));
        }
    }
}