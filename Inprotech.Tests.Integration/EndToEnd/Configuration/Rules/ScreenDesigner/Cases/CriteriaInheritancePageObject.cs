using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaInheritance;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.ScreenDesigner.Cases
{
    class CriteriaInheritancePageObject : DetailPage
    {
        public CriteriaInheritancePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public bool IsExpandAllButtonEnabled => Driver.FindElement(By.CssSelector("button[ng-click='vm.expandAll()']")).Enabled;

        public bool IsCollapseAllButtonEnabled => Driver.FindElement(By.CssSelector("button[ng-click='vm.collapseAll()']")).Enabled;

        public string PageTitle()
        {
            return Driver.FindElements(By.CssSelector("ipx-sticky-header ipx-page-title h2 span[ng-if='pageSubtitle']")).Last().Text;
        }

        public NgWebElement LevelUpIcon()
        {
            return Driver.FindElement(By.CssSelector("ipx-sticky-header ipx-page-title h2 a"));
        }

        public void CollapseAll()
        {
            Driver.FindElement(By.CssSelector("button[ng-click='vm.collapseAll()']")).TryClick();
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
            public NgWebElement CriteriaIdLink => _element.FindElement(By.CssSelector(".k-in a"));
            public string CriteriaName => _element.FindElement(By.CssSelector(".k-in .criteria-name")).Text;
            public bool IsVisible => _element.WithJs().IsVisible();
            public bool IsInSearch => _element.FindElement(By.XPath("./div")).FindElements(By.CssSelector(".k-in > .isInSearch")).Any();
            public bool IsParent => _element.FindElements(By.CssSelector(".k-group")).Any();
            public bool IsProtected => _element.FindElement(By.CssSelector("span.k-in")).FindElements(By.CssSelector("span[name='protected']")).Any();
        }
        public TreeNode[] GetAllTreeNodes()
        {
            return Driver.FindElements(By.CssSelector(".k-treeview .k-item")).Select(x => new TreeNode(x)).ToArray();
        }
    }
}
