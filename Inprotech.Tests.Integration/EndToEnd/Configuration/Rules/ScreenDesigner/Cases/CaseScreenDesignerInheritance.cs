using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using NUnit.Framework;
using OpenQA.Selenium;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.ScreenDesigner.Cases
{

    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseScreenDesignerInheritance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void GridInheritanceIsShown(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();
            var page = new CaseScreenDesignerSearchPageObject(driver);

            page.CriteriaRadioButton.Click();
            driver.WaitForAngular();
            page.Criteria.EnterAndSelect(data.CriteriaNavigation[1].Id.ToString());
            driver.WaitForAngular();
            page.SubmitButtonCriteria.Click();
            driver.WaitForAngular();
            Assert.AreEqual(1, page.Grid.Rows.Count);
            page.Grid.Cell(0, 0).FindElement(By.TagName("a")).Click();
            driver.WaitForAngular();
            var inheritancePage = new CriteriaInheritancePageObject(driver);

            AssertCriteriaInheritanceAreAllShown(inheritancePage, data, 1);
            inheritancePage.LevelUpButton.ClickWithTimeout();
            Assert.AreEqual(1, page.Grid.Rows.Count);
            page.Criteria.Clear();
            page.Criteria.EnterAndSelect(data.CriteriaNavigation[2].Id.ToString());
            page.SubmitButtonCriteria.ClickWithTimeout();
            Assert.AreEqual(1, page.Grid.Rows.Count);
            page.Grid.Cell(0, 0).FindElement(By.TagName("a")).ClickWithTimeout();
            AssertCriteriaInheritanceAreAllShown(inheritancePage, data, 2);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CriteriaDetailsInheritanceNavigation(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases/" + data.CriteriaNavigation[1].Id, user.Username, user.Password);
            var detailsPage = new CaseScreenDesignerMaintenancePageObject(driver);
            var inheritancePage = new CriteriaInheritancePageObject(driver);
            // Asserting state stack is working appropriately.
            // 1CD = Criteria Details For ID 1
            // 1CI = Criteria Inheritance for ID 1
            // 1CD
            AssertCriteriaDetailsPageIsShowing(detailsPage, data, 1);
            detailsPage.InheritanceIcon.ClickWithTimeout();
            
            AssertCriteriaInheritanceAreAllShown(inheritancePage, data, 1);
            // 1CD > 1CI
            inheritancePage.LevelUpButton.ClickWithTimeout();
            // 1CD
            AssertCriteriaDetailsPageIsShowing(detailsPage, data, 1);
            
            detailsPage.InheritanceIcon.ClickWithTimeout();
            //  1CD > 1CI
            AssertCriteriaInheritanceAreAllShown(inheritancePage, data, 1);
            var allTreeNodes = inheritancePage.GetAllTreeNodes();
            allTreeNodes[2].CriteriaIdLink.ClickWithTimeout();
            //  1CD > 1CI > 2CD
            AssertCriteriaDetailsPageIsShowing(detailsPage, data, 2);
            detailsPage.InheritanceIcon.ClickWithTimeout();

            //  1CD > 1CI > 2CD > 2CI
            AssertCriteriaInheritanceAreAllShown(inheritancePage, data, 2);
            inheritancePage.LevelUpButton.ClickWithTimeout();
            //  1CD > 1CI > 2CD
            AssertCriteriaDetailsPageIsShowing(detailsPage, data, 2);

            detailsPage.LevelUpButton.ClickWithTimeout();
            //  1CD > 1CI
            AssertCriteriaInheritanceAreAllShown(inheritancePage, data, 2);
            
            inheritancePage.LevelUpButton.ClickWithTimeout();
            //  1CD
            AssertCriteriaDetailsPageIsShowing(detailsPage, data, 2);
        }

        static void AssertCriteriaDetailsPageIsShowing(CaseScreenDesignerMaintenancePageObject detailsPage, CaseScreenDesignerDbSetup.ClassScreenDesignerData data, int index)
        {
            Assert.True(detailsPage.InheritanceIconShowing);
            Assert.AreEqual(detailsPage.CriteriaNumber, data.CriteriaNavigation[index].Id.ToString());
            Assert.AreEqual(detailsPage.CriteriaName, data.CriteriaNavigation[index].Description);
        }

        static void AssertCriteriaInheritanceAreAllShown(CriteriaInheritancePageObject inheritancePage, CaseScreenDesignerDbSetup.ClassScreenDesignerData data, int isInSearch)
        {
            var allNodes = inheritancePage.GetAllTreeNodes();
            Assert.AreEqual(5, allNodes.Length);
            for (var i = 0; i < 5; i++)
            {
                Assert.AreEqual(data.CriteriaNavigation[i].Description, allNodes[i].CriteriaName);
                Assert.AreEqual(data.CriteriaNavigation[i].Id.ToString(), allNodes[i].CriteriaId);
            }
            Assert.IsTrue(allNodes[isInSearch].IsInSearch);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShowingCharisteriscDetails(BrowserType browserType)
        {
            var data = new CaseScreenDesignerDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainCpassRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithPermission(ApplicationTask.MaintainRules, Allow.Create | Allow.Delete | Allow.Modify)
                       .WithLicense(LicensedModule.IpMatterManagementModule)
                       .Create();
            SignIn(driver, "/#/configuration/rules/screen-designer/cases", user.Username, user.Password);
            driver.WaitForAngularWithTimeout();
            var page = new CaseScreenDesignerSearchPageObject(driver);

            page.CriteriaRadioButton.Click();
            page.Criteria.EnterAndSelect(data.CriteriaNavigation[1].Id.ToString());
            page.SubmitButtonCriteria.ClickWithTimeout();
            Assert.AreEqual(1, page.Grid.Rows.Count);
            page.Grid.Cell(0, 0).FindElement(By.TagName("a")).ClickWithTimeout();

            var inheritancePage = new CaseScreenDesignerInheritancePageObject(driver);
            inheritancePage.ToggleSummary.ClickWithTimeout();

            Assert.True(inheritancePage.InheritanceTreeItems.Length > 0, "Inheritance items exists");
            inheritancePage.InheritanceTreeItems[0].ClickWithTimeout();

            Assert.AreEqual(inheritancePage.CriteriaDetails.Length, 10);
            Assert.AreEqual(inheritancePage.CriteriaHeader, inheritancePage.InheritanceTreeItems[0].Text);

        }
    }
}
