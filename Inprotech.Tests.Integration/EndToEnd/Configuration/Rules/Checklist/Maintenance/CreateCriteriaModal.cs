using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Checklist.Maintenance
{
    public class CreateCriteriaModal : MaintenanceModal
    {
        public CreateCriteriaModal(NgWebDriver driver, string id = null) : base(driver, id)
        {
        }

        public NgWebElement SaveButton => Modal.FindElement(By.CssSelector("ipx-save-button")).FindElement(By.TagName("button"));
        public void CloseModal()
        {
            Modal.FindElement(By.CssSelector("ipx-close-button button")).ClickWithTimeout();
        }
        public AngularPicklist Office => new AngularPicklist(Driver).ByName("office");
        public AngularPicklist CaseType => new AngularPicklist(Driver).ByName("caseType");
        public AngularPicklist Jurisdiction => new AngularPicklist(Driver).ByName("jurisdiction");
        public AngularPicklist PropertyType => new AngularPicklist(Driver).ByName("propertyType");
        public AngularPicklist Checklist => new AngularPicklist(Driver).ByName("checklist");
        public NgWebElement CriteriaName => Driver.FindElement(By.CssSelector("ipx-text-field[name='criteriaName'] textarea"));
    }
}
