using System.Linq;
using System.Threading;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaInheritance
{
    public class CriteriaInheritancePage : PageObject
    {
        public CriteriaInheritancePage(NgWebDriver driver) : base(driver)
        {
        }

        public bool IsExpandAllButtonEnabled => Driver.FindElement(By.CssSelector("button[ng-click='vm.expandAll()']")).Enabled;

        public bool IsCollapseAllButtonEnabled => Driver.FindElement(By.CssSelector("button[ng-click='vm.collapseAll()']")).Enabled;

        public NgWebElement BreakInheritanceButton => Driver.FindElement(By.ClassName("cpa-icon-unlink")).GetParent();

        public DetailView Detail => new DetailView(Driver);
        
        public InheritanceBreakConfirmation UnlinkModal => new InheritanceBreakConfirmation(Driver);

        public UnableToDeleteModal UnableToDeleteModal => new UnableToDeleteModal(Driver);

        public string PageTitle()
        {
            return Driver.FindElements(By.CssSelector("ip-sticky-header ip-page-title h2 span[ng-if='pageSubtitle']")).Last().Text;
        }

        public NgWebElement LevelUpIcon()
        {
            return Driver.FindElement(By.CssSelector("ip-sticky-header ip-page-title h2 a"));
        }

        public TreeNode[] GetAllTreeNodes()
        {
            return Driver.FindElements(By.CssSelector(".k-treeview .k-item")).Select(x => new TreeNode(x)).ToArray();
        }

        public void CollapseAll()
        {
            Driver.FindElement(By.CssSelector("button[ng-click='vm.collapseAll()']")).TryClick();
        }

        public NgWebElement DeleteButton => Driver.FindElement(By.ClassName("cpa-icon-trash-o")).GetParent();

        public void ClickDeleteButton()
        {
            DeleteButton.TryClick();
        }

        public void MoveNodeOver(int sourceIndex, int targetIndex)
        {
            var builder = new Actions(Driver);
            var source = Driver.FindElements(By.CssSelector(".k-treeview .k-item > div"))[sourceIndex];
            var target = Driver.FindElements(By.CssSelector(".k-treeview .k-item > div"))[targetIndex];

            builder.DragAndDrop(source, target).Perform();
        }

        public void ClickProceedButtonInModal()
        {
            Driver.FindElement(By.XPath("//button[@type='button' and contains(text(),'Proceed')]")).ClickWithTimeout();
        }

        public void ClickConfirmButtonInModal()
        {
            Driver.FindElement(By.XPath("//button[@type='button' and contains(text(),'Ok')]")).ClickWithTimeout();
        }

        public void MoveNodeBefore(int sourceIndex, int targetIndex)
        {
            var builder = new Actions(Driver);
            var source = Driver.FindElements(By.CssSelector(".k-treeview .k-item > div"))[sourceIndex];
            var target = Driver.FindElements(By.CssSelector(".k-treeview .k-item > div"))[targetIndex];

            builder
                .ClickAndHold(source)
                .MoveToElement(target)
                .Perform();

            for (var i = 0; i < 50; i++)
            {
                builder.MoveByOffset(0, -1).Perform();
                if (Driver.FindElements(By.CssSelector(".k-drop-hint")).Any())
                {
                    if (Driver.FindElement(By.CssSelector(".k-drop-hint")).Displayed)
                    {
                        Thread.Sleep(200);
                        builder.Release().Perform();
                        break;
                    }
                }
            }
        }

        public void SelectNodeByIndex(int index)
        {
            Driver.FindElements(By.CssSelector(".k-treeview .k-item .k-in"))[index].TryClick();
        }
        
        public void ClickNodeByIndex(int index)
        {
            Driver.FindElements(By.CssSelector(".k-treeview .k-item .k-in"))[index].FindElement(By.CssSelector("a")).Click();
        }

        public class TreeNode
        {
            readonly NgWebElement _element;

            public TreeNode(NgWebElement element)
            {
                _element = element;
            }

            public string Url => _element.FindElement(By.CssSelector(".k-in a")).GetAttribute("href");
            public string CriteriaId => _element.FindElement(By.CssSelector(".k-in a")).Text.Replace("(", string.Empty).Replace(")", string.Empty);
            public string CriteriaName => _element.FindElement(By.CssSelector(".k-in .criteria-name")).Text;
            public bool IsVisible => _element.WithJs().IsVisible();
            public bool IsInSearch => _element.FindElement(By.XPath("./div")).FindElements(By.CssSelector(".k-bot > .k-in > .isInSearch")).Any();
            public bool IsParent => _element.FindElements(By.CssSelector(".k-group")).Any();
            public bool IsProtected => _element.FindElement(By.CssSelector("span.k-in")).FindElements(By.CssSelector("span[name='protected']")).Any();
        }

        public class DetailView : PageObject
        {
            public DetailView(NgWebDriver driver) : base(driver)
            {
            }

            public string CriteriaHeader => Driver.FindElement(By.CssSelector(".detail-view header a")).Text;
            public string Office => Driver.FindElement(By.CssSelector(".detail-view span[translate='Office'] ~ .text")).Text;
            public string CaseType => Driver.FindElement(By.CssSelector(".detail-view span[translate='Case Type'] ~ .text")).Text;
            public string Jurisdiction => Driver.FindElement(By.CssSelector(".detail-view span[translate='Jurisdiction'] ~ .text")).Text;
            public string PropertyType => Driver.FindElement(By.CssSelector(".detail-view span[translate='propertyType'] ~ .text")).Text;
            public string Action => Driver.FindElement(By.CssSelector(".detail-view span[translate='Action'] ~ .text")).Text;
            public string CaseCategory => Driver.FindElement(By.CssSelector(".detail-view span[translate='Case Category'] ~ .text")).Text;
            public string SubType => Driver.FindElement(By.CssSelector(".detail-view span[translate='Sub Type'] ~ .text")).Text;
            public string DateOfLaw => Driver.FindElement(By.CssSelector(".detail-view span[translate='Date of Law'] ~ .text")).Text;
            public string LocalOrForeign => Driver.FindElement(By.CssSelector(".detail-view span[translate='Local or Foreign'] ~ .text")).Text;
            public string InUse => Driver.FindElement(By.CssSelector(".detail-view span[translate='In Use'] ~ .text")).Text;
            public string Protected => Driver.FindElement(By.CssSelector(".detail-view span[translate='Protected'] ~ .text")).Text;
        }
    }

    public class InheritanceUnlinkModal : ModalBase
    {
        const string Id = "InheritanceUnlinkConfirmationModal";

        public InheritanceUnlinkModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public void Proceed()
        {
            Modal.FindElement(By.CssSelector("button[translate='button.proceed']")).TryClick();
        }
    }

    public class UnableToDeleteModal : PageObject
    {
        public UnableToDeleteModal(NgWebDriver driver) : base(driver)
        {
        }

        public void ClickOkButton()
        {
            Driver.Wait().ForVisible(By.CssSelector(".modal-dialog button[translate='button.ok']")).TryClick();
        }
    }
}