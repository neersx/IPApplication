using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.ScreenDesigner.Cases
{
    internal class CaseScreenDesignerMaintenancePageObject : DetailPage
    {
        public CaseScreenDesignerMaintenancePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public string CriteriaNumber => Driver.FindElement(By.Id("screen-designer-criteria-id")).WithJs().GetInnerText();

        public string CriteriaName => CriteriaNameTextField.Text;

        public string Office => OfficePicklist.GetText();

        public AngularPicklist OfficePicklist => new AngularPicklist(Driver).ByName("office");

        public string Program => ProgramPicklist.GetText();

        public AngularPicklist ProgramPicklist => new AngularPicklist(Driver).ByName("program");

        public string CaseType => CaseTypePicklist.GetText();

        public AngularPicklist CaseTypePicklist => new AngularPicklist(Driver).ByName("caseType");

        public string Jurisdiction => JurisdictionPicklist.GetText();

        public AngularPicklist JurisdictionPicklist => new AngularPicklist(Driver).ByName("jurisdiction");

        public string PropertyType => PropertyTypePicklist.GetText();

        public AngularPicklist PropertyTypePicklist => new AngularPicklist(Driver).ByName("propertyType");

        public string CaseCategory => CaseCategoryPicklist.GetText();

        public AngularPicklist CaseCategoryPicklist => new AngularPicklist(Driver).ByName("caseCategory");

        public string SubType => SubTypePicklist.GetText();

        public AngularPicklist SubTypePicklist => new AngularPicklist(Driver).ByName("subType");

        public string Basis => BasisPicklist.GetText();

        public AngularPicklist BasisPicklist => new AngularPicklist(Driver).ByName("basis");

        public string Profile => ProfilePicklist.GetText();

        public AngularPicklist ProfilePicklist => new AngularPicklist(Driver).ByName("profile");

        public AngularTextField CriteriaNameTextField => new AngularTextField(Driver, "criteriaName");

        public AngularKendoGrid SectionGrid => new AngularKendoGrid(Driver, "gridSections");

        public bool InheritanceIconShowing => Driver.FindElements(By.CssSelector(".title-header.screen-designer-details .cpa-icon-inheritance")).Any();
        public NgWebElement InheritanceIcon => Driver.FindElement(By.CssSelector(".title-header.screen-designer-details .cpa-icon-inheritance"));

    }
}