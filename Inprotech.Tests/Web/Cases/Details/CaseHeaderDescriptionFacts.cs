using System.Collections.Generic;
using System.Data;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseHeaderDescriptionFacts
    {
        public class ForMethod : FactBase
        {
            [Fact]
            public void ReturnsEmptyStringWhenNotConfigured()
            {
                var f = new CaseHeaderDescriptionFixture(Db);
                var r = f.Subject.For(Fixture.String());
                Assert.Equal(string.Empty, r);
            }

            [Fact]
            public void RunsMatchingDocItemFromSiteControl()
            {
                var setting = Fixture.String();
                var other = Fixture.String();
                var caseReference = Fixture.String();
                var docItemResult = Fixture.String();

                var result = new DataSet();
                result.Tables.Add(new DataTable());
                result.Tables[0].Columns.Add("Result");
                var row = result.Tables[0].NewRow();
                row["Result"] = docItemResult;
                result.Tables[0].Rows.Add(row);

                new SiteControl {ControlId = SiteControls.CaseHeaderDescription, StringValue = setting}.In(Db);
                new SiteControl {ControlId = SiteControls.CaseDefaultDescription, StringValue = other}.In(Db);
                var dataItem = new DocItem {Name = setting, EntryPointUsage = 1, Sql = "SELECT"}.In(Db);

                var f = new CaseHeaderDescriptionFixture(Db);
                f.DocItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>()).Returns(result);
                var output = f.Subject.For(caseReference);

                f.DocItemRunner.Received(1).Run(dataItem.Id, Arg.Is<Dictionary<string, object>>(x => (string) x["gstrEntryPoint"] == caseReference));
                Assert.Equal(docItemResult, output);
            }
        }

        public class CaseHeaderDescriptionFixture : IFixture<CaseHeaderDescription>
        {
            public CaseHeaderDescriptionFixture(InMemoryDbContext db)
            {
                DocItemRunner = Substitute.For<IDocItemRunner>();
                Subject = new CaseHeaderDescription(db, DocItemRunner);
            }

            public IDocItemRunner DocItemRunner { get; set; }
            public CaseHeaderDescription Subject { get; set; }
        }
    }
}