using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Work
{
    public class WipDisbursementsPageObject : PageObject
    {
        public WipDisbursementsPageObject(NgWebDriver driver) : base(driver)
        {
        }
        public DatePicker TransactionDate => new DatePicker(Driver, "transactionDate");
        public AngularDropdown EntityDropDown => new AngularDropdown(Driver).ByName("entityDropdown");
        public IpxNumericField TotalAmount => new IpxNumericField(Driver, Container).ByName("totalAmount");
        public AngularPicklist CurrencyPickList => new AngularPicklist(Driver).ByName("currency");
        public AngularKendoGrid DisbursementsGrid => new AngularKendoGrid(Driver, "disbursementsGrid");
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement ModalApply => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));
        public ButtonInput SaveButton => new ButtonInput(Driver).ByCssSelector("ipx-save-button button");
        public DatePicker Date => new DatePicker(Driver, "date");
        public AngularPicklist DisbursementPickList => new AngularPicklist(Driver).ByName("disbursements");
        public AngularPicklist CasePickList => new AngularPicklist(Driver).ByName("case");
        public AngularPicklist NamePickList => new AngularPicklist(Driver).ByName("name");
        public AngularPicklist StaffPickList => new AngularPicklist(Driver).ByName("staff");
        public IpxNumericField Amount => new IpxNumericField(Driver, Container).ByName("amount");
        public AngularCheckbox AddAnotherCheckbox => new AngularCheckbox(Driver).ByName("addAnother");
    }
}