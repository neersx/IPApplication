using System;
using System.Collections.Generic;
using System.Linq;
using Autofac.Features.Metadata;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.ValidCombinations;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ValidCombinations
{
    public class ValidCombinationsControllerFacts
    {
        public class ValidCombinationsControllerFixture : IFixture<ValidCombinationsController>
        {
            public ValidCombinationsControllerFixture(InMemoryDbContext db)
            {
                MetaBulkController = Substitute.For<IEnumerable<Meta<Func<IValidCombinationBulkController>>>>();

                Subject = new ValidCombinationsController(db, MetaBulkController);
            }

            public IEnumerable<Meta<Func<IValidCombinationBulkController>>> MetaBulkController { get; }
            public ValidCombinationsController Subject { get; }
        }

        public class ViewDataMethod : FactBase
        {
            [Fact]
            public void ShouldReturnAllValidCombinationSearchTypesOrderByDescription()
            {
                var f = new ValidCombinationsControllerFixture(Db);

                var result = f.Subject.ViewData();
                var results = ((IEnumerable<dynamic>) result).ToArray();

                Assert.Equal(10, results.Length);
                Assert.Equal("default", results[0].Type);
                Assert.Equal("Select Characteristic", results[0].Description);
                Assert.Equal(KnownValidCombinationSearchTypes.AllCharacteristics, results[1].Type);
                Assert.Equal(KnownValidCombinationSearchTypes.AllCharacteristics, results[1].Type);
                Assert.Equal(ConfigurationResources.AllCharacteristics, results[1].Description);
                Assert.Equal(KnownValidCombinationSearchTypes.Action, results[2].Type);
                Assert.Equal(ConfigurationResources.ValidAction, results[2].Description);
                Assert.Equal(KnownValidCombinationSearchTypes.Basis, results[3].Type);
                Assert.Equal(ConfigurationResources.ValidBasis, results[3].Description);
                Assert.Equal(KnownValidCombinationSearchTypes.Category, results[4].Type);
                Assert.Equal(ConfigurationResources.ValidCategory, results[4].Description);
                Assert.Equal(KnownValidCombinationSearchTypes.Checklist, results[5].Type);
                Assert.Equal(ConfigurationResources.ValidChecklist, results[5].Description);
                Assert.Equal(KnownValidCombinationSearchTypes.PropertyType, results[6].Type);
                Assert.Equal(ConfigurationResources.ValidPropertyType, results[6].Description);
                Assert.Equal(KnownValidCombinationSearchTypes.Relationship, results[7].Type);
                Assert.Equal(ConfigurationResources.ValidRelationship, results[7].Description);
                Assert.Equal(KnownValidCombinationSearchTypes.Status, results[8].Type);
                Assert.Equal(ConfigurationResources.ValidStatus, results[8].Description);
                Assert.Equal(KnownValidCombinationSearchTypes.SubType, results[9].Type);
                Assert.Equal(ConfigurationResources.ValidSubType, results[9].Description);
            }
        }

        public class BulkCopyMethod : FactBase
        {
            [Fact]
            public void ShouldReturnExceptionWhenBulkCopyDetailsIsNull()
            {
                var f = new ValidCombinationsControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.BulkCopy(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("bulkCopyDetails", exception.Message);
            }
        }
    }
}