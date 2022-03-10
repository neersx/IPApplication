using System;
using System.Linq;
using System.Threading;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class DetailPage : PageObject
    {
        PageNav _pageNav;
        AngularPageNav _angularPageNav;

        public DetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement TitleHeader => Driver.FindElement(By.CssSelector("main-content ip-sticky-header div.row.title-header"));

        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector("[uib-modal-window='modal-window']"));

        public PageNav PageNav => _pageNav ?? (_pageNav = new PageNav(Driver));
        public AngularPageNav AngularPageNav => _angularPageNav ?? (_angularPageNav = new AngularPageNav(Driver));

        public NgWebElement SaveButton => Driver.FindElements(By.CssSelector(".btn-save")).Last();

        public bool IsSaveDisplayed => Driver.FindElements(By.CssSelector(".btn-save")).Any();

        public NgWebElement DeleteButton => Driver.FindElement(By.CssSelector(".btn[button-icon='trash-o']"));

        public NgWebElement RevertButton => Driver.FindElement(By.CssSelector(".cpa-icon-revert")).GetParent();

        public NgWebElement DiscardButton => Driver.FindElement(By.CssSelector(".btn-discard"));
        public NgWebElement RecoverableCasesAlert => Driver.FindElement(By.CssSelector("ip-schedule-recoverable-cases-alert"));
        public NgWebElement RecoverableDocumentsCountLink => Driver.FindElement(By.CssSelector("#recoverableDocumentsCount"));
        public NgWebElement RecoverableCasesCountLink => Driver.FindElement(By.CssSelector("#recoverableCasesCount"));
        
        public RecoverableCasesModal RecoverableCases => new RecoverableCasesModal(Driver);
        public RecoverableDocumentsModal RecoverableDocuments => new RecoverableDocumentsModal(Driver);
        
        public class RecoverableCasesModal : ModalBase
        {
            const string Id = "RecoverableCases";

            public RecoverableCasesModal(NgWebDriver driver) : base(driver, Id)
            {
            }

            public void Close()
            {
                Modal.FindElement(By.ClassName("btn-discard")).TryClick();
            }
        }
        public class RecoverableDocumentsModal : ModalBase
        {
            const string Id = "RecoverableDocuments";

            public RecoverableDocumentsModal(NgWebDriver driver) : base(driver, Id)
            {

            }

            public void Close()
            {
                Modal.FindElement(By.ClassName("btn-discard")).TryClick();
            }
        }
        public NgWebElement LevelUpButton => Driver.FindElements(By.CssSelector("span[class*='cpa-icon-arrow-circle-nw'")).Last();

        public bool IsSaveDisabled()
        {
            try
            {
                Driver.Wait().ForTrue(() => !SaveButton.Enabled, sleepInterval: 12000);
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        public void Save()
        {
            ClickButtonHighestZIndex(".btn-save");
        }

        public void Discard()
        {
            ClickButtonHighestZIndex(".btn-discard");
        }

        void ClickButtonHighestZIndex(string cssSelector)
        {
            // with nested picklists there may be several Save buttons in the dome, only one of them clickable
            foreach (var btn in Driver.FindElements(By.CssSelector(cssSelector)))
            {
                try
                {
                    btn.TryClick();
                    break;
                }
                catch
                {
                }
            }
        }

        public void Delete()
        {
            DeleteButton.TryClick();
        }
    }

    public class Topic : PageObject
    {
        readonly string _topicKey;

        string _topicContainerSelector;

        public Topic(NgWebDriver driver, string topicKey) : base(driver)
        {
            _topicKey = topicKey;
        }

        public NgWebElement TopicContainer => Driver.FindElement(By.CssSelector(TopicContainerSelector));

        public string TopicContainerSelector
        {
            get
            {
                if (string.IsNullOrWhiteSpace(_topicContainerSelector))
                {
                    _topicContainerSelector = _topicKey.EndsWith("_")
                        ? "[data-topic-key^=" + _topicKey + "]"
                        : "[data-topic-key=" + _topicKey + "]";
                }

                return _topicContainerSelector;
            }
            set => _topicContainerSelector = value;
        }

        public void Add()
        {
            TopicContainer.FindElement(By.CssSelector(".cpa-icon-plus-circle")).ClickWithTimeout();
        }

        public NgWebElement AddButton()
        {
            return TopicContainer.FindElement(By.CssSelector(".cpa-icon-plus-circle"));
        }

        public bool IsActive()
        {
            return TopicContainer.WithJs().HasClass("active");
        }

        public void NavigateTo()
        {
            Driver.FindElement(By.CssSelector(".topic-menu [data-topic-ref=" + _topicKey + "]")).TryClick();
            Thread.Sleep(500);
        }

        public bool Displayed()
        {
            var isElementPresent = Driver.FindElements(By.CssSelector(TopicContainerSelector)).Count == 1;
            return isElementPresent && TopicContainer.Displayed;
        }

        public int? NumberOfRecords()
        {
            var elements = Driver.FindElements(By.CssSelector(TopicContainerSelector + " #topicDataCount"));
            return !elements.Any() ? null : (int?)Convert.ToInt32(elements.First().WithJs().GetInnerText());
        }

        public int? NumberOfRecordsInSection()
        {
            var elements = Driver.FindElements(By.CssSelector(".topic-menu [data-topic-ref=" + _topicKey + "]" + " #topicDataCount"));
            return !elements.Any() ? null : (int?)Convert.ToInt32(elements.First().WithJs().GetInnerText());
        }
    }

    public class PageAction : PageObject
    {
        readonly string _actionKey;

        public PageAction(NgWebDriver driver, string actionKey) : base(driver)
        {
            _actionKey = actionKey;
        }

        public NgWebElement Action => Driver.FindElement(By.CssSelector(ActionSelector));

        public string ActionSelector => "[data-action-key=" + _actionKey + "]";

        public void Click()
        {
            Action.ClickWithTimeout();
        }
    }

    public class PageNav : PageObject
    {
        public PageNav(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement NavControl => Driver.FindElements(By.CssSelector("ip-detail-page-nav")).Last();

        public void NextPage()
        {
            NavControl.FindElement(By.ClassName("cpa-icon-chevron-circle-right")).ClickWithTimeout();
        }

        public void PrePage()
        {
            NavControl.FindElement(By.ClassName("cpa-icon-chevron-circle-left")).ClickWithTimeout();
        }

        public void FirstPage()
        {
            NavControl.FindElement(By.ClassName("cpa-icon-angle-double-left")).ClickWithTimeout();
        }

        public void LastPage()
        {
            NavControl.FindElement(By.ClassName("cpa-icon-angle-double-right")).ClickWithTimeout();
        }
        public string Current()
        {
            return NavControl.FindElement(By.CssSelector("span[name='current']"))?.Text;
        }
        public string Total()
        {
            return NavControl.FindElement(By.CssSelector("span[name='total']"))?.Text;
        }
    }

    public class AngularPageNav : PageObject
    {
        public AngularPageNav(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement NavControl => Driver.FindElements(By.CssSelector("ipx-detail-page-nav")).Last();

        public void NextPage()
        {
            NavControl.FindElement(By.ClassName("cpa-icon-chevron-circle-right")).ClickWithTimeout();
        }

        public void PrePage()
        {
            NavControl.FindElement(By.ClassName("cpa-icon-chevron-circle-left")).ClickWithTimeout();
        }

        public void FirstPage()
        {
            NavControl.FindElement(By.ClassName("cpa-icon-angle-double-left")).ClickWithTimeout();
        }

        public void LastPage()
        {
            NavControl.FindElement(By.ClassName("cpa-icon-angle-double-right")).ClickWithTimeout();
        }
        public string Current()
        {
            return NavControl.FindElement(By.CssSelector("span[name='current']"))?.Text;
        }
        public string Total()
        {
            return NavControl.FindElement(By.CssSelector("span[name='total']"))?.Text;
        }
    }
}