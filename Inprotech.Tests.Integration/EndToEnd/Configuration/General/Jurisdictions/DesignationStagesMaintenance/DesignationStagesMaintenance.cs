using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.DesignationStagesMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    class DesignationStagesMaintenance : IntegrationTest
    {
        const string GroupCode1 = "e2e";
        const string GroupName1 = "e2e - group";

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainDesignationStages(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .Create();
            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);

            DbSetup.Do(x =>
            {
                x.DbContext.Set<Country>().Add(new Country(GroupCode1, GroupName1, "1"));

                x.DbContext.SaveChanges();
            });
            
            var pageDetails = new DesignationStagesMaintenanceDetailPage(driver);

            #region Add Designation Stage in a Group
            pageDetails.DesignationStagesTopic.SearchTextBox(driver).SendKeys(GroupCode1);
            pageDetails.DesignationStagesTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(GroupCode1, searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.DesignationStagesTopic.BulkMenu(driver);
            pageDetails.DesignationStagesTopic.SelectPageOnly(driver);
            pageDetails.DesignationStagesTopic.EditButton(driver);
            driver.WaitForAngularWithTimeout();

            var topic = pageDetails.DesignationStagesTopic;

            topic.NavigateTo();
            topic.Add();
            Assert.IsTrue(pageDetails.DesignationStagesTopic.DesignationStageTextBox(driver).Displayed);
            pageDetails.Save();
            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            pageDetails.DesignationStagesTopic.DesignationStageTextBox(driver).SendKeys("e2e test");
            topic.RegistrationStatusDropDown(driver, topic.Grid.Rows[0]).Input.SelectByText("Pending");
            pageDetails.DesignationStagesTopic.AllowNationalPhaseCheckBox(driver).Click();
            pageDetails.Save();

            topic.NavigateTo();
            var stagesSearchResults = new KendoGrid(driver, "statusFlagsGrid");

            Assert.AreEqual(1, stagesSearchResults.Rows.Count);
            Assert.AreEqual("Pending", topic.RegistrationStatusDropDown(driver, topic.Grid.Rows[0]).Text, "Search returns record match");
            Assert.IsTrue(pageDetails.DesignationStagesTopic.AllowNationalPhaseCheckBox(driver).Selected);
            #endregion

            #region Edit Designation Stage in a Group
            topic.NavigateTo();
            topic.CaseCreationCopyProfileDropDown(driver, topic.Grid.Rows[0]).Input.SelectByText("Basic Details");
            pageDetails.Save();
            topic.NavigateTo();
            Assert.AreEqual(1, stagesSearchResults.Rows.Count);
            Assert.AreEqual("Basic Details", topic.CaseCreationCopyProfileDropDown(driver, topic.Grid.Rows[0]).Text, "Search returns record match");
            #endregion

            #region Delete Designation Stage in a Group
            topic.NavigateTo();
            topic.Grid.ToggleDelete(0);
            pageDetails.Save();
            topic.NavigateTo();
            Assert.AreEqual(0, stagesSearchResults.Rows.Count);
            #endregion
        }
    }
}
