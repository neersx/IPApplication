using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Relationship
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class RelationshipPicklist : IntegrationTest
    {
        [SetUp]
        public void ClassInit()
        {
            _relationshipPicklistDbSetUp = new RelationshipPicklistDbSetUp();
            _scenario = _relationshipPicklistDbSetUp.DataSetUp();
        }

        RelationshipPicklistDbSetUp _relationshipPicklistDbSetUp;
        RelationshipPicklistDbSetUp.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CopyRelationshipDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/relationship");

            var relationshipPicklist = new PickList(driver).ByName(string.Empty, "relationship");
            relationshipPicklist.OpenPickList(RelationshipPicklistDbSetUp.ExistingRelationship3);
            relationshipPicklist.DuplicateRow(0);

            var pageDetails = new RelationshipDetailPage(driver);

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("JKL");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(RelationshipPicklistDbSetUp.RelationshipToBeAdded);

            pageDetails.SaveButton.ClickWithTimeout();

            relationshipPicklist.SearchFor(RelationshipPicklistDbSetUp.RelationshipToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(RelationshipPicklistDbSetUp.RelationshipToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("JKL", searchResults.CellText(0, 1), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckClientSideValidationForMandatoryAndMaxLength(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/relationship");

            var relationshipPicklist = new PickList(driver).ByName(string.Empty, "relationship");
            relationshipPicklist.SearchButton.Click();
            relationshipPicklist.AddPickListItem();

            var pageDetails = new RelationshipDetailPage(driver);
            Assert.IsTrue(pageDetails.SaveButton.GetAttribute("disabled").Equals("true"), "Ensure Save is disabled");

            pageDetails.DefaultsTopic.Code.SendKeys("JKL");
            driver.WaitForAngular();
            pageDetails.SaveButton.Click();

            Assert.IsTrue(new TextField(driver, "value").HasError, "Description is mandatory");

            pageDetails.DefaultsTopic.Code.Clear();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code is mandatory");

            pageDetails.DefaultsTopic.Code.SendKeys("ZZZZ");
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be maximum 3 characters");

            pageDetails.DefaultsTopic.Description.SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be maximum 50 characters");

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
            var existingRelationship = _scenario.ExistingRelationship;

            SignIn(driver, "/#/configuration/general/validcombination/relationship");

            var relationshipPicklist = new PickList(driver).ByName(string.Empty, "relationship");
            relationshipPicklist.SearchButton.Click();
            relationshipPicklist.AddPickListItem();

            var pageDetails = new RelationshipDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys(existingRelationship.Relationship);
            pageDetails.DefaultsTopic.Description.SendKeys("abcd");
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be unique");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("JKL");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(existingRelationship.Description);
            pageDetails.SaveButton.ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be unique");

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); //edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ValidateFromAndToEventCombination(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/relationship");

            var relationshipPicklist = new PickList(driver).ByName(string.Empty, "relationship");
            relationshipPicklist.SearchButton.Click();
            relationshipPicklist.AddPickListItem();

            var pageDetails = new RelationshipDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys("XYZ");
            pageDetails.DefaultsTopic.Description.SendKeys("abcd");

            var fromEventPicklist = new PickList(driver).ByName(string.Empty, "fromEvent");
            fromEventPicklist.EnterAndSelect(_scenario.ExistingEvent.Description);

            driver.WaitForAngularWithTimeout();

            var toEventPicklist = new PickList(driver).ByName(string.Empty, "toEvent");
            toEventPicklist.Clear();

            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "toEvent").HasError, "From Event and To Event both should be entered");

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); // edit mode discard
            pageDetails.Discard(); // discard confirm. 
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class RelationshipPicklistDelete : IntegrationTest
    {
        [SetUp]
        public void ClassInit()
        {
            _relationshipPicklistDbSetUp = new RelationshipPicklistDbSetUp();
            _scenario = _relationshipPicklistDbSetUp.DataSetUp();
        }

        RelationshipPicklistDbSetUp _relationshipPicklistDbSetUp;
        RelationshipPicklistDbSetUp.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteRelationshipDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/relationship");

            var relationshipPicklist = new PickList(driver).ByName(string.Empty, "relationship");
            relationshipPicklist.OpenPickList(RelationshipPicklistDbSetUp.ExistingRelationship2);
            relationshipPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();

            relationshipPicklist.SearchFor(RelationshipPicklistDbSetUp.ExistingRelationship2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "Relationship should get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ClickDeleteRelationshipAndThenClickNoOnConfirmation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/relationship");

            var relationshipPicklist = new PickList(driver).ByName(string.Empty, "relationship");
            relationshipPicklist.OpenPickList(RelationshipPicklistDbSetUp.ExistingRelationship2);
            relationshipPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Cancel().ClickWithTimeout();

            relationshipPicklist.SearchFor(RelationshipPicklistDbSetUp.ExistingRelationship2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Relationship value should not get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteRelationshipDetailsWhichIsInUse(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            _relationshipPicklistDbSetUp.AddValidRelationship(_scenario.ExistingRelationship);

            SignIn(driver, "/#/configuration/general/validcombination/relationship");

            var relationshipPicklist = new PickList(driver).ByName(string.Empty, "relationship");
            relationshipPicklist.OpenPickList(_scenario.ExistingRelationship.Description);
            relationshipPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();
            driver.WaitForAngular();
            popups.AlertModal.Ok();

            relationshipPicklist.SearchFor(RelationshipPicklistDbSetUp.ExistingRelationship);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(3, searchResults.Rows.Count, "Relationship should not get deleted");
            Assert.AreEqual(_scenario.ExistingRelationship.Description, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class RelationshipPicklistEditing : IntegrationTest
    {
        [SetUp]
        public void ClassInit()
        {
            _relationshipPicklistDbSetUp = new RelationshipPicklistDbSetUp();
            _scenario = _relationshipPicklistDbSetUp.DataSetUp();
        }

        RelationshipPicklistDbSetUp _relationshipPicklistDbSetUp;
        RelationshipPicklistDbSetUp.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddRelationshipDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/relationship");

            var relationshipPicklist = new PickList(driver).ByName(string.Empty, "relationship");
            relationshipPicklist.SearchButton.Click();
            relationshipPicklist.AddPickListItem();

            var pageDetails = new RelationshipDetailPage(driver);
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Code.GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is equal");

            pageDetails.DefaultsTopic.Code.SendKeys("XYZ");
            pageDetails.DefaultsTopic.Description.SendKeys(RelationshipPicklistDbSetUp.RelationshipToBeAdded);
            pageDetails.DefaultsTopic.ShowFlag.WithJs().Click();
            pageDetails.SaveButton.ClickWithTimeout();

            Assert.AreEqual(RelationshipPicklistDbSetUp.RelationshipToBeAdded, relationshipPicklist.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("XYZ", relationshipPicklist.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            Assert.IsTrue(relationshipPicklist.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            relationshipPicklist.SearchFor(RelationshipPicklistDbSetUp.RelationshipToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(RelationshipPicklistDbSetUp.RelationshipToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("XYZ", searchResults.CellText(0, 1), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditAndSaveRelationshipDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingRelationship = _scenario.ExistingRelationship;

            SignIn(driver, "/#/configuration/general/validcombination/relationship");

            var relationshipPicklist = new PickList(driver).ById("relationship-picklist");
            relationshipPicklist.OpenPickList(_scenario.RelationshipName);
            relationshipPicklist.EditRow(0);
            var pageDetails = new RelationshipDetailPage(driver);

            var editedName = existingRelationship.Description + " edited";
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(editedName);
            pageDetails.SaveButton.ClickWithTimeout();

            relationshipPicklist.SearchFor(editedName);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Only one row is returned");
            Assert.AreEqual(editedName, searchResults.CellText(0, 0), "Ensure the text is updated");
        }

    }
}
