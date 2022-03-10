using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Events
{
    internal class ConfirmPropagateChangesModal : ModalBase
    {
        const string Id = "confirmPropagateEventChanges";
        public ConfirmPropagateChangesModal(NgWebDriver driver) : base(driver, Id)
        {
        }
        
        public NgWebElement ProceedButton => Modal.FindElement(By.ClassName("btn-primary"));
        public NgWebElement CancelButton => Modal.FindElement(By.CssSelector("button:not(.btn-primary)"));
        public Checkbox ActionOption => new Checkbox(Driver).ByLabel(".checkboxLabel");
        public NgWebElement UpdatedFields => Modal.FindElement(By.CssSelector("#updatedFields>ul"));
    }
}
