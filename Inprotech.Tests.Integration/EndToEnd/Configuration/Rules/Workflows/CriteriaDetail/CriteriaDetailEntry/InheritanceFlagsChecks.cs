using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail.CriteriaDetailEntry
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class InheritanceFlagsChecks : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void InheritanceFlags(BrowserType browserType)
        {
            Criteria criteria;

            using (var setup = new CriteriaDetailInheritenceFlagsDbSetup())
            {
                criteria = setup.AddCriteriaWithEntryInheritance();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows/" + criteria.Id);

            var entryGrid = new KendoGrid(driver, "entriesResults");

            var fullInheritsCell = entryGrid.Cell(0, 1).FindElement(By.TagName("span"));
            Assert.True(fullInheritsCell.WithJs().HasClass("cpa-icon-inheritance"));

            var partialInheritsCell = entryGrid.Cell(1, 1).FindElement(By.TagName("span"));
            Assert.True(partialInheritsCell.WithJs().HasClass("cpa-icon-inheritance-partial"));

            var noInheritanceCell = entryGrid.Cell(2, 1).FindElement(By.TagName("span"));
            Assert.False(noInheritanceCell.WithJs().HasClass("cpa-icon-inheritance"));
            Assert.False(noInheritanceCell.WithJs().HasClass("cpa-icon-inheritance-partial"));
        }
    }
}