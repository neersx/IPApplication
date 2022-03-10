using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class TreeView : PageObject
    {
        public TreeView(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public List<TreeNode> Folders => Driver.FindElements(By.CssSelector("kendo-treeview > ul > li.k-item.k-treeview-item")).Select(x => new TreeNode(x)).ToList();

        public class TreeNode
        {
            readonly NgWebElement _element;

            public TreeNode(NgWebElement element)
            {
                _element = element;
            }

            public string Name => _element.FindElement(By.CssSelector("div > span.k-in")).Text;
            public bool IsParent => _element.FindElements(By.CssSelector("div > span.ng-star-inserted")).Any();
            public string FolderIcon => _element.FindElement(By.CssSelector("ipx-icon span")).GetAttribute("class");
            public bool IsSelected => _element.FindElements(By.CssSelector("div > span.k-state-selected")).Any();
            public List<TreeNode> Children => _element.FindElements(By.CssSelector("ul li.k-item.k-treeview-item")).Select(x => new TreeNode(x)).ToList();

            public void Expand()
            {
                _element.FindElement(By.CssSelector("div > span.ng-star-inserted")).ClickWithTimeout();
            }

            public void Click()
            {
                _element.FindElement(By.CssSelector("span.k-in")).ClickWithTimeout();
            }
        }
    }
}