using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination
{
    internal class ValidCombinationsPage : DetailPage
    {
        public ValidCombinationsPage(NgWebDriver driver) : base(driver)
        {
        }

        public PickList Jurisdiction => new PickList(Driver).ById("jurisdiction-picklist");
        public PickList PropertyType => new PickList(Driver).ById("property-type-picklist");
        public PickList MaintainCaseType => new PickList(Driver).ById("case-type-picklist");
        public PickList MaintainJurisdiction => new PickList(Driver).ById("pk-jurisdiction");
        public PickList MaintainPropertyType => new PickList(Driver).ById("pk-property-type");
        public PickList MaintainCategory => new PickList(Driver).ById("case-category-picklist");
        public PickList MaintainBasis => new PickList(Driver).ById("basis-picklist");
        public SelectElement Characteristic => new SelectElement(Driver.FindElement(By.Name("searchcharacteristic")));
        public PickList MaintainSubType => new PickList(Driver).ById("sub-type-picklist");
        public PickList MaintainChecklist => new PickList(Driver).ById("checklist-picklist");
        public PickList MaintainRelationship => new PickList(Driver).ById("relationship-picklist");
    }
}