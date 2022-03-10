using System.Linq;
using System.Threading;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Names
{
    public class NameViewDetailPageObjects : DetailPage
    {
        public NameViewDetailPageObjects(NgWebDriver driver) : base(driver)
        {
        }
        
        public string PageTitle()
        {
            return Driver.FindElements(By.CssSelector("ipx-sticky-header ipx-page-title h2 before-title span")).Last().Text;
        }
        public NgWebElement MessageDiv => Driver.FindElement(By.ClassName("flash_alert"));
    }

    public class SupplierDetailsTopic : Topic
    {
        const string TopicKey = "supplierDetails";

        public SupplierDetailsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public AngularDropdown SupplierType => new AngularDropdown(Driver, "ipx-dropdown").ByName("SupplierType");
        public NgWebElement PurchaseDescriptionTextbox => Driver.FindElement(By.CssSelector("ipx-text-field[name='purchaseDescription'] textarea"));
        public NgWebElement InstructionTextbox => Driver.FindElement(By.CssSelector("ipx-text-field[name='instruction'] textarea"));
        public NgWebElement Payee => Driver.FindElement(By.CssSelector("ipx-text-field[name='withPayee'] textarea"));
        public AngularDropdown PaymentMethodDropDown => new AngularDropdown(Driver, "ipx-dropdown").ByName("paymentMethod");
        public AngularDropdown PaymentRestrictionDropDown => new AngularDropdown(Driver, "ipx-dropdown").ByName("paymentRestriction");
        public AngularDropdown ReasonDropDown => new AngularDropdown(Driver, "ipx-dropdown").ByName("reasonForRestriction");
        public AngularPicklist SendTo => new AngularPicklist(Driver).ByName("sendToName");
        public AngularPicklist SendToAttentionName => new AngularPicklist(Driver).ByName("attentionName");
        public AngularPicklist SendToAddress =>new AngularPicklist(Driver).ByName("sendToNameAddress");
        public NgWebElement Revert => Driver.FindElement(By.TagName("ipx-revert-button"));
        public ButtonInput SaveButton => new ButtonInput(Driver).ByCssSelector("ipx-save-button button");
    }

    public class TrustAccountingTopic : Topic
    {
        const string TopicKey = "trustAccounting";

        public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "trustAccounting");

        public TrustAccountingTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            TopicContainerSelector = $"[data-topic-key^='{TopicKey}']";
        }

        public new void NavigateTo()
        {
            Driver.FindElement(By.CssSelector("[data-topic-ref^=" + TopicKey + "]")).TryClick();
            Thread.Sleep(500);
        }
        public NgWebElement LocalBalanceTotal => Driver.FindElement(By.Name("localBalanceTotal"));

        public void ClickLocalBalance(int row)
        {
            Grid.Rows[row].FindElement(By.Name("lnkLocalBalance")).ClickWithTimeout();
        }

        public AngularKendoGrid DetailGrid => new AngularKendoGrid(Driver, "trustAccountingDetails");

        public void ClosePopup()
        {
            var button = FindElements(By.CssSelector(".modal-content .btn-discard")).Last();
            button.WithJs().Click();
        }
        public NgWebElement LocalValueTotal => Driver.FindElement(By.Name("localValueTotal"));

        public NgWebElement DetailLocalBalanceTotal => Driver.FindElement(By.Name("detailLocalBalanceTotal"));
    }

    public class NameDmsTopic : Topic
    {
        const string TopicKey = "nameDocumentManagementSystem";

        public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "nameDocumentManagementSystem");

        public NameDmsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            TopicContainerSelector = $"[data-topic-key^='{TopicKey}']";
        }
        public TreeView DirectoryTreeView => new TreeView(Driver);
        public DocumentManagementPageObject.DocumentGrid Documents => new DocumentManagementPageObject.DocumentGrid(Driver);

    }
}