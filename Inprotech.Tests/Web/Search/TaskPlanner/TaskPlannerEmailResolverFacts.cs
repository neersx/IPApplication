using System.Collections.Generic;
using System.Data;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases.Reminders;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner
{
    public class TaskPlannerEmailResolverFacts : FactBase
    {
        [Fact]
        public void VerifyResolveForSubject()
        {
            var fixture = new TaskPlannerEmailResolverFixture();
            var user = new User(Fixture.UniqueName(), false) { NameId = Fixture.Integer() };
            fixture.SecurityContext.User.Returns(user);
            var ds = new DataSet();
            ds.Tables.Add(new DataTable());
            ds.Tables[0].Columns.Add(new DataColumn("SUBJECT", typeof(string)));
            var dr = ds.Tables[0].NewRow();
            var subjectText = Fixture.String();
            dr["SUBJECT"] = subjectText;
            ds.Tables[0].Rows.Add(dr);
            fixture.DocItemRunner.Run("EMAIL_SUBJECT", Arg.Any<IDictionary<string, object>>()).Returns(ds);

            var subject = fixture.Subject.Resolve("A^12^46", "EMAIL_SUBJECT");

            Assert.Equal(subjectText, subject);
        }

        [Fact]
        public void VerifyResolveForBody()
        {
            var fixture = new TaskPlannerEmailResolverFixture();
            var user = new User(Fixture.UniqueName(), false) { NameId = Fixture.Integer() };
            fixture.SecurityContext.User.Returns(user);
            var ds = new DataSet();
            ds.Tables.Add(new DataTable());
            ds.Tables[0].Columns.Add(new DataColumn("BODY", typeof(string)));
            var dr = ds.Tables[0].NewRow();
            var bodyText = Fixture.String();
            dr["BODY"] = bodyText;
            ds.Tables[0].Rows.Add(dr);
            fixture.DocItemRunner.Run("EMAIL_BODY", Arg.Any<IDictionary<string, object>>()).Returns(ds);

            var subject = fixture.Subject.Resolve("A^12^46", "EMAIL_BODY");
            Assert.Equal(bodyText, subject);
        }
    }

    public class TaskPlannerEmailResolverFixture : IFixture<TaskPlannerEmailResolver>
    {
        public TaskPlannerEmailResolverFixture()
        {
            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            preferredCultureResolver.Resolve().Returns(Fixture.String());
            SecurityContext = Substitute.For<ISecurityContext>();
            DocItemRunner = Substitute.For<IDocItemRunner>();
            Subject = new TaskPlannerEmailResolver(SecurityContext, DocItemRunner, preferredCultureResolver);
        }

        public ISecurityContext SecurityContext { get; }
        public IDocItemRunner DocItemRunner { get; }
        public TaskPlannerEmailResolver Subject { get; }
    }
}