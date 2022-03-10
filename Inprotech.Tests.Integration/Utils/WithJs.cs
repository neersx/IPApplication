using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Inprotech.Tests.Integration.Extensions;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.Utils
{
    internal class ElementWithJs
    {
        readonly NgWebElement _element;

        public ElementWithJs(NgWebElement element)
        {
            _element = element;
        }

        public void Focus()
        {
            _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<object>("arguments[0].focus();", _element);
        }

        public bool IsVisible()
        {
            return _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<bool>("return $(arguments[0]).is(':visible');", _element);
        }

        public bool IsChecked()
        {
            return _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<bool>("return $(arguments[0]).is(':checked');", _element);
        }

        public bool IsDisabled()
        {
            return _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<bool>("return $(arguments[0]).is(':disabled');", _element);
        }

        public void Click()
        {
            _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<object>("arguments[0].click();", _element);
            _element.CurrentDriver().WaitForAngularWithTimeout();
        }

        public bool HasClass(string className)
        {
            var cls = _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<string>("return arguments[0].className;", _element);
            return cls.Split(' ').Contains(className);
        }

        public string GetInnerText(bool trim = true)
        {
            var txt = _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<string>("return arguments[0].innerText;", _element);
            return trim ? txt?.Trim() : txt;
        }

        public string GetValue()
        {
            var txt = _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<string>("return arguments[0].value;", _element);
            return txt;
        }
        
        public int ScrollLeft()
        {
            return (int) _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<long>("return arguments[0].scrollLeft;", _element);
        }

        public int ScrollTop
        {
            get => (int) _element.CurrentDriver().ExecuteJavaScript<long>("return Math.ceil(arguments[0].scrollTop);", _element);
            set => _element.CurrentDriver().ExecuteJavaScript<object>("arguments[0].scrollTop=arguments[1];", _element, value);
        }
        public void ScrollLeft(int x)
        {
            _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<object>("arguments[0].scrollLeft = arguments[1];", _element, x);
        }

        public void ScrollIntoView()
        {
            _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<object>(@"
                arguments[0].scrollIntoView();
                if($('ip-sticky-header').length) { 
                    var scrollBy = $('#mainPane').get(0).scrollTop; 
                    $('#mainPane').scrollTop(scrollBy - $('ip-sticky-header').height());
                }", _element);
        }

        public T GetAttributeValue<T>(string attr)
        {
            return _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<T>($"return $(arguments[0]).attr('{attr}');", _element);
        }
        
        public NgWebElement GetParent()
        {
            if (_element.TagName == "html") return null;
            
            var r = _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<dynamic>("return arguments[0].parentNode || '~empty~';", _element);
            var rwe = r as IWebElement;
            return rwe != null
                ? new NgWebElement(_element.CurrentDriver(), rwe)
                : null;
        }
        public void Blur()
        {
            _element.CurrentDriver().WrappedDriver.ExecuteJavaScript<string>("arguments[0].blur();", _element);
        }
    }

    internal class DriverWithJs
    {
        readonly NgWebDriver _driver;

        public DriverWithJs(NgWebDriver driver)
        {
            _driver = driver;
        }

        public string GetUrl(bool handlesUnexpectedJavascriptError = false, bool withDelay = false)
        {
            try
            {
                if (withDelay) Thread.Sleep(500);
                return _driver.WrappedDriver.ExecuteJavaScript<string>("return window.location.href");
            }
            catch (WebDriverException wde) when (handlesUnexpectedJavascriptError && wde.Message.Contains("UnexpectedJavaScriptError"))
            {
                return null;
            }
        }

        public string Reload(bool handlesUnexpectedJavascriptError = false)
        {
            try
            {
                return _driver.WrappedDriver.ExecuteJavaScript<string>("window.location.reload();");
            }
            catch (WebDriverException wde) when (handlesUnexpectedJavascriptError && wde.Message.Contains("UnexpectedJavaScriptError"))
            {
                return null;
            }
        }

        public int GetYScroll()
        {
            return (int) _driver.WrappedDriver.ExecuteJavaScript<long>("return Math.ceil(window.pageYOffset);");
        }

        public int GetWindowHeight()
        {
            return (int) _driver.WrappedDriver.ExecuteJavaScript<long>("return window.innerHeight;");
        }

        public void ScrollBy(int x, int y)
        {
            _driver.WrappedDriver.ExecuteJavaScript<object>("window.scrollBy(arguments[0],arguments[1]);", x, y);
        }

        public void ScrollTo(int x, int y)
        {
            _driver.WrappedDriver.ExecuteJavaScript<object>("window.scrollTo(arguments[0],arguments[1]);", x, y);
        }

        public void ScrollToTop()
        {
            _driver.WrappedDriver.ExecuteJavaScript<object>("window.scrollTo(0,0);");
        }

        public void ReloadPage()
        {
            _driver.WrappedDriver.ExecuteJavaScript<object>("window.location.reload();");
        }

        public T ExecuteJavaScript<T>(string script)
        {
            return _driver.WrappedDriver.ExecuteJavaScript<T>(script);
        }
    }

    internal static class WithJsExt
    {
        public static ElementWithJs WithJs(this NgWebElement element)
        {
            return new ElementWithJs(element);
        }

        public static DriverWithJs WithJs(this NgWebDriver driver)
        {
            return new DriverWithJs(driver);
        }

        public static IEnumerable<ElementWithJs> WithJs(this IEnumerable<NgWebElement> elements)
        {
            return elements.Select(_ => _.WithJs());
        }
    }

    internal class PreserveScroll : IDisposable
    {
        readonly Dictionary<NgWebElement, int> _parents;

        public PreserveScroll(NgWebElement element)
        {
            _parents = new Dictionary<NgWebElement, int>();

            while (true)
            {
                var parent = element.GetParent();
                if (parent == null) break;
                
                var scroll = parent.WithJs().ScrollTop;
                
                if (scroll != 0) _parents.Add(parent, scroll);

                element = parent;
            }
        }

        public void Dispose()
        {
            foreach (var pair in _parents)
            {
                pair.Key.WithJs().ScrollTop = pair.Value;
            }
        }
    }
}