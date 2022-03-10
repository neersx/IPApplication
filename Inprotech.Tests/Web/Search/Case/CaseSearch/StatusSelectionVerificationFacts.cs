using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search.Case.CaseSearch;
using Inprotech.Web.Search.CaseSupportData;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class StatusSelectionVerificationFacts
    {
        static KeyValuePair<int, string>[] BuildKeyValueList(int key, string value)
        {
            return new[] {new KeyValuePair<int, string>(key, value)};
        }

        static StatusSelection BuildSelection(
            KeyValuePair<int, string>[] caseStatuses = null,
            KeyValuePair<int, string>[] renewalStatuses = null)
        {
            caseStatuses = caseStatuses ?? new KeyValuePair<int, string>[0];
            renewalStatuses = renewalStatuses ?? new KeyValuePair<int, string>[0];

            return new StatusSelection
            {
                CaseStatuses = caseStatuses,
                RenewalStatuses = renewalStatuses
            };
        }

        public class CaseStatus
        {
            [Fact]
            public void ShouldNotInvokeCaseSupportDataServiceIfNoSelection()
            {
                var fixture = new StatusSelectionFixture();

                fixture.Subject.Verify(BuildSelection());

                fixture.CaseStatuses
                       .DidNotReceiveWithAnyArgs()
                       .Get(null, false, false, false, false);
            }

            [Fact]
            public void ShouldRemoveItemIfKeyDoesNotExistInTheNewList()
            {
                var fixture = new StatusSelectionFixture();

                fixture.CaseStatuses.Get(null, false, false, false, false)
                       .Returns(BuildKeyValueList(1, "v1"));

                var result = fixture.Subject.Verify(BuildSelection(BuildKeyValueList(2, "v2")));

                Assert.Empty(result.CaseStatuses);
            }

            [Fact]
            public void ShouldUpdateItemIfKeyExistsInTheNewList()
            {
                var fixture = new StatusSelectionFixture();

                fixture.CaseStatuses.Get(null, false, false, false, false)
                       .Returns(BuildKeyValueList(1, "v2"));

                var result = fixture.Subject.Verify(BuildSelection(BuildKeyValueList(1, "v1")));

                Assert.Equal("v2", result.CaseStatuses.Single().Value);
            }
        }

        public class RenewalStatus
        {
            [Fact]
            public void ShouldNotInvokeCaseSupportDataServiceIfNoSelection()
            {
                var fixture = new StatusSelectionFixture();

                fixture.Subject.Verify(BuildSelection());

                fixture.RenewalStatuses
                       .DidNotReceiveWithAnyArgs()
                       .Get(null, false, false, false);
            }

            [Fact]
            public void ShouldRemoveItemIfKeyDoesNotExistInTheNewList()
            {
                var fixture = new StatusSelectionFixture();

                fixture.RenewalStatuses.Get(null, false, false, false)
                       .Returns(BuildKeyValueList(1, "v1"));

                var result = fixture.Subject.Verify(BuildSelection(renewalStatuses: BuildKeyValueList(2, "v2")));

                Assert.Empty(result.RenewalStatuses);
            }

            [Fact]
            public void ShouldUpdateItemIfKeyExistsInTheNewList()
            {
                var fixture = new StatusSelectionFixture();

                fixture.RenewalStatuses
                       .Get(null, false, false, false)
                       .Returns(BuildKeyValueList(1, "v2"));

                var result = fixture.Subject.Verify(BuildSelection(renewalStatuses: BuildKeyValueList(1, "v1")));

                Assert.Equal("v2", result.RenewalStatuses.Single().Value);
            }
        }
    }

    public class StatusSelectionFixture : IFixture<StatusSelectionVerification>
    {
        public StatusSelectionFixture()
        {
            CaseStatuses = Substitute.For<ICaseStatuses>();
            RenewalStatuses = Substitute.For<IRenewalStatuses>();
        }

        public IRenewalStatuses RenewalStatuses { get; set; }

        public ICaseStatuses CaseStatuses { get; set; }

        public StatusSelectionVerification Subject => new StatusSelectionVerification(CaseStatuses, RenewalStatuses);
    }
}