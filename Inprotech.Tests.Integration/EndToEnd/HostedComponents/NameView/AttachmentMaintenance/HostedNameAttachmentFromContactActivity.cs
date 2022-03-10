using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.NameView.AttachmentMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedNameAttachmentFromContactActivity : HostedNameAttachmentBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainAttachment(BrowserType browserType)
        {
            VerifyMaintenance(browserType, false);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteAttachment(BrowserType browserType)
        {
            VerifyDelete(browserType, false);
        }
    }
}