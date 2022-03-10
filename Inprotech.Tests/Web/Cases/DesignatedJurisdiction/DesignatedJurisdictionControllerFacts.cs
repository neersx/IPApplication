using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Cases.Details.DesignatedJurisdiction;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.DesignatedJurisdiction
{
    public class DesignatedJurisdictionControllerFacts
    {
        class DesignatedJurisdictionControllerFixture : IFixture<DesignatedJurisdictionController>
        {
            public DesignatedJurisdictionControllerFixture()
            {
                DesignatedJurisdictions = Substitute.For<IDesignatedJurisdictions>();
                CaseView = Substitute.For<ICaseView>();
                CriticalDates = Substitute.For<ICriticalDatesResolver>();
                CaseTextSection = Substitute.For<ICaseTextSection>();
                AuthSettings = Substitute.For<IAuthSettings>();
                FileInstructInterface = Substitute.For<IFileInstructInterface>();

                Subject = new DesignatedJurisdictionController(DesignatedJurisdictions, CaseView, CriticalDates, CaseTextSection, FileInstructInterface, AuthSettings);
            }

            public IDesignatedJurisdictions DesignatedJurisdictions { get; }

            public ICaseTextSection CaseTextSection { get; }

            public ICaseView CaseView { get; }

            public ICriticalDatesResolver CriticalDates { get; }

            public IAuthSettings AuthSettings { get; }

            public IFileInstructInterface FileInstructInterface { get; }

            public DesignatedJurisdictionController Subject { get; }

            public DesignatedJurisdictionControllerFixture WithJurisdictionData(params Action<DesignatedJurisdictionData>[] apply)
            {
                var data = new List<DesignatedJurisdictionData>();
                foreach (var action in apply)
                {
                    var j = new DesignatedJurisdictionData {CaseStatus = Fixture.String()};
                    action(j);
                    data.Add(j);
                }

                DesignatedJurisdictions.Get(Arg.Any<int>()).Returns(data.AsQueryable());
                return this;
            }

            public DesignatedJurisdictionControllerFixture WithCaseViewData()
            {
                CaseView.GetSummary(Arg.Any<int>()).Returns(new[] {new OverviewSummary()}.AsDbAsyncEnumerble().AsQueryable());
                CaseView.GetNames(Arg.Any<int>()).Returns(new[] {new NameSummary() }.AsQueryable());
                return this;
            }
        }

        public class GetFilterDataForColumnMethod
        {
            [Fact]
            public async Task AppliesMultipleFilters()
            {
                var caseKey = Fixture.Integer();
                var filteredJurisdiction = Fixture.String();
                var caseStatus1 = Fixture.String();
                var caseStatus2 = Fixture.String();
                var f = new DesignatedJurisdictionControllerFixture().WithJurisdictionData(a =>
                                                                                           {
                                                                                               a.CaseStatus = caseStatus1;
                                                                                               a.Jurisdiction = filteredJurisdiction;
                                                                                           },
                                                                                           b => b.CaseStatus = caseStatus2,
                                                                                           c => c.CaseStatus = Fixture.String());
                var result = (await f.Subject.GetFilterDataForColumn(caseKey, "caseStatus", new[]
                {
                    new CommonQueryParameters.FilterValue {Field = "jurisdiction", Operator = CollectionExtensions.FilterOperator.Eq.ToString(), Value = filteredJurisdiction}
                })).ToArray();

                f.DesignatedJurisdictions.Received(1).Get(caseKey).IgnoreAwaitForNSubstituteAssertion();

                Assert.Single(result);
                Assert.Equal(1, result.Count(_ => _.Code == caseStatus1));
            }

            [Fact]
            public async Task ReturnsDistinctFiltersForCaseStatus()
            {
                var caseKey = Fixture.Integer();
                var caseStatus1 = Fixture.String();
                var caseStatus2 = Fixture.String();
                var f = new DesignatedJurisdictionControllerFixture().WithJurisdictionData(a => a.CaseStatus = caseStatus1,
                                                                                           b => b.CaseStatus = caseStatus2,
                                                                                           c => c.CaseStatus = caseStatus1);
                var result = (await f.Subject.GetFilterDataForColumn(caseKey, "caseStatus", new CommonQueryParameters.FilterValue[0])).ToArray();
                f.DesignatedJurisdictions.Received(1).Get(caseKey).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Count());
                Assert.Equal(1, result.Count(_ => _.Code == caseStatus1));
            }

            [Fact]
            public async Task ReturnsDistinctFiltersForDesignatedStatus()
            {
                var caseKey = Fixture.Integer();
                var designationStatus1 = Fixture.String();
                var designationStatus2 = Fixture.String();
                var f = new DesignatedJurisdictionControllerFixture().WithJurisdictionData(a => a.DesignatedStatus = designationStatus1,
                                                                                           b => b.DesignatedStatus = designationStatus2,
                                                                                           c => c.DesignatedStatus = designationStatus1);
                var result = (await f.Subject.GetFilterDataForColumn(caseKey, "designatedStatus", new CommonQueryParameters.FilterValue[0])).ToArray();
                f.DesignatedJurisdictions.Received(1).Get(caseKey).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Count());
                Assert.Equal(1, result.Count(_ => _.Code == designationStatus1));
            }

            [Fact]
            public async Task ReturnsDistinctFiltersForJurisdiction()
            {
                var caseKey = Fixture.Integer();
                var jurisdiction1 = Fixture.String();
                var jurisdiction2 = Fixture.String();
                var f = new DesignatedJurisdictionControllerFixture().WithJurisdictionData(a => a.Jurisdiction = jurisdiction1,
                                                                                           b => b.Jurisdiction = jurisdiction2,
                                                                                           c => c.Jurisdiction = jurisdiction1);
                var result = (await f.Subject.GetFilterDataForColumn(caseKey, "jurisdiction", new CommonQueryParameters.FilterValue[0])).ToArray();
                f.DesignatedJurisdictions.Received(1).Get(caseKey).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(2, result.Count());
                Assert.Equal(1, result.Count(_ => _.Code == jurisdiction1));
            }

            [Fact]
            public async Task UnSupportedFilterThrowsException()
            {
                var f = new DesignatedJurisdictionControllerFixture();
                await Assert.ThrowsAsync<NotSupportedException>(async () => await f.Subject.GetFilterDataForColumn(Fixture.Integer(), Fixture.String("XYZ"), new CommonQueryParameters.FilterValue[0]));
            }
        }

        public class DesignationDetailsMethod
        {
            [Fact]
            public async Task ReturnsJurisdictionDetails()
            {
                var caseKey = Fixture.Integer();
                var f = new DesignatedJurisdictionControllerFixture().WithCaseViewData();
                await f.Subject.DesignationDetails(caseKey);
                f.CaseView.Received(1).GetNames(caseKey);
                f.CaseView.Received(1).GetSummary(caseKey);
                f.CriticalDates.Received(1).Resolve(caseKey).IgnoreAwaitForNSubstituteAssertion();
                await f.CaseTextSection.Received(1).GetClassAndText(caseKey);
            }
        }

        public class DesignatedJurisdictionMethod
        {
            readonly CommonQueryParameters _cqp = new CommonQueryParameters();
            readonly DesignatedJurisdictionControllerFixture _fixture = new DesignatedJurisdictionControllerFixture();
            readonly int _caseKey = Fixture.Integer();

            [Fact]
            public async Task ReturnsPagedResult()
            {
                var f = _fixture.WithJurisdictionData(x => { });
                var result = await f.Subject.DesignatedJurisdiction(_caseKey, _cqp);
                f.DesignatedJurisdictions.Received(1).Get(_caseKey).IgnoreAwaitForNSubstituteAssertion();
                Assert.NotNull(result);
                Assert.Single(result.Data);
            }

            [Fact]
            public async Task ShouldNotPopulateFiledDetailsIfSsoNotSet()
            {
                var r1Ok = Fixture.Integer();

                _fixture.AuthSettings.SsoEnabled.Returns(false); // not configured.

                _fixture.FileInstructInterface.GetFiledCaseIdsFor(Arg.Any<HttpRequestMessage>(), _caseKey)
                        .Returns(new FiledCases
                        {
                            FiledCaseIds = new[] { r1Ok },
                            CanView = true
                        });

                _fixture.WithJurisdictionData(r1 => { r1.CaseKey = r1Ok; });

                var result = await _fixture.Subject.DesignatedJurisdiction(_caseKey, _cqp);

                Assert.False(result.Items<DesignatedJurisdictionData>().Last().IsFiled);
            }

            const bool IpPlatformSessionActive = true;
            const bool IpPlatformSessionInactive = false;
            
            [Theory]
            [InlineData(IpPlatformSessionActive)]
            [InlineData(IpPlatformSessionInactive)]
            public async Task ShouldReturnCanViewInFileIfThereIsActiveIpPlatformSession(bool ipPlatformIsActive)
            {
                var r1Ok = Fixture.Integer();
                var r2NotOk = Fixture.Integer();
                var r3FiledButNoAccess = Fixture.Integer();

                _fixture.AuthSettings.SsoEnabled.Returns(true);

                _fixture.FileInstructInterface.GetFiledCaseIdsFor(Arg.Any<HttpRequestMessage>(), _caseKey)
                        .Returns(new FiledCases
                        {
                            FiledCaseIds = new[] {r1Ok, r3FiledButNoAccess},
                            CanView = ipPlatformIsActive
                        });

                _fixture.WithJurisdictionData(
                                              r1 =>
                                              {
                                                  r1.CaseKey = r1Ok;
                                                  r1.CanView = true;
                                              },
                                              r2 => { r2.CaseKey = r2NotOk; },
                                              r3 =>
                                              {
                                                  r3.CaseKey = r3FiledButNoAccess;
                                                  r3.CanView = false;
                                              });
                
                var result = await _fixture.Subject.DesignatedJurisdiction(_caseKey, _cqp);

                var i = result.Items<DesignatedJurisdictionData>().ToArray();

                // first case filed, inprotech case accessible
                Assert.True(i.ElementAt(0).IsFiled);
                Assert.Equal(ipPlatformIsActive, i.ElementAt(0).CanViewInFile);
                
                // second case not filed, inprotech case accessible
                Assert.False(i.ElementAt(1).IsFiled);
                Assert.False(i.ElementAt(1).CanViewInFile);

                // third case filed, inprotech case not accessible (could be due to Ethical Wall / Row Level Access)
                Assert.True(i.ElementAt(2).IsFiled);
                Assert.False(i.ElementAt(2).CanViewInFile);
            }
        }
    }
}