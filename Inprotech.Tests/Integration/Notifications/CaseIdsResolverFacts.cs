using System;
using System.Linq;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.TempStorage;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class CaseIdsResolverFacts : FactBase
    {
        public CaseIdsResolverFacts()
        {
            _caseIdsResolver = new CaseIdsResolver(Db);
        }

        readonly CaseIdsResolver _caseIdsResolver;

        [Theory]
        [InlineData("123,4556,-1233", 3)]
        [InlineData("123,,-1233", 2)]
        public void SplitsCaseIdsFromCaseList(string caseIds, int expectedNumberOfElements)
        {
            Assert.Equal(expectedNumberOfElements,
                         _caseIdsResolver.Resolve(new SelectedCasesNotificationOptions
                         {
                             Caselist = caseIds
                         }).Count());
        }

        [Fact]
        public void ReturnsCaseIdsCorrectlyInOrder()
        {
            var r = _caseIdsResolver.Resolve(new SelectedCasesNotificationOptions
            {
                Caselist = "3,2,1"
            });

            Assert.True(new[] {"3", "2", "1"}.SequenceEqual(r));
        }

        [Fact]
        public void ReturnsCaseIdsFromTempStorage()
        {
            var t = new TempStorage("3,2,1").In(Db);

            var r = _caseIdsResolver.Resolve(new SelectedCasesNotificationOptions
            {
                Ts = t.Id
            });

            Assert.True(new[] {"3", "2", "1"}.SequenceEqual(r));
        }

        [Fact]
        public void ThrowsIfBothCaseListOrTemporaryStorageIdAreNotProvided()
        {
            Assert.Throws<ArgumentException>(
                                             () => { _caseIdsResolver.Resolve(new SelectedCasesNotificationOptions()); });
        }

        [Fact]
        public void ThrowsIfNoArgumentsAreProvided()
        {
            Assert.Throws<ArgumentNullException>(
                                                 () => { _caseIdsResolver.Resolve(null); });
        }
    }
}