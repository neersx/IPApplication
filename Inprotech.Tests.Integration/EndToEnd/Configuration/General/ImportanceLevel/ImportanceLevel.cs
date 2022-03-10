using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ImportanceLevel
{
    [Category(Categories.E2E)]
    [TestFixture]
    class ImportanceLevel : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _importanceLevelDbSetup = new ImportanceLevelDbSetup();
            _scenario = _importanceLevelDbSetup.Prepare();
        }

        ImportanceLevelDbSetup _importanceLevelDbSetup;
        ImportanceLevelDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddImportanceLevel(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingImportanceLevel = _scenario.ImportanceLevels;

            SignIn(driver, "/#/configuration/general/importancelevel");

            var pageDetails = new ImportanceLevelDetailPage(driver);
            var searchResults = new KendoGrid(driver, "importanceGrid");
            var searchResultsCount = searchResults.Rows.Count;

            #region verify page fields
            Assert.IsNotNull(pageDetails.DefaultsTopic.SaveButton(driver).GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.RevertButton(driver).GetAttribute("disabled"), "Ensure Revert Button is disabled");
            Assert.IsNull(pageDetails.DefaultsTopic.AddNewImportanceLevelButton(driver).GetAttribute("disabled"), "Ensure Add New Importance Level Button is enabled");
            #endregion

            #region Check For Unique Level And Max Length

            pageDetails.DefaultsTopic.AddNewImportanceLevelButton(driver).ClickWithTimeout();
            pageDetails.DefaultsTopic.Level(driver).SendKeys(existingImportanceLevel.importanceLevel1.Level);
            Assert.IsTrue(new TextField(driver, "level").HasError, "Importance Level should be unique");

            pageDetails.DefaultsTopic.Level(driver).Clear();
            pageDetails.DefaultsTopic.Level(driver).SendKeys("101");
            Assert.IsTrue(new TextField(driver, "level").HasError, "Importance Level should be maximum 2 characters");
            #endregion

            #region Add Importance Level
            pageDetails.DefaultsTopic.Level(driver).Clear();

            pageDetails.DefaultsTopic.Level(driver).SendKeys("12");
            pageDetails.DefaultsTopic.Description(driver, "12").SendKeys(ImportanceLevelDbSetup.ImportanceLevelToBeAdded);
            pageDetails.DefaultsTopic.SaveButton(driver).ClickWithTimeout();

            Assert.IsNotNull(pageDetails.DefaultsTopic.SaveButton(driver).GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.RevertButton(driver).GetAttribute("disabled"), "Ensure Revert Button is disabled");
            Assert.AreEqual(searchResultsCount + 1, searchResults.Rows.Count);
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditImportanceLevel(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingImportanceLevel = _scenario.ImportanceLevels;
            SignIn(driver, "/#/configuration/general/importancelevel");

            var pageDetails = new ImportanceLevelDetailPage(driver);
            var searchResults = new KendoGrid(driver, "importanceGrid");
            #region Edit Importance Level and Revert Changes
            var editLevel = (string)existingImportanceLevel.importanceLevel1.Level;
            pageDetails.DefaultsTopic.Description(driver, editLevel).Clear();
            pageDetails.DefaultsTopic.Description(driver, editLevel).SendKeys(ImportanceLevelDbSetup.ImportanceLevelToBeEdit);
            pageDetails.DefaultsTopic.RevertButton(driver).ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            Assert.AreEqual(ImportanceLevelDbSetup.ImportanceLevelDescription, pageDetails.DefaultsTopic.Description(driver, editLevel).GetAttribute("value"), "Ensure the text is not updated");
            #endregion

            #region Edit Importance Level and Revert Changes
            pageDetails.DefaultsTopic.Description(driver, editLevel).Clear();
            pageDetails.DefaultsTopic.Description(driver, editLevel).SendKeys(ImportanceLevelDbSetup.ImportanceLevelToBeEdit);
            pageDetails.DefaultsTopic.SaveButton(driver).ClickWithTimeout();
            Assert.AreEqual(ImportanceLevelDbSetup.ImportanceLevelToBeEdit, pageDetails.DefaultsTopic.Description(driver, editLevel).GetAttribute("value"), "Ensure the text is not updated");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteImportanceLevel(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingImportanceLevel = _scenario.ImportanceLevels;
            SignIn(driver, "/#/configuration/general/importancelevel");

            var pageDetails = new ImportanceLevelDetailPage(driver);
            var searchResults = new KendoGrid(driver, "importanceGrid");
            var searchResultsCount = searchResults.Rows.Count;
            var popups = new CommonPopups(driver);

            #region Delete Successfully
            var deleteLevel = (string)existingImportanceLevel.importanceLevel1.Level;
            pageDetails.DefaultsTopic.DeleteButton(driver, deleteLevel).ClickWithTimeout();
            pageDetails.DefaultsTopic.SaveButton(driver).ClickWithTimeout();
            Assert.AreEqual(searchResultsCount - 1, searchResults.Rows.Count);
            #endregion

            #region Unable to complete as records in use
            searchResultsCount = searchResults.Rows.Count;
            pageDetails.DefaultsTopic.DeleteButton(driver, "9").ClickWithTimeout();
            pageDetails.DefaultsTopic.SaveButton(driver).ClickWithTimeout();
            popups.AlertModal.Ok();
            Assert.AreEqual(searchResultsCount, searchResults.Rows.Count);
            #endregion

            #region Partially complete as records in use
            deleteLevel = (string) existingImportanceLevel.importanceLevel2.Level;
            searchResultsCount = searchResults.Rows.Count;
            pageDetails.DefaultsTopic.DeleteButton(driver, "9").ClickWithTimeout();
            pageDetails.DefaultsTopic.DeleteButton(driver, deleteLevel).ClickWithTimeout();
            pageDetails.DefaultsTopic.SaveButton(driver).ClickWithTimeout();
            popups.AlertModal.Ok();
            Assert.AreEqual(searchResultsCount - 1, searchResults.Rows.Count);
            #endregion
        }
    }
}
