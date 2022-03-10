using Inprotech.Tests.Integration.EndToEnd.Configuration.SanityCheck.Case;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.SanityCheck.Name
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SanityCheckNameMaintenance : IntegrationTest
    {
        NameSanityCheckRuleDetails _data;

        [SetUp]
        public void Setup()
        {
            _data = new SanityCheckNamesDbSetup().SetupNamesSanityData();
        }

        [TestCase(BrowserType.Chrome)]
        public void AddDeleteEditRule(BrowserType browserType)
        {
            const string newRule = "new rule - e2e";
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/sanity-check/name");

            var searchPage = new NameSearch(driver);
            searchPage.SanityCheckGrid.AddButton.Click();
            driver.WaitForAngular();

            var maintenancePage = new NameMaintenancePage(driver);
            maintenancePage.SanityRuleRelatedFields.DisplayMessage.Input.SendKeys(newRule);
            maintenancePage.SanityRuleRelatedFields.DisplayMessage.Input.SendKeys(Keys.Tab);
            Assert.AreEqual(newRule, maintenancePage.SanityRuleRelatedFields.RuleDescription.Text, "Rule description defaults from display message");
            maintenancePage.SaveButton.Click();
          
            maintenancePage.BackButton.Click();
            driver.WaitForAngular();

            searchPage.SanityRuleRelatedFields.RuleDescription.Input.SendKeys(newRule);
            searchPage.SearchButton.Click();

            driver.WaitForAngular();
            Assert.AreEqual(1, searchPage.SanityCheckGrid.Rows.Count, "The new rule is added and searchable");

            searchPage.SanityCheckGrid.Edit(0);

            maintenancePage.NameCharacteristics.Name.EnterAndSelect("e2e");
            maintenancePage.NameCharacteristics.Jurisdiction.EnterAndSelect("e2e");
            maintenancePage.NameCharacteristics.IsOrganisation.Click();
            maintenancePage.NameCharacteristics.IsClientOnly.Click();
            
            maintenancePage.InstructionRelatedFields.InstructionType.EnterAndSelect("e2e");
            maintenancePage.InstructionRelatedFields.Characteristic.EnterAndSelect("e2e");
            
            maintenancePage.SaveButton.Click();

            maintenancePage.BackButton.Click();
            driver.WaitForAngular();

            Assert.AreEqual(1, searchPage.SanityCheckGrid.Rows.Count, "Name sanity check results returned 1 row for the new rule");

            searchPage.SanityCheckGrid.SelectIpCheckbox(0);
            searchPage.BulkMenuButton.Click();
            searchPage.DeleteSelectedOption.Click();
            searchPage.DeletePopup.Click();
            driver.WaitForAngular();

            Assert.AreEqual(0, searchPage.SanityCheckGrid.Rows.Count, "Name SanityCheckGrid is refreshed and the new rule is deleted");
        }
    }
}