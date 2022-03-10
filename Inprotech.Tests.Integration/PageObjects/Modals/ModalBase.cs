using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Modals
{
    public class ModalBase : PageObject
    {
        readonly string _id;

        public ModalBase(NgWebDriver driver, string id = null) : base(driver)
        {
            _id = id;
        }

        public NgWebElement Modal
        {
            get
            {
                var selector = By.ClassName("modal");
                var script = "return $('.modal').is(':visible') == true;";

                if (_id != null)
                {
                    selector = By.Id(_id);
                    script = $"return $('#{_id}').is(':visible') == true;";
                }
                
                Driver.Wait().ForTrue(() => Driver.WrappedDriver.ExecuteJavaScript<bool>(script));

                return Driver.FindElement(selector);
            }
        }

        protected void WaitUntilModalClose(int waitTimeout = 150000)
        {
            var script = "return $('.modal').is(':visible') == false;";
            if (_id != null)
            {
                script = $"return $('#{_id}').is(':visible') == false;";
            }

            Driver.Wait().ForTrue(() => Driver.WrappedDriver.ExecuteJavaScript<bool>(script), waitTimeout);
        }
    }

    public class MaintenanceModal : ModalBase
    {
        public MaintenanceModal(NgWebDriver driver, string id = null) : base(driver, id)
        {

        }

        public void Apply()
        {
            Modal.FindElement(By.ClassName("btn-save")).TryClick();
        }

        public void Close()
        {
            Modal.FindElement(By.ClassName("btn-discard")).TryClick();
        }

        public void ToggleAddAnother()
        {
            Modal.FindElement(By.CssSelector(".modal-header-controls ip-checkbox label")).TryClick();
        }

        public void NavigateToFirst()
        {
            Modal.FindElement(By.CssSelector(".modal-nav button[ng-click=\"vm.first()\"]")).TryClick();
        }

        public void NavigateToPrevious()
        {
            Modal.FindElement(By.CssSelector(".modal-nav button[ng-click=\"vm.prev()\"]")).TryClick();
        }

        public void NavigateToNext()
        {
            Modal.FindElement(By.CssSelector(".modal-nav button[ng-click=\"vm.next()\"]")).TryClick();
        }

        public void NavigateToLast()
        {
            Modal.FindElement(By.CssSelector(".modal-nav button[ng-click=\"vm.last()\"]")).TryClick();
        }
    }
}