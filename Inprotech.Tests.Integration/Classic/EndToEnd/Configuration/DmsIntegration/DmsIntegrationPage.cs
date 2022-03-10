using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.Configuration.DmsIntegration
{
    public class DmsIntegrationPage : PageObject
    {
        readonly string DmsButtonSelector = "div[data-topic-key=UsptoPrivatePair] .dms-send-btn";

        public DmsIntegrationPage(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement SaveButton => Driver.FindElements(By.CssSelector(".btn-save")).Last();
        public DiscardChangesModal DiscardChangesModal => new DiscardChangesModal(Driver);

        public bool IsSaveDisabled => SaveButton.IsDisabled();

        public NgWebElement RevertButton => Driver.FindElement(By.CssSelector(".cpa-icon-revert")).GetParent();

        public ButtonInput MoveToDms => new ButtonInput(Driver).ByCssSelector(DmsButtonSelector);

        public bool MoveToDmsExists => Driver.FindElements(By.CssSelector(DmsButtonSelector)).Count > 0;

        public NgWebElement PrivatePairChk => Driver.FindElement(By.CssSelector("div[data-topic-key=UsptoPrivatePair] .switch label"));

        public TextInput PrivatePairLocation => new TextInput(Driver).ByCssSelector("div[data-topic-key=UsptoPrivatePair] input[type=text]");

        public NgWebElement AlertInfoIdle => Driver.FindElement(By.CssSelector("div[data-topic-key=UsptoPrivatePair] .alert-info.idle"));
        public NgWebElement AlertInfoStarted => Driver.FindElement(By.CssSelector("div[data-topic-key=UsptoPrivatePair] .alert-info.started"));

        public NgWebElement AlertInfoSuccess => Driver.FindElement(By.CssSelector("div[data-topic-key=UsptoPrivatePair] .alert-success"));
        public ButtonInput AlertInfoSuccessClose => new ButtonInput(Driver).ByCssSelector("div[data-topic-key=UsptoPrivatePair] .alert-success .close");
        public AngularTextField WorkspaceUsername => new AngularTextField(Driver, "username");
        public AngularTextField WorkspacePassword => new AngularTextField(Driver, "password");
        public AngularPicklist WorkspaceCaseRef => new AngularPicklist(Driver, Container).ByName("caseIrn");
        public AngularPicklist WorkspaceNameRef => new AngularPicklist(Driver, Container).ByName("pkName");
        public NgWebElement WorkspaceTestButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("workspaceTest"));
        }
        public NgWebElement WorkspaceTestCancelButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("workspaceCancel"));
        }

        public void Save()
        {
            SaveButton.ClickWithTimeout();
        }

        public void Revert()
        {
            RevertButton.ClickWithTimeout();
        }

        public class DatabaseTopic : Topic
        {
            const string TopicKey = "databases";

            public DatabaseTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "imanageDatabase");
            public NgWebElement Enabled => Driver.FindElement(By.CssSelector("div[data-topic-key=iManageSettings] .switch label"));

            public NgWebElement Notification => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
            public NgWebElement NotificationTitle => Driver.FindElement(By.Id("modalErrorLabel"));
            public NgWebElement NotificationYes => Driver.FindElement(By.CssSelector(".modal-dialog .btn-primary"));
            public NgWebElement NotificationCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn"));
            public NgWebElement NotificationNo => Driver.FindElement(By.CssSelector(".modal-dialog .btn"));
            public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
            public NgWebElement ModalApply => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
            public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));
            public AngularTextField Server => new AngularTextField(Driver, "server");
            public AngularTextField Database => new AngularTextField(Driver, "Database");
            public AngularDropdown IntegrationType => new AngularDropdown(Driver).ByName("IntegrationType");
            public AngularTextField CustomerId => new AngularTextField(Driver, "CustomerId");
            public AngularDropdown LoginType => new AngularDropdown(Driver).ByName("LoginType");
            public AngularTextField Password => new AngularTextField(Driver, "password");
            public AngularTextField ClientId => new AngularTextField(Driver, "ClientId");
            public AngularTextField ClientSecret => new AngularTextField(Driver, "ClientSecret");
            public AngularTextField TestUsername => new AngularTextField(Driver, "testUsername");
            public AngularTextField TestPassword => new AngularTextField(Driver, "testPassword");
            public NgWebElement TestSaveButton(NgWebDriver driver)
            {
                return driver.FindElement(By.CssSelector("ipx-i-manage-credentials-input .btn-save"));
            }

            public DiscardChangesModal DiscardChangesModal => new DiscardChangesModal(Driver);

            public NgWebElement Description(NgWebDriver driver, string level)
            {
                return driver.FindElement(By.Id(level)).FindElement(By.TagName("input"));
            }

            public NgWebElement SaveButton(NgWebDriver driver)
            {
                return driver.FindElement(By.CssSelector(".btn-save"));
            }
            public NgWebElement TestButton(NgWebDriver driver)
            {
                return driver.FindElement(By.Name("test"));
            }

            public NgWebElement TestWorkspaceButton(NgWebDriver driver, string type)
            {
                return driver.FindElement(By.Name(type));
            }

            public NgWebElement RevertButton(NgWebDriver driver)
            {
                return driver.FindElement(By.CssSelector(".btn-warning"));
            }

            public NgWebElement DeleteButton(NgWebDriver driver, string level)
            {
                return driver.FindElement(By.XPath("//ip-text-field[@id='" + level + "']/parent::*/parent::*//ip-kendo-toggle-delete-button//button"));
            }
        }

        public class WorkSpaceTopic : Topic
        {
            const string TopicKey = "workspaces";

            public WorkSpaceTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public AngularKendoGrid NameTypesGrid => new AngularKendoGrid(Driver, "imanageWorkspacesNameTypes");

            public AngularDropdown SearchField => new AngularDropdown(Driver).ByName("SearchField");

            public AngularTextField SubClass => new AngularTextField(Driver, "Subclass");
            public AngularTextField Subtype => new AngularTextField(Driver, "Subtype");

            public class EditableNameRow : PageObject
            {
                public EditableNameRow(NgWebDriver driver, AngularKendoGrid grid, int rowIndex, NgWebElement container = null) : base(driver, container)
                {
                    Container = grid.Rows[rowIndex];
                }

                public AngularPicklist NameType => new AngularPicklist(Driver, Container).ByName("nameTypePicklist");

                public IpxTextField SubClass => new IpxTextField(Driver, Container).ByName("subClass");
            }
        }

        public class DataItemTopic : Topic
        {
            const string TopicKey = "dataItems";

            public DataItemTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public AngularPicklist CaseSearch => new AngularPicklist(Driver, Container).ByName("caseSearch");
            public AngularPicklist NameSearch => new AngularPicklist(Driver, Container).ByName("nameSearch");
        }
    }
}