using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.EventCategory
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Scenario)]
    public class ViewOnlyEventCategoryPicklist : IntegrationTest
    {
        [SetUp]
        public void CreateViewOnlyUser()
        {
            _loginUser = new Users()
                .WithLicense(LicensedModule.CasesAndNames)
                .WithPermission(ApplicationTask.MaintainWorkflowRules)
                .WithPermission(ApplicationTask.MaintainEventCategory, Deny.Execute)
                .Create();
        }

        TestUser _loginUser;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ViewEventCategoryList(BrowserType browserType)
        {
            using (var setup = new EventCategoryDbSetup())
            {
                setup.DataSetup();
            }
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows", _loginUser.Username, _loginUser.Password);
            driver.FindRadio("search-by-event").Click();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList();
            driver.WaitForAngularWithTimeout();
            eventsPicklist.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var eventCategory = new PickList(driver).ByName("ip-picklist-modal-maintenance", "category");
            eventCategory.OpenPickList();

            var editButtonShown = eventCategory.IsRowButtonAvailable(0, "pencil-square-o");
            var viewButtonShown = eventCategory.IsRowButtonAvailable(0, "info-circle");
            var deleteButtonShown = eventCategory.IsRowButtonAvailable(0, "trash");

            Assert.True(viewButtonShown, "The View action button is incorrectly hidden.");
            Assert.False(editButtonShown, "The Edit action button is incorrectly shown.");
            Assert.False(deleteButtonShown, "The Delete action button is incorrectly shown.");

            eventCategory.ViewRow(0);

            var descriptionField = driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea"));
            var nameField = driver.FindElement(By.Name("name")).FindElement(By.TagName("input"));
            var imagePicklist = new PickList(driver).ByName(string.Empty, "imageDescription");

            Assert.IsTrue(descriptionField.IsDisabled(), "Expected Description to be disabled");
            Assert.IsTrue(nameField.IsDisabled(), "Expected Name field to be disabled");
            Assert.IsFalse(imagePicklist.Enabled, "Expected Image picklist to be disabled");
        }
    }

    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Scenario)]
    public class MaintainableEventCategoryPicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddNewEventCategory(BrowserType browserType)
        {
            EventCategoryDbSetup.ScenarioData scenarioData;
            using (var setup = new EventCategoryDbSetup())
            {
                scenarioData = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(Fixture.String(10));
            driver.WaitForAngularWithTimeout();
            eventsPicklist.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var eventCategory = new PickList(driver).ByName("ip-picklist-modal-maintenance", "category");
            eventCategory.OpenPickList();
            eventCategory.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var maintenance = new EventCategoryDetailPage(driver);

            var newCategory = Fixture.String(50);
            var newDescription = Fixture.String(254);
            var name = driver.FindElement(By.Name("name")).FindElement(By.TagName("input"));
            var description = driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea"));

            Assert.AreEqual(string.Empty, maintenance.CategoryDescription.Value(), "Category must be blank by default");
            name.SendKeys(newCategory);
            Assert.AreEqual(string.Empty, maintenance.CategoryDescription.Value(), "Category Description must be blank by default");
            description.SendKeys(newDescription);
            maintenance.ImagePicklist.EnterAndSelect(scenarioData.Image);

            maintenance.Save();

            Assert.AreEqual(newCategory, eventCategory.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual(newDescription, eventCategory.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual(scenarioData.Image, eventCategory.SearchGrid.CellText(0, 3), "Ensure the text is updated");

            Assert.IsTrue(eventCategory.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");
            
            eventCategory = new PickList(driver).ByName("ip-picklist-modal-maintenance", "category");
            eventCategory.SearchFor(newCategory);
            driver.WaitForAngularWithTimeout();
            eventCategory.EditRow(0);
            driver.WaitForAngularWithTimeout();

            maintenance = new EventCategoryDetailPage(driver);

            Assert.AreEqual(newCategory, maintenance.Category.Value(), "Newly added category saved with incorrect name.");
            Assert.AreEqual(newDescription, maintenance.CategoryDescription.Value(), "Newly added category saved with incorrect description.");
            Assert.AreEqual(scenarioData.Image, maintenance.ImagePicklist.GetText(), "Newly added category saved with incorrect image.");

            //https://github.com/mozilla/geckodriver/issues/1151
            maintenance.Discard(); // discard event category edit mode
            maintenance.Discard(); // discard event category picklist.
            maintenance.Discard(); // discard add event picklist
            maintenance.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DuplicateEventCategory(BrowserType browserType)
        {
            EventCategoryDbSetup.ScenarioData scenarioData;
            using (var setup = new EventCategoryDbSetup())
            {
                scenarioData = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(Fixture.String(10));
            driver.WaitForAngularWithTimeout();
            eventsPicklist.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var eventCategory = new PickList(driver).ByName("ip-picklist-modal-maintenance", "category");
            eventCategory.OpenPickList();
            eventCategory.SearchFor(scenarioData.ExistingCategory);

            var editButtonShown = eventCategory.IsRowButtonAvailable(0, "pencil-square-o");
            var viewButtonShown = eventCategory.IsRowButtonAvailable(0, "info-circle");
            var deleteButtonShown = eventCategory.IsRowButtonAvailable(0, "trash");

            Assert.False(viewButtonShown, "The View action button is incorrectly shown.");
            Assert.True(editButtonShown, "The Edit action button is incorrectly hidden.");
            Assert.True(deleteButtonShown, "The Delete action button is incorrectly hidden.");

            var newCategory = Fixture.String(50);
            var newDescription = Fixture.String(254);

            eventCategory.DuplicateRow(0);

            var nameValue = driver.FindElement(By.Name("name")).FindElement(By.TagName("input")).Value();
            var description = driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea"));
            var imagePicklist = new PickList(driver).ByName(string.Empty, "imageDescription");
            var nameField = driver.FindElement(By.Name("name")).FindElement(By.TagName("input"));

            Assert.AreEqual(scenarioData.ExistingCategory + " - Copy", nameValue, "Expect Copy keyword to be appended to Category");

            nameField.Clear();
            nameField.SendKeys(newCategory);
            description.Clear();
            description.SendKeys(newDescription);
            imagePicklist.EnterAndSelect(scenarioData.Image);

            var saveButton = driver.FindElement(By.CssSelector(".btn-save"));
            saveButton.WithJs().Click();

            eventCategory.SearchFor(newCategory);
            driver.WaitForAngularWithTimeout();
            eventCategory.EditRow(0);
            driver.WaitForAngularWithTimeout();

            var updatedDescription = driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea")).Value();
            var updatedName = driver.FindElement(By.Name("name")).FindElement(By.TagName("input")).Value();
            var updatedImage = new PickList(driver).ByName(string.Empty, "imageDescription").GetText();

            Assert.AreEqual(newCategory, updatedName, "Expected category name to be unchanged.");
            Assert.AreEqual(newDescription, updatedDescription, "Expected description to have been updated, but is not.");
            Assert.AreEqual(scenarioData.Image, updatedImage, "Expected image to have been updated, but is not.");

            //https://github.com/mozilla/geckodriver/issues/1151
            var maintenance = new EventCategoryDetailPage(driver);

            maintenance.Discard(); // discard event category edit mode
            maintenance.Discard(); // discard event category picklist.
            maintenance.Discard(); // discard add event picklist
            maintenance.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateExistingEventCategory(BrowserType browserType)
        {
            EventCategoryDbSetup.ScenarioData scenarioData;
            using (var setup = new EventCategoryDbSetup())
            {
                scenarioData = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(Fixture.String(10));
            driver.WaitForAngularWithTimeout();
            eventsPicklist.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var eventCategory = new PickList(driver).ByName("ip-picklist-modal-maintenance", "category");
            eventCategory.OpenPickList();
            eventCategory.SearchFor(scenarioData.ExistingCategory);

            var editButtonShown = eventCategory.IsRowButtonAvailable(0, "pencil-square-o");
            var viewButtonShown = eventCategory.IsRowButtonAvailable(0, "info-circle");
            var deleteButtonShown = eventCategory.IsRowButtonAvailable(0, "trash");

            Assert.False(viewButtonShown, "The View action button is incorrectly shown.");
            Assert.True(editButtonShown, "The Edit action button is incorrectly hidden.");
            Assert.True(deleteButtonShown, "The Delete action button is incorrectly hidden.");

            var newCategory = Fixture.String(50);
            var newDescription = Fixture.String(254);

            eventCategory.EditRow(0);

            var description = driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea"));
            var imagePicklist = new PickList(driver).ByName(string.Empty, "imageDescription");

            description.Clear();
            description.SendKeys(newDescription);
            imagePicklist.EnterAndSelect(scenarioData.Image);

            var saveButton = driver.FindElement(By.CssSelector(".btn-save"));
            saveButton.WithJs().Click();

            eventCategory.SearchFor(scenarioData.ExistingCategory);
            driver.WaitForAngularWithTimeout();
            eventCategory.EditRow(0);
            driver.WaitForAngularWithTimeout();

            var updatedDescription = driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea")).Value();
            var updatedName = driver.FindElement(By.Name("name")).FindElement(By.TagName("input")).Value();
            var updatedImage = new PickList(driver).ByName(string.Empty, "imageDescription").GetText();

            Assert.AreEqual(scenarioData.ExistingCategory, updatedName, "Expected category name to be unchanged.");
            Assert.AreEqual(newDescription, updatedDescription, "Expected description to have been updated, but is not.");
            Assert.AreEqual(scenarioData.Image, updatedImage, "Expected image to have been updated, but is not.");

            var name = driver.FindElement(By.Name("name")).FindElement(By.TagName("input"));
            name.Clear();
            name.SendKeys(newCategory);
            saveButton = driver.FindElement(By.CssSelector(".btn-save"));

            saveButton.WithJs().Click();

            eventCategory.SearchFor(newCategory);
            driver.WaitForAngularWithTimeout();
            eventCategory.EditRow(0);
            driver.WaitForAngularWithTimeout();

            updatedName = driver.FindElement(By.Name("name")).FindElement(By.TagName("input")).Value();
            Assert.AreEqual(newCategory, updatedName, "Expected category name to have been updated, but is not.");

            updatedDescription = driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea")).Value();
            Assert.AreEqual(newDescription, updatedDescription, "Expected description to have been updated, but is not.");

            updatedImage = new PickList(driver).ByName(string.Empty, "imageDescription").GetText();
            Assert.AreEqual(scenarioData.Image, updatedImage, "Expected image to have been updated, but is not.");
            
            //https://github.com/mozilla/geckodriver/issues/1151
            var maintenance = new EventCategoryDetailPage(driver);

            maintenance.Discard(); // discard event category edit mode
            maintenance.Discard(); // discard event category picklist.
            maintenance.Discard(); // discard add event picklist
            maintenance.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteExistingEventCategory(BrowserType browserType)
        {
            EventCategoryDbSetup.ScenarioData scenarioData;
            using (var setup = new EventCategoryDbSetup())
            {
                scenarioData = setup.DataSetup();
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();
            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.OpenPickList(Fixture.String(10));
            driver.WaitForAngularWithTimeout();
            eventsPicklist.AddPickListItem();
            driver.WaitForAngularWithTimeout();

            var eventCategory = new PickList(driver).ByName("ip-picklist-modal-maintenance", "category");
            eventCategory.OpenPickList();
            eventCategory.SearchFor(scenarioData.ExistingCategory);
            driver.WaitForAngularWithTimeout();
            eventCategory.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().Click();

            var resultsGrid = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, resultsGrid.Rows.Count, "Expected event catgegory to be deleted but was not.");

            eventCategory.Clear();
            eventCategory.SearchFor(scenarioData.ExistingCategory);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(0, resultsGrid.Rows.Count, "Expected event catgegory to be deleted but was not.");

            //https://github.com/mozilla/geckodriver/issues/1151
            var maintenance = new EventCategoryDetailPage(driver);

            maintenance.Discard(); // discard event category picklist.
            maintenance.Discard(); // discard add event picklist
            maintenance.Discard(); // discard confirm.
        }
    }
}