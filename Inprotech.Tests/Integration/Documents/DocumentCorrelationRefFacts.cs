using System.Linq;
using Inprotech.Integration.Documents;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using Xunit;

namespace Inprotech.Tests.Integration.Documents
{
    public class DocumentCorrelationRefFacts : FactBase
    {
        [Fact]
        public void CanTestForComparisonDocument()
        {
            var r = new Event
            {
                CorrelationRef = new ComparisonDocument().CorrelationRef()
            };

            Assert.True(r.IsBasedOnComparisonDocument());
        }

        [Fact]
        public void CanTestForDocument()
        {
            var doc = new Document().In(Db);
            var r = new Event
            {
                CorrelationRef = doc.CorrelationRef()
            };

            int id;
            Assert.False(r.IsBasedOnComparisonDocument());
            Assert.True(int.TryParse(r.CorrelationRef, out id));
            Assert.Equal(id, doc.Id);
        }

        [Fact]
        public void ComparisonDocumentCorrelationRefShouldReturnCorrelationId()
        {
            var doc = new ComparisonDocument();

            Assert.Equal(doc.CorrelationId.ToString(), doc.CorrelationRef());
        }

        [Fact]
        public void Covariance()
        {
            var docs = new[]
            {
                new Document().In(Db),
                new ComparisonDocument()
            };

            Assert.Equal(docs.First().Id.ToString(), docs.First().CorrelationRef());
            Assert.Equal(((ComparisonDocument) docs.Last()).CorrelationId.ToString(), docs.Last().CorrelationRef());
        }

        [Fact]
        public void DocumentCorrelationRefShouldReturnDocumentId()
        {
            var doc = new Document().In(Db);

            Assert.Equal(doc.Id.ToString(), doc.CorrelationRef());
        }
    }
}