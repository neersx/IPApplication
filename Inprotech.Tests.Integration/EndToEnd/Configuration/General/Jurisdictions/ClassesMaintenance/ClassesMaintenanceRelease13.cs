using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.ClassesMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(dbReleaseLevel: DbCompatLevel.Release13)]
    class ClassesMaintenanceRelease13 : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainClasses(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            new ClassesMaintenanceDbSetUp().Prepare(false);
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
            
            #region Delete International Class from Jurisdiction
            classesSearchResults.ToggleDelete(0);
            pageDetails.ClassesTopic.SaveButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            Assert.AreEqual(2, classesSearchResults.Rows.Count);
            #endregion
        }
    }
}
