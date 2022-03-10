using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.WipAdjustments
{
    public class WipAdjustmentsPageObject : PageObject
    {
        public WipAdjustmentsPageObject(NgWebDriver driver) : base(driver)
        {
        }
        public IpxTextField WipCode => new IpxTextField(Driver).ByName("wipCode");
        public DatePicker TransactionDate => new DatePicker(Driver, "transactionDate");
        public AngularPicklist CasePicklist => new AngularPicklist(Driver).ByName("newCase");
        public AngularPicklist StaffPicklist => new AngularPicklist(Driver).ByName("newStaff");
        public AngularDropdown Reason => new AngularDropdown(Driver).ByName("reason");
        public IpxRadioButton DebitRadioButton => new IpxRadioButton(Driver).ById("rdbDebit");
        public IpxRadioButton CreditRadioButton => new IpxRadioButton(Driver).ById("rdbCredit");
        public IpxRadioButton StaffRadioButton => new IpxRadioButton(Driver).ById("rdbStaff");
        public IpxRadioButton NarrativeRadioButton => new IpxRadioButton(Driver).ById("rdbNarrative");
        public IpxTextField DebitNoteText => new IpxTextField(Driver).ByName("debitNoteText");
        public IpxNumericField LocalValue => new IpxNumericField(Driver, Container).ByName("localValue");
        public IpxNumericField LocalAdjustmentValue => new IpxNumericField(Driver, Container).ByName("localAdjustment");
        public IpxNumericField CurrentLocalValue => new IpxNumericField(Driver, Container).ByName("currentLocalValue");
        public IpxNumericField ForeignValue => new IpxNumericField(Driver, Container).ByName("foreignValue");
        public IpxNumericField CurrentForeignValue => new IpxNumericField(Driver, Container).ByName("currentForeignValue");
        public ButtonInput SaveButton => new ButtonInput(Driver).ByCssSelector("ipx-save-button button");
        public NgWebElement ButtonClose => Driver.FindElement(By.CssSelector("ipx-close-button button"));
    }
}