using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Checklist.Search;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Checklist.Maintenance
{
    public class MaintainChecklistCriteria : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void AddCriteria(BrowserType browserType)
        {
            var data = new ChecklistSearchDbSetup().SetUp();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/checklist-configuration");
            
            var page = new ChecklistRulesPage(driver, "ipx-checklist-search-by-characteristics");
            page.CaseTypePl.EnterExactSelectAndBlur(data.CaseType.Name);
            page.JurisdictionPl.EnterExactSelectAndBlur(data.Jurisdiction.Name);
            page.PropertyTypePl.EnterExactSelectAndBlur(data.PropertyType.Code);
            page.ChecklistPl.EnterExactSelectAndBlur(data.ValidChecklist);
            page.AddButton.ClickWithTimeout();

            var createModal = new CreateCriteriaModal(driver);
            Assert.True(createModal.SaveButton.IsDisabled(), "Expected Save to be disabled initially until criteria is valid");

            createModal.CloseModal();

            page.AddButton.ClickWithTimeout();
            createModal = new CreateCriteriaModal(driver);
            Assert.AreEqual(data.CaseType.Name, createModal.CaseType.InputValue, $"Expected Case Type to be pre-populated with {data.CaseType.Name}");   
            Assert.AreEqual(data.Jurisdiction.Name, createModal.Jurisdiction.InputValue, $"Expected Jurisdiction to be pre-populated with {data.Jurisdiction.Name}");
            Assert.AreEqual(data.ValidPropertyType, createModal.PropertyType.InputValue, $"Expected Property Type to be pre-populated with {data.ValidPropertyType}");
            Assert.AreEqual(data.ValidChecklist, createModal.Checklist.InputValue, $"Expected Checklist to be pre-populated with {data.ValidChecklist}");

            var criteriaName = $"New Checklist - {Fixture.AlphaNumericString(20)}";
            createModal.CriteriaName.SendKeys(criteriaName);
            createModal.SaveButton.ClickWithTimeout();

            Assert.AreEqual(1, page.Grid.Rows.Count, "Expected newly added criteria to be returned by the search");
            Assert.AreEqual(criteriaName, page.Grid.CellText(0, page.Grid.FindColByText("Criteria Name")));
        }
    }
}
