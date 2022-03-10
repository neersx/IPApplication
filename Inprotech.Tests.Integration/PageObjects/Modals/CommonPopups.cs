using System.Linq;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Modals
{
    public class CommonPopups : PageObject
    {
        public CommonPopups(NgWebDriver driver) : base(driver)
        {
        }

        public ConfirmModal ConfirmModal => new ConfirmModal(Driver);
        public AngularConfirmDeleteModal ConfirmNgDeleteModal => new AngularConfirmDeleteModal(Driver);
        public ConfirmDeleteModal ConfirmDeleteModal => new ConfirmDeleteModal(Driver);
        public DiscardChangesModal DiscardChangesModal => new DiscardChangesModal(Driver);
        public InfoModal InfoModal => new InfoModal(Driver);
        public AlertModal AlertModal => new AlertModal(Driver);
        public SanityCheckModal SanityCheckModal => new SanityCheckModal(Driver);

        public NgWebElement FlashAlert()
        {
            return Driver.FindElements(By.ClassName("flash_alert")).FirstOrDefault();
        }

        public void WaitForFlashAlert(int timeout = 120000)
        {
            Driver.Wait().ForExists(By.ClassName("flash_alert"), timeout);
        }

        public bool FlashAlertIsDisplayed(int timeout = 120000)
        {
            try
            {
                Driver.Wait().ForExists(By.ClassName("flash_alert"), timeout);
                return true;
            }
            catch (WebDriverTimeoutException)
            {
                return false;
            }
        }

        public void Dismiss()
        {
            Driver.FindElement(By.Id("dismissAll")).WithJs().Click();
        }
    }
}