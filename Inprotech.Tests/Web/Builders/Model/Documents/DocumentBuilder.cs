using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Documents;

namespace Inprotech.Tests.Web.Builders.Model.Documents
{
    public class DocumentBuilder : IBuilder<Document>
    {
        public string Name { get; set; }
        public string Code { get; set; }
        public int? ConsumerMask { get; set; }
        public bool IsForPrimeCasesOnly { get; set; }

        public Document Build()
        {
            return new Document(Name ?? Fixture.UniqueName(), Code ?? Fixture.UniqueName())
            {
                ConsumersMask = ConsumerMask.HasValue ? ConsumerMask.Value : 0,
                IsForPrimeCasesOnly = IsForPrimeCasesOnly
            };
        }

        public static DocumentBuilder ForInproDoc()
        {
            return new DocumentBuilder {ConsumerMask = (int)LetterConsumers.InproDoc};
        }

        public static DocumentBuilder ForCases()
        {
            return new DocumentBuilder {ConsumerMask = (int)LetterConsumers.Cases};
        }

        public static DocumentBuilder ForPrimeCase()
        {
            var b = ForCases();
            b.IsForPrimeCasesOnly = true;
            return b;
        }
    }
}