using System;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Web.Builders.Model.ValidCombinations
{
    public class DateOfLawBuilder : IBuilder<DateOfLaw>
    {
        public string CountryCode { get; set; }
        public string PropertyTypeId { get; set; }
        public DateTime? Date { get; set; }
        public string RetroActionPrefix { get; set; }
        public string RetroActionId { get; set; }
        public bool IsDefault { get; set; }
        public Event LawEvent { get; set; }

        public DateOfLaw Build()
        {
            var countryCode = string.IsNullOrEmpty(CountryCode) ? Fixture.String("Country") : CountryCode;
            var propertyTypeId = string.IsNullOrEmpty(PropertyTypeId)
                ? Fixture.String("PropertyTypeId")
                : PropertyTypeId;
            var retroActionId = string.IsNullOrEmpty(RetroActionId) ? Fixture.String() : RetroActionId;

            return new DateOfLaw
            {
                CountryId = countryCode,
                PropertyTypeId = propertyTypeId,
                SequenceNo = Fixture.Short(),
                Date = Date ?? Fixture.PastDate(),
                Country = new CountryBuilder {Id = countryCode}.Build(),
                PropertyType = new PropertyTypeBuilder {Id = propertyTypeId}.Build(),
                RetroAction = IsDefault ? null : new ActionBuilder {Id = retroActionId, Name = string.IsNullOrEmpty(RetroActionPrefix) ? Fixture.UniqueName() : Fixture.String(RetroActionPrefix)}.Build(),
                LawEvent = LawEvent ?? new EventBuilder().Build(),
                RetroEvent = new EventBuilder().Build()
            };
        }
    }
}