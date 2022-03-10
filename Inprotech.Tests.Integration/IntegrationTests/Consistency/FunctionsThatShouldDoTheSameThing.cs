using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Consistency
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class FunctionsThatShouldDoTheSameThing
    {
        [Test]
        public void EnsureComparisonFunctionsAreConsistent()
        {
            const string crypticDescription = "CrypticDescription ABCDE~!@#$%^&*()_+`_+[]{}\\|;':\",./<>?1234567890";
            const string alphanumericOnly = "crypticdescriptionabcde1234567890";
            var dbCount = DbSetup.Do(setup =>
                                     {
                                         var criteria = setup.InsertWithNewId(new Criteria
                                                                              {
                                                                                  Description = Fixture.Prefix("parent")
                                                                              });
                                         setup.Insert<DataEntryTask>(new DataEntryTask(criteria.Id, 1) {Description = crypticDescription});

                                         return setup.DbContext.Set<DataEntryTask>()
                                                     .Where(_ => _.CriteriaId == criteria.Id)
                                                     .Count(_ => DbFuncs.StripNonAlphanumerics(_.Description) == alphanumericOnly);
                                     });

            var netCount = crypticDescription.ToLower().StripNonAlphanumerics() == alphanumericOnly ? 1 : 0;

            Assert.AreEqual(1, dbCount);
            Assert.AreEqual(1, netCount);
        }
    }
}