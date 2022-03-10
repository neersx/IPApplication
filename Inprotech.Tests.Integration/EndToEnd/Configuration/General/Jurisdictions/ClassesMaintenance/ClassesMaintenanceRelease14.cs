using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.ClassesMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(dbReleaseLevel: DbCompatLevel.Release14)]
    class ClassesMaintenanceRelease14 : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainClasses(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            new ClassesMaintenanceDbSetUp().Prepare();
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .Create();
            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);
            var pageDetails = new ClassesMaintenanceDetailPage(driver);
            var topic = pageDetails.ClassesTopic;

            var propertyTypePicklist = new PickList(driver).ByName("propertyType");
            var internationalClassesPicklist = new PickList(driver).ByName("internationalclass");

            #region Add Class to ZZZ Jurisdiction
            pageDetails.ClassesTopic.SearchTextBox(driver).SendKeys("ZZZ");
            pageDetails.ClassesTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("ZZZ", searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.ClassesTopic.BulkMenu(driver);
            pageDetails.ClassesTopic.SelectPageOnly(driver);
            pageDetails.ClassesTopic.EditButton(driver);
            topic.NavigateTo();
            var classesSearchResults = new KendoGrid(driver, "localClasses");
            var classesSearchResultsCount = classesSearchResults.Rows.Count;
            topic.Add();
            pageDetails.ClassesTopic.ClassHeadingTextArea(driver).SendKeys("e2e test");
            pageDetails.ClassesTopic.ApplyButton(driver).ClickWithTimeout();
            Assert.IsTrue(propertyTypePicklist.HasError, "Required Field");
            Assert.IsTrue(new TextField(driver, "class").HasError, "Required Field");
            pageDetails.ClassesTopic.ClassTextBox(driver).SendKeys("111111");
            Assert.IsTrue(new TextField(driver, "class").HasError, "Max Length");
            propertyTypePicklist.EnterAndSelect("Trade Mark");
            pageDetails.ClassesTopic.ClassTextBox(driver).Clear();
            pageDetails.ClassesTopic.ClassTextBox(driver).SendKeys("01");
            pageDetails.ClassesTopic.ApplyButton(driver).ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();

            pageDetails.ClassesTopic.ClassTextBox(driver).Clear();
            pageDetails.ClassesTopic.ClassTextBox(driver).SendKeys("e2");
            pageDetails.ClassesTopic.SubClassTextBox(driver).SendKeys("sc01");
            pageDetails.ClassesTopic.EffectiveDatePicker(driver).SendKeys(DateTime.Now.ToString("yyyy-MM-dd"));
            pageDetails.ClassesTopic.NotesTextArea(driver).SendKeys("e2e test");
            pageDetails.ClassesTopic.ApplyButton(driver).ClickWithTimeout();
            pageDetails.ClassesTopic.SaveButton(driver).ClickWithTimeout();
            var newSearchResultCount = classesSearchResultsCount + 1;
            Assert.AreEqual(newSearchResultCount, classesSearchResults.Rows.Count);
            Assert.AreEqual(newSearchResultCount, topic.NumberOfRecords(), "Topic displays count");
            #endregion

            #region Add International Class to Jurisdiction
            pageDetails.ClassesTopic.LevelUp();
            pageDetails.ClassesTopic.SearchTextBox(driver).Clear();
            pageDetails.ClassesTopic.SearchTextBox(driver).SendKeys(ClassesMaintenanceDbSetUp.CountryCode1);
            pageDetails.ClassesTopic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ClassesMaintenanceDbSetUp.CountryCode1, searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.ClassesTopic.BulkMenu(driver);
            pageDetails.ClassesTopic.SelectPageOnly(driver);
            pageDetails.ClassesTopic.EditButton(driver);
            topic.NavigateTo();
            topic.Add();
            propertyTypePicklist.EnterAndSelect("Patent");
            Assert.False(internationalClassesPicklist.Enabled, "International Classes Picklist should be disabled.");
            propertyTypePicklist.Clear();
            propertyTypePicklist.EnterAndSelect("Trade Mark");
            pageDetails.ClassesTopic.ClassTextBox(driver).SendKeys("e3");
            pageDetails.ClassesTopic.SubClassTextBox(driver).SendKeys("sc01");
            pageDetails.ClassesTopic.ClassHeadingTextArea(driver).SendKeys("e3e test");
            pageDetails.ClassesTopic.EffectiveDatePicker(driver).SendKeys(DateTime.Now.ToString("yyyy-MM-dd"));
            internationalClassesPicklist.EnterAndSelect("e2");
            pageDetails.ClassesTopic.NotesTextArea(driver).SendKeys("e3e test");
            internationalClassesPicklist.EnterAndSelect("01");
            pageDetails.ClassesTopic.ApplyButton(driver).ClickWithTimeout();
            pageDetails.ClassesTopic.SaveButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            
            Assert.AreEqual("e3", classesSearchResults.CellText(2, 2), "Search returns record matching Code");
            Assert.AreEqual("e3e test", classesSearchResults.CellText(2, 3), "Search returns record matching Code");
            Assert.AreEqual("01, e2", classesSearchResults.CellText(2, 4), "Search returns record matching Code");
            Assert.AreEqual(DateTime.Now.ToShortDateString(), Convert.ToDateTime(classesSearchResults.CellText(2, 6)).ToShortDateString(), "Search returns record matching Code");
            Assert.AreEqual("Trade Marks", classesSearchResults.CellText(2, 7), "Search returns record matching Code");
            #endregion

            #region Edit International Class in Jurisdiction
            classesSearchResults.ClickEdit(0);
            pageDetails.ClassesTopic.ClassTextBox(driver).Clear();
            pageDetails.ClassesTopic.ClassTextBox(driver).SendKeys("e4");
            pageDetails.ClassesTopic.SubClassTextBox(driver).SendKeys("sc01");
            pageDetails.ClassesTopic.ApplyButton(driver).ClickWithTimeout();
            pageDetails.ClassesTopic.SaveButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            Assert.AreEqual("e4", classesSearchResults.CellText(2, 2), "Search returns record matching Code");
            #endregion

            #region Class item Picklist
            Assert.True(searchResults.FindElement(By.CssSelector("[button-icon='cpa-icon cpa-icon-items-o']")).Displayed, "Icon is visible.");
            classesSearchResults.ClickIcon(0);
            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(2, searchResults.Rows.Count);
            pageDetails.ClassesTopic.ClassItemTextBox(driver).SendKeys("Item3 Description");
            pageDetails.ClassesTopic.ClassItemPicklistSearchButton(driver).WithJs().Click();

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("Item3 Description", searchResults.CellText(0, 1), "Search returns record matching Item Description");
            Assert.AreEqual("Arabic", searchResults.CellText(0, 2), "Search returns record matching Language");
            Assert.AreEqual("sc01", searchResults.CellText(0, 3), "Search returns record matching Sub Class");
            Assert.AreEqual("2C", searchResults.CellText(0, 4), "Search returns record matching Class");
            #endregion

            #region Class item Add/Edit/Delete Picklist

            //Add ClassItem Picklist with Add Another
            pageDetails.ClassesTopic.AddClassItemButton(driver).ClickWithTimeout();
            pageDetails.ClassesTopic.AddAnotherCheckBox(driver).WithJs().Click();
            pageDetails.ClassesTopic.ItemNumberTextBox(driver).SendKeys("Item-e2e");
            pageDetails.ClassesTopic.ItemDescriptionTextBox(driver).SendKeys("Item-e2e description");
            pageDetails.ClassesTopic.ClassItemPicklistSaveButton(driver).ClickWithTimeout();

            //Add ClassItem Pikclist without Add Another
            pageDetails.ClassesTopic.ItemNumberTextBox(driver).Clear();
            pageDetails.ClassesTopic.ItemNumberTextBox(driver).SendKeys("Item-e2e new");
            pageDetails.ClassesTopic.ItemDescriptionTextBox(driver).Clear();
            pageDetails.ClassesTopic.ItemDescriptionTextBox(driver).SendKeys("Item-e2e description new");
            pageDetails.ClassesTopic.AddAnotherCheckBox(driver).WithJs().Click();
            pageDetails.ClassesTopic.ClassItemPicklistSaveButton(driver).ClickWithTimeout();

            pageDetails.ClassesTopic.ClassItemPicklistSearchButton(driver).WithJs().Click();
            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("iteme2e3", searchResults.CellText(0, 0), "Search returns record matching Item Number");
            Assert.AreEqual("Item3 Description", searchResults.CellText(0, 1), "Search returns record matching Item Description");
            Assert.AreEqual("Arabic", searchResults.CellText(0, 2), "Search returns record matching Language");

            //Edit ClassItem Picklist
            pageDetails.ClassesTopic.EditIcon(driver).ClickWithTimeout();
            pageDetails.ClassesTopic.ItemNumberTextBox(driver).Clear();
            pageDetails.ClassesTopic.ItemNumberTextBox(driver).SendKeys("Item-e2e-edited");
            pageDetails.ClassesTopic.ItemDescriptionTextBox(driver).Clear();
            pageDetails.ClassesTopic.ItemDescriptionTextBox(driver).SendKeys("Item-e2e description-edited");
            pageDetails.ClassesTopic.ClassItemLanguagePickList.Clear();
            pageDetails.ClassesTopic.ClassItemPicklistSaveButton(driver).ClickWithTimeout();
            pageDetails.ClassesTopic.ClassItemPicklistCloseButton(driver).ClickWithTimeout();

            pageDetails.ClassesTopic.ClassItemTextBox(driver).Clear();
            pageDetails.ClassesTopic.ClassItemTextBox(driver).SendKeys("Item-e2e-edited");
            pageDetails.ClassesTopic.ClassItemPicklistSearchButton(driver).WithJs().Click();
            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("Item-e2e-edited", searchResults.CellText(0, 0), "Search returns record matching Item Number");
            Assert.AreEqual("Item-e2e description-edited", searchResults.CellText(0, 1), "Search returns record matching Item Description");

            //Delete Classitem Picklist
            pageDetails.ClassesTopic.DeleteIcon(driver).ClickWithTimeout();
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, searchResults.Rows.Count);

            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion

            #region Delete International Class from Jurisdiction
            classesSearchResults.ToggleDelete(0);
            pageDetails.ClassesTopic.SaveButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            Assert.AreEqual(2, classesSearchResults.Rows.Count);
            #endregion
        }
    }
}
