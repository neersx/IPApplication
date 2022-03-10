using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class ExternalPatentInfoLinkResolverFacts
    {
        public class ResolveForRelatedCase : FactBase
        {
            readonly IDocItemRunner _docItemRunner = Substitute.For<IDocItemRunner>();
            readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();
            readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

            readonly string _countryCode = Fixture.String();
            readonly string _number = Fixture.String();
            readonly string _caseRef = Fixture.String();

            IExternalPatentInfoLinkResolver CreateSubject(bool isExternalUser = false, bool hasPermission = true, string uri = "https://innography.com")
            {
                var dataSet = new DataSet();
                var dataTable = new DataTable();
                dataTable.Columns.Add(new DataColumn());
                dataTable.Rows.Add(uri);
                dataSet.Tables.Add(dataTable);

                _securityContext.User.Returns(new User(Fixture.String(), isExternalUser));
                _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewExternalPatentInformation).Returns(hasPermission);
                _docItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>())
                              .Returns(dataSet);

                return new ExternalPatentInfoLinkResolver(Db, _securityContext, _docItemRunner, _taskSecurityProvider);
            }

            [Theory]
            [InlineData(null)]
            [InlineData("")]
            [InlineData("rubbish")]
            public void ShouldReturnFalseIfDocItemNotFoundOrReturnedEmptyOrInvalid(string returnedUri)
            {
                var docItemName = Fixture.String();

                new SiteControl
                {
                    ControlId = SiteControls.LinkFromRelatedOfficialNumber,
                    StringValue = docItemName
                }.In(Db);

                new DocItem
                {
                    Name = docItemName
                }.In(Db);

                var subject = CreateSubject(uri: returnedUri);

                Assert.False(subject.Resolve(_caseRef, _countryCode, _number, out _));
            }

            [Fact]
            public void ShouldReturnFalseIfCountryCodeNotPassedIn()
            {
                var subject = CreateSubject(hasPermission: false);

                Assert.False(subject.Resolve(_caseRef, null, _number, out _));
            }

            [Fact]
            public void ShouldReturnFalseIfItWasExternalUser()
            {
                var subject = CreateSubject(true);

                Assert.False(subject.Resolve(_caseRef, _countryCode, _number, out _));
            }

            [Fact]
            public void ShouldReturnFalseIfNumberNotPassedIn()
            {
                var subject = CreateSubject(hasPermission: false);

                Assert.False(subject.Resolve(_caseRef, _countryCode, null, out _));
            }

            [Fact]
            public void ShouldReturnFalseIfUnableToResolveDocItem()
            {
                var docItemName = Fixture.String();

                new SiteControl
                {
                    ControlId = SiteControls.LinkFromRelatedOfficialNumber,
                    StringValue = docItemName
                }.In(Db);

                new DocItem
                {
                    Name = docItemName + Fixture.String() /* other doc item */
                }.In(Db);

                var subject = CreateSubject();

                Assert.False(subject.Resolve(_caseRef, _countryCode, _number, out _));
            }

            [Fact]
            public void ShouldReturnFalseIfUnableToResolveSiteControlForDocItem()
            {
                new SiteControl
                {
                    ControlId = SiteControls.LinkFromRelatedOfficialNumber,
                    StringValue = null
                }.In(Db);

                var subject = CreateSubject();

                Assert.False(subject.Resolve(_caseRef, _countryCode, _number, out _));
            }

            [Fact]
            public void ShouldReturnFalseIfUserDidNotHavePermission()
            {
                var subject = CreateSubject(hasPermission: false);

                Assert.False(subject.Resolve(_caseRef, _countryCode, _number, out _));
            }

            [Fact]
            public void ShouldReturnTrueIfDocItemReturnedValidUri()
            {
                var docItemName = Fixture.String();

                new SiteControl
                {
                    ControlId = SiteControls.LinkFromRelatedOfficialNumber,
                    StringValue = docItemName
                }.In(Db);

                new DocItem
                {
                    Name = docItemName
                }.In(Db);
                var subject = CreateSubject();

                Assert.True(subject.Resolve(_caseRef, _countryCode, _number, out var externalLink));
                Assert.Equal("https://innography.com/", externalLink.ToString());
            }

            [Fact]
            public void ShouldThrowIfCaseRefIsNull()
            {
                Assert.Throws<ArgumentNullException>(() => CreateSubject().Resolve(null, _countryCode, _number, out _));
            }
        }

        public class ResolveForNumberTypeLinkedDataItem : FactBase
        {
            readonly IDocItemRunner _docItemRunner = Substitute.For<IDocItemRunner>();
            readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();
            readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

            IExternalPatentInfoLinkResolver CreateSubject(bool isExternalUser = false, bool hasPermission = true, string uri = "https://innography.com")
            {
                var dataSet = new DataSet();
                var dataTable = new DataTable();
                dataTable.Columns.Add(new DataColumn());
                dataTable.Rows.Add(uri);
                dataSet.Tables.Add(dataTable);

                _securityContext.User.Returns(new User(Fixture.String(), isExternalUser));
                _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewExternalPatentInformation).Returns(hasPermission);
                _docItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>())
                              .Returns(dataSet);

                return new ExternalPatentInfoLinkResolver(Db, _securityContext, _docItemRunner, _taskSecurityProvider);
            }

            [Theory]
            [InlineData(null)]
            [InlineData("")]
            [InlineData("rubbish")]
            public void ShouldReturnFalseIfDocItemNotFoundOrReturnedEmptyOrInvalid(string returnedUri)
            {
                var subject = CreateSubject(uri: returnedUri);

                Assert.False(subject.Resolve(Fixture.String(), Fixture.Integer(), out _));
            }

            [Fact]
            public void ShouldReturnFalseIfItWasExternalUser()
            {
                var subject = CreateSubject(true);

                Assert.False(subject.Resolve(Fixture.String(), Fixture.Integer(), out _));
            }

            [Fact]
            public void ShouldReturnFalseIfUserDidNotHavePermission()
            {
                var subject = CreateSubject(hasPermission: false);

                Assert.False(subject.Resolve(Fixture.String(), Fixture.Integer(), out _));
            }

            [Fact]
            public void ShouldReturnTrueIfDocItemReturnedValidUri()
            {
                var subject = CreateSubject();

                Assert.True(subject.Resolve(Fixture.String(), Fixture.Integer(), out var externalLink));
                Assert.Equal("https://innography.com/", externalLink.ToString());
            }

            [Fact]
            public void ShouldThrowIfCaseRefIsNull()
            {
                Assert.Throws<ArgumentNullException>(() => CreateSubject().Resolve(null, Fixture.Integer(), out _));
            }
        }

        public class ResolveOfficialNumbers : FactBase
        {
            readonly IDocItemRunner _docItemRunner = Substitute.For<IDocItemRunner>();
            readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();
            readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

            IExternalPatentInfoLinkResolver CreateSubject(bool isExternalUser = false, bool hasPermission = true, string uri = "https://innography.com")
            {
                var dataSet = new DataSet();
                var dataTable = new DataTable();
                dataTable.Columns.Add(new DataColumn());
                dataTable.Rows.Add(uri);
                dataSet.Tables.Add(dataTable);

                _securityContext.User.Returns(new User(Fixture.String(), isExternalUser));
                _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewExternalPatentInformation).Returns(hasPermission);
                _docItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>())
                              .Returns(dataSet);

                return new ExternalPatentInfoLinkResolver(Db, _securityContext, _docItemRunner, _taskSecurityProvider);
            }

            [Theory]
            [InlineData(null)]
            [InlineData("")]
            [InlineData("rubbish")]
            public void ShouldReturnEmptyIfDocItemNotFoundOrReturnedEmptyOrInvalid(string returnedUri)
            {
                var subject = CreateSubject(uri: returnedUri);

                Assert.False(subject.ResolveOfficialNumbers(Fixture.String(), new[] {Fixture.Integer()}).Any());
            }

            [Fact]
            public void ShouldHandleDuplicatesInDocItemNumbers()
            {
                var subject = CreateSubject();

                var docItem = Fixture.Integer();
                var r = subject.ResolveOfficialNumbers(Fixture.String(), new[] {docItem, docItem});
                Assert.Single(r);
                Assert.Equal("https://innography.com/", r.First().Value.ToString());
            }

            [Fact]
            public void ShouldReturnDataIfDocItemReturnedValidUri()
            {
                var subject = CreateSubject();

                var r = subject.ResolveOfficialNumbers(Fixture.String(), new[] {Fixture.Integer()});
                Assert.Single(r);
                Assert.Equal("https://innography.com/", r.First().Value.ToString());
            }

            [Fact]
            public void ShouldReturnEmptyIfItWasExternalUser()
            {
                var subject = CreateSubject(true);

                Assert.False(subject.ResolveOfficialNumbers(Fixture.String(), new[] {Fixture.Integer()}).Any());
            }

            [Fact]
            public void ShouldReturnEmptyIfUserDidNotHavePermission()
            {
                var subject = CreateSubject(hasPermission: false);

                Assert.False(subject.ResolveOfficialNumbers(Fixture.String(), new[] {Fixture.Integer()}).Any());
            }

            [Fact]
            public void ShouldThrowIfCaseRefIsNull()
            {
                Assert.Throws<ArgumentNullException>(() => CreateSubject().ResolveOfficialNumbers(null, new[] {Fixture.Integer()}));
            }
        }

        public class ResolveRelatedCases : FactBase
        {
            readonly IDocItemRunner _docItemRunner = Substitute.For<IDocItemRunner>();
            readonly ISecurityContext _securityContext = Substitute.For<ISecurityContext>();
            readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

            readonly string _countryCode = Fixture.String();
            readonly string _number = Fixture.String();
            readonly string _caseRef = Fixture.String();

            IExternalPatentInfoLinkResolver CreateSubject(bool isExternalUser = false, bool hasPermission = true, string uri = "https://innography.com")
            {
                var dataSet = new DataSet();
                var dataTable = new DataTable();
                dataTable.Columns.Add(new DataColumn());
                dataTable.Rows.Add(uri);
                dataSet.Tables.Add(dataTable);

                _securityContext.User.Returns(new User(Fixture.String(), isExternalUser));
                _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewExternalPatentInformation).Returns(hasPermission);
                _docItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>())
                              .Returns(dataSet);

                return new ExternalPatentInfoLinkResolver(Db, _securityContext, _docItemRunner, _taskSecurityProvider);
            }

            [Theory]
            [InlineData(null)]
            [InlineData("")]
            [InlineData("rubbish")]
            public void ShouldReturnEmptyIfDocItemNotFoundOrReturnedEmptyOrInvalid(string returnedUri)
            {
                var docItemName = Fixture.String();

                new SiteControl
                {
                    ControlId = SiteControls.LinkFromRelatedOfficialNumber,
                    StringValue = docItemName
                }.In(Db);

                new DocItem
                {
                    Name = docItemName
                }.In(Db);

                var subject = CreateSubject(uri: returnedUri);

                var r = subject.ResolveRelatedCases(_caseRef, new[] {(_countryCode, _number)});
                Assert.Empty(r);
            }

            [Fact]
            public void ShouldHandleDuplicates()
            {
                var docItemName = Fixture.String();

                new SiteControl
                {
                    ControlId = SiteControls.LinkFromRelatedOfficialNumber,
                    StringValue = docItemName
                }.In(Db);

                new DocItem
                {
                    Name = docItemName
                }.In(Db);
                var subject = CreateSubject();

                var r = subject.ResolveRelatedCases(_caseRef, new[] {(_countryCode, _number), (_countryCode, _number)});
                Assert.NotEmpty(r);
                Assert.Equal("https://innography.com/", r.First().Value.ToString());
                Assert.Single(r);
            }

            [Fact]
            public void ShouldReturnDataIfDocItemReturnedValidUri()
            {
                var docItemName = Fixture.String();

                new SiteControl
                {
                    ControlId = SiteControls.LinkFromRelatedOfficialNumber,
                    StringValue = docItemName
                }.In(Db);

                new DocItem
                {
                    Name = docItemName
                }.In(Db);
                var subject = CreateSubject();

                var r = subject.ResolveRelatedCases(_caseRef, new[] {(_countryCode, _number)});
                Assert.NotEmpty(r);
                Assert.Equal("https://innography.com/", r.First().Value.ToString());
            }

            [Fact]
            public void ShouldReturnEmptyIfCountryCodeNotPassedIn()
            {
                var subject = CreateSubject();

                var r = subject.ResolveRelatedCases(_caseRef, new[] {(null as string, _number)});
                Assert.Empty(r);
            }

            [Fact]
            public void ShouldReturnEmptyIfItWasExternalUser()
            {
                var subject = CreateSubject(true);

                var r = subject.ResolveRelatedCases(_caseRef, new[] {(_countryCode, _number)});
                Assert.Empty(r);
            }

            [Fact]
            public void ShouldReturnEmptyIfNumberNotPassedIn()
            {
                var subject = CreateSubject();

                var r = subject.ResolveRelatedCases(_caseRef, new[] {(_countryCode, null as string)});
                Assert.Empty(r);
            }

            [Fact]
            public void ShouldReturnEmptyIfUnableToResolveDocItem()
            {
                var docItemName = Fixture.String();

                new SiteControl
                {
                    ControlId = SiteControls.LinkFromRelatedOfficialNumber,
                    StringValue = docItemName
                }.In(Db);

                new DocItem
                {
                    Name = docItemName + Fixture.String() /* other doc item */
                }.In(Db);

                var subject = CreateSubject();

                var r = subject.ResolveRelatedCases(_caseRef, new[] {(_countryCode, _number)});
                Assert.Empty(r);
            }

            [Fact]
            public void ShouldReturnEmptyIfUnableToResolveSiteControlForDocItem()
            {
                new SiteControl
                {
                    ControlId = SiteControls.LinkFromRelatedOfficialNumber,
                    StringValue = null
                }.In(Db);

                var subject = CreateSubject();

                var r = subject.ResolveRelatedCases(_caseRef, new[] {(_countryCode, _number)});
                Assert.Empty(r);
            }

            [Fact]
            public void ShouldReturnEmptyIfUserDidNotHavePermission()
            {
                var subject = CreateSubject(hasPermission: false);

                var r = subject.ResolveRelatedCases(_caseRef, new[] {(_countryCode, _number)});
                Assert.Empty(r);
            }

            [Fact]
            public void ShouldThrowIfCaseRefIsNull()
            {
                Assert.Throws<ArgumentNullException>(() => CreateSubject().ResolveRelatedCases(null, new[] {(_countryCode, _number)}));
            }
        }
    }
}