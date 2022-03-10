using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Attachments
{
    public class AttachmentsSettingsPage : PageObject
    {
        public AttachmentsSettingsPage(NgWebDriver driver) : base(driver)
        {
        }

        NgWebElement SaveButton => Driver.FindElement(By.CssSelector(".page-title .btn-save"));

        NgWebElement RevertButton => Driver.FindElement(By.CssSelector(".page-title .cpa-icon-revert")).GetParent();

        public void Save()
        {
            SaveButton.ClickWithTimeout();
        }

        public void Revert()
        {
            RevertButton.ClickWithTimeout();
        }

        public class StorageLocationsTopic : Topic
        {
            const string TopicKey = "storageLocations";

            public StorageLocationsTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            By ModalSelector => By.CssSelector(".modal-dialog");

            public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "storageLocations");

            public NgWebElement Modal => Driver.Wait().ForVisible(ModalSelector);
            public NgWebElement ModalApply => Modal.FindElement(By.CssSelector(".btn-save"));
            public NgWebElement ModalCancel => Modal.FindElement(By.CssSelector(".btn-discard"));
            public AngularTextField Name => new AngularTextField(Driver, "name");
            public AngularTextField Path => new AngularTextField(Driver, "path");
            public AngularCheckbox CanUpload => new AngularCheckbox(Driver).ByName("canUploadModal");

            public bool ModalExists()
            {
                return Driver.FindElements(ModalSelector).Count > 0;
            }
        }

        public class NetworkDriveTopic : Topic
        {
            const string TopicKey = "networkDriveMapping";

            public NetworkDriveTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            By ModalSelector => By.CssSelector(".modal-dialog");

            public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "networkDriveMapping");

            public NgWebElement Modal => Driver.Wait().ForVisible(ModalSelector);
            public NgWebElement ModalApply => Modal.FindElement(By.CssSelector(".btn-save"));
            public NgWebElement ModalCancel => Modal.FindElement(By.CssSelector(".btn-discard"));
            public AngularDropdown Drive => new AngularDropdown(Driver).ByName("driveLetter");
            public AngularTextField Path => new AngularTextField(Driver, "uncPath");

            public bool ModalExists()
            {
                return Driver.FindElements(ModalSelector).Count > 0;
            }
        }

        public class DmsIntegrationTopic : Topic
        {
            const string TopicKey = "attachmentDmsIntegration";

            public DmsIntegrationTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public NgWebElement DmsToggle => Driver.FindElement(By.CssSelector("label[for='enableDms']"));
            public bool DmsToggleDisabled => Driver.FindElement(By.Id("enableDms")).IsDisabled();
            public NgWebElement NavigateButton => Driver.FindElement(By.Id("btnSearch"));
        }
        public class BrowseTopic : Topic
        {
            const string TopicKey = "attachmentBrowseSetting";

            public BrowseTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public NgWebElement BrowseToggle => Driver.FindElement(By.CssSelector("label[for='browseFiles']"));
        }
    }
}