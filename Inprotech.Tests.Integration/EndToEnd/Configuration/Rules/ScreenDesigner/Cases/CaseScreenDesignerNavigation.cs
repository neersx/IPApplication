using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.ScreenDesigner.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseScreenDesignerNavigation : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void FiltersArePersistedOnNavigatingInAndOutOfRecords(BrowserType browserType)
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

            page.SubmitButton.WithJs().Click();
            Assert.True(page.PageIsShown, "Page is shown");
            Assert.True(page.Grid.Rows.Any(), "Records are shown after search");
            page.Characteristics.Program.EnterAndSelect(data.ProgramNavigation.Name);
            driver.WaitForAngular();
            page.CriteriaNotInUse.Click();
            driver.WaitForAngular();

            page.SubmitButton.WithJs().Click();
            Assert.AreEqual(10, page.Grid.Rows.Count, "10 matching rows are shown");

            page.Grid.Cell(9, "Criteria No.").FindElement(By.TagName("a")).Click();
            driver.WaitForAngular();
            var maintenancePage = new CaseScreenDesignerMaintenancePageObject(driver);
            maintenancePage.LevelUpButton.Click();
            driver.WaitForAngular();

            Assert.IsNotEmpty(page.Characteristics.Program.InputValue);

            page.CriteriaRadioButton.Click();
            driver.WaitForAngular();

            page.Criteria.EnterAndSelect(data.CriteriaNavigation[0].Id.ToString());
            driver.WaitForAngular();
            page.SubmitButtonCriteria.Click();
            driver.WaitForAngular();
            Assert.AreEqual(1, page.Grid.Rows.Count);
            Assert.AreEqual(data.CriteriaNavigation[0].Id.ToString(), page.Grid.Cell(0, "Criteria No.").WithJs().GetInnerText());
            page.Grid.Cell(0, "Criteria No.").FindElement(By.TagName("a")).Click();

            driver.WaitForAngular();
            maintenancePage.LevelUpButton.Click();
            driver.WaitForAngular();

            Assert.True(page.CriteriaRadioButton.IsChecked, "Maintains tab selection");
            Assert.AreEqual(1, page.Grid.Rows.Count, "Correct number of rows reloaded");
            Assert.AreEqual(page.Criteria.Tags.FirstOrDefault(), data.CriteriaNavigation[0].Id.ToString(), "Criteria filter persisted");
            Assert.AreEqual(data.CriteriaNavigation[0].Id.ToString(), page.Grid.Cell(0, "Criteria No.").WithJs().GetInnerText(), "Correct Criteria Shown");

            page.CharacteristicsRadioButton.Click();
            driver.WaitForAngular();
            Assert.IsNotEmpty(page.Characteristics.Program.InputValue, "Program filter still persisted.");

            page.SubmitButton.Click();
            driver.WaitForAngular();
            page.Grid.Cell(9, "Criteria No.").FindElement(By.TagName("a")).Click(); //Click last visible;
            AssertCriteria(maintenancePage, data.CriteriaNavigation[9], driver);
            maintenancePage.AngularPageNav.NextPage();
            AssertCriteria(maintenancePage, data.CriteriaNavigation[10], driver);
            maintenancePage.AngularPageNav.NextPage();
            AssertCriteria(maintenancePage, data.CriteriaNavigation[11], driver);
            maintenancePage.AngularPageNav.NextPage();
            AssertCriteria(maintenancePage, data.CriteriaNavigation[12], driver);

            maintenancePage.LevelUpButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual("2", page.Grid.CurrentPage(), "Is on second page now");
            Assert.AreEqual(3, page.Grid.Rows.Count);
            page.Grid.Cell(0, "Criteria No.").FindElement(By.TagName("a")).Click(); //Click first visible;
            AssertCriteria(maintenancePage, data.CriteriaNavigation[10], driver);
            maintenancePage.AngularPageNav.PrePage();
            AssertCriteria(maintenancePage, data.CriteriaNavigation[9], driver);

            maintenancePage.AngularPageNav.PrePage();
            AssertCriteria(maintenancePage, data.CriteriaNavigation[8], driver);

            maintenancePage.AngularPageNav.PrePage();
            AssertCriteria(maintenancePage, data.CriteriaNavigation[7], driver);

            maintenancePage.LevelUpButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual("1", page.Grid.CurrentPage(), "Is back on first page");
            Assert.AreEqual(10, page.Grid.Rows.Count);

        }

        void AssertCriteria(CaseScreenDesignerMaintenancePageObject page, Criteria criteria, NgWebDriver driver)
        {
            driver.WaitForAngular();

            Assert.AreEqual(page.CriteriaName, criteria.Description ?? string.Empty);
            Assert.AreEqual(page.Office, criteria.Office?.Name ?? string.Empty);
            Assert.AreEqual(page.CaseType, criteria.CaseType?.Name ?? string.Empty);
            Assert.AreEqual(page.Jurisdiction, criteria.Country?.Name ?? string.Empty);
            Assert.AreEqual(page.PropertyType, criteria.PropertyType?.Name ?? string.Empty);
            Assert.AreEqual(page.CaseCategory, criteria.CaseCategory?.Name ?? string.Empty);
            Assert.AreEqual(page.SubType, criteria.SubType?.Name ?? string.Empty);
            Assert.AreEqual(page.Basis, criteria.Basis?.Name ?? string.Empty);
        }
    }
}