using System;
using System.Collections.Generic;
using System.Data;
using Inprotech.Contracts;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Accounting.Billing.BillReview;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.BillReview
{
    public class EmailSubjectBodyResolverFacts
    {
        public class ResolveForCaseFacts
        {
            [Fact]
            public void ShouldResolveForCaseUsingCaseReference()
            {
                var caseRef = Fixture.String();

                var fixture = new EmailSubjectBodyResolverFixture()
                    .WithCaseSubjectDocItemResult("subject")
                    .WithCaseBodyDocItemResult("body")
                    .WithSiteControls();

                var r = fixture.Subject.ResolveForCase(caseRef);
                
                Assert.Equal("subject", r.Subject);
                Assert.Equal("body", r.Body);

                fixture.DocItemRunner.Received(1)
                       .Run(fixture.CaseSubjectDataItem, Arg.Is<Dictionary<string, object>>(_ => (string) _["gstrEntryPoint"] == caseRef));

                fixture.DocItemRunner.Received(1)
                       .Run(fixture.CaseBodyDataItem, Arg.Is<Dictionary<string, object>>(_ => (string) _["gstrEntryPoint"] == caseRef));
            }

            [Fact]
            public void ShouldReturnEmptyIfSubjectDataItemNotDefined()
            {
                var caseRef = Fixture.String();

                var fixture = new EmailSubjectBodyResolverFixture
                    {
                        CaseSubjectDataItem = null
                    }.WithCaseBodyDocItemResult("body")
                     .WithSiteControls();
                
                var r = fixture.Subject.ResolveForCase(caseRef);
                
                Assert.Equal(string.Empty, r.Subject);
                Assert.Equal("body", r.Body);

                fixture.DocItemRunner.DidNotReceive()
                       .Run(Arg.Is<string>(_ => _ != fixture.CaseBodyDataItem), Arg.Any<Dictionary<string, object>>());

                fixture.DocItemRunner.Received(1)
                       .Run(fixture.CaseBodyDataItem, Arg.Is<Dictionary<string, object>>(_ => (string) _["gstrEntryPoint"] == caseRef));
            }

            [Fact]
            public void ShouldReturnEmptyIfBodyDataItemNotDefined()
            {
                var caseRef = Fixture.String();

                var fixture = new EmailSubjectBodyResolverFixture
                    {
                        CaseBodyDataItem = null
                    }.WithCaseSubjectDocItemResult("subject")
                     .WithSiteControls();
                
                var r = fixture.Subject.ResolveForCase(caseRef);
                
                Assert.Equal("subject", r.Subject);
                Assert.Equal(string.Empty, r.Body);

                fixture.DocItemRunner.DidNotReceive()
                       .Run(Arg.Is<string>(_ => _ != fixture.CaseSubjectDataItem), Arg.Any<Dictionary<string, object>>());

                fixture.DocItemRunner.Received(1)
                       .Run(fixture.CaseSubjectDataItem, Arg.Is<Dictionary<string, object>>(_ => (string) _["gstrEntryPoint"] == caseRef));
            }
            
            [Fact]
            public void ShouldReturnEmptyIfSubjectDataItemExecutionResultedInError()
            {
                var caseRef = Fixture.String();

                var fixture = new EmailSubjectBodyResolverFixture()
                              .WithCaseSubjectDocItemResult("bummer!", true)
                              .WithCaseBodyDocItemResult("body")
                              .WithSiteControls();

                var r = fixture.Subject.ResolveForCase(caseRef);

                Assert.Equal(string.Empty, r.Subject);
                Assert.Equal("body", r.Body);

                fixture.Logger.Received(1).Warning(Arg.Is<string>(_ => _.Contains("bummer!")));
            }

            [Fact]
            public void ShouldReturnEmptyIfBodyDataItemExecutionResultedInError()
            {
                var caseRef = Fixture.String();

                var fixture = new EmailSubjectBodyResolverFixture()
                              .WithCaseBodyDocItemResult("bummer!", true)
                              .WithCaseSubjectDocItemResult("subject")
                              .WithSiteControls();

                var r = fixture.Subject.ResolveForCase(caseRef);

                Assert.Equal("subject", r.Subject);
                Assert.Equal(string.Empty, r.Body);

                fixture.Logger.Received(1).Warning(Arg.Is<string>(_ => _.Contains("bummer!")));
            }
        }

        public class ResolveForNameFacts
        {
            [Fact]
            public void ShouldResolveForNameUsingNameId()
            {
                var nameId = Fixture.Integer();

                var fixture = new EmailSubjectBodyResolverFixture()
                    .WithNameSubjectDocItemResult("subject")
                    .WithNameBodyDocItemResult("body")
                    .WithSiteControls();

                var r = fixture.Subject.ResolveForName(nameId);
                
                Assert.Equal("subject", r.Subject);
                Assert.Equal("body", r.Body);

                fixture.DocItemRunner.Received(1)
                       .Run(fixture.NameSubjectDataItem, Arg.Is<Dictionary<string, object>>(_ => (int) _["gstrEntryPoint"] == nameId));

                fixture.DocItemRunner.Received(1)
                       .Run(fixture.NameBodyDataItem, Arg.Is<Dictionary<string, object>>(_ => (int) _["gstrEntryPoint"] == nameId));
            }

            [Fact]
            public void ShouldReturnEmptyIfSubjectDataItemNotDefined()
            {
                var nameId = Fixture.Integer();

                var fixture = new EmailSubjectBodyResolverFixture
                    {
                        NameSubjectDataItem = null
                    }.WithNameBodyDocItemResult("body")
                     .WithSiteControls();
                
                var r = fixture.Subject.ResolveForName(nameId);
                
                Assert.Equal(string.Empty, r.Subject);
                Assert.Equal("body", r.Body);

                fixture.DocItemRunner.DidNotReceive()
                       .Run(Arg.Is<string>(_ => _ != fixture.NameBodyDataItem), Arg.Any<Dictionary<string, object>>());

                fixture.DocItemRunner.Received(1)
                       .Run(fixture.NameBodyDataItem, Arg.Is<Dictionary<string, object>>(_ => (int) _["gstrEntryPoint"] == nameId));
            }

            [Fact]
            public void ShouldReturnEmptyIfBodyDataItemNotDefined()
            {
                var nameId = Fixture.Integer();

                var fixture = new EmailSubjectBodyResolverFixture
                    {
                        NameBodyDataItem = null
                    }.WithNameSubjectDocItemResult("subject")
                     .WithSiteControls();
                
                var r = fixture.Subject.ResolveForName(nameId);
                
                Assert.Equal("subject", r.Subject);
                Assert.Equal(string.Empty, r.Body);

                fixture.DocItemRunner.DidNotReceive()
                       .Run(Arg.Is<string>(_ => _ != fixture.NameSubjectDataItem), Arg.Any<Dictionary<string, object>>());

                fixture.DocItemRunner.Received(1)
                       .Run(fixture.NameSubjectDataItem, Arg.Is<Dictionary<string, object>>(_ => (int) _["gstrEntryPoint"] == nameId));
            }
            
            [Fact]
            public void ShouldReturnEmptyIfSubjectDataItemExecutionResultedInError()
            {
                var nameId = Fixture.Integer();

                var fixture = new EmailSubjectBodyResolverFixture()
                              .WithNameSubjectDocItemResult("bummer!", true)
                              .WithNameBodyDocItemResult("body")
                              .WithSiteControls();

                var r = fixture.Subject.ResolveForName(nameId);

                Assert.Equal(string.Empty, r.Subject);
                Assert.Equal("body", r.Body);

                fixture.Logger.Received(1).Warning(Arg.Is<string>(_ => _.Contains("bummer!")));
            }

            [Fact]
            public void ShouldReturnEmptyIfBodyDataItemExecutionResultedInError()
            {
                var nameId = Fixture.Integer();

                var fixture = new EmailSubjectBodyResolverFixture()
                              .WithNameBodyDocItemResult("bummer!", true)
                              .WithNameSubjectDocItemResult("subject")
                              .WithSiteControls();

                var r = fixture.Subject.ResolveForName(nameId);

                Assert.Equal("subject", r.Subject);
                Assert.Equal(string.Empty, r.Body);

                fixture.Logger.Received(1).Warning(Arg.Is<string>(_ => _.Contains("bummer!")));
            }
        }

        public class EmailSubjectBodyResolverFixture : IFixture<EmailSubjectBodyResolver>
        {
            public string CaseSubjectDataItem { get; set; } = "CASE_SUBJECT";

            public string CaseBodyDataItem { get; set; } = "CASE_BODY";

            public string NameSubjectDataItem { get; set; } = "NAME_SUBJECT";

            public string NameBodyDataItem { get; set; } = "NAME_BODY";

            public ILogger<EmailSubjectBodyResolver> Logger { get; } = Substitute.For<ILogger<EmailSubjectBodyResolver>>();

            public IDocItemRunner DocItemRunner { get; } = Substitute.For<IDocItemRunner>();

            public ISiteControlReader SiteControlReader { get; } = Substitute.For<ISiteControlReader>();

            public EmailSubjectBodyResolver Subject { get; }

            public EmailSubjectBodyResolverFixture()
            {
                Subject = new EmailSubjectBodyResolver(Logger, SiteControlReader, DocItemRunner);
            }

            public EmailSubjectBodyResolverFixture WithCaseSubjectDocItemResult(string result, bool isError = false)
            {
                return isError
                    ? WithDocItemExecutionError(CaseSubjectDataItem, result)
                    : WithDocItemResult(CaseSubjectDataItem, result);
            }

            public EmailSubjectBodyResolverFixture WithCaseBodyDocItemResult(string result, bool isError = false)
            {
                return isError
                    ? WithDocItemExecutionError(CaseBodyDataItem, result)
                    : WithDocItemResult(CaseBodyDataItem, result);
            }

            public EmailSubjectBodyResolverFixture WithNameSubjectDocItemResult(string result, bool isError = false)
            {
                return isError
                    ? WithDocItemExecutionError(NameSubjectDataItem, result)
                    : WithDocItemResult(NameSubjectDataItem, result);
            }

            public EmailSubjectBodyResolverFixture WithNameBodyDocItemResult(string result, bool isError = false)
            {
                return isError
                    ? WithDocItemExecutionError(NameBodyDataItem, result)
                    : WithDocItemResult(NameBodyDataItem, result);
            }

            public EmailSubjectBodyResolverFixture WithSiteControls()
            {
                SiteControlReader.ReadMany<string>(SiteControls.EmailCaseSubject,
                                                   SiteControls.EmailCaseBody,
                                                   SiteControls.EmailNameSubject,
                                                   SiteControls.EmailNameBody)
                                 .Returns(new Dictionary<string, string>
                                 {
                                     { SiteControls.EmailCaseSubject, CaseSubjectDataItem },
                                     { SiteControls.EmailCaseBody, CaseBodyDataItem },
                                     { SiteControls.EmailNameSubject, NameSubjectDataItem },
                                     { SiteControls.EmailNameBody, NameBodyDataItem }
                                 });

                return this;
            }

            EmailSubjectBodyResolverFixture WithDocItemResult(string docItem, string result)
            {
                DocItemRunner.Run(docItem, Arg.Any<Dictionary<string, object>>())
                             .Returns(CreateScalarValueDataSet(result));

                return this;
            }

            EmailSubjectBodyResolverFixture WithDocItemExecutionError(string docItem, string errorMessage)
            {
                DocItemRunner.When(_ => _.Run(docItem, Arg.Any<Dictionary<string, object>>()))
                                         
                             .Do(_ => throw new Exception(errorMessage));

                return this;
            }

            static DataSet CreateScalarValueDataSet(string value)
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
}