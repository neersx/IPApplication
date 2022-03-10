using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaMaintenance
{
    public class CriteriaMaintenance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddCriteria(BrowserType browserType)
        {
            CriteriaMaintenanceDbSetup.DetailDataFixture dataFixture;
            using (var setup = new CriteriaMaintenanceDbSetup())
            {
                dataFixture = setup.SetUp();
            }

            var driver = BrowserProvider.Get(browserType);
            var url = "/#/configuration/rules/workflows";
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainWorkflowRulesProtected)
                       .Create();
            SignIn(driver, url, user.Username, user.Password);
            var modal = new CriteriaMaintenanceModal(driver);

            driver.FindElement(By.Id("criteria-add-btn")).ClickWithTimeout();

            Assert.True(modal.InUseYes.IsChecked, "By defualt InUse is set to Yes");
            Assert.True(modal.ProtectCriteriaNo.IsChecked, "By defualt Protect Criteria is set to No");

            Assert.False(modal.ProtectCriteriaYes.IsDisabled, "can edit protected criteria");
            Assert.False(modal.ProtectCriteriaNo.IsDisabled, "can edit protected criteria");

            modal.CriteriaName.Input(dataFixture.CriteriaName);
            modal.OfficePl.SendKeys(dataFixture.Office);
            modal.ActionPl.SendKeys(dataFixture.Action);
            modal.CaseTypePl.SendKeys(dataFixture.CaseType);
            modal.JurisdictionPl.SendKeys(dataFixture.Jurisdiction);
            modal.RenewalPl.EnterAndSelect(dataFixture.RenewalType);

            modal.Save.Click();

            Criteria criteria;
            using (var setup = new CriteriaMaintenanceDbSetup())
            {
                criteria = setup.GetCriteria(dataFixture.CriteriaName);
            }

            Assert.NotNull(criteria, "Criteria is saved in database");
            Assert.AreEqual(driver.Url, $"{Env.RootUrl}/#/configuration/rules/workflows/{criteria.Id}", "Modal should redirect to detail page after save");

            var criteriaDetailsPage = new WorkflowCharacteristicsPage(driver, "div[data-topic-key=\"characteristics\"]");
            Assert.AreEqual(dataFixture.Action, criteriaDetailsPage.ActionPl.GetText());
            Assert.AreEqual(dataFixture.RenewalType, criteriaDetailsPage.RenewalPl.GetText());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PreventChangesToProtectedCriteriaIfUnauthorised(BrowserType browserType)
        {
            using (var setup = new CriteriaMaintenanceDbSetup())
            {
                setup.SetUp();
            }

            var driver = BrowserProvider.Get(browserType);
            var url = "/#/configuration/rules/workflows";
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainWorkflowRules)
                       .WithPermission(ApplicationTask.MaintainWorkflowRulesProtected, Deny.Execute)
                       .Create();
            SignIn(driver, url, user.Username, user.Password);
            var modal = new CriteriaMaintenanceModal(driver);

            driver.FindElement(By.Id("criteria-add-btn")).ClickWithTimeout();

            Assert.True(modal.ProtectCriteriaYes.IsDisabled, "No right to edit protected criteria");
            Assert.True(modal.ProtectCriteriaNo.IsDisabled, "No right to edit protected criteria");
        }
    }
}