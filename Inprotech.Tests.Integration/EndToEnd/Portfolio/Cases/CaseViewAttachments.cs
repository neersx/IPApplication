using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Security;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseViewAttachments : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CaseViewAttachmentModal(BrowserType browserType)
        {
            var data = new CaseDetailsActionsDbSetup().ActionsSetup();

            var rowSecurity = DbSetup.Do(x =>
            {
                var @case = x.DbContext.Set<Case>().Single(_ => _.Id == data.CaseId);

                var propertyType = @case.PropertyType;
                var caseType = @case.Type;

                var rowAccessDetail = new RowAccess("ra1", "row access one")
                {
                    Details = new List<RowAccessDetail>
                    {
                        new RowAccessDetail("ra1")
                        {
                            SequenceNo = 0,
                            Office = @case.Office,
                            AccessType = RowAccessType.Case,
                            CaseType = caseType,
                            PropertyType = propertyType,
                            AccessLevel = 15
                        },
                        new RowAccessDetail("ra1")
                        {
                            SequenceNo = 1,
                            Office = null,
                            AccessType = RowAccessType.Name,
                            AccessLevel = 15,
                            CaseType = caseType,
                            PropertyType = propertyType
                        }
                    }
                };

                var user = new Users(x.DbContext).WithRowLevelAccess(rowAccessDetail).Create();

                return new
                {
                    user,
                    rowAccessDetail
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{data.CaseId}", rowSecurity.user.Username, rowSecurity.user.Password);

            var attachments = new AttachmentListObj(driver);
            attachments.Open();
            driver.WaitForAngular();
            Assert.AreEqual(3, attachments.AttachmentsGrid.Rows.Count);
            Assert.AreEqual("attachment", attachments.AttachmentName(0));
            Assert.AreEqual("attachment2", attachments.AttachmentName(1));
            Assert.AreEqual("attachment3", attachments.AttachmentName(2));
            Assert.True(attachments.IsPriorArt(2));

            attachments.Close();

            var actionsTopic = new ActionTopic(driver);
            Assert.AreEqual(1, actionsTopic.AttachmentIcons.Count(), "One attachment icon is displayed");
            var icon = actionsTopic.AttachmentIcons.First();

            driver.Hover(icon);
            driver.WaitForAngular();
            Assert.NotNull(actionsTopic.AttachmentPopup);
            Assert.True(actionsTopic.AttachmentPopup.Text.Contains("Showing 1 of 1"));
            
            icon.Click();
            Assert.Null(actionsTopic.AttachmentPopup);

            attachments = new AttachmentListObj(driver);
            Assert.AreEqual(1, attachments.AttachmentsGrid.Rows.Count);
            Assert.AreEqual("attachment", attachments.AttachmentName(0));
        }
    }
}