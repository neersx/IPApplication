using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class CaseStatusSummaryReaderFacts : FactBase
    {
        public CaseStatusSummaryReaderFacts()
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            SecurityContext = Substitute.For<ISecurityContext>();
            _subject = new CaseStatusReader(Db, SecurityContext, PreferredCultureResolver);

            var builder = new TableCodeBuilder();
            builder.TableCode = (int) KnownStatusCodes.Pending;
            _pending = builder.Build();
            _pending.In(Db);

            builder.TableCode = (int) KnownStatusCodes.Registered;
            _registered = builder.Build();
            _registered.In(Db);

            builder.TableCode = (int) KnownStatusCodes.Dead;
            _dead = builder.Build();
            _dead.In(Db);
        }

        readonly ICaseStatusReader _subject;
        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public ISecurityContext SecurityContext { get; }
        readonly TableCode _pending;
        readonly TableCode _registered;
        readonly TableCode _dead;

        public static Case BuildCase(bool isLive = false, bool isPropertyLive = false, bool isRegistered = false, bool hasProperty = true, bool hasStatus = true)
        {
            return new CaseBuilder
            {
                HasNoDefaultStatus = !hasStatus,
                Status = new StatusBuilder {IsLive = isLive, IsRegistered = isRegistered}.Build(),
                Property = !hasProperty ? null : new CasePropertyBuilder {Status = new StatusBuilder {IsLive = isPropertyLive}.Build()}.Build()
            }.Build();
        }

        [Fact]
        public void OtherwiseShouldReturnPending()
        {
            var c = BuildCase(true, true, false);
            var r = _subject.GetCaseStatusSummary(c);

            Assert.Equal(_pending, r);
        }

        [Fact]
        public void RetrieveExternalCaseStatus()
        {
            var @case = new CaseBuilder().Build().In(Db);
            @case.CaseStatus.ExternalName = Fixture.String();
            SecurityContext.User.Returns(UserBuilder.AsExternalUser(Db, null).Build());

            var status = _subject.GetCaseStatusDescription(@case.CaseStatus);

            Assert.Equal(@case.CaseStatus.ExternalName, status);
        }

        [Fact]
        public void RetrieveInternalCaseStatus()
        {
            var @case = new CaseBuilder().Build().In(Db);
            SecurityContext.User.Returns(UserBuilder.AsInternalUser(Db).Build());

            var status = _subject.GetCaseStatusDescription(@case.CaseStatus);

            Assert.Equal(@case.CaseStatus.Name, status);
        }

        [Fact]
        public void ShouldReturnDeadIfCasePropertyStatusIsNotLive()
        {
            var c = BuildCase(true, false);
            var r = _subject.GetCaseStatusSummary(c);

            Assert.Equal(_dead, r);
        }

        [Fact]
        public void ShouldReturnDeadIfCaseStatusIsNotLive()
        {
            var c = BuildCase(false);
            var r = _subject.GetCaseStatusSummary(c);

            Assert.Equal(_dead, r);
        }

        [Fact]
        public void ShouldReturnPendingIfRenewalStatusCodeIsNull()
        {
            var c = BuildCase(hasProperty: false, isLive: true, isRegistered: false);
            var r = _subject.GetCaseStatusSummary(c);

            Assert.Equal(_pending, r);
        }

        [Fact]
        public void ShouldReturnPendingIfStatusCodeIsNull()
        {
            var c = BuildCase(hasStatus: false, isPropertyLive: true, isRegistered: false);
            c.CaseStatus = null;

            var r = _subject.GetCaseStatusSummary(c);

            Assert.Equal(_pending, r);
        }

        [Fact]
        public void ShouldReturnRegisteredCaseStatusIsRegistered()
        {
            var c = BuildCase(true, true, true);
            var r = _subject.GetCaseStatusSummary(c);

            Assert.Equal(_registered, r);
        }
    }
}