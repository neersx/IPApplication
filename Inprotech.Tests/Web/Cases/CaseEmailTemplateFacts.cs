using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class CaseEmailTemplateFacts
    {
        public class ForCaseName : FactBase
        {
            [Fact]
            public async Task ShouldReturnForCaseName()
            {
                var f = new CaseEmailTemplateFixture(Db)
                        .WithEmailValidated()
                        .WithDocItemResult("EMAIL_CASE_CC_WEB", "abc@def.com; efg@def.com ; asd@gmail.com")
                        .WithDocItemResult("EMAIL_CASE_SUBJECT_WEB", "Regarding xkahdf")
                        .WithDocItemResult("EMAIL_CASE_BODY_WEB", "Regarding akljdlkdfs" + Environment.NewLine + "This is new title");

                var r = await f.Subject.ForCaseName(f.Parameters);

                Assert.Null(r.RecipientEmail);
                Assert.Equal(r.RecipientCopiesTo.ToArray(), new[] {"abc@def.com", "efg@def.com", "asd@gmail.com"});
                Assert.Equal("Regarding xkahdf", r.Subject);
                Assert.Equal("Regarding akljdlkdfs" + Environment.NewLine + "This is new title", r.Body);

                f.DocItemRunner.Received(1)
                 .Run("EMAIL_CASE_CC_WEB", Arg.Is<Dictionary<string, object>>(x => (string) x["gstrEntryPoint"] == f.CaseRef && (int) x["gstrUserId"] == f.UserId && (string) x["p1"] == f.NameType && (int) x["p2"] == f.Sequence));
                f.DocItemRunner.Received(1)
                 .Run("EMAIL_CASE_SUBJECT_WEB", Arg.Is<Dictionary<string, object>>(x => (string) x["gstrEntryPoint"] == f.CaseRef && (int) x["gstrUserId"] == f.UserId && (string) x["p1"] == f.NameType && (int) x["p2"] == f.Sequence));
                f.DocItemRunner.Received(1)
                 .Run("EMAIL_CASE_BODY_WEB", Arg.Is<Dictionary<string, object>>(x => (string) x["gstrEntryPoint"] == f.CaseRef && (int) x["gstrUserId"] == f.UserId && (string) x["p1"] == f.NameType && (int) x["p2"] == f.Sequence));
            }

            [Fact]
            public async Task ShouldNotReturnEmailsWhichCantBeValidated()
            {
                var f = new CaseEmailTemplateFixture(Db)
                        .WithEmailValidated(false)
                        .WithDocItemResult("EMAIL_CASE_CC_WEB", "abc@def.com; efg@def.com ; asd@gmail.com")
                        .WithDocItemResult("EMAIL_CASE_SUBJECT_WEB", "Regarding xkahdf")
                        .WithDocItemResult("EMAIL_CASE_BODY_WEB", "Regarding akljdlkdfs" + Environment.NewLine + "This is new title");

                var r = await f.Subject.ForCaseName(f.Parameters);

                Assert.Null(r.RecipientEmail);
                Assert.Equal(r.RecipientCopiesTo.ToArray(), new string[0]);
                Assert.Equal("Regarding xkahdf", r.Subject);
                Assert.Equal("Regarding akljdlkdfs" + Environment.NewLine + "This is new title", r.Body);
            }
        }

        public class ForCaseMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnForCase()
            {
                var f = new CaseEmailTemplateFixture(Db)
                        .WithEmailValidated()
                        .WithDocItemResult("EMAIL_CASE_TO_ADMIN", "helpdesk@cpaglobal.com")
                        .WithDocItemResult("EMAIL_CASE_SUBJECT_ADMIN", "Regarding xkahdf")
                        .WithDocItemResult("EMAIL_CASE_BODY_ADMIN", "Regarding akljdlkdfs" + Environment.NewLine + "This is new title");

                var r = await f.Subject.ForCase(f.CaseId);

                Assert.Equal("helpdesk@cpaglobal.com", r.RecipientEmail);
                Assert.Equal("Regarding xkahdf", r.Subject);
                Assert.Equal("Regarding akljdlkdfs" + Environment.NewLine + "This is new title", r.Body);

                f.DocItemRunner.Received(1)
                 .Run("EMAIL_CASE_TO_ADMIN", Arg.Is<Dictionary<string, object>>(x => (string) x["gstrEntryPoint"] == f.CaseRef && (int) x["gstrUserId"] == f.UserId));
                f.DocItemRunner.Received(1)
                 .Run("EMAIL_CASE_SUBJECT_ADMIN", Arg.Is<Dictionary<string, object>>(x => (string) x["gstrEntryPoint"] == f.CaseRef && (int) x["gstrUserId"] == f.UserId));
                f.DocItemRunner.Received(1)
                 .Run("EMAIL_CASE_BODY_ADMIN", Arg.Is<Dictionary<string, object>>(x => (string) x["gstrEntryPoint"] == f.CaseRef && (int) x["gstrUserId"] == f.UserId));
            }

            [Fact]
            public async Task ShouldNotReturnRecipientEmailWhichCantBeValidated()
            {
                var f = new CaseEmailTemplateFixture(Db)
                        .WithEmailValidated(false)
                        .WithDocItemResult("EMAIL_CASE_TO_ADMIN", "helpdesk@cpaglobal.com")
                        .WithDocItemResult("EMAIL_CASE_SUBJECT_ADMIN", "Regarding xkahdf")
                        .WithDocItemResult("EMAIL_CASE_BODY_ADMIN", "Regarding akljdlkdfs" + Environment.NewLine + "This is new title");

                var r = await f.Subject.ForCase(f.CaseId);

                Assert.Null(r.RecipientEmail);
                Assert.Equal("Regarding xkahdf", r.Subject);
                Assert.Equal("Regarding akljdlkdfs" + Environment.NewLine + "This is new title", r.Body);
            }
        }
    }

    public class CaseEmailTemplateFixture : IFixture<CaseEmailTemplate>
    {
        public CaseEmailTemplateFixture(InMemoryDbContext db)
        {
            CaseId = new CaseBuilder {Irn = CaseRef}.Build().In(db).Id;
            var user = new User(Fixture.String(), Fixture.Boolean());
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(user);
            UserId = user.Id;

            Parameters = new CaseNameEmailTemplateParameters {CaseKey = CaseId, NameType = NameType, Sequence = Sequence};
            DocItemRunner = Substitute.For<IDocItemRunner>();
            EmailValidator = Substitute.For<IEmailValidator>();

            Subject = new CaseEmailTemplate(db, securityContext, DocItemRunner, EmailValidator);
        }

        public string NameType { get; } = Fixture.String();

        public short Sequence { get; } = Fixture.Short();

        public string CaseRef { get; } = Fixture.String();

        public int CaseId { get; }

        public int UserId { get; }

        public CaseNameEmailTemplateParameters Parameters { get; }

        public IDocItemRunner DocItemRunner { get; }

        public IEmailValidator EmailValidator { get; }

        public CaseEmailTemplate Subject { get; }

        public CaseEmailTemplateFixture WithDocItemResult(string docItemName, string result)
        {
            var scalarValueDataSet = CreateScalarValueDataSet(result);
            DocItemRunner.Run(docItemName, Arg.Any<Dictionary<string, object>>()).Returns(scalarValueDataSet);
            return this;
        }

        public CaseEmailTemplateFixture WithEmailValidated(bool validated = true)
        {
            EmailValidator.IsValid(Arg.Any<string>()).Returns(validated);
            return this;
        }

        DataSet CreateScalarValueDataSet(string value)
        {
            var ds = new DataSet();
            var dt = new DataTable();
            dt.Columns.Add(new DataColumn());
            dt.Rows.Add(value);
            ds.Tables.Add(dt);
            return ds;
        }
    }
}