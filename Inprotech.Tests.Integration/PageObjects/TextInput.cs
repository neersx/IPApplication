using Inprotech.Tests.Integration.Utils;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class TextInput : Selectors<TextInput>
    {
        public TextInput(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public string Value => Element.WithJs().GetValue();

        public void Input(params string[] input)
        {
            foreach(var str in input)
            {
                Element.SendKeys(str);
            }
            Element.SendKeys(OpenQA.Selenium.Keys.Tab);
        }
        
        public void Clear()
        {
            Element.Clear();
        }

        public void Click()
        {
            Element.Click();
        }

        public bool HasClass(string className)
        {
            return Element.WithJs().HasClass(className);
        }
    }
}