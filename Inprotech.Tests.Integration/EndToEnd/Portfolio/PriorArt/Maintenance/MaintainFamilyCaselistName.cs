using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt.Maintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class MaintainLinkedCaseFamily : MaintainFamilyCaselistName
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void LinkFamilyMemberToPriorArt(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Modify).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + _data.Ipo.Id, user.Username, user.Password);
            var maintenancePage = new PriorArtMaintenancePageObjects(driver);
            maintenancePage.GoToStep(3);

            maintenancePage.LinkCasesButton.Click();
            var linkCasesDialog = new LinkCasesDialog(driver, "addLinkedCases");
            linkCasesDialog.CaseReference.SendKeys(_data.CaseFamilyMember.Irn);
            linkCasesDialog.CaseReference.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseReference.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();

            maintenancePage.GoToStep(4);

            maintenancePage.LinkFamilyListOrNameButton.Click();

            linkCasesDialog = new LinkCasesDialog(driver, "addLinkedCases");
            linkCasesDialog.CaseFamily.SendKeys(_data.Family.Id);
            linkCasesDialog.CaseFamily.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseFamily.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();

            maintenancePage.GoToStep(3);
            driver.WaitForAngular();

            var linkedCases = maintenancePage.LinkedCasesList;
            Assert.True(linkedCases.ColumnContains(linkedCases.FindColByText("Family"), By.XPath($"//td[contains(text(),'{_data.Family.Name}')]"), 4));
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class MaintainFamilyCaselistName : IntegrationTest
    {
        internal dynamic _data;

        [SetUp]
        public void Setup()
        {
            var setup = new PriorArtDataSetup();
            _data = setup.CreateData(withLinkedCases: true);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void LinkCaseToPriorArt(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Modify).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + _data.Ipo.Id, user.Username, user.Password);
            var maintenancePage = new PriorArtMaintenancePageObjects(driver);
            maintenancePage.GoToStep(3);

            maintenancePage.LinkCasesButton.Click();
            var linkCasesDialog = new LinkCasesDialog(driver, "addLinkedCases");
            linkCasesDialog.CaseFamily.SendKeys(_data.Family.Id);
            linkCasesDialog.CaseFamily.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseFamily.SendKeys(Keys.Enter);
            linkCasesDialog.CaseLists.SendKeys(_data.CaseList.Name);
            linkCasesDialog.CaseLists.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseLists.SendKeys(Keys.Enter);
            linkCasesDialog.CaseName.SendKeys(_data.Name.NameCode);
            linkCasesDialog.CaseName.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseName.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();

            maintenancePage.GoToStep(4);
            var familyCaselistNamePage = new FamilyCaselistNamePageObjects(driver);

            Assert.AreEqual(2, familyCaselistNamePage.FamilyCaselistGrid.Rows.Count, "The added caselist and family should be displayed.");
            Assert.True(familyCaselistNamePage.FamilyCaselistGrid.CellText(0,2).Contains(_data.Family.Name), "Shows the correct family.");
            Assert.True(familyCaselistNamePage.FamilyCaselistGrid.CellText(1,2).Contains(_data.CaseList.Name), "Shows the correct case list.");
            Assert.AreEqual(1, familyCaselistNamePage.LinkedNameGrid.Rows.Count, "The added linked name should be displayed.");
            Assert.Throws<NoSuchElementException>(() => familyCaselistNamePage.FamilyCaselistGrid.DeleteButton(1), "Delete button is not displayed in family grid.");
            Assert.Throws<NoSuchElementException>(() => familyCaselistNamePage.LinkedNameGrid.DeleteButton(1), "Delete button is not displayed in name grid.");

            familyCaselistNamePage.FamilyCaselistGrid.ExpandRow(0);

            Assert.AreEqual(1, familyCaselistNamePage.FamilyCaseDetailGrid.Rows.Count, "Shows the linked cases for the family.");

            var deleteUser = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Modify | Allow.Delete).Create();
            SignIn(driver, $"/#/reference-management?priorartId=" + _data.Ipo.Id, deleteUser.Username, deleteUser.Password);
            maintenancePage.GoToStep(4);

            Assert.True(familyCaselistNamePage.FamilyCaselistGrid.DeleteButton(1).Displayed, "Delete button is displayed in family grid.");
            Assert.True(familyCaselistNamePage.LinkedNameGrid.DeleteButton(1).Displayed, "Delete button is displayed in name grid.");

            familyCaselistNamePage.FamilyCaselistGrid.DeleteButton(1).Click();
            var popup = new CommonPopups(driver);
            popup.ConfirmModal.Yes().Click();

            Assert.AreEqual(1, familyCaselistNamePage.FamilyCaselistGrid.Rows.Count, "Family is deleted.");
            maintenancePage.GoToStep(3);

            var linkedCases = maintenancePage.LinkedCasesList;
            Assert.AreEqual(3, linkedCases.Rows.Count, "Expected grid to be automatically refreshed after deleting family");
            for (var i = 0; i < linkedCases.Rows.Count; i++)
            {
                Assert.AreEqual(string.Empty, linkedCases.CellText(i, "Family"));
            }

            maintenancePage.GoToStep(4);
            maintenancePage.LinkFamilyListOrNameButton.Click();

            linkCasesDialog = new LinkCasesDialog(driver, "addLinkedCases");
            linkCasesDialog.CaseFamily.SendKeys(_data.Family.Id);
            linkCasesDialog.CaseFamily.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseFamily.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();

            maintenancePage.GoToStep(3);
            driver.WaitForAngular();

            linkedCases = maintenancePage.LinkedCasesList;
            Assert.AreEqual(4, linkedCases.Rows.Count, "Expected grid to be automatically refreshed after adding family");
            Assert.True(linkedCases.ColumnContains(linkedCases.FindColByText("Family"), By.XPath($"//td[contains(text(),'{_data.Family.Name}')]"), 4));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void LinkCaseListToPriorArt(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Modify).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + _data.Ipo.Id + "caseKey=" + _data.Case.Id, user.Username, user.Password);
            var maintenancePage = new PriorArtMaintenancePageObjects(driver);
            maintenancePage.GoToStep(4);
            maintenancePage.LinkFamilyListOrNameButton.Click();

            var linkCasesDialog = new LinkCasesDialog(driver, "addLinkedCases");
            linkCasesDialog.CaseLists.SendKeys(_data.CaseList.Name);
            linkCasesDialog.CaseLists.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseLists.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();

            maintenancePage.GoToStep(3);

            var linkedCases = maintenancePage.LinkedCasesList;
            Assert.AreEqual(2, linkedCases.Rows.Count, "Expected grid to be automatically refreshed after adding case list");
            Assert.True(linkedCases.ColumnContains(linkedCases.FindColByText("Case List"), By.XPath($"//td[text() = '{_data.CaseList.Name}']"), 2));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void LinkNameToPriorArt(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create | Allow.Modify).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/reference-management?priorartId=" + _data.Ipo.Id + "caseKey=" + _data.Case.Id, user.Username, user.Password);
            var maintenancePage = new PriorArtMaintenancePageObjects(driver);
            maintenancePage.GoToStep(4);
            maintenancePage.LinkFamilyListOrNameButton.Click();

            var linkCasesDialog = new LinkCasesDialog(driver, "addLinkedCases");
            linkCasesDialog.CaseName.SendKeys(_data.Name.NameCode);
            linkCasesDialog.CaseName.SendKeys(Keys.ArrowDown);
            linkCasesDialog.CaseName.SendKeys(Keys.Enter);
            linkCasesDialog.SaveButton.WithJs().Click();

            maintenancePage.GoToStep(3);

            var linkedCases = maintenancePage.LinkedCasesList;
            Assert.AreEqual(2, linkedCases.Rows.Count, "Expected grid to be automatically refreshed after adding a name");
            Assert.True(linkedCases.ColumnContains(linkedCases.FindColByText("Linked via Names"), By.XPath($"//td[contains(text(),'{_data.Name.LastName}')]"), 2));
        }
    }
}
