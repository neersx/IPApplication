using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class NumberTypeBuilder
    {
        public string Code { get; set; }
        public string Name { get; set; }
        public int? RelatedEventNo { get; set; }
        public bool IssuedByIpOffice { get; set; }
        public short? DisplayPriority { get; set; }
        public Event RelatedEvent { get; set; }
        public int? DataItemId { get; set; }

        public NumberType Build()
        {
            var numberType = new NumberType(
                                            Code ?? Fixture.String("A"),
                                            Name ?? Fixture.String("String"),
                                            RelatedEventNo ?? Fixture.Integer())
            {
                DisplayPriority = DisplayPriority ?? Fixture.Short(),
                IssuedByIpOffice = IssuedByIpOffice
            };

            numberType.DocItemId = DataItemId;
            numberType.RelatedEvent = new Event(numberType.RelatedEventId.GetValueOrDefault(), Fixture.String("RelatedEventDesc"));
            return numberType;
        }

        public static NumberTypeBuilder ForRelatedEvent(int relatedEventNo)
        {
            return new NumberTypeBuilder {RelatedEventNo = relatedEventNo};
        }
    }

    public static class NumberTypeBuilderEx
    {
        public static NumberTypeBuilder ForNumberTypeIssuedByIpOffice(
            this NumberTypeBuilder builder,
            short? displayPriority = null)
        {
            builder.IssuedByIpOffice = true;
            builder.DisplayPriority = displayPriority;
            return builder;
        }
    }
}