using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CriteriaSearchCases : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchByCase(BrowserType browserType)
        {
            CriteriaSearchDbSetup.Result dataFixture;
            using (var setup = new CriteriaSearchDbSetup())
            {
                dataFixture = setup.Setup();
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");

            Assert.IsTrue(driver.FindRadio("search-by-characteristics").Input.Selected, "search by characteristics should be default selection");

            // switch to Search By Case 

            driver.FindRadio("search-by-case").Click();

            var protectedCriteria = driver.FindElement(By.Id("characteristics-include-protected-criteria"));

            Assert.IsTrue(protectedCriteria.Selected, "Protected criteria is ticked by default if a user has MaintainWorkflowRulesProtected permission");

            #region Auto-fills criteria and focuses on Action

            var page = new WorkflowCharacteristicsPage(driver, "ip-search-by-case");
            
            page.CasePl.EnterAndSelect(CriteriaSearchDbSetup.Irn);

            Assert.AreEqual(CriteriaSearchDbSetup.OfficeDescription, page.OfficePl.GetText());
            Assert.AreEqual(CriteriaSearchDbSetup.CaseTypeDescription, page.CaseTypePl.GetText());
            Assert.AreEqual(CriteriaSearchDbSetup.JurisdictionDescription, page.JurisdictionPl.GetText());
            Assert.AreEqual(CriteriaSearchDbSetup.ValidPropertyTypeDescription, page.PropertyTypePl.GetText());
            Assert.AreEqual(CriteriaSearchDbSetup.ValidCaseCategoryDescription, page.CaseCategoryPl.GetText());
            Assert.AreEqual(CriteriaSearchDbSetup.ValidSubTypeDescription, page.SubTypePl.GetText());
            Assert.AreEqual(CriteriaSearchDbSetup.ValidBasisDescription, page.BasisPl.GetText());
            Assert.AreEqual(string.Empty, page.DateOfLawPl.GetText());
            Assert.AreEqual("foreign-clients", page.LocalOrForeign.Value);

            #endregion
            
            page.ActionPl.EnterAndSelect(CriteriaSearchDbSetup.ValidActionDescription);
            Assert2.WaitEqual(3, 500, () => dataFixture.FormattedDateOfLaw, () => page.DateOfLawPl.GetText(), "Defaults Date Of Law when Case and Action Specified");
        }
    }
}