using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Newtonsoft.Json;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents
{
    public class Message
    {
        public string Type { get; set; }
    }

    internal class PostMessage
    {
        [JsonProperty("queryContextKey")]
        public int QueryContextKey { get; set; }

        [JsonProperty("queryKey", NullValueHandling = NullValueHandling.Ignore)]
        public int? QueryKey { get; set; }

        [JsonProperty("payload", NullValueHandling = NullValueHandling.Ignore)]
        public string Payload { get; set; }
    }

    public class LifeCycleMessage : Message
    {
        public string Action { get; set; }
        public string Target { get; set; }
        public dynamic Payload { get; set; }
    }

    public class NavigationMessage : Message
    {
        public string Action { get; set; }
        public string[] Args { get; set; }
    }

    internal class HostedTestPageObject : PageObject
    {
        public HostedTestPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularDropdown AttachmentBaseTypeDropdown => new AngularDropdown(Driver).ByName("attachmentBaseType");
        public AngularPicklist CasePicklist => new AngularPicklist(Driver).ByName("caseKey");
        public AngularPicklist NamePicklist => new AngularPicklist(Driver).ByName("nameKey");
        public AngularPicklist ProgramPicklist => new AngularPicklist(Driver).ByName("program");
        public AngularTextField ActivityId => new AngularTextField(Driver, "activityId");
        public AngularTextField SequenceNo => new AngularTextField(Driver, "sequenceNo");
        public ButtonInput CaseSubmitButton => new ButtonInput(Driver).ById("btnLoadCaseTopic");
        public ButtonInput NameSubmitButton => new ButtonInput(Driver).ById("btnLoadNameTopic");
        public ButtonInput AttachmentSubmitButton => new ButtonInput(Driver).ById("btnLoadAttachment");
        public AngularCheckbox IsWordCheckBox => new AngularCheckbox(Driver).ByName("isWord");
        public ButtonInput GenerateWordSubmitButton => new ButtonInput(Driver).ById("btnLoadGenerateDocument");
        public ButtonInput StartTimerButton => new ButtonInput(Driver).ById("btnStartTimer");
        public ButtonInput OnRequestDataResponseButton => new ButtonInput(Driver).ById("btnOnRequestDataResponseReceived");
        public AngularDropdown ComponentDropdown => new AngularDropdown(Driver).ByName("viewComponent");
        public SearchPageObject HostedSearchPage => new SearchPageObject(Driver);
        public CaseSearchPageObject HostedSearchResultsPage => new CaseSearchPageObject(Driver);
        public string FrameSource => Driver.FindElement(By.Id("searchResultHost")).GetAttribute("src");
        NgWebElement OnInitButton => Driver.FindElement(By.Id("btnOnInit"));
        public IpxTextField PostMessageTextField => new IpxTextField(Driver).ByName("postMessage");
        public IpxTextField NavigationMessagesTextField => new IpxTextField(Driver).ByName("receivedNavigationMessages");
        public IpxTextField LifeCycleMessagesTextField => new IpxTextField(Driver).ByName("receivedLifeCycleMessages");
        public IpxTextField EntityIdTextField => new IpxTextField(Driver).ByName("entityId");
        public IpxTextField TransKeyTextField => new IpxTextField(Driver).ByName("transKey");
        public IpxTextField WipSeqKeyTextField => new IpxTextField(Driver).ByName("wipSeqKey");
        public ButtonInput LoadWipAdjustment => new ButtonInput(Driver).ById("btnLoadWIPAdjustment");
        public ButtonInput LoadSplitWip => new ButtonInput(Driver).ById("btnLoadSplitWip");
        public NgWebElement MoreItemButton => Driver.FindElement(By.Id("tasksMenu"));

        public List<NavigationMessage> NavigationMessages
        {
            get
            {
                var messages = NavigationMessagesTextField.Text.Split(new[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);
                return messages.Select(JsonConvert.DeserializeObject<NavigationMessage>).ToList();
            }
        }

        public void ClearNavigationMessages()
        {
            NavigationMessagesTextField.Text = string.Empty;
        }

        public List<LifeCycleMessage> LifeCycleMessages
        {
            get
            {
                var messages = LifeCycleMessagesTextField.Text.Split(new[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);
                return messages.Select(JsonConvert.DeserializeObject<LifeCycleMessage>).ToList();
            }
        }

        public void CallOnInit(PostMessage message = null)
        {
            PostMessageTextField.Text = message != null ? JsonConvert.SerializeObject(message) : string.Empty;
            Driver.WaitForAngular();
            OnInitButton.Click();
            Driver.WaitForAngular();
        }

        public void CallOnRequestDataResponse<T>(DataReceivedMessage<T> message)
        {
            PostMessageTextField.Text = message != null ? JsonConvert.SerializeObject(message) : string.Empty;
            Driver.WaitForAngular();
            OnRequestDataResponseButton.Click();
            Driver.WaitForAngular();
        }

        public void WaitForLifeCycleAction(string action)
        {
            WaitForTrue(() => LifeCycleMessages.Any(x => x.Action == action));
        }

        public void WaitForNavigationAction(string action)
        {
            WaitForTrue(() => NavigationMessages.Any(x => string.Equals(action, x.Action)));
        }

        void WaitForTrue(Func<bool> condition, int msTimeout = 60000, int waitTime = 1000)
        {
            new WebDriverWait(new SystemClock(), Driver, TimeSpan.FromMilliseconds(msTimeout), TimeSpan.FromMilliseconds(waitTime))
                .Until(d => condition().Equals(true));
        }

        public class DataReceivedMessage<T>
        {
            public DataReceivedMessage(string key, T value)
            {
                Key = key;
                Value = value;
            }

            [JsonProperty("key", NullValueHandling = NullValueHandling.Ignore)]
            public string Key { get; set; }

            [JsonProperty("value", NullValueHandling = NullValueHandling.Ignore)]
            public T Value { get; set; }
        }

        public class SanityCheckPayload
        {
            public string DisplayMessage { get; set; }
        }
    }
}