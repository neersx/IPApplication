using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    class DateComparisonModal : MaintenanceModal
    {
        public DateComparisonModal(NgWebDriver driver) : base(driver, null)
        {
        }

        public PickList EventA => new PickList(Driver).ByName(".modal", "eventA");

        public IpRadioButton EventAEventDate => new IpRadioButton(Driver, Modal).ByName("eventAEventDate");

        public IpRadioButton EventADueDate => new IpRadioButton(Driver, Modal).ByName("eventADueDate");

        public IpRadioButton EventAEventOrDue => new IpRadioButton(Driver, Modal).ByName("eventAEventOrDue");

        public DropDown EventARelativeCycle => new DropDown(Driver, Modal).ByName("eventARelativeCycle");

        public DropDown ComparisonOperator => new DropDown(Driver, Modal).ByName("comparisonOperator");

        public IpRadioButton CompareEventBOption => new IpRadioButton(Driver, Modal).ByLabel(".eventB");

        public IpRadioButton CompareDateOption => new IpRadioButton(Driver, Modal).ByLabel(".date");

        public IpRadioButton CompareSystemDateOption => new IpRadioButton(Driver, Modal).ByLabel(".systemDate");
        
        public PickList EventB => new PickList(Driver).ByName(".modal", "eventB");
        public IpRadioButton EventBEventDate => new IpRadioButton(Driver, Modal).ByName("eventBEventDate");
        public IpRadioButton EventBDueDate => new IpRadioButton(Driver, Modal).ByName("eventBDueDate");
        public IpRadioButton EventBEventOrDue => new IpRadioButton(Driver, Modal).ByName("eventBEventOrDue");
        public DropDown EventBRelativeCycle => new DropDown(Driver, Modal).ByName("eventBRelativeCycle");
        public PickList CompareRelationship => new PickList(Driver).ByName(".modal", "compareRelationship");
        
        public DatePicker CompareDate => new DatePicker(Driver, "compareDate");
        
        public bool EventBOptionsHidden()
        {
            return !Driver.FindElements(By.CssSelector("ip-typeahead[name='eventB']")).Any();
        }
        public bool CompareOptionsHidden()
        {
            return !Driver.FindElements(By.CssSelector("ip-radio-button[label='.eventB']")).Any();
        }

        public bool CompareDateHidden()
        {
            return !Driver.FindElements(By.CssSelector("ip-datepicker[name='compareDate']")).Any();
        }
    }
}