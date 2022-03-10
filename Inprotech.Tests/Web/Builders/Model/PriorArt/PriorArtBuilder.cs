using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Web.Builders.Model.PriorArt
{
    public class PriorArtBuilder : IBuilder<InprotechKaizen.Model.PriorArt.PriorArt>
    {
        public string OfficialNumber { get; set; }
        public Country Country { get; set; }
        public string Kind { get; set; }
        public string Description { get; set; }
        public string City { get; set; }
        public string Title { get; set; }
        public TableCode SourceType { get; set; }

        public InprotechKaizen.Model.PriorArt.PriorArt Build()
        {
            return new InprotechKaizen.Model.PriorArt.PriorArt(
                                                               OfficialNumber ?? Fixture.String("OfficialNumber"),
                                                               Country ?? new CountryBuilder().Build(),
                                                               Kind);
        }

        public InprotechKaizen.Model.PriorArt.PriorArt BuildSourceDocument()
        {
            return new InprotechKaizen.Model.PriorArt.PriorArt(SourceType ?? new TableCodeBuilder().Build(), Country)
            {
                IsSourceDocument = true
            };
        }

        public InprotechKaizen.Model.PriorArt.PriorArt BuildLiterature()
        {
            return new InprotechKaizen.Model.PriorArt.PriorArt(SourceType ?? new TableCodeBuilder().Build(), Country)
            {
                Description = Description ?? Fixture.String("Description"),
                City = City ?? Fixture.String("City"),
                Title = Title ?? Fixture.String("Title"),
                IsSourceDocument = false,
                IsIpDocument = false
            };
        }
    }
}